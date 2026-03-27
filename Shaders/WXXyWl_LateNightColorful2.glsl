#version 330 core

// Late Night Colorful 2
// Created by OneHung
// Audio-reactive colorful fractal inspired by zozuar and diatribes
// https://www.shadertoy.com/view/WXXyWl

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

#define BASS_WAVE_BOOST 0.3
#define KICK_THRESHOLD 0.5
#define KICK_DECAY 3.0
#define COLOR_SPEED_R 0.5
#define COLOR_SPEED_G 0.7
#define COLOR_SPEED_B 0.9
#define BRIGHTNESS 1.3
#define KICK_BRIGHTNESS 0.3
#define ITERATIONS 32.0

vec3 tanh3(vec3 x) {
    vec3 ex = exp(2.0 * x);
    return (ex - 1.0) / (ex + 1.0);
}

void main() {
    vec2 u = gl_FragCoord.xy;
    
    // Sample bass frequencies
    float bass = texture(iChannel0, vec2(0.02, 0.25)).x;
    float bassKick = texture(iChannel0, vec2(0.05, 0.25)).x;
    
    // Detect kick hits
    float kickHit = smoothstep(KICK_THRESHOLD, KICK_THRESHOLD + 0.1, bassKick);
    float kickImpulse = kickHit * exp(-KICK_DECAY * fract(iTime));
    
    // Bass wave perturbation
    float bassWave = pow(bass, 2.0) * BASS_WAVE_BOOST;
    
    float s = 4.;
    vec2 q = vec2(0.0), p = u.xy/iResolution.y - 0.5;
    
    vec3 color = vec3(0.0);
    
    for(float i = 0.; i < ITERATIONS; i += 1.0) {
        p *= mat2(cos(1. + vec4(0, 33, 11, 0)));
        
        q += cos(2.*iTime - dot(cos(4.*iTime + p + cos(q)), p) + s * p + i*i) 
           + sin(s*p + q.yx) * (1.0 + bassWave + kickImpulse);
        
        s *= 1.3;
        float dist = length(q*q / s);
        
        color.r += dist * (0.5 + 0.5 * sin(iTime * COLOR_SPEED_R + i * 0.3));
        color.g += dist * (0.5 + 0.5 * sin(iTime * COLOR_SPEED_G + i * 0.3 + 2.1));
        color.b += dist * (0.5 + 0.5 * sin(iTime * COLOR_SPEED_B + i * 0.3 + 4.2));
    }
    
    // Apply tanh normalization
    color = tanh3(color / 10.0);
    
    // Color shifts
    vec3 colorShift = vec3(
        sin(iTime * 0.3) * 0.2,
        sin(iTime * 0.5 + 2.0) * 0.2,
        sin(iTime * 0.7 + 4.0) * 0.2
    );
    color += colorShift;
    
    // Enhancement with kick flash
    color = pow(color, vec3(0.8));
    color *= BRIGHTNESS + kickImpulse * KICK_BRIGHTNESS;
    
    fragColor = vec4(color, 1.0);
}

