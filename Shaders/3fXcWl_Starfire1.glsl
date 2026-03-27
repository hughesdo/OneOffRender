#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Starfire1
// Created by diatribes
// Shadertoy ID: 3fXcWl
// https://www.shadertoy.com/view/3fXcWl

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,a,d,s,t=iTime;
    vec3  p,r = vec3(iResolution.xy, iResolution.y);
    for(o*=i; i++<1e2;
        d += s = .005+abs(s) * .5,
        o += vec4(11,2.7-cos(.5*t)*.6,.8,0)/s)
        for (p = vec3(((u-r.xy/2.)/r.y+cos(t*.3)*vec2(.02,.03)) * d, d - 9.),
            s = length(p) - 5.8,
            a = 1.; a < 24.; a += a)
            p += cos(.15*t+a+p.yzx*3.)*.3,
            s -= abs(dot(sin(.14*t+p * a * 6.), .05+p-p)) / a;
    o = tanh(o / 1e4);
    
    fragColor = o;
}

