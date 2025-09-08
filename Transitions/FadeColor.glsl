// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform vec3 color; // = vec3(0.0)
uniform float colorPhase; // = 0.4

out vec4 outColor;

vec4 transition(vec2 uv) {
    return mix(
        mix(vec4(color, 1.0), texture(from, uv), smoothstep(1.0 - colorPhase, 0.0, progress)),
        mix(vec4(color, 1.0), texture(to, uv), smoothstep(colorPhase, 1.0, progress)),
        progress
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}