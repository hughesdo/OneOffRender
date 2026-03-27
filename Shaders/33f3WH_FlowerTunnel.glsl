#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Flower Tunnel
// Created by diatribes
// Shadertoy ID: 33f3WH
// https://www.shadertoy.com/view/33f3WH

#define P(z) vec3(sin((z) * .2)*5., sin((z) * .2)*6., (z))

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float T = iTime*4., f, d = 0., s=.002,l,w,j;
    vec3  p = P(T),q=p,
          Z = normalize( P(T+3.) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3((u-iResolution.xy/2.)/iResolution.y, 1) 
             * mat3(-X, cross(X, Z), Z);
    o-=o;
    for(int i = 0; i++<100 && s > .001;) {
        p = q + D * d;
        o.rgb += sin(p*.3)*.01+.01;
        p.xy -= P(p.z).xy;
        p.xy *= .5;
        p.x -= 1.5;
        f = .9+(sin(p.z*.1)*.15+.15);
        w = .04;
        for (j=0.; j++ < 6.; p *= l, w *= l )
            p  = abs(sin(p)) - 1.,
            l = f/dot(p-vec3(.45,.35,-.1),p)+1.5;
        o.rgb += sin(p*.3)*.04+.015;
        s = length(p)/w;        
        d += s;
    }
    o.rgb = pow((2. - o.rgb) * exp(-d/5.),vec3(.45));
    
    fragColor = o;
}

