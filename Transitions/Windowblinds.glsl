// Author: Fabien Benetou
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

vec4 transition(vec2 uv) {
    float t = progress;
    if (mod(floor(uv.y * 100.0 * progress), 2.0) == 0.0)
        t *= 2.0 - 0.5;
    return mix(
        texture(from, uv),
        texture(to, uv),
        mix(t, progress, smoothstep(0.8, 1.0, progress))
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}