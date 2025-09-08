// License: MIT
// Author: fkuteken
// Ported by gre from https://gist.github.com/fkuteken/f63e3009c1143950dee9063c3b83fb88
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform vec4 bgcolor; // = vec4(0.0, 0.0, 0.0, 1.0)
uniform float ratio; // = 1.0, aspect ratio

out vec4 outColor;

vec4 transition(vec2 p) {
    vec2 ratio2 = vec2(1.0, 1.0 / ratio);
    float s = pow(2.0 * abs(progress - 0.5), 3.0);
    float dist = length((vec2(p) - 0.5) * ratio2);
    return mix(
        progress < 0.5 ? texture(from, p) : texture(to, p),
        bgcolor,
        step(s, dist)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}