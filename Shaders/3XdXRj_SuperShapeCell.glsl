#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Super Shape Cell
// Created by diatribes
// Shadertoy ID: 3XdXRj
// https://www.shadertoy.com/view/3XdXRj

/*
    Tinkering with the super shape I've seen in @mrange shaders
    e.g:
        https://www.shadertoy.com/view/3X3SzS
*/

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s, i, d, e, T = iTime;
    vec3  p,r = vec3(iResolution.xy, iResolution.y);
    for(o*=i; i++ < 80.; o += 1. / max(s+e, .01) )
        p = vec3( (u+u - r.xy) / r.y*d, d - 1. ),
        e = length(p - vec3(
                sin(sin(T*3.5)+T*.7)*.8,
                sin(sin(T*1.3)+T*.5)*.8,
                2.+cos(T*.5)*.8))-.05,
        p.xz *= mat2(cos(T*.4+vec4(0,33,11,0))),
        p += abs(dot(sin(p * 256.), .002+p-p)),
        d += s = 1e-5+abs(min(min(e,1.), pow(dot(p=p*p*p*p,p),.125) -.45))*.9;
    o = tanh((2.+cos(.3*T+vec4(3,1,0,0)))*o/1e2);
    
    fragColor = o;
}

