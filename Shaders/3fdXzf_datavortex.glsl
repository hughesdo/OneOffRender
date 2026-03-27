#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// data vortex
// Created by diatribes
// Shadertoy ID: 3fdXzf
// https://www.shadertoy.com/view/3fdXzf

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i, d, s, n, t=-iTime*.2;
    vec3 p;
    u = (u-iResolution.xy/2.)/iResolution.y;
    for(o*=i; i++<1e2; ) {
        p = vec3(u * d, d + t*32.)*.5;
        p.xy *= mat2(cos(p.z*.3+vec4(0,33,11,0))),
        s = cos(p.y-t)+cos(p.x/t)+cos(p.x+t);
        p.xy += cos(t+vec2(.05,.09)*p.z)*8.;
        p.xy *= mat2(cos(2.*t+vec4(0,33,11,0)));
        for (n = 1.5; n < 16.; n += n )
            s -= abs(dot(step(.3, sin(t+p*n )), vec3(1))) / n;
        d += s = .01 + abs(s)*.4;
        o += 1. / s;
    }
    o = tanh(vec4(3,9,2,1)*o*o / d / 9e5);
    
    fragColor = o;
}

