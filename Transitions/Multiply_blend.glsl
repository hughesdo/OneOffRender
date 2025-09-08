// Author: Fernando Kuteken
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

vec4 blend(vec4 a, vec4 b) {
    return a * b;
}

vec4 transition(vec2 uv) {
    vec4 blended = blend(texture(from, uv), texture(to, uv));
    if (progress < 0.5) {
        return mix(texture(from, uv), blended, 2.0 * progress);
    } else {
        return mix(blended, texture(to, uv), 2.0 * progress - 1.0);
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}