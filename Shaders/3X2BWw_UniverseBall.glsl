#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Universe Ball
// Created by diatribes
// Shadertoy ID: 3X2BWw
// https://www.shadertoy.com/view/3X2BWw

// inspired by @Jaenam's gem shaders
// e.g., https://www.shadertoy.com/view/t3SyzV

// can play with color here
#define PALETTE vec3(6,4,2)

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,s,e, t=iTime*.05, d;
    vec3  p, c;
    u = (u+u-iResolution.xy)/iResolution.y;
    for(; i++ < 1e2 && d < 1e1;
        d += s = min(7.*max(.04*e, .001), max(s, dot(abs(p-floor(p)-.5), vec3(.04)))),
        c +=(1.+cos(p.z+PALETTE))/s) 
        p = vec3(u * d, d - 5.),
        s = length(p)-2.5,
        e = p.y+2.3,
        p.xy *= mat2(cos(t+p.z*1.3+vec4(0,33,11,0))),
        p += cos(t+t+p.zxy)+cos(t+p.yzx*3.),
        p += cos(1e1*t+dot(cos(1e1*t+p), p) *  p);
        
    o.rgb = tanh(c*c/d/2e7/length(u-.6));
    
    fragColor = o;
}

