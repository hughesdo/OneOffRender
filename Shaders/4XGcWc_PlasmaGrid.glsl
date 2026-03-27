#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Plasma Grid
// Created by diatribes
// Shadertoy ID: 4XGcWc
// https://www.shadertoy.com/view/4XGcWc

#define MAX_STEPS 30
#define MAX_DIST 60.0
#define SURFACE_DIST .1

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
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

vec3 getColor(float amount) {
  vec3 color = vec3(0.8, 0.8, 0.9) + vec3(0.5)
       * cos(vec3(amount*.1, 0.0,sin(amount)) + amount * vec3(1.0, 0.7, 0.4	));
  return color * amount;
}

vec3 repeat(vec3 p, float c) {
  return mod(p,c)-0.5*c;
}

float sdBoxFrame( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float scene(vec3 p) {
  vec3 s = repeat(p - vec3(0.0, 0.0, -5.0), 4.0);
  float dist = sdBoxFrame(s, vec3(1.1,1.3,1.5), 0.025 );
  float sphereDist = length(s) - 0.5;
  float distance = min(dist, sphereDist);
  return distance;
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

vec3 plasma(vec2 uv) {
    float t = iTime / 2.0;
    uv *= 10.;
    float r = distance(uv, vec2(sin(t), sin(t)));
    float g = distance(uv, vec2(0, 3.));
    float b = distance(uv, vec2(r, sin(t)*25.));
    float value = abs(sin(r+t) + sin(g+t) + sin(b+t) + sin(uv.x+t) + cos(uv.y+t));
    value = sqrt(value);
    r/=value;
    g/=value;
    b/=value;
    return vec3(r,g,b);
}

void main()
{
  vec2 u = gl_FragCoord.xy;
  vec2 uv = u.xy/iResolution.xy-.5;
  uv.x *= iResolution.x / iResolution.y;
  vec3 ro = vec3(0.0, 0.0, -iTime*4.0);
  vec3 rd = normalize(vec3(uv, -1.0));
  float d = raymarch(ro, rd);
  vec3 color = vec3(0.0);
  if(d<MAX_DIST) {
    vec3 p = ro + rd * d;
    vec3 normal = getNormal(p);
    vec3 lightDirection = normalize(ro - p);
    float diffuse = max(dot(normal, lightDirection), .0);
    color = plasma(p.xy) * diffuse;
  } else {
    color = vec3(0.);
  }
  fragColor = vec4(color,1.);
}

