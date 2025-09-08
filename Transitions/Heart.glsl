// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

float inHeart(vec2 p, vec2 center, float size) {
    if (size == 0.0) return 0.0;
    vec2 o = (p - center) / (1.6 * size);
    float a = o.x * o.x + o.y * o.y - 0.3;
    return step(a * a * a, o.x * o.x * o.y * o.y * o.y);
}

vec4 transition(vec2 uv) {
    return mix(
        texture(from, uv),
        texture(to, uv),
        inHeart(uv, vec2(0.5, 0.4), progress)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}