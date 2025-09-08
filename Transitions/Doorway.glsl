// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float reflection; // = 0.4
uniform float perspective; // = 0.4
uniform float depth; // = 3.0

out vec4 outColor;

const vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
const vec2 boundMin = vec2(0.0, 0.0);
const vec2 boundMax = vec2(1.0, 1.0);

bool inBounds(vec2 p) {
    return all(lessThan(boundMin, p)) && all(lessThan(p, boundMax));
}

vec2 project(vec2 p) {
    return p * vec2(1.0, -1.2) + vec2(0.0, -0.02);
}

vec4 bgColor(vec2 p, vec2 pto) {
    vec4 c = black;
    pto = project(pto);
    if (inBounds(pto)) {
        c += mix(black, texture(to, pto), reflection * mix(1.0, 0.0, pto.y));
    }
    return c;
}

vec4 transition(vec2 p) {
    vec2 pfr = vec2(-1.0), pto = vec2(-1.0);
    float middleSlit = 2.0 * abs(p.x - 0.5) - progress;
    if (middleSlit > 0.0) {
        pfr = p + (p.x > 0.5 ? -1.0 : 1.0) * vec2(0.5 * progress, 0.0);
        float d = 1.0 / (1.0 + perspective * progress * (1.0 - middleSlit));
        pfr.y -= d / 2.0;
        pfr.y *= d;
        pfr.y += d / 2.0;
    }
    float size = mix(1.0, depth, 1.0 - progress);
    pto = (p + vec2(-0.5, -0.5)) * vec2(size, size) + vec2(0.5, 0.5);
    if (inBounds(pfr)) {
        return texture(from, pfr);
    }
    else if (inBounds(pto)) {
        return texture(to, pto);
    }
    else {
        return bgColor(p, pto);
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}