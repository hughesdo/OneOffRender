// Author: 0gust1
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float zoom_quickness; // = 0.8

out vec4 outColor;

float nQuick = clamp(zoom_quickness, 0.2, 1.0);

vec2 zoom(vec2 uv, float amount) {
    return 0.5 + ((uv - 0.5) * (1.0 - amount));
}

vec4 transition(vec2 uv) {
    return mix(
        texture(from, zoom(uv, smoothstep(0.0, nQuick, progress))),
        texture(to, uv),
        smoothstep(nQuick - 0.2, 1.0, progress)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}