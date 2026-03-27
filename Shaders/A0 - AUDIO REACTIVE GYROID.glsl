#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

/*
    AUDIO REACTIVE GYROID
    =====================
    Setup: Set iChannel0 to audio (mic or music)
*/

// === TWEAK THESE ===
#define AUDIO_STRENGTH 0.5
#define GYROID_SCALE 9.0
#define ROTATION_SPEED 0.2
#define SURFACE_THICKNESS 0.02


// Audio bands
float bass, mids, treble;

void getAudio() {
    bass = texture(iChannel0, vec2(0.05, 0.0)).x;
    mids = texture(iChannel0, vec2(0.2, 0.0)).x;
    treble = texture(iChannel0, vec2(0.6, 0.0)).x;

    bass = pow(bass, 0.8) * AUDIO_STRENGTH;
    mids = pow(mids, 0.8) * AUDIO_STRENGTH;
    treble = pow(treble, 0.8) * AUDIO_STRENGTH;
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float gyroid(vec3 p) {
    return dot(sin(p), cos(p.zxy));
}

float map(vec3 p) {
    float t = iTime * ROTATION_SPEED;
    p.xy *= rot(t);
    p.yz *= rot(t * 0.7);

    float pulse = 1.0 + bass * 0.15;

    float g = abs(gyroid(p * GYROID_SCALE)) / GYROID_SCALE - SURFACE_THICKNESS;
    float sphere = length(p) - 1.3 * pulse;

    return max(g, sphere);
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

float march(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 100; i++) {
        float d = map(ro + rd * t);
        if (d < 0.001 || t > 20.0) break;
        t += d * 0.8;
    }
    return t;
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    getAudio();

    // Camera
    vec3 ro = vec3(0.0, 0.0, 3.5);
    vec3 rd = normalize(vec3(uv, -1.5));

    float t = march(ro, rd);

    // Background - deep blue/purple, pulses with bass
    vec3 col = mix(vec3(0.05, 0.08, 0.15), vec3(0.02, 0.01, 0.08), length(uv));
    col *= (1.0 + bass * 0.4);

    if (t < 20.0) {
        vec3 p = ro + rd * t;
        vec3 n = calcNormal(p);

        // Lighting
        vec3 lightDir = normalize(vec3(1.0, 2.0, 1.0));
        float diff = max(dot(n, lightDir), 0.0);
        float spec = pow(max(dot(reflect(-lightDir, n), -rd), 0.0), 32.0);
        float fres = pow(1.0 - max(dot(n, -rd), 0.0), 3.0);

        // === IRIDESCENT RAINBOW COLOR (inspired by reference) ===
        // Position-based rainbow that shifts with time and audio
        float colorSpeed = 0.5 + mids * 0.5;
        float colorScale = 2.0 + treble * 1.0;
        vec3 baseCol = 0.5 + 0.5 * cos(iTime * colorSpeed + p * colorScale + vec3(0.0, 2.0, 4.0));

        // Boost saturation and vibrancy with audio
        baseCol = pow(baseCol, vec3(0.8));  // Brighten
        baseCol *= 1.0 + bass * 0.4;        // Bass brightens

        // Secondary iridescence on edges (fresnel rainbow)
        vec3 edgeCol = 0.5 + 0.5 * cos(iTime * 0.3 + fres * 6.0 + vec3(2.0, 0.0, 4.0));
        baseCol = mix(baseCol, edgeCol, fres * 0.6);

        // Combine lighting
        col = baseCol * (diff * 0.7 + 0.3);
        col += spec * vec3(1.0, 0.95, 0.9) * 0.6;
        col += fres * baseCol * 0.3;

        // Extra glow on bass hits
        col += baseCol * fres * bass * 0.4;
    }

    // Vignette
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.3);

    // Tone mapping + gamma
    col = col / (1.0 + col);
    col = pow(col, vec3(0.45));

    fragColor = vec4(col, 1.0);
}
