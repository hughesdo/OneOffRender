#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// Cosmic Vortex - Audio Reactive
// Set iChannel0 to audio input

#define PI 3.14159265359
#define TAU 6.28318530718

float getAudio(float f) { return texture(iChannel0, vec2(f, 0.0)).x; }
float bass() { return (getAudio(0.01) + getAudio(0.05) + getAudio(0.08)) * 0.8; }
float mid() { return (getAudio(0.15) + getAudio(0.25) + getAudio(0.35)) * 0.6; }
float high() { return (getAudio(0.5) + getAudio(0.65) + getAudio(0.8)) * 0.5; }

vec3 spectrum(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.33, 0.67)));
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float b = bass(), m = mid(), h = high(), total = b + m + h;
    
    // Polar coordinates
    float r = length(uv);
    float a = atan(uv.y, uv.x);
    float time = iTime;

    // High-frequency wiggle (~70 teeth per revolution)
    float wiggle = sin(a * (70.0 + h * 20.0) + time * 3.0) * (0.025 + m * 0.015);
    float wobble = sin(a * 7.0 - time * 2.0) * 0.01 * (1.0 + b);

    // Tunnel coordinate: 1/r = infinite depth, +a = spiral twist
    float tunnel = 1.0 / (r + 0.001);
    float spiralCoord = tunnel + a * 3.5 + wiggle + wobble + time * (2.0 + m * 1.5);
    float rotatedA = a + time * (0.5 + b * 0.3);

    // Generate lines via sine interference (multiple frequencies for density)
    float lines1 = pow(abs(sin(spiralCoord * 8.0)), 0.3);
    float lines2 = pow(abs(sin(spiralCoord * 16.0 + 0.5)), 0.5) * 0.5;
    float lines3 = pow(abs(sin(spiralCoord * 24.0 + 1.0)), 0.7) * 0.25;
    float lines = clamp(lines1 + lines2 + lines3, 0.0, 1.5) * (0.8 + total * 0.4);

    // Color follows spiral arms
    float colorCoord = rotatedA / TAU + tunnel * 0.15;
    vec3 col = pow(spectrum(colorCoord), vec3(0.7)) * lines;

    // Glow + hot cores
    col += spectrum(colorCoord + 0.1) * (0.15 / (r + 0.15)) * (0.5 + 0.5 * sin(spiralCoord * 8.0)) * (1.0 + total * 0.5);
    col += vec3(1.0, 0.95, 0.9) * pow(abs(sin(spiralCoord * 8.0)), 8.0) * 0.3 * smoothstep(0.0, 0.3, r);

    // Depth: dark center void + edge falloff
    col *= smoothstep(0.0, 0.25, r) * smoothstep(1.5, 0.5, r);

    // Tone mapping + saturation
    col = pow(mix(vec3(dot(1.0 - exp(-col * 1.8), vec3(0.299, 0.587, 0.114))), 1.0 - exp(-col * 1.8), 1.3), vec3(0.9));

    fragColor = vec4(col, 1.0);
}