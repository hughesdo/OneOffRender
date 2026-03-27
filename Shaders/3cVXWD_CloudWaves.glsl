#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Cloud Waves
// Created by diatribes
// Shadertoy ID: 3cVXWD
// https://www.shadertoy.com/view/3cVXWD

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,a,d,s,t=iTime;
    vec3  p;    
    u = (u-iResolution.xy/2.)/iResolution.y;
    for(o*=i; i++<1e2;
        d += s = .04 + abs(s)*.1,
        o += 1./s)
        for (p = vec3(u * d, d + t),
            s = 4.+p.y,
            a = .05; a < 2.; a += a)
            p += cos(t+p.yzx)*.03,
            s -= abs(dot(sin(.5*t+p * a * 6.), .05+p-p)) / a;
    u -= vec2(-.5, .4);
    o = tanh(o*o / 3e6 / dot(u,u));
    
    fragColor = o;
}

