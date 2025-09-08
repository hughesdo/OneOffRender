#version 330
uniform sampler2D from;
uniform sampler2D to;
uniform float progress;
in vec2 v_text;
out vec4 fragColor;

void main() {
    vec4 colorFrom = texture(from, v_text);
    vec4 colorTo = texture(to, v_text);
    fragColor = mix(colorFrom, colorTo, progress);
}
