// Author: Brandon Anzaldi
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float offset; // = 0.05

out vec4 outColor;

highp float noise(vec2 co) {
    highp float a = 12.9898;
    highp float b = 78.233;
    highp float c = 43758.5453;
    highp float dt = dot(co.xy * progress, vec2(a, b));
    highp float sn = mod(dt, 3.14);
    return fract(sin(sn) * c);
}

vec4 transition(vec2 p) {
    if (progress < offset) {
        return texture(from, p);
    } else if (progress > (1.0 - offset)) {
        return texture(to, p);
    } else {
        return vec4(vec3(noise(p)), 1.0);
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}