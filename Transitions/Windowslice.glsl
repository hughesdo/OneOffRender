// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float count; // = 10.0
uniform float smoothness; // = 0.5

out vec4 outColor;

vec4 transition(vec2 p) {
    float pr = smoothstep(-smoothness, 0.0, p.x - progress * (1.0 + smoothness));
    float s = step(pr, fract(count * p.x));
    return mix(texture(from, p), texture(to, p), s);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}