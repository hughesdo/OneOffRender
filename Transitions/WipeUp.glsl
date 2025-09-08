// Author: Jake Nelson
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

vec4 transition(vec2 uv) {
    vec2 p = uv.xy / vec2(1.0).xy;
    vec4 a = texture(from, p);
    vec4 b = texture(to, p);
    return mix(a, b, step(0.0 + p.y, progress));
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}