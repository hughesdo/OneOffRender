#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Plasma Bath House
// Created by diatribes
// Shadertoy ID: 4XcBWj
// https://www.shadertoy.com/view/4XcBWj

#define GAMMA 2.2
#define MAX_STEPS 100
#define MAX_DIST 100.0
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
  float da = sdBox(p.xyz, vec3(inf, s, s));
  float db = sdBox(p.yzx, vec3(s, inf, s));
  float dc = sdBox(p.zxy, vec3(s, s, inf));
  return min(da, min(db, dc));
}

float scene(vec3 p, out vec3 rgb) {
  vec3 s = repeat(p - vec3(0.0, 0.0, -1.0), 12.0);
  float cross = sdCross(s, 1.5);
  float plane = p.y+5.0;
  float d = cross;
  vec2 uv = p.xy*.015;
  float z=20.;
  float r=distance(uv+d,vec2(sin(iTime),sin(iTime)));
  float g=distance(.5*d+z*uv,vec2(0.,r));
  float b=distance(.5*d-z*uv,vec2(g,sin(iTime)*2.));
  if (plane<d) {
    float v = (abs(sin(r)+sin(g)+sin(b)))*5.;
    rgb = vec3(.2,.0,.2)+vec3(r/v,g/v,b/v);
  } else {
    float v = (abs(sin(r)+sin(g)+sin(b)))*5.;
    rgb = vec3(r/v,g/v,b/v);
  }
  return min(d, plane);
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
  float time = iTime;
  vec2 uv = u.xy/iResolution.xy-.5;
  uv.x *= iResolution.x / iResolution.y;
  vec3 ro = vec3(sin(sin(iTime*.5)), sin(time*.5)*4.25, -time*16.0);
  vec3 rd = normalize(vec3(uv, -1.0));
  float sa = -sin(iTime);
  float ca = cos(iTime);
  mat2 m = mat2(sa,-ca,ca,sa);
  rd.xz*=m;
  
  vec3 rgb;
  float d = raymarch(ro, rd, rgb);
  vec3 color = vec3(0.0);
  if(d<MAX_DIST) {
    vec3 p = ro + rd * d;
    vec3 normal = getNormal(p);
    vec3 lightDirection = normalize(ro - p);
    float diffuse = max(dot(normal, lightDirection), .5);
    color = rgb * diffuse;
  } else {
    color = vec3(0.);
  }
  color = vec3(pow(color, vec3(1.0/GAMMA))) * (.75 - d  / float(MAX_STEPS));
  fragColor = vec4(color,1.);
}

