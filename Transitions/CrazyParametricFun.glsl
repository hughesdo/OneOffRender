// Author: mandubian
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float a; // = 4.0
uniform float b; // = 1.0
uniform float amplitude; // = 120.0
uniform float smoothness; // = 0.1

out vec4 outColor;

vec4 transition(vec2 uv) {
    vec2 p = uv.xy / vec2(1.0).xy;
    vec2 dir = p - vec2(0.5);
    float dist = length(dir);
    float x = (a - b) * cos(progress) + b * cos(progress * ((a / b) - 1.0));
    float y = (a - b) * sin(progress) - b * sin(progress * ((a / b) - 1.0));
    vec2 offset = dir * vec2(sin(progress * dist * amplitude * x), sin(progress * dist * amplitude * y)) / smoothness;
    return mix(texture(from, p + offset), texture(to, p), smoothstep(0.2, 1.0, progress));
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}