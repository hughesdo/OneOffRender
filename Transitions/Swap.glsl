// Author: gre
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float reflection; // = 0.4
uniform float perspective; // = 0.2
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

vec4 bgColor(vec2 p, vec2 pfr, vec2 pto) {
    vec4 c = black;
    pfr = project(pfr);
    if (inBounds(pfr)) {
        c += mix(black, texture(from, pfr), reflection * mix(1.0, 0.0, pfr.y));
    }
    pto = project(pto);
    if (inBounds(pto)) {
        c += mix(black, texture(to, pto), reflection * mix(1.0, 0.0, pto.y));
    }
    return c;
}

vec4 transition(vec2 p) {
    vec2 pfr, pto = vec2(-1.0);
    float size = mix(1.0, depth, progress);
    float persp = perspective * progress;
    pfr = (p + vec2(-0.0, -0.5)) * vec2(size / (1.0 - perspective * progress), size / (1.0 - size * persp * p.x)) + vec2(0.0, 0.5);
    size = mix(1.0, depth, 1.0 - progress);
    persp = perspective * (1.0 - progress);
    pto = (p + vec2(-1.0, -0.5)) * vec2(size / (1.0 - perspective * (1.0 - progress)), size / (1.0 - size * persp * (0.5 - p.x))) + vec2(1.0, 0.5);
    if (progress < 0.5) {
        if (inBounds(pfr)) {
            return texture(from, pfr);
        }
        if (inBounds(pto)) {
            return texture(to, pto);
        }
    }
    if (inBounds(pto)) {
        return texture(to, pto);
    }
    if (inBounds(pfr)) {
        return texture(from, pfr);
    }
    return bgColor(p, pfr, pto);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}