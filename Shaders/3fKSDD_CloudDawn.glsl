#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Cloud Dawn
// Created by diatribes
// Shadertoy ID: 3fKSDD
// https://www.shadertoy.com/view/3fKSDD

// The sky in @Xor's "Runner" made me want to make a nice
// sun sky :)
// https://www.shadertoy.com/view/wfGXDh

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,a,d,s,t=iTime;
    vec3  p;    
    u = (u-iResolution.xy/2.)/iResolution.y;
    for(o*=i; i++<1e2;
        d += s = .06 + abs(s)*.5,
        o += (vec4(5,2,1,0) - cos(p.y))*s/(1.+d))
        for (p = vec3(u * d, d + t*4.),
            s = 5.+p.y,
            a = .05; a < 2.; a += a)
            p += cos(t+p.yzx)*.03,
            s -= abs(dot(sin(.5*t+p * a * 6.), vec3( .06))) / a;
    u.y -= .1;
    o = tanh(o / 5e1 / length(u));
    
    fragColor = o;
}

