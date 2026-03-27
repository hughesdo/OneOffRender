#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// Audio-Reactive Wave Interference
// Beautiful wave patterns with audio synchronization
// Add audio to iChannel0

#define PI 3.14159265359
#define TAU 6.28318530718

mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

// Simple hash function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Wave function
float wave(vec2 p, vec2 center, float freq, float phase) {
    float dist = length(p - center);
    return sin(dist * freq - phase) * exp(-dist * 0.5);
}

// Multiple wave sources
float waves(vec2 p, float time, float audioLow, float audioMid, float audioHigh) {
    float w = 0.0;
    
    // Main rotating waves
    for(int i = 0; i < 5; i++) {
        float angle = float(i) * TAU / 5.0 + time * 0.3;
        vec2 center = vec2(cos(angle), sin(angle)) * (1.5 + audioMid * 0.5);
        float freq = 8.0 + float(i) * 2.0 + audioHigh * 5.0;
        float phase = time * (2.0 + float(i) * 0.5) + audioLow * 3.0;
        w += wave(p, center, freq, phase);
    }
    
    // Central pulsing wave
    w += wave(p, vec2(0), 12.0 + audioMid * 10.0, time * 4.0 + audioLow * 5.0) * 1.5;
    
    // Audio-reactive waves
    for(int i = 0; i < 3; i++) {
        float angle = float(i) * TAU / 3.0 - time * 0.5;
        vec2 center = vec2(cos(angle), sin(angle)) * audioLow * 2.0;
        w += wave(p, center, 15.0, time * 6.0) * audioHigh;
    }
    
    return w;
}

// Radial patterns
float radialPattern(vec2 p, float segments, float time) {
    float angle = atan(p.y, p.x);
    float radius = length(p);
    
    // Segment the circle
    float segAngle = angle * segments / TAU;
    float pattern = sin(segAngle + time) * sin(radius * 10.0 - time * 2.0);
    
    return pattern;
}

vec3 getAudio() {
    return vec3(
        texture(iChannel0, vec2(0.05, 0.25)).x,
        texture(iChannel0, vec2(0.15, 0.25)).x,
        texture(iChannel0, vec2(0.35, 0.25)).x
    ) * 2.5;
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    
    vec3 audio = getAudio();
    float audioLow = audio.x;
    float audioMid = audio.y;
    float audioHigh = audio.z;
    
    // Rotate space with audio
    uv = rot(sin(iTime * 0.2) * 0.3 + audioLow * 0.5) * uv;
    
    // Calculate wave interference
    float w = waves(uv, iTime, audioLow, audioMid, audioHigh);
    
    // Add radial patterns
    float radial = radialPattern(uv, 8.0 + audioMid * 4.0, iTime);
    w += radial * 0.3;
    
    // Normalize and create bands
    w = w * 0.3 + 0.5;
    
    // Color mapping with audio
    vec3 col = vec3(0);
    
    // Create color bands
    float colorPhase = iTime * 0.5 + audioMid * TAU;
    vec3 color1 = vec3(0.2, 0.4, 0.8); // Blue
    vec3 color2 = vec3(0.8, 0.2, 0.6); // Magenta
    vec3 color3 = vec3(0.2, 0.8, 0.6); // Cyan
    vec3 color4 = vec3(0.9, 0.6, 0.2); // Orange
    
    // Interpolate between colors based on wave value
    if(w < 0.25) {
        col = mix(color1, color2, w * 4.0);
    } else if(w < 0.5) {
        col = mix(color2, color3, (w - 0.25) * 4.0);
    } else if(w < 0.75) {
        col = mix(color3, color4, (w - 0.5) * 4.0);
    } else {
        col = mix(color4, color1, (w - 0.75) * 4.0);
    }
    
    // Add audio-reactive color shift
    col = mix(col, col.zxy, audioHigh * 0.5);
    
    // Add glow at wave peaks
    float glow = pow(abs(fract(w * 4.0) - 0.5) * 2.0, 3.0);
    col *= 0.5 + glow * (1.0 + audioLow * 0.5);
    
    // Add sparkles at intersections
    float sparkle = step(0.98, abs(fract(w * 20.0 + hash(uv * 10.0)) - 0.5) * 2.0);
    col += vec3(1) * sparkle * (0.5 + audioHigh * 0.5);
    
    // Background glow
    float bgGlow = exp(-length(uv) * 1.5);
    col += vec3(0.1, 0.2, 0.3) * bgGlow * (0.5 + audioLow * 0.5);
    
    // Audio pulse effect
    float pulse = sin(iTime * 10.0) * audioLow * 0.1;
    col += vec3(0.2, 0.3, 0.5) * pulse;
    
    // Vignette
    float vignette = 1.0 - dot(uv * 0.5, uv * 0.5);
    col *= 0.2 + 0.8 * pow(vignette, 0.5);
    
    // Color grading
    col = pow(col, vec3(0.9));
    col = col * col * (3.0 - 2.0 * col);
    
    fragColor = vec4(col, 1.0);
}
