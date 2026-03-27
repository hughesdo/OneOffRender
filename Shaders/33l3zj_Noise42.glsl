#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Noise42
// Created by diatribes
// Shadertoy ID: 33l3zj
// https://www.shadertoy.com/view/33l3zj

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float T=iTime*.08,d=0.,a = .5, f = tanh(sin(T*20.)*.2);
    u = (u-iResolution.xy/2.)/iResolution.y;
    o -= o;
    for (; a < 2.5;
        d += abs(dot(sin(vec3(u+sin(T), T) * a * (24.+sin(a)*16.)),
        vec3(.025))) / a, a *= 1.4142, o.rgb+=d);
    o.rgb *= 1.25 - length(vec2(sin(T*4.)*.5+u.x-f*.3,u.y-f*.7))*1.75;
    o.rgb *= vec3(.8,0,0);
    
    fragColor = o;
}

