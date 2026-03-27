#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Star Field Flight [351]
// Created by diatribes
// Shadertoy ID: 3ft3DS
// https://www.shadertoy.com/view/3ft3DS

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,d,s,t = iTime*3.;
    vec3  p;    
    u = ((u-iResolution.xy/2.)/iResolution.y);
    for(o*=i; i++<80.;o += (1.+cos(d+vec4(4,2,1,0))) / s)
        p = vec3(u * d, d + t),
        p.xy *= mat2(cos(tanh(sin(t*.1)*4.)*3.+vec4(0,33,11,0))),
        p.xy -= vec2(sin(t*.07)*16., sin(t*.05)*16.),
        p += cos(t+p.y+p.x+p.yzx*.4)*.3,
        d += s = length(min( p = cos(p) + cos(p).yzx, p.zxy))*.3;
    o = tanh(o / d / 2e2);
    
    fragColor = o;
}
/*
    Playing with the laser field Xor demonstrates here:
    https://www.shadertoy.com/view/tct3Rf
*/

