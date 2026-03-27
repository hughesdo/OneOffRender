#version 330 core

// Space Cave - Audio-Reactive Breathing Cave
// Created by OneHung
// Inspired by Blackle Mori's Music Cave
// https://www.shadertoy.com/view/wfyczt

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

#define AUDIO_MIX 0.4
#define ENABLE_EROSION 1.0
#define ENABLE_EDGE_GLOW 1.0
#define ENABLE_BREATHING 1.0
#define ENABLE_FOG 1.0
#define ENABLE_RIM 1.0
#define TRAVEL_SPEED 6.0
#define CAVE_RADIUS 1.5
#define BRIGHTNESS 1.4
#define SATURATION 1.3
#define GLOW_INTENSITY 1.0
#define FOG_AMOUNT 0.5
#define RIM_STRENGTH 0.4
#define EROSION_DEPTH 0.25

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(ax,p)*ax, p, cos(ro)) + sin(ro)*cross(ax,p);
}

#define FK(k) floatBitsToInt(k*k/7.)^floatBitsToInt(k)
float hash(float a, float b) {
    int x = FK(a), y = FK(b);
    return float((x*x-y)*(y*y+x)-x)/2.14e9;
}

float audioRaw(float freq) {
    return pow(texture(iChannel0, vec2(freq, 0.25)).r, 2.0);
}

float bassEnergy, midEnergy, highEnergy, totalEnergy;
void sampleAudio() {
    float m = AUDIO_MIX;
    bassEnergy = (audioRaw(0.02) + audioRaw(0.05) + audioRaw(0.08) + audioRaw(0.12)) / 4.0 * m;
    midEnergy = (audioRaw(0.2) + audioRaw(0.35) + audioRaw(0.5)) / 3.0 * m;
    highEnergy = (audioRaw(0.6) + audioRaw(0.75) + audioRaw(0.9)) / 3.0 * m;
    totalEnergy = bassEnergy + midEnergy + highEnergy;
}

float smin(float a, float b, float k) {
    float h = max(0.0, k - abs(b-a)) / k;
    return min(a, b) - h*h*h*k/6.0;
}

float edges;
float comp(vec3 p) {
    vec3 s = sin(p) * sin(p);
    edges = max(max(edges, s.x), max(s.z, s.y));
    p = asin(sin(p));
    return dot(p, normalize(vec3(1)));
}

float gatedSphere(vec4 p, float scale, bool gated) {
    if (!gated) {
        p.yzw = abs(p.yzw);
        if (p.y > p.z) p.yz = p.zy;
        if (p.z > p.w) p.zw = p.wz;
        if (p.y > p.z) p.yz = p.zy;
        p.w -= scale;
    }
    return length(p) - scale / 2.2;
}

float audioErode(vec3 p, float baseDist, float erodeAmount) {
    if (ENABLE_EROSION < 0.5) return baseDist;
    float eroded = baseDist;
    float accum = baseDist;
    for (int i = 0; i < 4; i++) {
        p = erot(p, normalize(vec3(1, 2, 3)), 0.2 + float(i) * 0.3);
        p = erot(p, normalize(vec3(3, 1, 2)), 0.5 + float(i) * 0.2);
        float octaveScale = 0.6 / pow(float(i + 1), 1.3);
        float audioMod = 0.3;
        if (i < 2) audioMod += bassEnergy * 1.0;
        else audioMod += midEnergy * 0.6;
        vec4 p4d = vec4(accum, p);
        vec3 id = floor(p4d.yzw / octaveScale);
        p4d.yzw = (fract(p4d.yzw / octaveScale) - 0.5) * octaveScale;
        bool gated = hash(id.x, hash(id.y, id.z)) > 0.5 - audioMod * 0.1;
        float holeDepth = octaveScale * erodeAmount * audioMod;
        float holes = gatedSphere(p4d, octaveScale, gated);
        eroded = -smin(-eroded, holes - holeDepth, 0.03 * sqrt(octaveScale));
        accum = eroded;
    }
    return eroded;
}

float caveWalls;
float travelPos;

float scene(vec3 p) {
    edges = 0.0;
    p.z += travelPos;
    float d1 = comp(erot(p, normalize(vec3(3, 2, 1)), 0.5) + 1.0);
    float d2 = comp(erot(p, normalize(vec3(2, 1, 3)), 0.6) + 2.0);
    float d3 = comp(erot(p, normalize(vec3(1, 3, 2)), 0.7) + 3.0 + iTime * 0.1);
    float breathe = ENABLE_BREATHING > 0.5 ? (1.0 + bassEnergy * 0.2) : 1.0;
    caveWalls = (d1 + d2 + d3) / 3.0 - length(p.xy * vec2(1.0, 0.8)) / 3.0 + CAVE_RADIUS * breathe;
    float erodeAmt = EROSION_DEPTH + totalEnergy * 0.2;
    return audioErode(p, caveWalls, erodeAmt);
}

vec3 norm(vec3 p) {
    mat3 k = mat3(p, p, p) - mat3(0.01);
    return normalize(scene(p) - vec3(scene(k[0]), scene(k[1]), scene(k[2])));
}

void main() {
    vec2 uv = (gl_FragCoord.xy - iResolution.xy * 0.5) / iResolution.y;
    sampleAudio();
    travelPos = iTime * TRAVEL_SPEED;

    vec3 cam = normalize(vec3(uv.x * 0.5, uv.y * 0.5, 1.2));
    vec3 init = vec3(0.0, 0.0, 0.0);
    cam = erot(cam, vec3(0, 0, 1), sin(iTime * 0.3) * 0.06);
    cam = erot(cam, vec3(1, 0, 0), sin(iTime * 0.2) * 0.03);
    init.y += bassEnergy * 0.1;

    vec3 p = init;
    bool hit = false;
    float dist;
    float edgeGlow = 0.0;
    float marchDist = 0.0;

    for (int i = 0; i < 80 && !hit; i++) {
        dist = scene(p);
        hit = dist * dist < 1e-6;
        if (ENABLE_EDGE_GLOW > 0.5) {
            float eg = smoothstep(0.93, 1.0, edges) / (1.0 + abs(caveWalls) * 60.0);
            float wave = pow(abs(sin((p.z + travelPos) * 0.06 + iTime * 0.2)), 2.5);
            wave *= 1.0 + bassEnergy * 1.5;
            edgeGlow += eg * wave * 0.2 * GLOW_INTENSITY;
        }
        p += cam * dist;
        marchDist += dist;
        if (marchDist > 50.0) break;
    }

    float fogFactor = ENABLE_FOG > 0.5 ? smoothstep(40.0, 0.0, marchDist) : 1.0;
    fogFactor = mix(1.0, fogFactor, FOG_AMOUNT);

    #define AO(pp, nn, t) smoothstep(-t, t, scene(pp + nn * t))

    vec3 n = norm(p);
    vec3 r = reflect(cam, n);
    float ao = AO(p, n, 0.5) * AO(p, n, 0.25) * AO(p, n, 0.1);
    float sss = AO(p, vec3(0.5), 0.5);
    float spec = length(sin(r * 2.5) * 0.4 + 0.6) / sqrt(2.0);
    float diff = length(sin(n * 2.0) * 0.5 + 0.5) / sqrt(3.0);

    float rim = 0.0;
    if (ENABLE_RIM > 0.5) {
        rim = pow(1.0 - abs(dot(cam, n)), 2.5);
        rim *= RIM_STRENGTH * (1.0 + totalEnergy);
    }

    float phase = (p.z + travelPos) * 0.012 + iTime * 0.05;
    vec3 col1 = vec3(0.4, 0.55, 0.9);
    vec3 col2 = vec3(0.7, 0.4, 0.8);
    vec3 col3 = vec3(0.3, 0.7, 0.6);
    vec3 wallCol = mix(col1, col2, sin(phase) * 0.5 + 0.5);
    wallCol = mix(wallCol, col3, sin(phase * 1.4 + 1.0) * 0.5 + 0.5);

    vec3 grey = vec3(dot(wallCol, vec3(0.299, 0.587, 0.114)));
    vec3 matcol = mix(grey, wallCol, SATURATION);
    vec3 col = mix(diff, sss, 0.3) * matcol;

    float ms = step(0.93, edges);
    col *= 1.0 - ms * 0.3;
    col += pow(spec, 8.0) * 0.4;

    vec3 rimCol = mix(vec3(0.5, 0.4, 0.8), vec3(0.8, 0.5, 0.4), sin(phase * 2.0) * 0.5 + 0.5);
    col += rim * rimCol;
    col = col * ao * BRIGHTNESS;

    vec3 bgCol = mix(vec3(0.12, 0.08, 0.18), vec3(0.04, 0.06, 0.12), uv.y * 0.5 + 0.5);
    col = hit ? mix(bgCol, col, fogFactor) : bgCol;

    vec3 glowCol = mix(vec3(0.5, 0.5, 0.9), vec3(0.9, 0.5, 0.4), sin(iTime * 0.2) * 0.5 + 0.5);
    col += edgeGlow * edgeGlow * glowCol;
    col += edgeGlow * 0.1 * vec3(0.4, 0.5, 0.8);
    col *= 1.0 - dot(uv, uv) * 0.3;

    fragColor = vec4(sqrt(max(col, 0.0)), 1.0);
}

