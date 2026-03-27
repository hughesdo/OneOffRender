#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// 0xff0000
// Created by diatribes
// Shadertoy ID: 3ffcD8
// https://www.shadertoy.com/view/3ffcD8

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,a,d,s,t=.4*iTime;
    vec3  p;    
    u = (u+u-iResolution.xy)/iResolution.y;
    for(o*=i; i++<64.;
        d += s = .01 + abs(s) * .4,
        o += s*d, o.r+=d/s)
        for (p = vec3(u * d, d + t),
            s = min(cos(p.z), 6. - length(p.xy * sin(p.y*.6))),
            a = .8; a < 16.; a += a)
            p += cos(t+p.yzx)*.1,
            s += abs(dot(sin(t+.2*p.z+p * a), .6+p-p)) / a;
    o = tanh(o / 2e4 * length(u));
    
    fragColor = o;
}

