#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// 2D Fractal Experiment
// Created by diatribes
// Shadertoy ID: 4XcBWM
// https://www.shadertoy.com/view/4XcBWM

vec3 fractal(vec3 p){
  float z = p.z;
  float m = 1.;
  for (int i = 0; i < 5; i++) {
        float n = abs(p.x*p.y*p.z);
        p = abs(p)/clamp(n,.2,1.)-1.75;
        m = abs(min(p.x,min(p.y,p.z)));
    }
    m = exp(-2. * m)*2.;
    vec3 col=vec3(1.0, p.xy) * m;
    return col;
}

void main(){
    vec2 u = gl_FragCoord.xy;
    float t = iTime / 2.0;
    vec2 uv = u.xy / iResolution.xy - .5;
    uv.x *= iResolution.x/iResolution.y;
    vec3 p = vec3(uv.xy, sin(iTime*.1));
    vec3 color = fractal(p);
    fragColor = vec4 (color, 1.0);
}

