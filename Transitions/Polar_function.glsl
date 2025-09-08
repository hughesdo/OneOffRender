// Author: Fernando Kuteken
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform int segments; // = 5

out vec4 outColor;

#define PI 3.14159265359

vec4 transition(vec2 uv) {
    float angle = atan(uv.y - 0.5, uv.x - 0.5) - 0.5 * PI;
    float normalized = (angle + 1.5 * PI) * (2.0 * PI);
    float radius = (cos(float(segments) * angle) + 4.0) / 4.0;
    float difference = length(uv - vec2(0.5, 0.5));
    if (difference > radius * progress)
        return texture(from, uv);
    else
        return texture(to, uv);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}