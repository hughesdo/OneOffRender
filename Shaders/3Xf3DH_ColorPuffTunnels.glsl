#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Color Puff Tunnels
// Created by diatribes
// Shadertoy ID: 3Xf3DH
// https://www.shadertoy.com/view/3Xf3DH

#define T (iTime * 2.)
#define P0(z) (vec3(tanh(cos((z) * .12) * .15) * 12., \
                      tanh(cos((z) * .21) * .4) * 12., (z)))
#define P1(z) (vec3(tanh(cos((z*.15) * .04) * 2.3) * 12., \
                      tanh(cos((z) * .12) * .13) * 12., (z)))
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize
void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.002,d=0.,i=0.,a;
    vec3  r = vec3(iResolution.xy, iResolution.y),
          p = P0(T),ro=p,
          Z = N( P0(T+1.) - p),
          X = N(vec3(Z.z,0,-Z)),
          D = vec3(rot(sin(T*.3)*.4)*(u-r.xy/2.)/r.y, 1) 
              *.6* mat3(-X, cross(X, Z), Z);
    o -= o;
    while(i++ < 100. && s > .001) {
        p = ro + D * d;
        s = 1. - min(length(p.xy - P0(p.z).xy),
                     length(p.y - P1(p.z).y+3.));
        for(float a=.2;a < 4.;
            s-=abs(dot(sin(.6*T+p*a*10.),
            vec3(1.)))/a*.03,a+=a);

        d += s;
        o.rgb += sin(p*.75)*.03+.01;
    }
    o = vec4(pow((1.-o.rgb)*exp(-d/9.), vec3(.45)), 1.);
    
    fragColor = o;
}

