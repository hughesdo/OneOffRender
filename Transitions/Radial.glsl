// License: MIT
// Author: Xaychru
// Ported by gre from https://gist.github.com/Xaychru/ce1d48f0ce00bb379750
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float smoothness; // = 1.0

out vec4 outColor;

const float PI = 3.141592653589;

vec4 transition(vec2 p) {
    vec2 rp = p * 2.0 - 1.0;
    return mix(
        texture(to, p),
        texture(from, p),
        smoothstep(0.0, smoothness, atan(rp.y, rp.x) - (progress - 0.5) * PI * 2.5)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}