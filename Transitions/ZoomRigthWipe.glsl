// Author: Handk
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float zoom_quickness; // = 0.8

out vec4 outColor;

float nQuick = clamp(zoom_quickness, 0.0, 0.5);

vec2 zoom(vec2 uv, float amount) {
    if (amount < 0.5)
        return 0.5 + ((uv - 0.5) * (1.0 - amount));
    else
        return 0.5 + ((uv - 0.5) * amount);
}

vec4 transition(vec2 uv) {
    if (progress < 0.5) {
        vec4 c = mix(
            texture(from, zoom(uv, smoothstep(0.0, nQuick, progress))),
            texture(to, uv),
            step(0.5, progress)
        );
        return c;
    }
    else {
        vec2 p = uv.xy / vec2(1.0).xy;
        vec4 d = texture(from, p);
        vec4 e = texture(to, p);
        vec4 f = mix(d, e, step(0.0 + p.x, (progress - 0.5) * 2.0));
        return f;
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}