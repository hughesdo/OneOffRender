// License: MIT
// Author: martiniti
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform vec4 bgcolor; // = vec4(0.0, 0.0, 0.0, 1.0)

out vec4 outColor;

vec4 transition(vec2 uv) {
    float s = pow(2.0 * abs(progress - 0.5), 3.0);
    vec2 q = uv.xy / vec2(1.0).xy;
    vec2 bl = step(vec2(1.0 - 2.0 * abs(progress - 0.5)), q + 0.25);
    vec2 tr = step(vec2(1.0 - 2.0 * abs(progress - 0.5)), 1.25 - q);
    float dist = length(1.0 - bl.x * bl.y * tr.x * tr.y);
    return mix(
        progress < 0.5 ? texture(from, uv) : texture(to, uv),
        bgcolor,
        step(s, dist)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}