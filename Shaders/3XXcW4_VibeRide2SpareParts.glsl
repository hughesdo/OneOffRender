#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Vibe Ride 2: Spare Parts
// Created by diatribes
// Shadertoy ID: 3XXcW4
// https://www.shadertoy.com/view/3XXcW4

#define T (iTime)
#define P(z) (vec3(cos((z) * .12) * 16., cos((z) * .1) * 8., (z)))
#define R(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize

float tunnel(vec3 p) {
    return 2.5 - length(p.xy);
}

float fractal(vec3 p) {
    float s,w,l;
    
    p.y += .7;
    p *= vec3(.45, .25, .65);
    p += cos(p.yzx * 6. + p.xzy * 2. + p.zxy *4.)*.1;
    
    for (s=0.,w=.7; s++ < 8.; p *= l, w *= l )
        p  = sin(p),
        l = 3./dot(p,p);

    return length(p)/w-.001;
}

float smin(float a, float b, float k){
   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}

float map(vec3 p) {
    p.xy -= P(p.z).xy;
    return smin(.8-p.y,
           max(fractal(p), tunnel(p)), 1.);
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.1,d=0.,i=0.;
    vec3  r = vec3(iResolution.xy, iResolution.y);
    u = (u-r.xy/2.)/r.y;
        
    vec3  p = P(T),ro=p,
          Z = N( P(T+4.) - p),
          X = N(vec3(Z.z,0,-Z)),
          D = vec3(R(sin(T*.3)*.3)*u, 1) 
             * mat3(-X, cross(X, Z), Z);

    o = vec4(0);
    for(;i++ < 128.;)
        p = ro + D * d * .7,
        d += s = map(p),
        o += 3e2*vec4(16,4,1,0) + 1.*vec4(1,2,5,0)/(.001+abs(s))*d;
    o = tanh(o / 4e6 * exp(d/16.));
    
    fragColor = o;
}

