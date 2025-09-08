// Author: Woohyun Kim
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float edge_thickness; // = 0.001
uniform float edge_brightness; // = 8.0

out vec4 outColor;

vec4 detectEdgeColor(vec3[9] c) {
    vec3 dx = 2.0 * abs(c[7] - c[1]) + abs(c[2] - c[6]) + abs(c[8] - c[0]);
    vec3 dy = 2.0 * abs(c[3] - c[5]) + abs(c[6] - c[8]) + abs(c[0] - c[2]);
    float delta = length(0.25 * (dx + dy) * 0.5);
    return vec4(clamp(edge_brightness * delta, 0.0, 1.0) * c[4], 1.0);
}

vec4 getFromEdgeColor(vec2 uv) {
    vec3 c[9];
    for (int i = 0; i < 3; ++i) for (int j = 0; j < 3; ++j) {
        vec4 color = texture(from, uv + edge_thickness * vec2(i - 1, j - 1));
        c[3 * i + j] = color.rgb;
    }
    return detectEdgeColor(c);
}

vec4 getToEdgeColor(vec2 uv) {
    vec3 c[9];
    for (int i = 0; i < 3; ++i) for (int j = 0; j < 3; ++j) {
        vec4 color = texture(to, uv + edge_thickness * vec2(i - 1, j - 1));
        c[3 * i + j] = color.rgb;
    }
    return detectEdgeColor(c);
}

vec4 transition(vec2 uv) {
    vec4 start = mix(texture(from, uv), getFromEdgeColor(uv), clamp(2.0 * progress, 0.0, 1.0));
    vec4 end = mix(getToEdgeColor(uv), texture(to, uv), clamp(2.0 * (progress - 0.5), 0.0, 1.0));
    return mix(start, end, progress);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}