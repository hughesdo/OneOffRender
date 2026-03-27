#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Lyfe
// Created by diatribes
// Shadertoy ID: 3XlyDf
// https://www.shadertoy.com/view/3XlyDf

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i, s = 4.;
    vec2 q, p = u.xy/iResolution.y-.5;
    for(o = vec4(0); i++ < 32.; o += length(q*q / (s *= 1.3)))
      p *= mat2(cos(1.+vec4(0,33,11,0))),
      q += cos(2.*iTime - dot(cos(4.*iTime+p+cos(q)), p) + s *  p + i*i)+sin(s*p+q.yx);
    o = tanh(o/1e1);
    
    fragColor = o;
}

