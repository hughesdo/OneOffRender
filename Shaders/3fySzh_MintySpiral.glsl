#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Minty Spiral
// Created by diatribes
// Shadertoy ID: 3fySzh
// https://www.shadertoy.com/view/3fySzh

void main() 
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,d;
    vec3 p;
    u = (u-iResolution.xy/2.)/iResolution.y;
    for(o*=i; i++<60.; o += 1.+cos(p.zxxy))
        p = vec3(u * d, d),
        p.xy *= mat2(cos(iTime+.3*p.z+vec4(0,33,11,0))),
        d += .005+.3*(abs(fract(p.x)-.5)+1.+cos(p.y));
    o = tanh(o*o*o/d/2e4);
    
    fragColor = o;
}

