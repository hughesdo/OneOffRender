// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float intensity; // = 0.3

out vec4 outColor;

vec3 grayscale(vec3 color) {
    return vec3(0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b);
}

vec4 transition(vec2 uv) {
    vec4 fc = texture(from, uv);
    vec4 tc = texture(to, uv);
    return mix(
        mix(vec4(grayscale(fc.rgb), 1.0), fc, smoothstep(1.0 - intensity, 0.0, progress)),
        mix(vec4(grayscale(tc.rgb), 1.0), tc, smoothstep(intensity, 1.0, progress)),
        progress
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}