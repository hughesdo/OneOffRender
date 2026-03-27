#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Plasma Pit Tunnel
// Created by diatribes
// Shadertoy ID: 43yyDc
// https://www.shadertoy.com/view/43yyDc

#define MAX_STEPS 45
#define MAX_DIST 7.0
#define SURFACE_DIST 0.01
#define inf 1e10
#define NUM_OCTAVES 5

float rand(in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float noise(vec2 p){
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}

float fbm(vec2 x) {
	float v = 0.0;
	float a = 0.5;
	vec2 shift = vec2(100);
	for (int i = 0; i < NUM_OCTAVES; ++i) {
		v += a * noise(x);
		x = x * 2.0 + shift;
		a *= 0.5;
	}
	return v;
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
  p = (1.0 * vec4(p, 1.0)).xyz;
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
  vec3 ro = vec3(0.0, 0.0, -iTime*2.0);
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

