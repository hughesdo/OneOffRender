#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Keep Going
// Created by diatribes
// Shadertoy ID: 33lGzn
// https://www.shadertoy.com/view/33lGzn

#define P(z) vec3(tanh(cos((z) * .3) * .5) * 8., \
                  tanh(cos((z) * .23) * .4) * 12., (z))
#define T (iTime*.75)
#define rot(a) mat2(cos(a+vec4(0,33,11,0)))

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.002,l,w=1.,d=0.;
    vec3  p = P(T),ro=p,
          Z = normalize( P(T+1.) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3(rot(sin(p.z*.2)*.3)*(u-iResolution.xy/2.)/iResolution.y, 1) 
             * mat3(-X, cross(X, Z), Z);
    o -= o;
    for(int i = 0; i++ < 90 && s > .001;) {
        p = ro + D * d;
        p.xy -=  P(p.z).xy;
        s = min(1.75+p.y,min(.5 - p.y, 1.25 - length(p.xy)));
        for(float a=.2;a < 4.;
            s-=abs(dot(sin(T+T+p*a*24.),
            vec3(.6+sin(p.z)*.25)))/a*.02,a+=a);
        p.x -= 4.;
        p.y += .25;
        p = clamp(p, -1.0, 1.0) * 2.0 - p;
        w = .8;
        for (int j=0; j++ < 8; p *= l, w *= l )
            p = clamp(p, -2.0, 2.0) * 2.0 - p,
            p  = abs(sin(p)) - 1.,
            l = 1.4/dot(p,p);
        o.rgb += sin(p)*.05+.05;
        s = min(s, length(p)/w);
        d += s;
    }
    o.rgb *= vec3(4,.05,.02)*exp(-d/3.);
    o.rgb = pow(o.rgb, vec3(.45));
    
    fragColor = o;
}

