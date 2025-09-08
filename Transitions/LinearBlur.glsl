// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float intensity; // = 0.1

out vec4 outColor;

const int passes = 6;

vec4 transition(vec2 uv) {
    vec4 c1 = vec4(0.0);
    vec4 c2 = vec4(0.0);
    float disp = intensity * (0.5 - distance(0.5, progress));
    for (int xi = 0; xi < passes; xi++) {
        float x = float(xi) / float(passes) - 0.5;
        for (int yi = 0; yi < passes; yi++) {
            float y = float(yi) / float(passes) - 0.5;
            vec2 v = vec2(x, y);
            float d = disp;
            c1 += texture(from, uv + d * v);
            c2 += texture(to, uv + d * v);
        }
    }
    c1 /= float(passes * passes);
    c2 /= float(passes * passes);
    return mix(c1, c2, progress);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}