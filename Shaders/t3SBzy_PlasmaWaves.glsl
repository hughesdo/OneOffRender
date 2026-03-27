#version 330 core

// Plasma Waves
// Created by OneHung
// Sine wave interference patterns - audio reactive colors and ripples
// https://www.shadertoy.com/view/t3SBzy

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = fragCoord / iResolution.y;
    
    // Audio sampling
    float bass = texture(iChannel0, vec2(0.05, 0.25)).x;
    float mid = texture(iChannel0, vec2(0.3, 0.25)).x;
    float treble = texture(iChannel0, vec2(0.7, 0.25)).x;
    
    // Smooth response
    bass = smoothstep(0.0, 0.7, bass);
    mid = smoothstep(0.0, 0.6, mid);
    treble = smoothstep(0.1, 0.5, treble);
    
    float t = iTime * 0.5;

    // Multiple sine wave layers - natural movement only
    float wave1 = sin(uv.x * 10.0 + t) * sin(uv.y * 10.0 - t * 0.7);
    float wave2 = sin((uv.x + uv.y) * 8.0 - t * 1.3) * 0.7;
    float wave3 = sin((uv.x - uv.y) * 12.0 + t * 1.1) * 0.5;

    float pattern = wave1 + wave2 + wave3;

    // Circular ripple from center - natural movement
    vec2 center = uv - vec2(iResolution.x / iResolution.y * 0.5, 0.5);
    float dist = length(center);
    float ripple = sin(dist * 15.0 - t * 3.0) * exp(-dist * 2.0);
    pattern += ripple * 0.8;
    
    pattern = pattern * 0.5 + 0.5;
    
    // Color mapping with audio-reactive palette shifting
    vec3 darkBlue = vec3(0.1, 0.0, 0.3);
    vec3 cyan = vec3(0.0, 0.8 + treble * 0.2, 0.9);  // Treble boosts cyan
    vec3 hotPink = vec3(1.0, 0.2 + bass * 0.2, 0.6);  // Bass affects pink
    
    vec3 color;
    if (pattern < 0.5) {
        float t1 = pattern * 2.0;
        color = mix(darkBlue, cyan, t1);
    } else {
        float t2 = (pattern - 0.5) * 2.0;
        color = mix(cyan, hotPink, t2);
    }
    
    // Brightness variation
    color *= 0.8 + 0.2 * sin(pattern * 6.28);
    
    // Bass pulses overall brightness
    color *= 1.0 + bass * 0.25;
    
    // Boost overall brightness
    color = pow(color, vec3(0.85));
    
    fragColor = vec4(color, 1.0);
}

