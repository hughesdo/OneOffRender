// Author: Mr Speaker
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float speed; // = 2.0

out vec4 outColor;

vec4 transition(vec2 uv) {
    vec2 p = uv.xy / vec2(1.0).xy;
    float circPos = atan(p.y - 0.5, p.x - 0.5) + progress * speed;
    float modPos = mod(circPos, 3.1415 / 4.0);
    float signed = sign(progress - modPos);
    return mix(texture(to, p), texture(from, p), step(signed, 0.5));
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}