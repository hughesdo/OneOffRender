// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform sampler2D luma;

out vec4 outColor;

vec4 transition(vec2 uv) {
    return mix(
        texture(to, uv),
        texture(from, uv),
        step(progress, texture(luma, uv).r)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}