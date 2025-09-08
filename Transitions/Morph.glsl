// Author: paniq
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float strength; // = 0.1

out vec4 outColor;

vec4 transition(vec2 p) {
    vec4 ca = texture(from, p);
    vec4 cb = texture(to, p);
    vec2 oa = (((ca.rg + ca.b) * 0.5) * 2.0 - 1.0);
    vec2 ob = (((cb.rg + cb.b) * 0.5) * 2.0 - 1.0);
    vec2 oc = mix(oa, ob, 0.5) * strength;
    float w0 = progress;
    float w1 = 1.0 - w0;
    return mix(texture(from, p + oc * w0), texture(to, p - oc * w1), progress);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}