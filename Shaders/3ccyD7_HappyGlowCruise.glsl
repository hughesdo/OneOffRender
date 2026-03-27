#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Happy Glow Cruise
// Created by diatribes
// Shadertoy ID: 3ccyD7
// https://www.shadertoy.com/view/3ccyD7

// i tried to make it run better on non-mega-gpus
// let me know how performance is if you don't mind :D

#define T (iTime*6.)
#define P(z) vec3(cos((z) *  .05) * 16., \
                 cos((z) *  .1) * 8., (z))
#define R(a) mat2(cos(a+vec4(0,33,11,0)))
#define N normalize

float light;

float orb(vec3 p) {
    vec3 q = P(p.z);
    return length(p - vec3(
            q.x+(sin(p.z*.4) * .4),
            q.y+sin(sin(p.z*.3)+T) * .5,
           5.+T+tan(cos(T*.2)*.5)*3.2));
}

#define MENGERLAYER(scale, minmax, hole)\
    s /= (scale), \
    p = abs(fract(q/s)*s - s*.5), \
 	d = minmax(d, min(max(p.x, p.y), \
                  min(max(p.y, p.z), \
                  max(p.x, p.z))) - s/(hole))
float fractal(vec3 q){
    vec3 p;
    
    // *** Play with scale (s)
    // 2 - 8 works'ish
    float s = 4., d = 9e9;
    MENGERLAYER(1., min, 6.);
    MENGERLAYER(4., max, 3.5);
    return d;
}

float map(vec3 p) {
    float n, s, o;
    vec3 q = p;
    p.xy -= P(p.z).xy;
    p.y += .1;
    s = max(1. - abs(p.x),1. - abs(p.y));
    s = min(s, fractal(p));
    s = min(s, o = orb(q) - .01);
    light += 1./max(o,.001);
    return min(o, max(-q.y-5.35, s));
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s,d,i,a;
    vec3  p = P(T),ro=p,
          Z = N( P(T+3.) - p),
          X = N(vec3(Z.z,0,-Z)),
          D = vec3(R(sin(T*.2)*.3)*(u-iResolution.xy/2.)/iResolution.y, 1) 
              * mat3(-X, cross(X, Z), Z);
    for(o=vec4(0);i++ < 5e1 && d < 5e1;
        o += vec4(2,1e1,4,0)/s
          + 6e1*vec4(2,1,8,0)*light / d)
        p = ro + D * d,
        d += s = .01+.65*abs(map(p));
    o = tanh(o*o/4e8);
    
    fragColor = o;
}

