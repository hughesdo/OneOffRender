#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Little Gem Flight
// Created by diatribes
// Shadertoy ID: 33lGz4
// https://www.shadertoy.com/view/33lGz4

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float T=iTime, s=.002,l,w=1.,i=70.,d,f=tanh(sin(T*.5)*10.)*1.55;
    vec3 p = vec3(f,0,T),q;
    o -= o;
    while(i-- > 0. && s > .001) {
        q = p;
        w = 1.;
        for (s = 0.; s++ < 8.; q *= l, w *= l )
            q  = abs(sin(q)) - 1.,
            l = 1.2/dot(q,q)-(tanh(cos(T))*.3)*.5;
        p += (s = length(q)/w)*vec3((u-iResolution.xy/2.)/iResolution.y, 1);
        d += s;
        o.rgb += (abs(sin(q))*.035+.005)*vec3(1,f,1);
    }
    o.rgb *= exp(-d/3.);
    
    fragColor = o;
}

