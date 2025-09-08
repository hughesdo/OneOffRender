// Author: 0gust1
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform bool direction; // = true
uniform float l_threshold; // = 0.8
uniform bool above; // = false

out vec4 outColor;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x * 34.0) + 1.0) * x);
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
    m = m * m;
    m = m * m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float luminance(vec4 color) {
    return color.r * 0.299 + color.g * 0.587 + color.b * 0.114;
}

vec4 transition(vec2 uv) {
    vec2 p = uv.xy / vec2(1.0).xy;
    if (progress == 0.0) {
        return texture(from, p);
    } else if (progress == 1.0) {
        return texture(to, p);
    } else {
        float x = progress;
        vec2 center = vec2(1.0, direction ? 1.0 : 0.0);
        float dist = distance(center, p) - progress * exp(snoise(vec2(p.x, 0.0)));
        float r = x - rand(vec2(p.x, 0.1));
        float m;
        if (above) {
            m = dist <= r && luminance(texture(from, p)) > l_threshold ? 1.0 : (progress * progress * progress);
        } else {
            m = dist <= r && luminance(texture(from, p)) < l_threshold ? 1.0 : (progress * progress * progress);
        }
        return mix(texture(from, p), texture(to, p), m);
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}