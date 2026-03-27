#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// =================================================================
// LIQUID MOSAIC GLASS ORB SHADER
// Audio-reactive specular highlight on iChannel0
// =================================================================

// =================================================================
// CONSTANTS & CONFIGURATION
// =================================================================
#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURF_DIST 0.001
#define PI 3.14159265359

// --- AUDIO SPECULAR TUNING ---
const float SPEC_AUDIO_BOOST = 6.0;           // Brightness punch on hits
const float SPEC_AUDIO_WARMTH = 0.7;          // Gold color shift on hits
const float SPEC_AUDIO_FREQ = 0.08;           // Bass bin
const float SPEC_BLOOM_SPREAD = 40.0;         // How much highlight widens on hits

// Color palette
const vec3 COL_ORB_DEEP = vec3(0.0, 0.294, 0.286);
const vec3 COL_ORB_BRIGHT = vec3(0.0, 0.898, 0.933);
const vec3 COL_ORB_SHADOW = vec3(0.0, 0.169, 0.169);
const vec3 COL_GRID_GOLD = vec3(1.0, 0.75, 0.0);
const vec3 COL_GRID_DARK = vec3(0.8, 0.467, 0.133);
const vec3 COL_BG_TERRACOTTA = vec3(0.804, 0.357, 0.271);

// =================================================================
// NOISE FUNCTIONS FOR ORGANIC WOBBLE
// =================================================================

float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
            mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
        mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
            mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y),
        f.z
    );
}

float fbm(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for(int i = 0; i < 4; i++) {
        value += amplitude * noise3D(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

// =================================================================
// SIGNED DISTANCE FUNCTIONS
// =================================================================

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float mapOrb(vec3 p) {
    float t = iTime;
    float d = sdSphere(p, 1.0);

    float wobble = 0.0;
    wobble += sin(t * 0.8) * 0.03;
    wobble += sin(p.x * 3.0 + t * 1.2) * 0.02;
    wobble += sin(p.y * 2.5 + t * 0.9) * 0.02;
    wobble += sin(p.z * 2.8 + t * 1.1) * 0.02;

    vec3 noisePos = p * 2.0 + vec3(t * 0.3, t * 0.2, t * 0.25);
    wobble += fbm(noisePos) * 0.08;

    float quadrantDelay = sin(atan(p.y, p.x) * 2.0 + t) * 0.015;
    wobble += quadrantDelay;

    return d + wobble;
}

// =================================================================
// RAYMARCHING
// =================================================================

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        mapOrb(p + e.xyy) - mapOrb(p - e.xyy),
        mapOrb(p + e.yxy) - mapOrb(p - e.yxy),
        mapOrb(p + e.yyx) - mapOrb(p - e.yyx)
    ));
}

float rayMarch(vec3 ro, vec3 rd) {
    float dO = 0.0;
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dO;
        float dS = mapOrb(p);
        dO += dS;
        if(dO > MAX_DIST || dS < SURF_DIST) break;
    }
    return dO;
}

// =================================================================
// LIGHTING & MATERIALS
// =================================================================

float fresnel(vec3 viewDir, vec3 normal, float power) {
    return pow(1.0 - max(dot(viewDir, normal), 0.0), power);
}

float softShadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
    float res = 1.0;
    float t = mint;
    for(int i = 0; i < 32; i++) {
        float h = mapOrb(ro + rd * t);
        res = min(res, k * h / t);
        t += clamp(h, 0.02, 0.1);
        if(h < 0.001 || t > maxt) break;
    }
    return clamp(res, 0.0, 1.0);
}

// =================================================================
// MOSAIC GRID SYSTEM
// =================================================================

vec2 getMosaicUV(vec2 uv, float time) {
    float gridRows = 13.0;
    float gridCols = floor(gridRows * iResolution.x / iResolution.y);
    float offset = time * 0.2;

    vec2 gridUV = uv * vec2(gridCols, gridRows);
    gridUV.x += offset;

    vec2 cell = floor(gridUV);
    vec2 cellUV = fract(gridUV);
    vec2 cellCenter = vec2(0.5);
    vec2 distFromCenter = cellUV - cellCenter;

    float dist = length(distFromCenter);
    float distortion = 1.0 + dist * dist * 0.3;
    vec2 localUV = cellCenter + distFromCenter * distortion;

    return vec2(
        cell.x + mod(cell.y, 2.0) * 0.5,
        localUV.y
    );
}

vec3 getGridColor(vec2 uv, float time) {
    float gridRows = 13.0;
    float gridCols = floor(gridRows * iResolution.x / iResolution.y);

    vec2 gridUV = uv * vec2(gridCols, gridRows);
    gridUV.x += time * 0.2;

    vec2 cell = floor(gridUV);
    vec2 cellUV = fract(gridUV);

    float lineThickness = 0.08;
    float edgeX = smoothstep(0.0, lineThickness, cellUV.x) * smoothstep(1.0, 1.0 - lineThickness, cellUV.x);
    float edgeY = smoothstep(0.0, lineThickness, cellUV.y) * smoothstep(1.0, 1.0 - lineThickness, cellUV.y);
    float edge = edgeX * edgeY;

    float cellHash = hash(vec3(cell, 0.0));
    vec3 gridColor = mix(COL_GRID_DARK, COL_GRID_GOLD, cellHash * 0.5 + 0.5);
    gridColor *= 0.8 + 0.2 * sin(cell.x * 0.5 + cell.y * 0.3);

    return gridColor * edge;
}

// =================================================================
// MAIN RENDERING
// =================================================================

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 originalUV = uv;
    float t = iTime;

    // === AUDIO: bass + mid samples for specular ===
    float audioHit = texture(iChannel0, vec2(SPEC_AUDIO_FREQ, 0.0)).x;
    float audioMid = texture(iChannel0, vec2(0.3, 0.0)).x;
    float audioDrive = audioHit * 0.7 + audioMid * 0.3;

    // ========================================
    // BACKGROUND (Terracotta)
    // ========================================
    vec3 bgColor = COL_BG_TERRACOTTA;
    bgColor *= 0.9 + 0.1 * (uv.y + 0.5);

    // ========================================
    // MOSAIC GRID DISTORTION
    // ========================================
    vec2 mosaicInfo = getMosaicUV(originalUV, t);
    float mosaicY = mosaicInfo.y;
    vec3 gridColor = getGridColor(originalUV, t);

    vec2 refractionOffset = vec2(
        sin(mosaicInfo.x * 3.14159) * 0.02,
        cos(mosaicInfo.x * 2.5) * 0.015
    );
    uv += refractionOffset;

    // ========================================
    // CAMERA SETUP
    // ========================================
    vec3 ro = vec3(0.0, 0.0, 3.5);
    vec3 rd = normalize(vec3(uv, -1.5));

    // ========================================
    // CHROMATIC ABERRATION
    // ========================================
    vec3 finalColor = vec3(0.0);

    float caStrength = 0.015;
    vec3 caOffsets = vec3(-caStrength, 0.0, caStrength);

    for(int channel = 0; channel < 3; channel++) {
        vec3 rdCA = rd;
        rdCA.xy += caOffsets[channel] * vec2(1.0, 1.0);
        rdCA = normalize(rdCA);

        float d = rayMarch(ro, rdCA);
        vec3 col = bgColor;

        if(d < MAX_DIST) {
            vec3 p = ro + rdCA * d;
            vec3 n = calcNormal(p);
            vec3 v = normalize(ro - p);

            // ========================================
            // GLASS MATERIAL
            // ========================================
            float fres = fresnel(v, n, 3.0);

            float colorMix = (p.y + 1.0) * 0.5 + 0.2;
            colorMix += fres * 0.3;
            vec3 orbColor = mix(COL_ORB_DEEP, COL_ORB_BRIGHT, clamp(colorMix, 0.0, 1.0));

            float shadowFactor = smoothstep(-1.0, 0.5, -p.y - p.x * 0.3);
            orbColor = mix(orbColor, COL_ORB_SHADOW, shadowFactor * 0.6);

            // ========================================
            // LIGHTING
            // ========================================
            vec3 lightPos = vec3(2.0, 2.5, 4.0);
            vec3 l = normalize(lightPos - p);
            float diff = max(dot(n, l), 0.0) * 0.3;

            vec3 h = normalize(l + v);

            // Audio widens the highlight on hits (lower exponent = bigger hotspot)
            float specPow = 80.0 - audioDrive * SPEC_BLOOM_SPREAD;
            float spec = pow(max(dot(n, h), 0.0), specPow);

            // Audio-reactive specular intensity and color
            float specBoost = 1.0 + audioDrive * SPEC_AUDIO_BOOST;
            vec3 specColor = mix(vec3(1.0), vec3(1.0, 0.85, 0.6), audioDrive * SPEC_AUDIO_WARMTH);

            vec3 lightPos2 = vec3(-1.5, -1.0, 2.0);
            vec3 l2 = normalize(lightPos2 - p);
            float diff2 = max(dot(n, l2), 0.0) * 0.15;

            float rim = pow(1.0 - max(dot(v, n), 0.0), 2.0);

            // ========================================
            // REFRACTION
            // ========================================
            float IOR = 1.45;
            vec3 refractDir = refract(-rdCA, n, 1.0/IOR);

            vec3 refractColor = COL_BG_TERRACOTTA;
            refractColor *= 0.8 + 0.2 * (refractDir.x * 0.5 + 0.5);

            float disp = float(channel - 1) * 0.02;
            vec3 refractDirR = refract(-rdCA, n, 1.0/(IOR + disp));
            refractColor = mix(refractColor, COL_BG_TERRACOTTA * 1.1, length(refractDirR) * 0.2);

            // Combine reflection and refraction
            vec3 reflectColor = orbColor + spec * specColor * specBoost;
            col = mix(refractColor, reflectColor, fres * 0.7);

            // Diffuse
            col += orbColor * diff + orbColor * diff2;

            // Specular highlight - audio reactive
            col += spec * specColor * 1.5 * specBoost;

            // Rim light
            col += rim * COL_ORB_BRIGHT * 0.3;

            // Internal glow
            float internalGlow = (1.0 - fres) * 0.2;
            col += orbColor * internalGlow;
        }

        if(channel == 0) finalColor.r = col.r;
        else if(channel == 1) finalColor.g = col.g;
        else finalColor.b = col.b;
    }

    // ========================================
    // GRID OVERLAY
    // ========================================
    float gridAlpha = 0.85;
    finalColor = mix(finalColor, gridColor, gridAlpha * 0.3);

    float gridRows = 13.0;
    float gridCols = floor(gridRows * iResolution.x / iResolution.y);
    vec2 gridUV = originalUV * vec2(gridCols, gridRows);
    gridUV.x += t * 0.2;
    vec2 cell = floor(gridUV);
    vec2 cellUV = fract(gridUV);

    float lineThickness = 0.06;
    float gridLines = 1.0 - smoothstep(0.0, lineThickness, min(cellUV.x, min(cellUV.y, min(1.0-cellUV.x, 1.0-cellUV.y))));

    float d = rayMarch(ro, rd);
    if(d < MAX_DIST) {
        gridLines *= 0.6;
    }
    finalColor = mix(finalColor, finalColor * 0.7, gridLines * 0.5);

    // ========================================
    // FINAL ADJUSTMENTS
    // ========================================
    float vignette = 1.0 - length(originalUV) * 0.4;
    finalColor *= vignette;

    float luma = dot(finalColor, vec3(0.299, 0.587, 0.114));
    finalColor = mix(vec3(luma), finalColor, 1.15);

    finalColor = pow(finalColor, vec3(0.9));

    fragColor = vec4(finalColor, 1.0);
}