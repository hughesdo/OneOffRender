// Author: pschroen
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float smoothness; // = 0.1
uniform vec2 direction; // = vec2(-1.0, 1.0)

out vec4 outColor;

const vec2 center = vec2(0.5, 0.5);

vec4 transition(vec2 uv) {
    vec2 v = normalize(direction);
    v /= abs(v.x) + abs(v.y);
    float d = v.x * center.x + v.y * center.y;
    float m = 1.0 - smoothstep(-smoothness, 0.0, v.x * uv.x + v.y * uv.y - (d - 0.5 + progress * (1.0 + smoothness)));
    return mix(texture(from, (uv - 0.5) * (1.0 - m) + 0.5), texture(to, (uv - 0.5) * m + 0.5), m);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}