#version 330 core

// Flowing Hexagons
// Created by OneHung
// Hexagonal tiling with sine distortions - audio reactive glow and color
// https://www.shadertoy.com/view/t3BfRy

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Audio sampling
    float bass = texture(iChannel0, vec2(0.05, 0.25)).x;
    float mid = texture(iChannel0, vec2(0.25, 0.25)).x;
    float treble = texture(iChannel0, vec2(0.7, 0.25)).x;
    
    // Smooth audio response
    bass = smoothstep(0.0, 0.8, bass);
    mid = smoothstep(0.0, 0.7, mid);
    treble = smoothstep(0.1, 0.6, treble);
    
    float t = iTime * 0.4;

    // Create flowing distortion - natural movement only
    vec2 flow = uv + 0.3 * vec2(
        sin(uv.y * 3.0 + t) + cos(uv.x * 2.0 - t * 0.7),
        cos(uv.x * 3.0 - t) + sin(uv.y * 2.0 + t * 0.7)
    );
    
    // Hexagonal tiling setup
    vec2 hexSize = vec2(0.15);
    vec2 hexGrid = vec2(2.0, 3.464) * hexSize;
    
    vec2 cell = flow / hexGrid;
    cell.x += 0.5 * mod(floor(cell.y), 2.0);
    
    vec2 cellId = floor(cell);
    vec2 cellPos = fract(cell) - 0.5;
    cellPos.x *= hexGrid.x / hexGrid.y;
    
    float d = length(cellPos);
    
    // Create hex pattern with smooth edges
    float hexDist = max(
        abs(cellPos.x) * 0.866 + abs(cellPos.y) * 0.5,
        abs(cellPos.y)
    );
    
    // Smooth circles in hex grid
    float pattern = smoothstep(0.35, 0.32, d);
    
    // Pulsing based on cell position - natural movement
    float pulse = sin(cellId.x * 0.5 + cellId.y * 0.7 + t * 2.0) * 0.5 + 0.5;
    pattern *= 0.6 + 0.4 * pulse;
    
    // Color based on position and time - treble shifts hue
    vec3 color1 = vec3(0.1, 0.4, 0.8);
    vec3 color2 = vec3(0.9, 0.3, 0.6);
    vec3 color3 = vec3(0.2, 0.9, 0.7);
    
    float colorMix = sin(cellId.x * 0.3 + cellId.y * 0.4 + t * 0.5 + treble * 2.0) * 0.5 + 0.5;
    vec3 baseColor = mix(color1, color2, colorMix);
    baseColor = mix(baseColor, color3, sin(colorMix * 3.14 + t) * 0.5 + 0.5);
    
    // Bass boosts saturation
    baseColor = mix(vec3(dot(baseColor, vec3(0.299, 0.587, 0.114))), baseColor, 1.0 + bass * 0.3);
    
    vec3 color = baseColor * pattern;
    
    // Glow around each hex - natural intensity with audio color shift
    float glow = exp(-d * 8.0) * 0.5 * pulse;
    color += baseColor * glow;
    
    // Subtle background gradient
    vec3 bg = mix(
        vec3(0.05, 0.02, 0.15),
        vec3(0.15, 0.05, 0.25),
        length(uv) * 0.5
    );
    color += bg * (1.0 - pattern);
    
    // Overall brightness boost on bass
    color *= 1.0 + bass * 0.2;
    
    fragColor = vec4(color, 1.0);
}

