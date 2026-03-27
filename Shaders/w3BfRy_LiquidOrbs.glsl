#version 330 core

// Liquid Orbs
// Created by OneHung
// Organic flowing pattern with rich colors - audio reactive orb sizes and glow
// https://www.shadertoy.com/view/w3BfRy

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Audio sampling
    float bass = texture(iChannel0, vec2(0.05, 0.25)).x;
    float mid = texture(iChannel0, vec2(0.3, 0.25)).x;
    float treble = texture(iChannel0, vec2(0.7, 0.25)).x;
    
    // Smooth response
    bass = smoothstep(0.0, 0.7, bass);
    mid = smoothstep(0.0, 0.6, mid);
    treble = smoothstep(0.1, 0.5, treble);
    
    float t = iTime * 0.3;
    
    // Layer 1: Large slow orbs - bass reactive
    vec2 p1 = uv + vec2(sin(t * 0.7) * 0.5, cos(t * 0.5) * 0.4);
    float d1 = length(p1);
    
    // Layer 2: Medium speed orbs - mid reactive
    vec2 p2 = uv + vec2(cos(t * 1.2 + 2.0) * 0.3, sin(t * 0.9 + 1.0) * 0.35);
    float d2 = length(p2);
    
    // Layer 3: Small fast orbs - treble reactive
    vec2 p3 = uv + vec2(sin(t * 2.0 + 4.0) * 0.2, cos(t * 1.8 + 3.0) * 0.25);
    float d3 = length(p3);
    
    // Create soft circular patterns - audio affects falloff (size)
    float orb1 = exp(-d1 * (3.0 - bass * 0.8));
    float orb2 = exp(-d2 * (4.0 - mid * 0.6));
    float orb3 = exp(-d3 * (6.0 - treble * 1.0));
    
    // Combine orbs with audio-boosted intensities
    float pattern = orb1 * (0.6 + bass * 0.3) + orb2 * (0.8 + mid * 0.3) + orb3 * (1.0 + treble * 0.4);
    
    // Add rings - bass affects ring visibility
    float ring1 = exp(-abs(d1 - 0.3) * 20.0) * (1.0 + bass * 0.5);
    float ring2 = exp(-abs(d2 - 0.25) * 25.0) * (1.0 + mid * 0.4);
    pattern += ring1 * 0.4 + ring2 * 0.3;
    
    // Rich color palette
    vec3 color1 = vec3(0.9, 0.2, 0.5);  // Hot pink
    vec3 color2 = vec3(0.2, 0.5, 0.9);  // Sky blue
    vec3 color3 = vec3(0.9, 0.7, 0.1);  // Gold
    vec3 color4 = vec3(0.3, 0.9, 0.6);  // Mint
    
    // Mix colors based on position and pattern
    vec3 color = mix(color1, color2, orb1 * 0.7 + 0.3);
    color = mix(color, color3, orb2 * 0.6);
    color = mix(color, color4, orb3 * 0.5);
    
    // Apply pattern intensity
    color *= pattern;
    
    // Shimmer - treble affects shimmer speed
    float shimmerSpeed = 5.0 + treble * 3.0;
    float shimmer = sin(length(uv) * 20.0 - t * shimmerSpeed) * 0.5 + 0.5;
    color += vec3(shimmer * pattern * 0.2);
    
    // Dark background with gradient
    vec3 bg = vec3(0.02, 0.01, 0.05) * (1.0 + length(uv) * 0.5);
    color = mix(bg, color, clamp(pattern, 0.0, 1.0));
    
    // Overall brightness on bass
    color *= 1.0 + bass * 0.2;
    
    color = pow(color, vec3(0.9));
    
    fragColor = vec4(color, 1.0);
}

