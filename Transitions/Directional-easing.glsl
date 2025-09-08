// Author: Max Plotnikov
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform vec2 direction; // = vec2(0.0, 1.0)

out vec4 outColor;

vec4 transition(vec2 uv) {
    float easing = sqrt((2.0 - progress) * progress);
    vec2 p = uv + easing * sign(direction);
    vec2 f = fract(p);
    return mix(
        texture(to, f),
        texture(from, f),
        step(0.0, p.y) * step(p.y, 1.0) * step(0.0, p.x) * step(p.x, 1.0)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}