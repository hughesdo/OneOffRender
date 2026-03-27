// ============================================================================
// MILKDROP TRIBUTE - Main Image Shader
// Classic MilkDrop aesthetics: wave displacement, geometric overlays,
// color cycling, and beat-reactive pulsing
// https://www.shadertoy.com/view/tcKBzm
// ============================================================================

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Buffer A (audio analysis & beat history)

out vec4 fragColor;

// ----------------------------------------------------------------------------
// Utility Functions
// ----------------------------------------------------------------------------

// Rotation matrix
mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

// Cosine palette (Inigo Quilez style)
vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
}

// Standard MilkDrop palette
vec3 milkPalette(float t, float phase) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557) + phase;
    return a + b * cos(6.28318 * (c * t + d));
}

// Smooth noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion
float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 6; i++) {
        if (i >= octaves) break;
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

// Signed distance functions for geometric shapes
float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdHexagon(vec2 p, float r) {
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
    return length(p) * sign(p.y);
}

// Smooth minimum for organic blending
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// ----------------------------------------------------------------------------
// Main Shader
// ----------------------------------------------------------------------------

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    // Normalized coordinates (-1 to 1), aspect corrected
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 originalUV = uv;
    
    // Audio analysis - sample multiple frequency bands
    float bass = texelFetch(iChannel0, ivec2(4, 0), 0).r;
    float mid = texelFetch(iChannel0, ivec2(32, 0), 0).r;
    float high = texelFetch(iChannel0, ivec2(64, 0), 0).r;
    float treble = texelFetch(iChannel0, ivec2(96, 0), 0).r;
    float energy = (bass + mid + high + treble) * 0.25;
    
    // Get parameters from Buffer A
    vec4 param1 = texelFetch(iChannel0, ivec2(64, 0), 0);
    vec4 param2 = texelFetch(iChannel0, ivec2(65, 0), 0);
    vec4 param3 = texelFetch(iChannel0, ivec2(66, 0), 0);
    vec4 param4 = texelFetch(iChannel0, ivec2(67, 0), 0);
    
    float t = iTime;
    float beatPulse = smoothstep(0.6, 1.0, bass);
    
    // =========================================================================
    // LAYER 1: Wave Displacement Background
    // =========================================================================
    
    vec2 waveUV = uv * 2.0;
    
    // Multi-layered sinusoidal waves (classic MilkDrop signature)
    float wave1 = sin(waveUV.x * 4.0 + waveUV.y * 3.0 + t * 0.8 + bass * 2.0) * 0.5;
    float wave2 = sin(waveUV.y * 5.0 - waveUV.x * 2.0 + t * 0.6 + mid * 1.5) * 0.5;
    float wave3 = sin((waveUV.x + waveUV.y) * 3.0 + t * 1.0 + high * 2.0) * 0.5;
    
    float waves = wave1 + wave2 + wave3;
    waves = waves * 0.33; // Normalize
    
    // Apply wave displacement to UV
    vec2 displacedUV = uv + vec2(waves * 0.1 * (1.0 + energy), waves * 0.08 * (1.0 + energy));
    
    // Background gradient based on waves
    vec3 bgColor = milkPalette(waves + t * 0.05, t * 0.02);
    bgColor *= 0.3 + energy * 0.4;
    
    // =========================================================================
    // LAYER 2: Rotating Geometric Patterns
    // =========================================================================
    
    vec2 geoUV = displacedUV;
    
    // Multiple rotation layers
    float rot1 = param1.x;      // Rotation from Buffer A
    float rot2 = param2.x;
    float rot3 = param3.x;
    
    // Apply rotations
    geoUV *= rot(rot1);
    float rotLayer1 = length(geoUV);
    float angLayer1 = atan(geoUV.y, geoUV.x);
    
    // Concentric rings with rotation
    float rings = abs(sin(rotLayer1 * 15.0 - t * 2.0 + bass * 5.0));
    rings = smoothstep(0.1, 0.9, rings);
    rings *= exp(-rotLayer1 * 2.0) * (0.5 + bass);
    
    // Star/asterisk pattern
    vec2 starUV = geoUV * rot(rot2);
    float arms = abs(cos(angLayer1 * 5.0 + t + rot2)) * 0.1;
    arms += abs(cos(angLayer1 * 3.0 - t * 0.7 + rot2)) * 0.15;
    float star = smoothstep(0.05, 0.0, arms - rotLayer1 * 0.3);
    star *= (0.5 + energy * 0.5);
    
    // Hexagonal pattern
    vec2 hexUV = geoUV * rot(rot3);
    float hexDist = sdHexagon(hexUV, 0.3 + bass * 0.1);
    float hexPattern = smoothstep(0.02, 0.0, abs(hexDist - 0.05));
    hexPattern += smoothstep(0.02, 0.0, abs(hexDist - 0.15));
    hexPattern *= (0.4 + mid);
    
    // Combine geometric layers
    vec3 geoColor = milkPalette(angLayer1 * 0.3 + t * 0.1 + rot1, t * 0.03);
    geoColor *= rings + star + hexPattern;
    geoColor *= 1.0 + energy;
    
    // =========================================================================
    // LAYER 3: Kaleidoscope / Radial Symmetry
    // =========================================================================
    
    vec2 kaleidoUV = displacedUV;
    float kaleidoR = length(kaleidoUV);
    float kaleidoA = atan(kaleidoUV.y, kaleidoUV.x);
    
    // 8-fold radial symmetry
    float segments = 8.0;
    kaleidoA = abs(mod(kaleidoA, 3.14159 / segments) - 1.5708 / segments);
    kaleidoUV = vec2(cos(kaleidoA), sin(kaleidoA)) * kaleidoR;
    
    // Wavy lines from center
    float radialWave = sin(kaleidoR * 20.0 - t * 4.0 + bass * 8.0);
    float radialLines = smoothstep(0.0, 0.5, abs(radialWave)) * (0.3 + high);
    
    // Spiral pattern
    float spiral = sin(kaleidoR * 10.0 - kaleidoA * 6.0 + t * 1.5);
    float spiralPattern = smoothstep(0.2, 0.8, spiral);
    
    // Inner glow
    float innerGlow = exp(-kaleidoR * 3.0) * (0.5 + energy);
    
    vec3 kaleidoColor = milkPalette(kaleidoA * 0.5 + t * 0.08, t * 0.015);
    kaleidoColor *= (radialLines + spiralPattern + innerGlow) * 2.0;
    kaleidoColor *= (0.6 + energy * 0.8);
    
    // =========================================================================
    // LAYER 4: Animated Curves and Lines
    // =========================================================================
    
    vec2 curveUV = uv * 3.0;
    
    // Sine curves
    float curve1 = sin(curveUV.x * 4.0 + t + param1.y * 5.0);
    float curve2 = cos(curveUV.y * 3.0 - t * 0.7 + param2.y * 5.0);
    float curve3 = sin((curveUV.x + curveUV.y) * 2.0 + t * 1.2 + param3.y * 5.0);
    
    // Combine curves
    float curves = abs(curve1 * 0.5 + curve2 * 0.3 + curve3 * 0.2);
    curves = smoothstep(0.7, 0.3, curves);
    curves *= exp(-length(uv) * 1.5) * (0.4 + energy);
    
    // Perpendicular lines
    float lines = abs(sin(curveUV.x * 10.0 + t * 2.0)) * 0.1;
    lines += abs(cos(curveUV.y * 8.0 - t * 1.8)) * 0.1;
    lines = smoothstep(0.08, 0.0, lines);
    lines *= exp(-length(uv) * 2.0) * (0.3 + mid);
    
    vec3 curveColor = milkPalette(curve1 * 0.3 + t * 0.12, t * 0.025);
    curveColor *= (curves + lines) * 1.5;
    
    // =========================================================================
    // LAYER 5: Beat Pulse Effects
    // =========================================================================
    
    vec2 pulseUV = uv;
    
    // Expanding ring on beat
    float pulseRing = abs(length(pulseUV) - t * 0.5 + bass * 0.5);
    pulseRing = smoothstep(0.05, 0.0, abs(pulseRing - fract(t * 0.3)));
    pulseRing *= smoothstep(0.3, 0.0, length(pulseUV));
    pulseRing *= beatPulse * 2.0;
    
    // Screen shake on strong beats
    float shake = (bass > 0.7) ? (hash(vec2(t * 10.0)) - 0.5) * 0.05 : 0.0;
    pulseUV += vec2(shake);
    
    // Flash effect
    float flash = smoothstep(0.8, 1.0, bass) * 0.3;
    
    vec3 pulseColor = vec3(flash) + vec3(1.0, 0.8, 0.6) * pulseRing;
    
    // =========================================================================
    // LAYER 6: Organic Noise Layer
    // =========================================================================
    
    vec2 noiseUV = uv * 4.0 + vec2(t * 0.1, t * 0.15);
    float organicNoise = fbm(noiseUV, 5);
    
    // Fluid-like color banding
    vec3 fluidColor = milkPalette(organicNoise + t * 0.06, t * 0.018);
    fluidColor *= organicNoise * 0.5;
    fluidColor *= (0.4 + energy * 0.6);
    
    // =========================================================================
    // FINAL COMPOSITION
    // =========================================================================
    
    vec3 finalColor = bgColor;
    
    // Additive blending of geometric layer
    finalColor += geoColor * 0.8;
    
    // Kaleidoscope overlay
    finalColor = mix(finalColor, kaleidoColor, 0.6);
    
    // Curve patterns
    finalColor += curveColor * 0.5;
    
    // Beat effects
    finalColor += pulseColor;
    
    // Fluid layer
    finalColor = mix(finalColor, fluidColor, 0.4);
    
    // Radial vignette
    float vignette = 1.0 - length(uv * 0.7);
    vignette = smoothstep(0.0, 1.0, vignette);
    finalColor *= vignette;
    
    // Dynamic brightness
    finalColor *= 0.8 + energy * 0.4;
    
    // Subtle scanline effect
    float scanline = sin(fragCoord.y * 3.14159 / iResolution.y * 200.0) * 0.02;
    finalColor -= scanline;
    
    // Gamma correction
    finalColor = pow(finalColor, vec3(0.9));
    
    fragColor = vec4(finalColor, 1.0);
}
