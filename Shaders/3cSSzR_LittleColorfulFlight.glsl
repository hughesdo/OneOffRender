#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Little Colorful Flight
// Created by diatribes
// Shadertoy ID: 3cSSzR
// https://www.shadertoy.com/view/3cSSzR

#define P(z) (vec3(tanh(cos((z) * .32) * .20) * 26., \
                   tanh(cos((z) * .41) * .25) * 32., (z)))
#define N normalize

float M(vec3 p) {
    float s,l,w = 1.;
    s = 4. - length(p.xy - P(p.z).xy);    
    p.xy -= P(p.z).xy;
    p.x -= 1.5;

    for (int i; i++ < 6; p *= l, w *= l )
        p  = abs(sin(p)) - 1.,
        l = 1.5/dot(p,p);
    return min(s, length(p)/w - .01); 
}

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float T = iTime*1.2, d, i, s=.02;
    vec3  r = vec3(iResolution.xy, iResolution.y),
          p = P(T),
          Z = N( P(T+1.) - p),
          X = N(vec3(Z.z,0,-Z)),
          D = vec3((u-r.xy/2.)/r.y, 1) 
             * mat3(-X, cross(X, Z), Z);
    o-=o;
    while( s > .001)
        p += s*D,
        o.rgb += (s = M(p))*sin(p)*.2+.02;
    
    fragColor = o;
}

