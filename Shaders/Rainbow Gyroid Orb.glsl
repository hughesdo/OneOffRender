// Rainbow Gyroid Orb - Audio Reactive Shader
// Centered gyroid cage with plasma core - RAINBOW edition
// Converted from Shadertoy to OneOffRender format

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

// ============================================
// AUDIO REACTIVITY TWEAKS
// ============================================
#define BASS_FREQ           1.00
#define BASS_SMOOTHING      0.2
#define PLASMA_BASE         1.8
#define PLASMA_PULSE        12.0
#define CAGE_GLOW_MULT      2.5

// ============================================
// RAINBOW PARAMETERS
// ============================================
#define RAINBOW_SPEED       0.3
#define RAINBOW_SPREAD      2.0
#define RAINBOW_SATURATION  1.0
#define BASS_HUE_SHIFT      1.0
#define VIBRANCE_BOOST      2.0

// ============================================
// ORB PARAMETERS
// ============================================
#define ORB_RADIUS          0.4
#define ORB_SHELL_THICK     0.03
#define ORB_GYROID_SCALE    24.0
#define ORB_GYROID_THICK    0.25
#define PLASMA_CORE_SIZE    0.15
#define ORB_SPIN_SPEED      0.5

// ============================================
// CAMERA
// ============================================
#define CAM_DIST            1.2

// Globals
float orbLight;
float plasmaLight;
float bassLevel;

mat2 Rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}

vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec3 rainbow(float hue, float sat, float val) {
    return hsv2rgb(vec3(fract(hue), sat, val));
}

float getFFTSmoothed(float freq) {
    float sum = 0.0;
    for (float i = -2.0; i <= 2.0; i++) {
        sum += texture(iChannel0, vec2(freq + i * BASS_SMOOTHING * 0.1, 0.0)).x;
    }
    return sum / 5.0;
}

float orbGyroid(vec3 p) {
    float scale = ORB_GYROID_SCALE;
    vec3 p2 = p * scale;

    p2.xy *= Rot(iTime * ORB_SPIN_SPEED);
    p2.yz *= Rot(iTime * ORB_SPIN_SPEED * 0.7);

    return (abs(dot(sin(p2), cos(p2.zxy))) - ORB_GYROID_THICK) / scale;
}

float alienOrb(vec3 p) {
    float distFromCenter = length(p);

    float sphere = abs(distFromCenter - ORB_RADIUS) - ORB_SHELL_THICK;
    float cage = smin(sphere, orbGyroid(p) * 0.7, -0.03);
    float core = distFromCenter - PLASMA_CORE_SIZE;

    float plasmaIntensity = PLASMA_BASE + bassLevel * PLASMA_PULSE;
    plasmaLight += plasmaIntensity / max(core * core, 0.001);

    float cageGlow = CAGE_GLOW_MULT / max(abs(cage), 0.01);
    orbLight += cageGlow * (1.0 + bassLevel * 5.0);

    return cage;
}

float map(vec3 p) {
    return alienOrb(p);
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.001, 0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    bassLevel = clamp(getFFTSmoothed(BASS_FREQ) * 3.0, 0.0, 1.0);

    orbLight = 0.0;
    plasmaLight = 0.0;

    vec3 ro = vec3(0.0, 0.0, -CAM_DIST);
    vec3 rd = normalize(vec3(uv, 1.0));

    // Raymarch
    float d = 0.0;
    vec3 col = vec3(0);
    vec3 hitPos;
    bool hit = false;

    for (float i = 0.0; i < 100.0; i++) {
        vec3 p = ro + rd * d;
        float s = map(p);

        if (s < 0.005) {
            hit = true;
            hitPos = p;
            break;
        }

        d += s * 0.8;
        if (d > 20.0) break;
    }

    // Surface shading
    if (hit) {
        vec3 n = getNormal(hitPos);

        vec3 toCore = normalize(-hitPos);
        float coreDiff = max(dot(n, toCore), 0.0);
        float fresnel = pow(1.0 - abs(dot(n, -rd)), 3.0);

        // === RAINBOW HUES ===
        float spatialHue = dot(hitPos, vec3(1.0, 0.7, 0.5)) * RAINBOW_SPREAD;
        float timeHue = iTime * RAINBOW_SPEED;
        float bassHue = bassLevel * BASS_HUE_SHIFT;

        float hue1 = spatialHue + timeHue + bassHue;

        float cageBright = 0.85 + bassLevel * 0.15;
        vec3 cageColor = rainbow(hue1, RAINBOW_SATURATION, cageBright);

        float plasmaHue = hue1 + 0.15;
        vec3 plasmaColor = rainbow(plasmaHue, RAINBOW_SATURATION, 1.0);

        col += cageColor * (coreDiff * 0.9 + 0.55);
        col += fresnel * plasmaColor * (1.0 + bassLevel * 6.0);

        float sss = pow(max(0.0, dot(rd, toCore)), 2.0) * 0.5;
        col += sss * plasmaColor * (1.0 + bassLevel * PLASMA_PULSE);

        float veinPattern = abs(dot(sin(hitPos * 30.0 + iTime * 2.0), cos(hitPos.zxy * 30.0)));
        veinPattern = smoothstep(0.3, 0.5, veinPattern);
        vec3 veinColor = rainbow(hue1 + 0.33, RAINBOW_SATURATION, 1.0);
        col += veinColor * veinPattern * 0.8 * (1.0 + bassLevel * 8.0);
    }

    // Background
    vec3 bg = vec3(0.02, 0.01, 0.03);
    bg += vec3(0.02, 0.01, 0.02) * (1.0 - length(uv));
    col = max(col, bg);

    // Plasma core glow
    float glowHue = iTime * RAINBOW_SPEED * 0.5 + bassLevel * BASS_HUE_SHIFT;
    vec3 plasmaGlowColor = rainbow(glowHue, RAINBOW_SATURATION * 0.5, 1.0);
    col += plasmaGlowColor * plasmaLight * 0.000035 * (1.0 + bassLevel * 2.0);

    // Cage atmospheric glow
    vec3 cageGlowColor = rainbow(glowHue + 0.5, RAINBOW_SATURATION * 0.8, 1.0);
    col += cageGlowColor * orbLight * 0.0004 * (1.0 + bassLevel * 1.5);

    // Bass pulse
    float pulse = pow(bassLevel, 3.0);
    col *= 1.0 + pulse * 0.8;

    col *= VIBRANCE_BOOST;

    // Tone mapping
    col = tanh(col * 0.45);

    // Vignette
    col *= 1.0 - 0.1 * length(uv);

    // Edge glow on bass
    vec3 edgeColor = rainbow(glowHue + 0.25, RAINBOW_SATURATION, 1.0);
    col += edgeColor * bassLevel * 0.15 * pow(length(uv), 2.0);

    fragColor = vec4(col, 1.0);
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}

