// Author: haiyoucuv
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

#define PI 3.1415926

vec2 rotate2D(in vec2 uv, in float angle) {
    return uv * mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

vec4 transition(vec2 uv) {
    vec2 p = fract(rotate2D(uv - 0.5, progress * PI * 2.0) + 0.5);
    return mix(
        texture(from, p),
        texture(to, p),
        progress
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}