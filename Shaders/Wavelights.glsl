#version 330 core

// Wavelights
// Created by diatribes in 2025-10-21
// https://www.shadertoy.com/view/WfSyWy
// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

mat2 rot(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

void main() {
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 u = gl_FragCoord.xy;
    u.y = iResolution.y - u.y;

    float t = iTime;
    vec3 p = vec3(iResolution, 0.0);

    u = (u + u - p.xy) / p.y;

    vec4 o = vec4(0.0);
    float d = 3.5;

    for (int i = 0; i < 100; i++) {
        // position
        p = vec3(u * d, d);
        // rots
        p.xy *= rot(-t * 0.11);
        p.xz *= rot(t * 0.11);
        // ripples
        p += cos(2.0 * t + dot(cos(t + p), p) * p);
        // accumulate distance
        float s = dot(abs(p - floor(p) - 0.5), vec3(0.02));
        d += s;
        // accumulate color
        o += 6.0 * d * vec4(1.0, 2.0, 7.0, 0.0) + (1.0 + cos(p.z + vec4(6.0, 4.0, 2.0, 0.0))) / (s + 0.001);
    }

    // tonemap, brightness
    o = tanh(o / 2e4);
    fragColor = o;
}