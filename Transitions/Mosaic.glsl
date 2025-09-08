// License: MIT
// Author: Xaychru
// Ported by gre from https://gist.github.com/Xaychru/130bb7b7affedbda9df5
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform int endx; // = 2
uniform int endy; // = -1

out vec4 outColor;

#define PI 3.14159265358979323
#define POW2(X) X*X
#define POW3(X) X*X*X

float Rand(vec2 v) {
    return fract(sin(dot(v.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 Rotate(vec2 v, float a) {
    mat2 rm = mat2(cos(a), -sin(a), sin(a), cos(a));
    return rm * v;
}

float CosInterpolation(float x) {
    return -cos(x * PI) / 2.0 + 0.5;
}

vec4 transition(vec2 uv) {
    vec2 p = uv.xy / vec2(1.0).xy - 0.5;
    vec2 rp = p;
    float rpr = (progress * 2.0 - 1.0);
    float z = -(rpr * rpr * 2.0) + 3.0;
    float az = abs(z);
    rp *= az;
    rp += mix(vec2(0.5, 0.5), vec2(float(endx) + 0.5, float(endy) + 0.5), POW2(CosInterpolation(progress)));
    vec2 mrp = mod(rp, 1.0);
    vec2 crp = rp;
    bool onEnd = int(floor(crp.x)) == endx && int(floor(crp.y)) == endy;
    if (!onEnd) {
        float ang = float(int(Rand(floor(crp)) * 4.0)) * 0.5 * PI;
        mrp = vec2(0.5) + Rotate(mrp - vec2(0.5), ang);
    }
    if (onEnd || Rand(floor(crp)) > 0.5) {
        return texture(to, mrp);
    } else {
        return texture(from, mrp);
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}