#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Souls of Mercy
// Created by diatribes
// Shadertoy ID: 3cSBzw
// https://www.shadertoy.com/view/3cSBzw

#define T (iTime)

float fractal(vec3 p) {
    float s,w,l;
    p.xy *= mat2(cos(.3*T+p.z-vec4(0,33,11,0)));
    p += cos(T+p.yzx*12.)*.07;
    p.y -= 1.6;
    for (s=0.,w=1.; s++ < 7.; p *= l, w *= l )
        p  = abs(sin(p))-1.,
        l = 1.3/dot(p,p);
    return length(p)/w;
}

vec4 fire(vec2 u) {
    float i, d, s, n;
    vec3 p;
    vec4 o = vec4(0);
    for(; i++<1e2; ) {
        p = vec3(u * d, d + T*4.);
        p += cos(p.z+T+p.yzx*.5)*.6;
        s = 2.+sin(T*.5)*2.-length(p.xy);
        p.xy *= mat2(cos(.3*T+vec4(0,33,11,0)));
        for (n = 1.6; n < 32.; n += n )
            s -= abs(dot(sin( p.z + T + p*n ), vec3(1.12))) / n;
        d += s = .01 + abs(s)*.1;
        o += 1. / s;
    }
    return (vec4(5,2,1,1) * o * o / d);
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.1,d=0.,i=0.;
    vec3  p;
    u = (u-iResolution.xy/2.)/iResolution.y;

    o = vec4(0);
    for(;i++ < 64.;)
        p = vec3(u * d, d),
        d += s = fractal(p),
        o += .7/max(s, .001),
        o.b += .2/max(s, .001);
    o = mix(o, fire(u)/5e1, .4);
    o = tanh(o  / 1e5 / max(length(u), .001));
    
    fragColor = o;
}

