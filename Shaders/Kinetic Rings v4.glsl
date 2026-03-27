#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;
uniform vec4 iMouse;

out vec4 fragColor;

/*
    "Kinetic Rings v5" - Enhanced Materials & Audio-Reactive Movement
    - Outermost ring: Transparent reflective chrome
    - 2nd ring: See-through glass
    - 3rd ring: Fast rainbow color cycling
    - 4th ring: Audio-reactive wobble movement
    - 5th ring: Glossy
    - Background: Subtle animated nebula
    iChannel0 = Audio
    Author: Matrix Agent
*/

const float RING_THICKNESS = 0.04;
const float RING_RADIUS = 0.52;
const float RING_SPACING = 0.78;
const float BASE_SPEED = 0.35;
const float ORBIT_COMPLEXITY = 1.4;
const float CAMERA_SPEED = 0.18;

const float BASS_BREATHE = 0.06;
const float BASS_CORE_PULSE = 1.0;
const float BASS_NEON_GLOW = 2.0;
const float MID_COLOR_SHIFT = 0.5;
const float HIGH_SPARKLE = 1.0;

const float CORE_SIZE = 0.1;
const float CORE_WARP = 1.3;

const vec3 CHROME_A = vec3(0.6, 0.65, 0.75);
const vec3 CHROME_B = vec3(0.2, 0.25, 0.35);
const vec3 CHROME_C = vec3(0.5, 0.6, 1.0);
const vec3 CHROME_D = vec3(0.0, 0.05, 0.1);

const vec3 GLASS_A = vec3(0.6, 0.5, 0.4);
const vec3 GLASS_B = vec3(0.4, 0.35, 0.2);
const vec3 GLASS_C = vec3(1.0, 0.7, 0.4);
const vec3 GLASS_D = vec3(0.0, 0.1, 0.2);

const vec3 GLOSSY_A = vec3(0.5);
const vec3 GLOSSY_B = vec3(0.6);
const vec3 GLOSSY_C = vec3(1.0);
const vec3 GLOSSY_D = vec3(0.0, 0.33, 0.67);

const int NUM_RINGS = 5;

// Material IDs
const float MAT_CORE = 0.0;
const float MAT_CHROME_CLEAR = 1.0;   // Outermost - transparent chrome
const float MAT_GLASS = 2.0;          // 2nd - see-through glass
const float MAT_RAINBOW = 3.0;        // 3rd - fast rainbow
const float MAT_AUDIO_MOVE = 4.0;     // 4th - audio-reactive movement
const float MAT_GLOSSY = 5.0;         // 5th - glossy

vec3 getAudio() {
    float b = 0.0, m = 0.0, h = 0.0;
    for (float i = 0.0; i < 5.0; i++) {
        b += texture(iChannel0, vec2(0.02 + i * 0.02, 0.25)).x;
        m += texture(iChannel0, vec2(0.15 + i * 0.06, 0.25)).x;
        h += texture(iChannel0, vec2(0.5 + i * 0.1, 0.25)).x;
    }
    return vec3(pow(b / 5.0, 0.6), pow(m / 5.0, 0.7), pow(h / 5.0, 0.85));
}

vec3 chromeP(float t) { return CHROME_A + CHROME_B * cos(6.283185 * (CHROME_C * t + CHROME_D)); }
vec3 glassP(float t) { return GLASS_A + GLASS_B * cos(6.283185 * (GLASS_C * t + GLASS_D)); }
vec3 glossyP(float t) { return GLOSSY_A + GLOSSY_B * cos(6.283185 * (GLOSSY_C * t + GLOSSY_D)); }

// Fast rainbow palette - bright and saturated
vec3 rainbowP(float t) {
    return 0.5 + 0.5 * cos(6.283185 * (t + vec3(0.0, 0.33, 0.67)));
}

float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3D(vec3 p) {
    vec3 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x),
                   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
               mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
                   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
    float f = 0.5 * noise3D(p); p *= 2.01;
    f += 0.25 * noise3D(p); p *= 2.02;
    f += 0.125 * noise3D(p); p *= 2.03;
    return f + 0.0625 * noise3D(p);
}

mat3 rotX(float a) { float c = cos(a), s = sin(a); return mat3(1, 0, 0, 0, c, -s, 0, s, c); }
mat3 rotY(float a) { float c = cos(a), s = sin(a); return mat3(c, 0, s, 0, 1, 0, -s, 0, c); }
mat3 rotZ(float a) { float c = cos(a), s = sin(a); return mat3(c, -s, 0, s, c, 0, 0, 0, 1); }

float sdTorus(vec3 p, vec2 t) {
    return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

// Audio-reactive wobbling torus - only for the sound-reactive ring
float sdTorusWobble(vec3 p, vec2 t, float time, vec3 audio) {
    // Create audio-driven wave displacement
    float angle = atan(p.z, p.x);
    float wobbleFreq = 4.0;
    float wobbleAmp = audio.x * 0.08 + audio.y * 0.04;
    
    // Multiple wave frequencies for complex movement
    float wave1 = sin(angle * wobbleFreq + time * 6.0) * wobbleAmp;
    float wave2 = sin(angle * (wobbleFreq * 2.0) + time * 8.0 + audio.z * 3.0) * wobbleAmp * 0.5;
    float wave3 = cos(angle * (wobbleFreq * 0.5) + time * 4.0) * wobbleAmp * 0.3;
    
    // Pulsing radius based on bass
    float bassPulse = audio.x * 0.03;
    
    // Apply wobble to radius
    float wobbledRadius = t.x + wave1 + wave2 + wave3 + bassPulse;
    
    // Also wobble thickness slightly
    float wobbledThickness = t.y * (1.0 + audio.x * 0.2);
    
    return length(vec2(length(p.xz) - wobbledRadius, p.y)) - wobbledThickness;
}

float sdSphere(vec3 p, float r) { return length(p) - r; }

vec4 map(vec3 p, float t, vec3 au) {
    float wt = t * 2.0 + au.x * 3.0;
    float w = fbm(p * 4.0 + wt) * CORE_WARP * (0.5 + au.x * BASS_CORE_PULSE);
    float cs = CORE_SIZE * (1.0 + au.x * 0.3);
    float core = sdSphere(p, cs) - w * 0.03;
    vec4 res = vec4(core, MAT_CORE, -1.0, 0.0);
    
    for (int i = 0; i < NUM_RINGS; i++) {
        float fi = float(i);
        float ti = t * BASE_SPEED;
        float s1 = (1.0 + fi * 0.3) * ORBIT_COMPLEXITY;
        float s2 = (0.7 + fi * 0.25) * ORBIT_COMPLEXITY;
        float s3 = (0.5 + fi * 0.35) * ORBIT_COMPLEXITY;
        float ph = fi * 1.23456;
        
        mat3 rot = rotX(ti * s1 + ph) * rotY(ti * s2 * 0.7 + ph * 2.0) * rotZ(ti * s3 * 0.5 + ph * 0.5);
        vec3 q = rot * p;
        
        float br = RING_RADIUS * pow(RING_SPACING, fi);
        float mb = br * 0.08;
        float ba = min(au.x * BASS_BREATHE * mb * 10.0, mb);
        float rr = br + ba;
        float th = RING_THICKNESS * (1.0 - fi * 0.05);
        
        float ring;
        float mt;
        
        // Assign materials based on ring index
        // Ring 0 (outermost, largest radius) = transparent chrome
        // Ring 1 = glass
        // Ring 2 = rainbow
        // Ring 3 = audio-reactive movement (ONLY this one gets modified SDF)
        // Ring 4 (innermost) = glossy
        
        if (i == 3) {
            // ONLY ring 3 gets the wobble SDF modification
            ring = sdTorusWobble(q, vec2(rr, th), t, au);
            mt = MAT_AUDIO_MOVE;
        } else {
            ring = sdTorus(q, vec2(rr, th));
            if (i == 0) mt = MAT_CHROME_CLEAR;
            else if (i == 1) mt = MAT_GLASS;
            else if (i == 2) mt = MAT_RAINBOW;
            else mt = MAT_GLOSSY;
        }
        
        if (ring < res.x) res = vec4(ring, mt, fi, 0.0);
    }
    return res;
}

vec2 iSphere(vec3 ro, vec3 rd, float r) {
    float b = dot(ro, rd), c = dot(ro, ro) - r * r, h = b * b - c;
    if (h < 0.0) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b - h, -b + h);
}

vec3 calcN(vec3 p, float t, vec3 au) {
    vec2 e = vec2(0.0005, 0.0);
    return normalize(vec3(
        map(p + e.xyy, t, au).x - map(p - e.xyy, t, au).x,
        map(p + e.yxy, t, au).x - map(p - e.yxy, t, au).x,
        map(p + e.yyx, t, au).x - map(p - e.yyx, t, au).x
    ));
}

float calcAO(vec3 p, vec3 n, float t, vec3 au) {
    float o = 0.0, s = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.01 + 0.1 * float(i) / 4.0;
        o += (h - map(p + h * n, t, au).x) * s;
        s *= 0.95;
    }
    return clamp(1.0 - 2.5 * o, 0.0, 1.0);
}

vec4 intersect(vec3 ro, vec3 rd, float t, vec3 au) {
    vec4 r = vec4(-1.0);
    vec2 b = iSphere(ro, rd, 0.75);
    if (b.y > 0.0) {
        float tt = max(b.x, 0.001);
        for (int i = 0; i < 120; i++) {
            vec4 h = map(ro + tt * rd, t, au);
            if (h.x < 0.0004) {
                r = vec4(tt, h.yzw);
                break;
            }
            tt += h.x * 0.9;
            if (tt > b.y) break;
        }
    }
    return r;
}

// Enhanced environment with subtle animated nebula
vec3 getEnv(vec3 rd, float t, vec3 au) {
    // Base gradient - slightly more colorful
    vec3 c = mix(vec3(0.03, 0.04, 0.08), vec3(0.15, 0.18, 0.28), 0.5 + 0.5 * rd.y);
    
    // Subtle nebula clouds
    float nebula1 = fbm(rd * 2.0 + vec3(t * 0.02, 0.0, t * 0.01));
    float nebula2 = fbm(rd * 3.0 - vec3(t * 0.015, t * 0.01, 0.0));
    
    // Nebula colors - muted purples and blues
    vec3 nebulaColor1 = vec3(0.15, 0.08, 0.2) * nebula1;
    vec3 nebulaColor2 = vec3(0.05, 0.1, 0.18) * nebula2;
    
    c += nebulaColor1 * 0.4 + nebulaColor2 * 0.3;
    
    // Subtle star field
    float stars = pow(noise3D(rd * 50.0), 12.0) * 0.8;
    stars += pow(noise3D(rd * 80.0 + 100.0), 15.0) * 0.5;
    c += vec3(0.9, 0.95, 1.0) * stars;
    
    // Soft light sources for reflections
    c += pow(max(dot(rd, normalize(vec3(1.0, 0.6, 0.5))), 0.0), 32.0) * vec3(1.0, 0.9, 0.7) * 2.0;
    c += pow(max(dot(rd, normalize(vec3(-0.6, 0.4, -0.7))), 0.0), 24.0) * vec3(0.4, 0.6, 1.0) * 1.2;
    
    // Subtle audio-reactive shimmer
    float shimmer = sin(rd.x * 20.0 + rd.y * 15.0 + t * 0.5) * 0.5 + 0.5;
    c += vec3(0.02, 0.03, 0.05) * shimmer * au.y * 0.3;
    
    return c;
}

// Simple env for internal use (no time dependency for recursion)
vec3 getEnvSimple(vec3 rd) {
    vec3 c = mix(vec3(0.05, 0.05, 0.1), vec3(0.2, 0.25, 0.4), 0.5 + 0.5 * rd.y);
    c += pow(max(dot(rd, normalize(vec3(1.0, 0.6, 0.5))), 0.0), 32.0) * vec3(1.0, 0.9, 0.7) * 2.5;
    c += pow(max(dot(rd, normalize(vec3(-0.6, 0.4, -0.7))), 0.0), 24.0) * vec3(0.4, 0.6, 1.0) * 1.5;
    return c;
}

// === TRANSPARENT CHROME - Highly reflective with transparency ===
vec3 shadeChromeTransparent(vec3 p, vec3 n, vec3 rd, float ri, float t, vec3 au, float ao) {
    vec3 rf = reflect(rd, n);
    vec3 env = getEnvSimple(rf);
    
    // Strong fresnel for edge reflection
    float fresnel = pow(1.0 - max(dot(n, -rd), 0.0), 3.0);
    
    // Chrome tint
    vec3 tint = chromeP(ri * 0.3 + t * 0.02 + au.z * 0.5);
    
    // High reflectivity
    vec3 reflection = env * tint * 1.4;
    
    // Specular highlights - very sharp and bright
    vec3 l1 = normalize(vec3(0.8, 0.5, 0.6));
    vec3 l2 = normalize(vec3(-0.5, 0.7, -0.4));
    float sp1 = pow(max(dot(rf, l1), 0.0), 128.0) * 2.5;
    float sp2 = pow(max(dot(rf, l2), 0.0), 96.0) * 1.5;
    
    // High sparkle on treble
    float sparkle = pow(max(dot(rf, normalize(vec3(sin(t * 2.0), cos(t * 1.5), sin(t * 1.8)))), 0.0), 64.0);
    sparkle *= (1.0 + au.z * HIGH_SPARKLE * 4.0);
    
    // Combine with transparency controlled by fresnel
    // More transparent when looking straight, more reflective at edges
    float opacity = mix(0.3, 1.0, fresnel);
    
    vec3 col = reflection * opacity;
    col += (sp1 + sp2) * vec3(1.0, 0.98, 0.95);
    col += sparkle * vec3(1.0, 1.0, 1.0) * 0.8;
    
    // Edge glow
    col += fresnel * tint * 0.5;
    
    return col * ao;
}

// === GLASS - See-through with refraction ===
vec3 shadeGlass(vec3 p, vec3 n, vec3 rd, float ri, float t, vec3 au, float ao) {
    vec3 rf = reflect(rd, n);
    vec3 rr = refract(rd, n, 1.0 / 1.5);  // Glass IOR ~1.5
    
    vec3 envReflect = getEnvSimple(rf);
    vec3 envRefract = getEnvSimple(rr) * 0.9;  // Slight absorption
    
    // Fresnel - more reflection at glancing angles
    float fresnel = pow(1.0 - max(dot(n, -rd), 0.0), 4.0);
    fresnel = mix(0.04, 1.0, fresnel);  // Glass has ~4% reflection at normal
    
    // Subtle glass tint
    vec3 glassTint = glassP(ri * 0.35 + t * 0.03 + au.y * MID_COLOR_SHIFT);
    glassTint = pow(glassTint, vec3(0.8));
    
    // Chromatic aberration for realism
    vec3 rrR = refract(rd, n, 1.0 / 1.48);
    vec3 rrB = refract(rd, n, 1.0 / 1.52);
    vec3 refractColor = vec3(
        getEnvSimple(rrR).r,
        envRefract.g,
        getEnvSimple(rrB).b
    );
    
    // Mix reflection and refraction
    vec3 col = mix(refractColor * glassTint, envReflect, fresnel);
    
    // Sharp specular
    float sp = pow(max(dot(rf, normalize(vec3(0.8, 0.5, 0.6))), 0.0), 128.0);
    col += sp * vec3(1.0, 0.98, 0.95) * 0.8;
    
    // Subtle internal glow
    col += glassTint * pow(1.0 - fresnel, 2.0) * 0.15;
    
    return col * ao;
}

// === RAINBOW - Fast, bright color cycling ===
vec3 shadeRainbow(vec3 p, vec3 n, vec3 rd, float ri, float t, vec3 au, float ao) {
    // FAST color cycling - multiple frequencies
    float speed1 = t * 3.0;      // Fast base
    float speed2 = t * 5.0;      // Faster overlay
    float speed3 = t * 7.0;      // Even faster sparkle
    
    // Position-based variation for traveling waves
    float posPhase = length(p.xz) * 8.0 + p.y * 4.0;
    
    // Audio makes it even faster and more dynamic
    float audioSpeed = au.x * 4.0 + au.y * 2.0 + au.z * 1.0;
    
    // Multiple rainbow layers
    vec3 rainbow1 = rainbowP(ri * 0.5 + speed1 + posPhase * 0.1 + audioSpeed);
    vec3 rainbow2 = rainbowP(ri * 0.8 + speed2 * 1.3 - posPhase * 0.15 + audioSpeed * 1.5);
    vec3 rainbow3 = rainbowP(speed3 + posPhase * 0.2 + audioSpeed * 2.0);
    
    // Blend rainbows for rich, complex color
    vec3 baseColor = rainbow1 * 0.5 + rainbow2 * 0.35 + rainbow3 * 0.15;
    
    // Boost saturation and brightness
    baseColor = pow(baseColor, vec3(0.7));  // Gamma for brightness
    baseColor = mix(vec3(dot(baseColor, vec3(0.299, 0.587, 0.114))), baseColor, 1.5); // Saturation boost
    
    // Fresnel glow
    float fresnel = pow(1.0 - max(dot(n, -rd), 0.0), 2.0);
    
    // Emission - bright and glowing
    float emission = 1.5 + au.x * BASS_NEON_GLOW * 1.5;
    
    // Sparkle based on audio high frequencies
    float sparkle = pow(noise3D(p * 30.0 + t * 5.0), 4.0) * au.z * 3.0;
    
    // Combine
    vec3 col = baseColor * emission;
    col += baseColor * fresnel * emission * 1.2;  // Edge glow
    col += vec3(1.0) * sparkle;  // White sparkles
    
    // Pulsing intensity on bass
    col *= 0.8 + au.x * 0.4;
    
    return col;
}

// === AUDIO-REACTIVE RING - Movement shader (normal ring shading, movement is in SDF) ===
vec3 shadeAudioMove(vec3 p, vec3 n, vec3 rd, float ri, float t, vec3 au, float ao) {
    // Glossy metallic appearance with audio-reactive color
    float cp = ri * 0.5 + t * 0.08 + au.x * 0.5 + au.y * 0.4;
    vec3 baseColor = glossyP(cp);
    baseColor = pow(baseColor, vec3(0.6));
    
    // Add audio-reactive hue shift
    vec3 audioColor = 0.5 + 0.5 * cos(t * 2.0 + au.x * 6.0 + vec3(0.0, 2.0, 4.0));
    baseColor = mix(baseColor, audioColor, au.x * 0.4);
    
    vec3 rf = reflect(rd, n);
    vec3 env = getEnvSimple(rf);
    
    vec3 l1 = normalize(vec3(0.8, 0.5, 0.6));
    vec3 l2 = normalize(vec3(-0.5, 0.3, -0.6));
    
    float d1 = max(dot(n, l1), 0.0);
    float d2 = max(dot(n, l2), 0.0) * 0.4;
    float sp1 = pow(max(dot(rf, l1), 0.0), 48.0) * (1.0 + au.x);
    float sp2 = pow(max(dot(rf, l2), 0.0), 24.0) * 0.4;
    
    float fresnel = pow(1.0 - max(dot(n, -rd), 0.0), 4.0);
    
    vec3 col = baseColor * (d1 * vec3(1.0, 0.95, 0.9) * 1.3 + d2 * vec3(0.6, 0.7, 1.0) + vec3(0.25) * ao);
    col += (sp1 + sp2) * vec3(1.0, 0.98, 0.95) * 0.8;
    col += env * fresnel * 0.4;
    
    // Subtle pulse glow on bass
    col += baseColor * au.x * 0.3;
    
    return col * ao;
}

// === GLOSSY (for innermost ring) ===
vec3 shadeGlossy(vec3 p, vec3 n, vec3 rd, float ri, float t, vec3 au, float ao) {
    float cp = ri * 0.5 + t * 0.05 + au.x * 0.2 + au.y * 0.3 + au.z * 0.1;
    vec3 baseColor = pow(glossyP(cp), vec3(0.5));
    
    vec3 rf = reflect(rd, n);
    vec3 env = getEnvSimple(rf);
    
    vec3 l1 = normalize(vec3(0.8, 0.5, 0.6));
    vec3 l2 = normalize(vec3(-0.5, 0.3, -0.6));
    
    float d1 = max(dot(n, l1), 0.0);
    float d2 = max(dot(n, l2), 0.0) * 0.4;
    float sp1 = pow(max(dot(rf, l1), 0.0), 32.0) * (1.0 + au.z * 0.5);
    float sp2 = pow(max(dot(rf, l2), 0.0), 16.0) * 0.3;
    
    float fresnel = pow(1.0 - max(dot(n, -rd), 0.0), 4.0);
    
    vec3 col = baseColor * (d1 * vec3(1.0, 0.95, 0.9) * 1.2 + d2 * vec3(0.6, 0.7, 1.0) + vec3(0.2) * ao);
    col += (sp1 + sp2) * vec3(1.0, 0.98, 0.95) * 0.6;
    col += env * fresnel * 0.3;
    
    return col * ao;
}

// === IRIDESCENT CORE ===
vec3 shadeCore(vec3 pos, vec3 nor, vec3 rd, float t, vec3 audio) {
    vec2 I = pos.xy * 10.0;
    I += I - vec2(0.0);
    float d = dot(I, I);
    if (d > 0.0001) I /= d / 1.0;
    
    float timeOffset = t + audio.x * 2.0 + audio.y * 1.5;
    vec3 iridescent = 0.5 + 0.5 * cos(timeOffset + vec3(I.x, I.y, I.x + 2.0));
    vec3 iridescent2 = 0.5 + 0.5 * cos(timeOffset * 1.3 + vec3(pos.z * 8.0, pos.y * 6.0 + 2.0, pos.x * 7.0 + 4.0));
    vec3 iridescentFinal = mix(iridescent, iridescent2, 0.4);
    
    float pulse = 1.0 + audio.x * BASS_CORE_PULSE * 1.5;
    float plasma = pow(fbm(pos * 8.0 + t * 1.5 + audio.x * 5.0), 0.8);
    float fresnel = pow(1.0 - max(dot(nor, -rd), 0.0), 2.5);
    
    vec3 baseGlow = iridescentFinal * (1.2 + plasma * 0.8);
    vec3 edgeGlow = mix(iridescentFinal, vec3(1.0), 0.6) * fresnel * 2.5;
    
    float hotSpot = pow(max(
        sin(pos.x * 12.0 + t * 3.0 + audio.x * 8.0) *
        sin(pos.y * 12.0 + t * 2.5 + audio.y * 6.0) *
        sin(pos.z * 12.0 + t * 2.0 + audio.z * 4.0), 0.0), 2.0);
    
    vec3 hotColor = (iridescentFinal + vec3(0.3, 0.2, 0.1)) * hotSpot * audio.x * 3.0;
    
    vec3 cycling = 0.5 + 0.5 * cos(t * 0.8 + audio.y * 4.0 + vec3(0.0, 2.1, 4.2));
    baseGlow = mix(baseGlow, baseGlow * cycling, 0.3);
    
    vec3 col = (baseGlow + edgeGlow + hotColor) * pulse;
    col += iridescentFinal * fresnel * audio.x * 0.5;
    
    return col;
}

mat3 setCam(vec3 ro, vec3 ta) {
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, vec3(0, 1, 0)));
    vec3 cv = cross(cu, cw);
    return mat3(cu, cv, cw);
}

void main() {
    vec2 I = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = (2.0 * I - iResolution.xy) / iResolution.y;
    float t = iTime;
    vec3 au = getAudio();
    
    float ca = t * CAMERA_SPEED;
    float cr = 1.4;
    float ch = 0.2 + 0.1 * sin(t * 0.12);
    
    vec3 ro = vec3(cr * cos(ca), ch, cr * sin(ca));
    vec3 ta = vec3(0.0);
    
    mat3 cam = setCam(ro, ta);
    vec3 rd = cam * normalize(vec3(uv, 2.2));
    
    // Start with enhanced background
    vec3 col = getEnv(rd, t, au) * 0.15;
    
    vec4 res = intersect(ro, rd, t, au);
    
    if (res.x > 0.0) {
        vec3 pos = ro + res.x * rd;
        vec3 nor = calcN(pos, t, au);
        float mt = res.y;
        float ri = res.z;
        float ao = calcAO(pos, nor, t, au);
        
        if (mt < 0.5) {
            col = shadeCore(pos, nor, rd, t, au);
        } else if (mt < 1.5) {
            col = shadeChromeTransparent(pos, nor, rd, ri, t, au, ao);
        } else if (mt < 2.5) {
            col = shadeGlass(pos, nor, rd, ri, t, au, ao);
        } else if (mt < 3.5) {
            col = shadeRainbow(pos, nor, rd, ri, t, au, ao);
        } else if (mt < 4.5) {
            col = shadeAudioMove(pos, nor, rd, ri, t, au, ao);
        } else {
            col = shadeGlossy(pos, nor, rd, ri, t, au, ao);
        }
    }
    
    // Vignette
    vec2 q = I / iResolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.2);
    
    // Tone mapping
    col = pow(col * 1.15 / (1.0 + col * 1.15), vec3(0.4545));
    
    fragColor = vec4(col, 1.0);
}
