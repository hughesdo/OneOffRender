// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float smoothness; // = 0.3
uniform bool opening; // = true

out vec4 outColor;

const vec2 center = vec2(0.5, 0.5);
const float SQRT_2 = 1.414213562373;

vec4 transition(vec2 uv) {
    float x = opening ? progress : 1.0 - progress;
    float m = smoothstep(-smoothness, 0.0, SQRT_2 * distance(center, uv) - x * (1.0 + smoothness));
    return mix(texture(from, uv), texture(to, uv), opening ? 1.0 - m : m);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}