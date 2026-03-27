#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Bright Color Flight
// Created by diatribes
// Shadertoy ID: 3cSXzG
// https://www.shadertoy.com/view/3cSXzG

#define P(z) vec3(tanh(cos((z) * .24) * .7) * 12., \
                  tanh(cos((z) * .40) * .4) * 6., (z))
#define T iTime*2.5

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.002,l,w=1.,d=0.;
    vec3  r = vec3(iResolution.xy, iResolution.y),
          e = vec3(.001,0,0),
          p = P(T),ro=p,
          Z = normalize( P(T+1.) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3((u-r.xy/2.)/r.y, 1) 
             * mat3(-X, cross(X, Z), Z);
    o -= o;;
    for(int i = 0; i++ < 160 && s > .001;) {
        p = ro+D*d;
        p.xy -= P(p.z).xy;
        s = 2.75 - length(p.xy);
        p.x -= 4.;
        p.y -= 1.;
        p = clamp(p, -2.0, 2.0) * 2.0 - p;
        p.y = clamp(p.y, -1.0, 1.0) * 2.0 - p.y;
        w = .5;
        for (int j; j++ < 8; p *= l, w *= l )
            p  = abs(sin(p)) - 1.,
            l = 1.6/dot(p,p);
        o.rgb += (abs(sin(p))*.05);
        s = min(s, length(p)/w-.001);
        d += s;
    }
    o.rgb *= exp(-d/3.);
    o.rgb = pow(o.rgb, vec3(.45));
    
    fragColor = o;
}

