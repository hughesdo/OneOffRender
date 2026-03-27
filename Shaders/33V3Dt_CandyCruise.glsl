#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Candy Cruise
// Created by diatribes
// Shadertoy ID: 33V3Dt
// https://www.shadertoy.com/view/33V3Dt

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i, d, s=.1, n, t=iTime;
    vec3 p;
    u = (u-iResolution.xy/2.)/iResolution.y;
    
    u += vec2(cos(t*.3)*.3, cos(t*.15)*.2);
    
    for(o*=i; i++<1e2;
        d += s = (.001+abs(s)*.5),
        o += (1.+cos(.06*p.z+vec4(3,1,0,0)))/s)
        for (p = vec3(u * d, d + t+t),
             s = (4.+cos(p.z*.3)*3.) - length(p.xy),
             p.xy *= mat2(cos(p.z*.05+vec4(0,33,11,0))),
             p.x = 2.- abs(sin(p.z*.5))*sin(p.x),
             s = max(s, max(sin(p.y) , cos(p.x))),
             n = .5; n < 4.; n += n )
                 s -= abs(dot(sin(.11*t+p*n), vec3(.2))) / n,
                 s += abs(dot(sin(.12*t+p*n), vec3(.3))) / n;
                 
    o = tanh(o/1e4);
    
    fragColor = o;
}

