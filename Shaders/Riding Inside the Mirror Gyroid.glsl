#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

#define t (2. * iTime)
#define PI 3.14159265358979
#define TAU (2. * PI)
#define EPSILON  .01
#define MAX_DIST 100.

#define min2(a,b) (a.x < b.x ? a : b)
#define max2(a,b) (a.x > b.x ? a : b)
#define pos(n) ((n) * .5 + .5)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

vec3 cos_palette(vec3 a, vec3 b, vec3 c, vec3 d, float x) {
  return a + b * cos(TAU * (c * x + d));
}

vec3 palette(float x) {
  return cos_palette(vec3(.5), vec3(.5), vec3(1., 1., .5), vec3(.8, .9, .3), x);
}

vec2 path(float x) {
  return vec2(
    2. * sin(.2 * x),
    2. * cos(.15 * x)
  );
}

float gyroid(vec3 p, float scale) {
  return dot(scale * sin(p), scale * cos(p.yzx));
}

vec2 sdf(vec3 p) {
  vec2 di = vec2(MAX_DIST, -1.);
  p.xy -= path(p.z);
  float tunnel = length(p.xy) - 3.;
  tunnel += sin(.8 * p.x) * sin(.9 * p.y) * sin(.8 * p.z) * .1;
  float gyr = gyroid(p, pos(sin(.4 * t)) * .3 + .5);
  gyr = abs(gyr) - pos(sin(.5 * t)) * .2 - .1;
  gyr = max(gyr, -tunnel);
  di = min2(di, vec2(gyr, 1.));
  return di;
}

vec2 trace(vec3 ro, vec3 rd, int steps) {
  vec3 p = ro;
  vec2 di = vec2(-1.);
  float td = 0.;
  for (int i = 0; i < steps && td < MAX_DIST; i++) {
    di = sdf(p);
    if (di.x < EPSILON)
      return vec2(td, di.y);
    p += di.x * rd;
    td = distance(ro, p);
  }
  return vec2(-1.);
}

vec3 get_normal(vec3 p) {
  vec2 e = EPSILON * vec2(1., -1.);
  return normalize(
    e.xyy * sdf(p + e.xyy).x +
    e.yxy * sdf(p + e.yxy).x +
    e.yyx * sdf(p + e.yyx).x +
    e.xxx * sdf(p + e.xxx).x
  );
}

float diffuse(vec3 p, vec3 n, vec3 lo) {
  return max(0., dot(normalize(lo - p), n));
}

float specular(vec3 rd, vec3 n, vec3 lo) {
  return pow(max(0., dot(normalize(rd + lo), n)), 128.);
}

vec3 get_camera(vec2 uv, vec3 ro, vec3 ta) {
  vec3 f = normalize(ta - ro),
       r = normalize(cross(vec3(0., 1., 0.), f)),
       u = cross(r, f);
  return normalize(f + uv.x * r + uv.y * u);
}

vec3 render(vec2 uv) {
  vec3 ro = vec3(1., 1., 1.5 * t),
       ta = ro + vec3(0., 0., 1.);
  ro.xy += path(ro.z);
  ta.xy += path(ta.z);
  vec3 rd = get_camera(uv, ro, ta);
  vec2 swivel = path(ta.z);
  rd.xy *= rot(swivel.x/32.);
  rd.yz *= rot(swivel.y/16.);
  vec3 lo = ta,
       c  = vec3(0.);
  vec2 tdi = trace(ro, rd, 128);
  if (tdi.x > 0.) {
    vec3 p = ro + rd * tdi.x,
         n = get_normal(p);
    c = palette(p.z * .1) * (diffuse(p, n, lo) + specular(rd, n, lo));
    vec3 ro_refl = p + 2. * EPSILON * n,
         rd_refl = normalize(reflect(rd, n));
    vec2 tdi_refl = trace(ro_refl, rd_refl, 64);
    if (tdi_refl.x > 0.) {
      vec3 p_refl = ro_refl + rd_refl * tdi_refl.x,
           n_refl = get_normal(p_refl);
      c += palette(p_refl.z * .1) * (diffuse(p_refl, n_refl, lo) + specular(rd_refl, n_refl, lo));
    }
  }
  return c;
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

	vec2 uv = vec2(2. * fragCoord.xy - iResolution.xy)
            / max(iResolution.x, iResolution.y);
	vec3 c = vec3(0.);
  
    c = render(uv);
    c = pow(c, vec3(1./2.2));
	fragColor = vec4(c, 1.);
}