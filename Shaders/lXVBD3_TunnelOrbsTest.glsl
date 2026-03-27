#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Tunnel Orbs Test
// Created by diatribes
// Shadertoy ID: lXVBD3
// https://www.shadertoy.com/view/lXVBD3

#define R 1.5
#define S 4.

vec3 path1(float z) {
    return vec3(
        tanh(cos(z * .017)*1.) * 3.,
        tanh(cos(z * .1)*1.) * 6.,
        z
    );
}

vec3 path2(float z) {
    return vec3(
        tanh(cos(z * .12)*1.) * 4.,
        tanh(cos(z * .15)*1.) * 3.,
        z
    );
}

vec3 path3(float z) {
    return vec3(
        sin(z * .05) * 6.,
        sin(z * .08) * 4.,
        z
    );
}

vec3 fractal(vec3 p, int iterations){
  for (int i = 0; i < iterations; i++) {
    float n = abs(p.x*p.y*p.z);
    p = abs(p)/clamp(n,.2,.8)-1.75;
  }
  return vec3(p.x*p.y);
}

vec3 lightPosition(vec3 p, int i) {
    p.xy-=path1(p.z).xy;
    switch(i) {
    case 0:
        return p-vec3(
                tanh(cos(iTime*3.)*2.)*.75,
                tanh(cos(iTime*2.)*2.)*.75,
                iTime*S+tanh(cos(iTime*.4)*8.)*8.
            );
        break;
    case 1:
        return p-vec3(
                tanh(cos(iTime*5.)*3.)*.95,
                tanh(cos(iTime*2.6)*7.)*.65,
                iTime*S+tanh(cos(iTime*.39)*8.)*6.
            );
        break;
    }
}

vec3 colorize(vec3 p) {
    vec2 uv = sin(p.xz);
    float s = sin(p.z)*.5*5.5;
    float t = iTime / 5.0;
    float r = distance(uv*s, vec2(sin(p.xz)));
    float g = distance(uv*s, vec2(r, sin(p.xz+t)));
    float b = distance(uv*s, vec2(g, sin(p.xz+t)));
    float value = (abs(sin(r+t) + sin(g+t) + sin(b+t)
                        + sin(uv.x+t) + cos(uv.y+t)));
    r/=value;
    g/=value;
    b/=value;
    return vec3(r,g,b);
}

float scene(vec3 p, out vec3 rgb) {
    float p1 = length(p.xy - path1(p.z).xy);
    float p2 = length((p.xy - path2(p.z).xy).y+5.5);
    float p3 = length((p.xy - path3(p.z).xy).x+5.5);
    float o1 = length(lightPosition(p,0))-.3;
    float o2 = length(lightPosition(p,1))-.3;
    float hit = min(o1,min(o2,R - min(p1,min(p2, p3))));
    if (hit == o1) {
        rgb = vec3(.2,1.,1.);
    } else if (hit == o2) {
        rgb = vec3(1.,.2,.1);
    } else if (hit == R - p2) {
        rgb = fractal(sin(p),3);
    } else {
        rgb = fractal(cos(sin(p)),4);
    }
    return hit;
}

float raymarch(vec3 ro, vec3 rd, out vec3 rgb) {
   float d = 0.;
   for(float i = 0.; i < 200.; i++) {
        float step = scene(ro + rd *d, rgb);
        d += step;
        if(d > 100. || step < .001) {
            break;
        }
    }
    return d;
}

mat3 lookAt(vec3 origin, vec3 target, float roll) {
    vec3 rr = vec3(sin(roll), cos(roll), 0.0);
    vec3 ww = normalize(target - origin);
    vec3 uu = normalize(cross(ww, rr));
    vec3 vv = normalize(cross(uu, ww));
    return mat3(uu, vv, ww);
}

vec3 normal(vec3 p) {
    vec2 e = vec2(.01, 0);
    vec3 rgb;
    vec3 n = scene(p,rgb) - vec3(
         scene(p-e.xyy,rgb),
         scene(p-e.yxy,rgb),
         scene(p-e.yyx,rgb));
    return normalize(n);
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    vec3 rgb = vec3(1.);
    vec2 uv = -1.0 + 2.0*(u/iResolution.xy);
	uv.x *= iResolution.x/iResolution.y;
	vec3 ro = path1(iTime*S);
	vec3 rd = normalize(vec3(uv,1.)
            * lookAt(ro, 
                     vec3(ro.x,ro.y,ro.z)-lightPosition(ro,0),
                     sin(4.*sin(iTime*.5))));
	float d = raymarch(ro, rd, rgb);
    vec3 p = ro + rd * d;
    float diffuse = max(dot(normal(p), normalize(ro-p)), .0);
    if (d < 100.) {
        float o1 = abs(length(lightPosition(p,0)));
        float o2 = abs(length(lightPosition(p,1)));
        vec3 oc = pow(vec3(.2,1.,1.)/o1
                + vec3(1.,.2,.1)/o2, vec3(2.5));
        d = o1+o2;
        rgb *= 5.0/(pow(d*.5,d*.008));
        rgb *= diffuse;
        rgb *= oc;
    } else {
        vec3 red = vec3(.3, 0.00, 0.125);
        vec3 blue = vec3(0.0, 0.125, 0.5);
        rgb = mix(red.xyz, blue.xyz, uv.y);
    }
    o = vec4(pow(rgb, vec3(.45)), 1.0);
    fragColor = o;
}

