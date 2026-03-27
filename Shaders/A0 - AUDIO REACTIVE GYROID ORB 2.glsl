#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

/*
    AUDIO REACTIVE RAINBOW GYROID ORB
    ==================================
    Centered gyroid cage with plasma core - RAINBOW edition

    Setup: iChannel0 = Audio (mic or music)
*/

// ============================================
// AUDIO REACTIVITY TWEAKS
// ============================================
#define BASS_FREQ           1.00
#define BASS_SMOOTHING      0.2
#define PLASMA_BASE         1.8
#define PLASMA_PULSE        5.0
#define CAGE_GLOW_MULT      1.0

// ============================================
// RAINBOW PARAMETERS
// ============================================
#define RAINBOW_SPEED       0.3       // How fast the rainbow cycles over time
#define RAINBOW_SPREAD      2.0       // Spatial spread of rainbow across surface
#define RAINBOW_SATURATION  1.0       // Color saturation (0=white, 1=full)
#define BASS_HUE_SHIFT      0.4       // How much bass shifts the hue
#define VIBRANCE_BOOST      1.4       // Overall color intensity multiplier

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

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(1.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

// Rainbow color from hue offset
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

// Gyroid function for orb cage
float orbGyroid(vec3 p) {
    float scale = ORB_GYROID_SCALE;
    vec3 p2 = p * scale;

    p2.xy *= Rot(iTime * ORB_SPIN_SPEED);
    p2.yz *= Rot(iTime * ORB_SPIN_SPEED * 0.7);

    return (abs(dot(sin(p2), cos(p2.zxy))) - ORB_GYROID_THICK) / scale;
}

// The alien orb - gyroid cage with plasma core
float alienOrb(vec3 p) {
    float distFromCenter = length(p);

    float sphere = abs(distFromCenter - ORB_RADIUS) - ORB_SHELL_THICK;
    float cage = smin(sphere, orbGyroid(p) * 0.7, -0.03);
    float core = distFromCenter - PLASMA_CORE_SIZE;

    float plasmaIntensity = PLASMA_BASE + bassLevel * PLASMA_PULSE;
    plasmaLight += plasmaIntensity / max(core * core, 0.001);

    float cageGlow = CAGE_GLOW_MULT / max(abs(cage), 0.01);
    orbLight += cageGlow * (1.0 + bassLevel * 2.0);

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

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    bassLevel = clamp(getFFTSmoothed(BASS_FREQ) * 1.5, 0.0, 1.0);

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
        // Spatial hue: varies across the surface using position
        float spatialHue = dot(hitPos, vec3(1.0, 0.7, 0.5)) * RAINBOW_SPREAD;
        // Time cycling
        float timeHue = iTime * RAINBOW_SPEED;
        // Bass shifts the whole spectrum
        float bassHue = bassLevel * BASS_HUE_SHIFT;

        float hue1 = spatialHue + timeHue + bassHue;

        // Cage color: full rainbow, brightens with bass
        float cageBright = 0.85 + bassLevel * 0.15;
        vec3 cageColor = rainbow(hue1, RAINBOW_SATURATION, cageBright);

        // Plasma core: offset hue, high value, slightly less saturated for glow
        float plasmaHue = hue1 + 0.15;
        vec3 plasmaColor = rainbow(plasmaHue, RAINBOW_SATURATION * 0.65, 1.0);

        // Cage structure color
        col += cageColor * (coreDiff * 0.6 + 0.3);

        // Fresnel rim with plasma color
        col += fresnel * plasmaColor * (1.0 + bassLevel * 2.0);

        // Subsurface scattering approximation
        float sss = pow(max(0.0, dot(rd, toCore)), 2.0) * 0.5;
        col += sss * plasmaColor * (1.0 + bassLevel * PLASMA_PULSE);

        // Vein-like pulsing pattern with its own hue offset
        float veinPattern = abs(dot(sin(hitPos * 30.0 + iTime * 2.0), cos(hitPos.zxy * 30.0)));
        veinPattern = smoothstep(0.3, 0.5, veinPattern);
        vec3 veinColor = rainbow(hue1 + 0.33, RAINBOW_SATURATION, 1.0);
        col += veinColor * veinPattern * 0.45 * (1.0 + bassLevel * 3.0);
    }

    // Background - dark with subtle gradient
    vec3 bg = vec3(0.02, 0.01, 0.03);
    bg += vec3(0.02, 0.01, 0.02) * (1.0 - length(uv));
    col = max(col, bg);

    // Plasma core glow - rainbow
    float glowHue = iTime * RAINBOW_SPEED * 0.5 + bassLevel * BASS_HUE_SHIFT;
    vec3 plasmaGlowColor = rainbow(glowHue, RAINBOW_SATURATION * 0.5, 1.0);
    col += plasmaGlowColor * plasmaLight * 0.00004 * (1.0 + bassLevel * 2.0);

    // Cage atmospheric glow - complementary rainbow
    vec3 cageGlowColor = rainbow(glowHue + 0.5, RAINBOW_SATURATION * 0.8, 1.0);
    col += cageGlowColor * orbLight * 0.0004;

    // Screen-wide pulse on bass hits
    float pulse = pow(bassLevel, 3.0);
    col *= 1.0 + pulse * 0.3;

    // Vibrance boost
    col *= VIBRANCE_BOOST;

    // Tone mapping
    col = tanh(col * 0.6);

    // Vignette
    col *= 1.0 - 0.1 * length(uv);

    // Edge glow on bass - cycles through rainbow
    vec3 edgeColor = rainbow(glowHue + 0.25, RAINBOW_SATURATION, 1.0);
    col += edgeColor * bassLevel * 0.05 * pow(length(uv), 2.0);

    fragColor = vec4(col, 1.0);
}
