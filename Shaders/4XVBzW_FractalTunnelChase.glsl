#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Fractal Tunnel Chase
// Created by diatribes
// Shadertoy ID: 4XVBzW
// https://www.shadertoy.com/view/4XVBzW

#define MAX_STEPS 70.
#define MAX_DIST 30.
#define SURFACE_DIST .001
#define inf (MAX_DIST+1.0)
#define TIME_MULTIPLIER 7.
#define ORB_RADIUS .3

vec3 path(float z) {
    return vec3(
        sin(z*.1)*2.*cos(z*.2)*2.,
        sin(z*.05)*1.5*cos(z*.1)*2.,
        iTime*TIME_MULTIPLIER+1.5
    );
}

vec3 lightPosition(vec3 p) {
    p-=path(p.z);
    return p-vec3(
        0.,
        sin(iTime)*.3,
        sin(iTime)*3.+4.
    );
}

float fractal(vec3 p, out vec3 rgb, int iterations){
  float m = 1.;
  for (int i = 0; i < iterations; i++) {
    float n = abs(p.x*p.y*p.z);
    p = abs(p)/clamp(n,.2,1.2)-1.75;
    m = abs(min(p.x,min(p.y,p.z)));
  }
  m = exp(-3. * m)*2.5;
  rgb=vec3(p.xy,3.5) * m;
  return length(rgb*.1);
}

float scene(vec3 p, out vec3 rgb) {
	vec3 tun = abs(p - path(p.z));
    float orb = length(lightPosition(p))-ORB_RADIUS;
    float hit = min(orb,min(1.5-tun.x,1.5-tun.y));
    if (orb == hit) {
        rgb = vec3(.6,.1,.6);
    } else {
        vec3 temp;
        fractal(vec3(tun.xy,sin(p.z)),temp,5);
        fractal(vec3(tun.xy,sin(p.z)),rgb,3);
        rgb=mix(rgb,temp,.5);
    }
    return hit;
}

float raymarch(vec3 ro, vec3 rd, out vec3 rgb) {
  float dist = 0.0;
  for(float i = 0.; i < MAX_STEPS; i++) {
    vec3 p = ro + rd * dist;
    float step = scene(p, rgb);
    dist += step;
    if(dist > MAX_DIST || step < SURFACE_DIST) {
        break;
    }
  }
  return dist;
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
    vec3 rgb = vec3(1.);
	
    vec2 uv = -1.0 + 2.0*(u.xy/iResolution.xy);
	uv.x *= iResolution.x/iResolution.y;

	vec3 ro = vec3(cos(iTime)*.2, sin(iTime)*.3, iTime*TIME_MULTIPLIER);
	vec3 la = ro + vec3(0., 0., 1.);
	ro.xy = path(ro.z).xy;
	la.xy = path(la.z).xy-lightPosition(ro).xy;

	vec3 rd = normalize(vec3(uv,1.)*lookAt(ro,la,sin(iTime)*.2));

	float d = raymarch(ro, rd, rgb);
    vec3 p = ro + rd * d;
    
    float diffuse = max(dot(normal(p), normalize(ro-p)), .0);
    rgb *= diffuse*5.;
    
    float len = length(lightPosition(p));
    if (len > ORB_RADIUS*2.) {
      rgb /= (pow(len,len*.75));
    }
    
    fragColor = vec4(pow(rgb, vec3(.45)), 1.0);
}

