#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Tube Cruise Bubble Dude
// Created by diatribes
// Shadertoy ID: 3XKSzV
// https://www.shadertoy.com/view/3XKSzV

#define P(z) vec3(cos((z) * .11)  * 4., \
                  cos((z) * .13)  * 4., (z))
#define R(a) mat2(cos(a+vec4(0,33,11,0)))
#define T iTime * 4.
#define N(f, i, s) abs(dot(sin(f*p*s), i +p-p )) / s

float light = 0.;

float sdfWisp(vec3 p) {
    p.xy -= P(p.z).xy;
    return length(p - vec3(
                    sin(sin(T*.3)+T*.4)*1.5,
                    sin(sin(T*.4)+T*.5)*1.3,
                    T+16.+cos(T*.1)*10.))-1.;
}

float sdfTube(vec3 p){
    p.xy = mod(p.xy - P(p.z).xy,6.) - 3.;
    return length(p.xy) - 1.;
}

float map(vec3 p) {
    float tunnel = 16. - length(p.xy - P(p.z).xy);
    float tube = sdfTube(p);
    float wisp = sdfWisp(p);
    light += 1./max(wisp, .001);
    return min(tunnel, min(tube, wisp));
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s,d,i;
    vec3  r = vec3(iResolution.xy, iResolution.y),
          p = P(T),ro=p,
          Z = normalize( P(T+1.) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3(R(sin(T*.1)*.3)*(u-r.xy/2.)/r.y, 1) 
             * mat3(-X, cross(X, Z), Z);
    o = vec4(0);
    for(;i++ < 128. && d < 1e2;
        o += vec4(2,1,5,0)/s + 1e3*vec4(5,2,1,0)*light / d)
        p = ro + D * d,
        d += s = .001+.75*abs(map(p));
    o = tanh(o/2e5);
    
    fragColor = o;
}

