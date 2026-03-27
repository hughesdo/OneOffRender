#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Color Ripples [273]
// Created by diatribes
// Shadertoy ID: 33jSDc
// https://www.shadertoy.com/view/33jSDc

/*
    Inspired by Xor's recent raymarchers with comments!
    https://www.shadertoy.com/view/tXlXDX
*/

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,d,s;
    for(o*=i; i++<1e2; ) {
        vec3 p = d * normalize(vec3(u+u,0) - iResolution.xyx );
        for (s = .1; s < 1.;
            p -= dot(sin(p * s * 16.), vec3(.01)) / s,
            p.xz *= mat2(cos(.3*iTime+vec4(0,33,11,0))),
            s += s);
        d += s = .01 + abs(p.y);
        o += (1.+cos(d+vec4(4,2,1,0))) / s;
    }
    o = tanh(o / 6e3);
    
    fragColor = o;
}

