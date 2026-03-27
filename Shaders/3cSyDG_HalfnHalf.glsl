#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Half n' Half
// Created by diatribes
// Shadertoy ID: 3cSyDG
// https://www.shadertoy.com/view/3cSyDG

#define R(a) mat2(cos(a+vec4(0,33,11,0)))

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,s,
          d,
          t=iTime;
    vec3  p;
    
    u =(u+u-iResolution.xy)/iResolution.y;
    
    o = vec4(0);
    for (i = 0.; i < 100.; ++i) {
        
        // raymarch, calculate position
        p = vec3(u * d, d + 120.);
      
        // move forward and backward
        p.z += sin(.1*t)+sin(t*.2);
        
        // rots
        p.xy *= R(.1*t+p.z*.3);
        p.yz *= R(.05*p.y);
        
        // accumulate distance
        d += s = dot(abs(p-floor(p)-.5), vec3(.12));
        
        // accumulate brightness
        o += (u.x < u.y)? (1.+cos(p.z*vec4(6,2,4,0)))/s : vec4(1)/s,
        o += abs(.1/(u.x-u.y));
    }
    
    // tonemap, tint, brightness
    o = tanh(o*o/9e6);
    
    fragColor = o;
}

