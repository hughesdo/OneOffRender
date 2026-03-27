#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Digital Downpour
// Created by diatribes
// Shadertoy ID: 3X2cDc
// https://www.shadertoy.com/view/3X2cDc

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,d=1e1,s,r,t = iTime;
    vec3 p;
    u = (u-iResolution.xy/2.)/iResolution.y;
    for(o*=i; i++<32.;
        p *= vec3(.3, .6, 1),
        d += s = .05+.6*abs(4. - length(p.xy)),
        o += vec4(2,9,1,0)/s + 1.5*vec4(1,2,3,0)/length(vec2(u.y-.3,  u.x))/s)
        for(p = vec3(u * d, d - 1e1),
            p.yz *= mat2(cos(1.57+vec4(0,33,11,0))),
            p.z += t*6.,
            s = .1; s < 3.; s += s )
            p.yz += abs(dot(round(sin(p.x+p.y+t + .3*p / s )), vec3(4))) * s;
    o = tanh(.5*o*o/5e5);
    
    fragColor = o;
}

