#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Orb Light Hall
// Created by diatribes
// Shadertoy ID: 4XVBR1
// https://www.shadertoy.com/view/4XVBR1

#define FRACT_MIN .3
#define FRACT_MAX 1.8
#define FRACT_OFFSET 1.75
#define MAX_STEPS 60
#define MAX_DIST 30.0
#define SURFACE_DIST .001
#define inf (MAX_DIST+1.0)

vec3 repeat(vec3 p, float c) {
  return mod(p,c)-0.5*c;
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdSphere(vec3 p, float r) {
  return length(p) - r;
}

vec3 sdOrbLoc(vec3 p) {
  float sa = sin(iTime*3.);
  float ca = cos(iTime*3.);
  mat2 m = mat2(ca,-sa,sa,ca);
  vec3 r = p-vec3(
    sin(sin(iTime))*.7,
    cos(cos(iTime*.5))*.25,
    -iTime-4.25+sin(iTime*.5)*3.);
  r.xz *= m;
  return r;
}

float sdOrb(vec3 p, float r) {
  return sdSphere(sdOrbLoc(p), r);
}

float sdCross(in vec3 p, float s) {
  float da = sdBox(p.xyz, vec3(s, s, s));
  float db = sdBox(p.yzx, vec3(s, inf, s));
  float dc = sdBox(p.zxy, vec3(s, s, inf));
  float sp = sdSphere(p, s*2.0);
  return min(sp,min(da, min(db, dc)));
}

float fractal(vec3 p, out vec3 rgb, int iterations){
  float m = 1.;
  for (int i = 0; i < iterations; i++) {
    float n = abs(p.x*p.y*p.z);
    p = abs(p)/clamp(n,FRACT_MIN,FRACT_MAX)-FRACT_OFFSET;
    m = abs(min(p.x,min(p.y,p.z)));
  }
  m = exp(-2. * m)*2.5;
  rgb=vec3(p.xy,3.5) * m;
  return length(rgb*.1);
}

#define s(x) sin((x)+iTime)
float plasma(vec3 p, out vec3 rgb, float z) {
  float c = length(p) - 1.;
  float r=distance(sin(z*p.xz)*p.xz,vec2(s(0.),s(0.)))*p.z;
  float g=distance(z*p.xy,p.zx)*p.z;
  float b=distance(z*p.xz,vec2(g,s(0.)))*p.z;
  float v=1.+(20.)*abs(s(r)+s(g)+s(b));
  rgb = vec3(r/v,g/v*.5,b/v);
  return length(rgb)*.1;
}

float scene(vec3 p, out vec3 rgb) {
    vec3  s = repeat(p, 2.0);
    float c = sdCross(s, .125);
    float o = sdOrb(p, .1);
    float m = min(o,c);
          m = min(m,2.5-abs(p.x));
          m = min(m,1.0-abs(p.y));
    if (o <= m && m < c) {
        fractal(sdOrbLoc(p),rgb,7);
        rgb *= vec3(.1,3.,.1);
        return o;
    } else if (c < m) {
        fractal(s, rgb, 5);
        return c;
    } else {
        vec3 temp;
        fractal(s, rgb, 6);
        plasma(abs(s), temp, 32.);
        rgb = mix(rgb, temp, .5);
        return m;
    }
}

float raymarch(vec3 ro, vec3 rd, out vec3 rgb) {
  float dist = 0.0;
  for(int i = 0; i < MAX_STEPS; i++) {
    vec3 p = ro + rd * dist;
    float step = scene(p, rgb);
    dist += step;
    if(dist > MAX_DIST || step < SURFACE_DIST) {
        break;
    }
  }
  return dist;
}

vec3 getNormal(vec3 p) {
  vec2 e = vec2(.01, 0);
  vec3 rgb;
  vec3 n = scene(p,rgb) - vec3(
    scene(p-e.xyy,rgb),
    scene(p-e.yxy,rgb),
    scene(p-e.yyx,rgb));
  return normalize(n);
}

void main()
{
  vec2 u = gl_FragCoord.xy;
  vec2 uv = u.xy/iResolution.xy-.5;
  uv.x *= iResolution.x / iResolution.y;
  vec3 ro = vec3(0.0, 0.0, -iTime);
  vec3 rd = normalize(vec3(uv, -1.0));
  vec3 rgb;
  float d = raymarch(ro, rd, rgb);
  vec3 color = vec3(0.0);
  if(d<MAX_DIST) {
    vec3 p = ro + rd * d;
    vec3 normal = getNormal(p);
    vec3 lightDirection = normalize(ro - p);
    float diffuse = max(dot(normal, lightDirection), .0);
    color = rgb * diffuse;
  } else {
    color = vec3(0.);
  }
  fragColor = vec4(color,1.);
}

