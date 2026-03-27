#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Plasma Raymarch Experiment
// Created by diatribes
// Shadertoy ID: l33BWN
// https://www.shadertoy.com/view/l33BWN

#define MAX_STEPS 75
#define MAX_DIST 70.0
#define SURFACE_DIST .1
#define inf (MAX_DIST+1.0)

float plasma(vec2 uv, out vec3 rgb){
    float t = iTime;
    float r = distance(uv, vec2(-3.0,3.0));
    float g = distance(uv, vec2(1.0, 1.0-r)); 
    float b = distance(uv, vec2(r, sin(t)*.1));
    float v = ((cos(r+t)*.5+.8) + (cos(g+t)*.5+.8) + (cos(b+t)*.5+.8));
    v *= 10.0;
    rgb = vec3(r/v,g/v,b/v);
    return length(rgb);
}

float scene(vec3 p, out vec3 rgb) {
  return plasma(p.xy, rgb);
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

mat3 lookAt(vec3 origin, vec3 target, float roll) {
  vec3 rr = vec3(sin(roll), cos(roll), 0.0);
  vec3 ww = normalize(target - origin);
  vec3 uu = normalize(cross(ww, rr));
  vec3 vv = normalize(cross(uu, ww));
  return mat3(uu, vv, ww);
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    vec2 uv = (u - 0.5 * iResolution.xy) / iResolution.y;
    vec3 rayOrigin = vec3(0.0, 0.0, -5.0);
    vec3 target = vec3(0.0);
    mat3 camera = lookAt(rayOrigin, target, 0.0);
    vec3 rayDirection = camera * normalize(vec3(uv, 1.0));
    vec3 rgb;
    float dist = raymarch(rayOrigin, rayDirection, rgb);
    vec3 col = rgb;
    o = vec4(col, 1.0);
    fragColor = o;
}

