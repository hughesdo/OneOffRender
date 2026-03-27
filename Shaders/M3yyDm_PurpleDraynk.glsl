#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Purple Draynk
// Created by diatribes
// Shadertoy ID: M3yyDm
// https://www.shadertoy.com/view/M3yyDm

#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURFACE_DIST 0.001
#define inf 1e10

mat4 rotation3d(vec3 axis, float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;
  return mat4(
      oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,
      oc * axis.z * axis.x + axis.y * s, 0.0, oc * axis.x * axis.y + axis.z * s,
      oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
      oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s,
      oc * axis.z * axis.z + c, 0.0, 0.0, 0.0, 0.0, 1.0);
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdCross(in vec3 p) {
  float da = sdBox(p.xyz, vec3(inf, 1.0, 1.0));
  float db = sdBox(p.yzx, vec3(1.0, inf, 1.0));
  float dc = sdBox(p.zxy, vec3(1.0, 1.0, inf));
  return min(da, min(db, dc));
}

float scene(vec3 p) {
  float d = 0.0;
  float scale = 1.0;
  float angle = iTime * 0.9;
  vec3 axis = vec3(sin(iTime) * .1, cos(iTime) * .05, sin(iTime * .3) * .3);
  mat4 m = rotation3d(axis, angle);
  p = (m * vec4(p, 1.0)).xyz;
  for (int i = 0; i < 4; i++) {
    vec3 a = mod(p * scale, 3.0) - 1.0;
    vec3 r = 1.0 - 3.00 * abs(a);
    scale *= 3.25;
    float c = sdCross(r) / scale;
    d = max(d, c);
  }
  return d;
}

float raymarch(vec3 ro, vec3 rd) {
  float dist = 0.0;
  for (int i = 0; i < MAX_STEPS; i++) {
    vec3 p = ro + rd * dist;
    float step = scene(p);
    dist += step;
    if (dist > MAX_DIST || step < SURFACE_DIST) {
      break;
    }
  }
  return dist;
}

vec3 getNormal(vec3 p) {
  vec2 e = vec2(.01, 0);
  vec3 n =
      scene(p) - vec3(scene(p - e.xyy), scene(p - e.yxy), scene(p - e.yyx));
  return normalize(n);
}

vec3 getColor(float amount) {
  return vec3(.25, 0, .25) * sin(sin(iTime) * .5 + .5 + .25) *
         vec3(.473, 0, .833) * amount;
}

void main() {
  vec2 u = gl_FragCoord.xy;
  vec4 o;
  vec2 uv = u / iResolution.xy;
  uv -= 0.5;
  uv.x *= iResolution.x / iResolution.y;
  vec3 ro = vec3(0, 0, (sin(iTime) * .5 + .5));
  vec3 lightPosition = ro;
  vec3 rd = normalize(vec3(uv, -1.0));
  float d = raymarch(ro, rd);
  vec3 p = ro + rd * d;
  vec3 color = vec3(0.0);
  if (d < MAX_DIST) {
    vec3 normal = getNormal(p);
    vec3 lightDirection = normalize(lightPosition - p);
    float diffuse = max(dot(normal, lightDirection), 0.0);
    color = vec3(1.0, 1.0, 1.0) * (diffuse);
  }
  o = vec4(color * getColor(d*2.0), 1.0);
  fragColor = o;
}

