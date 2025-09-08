// Author: haiyoucuv
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

vec4 scale(in vec2 uv) {
    uv = 0.5 + (uv - 0.5) * progress;
    return texture(to, uv);
}

vec4 transition(vec2 uv) {
    return mix(
        texture(from, uv),
        scale(uv),
        progress
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}