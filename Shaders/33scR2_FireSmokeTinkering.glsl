#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Fire & Smoke Tinkering
// Created by diatribes
// Shadertoy ID: 33scR2
// https://www.shadertoy.com/view/33scR2

#define T iTime

vec4 smoke(vec2 u) {
    float i,d,s,t = iTime;
    vec3 p;
    vec4 o = vec4(0);
    for(; i++<64.;
        p *= vec3(.3, .6, 1),
        d += s = .3+.2*abs(p.y-2.),
        o += 1e1/s)
        for(p = vec3(u * d, d - t*1e1),
            s = .01; s < 4.; s += s )
            p.yz -= cos(p.zx*.05),
            p.yz -= abs(dot(sin(.02*p.z*s+.03*p.x+t + .5*p / s ), vec3(.1+s)));
    return o/2e3;
}

vec4 fire(vec2 u) {
    float i, d, s, n;
    vec3 p;
    vec4 o = vec4(0);
    mat2 r = mat2(cos(.3*T+vec4(0,33,11,0)));
    for(; i++<64.; ) {
        p = vec3(u * d, d);
        p += cos(p.z+T+p.yzx*.5)*.6;
        s = p.y-2.;
        p.yz *= r;
        for (n = 1.6; n < 32.; n += n )
            s += abs(dot(sin( p.z + T + p*n ), vec3(2.5))) / n;
        d += s = .01 + abs(s)*.1;
        o += 1. / s;
    }
    return vec4(6,2,1,1) * o * o / d / 2e5;
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    u = (u-iResolution.xy/2.)/iResolution.y;
    o = mix(fire(u), smoke(u), .92);
    o = tanh(o);
    
    fragColor = o;
}

