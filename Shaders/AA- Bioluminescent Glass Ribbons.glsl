// Bioluminescent Glass Ribbons - Audio Reactive Shader
// Smooth glassy organic ribbons with reflections
// For Shadertoy: Uses iChannel0 as audio texture

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT

out vec4 fragColor;

// ============================================
// TWEAKING VARIABLES - Audio Reactivity Controls
// ============================================

// Master toggle: Set to 0.0 to disable ALL audio reactivity
#define AUDIO_ENABLED 1.0

// Individual effect controls (0.0 = off, 1.0 = full effect)
#define BASS_RIBBON_PULSE 1.0       // Bass affects ribbon thickness pulsing
#define MID_RIBBON_TWIST 1.0        // Mids control ribbon twist intensity
#define BASS_GLOW_INTENSITY 1.0     // Bass boosts bloom/glow
#define MID_COLOR_SHIFT 1.0         // Mids shift color palette
#define HIGH_CAMERA_SHAKE 0.3       // Highs add subtle camera shake

// Influence multipliers (adjust strength of each effect)
#define BASS_INFLUENCE 3.0
#define MID_INFLUENCE 1.5
#define HIGH_INFLUENCE 1.2

// Static fallback values when audio is disabled
#define STATIC_BASS 0.3
#define STATIC_MID 0.25
#define STATIC_HIGH 0.2

// Glass material properties
#define REFLECTIVITY 0.95           // How reflective the glass is (0-1)
#define IOR 1.45                    // Index of refraction
#define SMOOTHNESS 0.95             // Surface smoothness

// ============================================
// END TWEAKING VARIABLES
// ============================================

#define PI 3.14159265359
#define TAU 6.28318530718
#define saturate(x) clamp(x, 0.0, 1.0)

// Get audio data with fallback
float getAudio(float freq) {
    if (AUDIO_ENABLED < 0.5) {
        return 0.25 + 0.1 * sin(iTime * 2.0 + freq * 10.0);
    }
    return texture(iChannel0, vec2(freq, 0.0)).x;
}

// Frequency band helpers
float getBass() {
    float raw = (getAudio(0.01) + getAudio(0.05) + getAudio(0.1)) / 3.0;
    return mix(STATIC_BASS, raw * BASS_INFLUENCE, AUDIO_ENABLED);
}

float getMid() {
    float raw = (getAudio(0.2) + getAudio(0.35) + getAudio(0.5)) / 3.0;
    return mix(STATIC_MID, raw * MID_INFLUENCE, AUDIO_ENABLED);
}

float getHigh() {
    float raw = (getAudio(0.6) + getAudio(0.75) + getAudio(0.9)) / 3.0;
    return mix(STATIC_HIGH, raw * HIGH_INFLUENCE, AUDIO_ENABLED);
}

// Rotation matrices
mat2 rot2(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

mat3 rotX(float a) {
    float c = cos(a), s = sin(a);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

mat3 rotY(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}

// Smooth minimum for organic blending
float smin(float a, float b, float k) {
    float h = saturate(0.5 + 0.5 * (b - a) / k);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Smooth max
float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}

// Hash function
float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0); // Quintic smoothing for glassier look

    return mix(
        mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
            mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
        mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
            mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// Smooth FBM
float fbm(vec3 p) {
    float f = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 3; i++) {
        f += amp * noise3D(p);
        p *= 2.03;
        amp *= 0.5;
    }
    return f;
}

// Bioluminescent color palette - smooth gradients
vec3 bioColor(float t, float mid) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.0, 0.33, 0.67);

    d += mid * MID_COLOR_SHIFT * vec3(0.2, -0.1, 0.1);

    return a + b * cos(TAU * (c * t + d));
}

// HSV to RGB for additional color control
vec3 hsv2rgb(float h, float s, float v) {
    vec3 c = fract(h + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0;
    c = saturate(abs(c) - 1.0);
    return v * mix(vec3(1.0), c, s);
}

// Smooth glass ribbon SDF
float glassRibbon(vec3 p, float ribbonId, float bass, float mid) {
    float t = iTime * 0.4 + ribbonId * 2.1;

    // Audio-reactive twist (smoother)
    float twistAmount = 1.5 + mid * MID_RIBBON_TWIST * 2.0;

    // Smooth flowing path using sine combinations
    float pathX = sin(p.z * 0.25 + t) * 2.5 + sin(p.z * 0.6 + t * 1.2) * 0.8;
    float pathY = cos(p.z * 0.35 + t * 0.8 + ribbonId) * 2.0 + cos(p.z * 0.15) * 1.0;

    vec3 q = p;
    q.x -= pathX;
    q.y -= pathY;

    // Smooth twist
    q.xy *= rot2(p.z * twistAmount * 0.08 + t * 0.5);

    // Audio-reactive thickness with smooth pulsing
    float pulse = sin(iTime * 3.0 + ribbonId * 1.5) * 0.5 + 0.5;
    float thickness = 0.12 + bass * BASS_RIBBON_PULSE * 0.1 * pulse;
    float width = 0.8 + sin(p.z * 1.5 + t * 1.5) * 0.3;

    // Smooth elliptical cross-section (no sharp edges)
    vec2 qxy = q.xy / vec2(width, thickness);
    float ribbon = (length(qxy) - 1.0) * min(width, thickness);

    // Very subtle surface detail for interest without breaking smoothness
    ribbon += fbm(p * 2.0 + t * 0.3) * 0.015;

    return ribbon;
}

// Scene with smooth blended ribbons
float map(vec3 p) {
    float bass = getBass();
    float mid = getMid();

    float d = 1e10;

    // Create smoothly interweaving ribbons
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        vec3 rp = p;

        // Smooth rotational offset
        rp = rotY(fi * TAU / 5.0 + iTime * 0.08) * rp;
        rp = rotX(fi * 0.3 + sin(iTime * 0.25 + fi) * 0.25) * rp;

        float ribbon = glassRibbon(rp, fi, bass, mid);

        // Extra smooth blending for glass-like merging
        d = smin(d, ribbon, 0.5);
    }

    // Add a central smooth sphere as focal point
    float sphere = length(p) - 1.2 - bass * BASS_RIBBON_PULSE * 0.3;
    d = smin(d, sphere, 0.8);

    return d;
}

// High quality normal with central differences
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.0005, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

// Schlick Fresnel approximation
float fresnel(vec3 rd, vec3 n, float f0) {
    float cosTheta = saturate(dot(-rd, n));
    return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0);
}

// Raymarching with glass material
vec3 march(inout vec3 ro, inout vec3 rd, inout vec3 attenuation, inout bool hit, float mid) {
    vec3 col = vec3(0.0);
    float t = 0.0;
    float tMax = 25.0;
    hit = false;

    for (int i = 0; i < 120; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);

        if (d < 0.0005) {
            hit = true;
            break;
        }
        if (t > tMax) break;

        t += d * 0.7; // Slightly conservative stepping for smooth surfaces
    }

    ro += rd * t;

    if (hit) {
        vec3 p = ro;
        vec3 n = calcNormal(p);
        vec3 ref = reflect(rd, n);

        // Smooth color based on position - creates flowing gradients
        float colorPhase = dot(p, vec3(0.3, 0.5, 0.4)) * 0.4 + iTime * 0.2;
        colorPhase += length(p) * 0.15;
        vec3 glassColor = bioColor(colorPhase, mid);

        // Subsurface-like color variation
        vec3 innerColor = bioColor(colorPhase + 0.3, mid) * 0.6;

        // Fresnel for glass-like reflection
        float f0 = pow((IOR - 1.0) / (IOR + 1.0), 2.0);
        float fres = fresnel(rd, n, f0) * REFLECTIVITY;

        // Soft diffuse lighting
        vec3 lightDir = normalize(vec3(0.5, 1.0, -0.3));
        float diff = saturate(dot(n, lightDir)) * 0.5 + 0.5; // Wrapped diffuse

        // Smooth specular highlight
        float spec = pow(saturate(dot(ref, lightDir)), 64.0 * SMOOTHNESS);

        // Secondary light for rim
        vec3 lightDir2 = normalize(vec3(-0.7, 0.3, 0.5));
        float rim = pow(1.0 - saturate(dot(-rd, n)), 3.0);
        float rimLight = saturate(dot(n, lightDir2)) * rim;

        // Glass material: mix of transmitted color and reflection
        vec3 transmitted = mix(innerColor, glassColor, 0.6) * diff;

        // Add subtle iridescence
        float iridescence = sin(dot(n, rd) * 10.0 + iTime) * 0.1 + 0.9;
        transmitted *= iridescence;

        // Combine: base color + specular + rim
        col = transmitted * (1.0 - fres * 0.5);
        col += vec3(1.0, 0.98, 0.95) * spec * 0.8; // Warm specular
        col += glassColor * rimLight * 0.4;

        // Distance fog for depth
        float fog = exp(-t * t * 0.008);
        col = mix(vec3(0.02, 0.01, 0.03), col, fog);

        col *= attenuation;

        // Update for next reflection bounce
        attenuation *= glassColor * fres * fog;
        ro += n * 0.002;
        rd = ref;
    }

    return col;
}

// Smooth background
vec3 background(vec3 rd, float mid) {
    // Gradient sky
    float y = rd.y * 0.5 + 0.5;
    vec3 sky = mix(vec3(0.02, 0.01, 0.05), vec3(0.08, 0.04, 0.12), y);

    // Subtle nebula clouds
    float nebula = fbm(rd * 4.0 + iTime * 0.05) * 0.4;
    nebula += fbm(rd * 8.0 - iTime * 0.03) * 0.2;

    vec3 nebulaColor = bioColor(nebula * 2.0 + iTime * 0.1, mid);
    sky += nebulaColor * nebula * 0.25;

    // Soft glow in center
    float centerGlow = exp(-dot(rd.xy, rd.xy) * 3.0);
    sky += bioColor(iTime * 0.15, mid) * centerGlow * 0.15;

    return sky;
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Get audio values
    float bass = getBass();
    float mid = getMid();
    float high = getHigh();

    // Camera setup
    vec3 ro = vec3(0.0, 0.0, -7.0 + sin(iTime * 0.4) * 1.5);
    vec3 lookAt = vec3(0.0);

    // Subtle audio-reactive camera shake
    if (AUDIO_ENABLED > 0.5) {
        ro.xy += high * HIGH_CAMERA_SHAKE * 0.05 * vec2(
            sin(iTime * 25.0),
            cos(iTime * 22.0)
        );
    }

    // Smooth camera orbit
    float camAngle = iTime * 0.15;
    ro.xz *= rot2(camAngle);
    ro.yz *= rot2(sin(iTime * 0.2) * 0.2);

    // Ray direction
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0, 1, 0), forward));
    vec3 up = cross(forward, right);
    vec3 rd = normalize(forward + uv.x * right + uv.y * up);

    // Initialize for reflection passes
    vec3 col = vec3(0.0);
    vec3 attenuation = vec3(1.0);
    bool hit = false;

    // Primary ray + reflections (like crystal shader)
    col += march(ro, rd, attenuation, hit, mid);
    if (hit) col += march(ro, rd, attenuation, hit, mid); // 1st reflection
    if (hit) col += march(ro, rd, attenuation, hit, mid); // 2nd reflection

    // Add background where rays escape
    col += background(rd, mid) * attenuation;

    // Subtle volumetric glow around surfaces
    vec3 glowCol = bioColor(iTime * 0.2, mid);
    col += glowCol * (1.0 - exp(-bass * BASS_GLOW_INTENSITY * 0.5)) * 0.1;

    // Post-processing
    // Soft vignette
    float vignette = 1.0 - dot(uv, uv) * 0.4;
    col *= vignette;

    // Audio-reactive brightness
    col *= 1.0 + bass * BASS_GLOW_INTENSITY * 0.2;

    // Tone mapping (ACES-like for smooth rolloff)
    col = col * (2.51 * col + 0.03) / (col * (2.43 * col + 0.59) + 0.14);

    // Gamma
    col = pow(saturate(col), vec3(0.4545));

    fragColor = vec4(col, 1.0);
}
