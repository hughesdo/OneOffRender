// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform vec4 fromStep; // = vec4(0.0, 0.2, 0.4, 0.0)
uniform vec4 toStep; // = vec4(0.6, 0.8, 1.0, 1.0)

out vec4 outColor;

vec4 transition(vec2 uv) {
    vec4 a = texture(from, uv);
    vec4 b = texture(to, uv);
    return mix(a, b, smoothstep(fromStep, toStep, vec4(progress)));
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}