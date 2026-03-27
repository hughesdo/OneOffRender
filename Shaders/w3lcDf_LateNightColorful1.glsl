#version 330 core

// Late Night Colorful 1
// Created by OneHung
// Colorful fractal patterns - audio reactive color intensity and movement
// Inspired by zozuar
// https://www.shadertoy.com/view/w3lcDf

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

vec3 tanh3(vec3 x) {
    vec3 ex = exp(2.0 * x);
    return (ex - 1.0) / (ex + 1.0);
}

void main() {
    vec2 u = gl_FragCoord.xy;
    
    // Audio sampling
    float bass = texture(iChannel0, vec2(0.05, 0.25)).x;
    float mid = texture(iChannel0, vec2(0.3, 0.25)).x;
    float treble = texture(iChannel0, vec2(0.7, 0.25)).x;
    
    // Smooth response
    bass = smoothstep(0.0, 0.7, bass);
    mid = smoothstep(0.0, 0.6, mid);
    treble = smoothstep(0.1, 0.5, treble);
    
    float s = 4.;
    vec2 q = vec2(0.0), p = u.xy/iResolution.y - 0.5;
    
    vec3 color = vec3(0.0);
    
    // Bass subtly affects iteration scaling
    float scaleFactor = 1.3 + bass * 0.05;
    
    for(float i = 0.; i < 32.; i += 1.0) {
        p *= mat2(cos(1. + vec4(0, 33, 11, 0)));
        q += cos(2.*iTime - dot(cos(4.*iTime + p + cos(q)), p) + s * p + i*i) + sin(s*p + q.yx);
        
        s *= scaleFactor;
        float dist = length(q*q / s);
        
        // Audio-reactive color channels
        color.r += dist * (0.5 + 0.5 * sin(iTime * 0.5 + i * 0.3) + bass * 0.3);
        color.g += dist * (0.5 + 0.5 * sin(iTime * 0.7 + i * 0.3 + 2.1) + mid * 0.25);
        color.b += dist * (0.5 + 0.5 * sin(iTime * 0.9 + i * 0.3 + 4.2) + treble * 0.3);
    }
    
    // Apply tanh normalization
    color = tanh3(color / 10.0);
    
    // Audio-reactive color shifts
    vec3 colorShift = vec3(
        sin(iTime * 0.3) * 0.2 + bass * 0.1,
        sin(iTime * 0.5 + 2.0) * 0.2 + mid * 0.1,
        sin(iTime * 0.7 + 4.0) * 0.2 + treble * 0.15
    );
    color += colorShift;
    
    // Vibrant color enhancement
    color = pow(color, vec3(0.8));
    color *= 1.3 + bass * 0.2;
    
    fragColor = vec4(color, 1.0);
}

