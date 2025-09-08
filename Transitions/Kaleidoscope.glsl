// Author: nwoeanhinnogaehr
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float speed; // = 1.0
uniform float angle; // = 1.0
uniform float power; // = 1.5

out vec4 outColor;

vec4 transition(vec2 uv) {
    vec2 p = uv.xy / vec2(1.0).xy;
    vec2 q = p;
    float t = pow(progress, power) * speed;
    p = p - 0.5;
    for (int i = 0; i < 7; i++) {
        p = vec2(sin(t) * p.x + cos(t) * p.y, sin(t) * p.y - cos(t) * p.x);
        t += angle;
        p = abs(mod(p, 2.0) - 1.0);
    }
    abs(mod(p, 1.0));
    return mix(
        mix(texture(from, q), texture(to, q), progress),
        mix(texture(from, p), texture(to, p), progress),
        1.0 - 2.0 * abs(progress - 0.5)
    );
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}