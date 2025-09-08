// License: MIT
// Author: pthrasher
// Adapted by gre from https://gist.github.com/pthrasher/04fd9a7de4012cbb03f6
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform vec2 center; // = vec2(0.5)
uniform float threshold; // = 3.0
uniform float fadeEdge; // = 0.1

out vec4 outColor;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 transition(vec2 p) {
    float dist = distance(center, p) / threshold;
    float r = progress - min(rand(vec2(p.y, 0.0)), rand(vec2(0.0, p.x)));
    return mix(texture(from, p), texture(to, p), mix(0.0, mix(step(dist, r), 1.0, smoothstep(1.0 - fadeEdge, 1.0, progress)), smoothstep(0.0, fadeEdge, progress)));
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}