// Author: Mark Craig
// mrmcsoftware on github and youtube (http://www.youtube.com/MrMcSoftware)
// License: MIT
// Rolls Transition by Mark Craig (Copyright © 2022)
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform int type; // = 0
uniform bool RotDown; // = false
uniform float ratio; // = 1.0

out vec4 outColor;

#define M_PI 3.14159265358979323846

vec4 transition(vec2 uv) {
    float theta;
    vec2 iResolution = vec2(ratio, 1.0);
    vec2 uvi;
    if (type == 0) { theta = (RotDown ? M_PI : -M_PI) / 2.0 * progress; uvi.x = 1.0 - uv.x; uvi.y = uv.y; }
    else if (type == 1) { theta = (RotDown ? M_PI : -M_PI) / 2.0 * progress; uvi = uv; }
    else if (type == 2) { theta = (RotDown ? -M_PI : M_PI) / 2.0 * progress; uvi.x = uv.x; uvi.y = 1.0 - uv.y; }
    else if (type == 3) { theta = (RotDown ? -M_PI : M_PI) / 2.0 * progress; uvi = 1.0 - uv; }
    float c1 = cos(theta);
    float s1 = sin(theta);
    vec2 uv2;
    uv2.x = (uvi.x * iResolution.x * c1 - uvi.y * iResolution.y * s1);
    uv2.y = (uvi.x * iResolution.x * s1 + uvi.y * iResolution.y * c1);
    if ((uv2.x >= 0.0) && (uv2.x <= iResolution.x) && (uv2.y >= 0.0) && (uv2.y <= iResolution.y)) {
        uv2 /= iResolution;
        if (type == 0) { uv2.x = 1.0 - uv2.x; }
        else if (type == 2) { uv2.y = 1.0 - uv2.y; }
        else if (type == 3) { uv2 = 1.0 - uv2; }
        return texture(from, uv2);
    }
    return texture(to, uv);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}