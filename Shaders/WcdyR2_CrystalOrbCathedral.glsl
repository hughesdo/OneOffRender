#version 330 core

// Crystal Orb Cathedral
// Created by OneHung
// diatribes-style with colorful audio orbs
// https://www.shadertoy.com/view/WcdyR2

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

#define T (iTime)

float orb1(vec3 p) {
    float t = T * 3.;
    return length(p - vec3(sin(t*.3) * 8., 2. + cos(t*.4) * 3., 10. + T + sin(t*.2) * 5.));
}

float orb2(vec3 p) {
    float t = T * 2.5;
    return length(p - vec3(cos(t*.4) * 6., -1. + sin(t*.3) * 2., 15. + T + cos(t*.25) * 4.));
}

float orb3(vec3 p) {
    float t = T * 4.;
    return length(p - vec3(sin(t*.2) * 7., sin(t*.5) * 4., 8. + T + sin(t*.35) * 6.));
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o = vec4(0.0);
    float d = 0.0, a, e1, e2, e3, i = 0.0, s, t = T;
    vec3 p = vec3(iResolution, 1.0);
    
    // Get audio frequencies
    float bass = texture(iChannel0, vec2(0.0, 0.25)).x;
    float mid = texture(iChannel0, vec2(0.2, 0.25)).x;
    float high = texture(iChannel0, vec2(0.5, 0.25)).x;
    
    // Fallback if no audio
    bass = bass > 0.01 ? bass : 0.3 + 0.1 * sin(t * 1.5);
    mid = mid > 0.01 ? mid : 0.2 + 0.1 * sin(t * 2.3);
    high = high > 0.01 ? high : 0.15 + 0.1 * sin(t * 3.7);
    
    // Scale coords
    u = (u + u - p.xy) / p.y;
    u += vec2(cos(t*.15)*.2, sin(t*.2)*.15);
    
    // Audio-reactive orb colors
    vec3 orb1Color = vec3(1.0 + bass * 3.0, 0.2 + mid * 0.5, 0.3 + high * 0.3);
    vec3 orb2Color = vec3(0.2 + high * 0.5, 0.3 + bass * 0.5, 1.0 + mid * 3.0);
    vec3 orb3Color = vec3(0.8 + mid * 2.0, 1.0 + high * 3.0, 0.1 + bass * 0.3);
    
    for(i = 0.0; i < 100.0; i++) {
        p = vec3(u * d, d + t);
        e1 = orb1(p) - .5;
        e2 = orb2(p) - .4;
        e3 = orb3(p) - .6;
        
        p.xy *= mat2(cos(.1*t + p.z/10. + vec4(0,33,11,0)));
        s = 5. - abs(p.y) + 3. - abs(p.x);
        
        for(a = .8; a < 16.; a += a) {
            p += cos(.7*t + p.yzx) * .15;
            s -= abs(dot(sin(.1*t + p * a), vec3(.6))) / a;
        }
        
        s = min(.02 + .3*abs(s), min(min(e1, e2), e3) * .8);
        d += s;
        
        o += 1./(s+.001) 
            + 1e3 * vec4(orb1Color, 0) / (e1*e1 + 1.)
            + 1e3 * vec4(orb2Color, 0) / (e2*e2 + 1.) 
            + 1e3 * vec4(orb3Color, 0) / (e3*e3 + 1.);
    }
    
    fragColor = tanh(o / 8e3);
}

