// License: MIT
// Author: P-Seebauer
// Ported by gre from https://gist.github.com/P-Seebauer/2a5fa2f77c883dd661f9
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float power; // = 5.0

out vec4 outColor;

vec4 transition(vec2 p) {
    vec4 fTex = texture(from, p);
    vec4 tTex = texture(to, p);
    float m = step(distance(fTex, tTex), progress);
    return mix(
        mix(fTex, tTex, m),
        tTex,
        pow(progress, power)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}