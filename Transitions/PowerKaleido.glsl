// Name: Power Kaleido
// Author: Boundless
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float scale; // = 2.0
uniform float z; // = 1.5
uniform float speed; // = 5.0
uniform float ratio; // = 1.0

out vec4 outColor;

#define PI 3.14159265358979
const float rad = 120.0;
const float deg = rad / 180.0 * PI;

vec2 refl(vec2 p, vec2 o, vec2 n) {
    return 2.0 * o + 2.0 * n * dot(p - o, n) - p;
}

vec2 rot(vec2 p, vec2 o, float a) {
    float s = sin(a);
    float c = cos(a);
    return o + mat2(c, -s, s, c) * (p - o);
}

vec4 transition(vec2 uv) {
    vec2 uv0 = uv;
    uv -= 0.5;
    uv.x *= ratio;
    uv *= z;
    uv = rot(uv, vec2(0.0), progress * speed);
    float dist = scale / 10.0;
    float theta = progress * 6.0 + PI / 0.5;
    for (int iter = 0; iter < 10; iter++) {
        for (float i = 0.0; i < 2.0 * PI; i += deg) {
            float ts = sign(asin(cos(i))) == 1.0 ? 1.0 : 0.0;
            if (((ts == 1.0) && (uv.y - dist * cos(i) > tan(i) * (uv.x + dist * sin(i)))) ||
                ((ts == 0.0) && (uv.y - dist * cos(i) < tan(i) * (uv.x + dist * sin(i))))) {
                uv = refl(vec2(uv.x + sin(i) * dist * 2.0, uv.y - cos(i) * dist * 2.0), vec2(0.0, 0.0), vec2(cos(i), sin(i)));
            }
        }
    }
    uv += 0.5;
    uv = rot(uv, vec2(0.5), progress * -speed);
    uv -= 0.5;
    uv.x /= ratio;
    uv += 0.5;
    uv = 2.0 * abs(uv / 2.0 - floor(uv / 2.0 + 0.5));
    vec2 uvMix = mix(uv, uv0, cos(progress * PI * 2.0) / 2.0 + 0.5);
    vec4 color = mix(texture(from, uvMix), texture(to, uvMix), cos((progress - 1.0) * PI) / 2.0 + 0.5);
    return color;
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}