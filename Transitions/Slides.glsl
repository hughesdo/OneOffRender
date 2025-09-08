// Author: Mark Craig
// mrmcsoftware on github and youtube (http://www.youtube.com/MrMcSoftware)
// License: MIT
// Slides Transition by Mark Craig (Copyright © 2022)
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform int type; // = 0
uniform bool In; // = false

out vec4 outColor;

#define rad2 rad / 2.0

vec4 transition(vec2 uv) {
    vec2 uv0 = uv;
    float rad = In ? progress : 1.0 - progress;
    float xc1, yc1;
    if (type == 0) { xc1 = 0.5 - rad2; yc1 = 0.0; }
    else if (type == 1) { xc1 = 1.0 - rad; yc1 = 0.5 - rad2; }
    else if (type == 2) { xc1 = 0.5 - rad2; yc1 = 1.0 - rad; }
    else if (type == 3) { xc1 = 0.0; yc1 = 0.5 - rad2; }
    else if (type == 4) { xc1 = 1.0 - rad; yc1 = 0.0; }
    else if (type == 5) { xc1 = 1.0 - rad; yc1 = 1.0 - rad; }
    else if (type == 6) { xc1 = 0.0; yc1 = 1.0 - rad; }
    else if (type == 7) { xc1 = 0.0; yc1 = 0.0; }
    else if (type == 8) { xc1 = 0.5 - rad2; yc1 = 0.5 - rad2; }
    uv.y = 1.0 - uv.y;
    vec2 uv2;
    if ((uv.x >= xc1) && (uv.x <= xc1 + rad) && (uv.y >= yc1) && (uv.y <= yc1 + rad)) {
        uv2 = vec2((uv.x - xc1) / rad, 1.0 - (uv.y - yc1) / rad);
        return In ? texture(to, uv2) : texture(from, uv2);
    }
    return In ? texture(from, uv0) : texture(to, uv0);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}