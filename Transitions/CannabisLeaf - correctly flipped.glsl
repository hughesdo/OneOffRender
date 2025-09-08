// Author: @Flexi23
// License: MIT
// Inspired by http://www.wolframalpha.com/input/?i=cannabis+curve
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float r; // = 0.5, leaf radius

out vec4 outColor;

vec4 transition(vec2 uv) {
    if (progress == 0.0) {
        return texture(from, uv);
    }
    
    vec2 leaf_uv = (uv - vec2(0.5)) / 10.0 / pow(progress, 3.5);
    leaf_uv.y = -leaf_uv.y - 0.35;
    float leaf_r = 0.18 * r;
    float o = atan(leaf_uv.y, leaf_uv.x);
    
    float leaf_shape = 1.0 - length(leaf_uv) + leaf_r * (1.0 + sin(o)) * (1.0 + 0.9 * cos(8.0 * o)) * (1.0 + 0.1 * cos(24.0 * o)) * (0.9 + 0.05 * cos(200.0 * o));
    float mask = 1.0 - step(leaf_shape, 1.0);
    
    return mix(texture(from, uv), texture(to, uv), mask);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}