// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float size; // = 0.2

out vec4 outColor;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 transition(vec2 uv) {
    float r = rand(vec2(0.0, uv.y));
    float m = smoothstep(0.0, -size, uv.x * (1.0 - size) + size * r - (progress * (1.0 + size)));
    return mix(
        texture(from, uv),
        texture(to, uv),
        m
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}