// Author: Mark Craig
// mrmcsoftware on github and youtube (http://www.youtube.com/MrMcSoftware)
// License: MIT
// RotateScaleVanish Transition by Mark Craig (Copyright © 2022)
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform bool FadeInSecond; // = true
uniform bool ReverseEffect; // = false
uniform bool ReverseRotation; // = false
uniform float ratio; // = 1.0

out vec4 outColor;

#define M_PI 3.14159265358979323846
#define _TWOPI 6.283185307179586476925286766559

vec4 transition(vec2 uv) {
    vec2 iResolution = vec2(ratio, 1.0);
    float t = ReverseEffect ? 1.0 - progress : progress;
    float theta = ReverseRotation ? _TWOPI * t : -_TWOPI * t;
    float c1 = cos(theta);
    float s1 = sin(theta);
    float rad = max(0.00001, 1.0 - t);
    float xc1 = (uv.x - 0.5) * iResolution.x;
    float yc1 = (uv.y - 0.5) * iResolution.y;
    float xc2 = (xc1 * c1 - yc1 * s1) / rad;
    float yc2 = (xc1 * s1 + yc1 * c1) / rad;
    vec2 uv2 = vec2(xc2 + iResolution.x / 2.0, yc2 + iResolution.y / 2.0);
    vec4 col3;
    vec4 ColorTo = ReverseEffect ? texture(from, uv) : texture(to, uv);
    if ((uv2.x >= 0.0) && (uv2.x <= iResolution.x) && (uv2.y >= 0.0) && (uv2.y <= iResolution.y)) {
        uv2 /= iResolution;
        col3 = ReverseEffect ? texture(to, uv2) : texture(from, uv2);
    } else {
        col3 = FadeInSecond ? vec4(0.0, 0.0, 0.0, 1.0) : ColorTo;
    }
    return mix(col3, ColorTo, t);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}