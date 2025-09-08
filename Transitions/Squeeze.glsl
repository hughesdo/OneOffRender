// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float colorSeparation; // = 0.04

out vec4 outColor;

vec4 transition(vec2 uv) {
    float y = 0.5 + (uv.y - 0.5) / (1.0 - progress);
    if (y < 0.0 || y > 1.0) {
        return texture(to, uv);
    } else {
        vec2 fp = vec2(uv.x, y);
        vec2 off = progress * vec2(0.0, colorSeparation);
        vec4 c = texture(from, fp);
        vec4 cn = texture(from, fp - off);
        vec4 cp = texture(from, fp + off);
        return vec4(cn.r, c.g, cp.b, c.a);
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}