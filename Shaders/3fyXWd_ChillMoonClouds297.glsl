#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Chill Moon Clouds [297]
// Created by diatribes
// Shadertoy ID: 3fyXWd
// https://www.shadertoy.com/view/3fyXWd

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,a,d,s,t=iTime;
    vec3  p;    
    u = (u+u-iResolution.xy)/iResolution.y;
    for(o*=i; i++<64.;
        d += s = .05 + abs(s)*.2,
        o += 1./s)
        for (p = vec3(u * d, d + t),
            s = 8. - length(p.xy * sin(p.y*.25)),
            a = .05; a < 2.; a += a)
            p += cos(t+p.yzx)*.03,
            s -= abs(dot(sin(.5*t+.1*p.z+p * a * 12.), .05+p-p)) / a;
    o = tanh(o*o / 3e6 / dot(u,u));
    
    fragColor = o;
}

