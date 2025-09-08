// Author: Fernando Kuteken
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform vec2 center; // = vec2(0.5, 0.5)
uniform vec3 backColor; // = vec3(0.1, 0.1, 0.1)

out vec4 outColor;

vec4 transition(vec2 uv) {
    float distance = length(uv - center);
    float radius = sqrt(8.0) * abs(progress - 0.5);
    
    if (distance > radius) {
        return vec4(backColor, 1.0);
    } else {
        if (progress < 0.5) return texture(from, uv);
        else return texture(to, uv);
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}