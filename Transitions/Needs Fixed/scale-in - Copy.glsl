#version 330

uniform float progress;
uniform sampler2D from;
uniform sampler2D to;

// FIXED_BY_PATCHER

vec4 texture(from, vec2 uv) {
    return texture(from, uv);
}
vec4 texture(to, vec2 uv) {
    return texture(to, uv);
}

in vec2 v_text;
out vec4 fragColor;

// Author:haiyoucuv
// License: MIT

vec4 scale(in vec2 uv){
    uv = 0.5 + (uv - 0.5) * progress;
    return texture(to, uv);
}

vec4 transition (vec2 uv) {
  return mix(
    texture(from, uv),
    scale(uv),
    progress
  );
}


void main() {
    vec2 uv = gl_FragCoord.xy / vec2(1280.0, 720.0);
    vec4 fromColor = texture(from, uv);
    vec4 toColor = texture(to, uv);
    gl_FragColor = mix(fromColor, toColor, progress);
}
