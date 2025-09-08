// Author: mandubian
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float amplitude; // = 1.0
uniform float waves; // = 30.0
uniform float colorSeparation; // = 0.3

out vec4 outColor;

float PI = 3.14159265358979323846264;

float compute(vec2 p, float prog, vec2 center) {
    vec2 o = p * sin(prog * amplitude) - center;
    // horizontal vector
    vec2 h = vec2(1.0, 0.0);
    // butterfly polar function
    float theta = acos(dot(o, h)) * waves;
    return (exp(cos(theta)) - 2.0 * cos(4.0 * theta) + pow(sin((2.0 * theta - PI) / 24.0), 5.0)) / 10.0;
}

vec4 transition(vec2 uv) {
    vec2 p = uv;
    float inv = 1.0 - progress;
    vec2 dir = p - vec2(0.5);
    float dist = length(dir);
    float disp = compute(p, progress, vec2(0.5, 0.5));
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