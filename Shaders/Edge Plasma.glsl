// =========================================================
// "Edge Plasma" - Audio Reactive Edge Tendril Shader v2
// =========================================================
// Tendrils reach INWARD from screen edges. Center stays
// completely clear for compositing over a centered subject.
// Black background for Screen/Add blend in After Effects.
//
// Techniques:
//   XorDev  - Sine-wave turbulence (rotation + octave stacking)
//   iq      - Ridged noise, domain warping, cosine palettes
//   Edge-distance masking for peripheral-only composition
// =========================================================

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;

// --- iq cosine palette: purple -> blue -> magenta -> white-hot ---
vec3 palette(float t) {
    vec3 a = vec3(0.4, 0.25, 0.55);
    vec3 b = vec3(0.45, 0.35, 0.45);
    vec3 c = vec3(0.8, 0.9, 0.7);
    vec3 d = vec3(0.65, 0.2, 0.55);
    return a + b * cos(6.28318 * (c * t + d));
}

// --- Hash noise (GPU-stable) ---
float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
        mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x),
        f.y
    );
}

// --- Ridged noise: sharp branching structures ---
float ridged(vec2 p) {
    return 1.0 - abs(noise(p) * 2.0 - 1.0);
}

// --- FBM with ridged octaves (lightning/electric look) ---
float fbmRidged(vec2 p) {
    float val = 0.0, amp = 0.55, freq = 1.0;
    mat2 rot = mat2(0.8, -0.6, 0.6, 0.8);
    for (int i = 0; i < 6; i++) {
        float r = ridged(p * freq);
        r = pow(r, 1.6);
        val += amp * r;
        p = rot * p;
        freq *= 2.1;
        amp *= 0.48;
    }
    return val;
}

// --- Standard smooth FBM ---
float fbm(vec2 p) {
    float val = 0.0, amp = 0.5, freq = 1.0;
    mat2 rot = mat2(0.8, -0.6, 0.6, 0.8);
    for (int i = 0; i < 5; i++) {
        val += amp * noise(p * freq);
        p = rot * p;
        freq *= 2.02;
        amp *= 0.5;
    }
    return val;
}

// --- XorDev turbulence: sine-wave displacement with rotation ---
vec2 turbulence(vec2 pos, float time, float amp, float speed) {
    float freq = 1.8;
    mat2 rot = mat2(0.6, -0.8, 0.8, 0.6);
    for (int i = 0; i < 7; i++) {
        float phase = freq * (pos * rot).y + speed * time + float(i) * 0.7;
        pos += amp * rot[0] * sin(phase) / freq;
        rot *= mat2(0.6, -0.8, 0.8, 0.6);
        freq *= 1.5;
    }
    return pos;
}

// --- Audio helpers ---
float getAudio(float freq) {
    return texture(iChannel0, vec2(freq, 0.25)).x;
}

float getBass() {
    return (getAudio(0.01) + getAudio(0.02) + getAudio(0.04)
          + getAudio(0.06) + getAudio(0.08)) / 5.0;
}

float getMids() {
    return (getAudio(0.12) + getAudio(0.18)
          + getAudio(0.25) + getAudio(0.32)) / 4.0;
}

float getHighs() {
    return (getAudio(0.45) + getAudio(0.55)
          + getAudio(0.65) + getAudio(0.75)) / 4.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Y-flip to match Shadertoy coordinate system
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 uvNorm = fragCoord / iResolution.xy;

    // --- Audio ---
    float bass   = getBass();
    float mids   = getMids();
    float highs  = getHighs();
    float energy = bass * 0.5 + mids * 0.3 + highs * 0.2;
    float t = iTime;

    // ==========================================================
    // EDGE DISTANCE (how close to the nearest screen border)
    // ==========================================================
    float dLeft   = uvNorm.x;
    float dRight  = 1.0 - uvNorm.x;
    float dBottom = uvNorm.y;
    float dTop    = 1.0 - uvNorm.y;
    float edgeDist = min(min(dLeft, dRight), min(dBottom, dTop));
    float cornerDist = length(uvNorm - 0.5) / 0.707;

    // ==========================================================
    // EDGE MASK: effect on periphery only, center protected
    // ==========================================================
    float reachDepth = 0.18 + 0.12 * bass + 0.05 * energy;
    float edgeMask = 1.0 - smoothstep(0.0, reachDepth, edgeDist);

    // Corner emphasis
    float cornerBoost = smoothstep(0.4, 0.95, cornerDist) * 0.5;
    edgeMask = max(edgeMask, cornerBoost * (0.6 + 0.4 * energy));

    // Hard center protection
    float centerKill = smoothstep(0.3 + 0.08 * bass, 0.18, edgeDist);
    edgeMask *= centerKill;

    if (edgeMask < 0.002) { fragColor = vec4(0.0); return; }

    // ==========================================================
    // TENDRIL COORDINATES
    // ==========================================================
    float angle = atan(uv.y, uv.x);
    float r = length(uv);
    float depth = edgeDist * 5.0;
    vec2 tendrilUV = vec2(angle * 1.5, depth);

    // ==========================================================
    // XorDev TURBULENCE
    // ==========================================================
    float turbAmp   = 0.5 + 0.5 * bass;
    float turbSpeed = 0.25 + 0.3 * mids;
    vec2 warped = turbulence(tendrilUV, t, turbAmp, turbSpeed);

    // ==========================================================
    // ELECTRIC TENDRIL PATTERN
    // ==========================================================
    // iq domain warp into ridged noise
    float warpT = t * 0.12;
    vec2 q = vec2(
        fbm(warped * 0.8 + vec2(1.7, 9.2) + warpT),
        fbm(warped * 0.8 + vec2(8.3, 2.8) - warpT * 0.8)
    );

    // Primary branching
    float branches = fbmRidged(warped * 1.2 + 2.5 * q);

    // Fine electric detail (highs-reactive)
    float fineScale = 3.0 + 3.0 * highs;
    float fineDetail = ridged(warped * fineScale + t * 0.3);
    fineDetail = pow(fineDetail, 2.0) * 0.5;

    // Broad glow
    float broadGlow = fbm(warped * 0.5 + t * 0.08);

    // Radial tendrils
    float radialTendrils = ridged(vec2(angle * 3.0 + fbm(tendrilUV * 1.5) * 2.0,
                                       depth * 2.0 - t * 0.15));
    radialTendrils = pow(radialTendrils, 2.5);

    // ==========================================================
    // COMBINE
    // ==========================================================
    float intensity = 0.0;
    intensity += branches * 0.5;
    intensity += fineDetail * (0.3 + 0.3 * highs);
    intensity += broadGlow * 0.25;
    intensity += radialTendrils * 0.4;

    float edgeBrightness = 1.0 - smoothstep(0.0, reachDepth * 1.2, edgeDist);
    intensity *= edgeBrightness * edgeMask;
    intensity *= 0.6 + 1.8 * energy;
    intensity = pow(max(intensity, 0.0), 1.3);

    // ==========================================================
    // COLOR
    // ==========================================================
    float colorParam = intensity * 0.8 + angle * 0.06 + t * 0.03 + bass * 0.15;
    vec3 col = palette(colorParam);

    // Blue-white electric cores
    col = mix(col, vec3(0.7, 0.8, 1.0), smoothstep(0.35, 0.8, intensity));

    // White-hot peaks
    col += vec3(0.9, 0.85, 1.0) * smoothstep(0.6, 1.2, intensity) * 0.5;

    col *= intensity * 2.2;

    // Deep purple tint in dim regions
    col += vec3(0.18, 0.04, 0.28) * edgeMask *
           (1.0 - smoothstep(0.0, 0.15, intensity)) * 0.4;

    // Orange/gold plasma nodes
    float hotSpots = pow(noise(warped * 3.0 + t * 0.5), 4.0);
    col += vec3(0.9, 0.5, 0.15) * hotSpots * edgeMask * bass * 1.5;

    // Sparkle on highs
    float sparkle = hash21(floor(fragCoord * 0.3) + floor(t * 8.0));
    sparkle = pow(sparkle, 40.0) * highs * 4.0 * edgeMask;
    col += vec3(0.7, 0.6, 1.0) * sparkle;

    // Tone map
    col = tanh(col * 1.1);

    fragColor = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
