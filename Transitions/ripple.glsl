// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float amplitude; // = 100.0
uniform float speed; // = 50.0

out vec4 outColor;

vec4 transition(vec2 uv) {
    vec2 dir = uv - vec2(0.5);
    float dist = length(dir);
    vec2 offset = dir * (sin(progress * dist * amplitude - progress * speed) + 0.5) / 30.0;
    return mix(
        texture(from, uv + offset),
        texture(to, uv),
        smoothstep(0.2, 1.0, progress)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}