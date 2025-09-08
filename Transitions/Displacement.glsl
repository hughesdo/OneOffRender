// Author: Travis Fischer
// License: MIT
// Adapted from a Codrops article by Robin Delaporte
// https://tympanus.net/Development/DistortionHoverEffect
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform sampler2D displacementMap;
uniform float strength; // = 0.5

out vec4 outColor;

vec4 transition(vec2 uv) {
    float displacement = texture(displacementMap, uv).r * strength;
    vec2 uvFrom = vec2(uv.x + progress * displacement, uv.y);
    vec2 uvTo = vec2(uv.x - (1.0 - progress) * displacement, uv.y);
    return mix(
        texture(from, uvFrom),
        texture(to, uvTo),
        progress
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}