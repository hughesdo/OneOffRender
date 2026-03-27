#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// There's a party in my head
// Created by diatribes
// Shadertoy ID: MXcfWH
// https://www.shadertoy.com/view/MXcfWH

#define MAX_STEPS 50
#define MAX_DIST 20.0
#define SURFACE_DIST .001
#define inf (MAX_DIST+1.0)

vec3 repeat(vec3 p, float c) {
  return mod(p,c)-0.5*c;
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdCross(in vec3 p, float s) {
  float da = sdBox(p.xyz, vec3(1.0, s, s));
  float db = sdBox(p.yzx, vec3(s, 1.0, s));
  float dc = sdBox(p.zxy, vec3(s, s, 1.0));
  return min(da, min(db, dc));
}

vec2 rotate(vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c)*p;
}

float scene(vec3 p) {
  vec3 s = p - vec3(0.0, 0.0, -3.5);
  s.xy = rotate(s.xy,iTime);
  s.xz = rotate(s.xz,iTime);
  float box = sin(sdBox(s, vec3(.25,.25,.25))*.5+.5);
  float cross = cos(sdCross(s, .125))*.5+.5;
  float boxCross = (box-cross)+(sin(iTime)*.25+.25);
  return min(cross,boxCross);
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

void main()
{
  vec2 u = gl_FragCoord.xy;
  vec4 o;
  vec2 uv = u/iResolution.xy-.5;
  uv.x *= iResolution.x / iResolution.y;
  vec3 ro = vec3(0.0, 0.0, 0.0);
  vec3 rd = normalize(vec3(uv, -1.0));
  float d = raymarch(ro, rd);
  vec3 color = vec3(0.0);
  vec3 p = ro + rd * d;
  if(d<MAX_DIST) {
    vec3 normal = getNormal(p);
    vec3 lightPosition = vec3(0.0, 0.0, 0.0);
    vec3 lightDirection = normalize(lightPosition - p);
    float diffuse = max(dot(normal, lightDirection), 0.0);
    color = vec3(1.0, 1.0, 1.0) * diffuse;
    float t = iTime / 2.0;
    uv *= 5.0;
    float r = distance(uv, vec2(sin(t), sin(1.0/t)*.1));
    float g = distance(uv, vec2(0, r)); 
    float b = distance(uv, vec2(r, sin(t)));
    float value = abs(sin(r+t) + sin(g+t) + sin(b+t) + sin(uv.x+t) + cos(uv.y+t));
    value *= 4.0;
    r /= value;
    g /= value;
    b /= value;
    color *= vec3(r,g,b) * (16.0/d);
  }
  o = vec4(color, 1.0);
  fragColor = o;
}

