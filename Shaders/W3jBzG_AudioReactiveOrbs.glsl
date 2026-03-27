#version 330 core

// Audio Reactive Orbs
// Created by OneHung
// Energetic and bold orbs flowing through calm space
// https://www.shadertoy.com/view/W3jBzG

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    float t = iTime * 0.3;
    
    // Sample audio across frequency spectrum
    float bass = texture(iChannel0, vec2(0.1, 0.25)).x;
    float mid = texture(iChannel0, vec2(0.5, 0.25)).x;
    float high = texture(iChannel0, vec2(0.9, 0.25)).x;
    
    // Boost audio response for visibility
    bass = pow(bass * 1.5, 2.0);
    mid = pow(mid * 1.5, 2.0);
    high = pow(high * 1.5, 2.0);
    
    vec3 color = vec3(0.0);
    
    // ORB 1: Large bass-reactive (hot pink)
    vec2 orb1Pos = vec2(sin(t * 0.7) * 0.4, cos(t * 0.5) * 0.3);
    float orb1Dist = length(uv - orb1Pos);
    float orb1Size = 0.15 + bass * 0.3;
    float orb1Glow = exp(-orb1Dist / orb1Size * 5.0);
    vec3 orb1Color = vec3(1.0, 0.2, 0.5) * orb1Glow * (1.0 + bass * 2.0);
    
    // ORB 2: Medium mid-reactive (cyan)
    vec2 orb2Pos = vec2(cos(t * 1.1 + 2.0) * 0.35, sin(t * 0.8 + 1.5) * 0.35);
    float orb2Dist = length(uv - orb2Pos);
    float orb2Size = 0.12 + mid * 0.25;
    float orb2Glow = exp(-orb2Dist / orb2Size * 5.0);
    vec3 orb2Color = vec3(0.1, 0.8, 0.9) * orb2Glow * (1.0 + mid * 2.0);
    
    // ORB 3: Small high-reactive (gold)
    vec2 orb3Pos = vec2(sin(t * 1.5 + 4.0) * 0.3, cos(t * 1.3 + 3.0) * 0.25);
    float orb3Dist = length(uv - orb3Pos);
    float orb3Size = 0.08 + high * 0.2;
    float orb3Glow = exp(-orb3Dist / orb3Size * 6.0);
    vec3 orb3Color = vec3(1.0, 0.7, 0.1) * orb3Glow * (1.0 + high * 3.0);
    
    // Combine orbs
    color += orb1Color + orb2Color + orb3Color;
    
    // Add subtle trails
    float trail1 = exp(-(orb1Dist - orb1Size) * 8.0) * 0.3 * bass;
    float trail2 = exp(-(orb2Dist - orb2Size) * 10.0) * 0.3 * mid;
    float trail3 = exp(-(orb3Dist - orb3Size) * 12.0) * 0.3 * high;
    
    color += vec3(1.0, 0.2, 0.5) * trail1;
    color += vec3(0.1, 0.8, 0.9) * trail2;
    color += vec3(1.0, 0.7, 0.1) * trail3;
    
    // Calm background
    vec3 bgGradient = mix(vec3(0.01, 0.0, 0.05), vec3(0.0, 0.02, 0.08), length(uv) * 0.8);
    color = mix(bgGradient, color, clamp(length(color), 0.0, 1.0));
    
    color = pow(color, vec3(0.9));
    
    fragColor = vec4(color, 1.0);
}

