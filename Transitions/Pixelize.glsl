// Author: gre
// License: MIT
// Forked from https://gist.github.com/benraziel/c528607361d90a072e98
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform ivec2 squaresMin; // = ivec2(20)
uniform int steps; // = 50

out vec4 outColor;

vec4 transition(vec2 uv) {
    float d = min(progress, 1.0 - progress);
    float dist = steps > 0 ? ceil(d * float(steps)) / float(steps) : d;
    vec2 squareSize = 2.0 * dist / vec2(squaresMin);
    vec2 p = dist > 0.0 ? (floor(uv / squareSize) + 0.5) * squareSize : uv;
    return mix(texture(from, p), texture(to, p), progress);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}