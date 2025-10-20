#version 330 core
// The original: sleepless
// Created by diatribes on 2025-08-17
// https://www.shadertoy.com/view/WclcRN
// Audio reactive modifications by @OneHung
// Fixed for OpenGL/WebGL compatibility

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture
out vec4 fragColor;

// Audio reactive modifications:
// TWEAK THESE VALUES:
#define BASS_SAMPLE_POS 0.05    // Lower = deeper bass (0.01-0.1)
#define BASS_MULTIPLIER 4.0     // How much brighter on bass hits (2.0-8.0)
#define COLOR_SHIFT_AMOUNT 8.0  // How much color changes on bass (4.0-12.0)
#define BASS_THRESHOLD 0.1      // Minimum bass level to trigger (0.05-0.3)
#define ORB_BRIGHTNESS 0.1      // Base orb brightness (0.5-3.0)

// Custom tanh implementation for compatibility
vec4 tanh4(vec4 x) {
    vec4 exp2x = exp(2.0 * x);
    return (exp2x - 1.0) / (exp2x + 1.0);
}

// woke up and couldn't get back to sleep :/
void mainImage(out vec4 o, vec2 u) {
    float d = 0.0;
    float a = 0.0;
    float e = 0.0;
    float i = 0.0;
    float s = 0.0;
    float t = iTime;
    vec3 p = iResolution.xyx;  // Original pattern
    
    // Get bass frequency from audio channel
    float bass = texture(iChannel0, vec2(BASS_SAMPLE_POS, 0.25)).x;
    bass = max(0.0, bass - BASS_THRESHOLD); // Remove noise floor
    float bassBoost = ORB_BRIGHTNESS * (1.0 + bass * BASS_MULTIPLIER); // Brightness multiplier

    // Scale coords - Zoom out 1.5x for wider cloud visibility
    u = (u + u - p.xy) / (p.y * 1.5);
    
    // Cinema bars
    //if (abs(u.y) > 0.8) { 
    //    o = vec4(0.0, 0.0, 0.0, 1.0); 
    //    return; 
    //}

    u += vec2(cos(t * 0.4) * 0.3, cos(t * 0.8) * 0.1);

    o = vec4(0.0);

    while (i < 128.0) {
        p.xy = u * d;
        p.z = d + t;
        e = length(p - vec3(
            sin(sin(t * 0.2) + t * 0.4) * 2.0,
            1.0 + sin(sin(t * 0.5) + t * 0.2) * 2.0,
            12.0 + t + cos(t * 0.3) * 8.0)) - 0.1;

        float angle = 0.1 * t + p.z / 16.0;
        mat2 rot = mat2(
            cos(angle + 0.0), cos(angle + 33.0),
            cos(angle + 11.0), cos(angle + 0.0)
        );
        p.xy *= rot;

        s = 6.0 - abs(p.y);  // Extend clouds vertically for more coverage

        a = 0.42;
        while (a < 16.0) {
            p += cos(0.4 * t + p.yzx) * 0.3;

            s -= abs(dot(sin(0.1 * t + p * a), 0.18 + p - p)) / a;

            a += a;
        }

        e = max(0.8 * e, 0.01);
        s = min(0.01 + 0.4 * abs(s), e);
        d += s;
        o += (1.0 + cos(0.1 * p.z * vec4(3.0, 1.0, 0.0, 0.0) + bass * COLOR_SHIFT_AMOUNT)) * bassBoost / (s + e * 2.0);

        i += 1.0;
    }

    u += (u.yx * 0.9 + 0.3 - vec2(-1.0, 0.5));
    o = tanh4(o / 6.0 / max(dot(u, u), 0.001));
    
    // Ensure alpha is 1.0
    o.a = 1.0;
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}