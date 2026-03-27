#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Lava Flight
// Created by diatribes
// Shadertoy ID: 3f2XRD
// https://www.shadertoy.com/view/3f2XRD

#define P(z) (vec3(tanh(cos((z) * .26) * .35) * 13., \
                   tanh(cos((z) * .33) * .45) * 13., (z)))
#define N normalize
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define T (iTime * 1.)


float M(vec3 p) {
    float s,l,w = 1.;
    float wave = .2*sin(T*.93)+sin(2.*T+p.z*4.1)*.26 +
                 sin(cos(4.*T+p.z*3.3)*.10)*.31 +
                 tanh(cos(8.*T+p.z*6.7)*.16)*.15;
    
    s = 6. - length(p.xy - P(p.z).xy);
    p.xy -= P(p.z).xy - abs(s)*.5;
    p.x -= 1.75 + wave*.7;
    p.y += wave*.5;
    for (float i; i++ < 6.; p *= l, w *= l )
        p  = abs(sin(p)) - 1.,
        l = 1.6/dot(p,p);

    s = min(s, length(p)/w - .001);
    return s; 
}

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float d, s=.02;
    vec3  r = vec3(iResolution.xy, iResolution.y),
          p = P(T),
          Z = N( P(T+1.) - p),
          X = N(vec3(Z.z,0,-Z)),
          D = vec3(rot(sin(iTime*.3))*(u-r.xy/2.)/r.y, 1) 
             * mat3(-X, cross(X, Z), Z);
    o-=o;
    while( s > .001)
        p += s*D,
        o.rgb += (s = M(p))*sin(p)*.05+(sin(p.z)*.01+.02);
    o.rgb *= .1/vec3(.1,.4,.95);
    
    fragColor = o;
}

