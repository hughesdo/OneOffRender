#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Disoriented...
// Created by diatribes
// Shadertoy ID: 3cXyDH
// https://www.shadertoy.com/view/3cXyDH

#define P(z) vec3(tanh(cos((z) * .31) * .6) * 6., \
                  tanh(cos((z) * .33) * .5) * 6., (z))
#define T ((sin(iTime*.3)+iTime*.3)) * 2.5
void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.002,d=0.,i,l,w,t=iTime*4.,f=(sin(iTime*1.5)*35.+60.);
    vec3  r = vec3(iResolution.xy, iResolution.y),
        p = P(T),ro = p,
        Z = normalize( P(T+3.) - (p - vec3(
                                  P(p.z).x+tanh(cos(t * .3)*2.) * 1.8,
                                  P(p.z).y+tanh(cos(t * .5)*2.) * 1.8,
                                  1.3+T+tanh(cos(t*.125)*9.)*9.)) - p),
        X = normalize(vec3(Z.z,0,-Z)),
        D = vec3(mat2(cos(sin(p.z*.3)*.3+vec4(0,33,11,0)))*(u-r.xy/2.)/r.y, 1) 
                * mat3(-X, cross(X, Z), Z);
    for(o*=0.; i++ < f && s > .001;d += s = length(p)/w) {
        p = ro + D * d;
        p.xy -= P(p.z).xy;
        p.xy *= .5;
        p.y -= 1.5;
        w = .8;
        for (int j; j++ < 8; p *= l, w *= l )
            p  = abs(sin(p)) - 1.,
            l = 1.6/dot(p,p);
    }
    o += tanh(.8/d);
    
    fragColor = o;
}

