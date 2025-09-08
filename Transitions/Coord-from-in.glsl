// Author: haiyoucuv
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

vec4 transition(vec2 uv) {
    vec4 coordTo = texture(to, uv);
    vec4 coordFrom = texture(from, uv);
    return mix(
        texture(from, coordTo.rg),
        texture(to, uv),
        progress
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}