// Author: zhmy
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

const vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
const vec2 boundMin = vec2(0.0, 0.0);
const vec2 boundMax = vec2(1.0, 1.0);

bool inBounds(vec2 p) {
    return all(lessThan(boundMin, p)) && all(lessThan(p, boundMax));
}

vec4 transition(vec2 uv) {
    vec2 spfr, spto = vec2(-1.0);
    float size = mix(1.0, 3.0, progress * 0.2);
    spto = (uv + vec2(-0.5, -0.5)) * vec2(size, size) + vec2(0.5, 0.5);
    spfr = (uv + vec2(0.0, 1.0 - progress));
    if (inBounds(spfr)) {
        return texture(to, spfr);
    } else if (inBounds(spto)) {
        return texture(from, spto) * (1.0 - progress);
    } else {
        return black;
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}