#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Electric Fog Tunnel
// Created by diatribes
// Shadertoy ID: 332XW3
// https://www.shadertoy.com/view/332XW3

#define T (iTime)
#define N normalize
#define P(z) (vec3(tanh(cos((z) * .4) * .3) * 10., \
                   tanh(cos((z) * .4) * .4) * 10., (z)))

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i, n, s, d;
    vec3 q, p, ro =  P(T),
         Z = N( P(T+1.) - ro),
         X = N(vec3(Z.z,0,-Z));
    u = (u-iResolution.xy/2.)/iResolution.y;
    
    vec3 D = vec3(u, 1) * mat3(-X, cross(X, Z), Z);
         
    o -= o;
    
    for(o *= i; i++ < 1e2;) {
        p = ro + D * d ;
        q = P(p.z);
        s = .75 - min(length(p.y  - q.x),
                  min(length(p.xy - q.xy),
                      length(p.x  - q.y)));
        for (n = .06; n < 2.;n += n)
            s -= abs(dot(sin(p * n * 32.), vec3(.01))) / n;
        s = .0005+abs(s)*.15;
            
        d += s;
        o += s;
    }

    o = tanh(o * abs(vec4(6,2,1,1) /
                     dot(cos(T+p*2.), vec3(1))) * exp(-d));
    
    fragColor = o;
}

