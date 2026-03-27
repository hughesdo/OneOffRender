#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Purple & Green Chase
// Created by diatribes
// Shadertoy ID: M3yfWd
// https://www.shadertoy.com/view/M3yfWd

#define R 2.
#define S 5.5

vec3 path1(float z) {
    return vec3(
        tanh(cos(z * .017)*1.) * 13.,
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

vec3 gyroid(vec3 p) {
  float g = (cos(p.x) * sin(p.y) + cos(p.y) * sin(p.z) + cos(p.z) * sin(p.x));
  return vec3(g);
}

vec3 lightPosition(vec3 p, int i) {
    p.xy-=path1(p.z).xy;
    switch(i) {
    case 0:
        return p-vec3(
                tanh(cos(iTime*3.)*2.)*.75,
                tanh(cos(iTime*2.)*2.)*.75,
                12.+iTime*S+tanh(cos(iTime*.4)*8.)*8.
            );
        break;
    case 1:
        return p-vec3(
                tanh(cos(iTime*2.)*3.)*.35,
                tanh(cos(iTime*2.6)*2.)*.65,
                13.+iTime*S+tanh(cos(iTime*.33)*8.)*9.
            );
        break;
    }
}

float scene(vec3 p, out vec3 rgb) {
    float g1 = length(gyroid(sin(p))*.3);
    g1 *= g1;
    float g2 = length(gyroid(sin(p*60.))*.1);
    g2 *= g2;
    float p1 = g2+g1+length(p.xy - path1(p.z).xy);
    float p2 = g2+g1+length((p.xy - path2(p.z).xy).y);
    float p3 = g1+length(g1+(p.xy - path3(p.z).xy).x+5.5);
    float o1 = length(lightPosition(p,0))-.3;
    float o2 = length(lightPosition(p,1))-.3;
    float hit = min(o1,min(o2,R - min(p1,min(p2, p3))));
    if (hit == o1) {
        rgb = vec3(1.);
    } else if (hit == o2) {
        rgb = vec3(1.);
    } else if (hit == R - p2) {
        rgb = vec3(.7,.0,.2);
    } else {
        rgb = vec3(1.);
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
                     sin(2.*sin(iTime*.1))));
	float d = raymarch(ro, rd, rgb);
    vec3 p = ro + rd * d;
    float diffuse = max(dot(normal(p), normalize(ro-p)), .05);
    if (d < 100.) {
        float o1 = abs(length(lightPosition(p,0)));
        float o2 = abs(length(lightPosition(p,1)));
        vec3 oc = mix(vec3(.2,0.,1.)/o1,
                vec3(.2,1.,.1)/o2,.5);
        d = o1+o2;
        rgb *= 2.5/(pow(d,d*.095));
        rgb *= diffuse;
        rgb = mix(rgb,oc,.5);
    } else {
        vec3 red = vec3(.3, 0.00, 0.125);
        vec3 blue = vec3(0.0, 0.125, 0.5);
        rgb = mix(red.xyz, blue.xyz, uv.y);
    }
    o = vec4(pow(rgb, vec3(.45)), 1.0);
    fragColor = o;
}

