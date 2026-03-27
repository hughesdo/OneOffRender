#version 330 core

// Gyroid Orb Journey v4 - Plasma Orb Edition
// Created by OneHung
// Inspired by BigWings' "Math Zoo - Alien Orb"
// https://www.shadertoy.com/view/WcdyW2

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

#define BASS_FREQ 0.05
#define BASS_SMOOTHING 0.2
#define PLASMA_BASE 0.8
#define PLASMA_PULSE 2.0
#define ORB_COLOR_SHIFT 0.5
#define CAGE_GLOW_MULT 1.0
#define ORB_RADIUS 0.4
#define ORB_SHELL_THICK 0.03
#define ORB_GYROID_SCALE 12.0
#define ORB_GYROID_THICK 0.25
#define PLASMA_CORE_SIZE 0.15
#define SPEED 1.5
#define ORB_LEAD_DISTANCE 5.0
#define ORB_WEAVE_AMOUNT 0.5
#define ORB_BOB_AMOUNT 0.3
#define ORB_SPIN_SPEED 0.3
#define TUNNEL_RADIUS 2.5
#define GYROID_FREQ 2.5
#define GYROID_THICKNESS 0.08
#define T (iTime * SPEED)
#define N normalize

mat2 Rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}

float getFFT(float freq) {
    return texture(iChannel0, vec2(freq, 0.25)).x;
}

float getFFTSmoothed(float freq) {
    float sum = 0.0;
    for (float i = -2.0; i <= 2.0; i++) {
        sum += texture(iChannel0, vec2(freq + i * BASS_SMOOTHING * 0.1, 0.25)).x;
    }
    return sum / 5.0;
}

vec3 P(float z) {
    return vec3(cos(z * 0.15) * 5.0, cos(z * 0.12) * 3.0, z);
}

float orbLight;
float plasmaLight;
float bassLevel;
vec3 currentOrbPos;

vec3 getOrbPos() {
    float orbZ = T * 1.5 + ORB_LEAD_DISTANCE + cos(T * 0.5) * 2.0;
    vec3 q = P(orbZ);
    return vec3(q.x + sin(orbZ * 0.4) * ORB_WEAVE_AMOUNT, q.y + sin(orbZ * 0.3 + T) * ORB_BOB_AMOUNT, orbZ);
}

float orbGyroid(vec3 p) {
    float scale = ORB_GYROID_SCALE;
    vec3 p2 = p * scale;
    p2.xy *= Rot(T * ORB_SPIN_SPEED);
    p2.yz *= Rot(T * ORB_SPIN_SPEED * 0.7);
    return (abs(dot(sin(p2), cos(p2.zxy))) - ORB_GYROID_THICK) / scale;
}

float alienOrb(vec3 p) {
    vec3 orbPos = getOrbPos();
    vec3 localP = p - orbPos;
    float distFromCenter = length(localP);
    float sphere = abs(distFromCenter - ORB_RADIUS) - ORB_SHELL_THICK;
    float cage = smin(sphere, orbGyroid(localP) * 0.7, -0.03);
    float core = distFromCenter - PLASMA_CORE_SIZE;
    float plasmaIntensity = PLASMA_BASE + bassLevel * PLASMA_PULSE;
    plasmaLight += plasmaIntensity / max(core * core, 0.001);
    float cageGlow = CAGE_GLOW_MULT / max(abs(cage), 0.01);
    orbLight += cageGlow * (1.0 + bassLevel * 2.0);
    return cage;
}

float gyroid(vec3 p) {
    p.xy -= P(p.z).xy;
    vec3 q = p * GYROID_FREQ;
    float g = (sin(q.x)*cos(q.y) + sin(q.y)*cos(q.z) + sin(q.z)*cos(q.x)) / GYROID_FREQ;
    float tunnel = TUNNEL_RADIUS - length(p.xy);
    return max(abs(g) - GYROID_THICKNESS, tunnel);
}

float map(vec3 p) {
    float orb = alienOrb(p);
    float g = gyroid(p);
    return min(g, orb);
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
    vec2 uv = (gl_FragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    bassLevel = clamp(getFFTSmoothed(BASS_FREQ) * 1.5, 0.0, 1.0);
    orbLight = 0.0;
    plasmaLight = 0.0;

    vec3 ro = P(T * 1.5);
    vec3 lookAt = P(T * 1.5 + 4.0);
    currentOrbPos = getOrbPos();

    vec3 Z = N(lookAt - ro);
    vec3 X = N(vec3(Z.z, 0, -Z.x));
    vec3 Y = cross(Z, X);
    float roll = sin(T * 0.3) * 0.2;
    uv *= Rot(roll);
    vec3 rd = N(uv.x * X + uv.y * Y + Z);

    float d = 0.0;
    vec3 col = vec3(0);
    vec3 hitPos;
    bool hit = false;

    for (float i = 0.0; i < 100.0; i++) {
        vec3 p = ro + rd * d;
        float s = map(p);
        float glow = 0.015 / (abs(s) + 0.01);
        vec3 glowCol = 0.5 + 0.5 * cos(p * 0.3 + vec3(0, 2, 4) + T * 0.2);
        col += glowCol * glow * exp(-d * 0.03);
        if (s < 0.005) { hit = true; hitPos = p; break; }
        d += s * 0.8;
        if (d > 60.0) break;
    }

    if (hit) {
        vec3 n = getNormal(hitPos);
        vec3 localP = hitPos - currentOrbPos;
        float distToOrbCenter = length(localP);
        bool hitOrb = distToOrbCenter < ORB_RADIUS + 0.1;

        if (hitOrb) {
            vec3 toCore = N(currentOrbPos - hitPos);
            float coreDiff = max(dot(n, toCore), 0.0);
            float fresnel = pow(1.0 - abs(dot(n, -rd)), 3.0);
            vec3 cageColor = mix(vec3(0.8, 0.6, 0.4), vec3(1.0, 0.3, 0.5), bassLevel * ORB_COLOR_SHIFT);
            vec3 plasmaColor = mix(vec3(1.0, 0.9, 0.8), vec3(1.0, 0.5, 0.8), bassLevel * ORB_COLOR_SHIFT);
            col += cageColor * (coreDiff * 0.5 + 0.2);
            col += fresnel * plasmaColor * (1.0 + bassLevel * 2.0);
            float sss = pow(max(0.0, dot(rd, toCore)), 2.0) * 0.5;
            col += sss * plasmaColor * (1.0 + bassLevel * PLASMA_PULSE);
            float veinPattern = abs(dot(sin(localP * 30.0 + iTime * 2.0), cos(localP.zxy * 30.0)));
            veinPattern = smoothstep(0.3, 0.5, veinPattern);
            col += plasmaColor * veinPattern * 0.3 * (1.0 + bassLevel * 3.0);
        } else {
            vec3 toOrb = N(currentOrbPos - hitPos);
            float orbDist = length(currentOrbPos - hitPos);
            float orbLightVal = max(dot(n, toOrb), 0.0) / (1.0 + orbDist * orbDist * 0.05);
            vec3 surfCol = 0.5 + 0.5 * cos(hitPos * 0.4 + vec3(0, 2, 4));
            col += surfCol * 0.3 / (1.0 + d * 0.1);
            vec3 orbCastColor = mix(vec3(1.0, 0.7, 0.4), vec3(1.0, 0.4, 0.6), bassLevel);
            col += orbCastColor * orbLightVal * (1.0 + bassLevel * 2.0);
        }
    }

    vec3 plasmaGlowColor = mix(vec3(1.0, 0.9, 0.85), vec3(1.0, 0.6, 0.8), bassLevel * ORB_COLOR_SHIFT);
    col += plasmaGlowColor * plasmaLight * 0.00003 * (1.0 + bassLevel * 2.0);
    vec3 cageGlowColor = mix(vec3(1.0, 0.7, 0.3), vec3(1.0, 0.4, 0.7), bassLevel * ORB_COLOR_SHIFT);
    col += cageGlowColor * orbLight * 0.0003;

    vec3 toOrbScreen = currentOrbPos - ro;
    float orbScreenDist = length(toOrbScreen.xy / toOrbScreen.z - uv);
    float starburst = 0.02 / max(orbScreenDist, 0.01);
    starburst *= smoothstep(60.0, 10.0, length(currentOrbPos - ro));
    col += plasmaGlowColor * starburst * 0.1 * (1.0 + bassLevel * 3.0);

    float pulse = pow(bassLevel, 3.0);
    col *= 1.0 + pulse * 0.3;
    col = tanh(col * 0.5);
    col *= 1.0 - 0.15 * length(uv);
    col += cageGlowColor * bassLevel * 0.03 * pow(length(uv), 2.0);

    fragColor = vec4(col, 1.0);
}

