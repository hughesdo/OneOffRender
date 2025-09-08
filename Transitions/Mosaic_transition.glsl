// Author: YueDev
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float mosaicNum; // = 10.0

out vec4 outColor;

vec2 getMosaicUV(vec2 uv) {
    float mosaicWidth = 2.0 / mosaicNum * min(progress, 1.0 - progress);
    float mX = floor(uv.x / mosaicWidth) + 0.5;
    float mY = floor(uv.y / mosaicWidth) + 0.5;
    return vec2(mX * mosaicWidth, mY * mosaicWidth);
}

vec4 transition(vec2 uv) {
    vec2 mosaicUV = min(progress, 1.0 - progress) == 0.0 ? uv : getMosaicUV(uv);
    return mix(texture(from, mosaicUV), texture(to, mosaicUV), progress * progress);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}