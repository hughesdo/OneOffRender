#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Inferno Cruise
// Created by diatribes
// Shadertoy ID: 3Xs3zl
// https://www.shadertoy.com/view/3Xs3zl

#define T (iTime*2.5)

#define P(z) (vec3(tanh(cos((z) * .135) * .5) * 16., \
                   tanh(cos((z) * .162) * .65) * 16., (z)))
#define rot(a) mat2(cos(a+vec4(0,33,11,0)))

vec2 shake() {
    return vec2(
        sin(T * 250.),
        cos(T * 570.)
    ) * 10.;
}

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.002,l,w=1.,d=0.;
    vec3  r = vec3(iResolution.xy, iResolution.y);
    
    if(sin(T*.3) > 0.)
        u += shake();
    u = (u-r.xy/2.)/r.y;


    vec3  p = P(T),ro=p,
          Z = normalize( P(T+1.) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3(rot(sin(p.z*.3)*.5)*u, 1) 
             * mat3(-X, cross(X, Z), Z);
    o -= o;
    for(int i = 0; i++ < 220 && s > .001;) {
        p = ro + D * d;
        p.xy -=  P(p.z).xy;
        s = min(1.75+p.y,min(.5 - p.y, 2.25 - length(p.xy)));
        for(float a=.2;a < 3.;
            s-=abs(dot(sin(T+p*a*24.),
            vec3(.5+sin(p.z)*.35)))/a*.0205,a+=a);
        p.x -= 4.;
        p.y += .4;
        p.y *= .75;
        p = clamp(p, -1.0, 1.0) * 2.0 - p;
        w = .8;
        for (int j=0; j++ < 6; p *= l, w *= l )
            p = clamp(p, -2.0, 2.0) * 2.0 - p,
            p  = abs(sin(p)) - 1.,
            l = 1.4/dot(p,p)-(tanh(cos(T*1.5)*3.3)*.3)*.5;;
        o.rgb += sin(p)*.01+.05;
        s = min(s, length(p)/w);
        d += s*.5;
    }
    o.rgb = mix(o.rgb,abs(sin(.5*T+p*.4) / dot(sin(T+p*8.),vec3(.2))),.015);

    o.rgb *= vec3(2,.2,.02)*exp(-d/2.);
    o.rgb = pow(o.rgb-dot(u,u)*.1, vec3(.45));
    
    fragColor = o;
}

