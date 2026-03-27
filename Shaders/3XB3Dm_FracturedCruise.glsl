#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Fractured Cruise
// Created by diatribes
// Shadertoy ID: 3XB3Dm
// https://www.shadertoy.com/view/3XB3Dm

#define W .75
#define H .75
#define L 10.

#define T (iTime*.5)
#define N normalize
#define P(z) (vec3(tanh(cos((z) * .35) * .5) * 8., \
                     tanh(cos((z) * .62) * .65) * 8., (z)))
#define rot(a) mat2(cos(a+vec4(0,33,11,0)))

// distance to tunnel
float tunnel(vec3 p) {
    vec3 tun = abs(p - P(p.z));
    return min(W-tun.x, H-tun.y);
}

// distance to fractal
float fractal(vec3 p, float s) {
    float w = 1., l;
    
    // scale, more instances, but smaller
    p.xy *= s;
    p.x -= 2.;
    // translate to some place interesting
    
    // NOTE: no p.xy -= path(p.z).xy,
    // we're going to go _through_ the fractal,
    // not stretch the fractal around the path
    
    // distance to fractal
    float f = tanh(sin(T*2.)*.01)*5.;
    for (int i; i++ < 8; p *= l, w *= l )
        p  = abs(sin(f+p)) - 1.,
        l = 1.5/dot(p,p);
    return length(p)/w; 
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,s=.002,d=0.;
    vec3  r = vec3(iResolution.xy, iResolution.y),
          p = P(T),ro=p,
          Z = normalize( P(T+1.) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3(rot(sin(T*.2)*3.3)*(u-r.xy/2.)/r.y, 1) 
              * mat3(-X, cross(X, Z), Z);
    o -= o;

    // raymarch tunnel
    for(i = 0.; i++ < L && s > .001;)
        p = ro + D * d,
        d += s = tunnel(p)*.5;
    float tunnelDist = d;
    
    // reset, origin now starts at p
    // i.e., p is on the tunnel (ro = p)
    ro = p, s=.002,d=0.;
    for(i = 0.; i++ < 80. && s > .001;)
        p = ro + D * d,
        d += s = min(fractal(.3*T+p, 1.5),
                     fractal(p, 1.)),
        o.rgb += sin(p*6.)*.01+.03; 


    o.rgb = 1. - o.rgb;
    for (i = .4; i < 1.6;
        o.rgb +=  abs(dot(sin(p* i * 512.),
        vec3(.15))) / i, i *= 1.4142);

    float f = (mod((p.z), 4.));
    if (f > 1.)
        o.rgb = mix(o.rgb,abs(sin(2.*T+p*.2) /
                          dot(sin(p*2.),vec3(2.))),.9);
    else if (f > 2.)
        o.rgb = mix(o.rgb,abs(sin(T+p) /
                          dot(sin(T+p), vec3(1))),.5);
    

    o.rgb *= exp(-(tunnelDist+d)/1.5);
    o.rgb = pow(o.rgb, vec3(.45));
    
    fragColor = o;
}

