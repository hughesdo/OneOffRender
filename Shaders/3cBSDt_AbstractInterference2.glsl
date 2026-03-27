#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Abstract Interference 2
// Created by diatribes
// Shadertoy ID: 3cBSDt
// https://www.shadertoy.com/view/3cBSDt

#define P(z) vec3(tanh(cos((z) * .45) * .6) * 12., \
                  tanh(cos((z) * .42) * .5) * 12., (z))
#define T (iTime*.5)
#define rot(a) mat2(cos(a+vec4(0,33,11,0)))
void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.002,l,w,ws,d=0.;
    vec3  r = vec3(iResolution.xy, iResolution.y),
          p = P(T),ro=p,
          Z = normalize( P(T+1.) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3(rot(sin(p.z*.6)*1.8)*(u-r.xy/2.)/r.y, 1) 
             * mat3(-X, cross(X, Z), Z);
    o -= o;
    for(int i = 0; i++ < 120 && s > .001;) {
        p = ro + D * d;
        o.rgb += sin(p*.6+exp(l))*.03+.015;
        float g = dot(sin(p),cos(.3*T+p))+(dot(sin(.6*T+p*1.3),cos(p*2.4)));
        p.xy -= P(p.z).xy - g*.35;
        p.x -= 2.75;
        p.y += (sin(T)*.15);
        p = mod(p, 6.) - 3.;
        p = clamp(p, -.5, .5) * 2.0 - p;
        w = 2.;
        ws = .0035;
        for (int j; j++ < 8; p *= l, w *= l )
            p  = abs(sin(p)) - 1.,
            l = (1.+ws)/dot(p,p),
            ws += ws;
        s = length(p)/w;
        d += s;
    }
    o.rgb *= exp(-d/4.);
    o.rgb = pow(o.rgb, vec3(.45));
    
    fragColor = o;
}

