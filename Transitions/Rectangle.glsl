// Author: martiniti
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform vec4 bgcolor; // = vec4(0.0, 0.0, 0.0, 1.0)

out vec4 outColor;

float s = pow(2.0 * abs(progress - 0.5), 3.0);

vec4 transition(vec2 p) {
    vec2 sq = p.xy / vec2(1.0).xy;
    vec2 bl = step(vec2(abs(1.0 - 2.0 * progress)), sq + 0.25);
    float dist = bl.x * bl.y;
    vec2 tr = step(vec2(abs(1.0 - 2.0 * progress)), 1.25 - sq);
    dist *= 1.0 * tr.x * tr.y;
    return mix(
        progress < 0.5 ? texture(from, p) : texture(to, p),
        bgcolor,
        step(s, dist)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}