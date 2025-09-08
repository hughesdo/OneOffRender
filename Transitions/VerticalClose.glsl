// Author: martiniti
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

vec4 transition(vec2 uv) {
    float s = 2.0 - abs((uv.x - 0.5) / (progress - 1.0)) - 2.0 * progress;
    return mix(
        texture(from, uv),
        texture(to, uv),
        smoothstep(0.5, 0.0, s)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}