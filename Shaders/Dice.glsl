// Audio-Reactive D&D Dice Morphing - Shadertoy Edition
// Based on @Jaenam97's Holofoil Dice with audio-reactive enhancements
// Original: https://www.shadertoy.com/view/tfGyzt
// Enhanced with audio-reactive dice morphing
// Connect iChannel0 to an audio source (music or mic)

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT

out vec4 fragColor;

// ============================================
// TWEAKABLE PARAMETERS - Adjust these!
// ============================================

// --- Dice Timing ---
#define SHAPE_TIME 4.0          // Seconds each die shape is displayed
#define MORPH_TIME 1.5          // Seconds for morph transition between shapes

// --- Audio Reactivity ---
#define AUDIO_GRID_SCALE 8.0    // How much audio affects grid density (CRANKED UP!)
#define AUDIO_HUE_SHIFT 8.0     // How much audio shifts color hue (CRANKED UP!)
#define AUDIO_ANIM_SCALE 6.0    // How much audio affects shape animation intensity (CRANKED UP!)
#define BASS_FREQ 0.1           // Bass frequency sample point (low frequencies)
#define MID_FREQ 0.5            // Mid frequency sample point (mid frequencies)
#define HIGH_FREQ 0.8           // High frequency sample point (high frequencies)

// ============================================
// DOT AUDIO REACTIVITY CONTROLS - NEW!
// ============================================

// --- Master Control ---
#define DOT_AUDIO_INTENSITY 2.0     // Master dial: 0.0 = off, 1.0 = normal, 2.0 = intense

// --- Toggle Switches (1.0 = on, 0.0 = off) ---
#define DOT_SIZE_REACTIVE 1.0       // Enable audio-reactive dot SIZE
#define DOT_BRIGHTNESS_REACTIVE 1.0 // Enable audio-reactive dot BRIGHTNESS
#define DOT_FREQ_VARIATION 1.0      // Enable frequency-based variation (different dots = different freqs)

// --- Effect Amounts (scaled by master intensity) ---
#define DOT_SIZE_AMOUNT 0.25        // How much dots grow with audio (0.1 = subtle, 0.3 = noticeable)
#define DOT_BRIGHT_AMOUNT 3.0       // How much brighter dots get with audio (1.0 = subtle, 3.0 = punchy)
#define DOT_BASE_BRIGHT_BOOST 1.8   // Base brightness multiplier for dots (makes them pop more)

// ============================================

// --- Visual Quality ---
#define RAY_STEPS 120.0          // Number of raymarching steps (higher = sharper, slower)
#define GRID_DENSITY 6.0        // Base grid cell density (higher = more cells)
#define NESTED_BOX_ITERS 3      // Nested box fractal iterations (1-5, higher = more detail)

// --- Chromatic Aberration ---
#define CHROMA_SPREAD 0.02      // RGB channel separation amount (0.0 = none, 0.05 = strong)

// --- Rotation Speeds ---
#define ROT_SPEED_XZ 0.5        // Camera rotation speed around XZ axis
#define ROT_SPEED_XY 0.333      // Camera rotation speed around XY axis

// --- Color & Contrast ---
#define COLOR_INTENSITY 1.6     // Overall color brightness multiplier
#define DOT_BRIGHTNESS 5.0      // Base brightness of the sparkle dots
#define EXPOSURE 1.0e7          // Exposure divisor (lower = brighter, try 1.0e6 to 1.0e8)
#define CONTRAST 2.0            // Tone mapping contrast (1.0 = soft, 3.0 = punchy)

// --- Shape Scales (tweak individual die sizes) ---
#define SCALE_D4 1.0            // Tetrahedron (d4) scale
#define SCALE_D6 1.0            // Cube (d6) scale
#define SCALE_D8 1.0            // Octahedron (d8) scale
#define SCALE_D10 1.0           // Pentagonal trapezohedron (d10) scale
#define SCALE_D12 1.0           // Dodecahedron (d12) scale
#define SCALE_D20 1.0           // Icosahedron (d20) scale

// ============================================
// CONSTANTS (don't change these)
// ============================================
#define PI 3.14159265359
#define TAU 6.28318530718
#define PHI 1.61803398875
#define NUM_DICE 6

// ============================================
// HELPER FUNCTIONS
// ============================================

mat2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

float getAudioBass() {
    return texture(iChannel0, vec2(BASS_FREQ, 0.0)).x;
}

float getAudioMids() {
    return texture(iChannel0, vec2(MID_FREQ, 0.0)).x;
}

float getAudioHighs() {
    return texture(iChannel0, vec2(HIGH_FREQ, 0.0)).x;
}

// Get audio value for a specific dot based on its frequency assignment
// freqSelect: 0.0-0.33 = bass, 0.33-0.66 = mids, 0.66-1.0 = highs
float getDotAudio(float freqSelect, float bass, float mids, float highs) {
    if (DOT_FREQ_VARIATION < 0.5) {
        // If frequency variation is off, use average
        return (bass + mids + highs) / 3.0;
    }

    // Smoothly blend between frequencies based on random selection
    if (freqSelect < 0.33) {
        return bass;
    } else if (freqSelect < 0.66) {
        return mids;
    } else {
        return highs;
    }
}

// ============================================
// DICE SDFS
// ============================================

float sdTetrahedron(vec3 p) {
    p /= SCALE_D4;
    return (max(abs(p.x + p.y) - p.z, abs(p.x - p.y) + p.z) - 1.0) / sqrt(3.0) * SCALE_D4;
}

float sdCube(vec3 p) {
    p /= SCALE_D6;
    vec3 q = abs(p) - vec3(1.0);
    return (length(max(q, vec3(0.0))) + min(max(q.x, max(q.y, q.z)), 0.0)) * SCALE_D6;
}

float sdOctahedron(vec3 p) {
    p /= SCALE_D8;
    p = abs(p);
    return (p.x + p.y + p.z - 1.0) * 0.57735027 * SCALE_D8;
}

float sdD10(vec3 p) {
    p /= SCALE_D10;
    float a = atan(p.x, p.z);
    float sect = TAU / 5.0;
    a = mod(a + sect * 0.5, sect) - sect * 0.5;
    p.xz = vec2(sin(a), cos(a)) * length(p.xz);

    vec3 n1 = normalize(vec3(0.8, 0.5, 0.4));
    vec3 n2 = normalize(vec3(0.8, -0.5, 0.4));

    float d = dot(abs(p), n1);
    d = max(d, dot(vec3(abs(p.x), -p.y, abs(p.z)), n2));
    d = max(d, dot(vec3(abs(p.x), p.y, abs(p.z)), n2));

    return (d - 0.65) * SCALE_D10;
}

float sdDodecahedron(vec3 p) {
    p /= SCALE_D12;
    vec3 n1 = normalize(vec3(0.0, PHI, 1.0));
    vec3 n2 = normalize(vec3(0.0, PHI, -1.0));
    vec3 n3 = normalize(vec3(1.0, 0.0, PHI));
    vec3 n4 = normalize(vec3(-1.0, 0.0, PHI));
    vec3 n5 = normalize(vec3(PHI, 1.0, 0.0));
    vec3 n6 = normalize(vec3(PHI, -1.0, 0.0));

    vec3 ap = abs(p);
    float d = dot(ap, n1);
    d = max(d, dot(ap, n2));
    d = max(d, dot(ap, n3));
    d = max(d, dot(ap, n4));
    d = max(d, dot(ap, n5));
    d = max(d, dot(ap, n6));

    return (d - 0.77) * SCALE_D12;
}

float sdIcosahedron(vec3 p) {
    p /= SCALE_D20;
    const float q = 0.618033988749895;
    vec3 n1 = normalize(vec3(q, 1.0, 0.0));
    vec3 n2 = normalize(vec3(-q, 1.0, 0.0));

    vec3 ap = abs(p);
    float d = dot(ap, n1);
    d = max(d, dot(ap, n2));
    d = max(d, dot(ap.xzy, n1));
    d = max(d, dot(ap.xzy, n2));
    d = max(d, dot(ap.zyx, n1));
    d = max(d, dot(ap.zyx, n2));

    return (d - 0.82) * SCALE_D20;
}

// ============================================
// DICE ANIMATIONS
// ============================================

vec3 animateD4(vec3 p, float t, float audio) {
    float audioMod = 1.0 + audio * AUDIO_ANIM_SCALE;
    p.xz *= rotate2D(t * 1.5);
    p.xy *= rotate2D(sin(t * 2.0) * 0.3 * audioMod);
    return p;
}

vec3 animateD6(vec3 p, float t, float audio) {
    float audioMod = 1.0 + audio * AUDIO_ANIM_SCALE * 0.5;
    float twist = sin(t * 0.3) * 1.5 * audioMod;
    float c = cos(twist * p.y);
    float s = sin(twist * p.y * 0.5);
    p.xz = mat2(c, -s, s, c) * p.xz;
    p.xy *= rotate2D(t * 0.4);
    p.yz *= rotate2D(t * 0.28);
    return p;
}

vec3 animateD8(vec3 p, float t, float audio) {
    float audioMod = 1.0 + audio * AUDIO_ANIM_SCALE;
    p.xy *= rotate2D(t * 0.8);
    p.yz *= rotate2D(t * 0.5);
    p *= 1.0 + sin(t * 2.0) * 0.08 * audioMod;
    return p;
}

vec3 animateD10(vec3 p, float t, float audio) {
    p.xy *= rotate2D(sin(t * 1.5) * 0.4);
    p.xz *= rotate2D(t * 1.2);
    return p;
}

vec3 animateD12(vec3 p, float t, float audio) {
    p.xy *= rotate2D(t * 0.3);
    p.yz *= rotate2D(t * 0.23);
    p.xz *= rotate2D(t * 0.17);
    return p;
}

vec3 animateD20(vec3 p, float t, float audio) {
    float ease = sin(t * 0.15) * 2.0;
    p.xy *= rotate2D(ease + sin(t * 2.0) * 0.2);
    p.yz *= rotate2D(ease * 0.7 + cos(t * 1.7) * 0.3);
    p.xz *= rotate2D(ease * 0.5);
    return p;
}

// ============================================
// DICE MORPHING
// ============================================

float evaluateDie(int die, vec3 p, float t, float audio) {
    float result = 0.0;
    if (die == 0) result = sdTetrahedron(animateD4(p, t, audio));
    else if (die == 1) result = sdCube(animateD6(p, t, audio));
    else if (die == 2) result = sdOctahedron(animateD8(p, t, audio));
    else if (die == 3) result = sdD10(animateD10(p, t, audio));
    else if (die == 4) result = sdDodecahedron(animateD12(p, t, audio));
    else result = sdIcosahedron(animateD20(p, t, audio));
    return result;
}

float evaluateDiceBoundary(vec3 p, float t, float audio) {
    float cycle = SHAPE_TIME + MORPH_TIME;
    float mod_t = mod(t, cycle * float(NUM_DICE));

    int curr = int(floor(mod_t / cycle));
    float local = mod(mod_t, cycle);

    float morph = 0.0;
    int next = curr;

    if (local > SHAPE_TIME) {
        morph = smoothstep(0.0, 1.0, (local - SHAPE_TIME) / MORPH_TIME);
        next = (curr + 1) % NUM_DICE;
    }

    float d1 = evaluateDie(curr, p, t, audio);
    float d2 = evaluateDie(next, p, t, audio);

    return mix(d1, d2, morph);
}

// ============================================
// MAIN SHADER
// ============================================

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 r = iResolution.xy;
    vec2 FC = fragCoord;
    vec4 o = vec4(0.0);

    // Get audio data
    float bass = getAudioBass();
    float mids = getAudioMids();
    float highs = getAudioHighs();
    float audio = (bass + mids + highs) / 3.0;  // Average for overall reactivity

    float time = iTime;

    // Audio-reactive grid scaling
    float gridScale = 1.0 + audio * AUDIO_GRID_SCALE;

    // Process RGB channels (chromatic separation)
    for(int channel = 0; channel < 3; channel++) {
        float Z = float(channel - 1) * CHROMA_SPREAD / 0.02; // Normalize to original scale
        float channelValue = 0.0;
        bool skip = false;

        float d = 0.0;
        for(float i = 0.0; i < RAY_STEPS; i += 1.0) {
            if(skip) break;

            vec3 p = vec3((FC * 2.0 - r) / r.y * d, d - 8.0);

            if(abs(p.x) > 5.0) {
                skip = true;
                continue;
            }

            // Camera rotations
            p.xz *= rotate2D(time * ROT_SPEED_XZ);
            p.xy *= rotate2D(time * ROT_SPEED_XY);

            // Audio-reactive grid
            float gd = GRID_DENSITY * gridScale;
            vec3 g = floor(p * gd);
            vec3 f = fract(p * gd) - 0.5;

            // === ENHANCED DOT AUDIO REACTIVITY ===

            // Random values for this dot
            float rand1 = fract(sin(dot(g, vec3(127.0, 312.0, 75.0))) * 43758.0);
            float rand2 = fract(sin(dot(g, vec3(44.0, 78.0, 123.0))) * 127.0);
            float rand3 = fract(sin(dot(g, vec3(91.0, 253.0, 17.0))) * 8934.0); // For frequency selection

            // Get this dot's assigned audio frequency
            float dotAudio = getDotAudio(rand3, bass, mids, highs) * DOT_AUDIO_INTENSITY;

            // Audio-reactive dot SIZE
            float baseSize = rand1 * 0.3 + 0.1;
            float sizeBoost = DOT_SIZE_REACTIVE * dotAudio * DOT_SIZE_AMOUNT * DOT_AUDIO_INTENSITY;
            float dotSize = baseSize + sizeBoost;
            float h = step(length(f), dotSize);

            // Random angle with audio hue shift (use bass for color shifts)
            float a = rand2 * TAU + bass * AUDIO_HUE_SHIFT * 30.0 + mids * 15.0 + time * 0.5;

            // Nested boxes
            float e = 1.0;
            float sc = 2.0;
            for(int j = 0; j < NESTED_BOX_ITERS; j++) {
                vec3 g2 = abs(fract(p * sc / 2.0) * 2.0 - 1.0);
                e = min(e, min(max(g2.x, g2.y), min(max(g2.y, g2.z), max(g2.x, g2.z))) / sc);
                sc *= 0.6;
            }

            // Dice morphing SDF
            vec3 pScaled = p / 3.0;
            float c = evaluateDiceBoundary(pScaled, time, audio) * 3.0;

            // Ray step with chromatic offset
            float sinC = length(sin(c));
            float s = 0.01 + 0.15 * abs(max(max(c, e - 0.1), sinC - 0.3) + Z * CHROMA_SPREAD - i / 130.0);
            d += s;

            // === ENHANCED DOT BRIGHTNESS ===
            float sf = smoothstep(0.02, 0.01, s);

            // Base audio brightness (existing)
            float audioBrightness = 1.0 + audio * 3.0;

            // NEW: Per-dot audio brightness boost
            float dotBrightBoost = DOT_BASE_BRIGHT_BOOST;
            dotBrightBoost += DOT_BRIGHTNESS_REACTIVE * dotAudio * DOT_BRIGHT_AMOUNT * DOT_AUDIO_INTENSITY;

            // Color accumulation with enhanced dot brightness
            channelValue += COLOR_INTENSITY * audioBrightness / s * (
                0.5 + 0.5 * sin(i * 0.3 + Z * 5.0) +
                sf * DOT_BRIGHTNESS * dotBrightBoost * h * sin(a + i * 0.4 + Z * 5.0)
            );
        }

        if(channel == 0) o.r = channelValue;
        else if(channel == 1) o.g = channelValue;
        else o.b = channelValue;
    }

    // Tone mapping
    o = o * o / EXPOSURE;
    vec4 exp2o = exp(CONTRAST * o);
    o = (exp2o - 1.0) / (exp2o + 1.0);

    fragColor = o;
}
