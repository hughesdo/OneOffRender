#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Nightmare Hall
// Created by diatribes
// Shadertoy ID: 3XXGRB
// https://www.shadertoy.com/view/3XXGRB

#define P(z) vec3(tanh(cos((z) * .31) * .6) * 6., \
                  tanh(cos((z) * .23) * .2) * 6., (z))
#define T ((sin(iTime*.5)+iTime*.5)) * 9.
#define rot(a) mat2(cos(a+vec4(0,33,11,0)))

vec3 orb(vec3 p) {
    float t = iTime*4.;
    return (p - vec3(
            P(p.z).x+tanh(cos(t * .5)*3.) * 2.5,
            P(p.z).y+tanh(cos(t * .7)*2.) * 2.5,
            1.3+T+tanh(cos(t*.125)*9.)*9.));
}

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.002,d=0.,i,l,w;
    vec3  r = vec3(iResolution.xy, iResolution.y),
          p = vec3(0,0,T),ro = p,
          Z = normalize( P(T+3.) - orb(p) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3(rot(sin(p.z*.3)*.3)*(u-r.xy/2.)/r.y, 1) 
             * mat3(-X, cross(X, Z), Z);

    o -= o;
    for(i = 0.; i++ < 80. && s > .001;) {
        p = ro + D * d;
        s = min(1. - p.y, min(p.x + 2.5, 2.5 - p.x));
        for (float a = .1; a < 2.;
            s -=  abs(dot(sin(2.*iTime+p * a * 24.)*.1, vec3(1.))) / a * .15,
            a += a); 
        p.x -= 1.5;
        p.x *= 1.5;
        p.y *= .2;
        p.y -= sin(iTime*6.)*.1;
        w = .8;
        for (int i; i++ < 6; p *= l, w *= l )
            p = clamp(p, -2.0, 2.0) * 2.0 - p,
            p  = abs(sin(p)) - 1.,
            l = 1.4/dot(p,p);
        s = min(s,length(p)/w - .001);
        o.rgb += s *.01+.02;
        d += s;
    }
    o.rgb *= vec3(d*.75,0,0);
    o.rgb *= exp(-d/2.);
    
    fragColor = o;
}

