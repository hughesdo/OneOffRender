#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Bitflip Pond Flight
// Created by diatribes
// Shadertoy ID: 3cKcR1
// https://www.shadertoy.com/view/3cKcR1

#define T (sin(iTime*.6)*96.+iTime*128.)
#define P(z) (vec3(cos((z)*.005)*164.+cos((z) * .005)  *32., \
                   0, (z)))
#define R(a) mat2(cos(a+vec4(0,33,11,0)))
#define N normalize

float map(vec3 p) {
    float n,s =24.-p.y;
    for(n = .02; n < 1.; n += n+n)
        s -= abs(dot(round(sin(.05*p/n+.02*p.yzx/n)), vec3(n*6.)));     
    return s ;
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.002,d=1.,i=0.;
    vec3  r = vec3(iResolution.xy, iResolution.y);
    
    u = (u-r.xy/2.)/r.y;
    
    if (abs(u.x) > .7) { o = vec4(0); fragColor = o; return; }
    u.y -=.35;
    
    o = vec4(0);
    
    vec3  e = vec3(.001,0,0),
          p = P(T),ro=p,
          Z = N( P(T+2.) - p),
          X = N(vec3(Z.z,0,-Z)),
          D = vec3(R(sin(T*.01)*.3)*u, 1) 
             * mat3(-X, cross(X, Z), Z);
    
    for(; i++ < 64. && d < 5e2;)
        p = ro + D * d,
        d += s = map(p) * .5,
        o += (1.+cos(.5*p.y+vec4(6,4,2,0)))/max(s, .001);
    
    o = tanh(vec4(1,2,5,0)*o / 1e5);
    
    fragColor = o;
}

