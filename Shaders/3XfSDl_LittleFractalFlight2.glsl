#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Little Fractal Flight 2
// Created by diatribes
// Shadertoy ID: 3XfSDl
// https://www.shadertoy.com/view/3XfSDl

/*
    This uses the raymarcher Xor provided in his example shaders
    e.g, https://www.shadertoy.com/view/t3XXWj
*/

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 O;
    vec3 p;
    float t = iTime,i,z,d,s,w,l,j,f;
    for (O *= i; i++ < 200.;
         O += (max(sin(z*.4+t + vec4(6, 2, 4, 0)) + .7, .2) / d)) {
        p = z * normalize(vec3(u+u,0)-iResolution.xxy);
        p.z -= t/2.;
        w = 1.;
        p.xy *=  mat2(cos(sin(t*.3)*2. + vec4(0, 33, 11, 0)));
        p.y -= 1.5;
        p.xy -= tanh(sin(t*.5)*10.)*3.125;
        f = sin(p.z)*.75+1.;
        w = 1.;
        for (j=0.; j++ < 4.; p *= l, w *= l )
            p  = abs(sin(p)) - 1.,
            l = f/dot(p-vec3(.15,.75,-.1),p)+1.25;
        z += (d = length(p)/w);
    }
    O *= abs((vec4(1)) /
         dot(cos(1.6*t+p),vec3(1.)))*1.;
    O /= 1e5;
    O = (O / (O + 0.155) * 1.019);
    
    fragColor = O;
}

