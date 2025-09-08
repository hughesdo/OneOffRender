// Author: mikolalysenko
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

vec2 offset(float progress, float x, float theta) {
    float phase = progress * progress + progress + theta;
    float shifty = 0.03 * progress * cos(10.0 * (progress + x));
    return vec2(0.0, shifty);
}

vec4 transition(vec2 p) {
    return mix(texture(from, p + offset(progress, p.x, 0.0)), texture(to, p + offset(1.0 - progress, p.x, 3.14)), progress);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}