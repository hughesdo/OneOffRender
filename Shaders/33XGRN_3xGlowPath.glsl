#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// 3x Glow Path
// Created by diatribes
// Shadertoy ID: 33XGRN
// https://www.shadertoy.com/view/33XGRN

#define P(z) vec3(sin((z) * .28)*5., sin((z) * .22)*6., (z))

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float T = iTime*2., f, d = 0., s=.002,l,w,j;
    vec3  p = P(T),q=p,
          Z = normalize( P(T+2.) - p)+sin(p)*.05,
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3((u-iResolution.xy/2.)/iResolution.y, 1) 
             * mat3(-X, cross(X, Z), Z);
    o-=o;
    for(int i = 0; i++<100 && s > .001;) {
        p = q + D * d;
        o.rgb += sin(p*.3)*.01+.01;
        s = 3.5 - length(p.xy - P(p.z).xy);
        p.xy -= P(p.z).xy;
        p.xy *= 2.;
        p.x -= 2.;
        f = sin(p.z)*.5+1.2;
        w = 1.;
        for (j=0.; j++ < 3.; p *= l, w *= l )
            p  = abs(sin(p)) - 1.,
            l = f/dot(p-vec3(.25,.75,-.1),p)+1.5;
        o.rgb += sin(p*.3)*.01+.01;
        s = min(s, length(p)/w-.005);        
        d += s;
    }
    o.rgb *= exp(-d/4.);
    
    fragColor = o;
}

