#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Core Burn
// Created by diatribes
// Shadertoy ID: 332yWD
// https://www.shadertoy.com/view/332yWD

#define T iTime

vec4 fire(vec2 u) {
    float i, d, s, n;
    vec3 p;
    vec4 o = vec4(0);
    for(; i++<1e2; ) {
        p = vec3(u * d, d);
        p += cos(p.z+T+p.yzx*.5)*.6;
        s = 6.-length(p.xy);
        p.xy *= mat2(cos(.3*T+vec4(0,33,11,0)));
        for (n = 1.6; n < 32.; n += n )
            s -= abs(dot(sin( p.z + T + p*n ), vec3(1.12))) / n;
        d += s = .01 + abs(s)*.1;
        o += 1. / s;
    }
    return vec4(5,2,1,1) * o * o / d;
}

vec4 heart(vec2 u) {
    float i, d, s, n;
    vec3 p;
    vec4 o = vec4(0);
    for(o = vec4(0); i++<1e2;
        d += s = .0001+.25*abs(s),
        o += 1./s)
        for (p = vec3(u * d, d - 6.),
             p += .1*(cos(3.*T+dot(cos(3.*T+p+cos(.3*p)), p) *  p )),
             s = length(p) - 1.,
             n = .01; n <.5; n += n )
                 s -= abs(dot(cos(T+p/n),sin(4.*p.yzx)*.2)) * n;
    return vec4(9,1,1,0)*o*o/d/1e4;
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    u = (u-iResolution.xy/2.)/iResolution.y;
    o = mix(fire(u), heart(u), .5);
    o = tanh(o/1e6);
    
    fragColor = o;
}

