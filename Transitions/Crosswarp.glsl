// Author: Eke Péter <peterekepeter@gmail.com>
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

vec4 transition(vec2 p) {
    float x = progress;
    x = smoothstep(0.0, 1.0, (x * 2.0 + p.x - 1.0));
    return mix(texture(from, (p - 0.5) * (1.0 - x) + 0.5), texture(to, (p - 0.5) * x + 0.5), x);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}