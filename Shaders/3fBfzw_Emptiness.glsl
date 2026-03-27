#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Emptiness
// Created by diatribes
// Shadertoy ID: 3fBfzw
// https://www.shadertoy.com/view/3fBfzw

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,d, s,c,w,n,t = iTime*.7;
    vec3 q,p;
    u = (u-iResolution.xy/2.)/iResolution.y+cos(t*.2)*vec2(.4,.1);;
    for(o=vec4(0); i++<1e2;
        w = .6*max(q.y, .001),
        c = .1+.2*abs(p.y-16.),
        d += s = min(c,w),
        o += w < c ? .005/s : .6/s)
        for (q = p = vec3(u * d, d + t*2.),p.x += t,
             n = .05; n < 6.; n += n )
             p += abs(dot(cos(.2*t + .4*p / n ), vec3(.8))) * n,
             q.yz += abs(dot(cos(q.z*.01 + .18*q / n ), vec3(1.3))) * n;
    o = tanh(o/2e3/length(u-.4));
    
    fragColor = o;
}

