// Author: Paweł Płóciennik
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float amplitude; // = 30.0
uniform float speed; // = 30.0

out vec4 outColor;

vec4 transition(vec2 p) {
    vec2 dir = p - vec2(0.5);
    float dist = length(dir);
    if (dist > progress) {
        return mix(texture(from, p), texture(to, p), progress);
    } else {
        vec2 offset = dir * sin(dist * amplitude - progress * speed);
        return mix(texture(from, p + offset), texture(to, p), progress);
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}