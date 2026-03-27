#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Wormhole Tunnel
// Created by diatribes
// Shadertoy ID: 4XKfzd
// https://www.shadertoy.com/view/4XKfzd

#define CAVERN_RADIUS 3.
#define MAX_STEPS 100.
#define MAX_DIST 100.
#define SURFACE_DIST .001
#define inf (MAX_DIST+1.0)
#define TIME_MULTIPLIER 16.
#define LENGTH2_DISABLED
#define FRACT_MIN  ((sin(iTime*.4)*.13)+(sin(iTime*.6)*.15+.5))
#define FRACT_MAX  1.75
#define FRACT_OFFS 1.25

float length2(vec2 p){
#ifdef LENGTH2_ENABLED
    float k = 20.;
    p = pow(abs(p), vec2(k));
    return pow(p.x + p.y, 1./k);
#else
    return length(p);
#endif
}

vec3 path1(float z) {
    return vec3(
        tan(cos(z * .001) * 1.3)+(cos(z * .05) * 1.5) * 5., 
        sin(sin(z * .01)) * 16.3,
        z
    );
}

vec3 path2(float z) {
    return vec3(
        CAVERN_RADIUS-cos(z * .05) * 5.75, 
        CAVERN_RADIUS-cos(z * .03) * 3.4, 
        z
    ) ;
}

vec3 path3(float z) {
    return vec3(
        CAVERN_RADIUS-cos(z * .5) * .125, 
        cos(z * .0125) * 5.125, 
        z
    ) ;
}

vec3 fractal(vec3 p, int interations){
  float m = 1.;
  for (int i = 0; i < interations; i++) {
    float n = abs(p.x*p.y*p.z);
    p = abs(p)/clamp(n,FRACT_MIN,FRACT_MAX)-FRACT_OFFS;
    m = abs(min(p.x,min(p.y,p.z)));
  }
  m = exp(-2. * m)*2.5;
  return vec3(p.xy,2.125) * m;
}

vec3 plasma(vec2 uv) {
    float t = iTime / 2.0;
    uv *= 10.;
    float r = distance(uv, vec2(sin(t), sin(t)));
    float g = distance(uv, vec2(0, 3.));
    float b = distance(uv, vec2(r, sin(t)*25.));
    float value = abs(sin(r+t) + sin(g+t) + sin(b+t) + sin(uv.x+t) + cos(uv.y+t));
    value = (value);
    r/=value;
    g/=value;
    b/=value;
    return pow(vec3(r,g,b)*vec3(.2,.2,.2), vec3(3.));
}

float scene(vec3 p, out vec3 rgb) {
    vec3 tun = abs(p - path1(p.z));
    vec3 orb1 = abs(p - path2(p.z));
    vec3 orb2 = abs(p - path3(p.z));
    float tunnel = max(CAVERN_RADIUS-length2(tun.xy),CAVERN_RADIUS-length2(tun.yx));
    float orb = min(length(orb1)-.5,length(orb2)-.5);
    float hit = min(tunnel,orb);
    if (orb == hit) {
        rgb = plasma(orb1.xy)*vec3(1.,.5,.5);
    } else {
        rgb = fractal(vec3(tun.xy,sin(p.z)),5);
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
    vec3 ro = vec3(0., 0., iTime*TIME_MULTIPLIER);
    vec3 la = ro + vec3(0., 0., 1.);
    ro.xy = path1(ro.z).xy;
    la.xy = path1(la.z).xy;
    vec3 rd = normalize(vec3(uv,1.)*lookAt(ro,la,0.));
    float d = raymarch(ro, rd, rgb);
    vec3 p = ro + rd * d;
    float diffuse = max(dot(normal(p), normalize(ro-p)), .0);
    rgb *= diffuse;
    fragColor = vec4(pow(rgb, vec3(.45)), 1.0);
}

