#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Cyclic Fractal Graffiti Hall
// Created by diatribes
// Shadertoy ID: 433BzB
// https://www.shadertoy.com/view/433BzB

#define FRACT_MIN .3
#define FRACT_MAX .8
#define FRACT_OFFSET 1.75

#define MAX_STEPS 50
#define MAX_DIST 4.0
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
  float da = sdBox(p.xyz, vec3(s, s, s));
  float db = sdBox(p.yzx, vec3(s, inf, s));
  float dc = sdBox(p.zxy, vec3(s, s, inf));
  return min(da, min(db, dc));
}

float fractal(vec3 p, out vec3 rgb, int iterations){
  float m = 1.;
  for (int i = 0; i < iterations; i++) {
        float n = abs(p.x*p.y*p.z);
        p = abs(p)/clamp(n,FRACT_MIN,FRACT_MAX)-FRACT_OFFSET;
        m = abs(min(p.x,min(p.y,p.z)));
  }
  m = exp(-2. * m)*3.;
  rgb=vec3(2.0, p.xy) * m;
  return length(rgb);
}

float scene(vec3 p) {
  vec3 s = repeat(p, 2.0);
  float cross = sdCross(s, .125);
  return min(1.0-p.x,min(1.0+p.x,min(1.0+p.y,min(1.0-p.y,cross))));
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


void main()
{
  vec2 u = gl_FragCoord.xy;
  vec2 uv = u.xy/iResolution.xy-.5;
  uv.x *= iResolution.x / iResolution.y;

  vec3 ro = vec3(0.0, sin(iTime*.25)*.5, -iTime*.2);
  vec3 rd = normalize(vec3(uv, -1.0));
  
  float d = raymarch(ro, rd);
  vec3 color = vec3(0.0);
  vec3 p = ro + rd * d;
  vec3 s = repeat(p, 2.0);
  
  int i = int(mod(iTime*.1, 3.0))+5;
  d += fractal(s, color,i);
  vec3 color2;
  fractal(s,color2,i-1);
  color *= (2.0/d);
  color = mix(color, color2, vec3(.5));

  fragColor = vec4(color, 1.0);
}

