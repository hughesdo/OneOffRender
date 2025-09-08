// Author: Ben Lucas
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float n_noise_pixels; // = 200.0
uniform float static_luminosity; // = 0.8

out vec4 outColor;

float rnd(vec2 st) {
    return fract(sin(dot(st.xy, vec2(10.5302340293, 70.23492931))) * 12345.5453123);
}

vec4 staticNoise(vec2 st, float offset, float luminosity) {
    float staticR = luminosity * rnd(st * vec2(offset * 2.0, offset * 3.0));
    float staticG = luminosity * rnd(st * vec2(offset * 3.0, offset * 5.0));
    float staticB = luminosity * rnd(st * vec2(offset * 5.0, offset * 7.0));
    return vec4(staticR, staticG, staticB, 1.0);
}

float staticIntensity(float t) {
    float transitionProgress = abs(2.0 * (t - 0.5));
    float transformedThreshold = 1.2 * (1.0 - transitionProgress) - 0.1;
    return min(1.0, transformedThreshold);
}

vec4 transition(vec2 uv) {
    float baseMix = step(0.5, progress);
    vec4 transitionMix = mix(
        texture(from, uv),
        texture(to, uv),
        baseMix
    );
    vec2 uvStatic = floor(uv * n_noise_pixels) / n_noise_pixels;
    vec4 staticColor = staticNoise(uvStatic, progress, static_luminosity);
    float staticThresh = staticIntensity(progress);
    float staticMix = step(rnd(uvStatic), staticThresh);
    return mix(transitionMix, staticColor, staticMix);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}