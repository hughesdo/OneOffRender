// Where Is Her Mind Plasma - Audio Reactive Shader
// Electric plasma ring with Rive vector feathering
// Converted from Shadertoy to OneOffRender format

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

// ============ TWEAK THESE ============
#define INTENSITY       0.8      // Overall brightness (0.5 - 8.0)
#define SPEED           0.6      // Animation speed (0.1 - 3.0)
#define TURBULENCE      1.4      // Plasma warp displacement (0.3 - 3.0)
#define RING_RADIUS     0.20     // Plasma ring center radius (0.2 - 0.7)
#define RING_WIDTH      0.22     // Plasma band thickness (0.05 - 0.5)
#define INNER_FALLOFF   0.18     // Inner edge hardness — low = sharp (0.01 - 0.3)
#define OUTER_FALLOFF   0.20     // Outer edge fade distance (0.05 - 0.5)
#define FEATHER_MAX     1.55     // Rive feather softness (0.0 - 1.5)
#define TENDRIL_SCALE   3.5      // Tendril pattern scale (1.0 - 8.0)
#define BRANCH_DEPTH    4        // Fractal detail octaves (3 - 8)
#define BASS_GAIN       1.6      // Bass reactivity (0.0 - 5.0)
#define MID_GAIN        1.0      // Mid-freq reactivity (0.0 - 3.0)
#define FLICKER_AMOUNT  0.25     // Audio flicker intensity (0.0 - 1.0)
#define TENDRIL_REACH   0.18     // How far tendrils extend beyond ring (0.0 - 0.4)
#define COLOR_PURPLE    1.2      // Purple/violet strength (0.0 - 1.5)
#define COLOR_BLUE      1.5      // Electric blue strength (0.0 - 2.0)
#define COLOR_WARMTH    0.7      // Amber/orange edge tint (0.0 - 1.0)
#define HOT_CORE        1.5      // White-hot highlight intensity (0.5 - 5.0)
#define BASS_RADIUS_FX  0.4      // Ring breathe amount from bass (0.0 - 0.1)
#define BASS_TURB_FX    0.8      // Extra turbulence from bass (0.0 - 2.0)
// =====================================


// ---- Rive Feathering (erf approximation) ----

float erf(float x) {
    float s = sign(x);
    x = abs(x);
    float t = 1.0 / (1.0 + 0.3275911 * x);
    float y = 1.0 - (((((1.061405429*t - 1.453152027)*t) + 1.421413741)*t
              - 0.284496736)*t + 0.254829592)*t * exp(-x*x);
    return s * y;
}

float featherDensity(float d, float r) {
    if (r < 1e-8) return d < 0.0 ? 1.0 : 0.0;
    return 0.5 * (1.0 - erf(d / (r * 1.41421356)));
}


// ---- Noise Primitives ----

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash21(i),             hash21(i + vec2(1, 0)), f.x),
        mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x),
        f.y
    );
}

float ridged(vec2 p) {
    float n = vnoise(p);
    n = abs(n * 2.0 - 1.0);
    n = 1.0 - n;
    return n * n;
}

float ridgedFBM(vec2 p, int oct, float tm) {
    float sum  = 0.0;
    float amp  = 0.5;
    float freq = 1.0;
    float prev = 1.0;
    for (int i = 0; i < 8; i++) {
        if (i >= oct) break;
        float drift = tm * (0.25 + float(i) * 0.08);
        float n = ridged(p * freq + drift);
        sum  += n * amp * prev;
        prev  = clamp(n * 1.2, 0.0, 1.0);
        freq *= 2.15;
        amp  *= 0.50;
    }
    return sum;
}


// ---- Domain Warping ----

float warpedPlasma(vec2 p, float tm, float extraTurb) {
    float turb = TURBULENCE + extraTurb;
    vec2 q = vec2(
        ridgedFBM(p + vec2(0.0, 0.0), BRANCH_DEPTH, tm * 0.6),
        ridgedFBM(p + vec2(5.2, 1.3),  BRANCH_DEPTH, tm * 0.7)
    );
    vec2 r = vec2(
        ridgedFBM(p + turb * q + vec2(1.7, 9.2), BRANCH_DEPTH, tm * 0.45),
        ridgedFBM(p + turb * q + vec2(8.3, 2.8), BRANCH_DEPTH, tm * 0.55)
    );
    return ridgedFBM(p + turb * r, BRANCH_DEPTH, tm);
}


// ---- Audio Extraction ----

float getBass() {
    float b = 0.0;
    b += texture(iChannel0, vec2(0.01, 0.0)).x;
    b += texture(iChannel0, vec2(0.02, 0.0)).x;
    b += texture(iChannel0, vec2(0.04, 0.0)).x;
    b += texture(iChannel0, vec2(0.07, 0.0)).x;
    b += texture(iChannel0, vec2(0.10, 0.0)).x;
    return b / 5.0;
}

float getMid() {
    float m = 0.0;
    m += texture(iChannel0, vec2(0.15, 0.0)).x;
    m += texture(iChannel0, vec2(0.25, 0.0)).x;
    m += texture(iChannel0, vec2(0.35, 0.0)).x;
    return m / 3.0;
}

float getHigh() {
    return (texture(iChannel0, vec2(0.55, 0.0)).x +
            texture(iChannel0, vec2(0.75, 0.0)).x) * 0.5;
}



// ---- Main ----

void mainImage(out vec4 O, in vec2 I) {
    vec2 uv = (I - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime * SPEED;

    // --- Audio ---
    float bass   = getBass() * BASS_GAIN;
    float mid    = getMid()  * MID_GAIN;
    float high   = getHigh();
    float energy = bass * 0.5 + mid * 0.3 + high * 0.2;

    // --- Ring geometry ---
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    float ringR = RING_RADIUS + bass * BASS_RADIUS_FX;

    float angularNoise = vnoise(vec2(a * 2.5, t * 0.3)) * 2.0 - 1.0;
    float reachNoise   = vnoise(vec2(a * 4.0 + 100.0, t * 0.2)) * TENDRIL_REACH;
    float localWidth   = RING_WIDTH + reachNoise + angularNoise * 0.06;

    float ringDist = abs(r - ringR) - localWidth * 0.5;

    float innerEdge = r - (ringR - localWidth * 0.5);
    float outerEdge = (ringR + localWidth * 0.5) - r;

    float innerMask = featherDensity(-innerEdge, INNER_FALLOFF);
    float outerMask = featherDensity(-outerEdge, OUTER_FALLOFF);
    float ringMask  = (1.0 - innerMask) * (1.0 - outerMask);

    float featherMask = featherDensity(ringDist, FEATHER_MAX);
    ringMask = max(ringMask, featherMask * 0.5);

    ringMask *= smoothstep(ringR - localWidth * 0.5 - 0.02,
                           ringR - localWidth * 0.5 + INNER_FALLOFF, r);

    // --- Plasma generation ---
    vec2 plasmaUV = vec2(a / 6.2831853 * TENDRIL_SCALE, r * TENDRIL_SCALE);
    float extraTurb = bass * BASS_TURB_FX;

    float p1 = warpedPlasma(plasmaUV, t, extraTurb);
    float p2 = warpedPlasma(plasmaUV * 1.7 + vec2(7.7, 3.1), t * 1.25, extraTurb * 0.7);
    float p3 = ridgedFBM(uv * TENDRIL_SCALE * 2.5 + vec2(t * 0.15, -t * 0.1),
                         BRANCH_DEPTH, t * 0.8);

    float plasma = p1 * 0.50 + p2 * 0.30 + p3 * 0.20;
    plasma *= 1.0 + bass * 1.2 + mid * 0.4;
    plasma = pow(max(plasma, 0.0), 1.4 - mid * 0.2);

    float flicker = 1.0 + FLICKER_AMOUNT * sin(t * 18.0 + bass * 10.0) * bass;
    plasma *= flicker;

    float P = plasma * ringMask;

    // --- Color palette ---
    vec3 col = vec3(0.0);

    col += vec3(0.55, 0.04, 0.92) * COLOR_PURPLE * P;
    col += vec3(0.08, 0.20, 1.0)  * COLOR_BLUE   * pow(max(P, 0.0), 1.3);
    col += vec3(0.75, 0.70, 1.0)  * pow(max(P, 0.0), 2.8) * 1.6;
    col += vec3(1.0,  0.55, 0.05) * pow(max(P, 0.0), 3.5) * HOT_CORE;

    float outerBlend = smoothstep(ringR, ringR + localWidth * 0.6, r);
    col += vec3(1.0, 0.50, 0.08) * COLOR_WARMTH * P * outerBlend;

    float innerBlend = smoothstep(ringR, ringR - localWidth * 0.5, r);
    col += vec3(0.9, 0.40, 0.12) * COLOR_WARMTH * 0.3 * P * innerBlend;

    col *= INTENSITY * (0.7 + energy * 1.5);
    col += vec3(0.5, 0.25, 0.7) * bass * 0.08 * ringMask;

    O = vec4(max(col, 0.0), 1.0);
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}
