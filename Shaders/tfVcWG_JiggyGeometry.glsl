#version 330 core

// Jiggy Geometry - Infinite Descent Audio Reactive Falling Portals
// Created by OneHung
// Enhanced with audio-reactive turbulence and parallax effects
// https://www.shadertoy.com/view/tfVcWG

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

#define AUDIO_SMOOTHING 0.85
#define TURBULENCE_STRENGTH 0.9
#define TURBULENCE_FREQ 8.0
#define DISTANCE_FALLOFF 0.05
#define BASS_RESPONSE 2.0
#define MID_RESPONSE 1.5
#define HIGH_RESPONSE 1.0
#define VIBRATION_SPEED 12.0
#define PARALLAX_STRENGTH 0.4
#define SCENE_ROTATION_SPEED 0.5
#define SWAY_AMPLITUDE 0.3
#define SWAY_SPEED_X 0.3
#define SWAY_SPEED_Y 0.23
#define PI 3.14159265359
#define TAU 6.28318530718

mat2 rot(float a) { return mat2(cos(a), sin(a), -sin(a), cos(a)); }
float hash(float n) { return fract(sin(n * 127.1) * 43758.5453); }

vec3 sampleAudio(float t) {
    float bass = texture(iChannel0, vec2(0.01, 0.25)).x;
    float mid = texture(iChannel0, vec2(0.1, 0.25)).x;
    float high = texture(iChannel0, vec2(0.5, 0.25)).x;
    bass = pow(abs(bass), 1.5) * BASS_RESPONSE;
    mid = pow(abs(mid), 1.8) * MID_RESPONSE;
    high = pow(abs(high), 2.0) * HIGH_RESPONSE;
    return vec3(bass, mid, high);
}

vec3 smoothAudio(vec3 audio, float smoothFactor) {
    return audio * (1.0 - smoothFactor) + audio * smoothFactor * 0.8;
}

float sdBoxFrame(vec3 p, vec3 b, float e) {
    p = abs(p) - b;
    vec3 q = abs(p + e) - e;
    return min(min(
        length(max(vec3(p.x, q.y, q.z), 0.)) + min(max(p.x, max(q.y, q.z)), 0.),
        length(max(vec3(q.x, p.y, q.z), 0.)) + min(max(q.x, max(p.y, q.z)), 0.)),
        length(max(vec3(q.x, q.y, p.z), 0.)) + min(max(q.x, max(q.y, p.z)), 0.));
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xy) - t.x, p.z);
    return length(q) - t.y;
}

float sdTriFrame(vec3 p, float r, float th) {
    vec2 q = p.xy; q.x = abs(q.x);
    float tri = max(q.x * 0.866 + q.y * 0.5, -q.y) - r * 0.5;
    float inner = max(q.x * 0.866 + q.y * 0.5, -q.y) - (r * 0.5 - th);
    return max(max(tri, -inner), abs(p.z) - th * 0.5);
}

float sdHexFrame(vec3 p, float r, float th) {
    vec2 q = abs(p.xy);
    float hex = max(q.x * 0.866 + q.y * 0.5, q.y) - r;
    float inner = max(q.x * 0.866 + q.y * 0.5, q.y) - (r - th);
    return max(max(hex, -inner), abs(p.z) - th * 0.5);
}

float sdDiamondFrame(vec3 p, float r, float th) {
    vec2 q = abs(p.xy);
    float dia = (q.x + q.y) * 0.707 - r;
    float inner = (q.x + q.y) * 0.707 - (r - th);
    return max(max(dia, -inner), abs(p.z) - th * 0.5);
}

float sdOctFrame(vec3 p, float r, float th) {
    vec2 q = abs(p.xy);
    float oct = max(max(q.x, q.y), (q.x + q.y) * 0.707) - r;
    float inner = max(max(q.x, q.y), (q.x + q.y) * 0.707) - (r - th);
    return max(max(oct, -inner), abs(p.z) - th * 0.5);
}

vec3 calcTurbulence(float camDist, vec3 audio, float seed, float t) {
    float distanceFactor = exp(-camDist * DISTANCE_FALLOFF);
    float audioIntensity = (audio.x * 0.4 + audio.y * 0.35 + audio.z * 0.25);
    audioIntensity = smoothAudio(vec3(audioIntensity), AUDIO_SMOOTHING).x;
    vec3 turbulence;
    turbulence.x = sin(t * VIBRATION_SPEED + seed * TAU) * audioIntensity;
    turbulence.y = cos(t * VIBRATION_SPEED * 1.3 + seed * TAU + 1.57) * audioIntensity;
    turbulence.z = 0.0;
    turbulence *= distanceFactor * TURBULENCE_STRENGTH;
    float detail = sin(t * VIBRATION_SPEED * 3.0 + seed * PI);
    turbulence.xy += vec2(detail * audio.z * 0.1) * distanceFactor;
    return turbulence;
}

float glow = 0.;
float hitId = 0.;
int hitType = 0;
vec3 globalAudio;

float scene(vec3 p) {
    float t = iTime;
    float spacing = 4.0;
    float scroll = t * 8.0;
    p.z += scroll;
    float frameId = floor(p.z / spacing + 0.5);
    float minDist = 1e5;
    
    for (float off = -2.; off <= 2.; off += 1.) {
        float id = frameId + off;
        float frameZ = id * spacing;
        float localZ = p.z - frameZ;
        float camDist = frameZ - scroll;
        if (camDist < 0.5 || camDist > 60.) continue;
        
        float seed = hash(id);
        float seed2 = hash(id + 50.);
        float seed3 = hash(id + 100.);
        float seed4 = hash(id + 150.);
        int shapeType = int(mod(abs(id), 6.));
        float size = 1.8 + seed2 * 0.6;
        float breathe = sin(t * 0.9 + seed * TAU);
        size *= 1.0 + breathe * 0.08 + globalAudio.x * 0.05;
        float thick = 0.15 + seed3 * 0.1 + globalAudio.y * 0.02;
        float angle = id * 0.3 + seed4 * TAU + t * (seed - 0.5) * 0.4;
        vec3 fp = vec3(p.xy, localZ);
        vec3 turbulence = calcTurbulence(camDist, globalAudio, seed, t);
        fp += turbulence;
        fp.xy *= rot(angle);
        
        float d;
        if (shapeType == 0) d = sdBoxFrame(fp, vec3(size, size, thick * 0.4), thick);
        else if (shapeType == 1) d = sdTorus(fp, vec2(size, thick));
        else if (shapeType == 2) d = sdTriFrame(fp, size * 2.2, thick);
        else if (shapeType == 3) d = sdHexFrame(fp, size, thick);
        else if (shapeType == 4) d = sdDiamondFrame(fp, size * 1.1, thick);
        else d = sdOctFrame(fp, size, thick);
        
        if (d < minDist) { minDist = d; hitId = id; hitType = shapeType; }
    }
    glow = 0.01 / (0.01 + minDist * minDist) * (1.0 + globalAudio.x * 0.3);
    return minDist;
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.002, 0);
    return normalize(vec3(
        scene(p + e.xyy) - scene(p - e.xyy),
        scene(p + e.yxy) - scene(p - e.yxy),
        scene(p + e.yyx) - scene(p - e.yyx)
    ));
}

vec3 getColor(int shape, float id, float t) {
    float h = hash(id + 300.);
    vec3 baseColor;
    if (shape == 0) baseColor = mix(vec3(0.2, 0.5, 1.0), vec3(0.0, 0.9, 0.9), h);
    else if (shape == 1) baseColor = mix(vec3(1.0, 0.4, 0.1), vec3(1.0, 0.8, 0.2), h);
    else if (shape == 2) baseColor = mix(vec3(0.1, 0.9, 0.3), vec3(0.6, 1.0, 0.2), h);
    else if (shape == 3) baseColor = mix(vec3(0.6, 0.2, 1.0), vec3(1.0, 0.3, 0.7), h);
    else if (shape == 4) baseColor = mix(vec3(1.0, 0.1, 0.4), vec3(1.0, 0.2, 0.2), h);
    else baseColor = mix(vec3(0.9, 0.95, 1.0), vec3(0.6, 0.85, 1.0), h);
    baseColor += vec3(globalAudio.z * 0.1, globalAudio.y * 0.05, globalAudio.x * 0.1);
    return baseColor;
}

void main() {
    vec2 F = gl_FragCoord.xy;
    vec2 R = iResolution.xy;
    vec2 uv = (F - 0.5 * R) / R.y;
    float t = iTime;

    globalAudio = sampleAudio(t);

    vec3 ro = vec3(0, 0, 0);
    vec3 rd = normalize(vec3(uv, 1.5));
    ro.x += sin(t * SWAY_SPEED_X) * SWAY_AMPLITUDE;
    ro.y += cos(t * SWAY_SPEED_Y) * SWAY_AMPLITUDE;
    float sceneRotation = t * SCENE_ROTATION_SPEED;
    rd.xy *= rot(sceneRotation + sin(t * 0.17) * 0.05);
    ro.xy += uv * PARALLAX_STRENGTH * sin(t * 0.2);

    float d = 0.;
    vec3 p;
    bool hit = false;
    float totalGlow = 0.;
    float finalId = 0.;
    int finalType = 0;

    for (int i = 0; i < 100; i++) {
        p = ro + rd * d;
        float dist = scene(p);
        totalGlow += glow * 0.01;
        if (dist < 0.002) { hit = true; finalId = hitId; finalType = hitType; break; }
        d += dist;
        if (d > 70.) break;
    }

    vec3 col = vec3(0.008, 0.01, 0.018) * (1.0 + globalAudio.x * 0.2);
    float centerV = exp(-length(uv) * 2.0);
    col += vec3(0.02, 0.025, 0.04) * centerV * (1.0 + globalAudio.y * 0.3);

    if (hit) {
        vec3 n = calcNormal(p);
        vec3 baseCol = getColor(finalType, finalId, t);
        vec3 lightDir = normalize(vec3(0.4, 0.6, -0.8));
        float diff = max(dot(n, lightDir), 0.);
        float amb = 0.3 + 0.2 * n.y;
        vec3 refl = reflect(rd, n);
        float spec = pow(max(dot(refl, lightDir), 0.), 24.) * (1.0 + globalAudio.z * 0.5);
        float fres = pow(1. - abs(dot(-rd, n)), 3.);
        col = baseCol * (diff * 0.6 + amb);
        col += vec3(1.0, 0.95, 0.9) * spec * 0.5;
        col += baseCol * fres * 0.4;
        float fog = exp(-d * 0.035);
        col = mix(vec3(0.01, 0.015, 0.025), col, fog);
    }

    col += vec3(0.3, 0.35, 0.5) * totalGlow * 0.2;
    col *= 1.0 - dot(uv, uv) * 0.3;
    col = pow(max(col, 0.), vec3(0.4545));

    fragColor = vec4(col, 1);
}

