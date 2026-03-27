#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Thursday Turbo Tunnel
// Created by diatribes
// Shadertoy ID: 3cBXDD
// https://www.shadertoy.com/view/3cBXDD

#define P(z) vec3(tanh(cos((z) * .2) * .5) * 16., \
                  tanh(cos((z) * .3) * .6) * 12., (z))
#define T iTime*2.5
#define rot(a) mat2(cos(a+vec4(0,33,11,0)))
void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.02,l,w=1.;
    vec3  r = vec3(iResolution.xy, iResolution.y),
          p = P(T),q,
          Z = normalize( P(T+1.) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3(rot(sin(p.z*.4)*.9)*(u-r.xy/2.)/r.y, 1) 
             * mat3(-X, cross(X, Z), Z);
    o -= o;;
    for(int i = 0; i++ < 150 && s > .001;) {
        q = p;
        q.xy -= P(q.z).xy;
        q.x -= 6.;
        q.xy *= 2.;
        w = 1.;
        q = clamp(q, -2.0, 2.0) * 2.0 - q;
        for (int j; j++ < 8; q *= l, w *= l )
            q  = abs(sin(q)) - 1.,
            l = 1.65/dot(q,q);
        p += (s = length(q)/w)*D;
        o.rgb += (abs(sin(p*.5))*.01+.001);
    }
    o.rgb = mix(o.rgb,abs(sin(p) / dot(sin(p*5.),vec3(1.))), .09);
    
    fragColor = o;
}

