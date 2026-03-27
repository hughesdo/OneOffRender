#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// 2d Fractal Experiment
// Created by diatribes
// Shadertoy ID: 4XdfW7
// https://www.shadertoy.com/view/4XdfW7

float fractal(vec3 p, out vec3 rgb){
  float m = 1.;
  for (int i = 0; i < 4; i++) {
    float n = abs(p.x*p.y*p.z);
    p = abs(p)/clamp(n,.2,1.)-1.75;
    m = abs(min(p.x,min(p.y,p.z)));
  }
  m = exp(-2. * m)*2.;
  rgb=vec3(2.0, p.xy) * m;
  return length(rgb);
}

float scene(vec3 p, out vec3 rgb) {
  return fractal(p, rgb);
}

void main()
{
  vec2 u = gl_FragCoord.xy;
  vec2 uv = u.xy/iResolution.xy-.5;
  uv.x *= iResolution.x / iResolution.y;
  uv *= 2.25;

  float z = 1.0+iTime*.001;
  vec3 ro = vec3(0.0, 0., z);
  vec3 rd = normalize(vec3(uv*1.5, -1.0));
  float s = sin(iTime*.15);
  float c = cos(iTime*.15);
  mat2 m = mat2(c, s, -s, c);
  rd.xy *= m;
  
  vec3 rgb;
  float d = scene(ro + rd, rgb);
  vec3 color = vec3(0.0);
  color = rgb;
  fragColor = vec4(color, 1.0);
}

