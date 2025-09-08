// Author: towrabbit
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec4 transition(vec2 uv) {
    vec4 leftSide = texture(from, uv);
    vec2 uv1 = uv;
    float uvz = floor(random(uv1) + progress);
    vec4 rightSide = texture(to, uv);
    return mix(leftSide, rightSide, uvz);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}