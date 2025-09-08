// License: MIT
// Author: Sergey Kosarevsky
// Ported by gre from https://gist.github.com/corporateshark/cacfedb8cca0f5ce3f7c
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

vec4 transition(vec2 UV) {
    float Radius = 1.0;
    float T = progress;
    UV -= vec2(0.5, 0.5);
    float Dist = length(UV);
    if (Dist < Radius) {
        float Percent = (Radius - Dist) / Radius;
        float A = (T <= 0.5) ? mix(0.0, 1.0, T / 0.5) : mix(1.0, 0.0, (T - 0.5) / 0.5);
        float Theta = Percent * Percent * A * 8.0 * 3.14159;
        float S = sin(Theta);
        float C = cos(Theta);
        UV = vec2(dot(UV, vec2(C, -S)), dot(UV, vec2(S, C)));
    }
    UV += vec2(0.5, 0.5);
    vec4 C0 = texture(from, UV);
    vec4 C1 = texture(to, UV);
    return mix(C0, C1, T);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}