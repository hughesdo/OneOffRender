// Raymarched Neon Tunnel Shader for Shadertoy
// Audio Reactive Version - Uses iChannel0 for audio input
// Copy this entire code into Shadertoy's "Image" tab
// Set iChannel0 to "Soundcloud" or any audio source

// ============================================================
// AUDIO REACTIVITY TWEAKING VARIABLES - Adjust these!
// ============================================================

// Master toggle: set to 0.0 to completely disable all audio effects
#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;


#define AUDIO_ENABLED 1.0

// Individual effect toggles (0.0 = off, 1.0 = on)
#define ENABLE_PALETTE_SHIFT 1.0      // Audio shifts the color palette
#define ENABLE_GLOW_PULSE 1.0         // Bass boosts glow/bloom intensity
#define ENABLE_SATURATION_BOOST 1.0   // Mids enhance color saturation
#define ENABLE_COLOR_TEMP_SHIFT 1.0   // Treble shifts color temperature (warm/cool)
#define ENABLE_HUE_ROTATE 1.0         // Overall audio rotates hue
#define ENABLE_SCREEN_ROTATION 1.0    // Rotate the entire screen view

// Effect intensity multipliers (0.0 to 2.0+ range, 1.0 = default)
#define PALETTE_SHIFT_AMOUNT 3.0      // How much audio shifts palette (0.0-2.0)
#define GLOW_PULSE_AMOUNT 4.0         // Glow pulse intensity (0.0-2.0)
#define SATURATION_AMOUNT 2.5         // Saturation boost strength (0.0-2.0)
#define COLOR_TEMP_AMOUNT 2.0         // Color temperature shift (0.0-2.0)
#define HUE_ROTATE_AMOUNT 3.0         // Hue rotation strength (0.0-2.0)
#define SCREEN_ROTATION_SPEED 0.1     // Screen rotation speed (0.0-1.0, higher = faster)

// Audio frequency band weights (tune to your music)
#define BASS_FREQ 0.05                // Where to sample bass (0.0-0.3)
#define MID_FREQ 0.3                  // Where to sample mids (0.3-0.6)
#define TREBLE_FREQ 0.7               // Where to sample treble (0.6-1.0)

// Smoothing (higher = smoother/slower response, 0.0 = instant)
#define AUDIO_SMOOTH 0.3

// ============================================================
// END TWEAKING VARIABLES
// ============================================================

#define MAX_STEPS 100
#define MAX_DIST 50.0
#define SURF_DIST 0.001

// Audio analysis - extracts frequency bands with smoothing
vec3 getAudio() {
    if(AUDIO_ENABLED < 0.5) return vec3(0.0);

    // Sample multiple points in each frequency band for stability
    float bass = 0.0;
    float mid = 0.0;
    float treble = 0.0;

    // Bass: low frequencies
    for(float i = 0.0; i < 0.2; i += 0.05) {
        bass += texture(iChannel0, vec2(BASS_FREQ + i, 0.0)).x;
    }
    bass /= 4.0;

    // Mids: middle frequencies
    for(float i = 0.0; i < 0.2; i += 0.05) {
        mid += texture(iChannel0, vec2(MID_FREQ + i, 0.0)).x;
    }
    mid /= 4.0;

    // Treble: high frequencies
    for(float i = 0.0; i < 0.2; i += 0.05) {
        treble += texture(iChannel0, vec2(TREBLE_FREQ + i, 0.0)).x;
    }
    treble /= 4.0;

    // Apply smoothing via power curve
    bass = pow(bass, AUDIO_SMOOTH);
    mid = pow(mid, AUDIO_SMOOTH);
    treble = pow(treble, AUDIO_SMOOTH);

    return vec3(bass, mid, treble);
}

// Rotation matrix
mat2 rot2D(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

// Hash function
float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

// Simplex-like noise
float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float n = i.x + i.y * 157.0 + 113.0 * i.z;
    return mix(
        mix(mix(hash21(vec2(n + 0.0, n + 0.0)), hash21(vec2(n + 1.0, n + 1.0)), f.x),
            mix(hash21(vec2(n + 157.0, n + 157.0)), hash21(vec2(n + 158.0, n + 158.0)), f.x), f.y),
        mix(mix(hash21(vec2(n + 113.0, n + 113.0)), hash21(vec2(n + 114.0, n + 114.0)), f.x),
            mix(hash21(vec2(n + 270.0, n + 270.0)), hash21(vec2(n + 271.0, n + 271.0)), f.x), f.y),
        f.z);
}

// Fractal Brownian Motion
float fbm(vec3 p) {
    float f = 0.0;
    f += 0.5000 * noise(p); p *= 2.02;
    f += 0.2500 * noise(p); p *= 2.03;
    f += 0.1250 * noise(p); p *= 2.01;
    f += 0.0625 * noise(p);
    return f / 0.9375;
}

// Audio-reactive cosine color palette
vec3 palette(float t, vec3 audio) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.33, 0.67);

    // Audio-reactive palette shift: bass shifts the phase
    float paletteShift = audio.x * 0.5 * PALETTE_SHIFT_AMOUNT * ENABLE_PALETTE_SHIFT;

    // Hue rotation based on overall audio energy
    float audioEnergy = (audio.x + audio.y + audio.z) / 3.0;
    float hueShift = audioEnergy * 0.3 * HUE_ROTATE_AMOUNT * ENABLE_HUE_ROTATE;

    d += vec3(paletteShift + hueShift);

    return a + b * cos(6.28318 * (c * t + d));
}

// Kaleidoscopic fold
vec3 kaleido(vec3 p) {
    float angle = 3.14159 / 4.0;
    p.xy = abs(p.xy);
    p.xy *= rot2D(angle);
    p.xy = abs(p.xy);
    p.xy *= rot2D(-angle * 0.5);
    return p;
}

// Scene SDF with displacement
float map(vec3 p) {
    float t = iTime * 0.5;

    // Move through tunnel
    p.z += t * 4.0;

    // Apply kaleidoscopic folding
    p = kaleido(p);

    // Tunnel base shape (box tunnel)
    float tunnel = -length(p.xy) + 2.5;

    // Add noise displacement
    vec3 np = p * 0.8;
    np.z *= 0.3;
    float disp = fbm(np + t * 0.5) * 1.2;

    tunnel += disp * 0.8;

    return tunnel;
}

// Calculate normal
vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

// Raymarching
float raymarch(vec3 ro, vec3 rd) {
    float d = 0.0;
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        float ds = map(p);
        d += ds;
        if(d > MAX_DIST || abs(ds) < SURF_DIST) break;
    }
    return d;
}

// RGB to HSV
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Get emission color based on noise - audio reactive
vec3 getEmission(vec3 p, vec3 audio) {
    float t = iTime * 0.5;
    p.z += t * 4.0;

    vec3 np = p * 0.8;
    np.z *= 0.3;
    float n = fbm(np + t * 0.5);

    // High noise = emission, low noise = dark metal
    float emitMask = smoothstep(0.3, 0.7, n);

    // Color based on noise and position - now audio reactive
    vec3 col = palette(n * 2.0 + t * 0.3 + p.z * 0.05, audio);

    // Audio-reactive glow pulse from bass
    float glowBoost = 1.0 + audio.x * 4.0 * GLOW_PULSE_AMOUNT * ENABLE_GLOW_PULSE;
    col *= emitMask * 3.0 * glowBoost;

    return col;
}

// Apply audio-reactive color post-processing
vec3 audioColorProcess(vec3 col, vec3 audio) {
    if(AUDIO_ENABLED < 0.5) return col;

    // Convert to HSV for manipulation
    vec3 hsv = rgb2hsv(col);

    // Saturation boost from mids
    float satBoost = audio.y * 0.5 * SATURATION_AMOUNT * ENABLE_SATURATION_BOOST;
    hsv.y = clamp(hsv.y * (1.0 + satBoost), 0.0, 1.0);

    // Convert back to RGB
    col = hsv2rgb(hsv);

    // Color temperature shift from treble (warm = more red, cool = more blue)
    float tempShift = (audio.z - 0.3) * COLOR_TEMP_AMOUNT * ENABLE_COLOR_TEMP_SHIFT;
    col.r *= 1.0 + tempShift * 0.3;
    col.b *= 1.0 - tempShift * 0.2;

    return col;
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Screen rotation - smooth continuous spin
    if(ENABLE_SCREEN_ROTATION > 0.5) {
        uv *= rot2D(iTime * SCREEN_ROTATION_SPEED);
    }

    // Get audio data once per frame
    vec3 audio = getAudio();

    // Camera setup
    vec3 ro = vec3(0.0, 0.0, 0.0);
    vec3 rd = normalize(vec3(uv, 1.0));

    // Slight camera rotation for dynamism
    float camRot = sin(iTime * 0.2) * 0.1;
    rd.xy *= rot2D(camRot);

    vec3 col = vec3(0.0);

    // Primary ray
    float d = raymarch(ro, rd);

    if(d < MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p);

        // Get emission at hit point - now audio reactive
        vec3 emit = getEmission(p, audio);

        // Fresnel for reflectivity
        float fresnel = pow(1.0 - abs(dot(-rd, n)), 3.0);

        // Reflection ray
        vec3 reflDir = reflect(rd, n);
        float reflDist = raymarch(p + n * 0.02, reflDir);

        vec3 reflCol = vec3(0.0);
        if(reflDist < MAX_DIST) {
            vec3 reflP = p + reflDir * reflDist;
            reflCol = getEmission(reflP, audio);
        }

        // Mix emission and reflection
        col = mix(emit, reflCol, fresnel * 0.6);

        // Add base emission
        col += emit * 0.3;

        // Ambient occlusion approximation
        float ao = 1.0 - float(d) / MAX_DIST;
        col *= ao;
    }

    // Apply audio color processing
    col = audioColorProcess(col, audio);

    // Post-processing
    // Bloom approximation - audio reactive intensity
    float bloomMult = 0.3 + audio.x * 0.4 * GLOW_PULSE_AMOUNT * ENABLE_GLOW_PULSE * AUDIO_ENABLED;
    col += col * col * bloomMult;

    // Vignette
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.3);

    // Tone mapping
    col = 1.0 - exp(-col * 1.5);

    // Gamma correction
    col = pow(col, vec3(0.4545));

    fragColor = vec4(col, 1.0);
}
