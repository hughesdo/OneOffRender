#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Spiral Overload
// Created by diatribes
// Shadertoy ID: 33KSWz
// https://www.shadertoy.com/view/33KSWz

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i, d ,s,n,t = iTime;
    vec3 p;
    u = (u-iResolution.xy/2.)/iResolution.y;
    u += vec2(cos(t*.6)*.2, sin(t*.4)*.25);
    for(o*=i; i++<1e2;d += s = .001+abs(s)*.7, o += 1./s)
        for (p = vec3(u * d, d+t*4.),
             p.xy *= mat2(cos(.2*t+p.z*.1+vec4(0,33,11,0))),
             p.xy /= sin(p.x + cos(p.y)),
             s = tanh(1.+p.y),
             n = 2.; n < 16.; n *= 1.42 )
                 s += abs(dot(step(1./d, cos(t+p.z+p*n)), vec3(.4))) / n;
    o = tanh(mix(o=vec4(8,1,3,4)*o / 2e3 /d, o.xzyw, smoothstep(0.,1.,length(u))));
    
    fragColor = o;
}

