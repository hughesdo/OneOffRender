#version 330
uniform sampler2D from;
uniform sampler2D to;
uniform float progress;
in vec2 v_text;
out vec4 fragColor;

// Author: Fernando Kuteken
// License: MIT

#define PI 3.141592653589

uniform float startingAngle; // = 90;

vec4 getFromColor(vec2 uv) {
    return texture(from, uv);
}

vec4 getToColor(vec2 uv) {
    return texture(to, uv);
}

vec4 transition(vec2 uv) {
    float offset = startingAngle * PI / 180.0;
    float angle = atan(uv.y - 0.5, uv.x - 0.5) + offset;
    float normalizedAngle = (angle + PI) / (2.0 * PI);
    normalizedAngle = normalizedAngle - floor(normalizedAngle);

    return mix(
        getFromColor(uv),
        getToColor(uv),
        step(normalizedAngle, progress)
    );
}

void main() {
    fragColor = transition(v_text);
}
