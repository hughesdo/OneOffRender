// Author: Ben Zhang
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float strength; // = 0.6

out vec4 outColor;

const float PI = 3.141592653589793;

vec4 transition(vec2 uv) {
    vec4 from = texture(from, uv);
    vec4 to = texture(to, uv);
    float from_m = 1.0 - progress + sin(PI * progress) * strength;
    float to_m = progress + sin(PI * progress) * strength;
    return vec4(
        from.r * from.a * from_m + to.r * to.a * to_m,
        from.g * from.a * from_m + to.g * to.a * to_m,
        from.b * from.a * from_m + to.b * to.a * to_m,
        mix(from.a, to.a, progress)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}