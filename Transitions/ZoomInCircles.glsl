// License: MIT
// Author: dycm8009
// Ported by gre from https://gist.github.com/dycm8009/948e99b1800e81ad909a
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float ratio; // = 1.0

out vec4 outColor;

vec2 zoom(vec2 uv, float amount) {
    return 0.5 + ((uv - 0.5) * amount);
}

vec4 transition(vec2 uv) {
    vec2 ratio2 = vec2(1.0, 1.0 / ratio);
    vec2 r = 2.0 * ((uv - 0.5) * ratio2);
    float pro = progress / 0.8;
    float z = pro * 0.2;
    float t = 0.0;
    if (pro > 1.0) {
        z = 0.2 + (pro - 1.0) * 5.0;
        t = clamp((progress - 0.8) / 0.07, 0.0, 1.0);
    }
    if (length(r) < 0.5 + z) {
        // uv = zoom(uv, 0.9 - 0.1 * pro);
    }
    else if (length(r) < 0.8 + z * 1.5) {
        uv = zoom(uv, 1.0 - 0.15 * pro);
        t = t * 0.5;
    }
    else if (length(r) < 1.2 + z * 2.5) {
        uv = zoom(uv, 1.0 - 0.2 * pro);
        t = t * 0.2;
    }
    else {
        uv = zoom(uv, 1.0 - 0.25 * pro);
    }
    return mix(texture(from, uv), texture(to, uv), t);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}