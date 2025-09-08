// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform ivec2 squares; // = ivec2(10, 10)
uniform vec2 direction; // = vec2(1.0, -0.5)
uniform float smoothness; // = 1.6

out vec4 outColor;

const vec2 center = vec2(0.5, 0.5);

vec4 transition(vec2 p) {
    vec2 v = normalize(direction);
    v /= abs(v.x) + abs(v.y);
    float d = v.x * center.x + v.y * center.y;
    float offset = smoothness;
    float pr = smoothstep(-offset, 0.0, v.x * p.x + v.y * p.y - (d - 0.5 + progress * (1.0 + offset)));
    vec2 squarep = fract(p * vec2(squares));
    vec2 squaremin = vec2(pr / 2.0);
    vec2 squaremax = vec2(1.0 - pr / 2.0);
    float a = (1.0 - step(progress, 0.0)) * step(squaremin.x, squarep.x) * step(squaremin.y, squarep.y) * step(squarep.x, squaremax.x) * step(squarep.y, squaremax.y);
    return mix(texture(from, p), texture(to, p), a);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}