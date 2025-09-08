// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float size; // = 0.04
uniform float zoom; // = 50.0
uniform float colorSeparation; // = 0.3

out vec4 outColor;

vec4 transition(vec2 p) {
    float inv = 1.0 - progress;
    vec2 disp = size * vec2(cos(zoom * p.x), sin(zoom * p.y));
    vec4 texTo = texture(to, p + inv * disp);
    vec4 texFrom = vec4(
        texture(from, p + progress * disp * (1.0 - colorSeparation)).r,
        texture(from, p + progress * disp).g,
        texture(from, p + progress * disp * (1.0 + colorSeparation)).b,
        1.0
    );
    return texTo * progress + texFrom * inv;
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}