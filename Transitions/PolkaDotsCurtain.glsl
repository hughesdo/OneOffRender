// Author: bobylito
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float dots; // = 20.0
uniform vec2 center; // = vec2(0.0, 0.0)

out vec4 outColor;

const float SQRT_2 = 1.414213562373;

vec4 transition(vec2 uv) {
    bool nextImage = distance(fract(uv * dots), vec2(0.5, 0.5)) < (progress / distance(uv, center));
    return nextImage ? texture(to, uv) : texture(from, uv);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}