#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Psychedelixploration
// Created by diatribes
// Shadertoy ID: l3cfDH
// https://www.shadertoy.com/view/l3cfDH

#define MAX_STEPS 30
#define MAX_DIST 30.0
#define SURFACE_DIST .01
 
float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,vec2(12.9898,78.233)))*43758.5453123);
}
 
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f*f*(3.0-2.0*f);
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

vec3 path(vec3 p){
  vec3 o = vec3(0.);
  o.x += noise(vec2(p.z*.25,5.))*5.;
  o.y += noise(vec2(p.z*.25,4.))*5.;
  return o;
}

vec3 repeat(vec3 p, float c) {
  return mod(p,c)-0.5*c;
}

float sdSphere(vec3 p, float radius) {
    return length(p) - radius;
}
float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}
float scene(vec3 p) {
  vec3 s = repeat(p - vec3(-.5, 0.0, -5.0), 4.0);
  float box = cos(sdBox(s, vec3(1.0)));
  float sphere = (length(s) - 0.25);
  return min(box,sphere);;
}

float raymarch(vec3 ro, vec3 rd) {
  float dist = 0.0;
  for(int i = 0; i < MAX_STEPS; i++) {
    vec3 p = ro + rd * dist;
    float step = scene(p);
    dist += step;
    if(dist > MAX_DIST || step < SURFACE_DIST) {
        break;
    }
  }
  return dist;
}

vec3 getNormal(vec3 p) {
  vec2 e = vec2(.01, 0);
  vec3 n = scene(p) - vec3(
    scene(p-e.xyy),
    scene(p-e.yxy),
    scene(p-e.yyx));
  return normalize(n);
}

vec3 rotateAxis(vec3 p, vec3 axis, float angle) {
  return mix(dot(axis, p)*axis, p, cos(angle)) + cross(axis,p)*sin(angle);
}

void main()
{
  vec2 u = gl_FragCoord.xy;
  vec4 o;
  float time = iTime * 5.0;
  vec2 uv = u/iResolution.xy;
  uv -= 0.5;
  uv.x *= iResolution.x / iResolution.y;

  vec3 ro = vec3(0.0, 0.0, -time*.25);
  vec3 rd = normalize(vec3(uv, -1.0));
  rd = rotateAxis(rd, vec3(0.0, 0.0, 1.0),.02*time);
  ro = path(ro)+rd;
  ro.z = -time*.75;
  
  float d = raymarch(ro, rd);
  vec3 color = vec3(0.0);
  if(d<MAX_DIST) {
      vec3 p = ro + rd * d;
      uv *= 5.0;
      vec3 normal = getNormal(p);
      vec3 lightPosition = vec3(ro);
      vec3 lightDirection = normalize(lightPosition - p);
      float diffuse = max(dot(normal, lightDirection), 0.0);
      color = vec3(1.0, 1.0, 1.0) * diffuse;
      float t = time / 8.0;
      float r = distance(.01*d+uv, vec2(sin(t), sin(1.0/t)*.1));
      float g = distance(.002+uv, vec2(uv.x, r*sin(t))); 
      float b = distance(.01*d+uv, vec2(r, sin(t)));
      float value = abs(sin(d*r+t) + sin(d*g+t) + sin(d*b+t));
      value *=  4.0;
      r /= value;
      g /= value;
      b /= value;
      color *= vec3(r,g,b) * (16.0/d);
  }
  o = vec4(color, 1.0);
  fragColor = o;
}

