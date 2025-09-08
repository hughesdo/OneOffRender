// Author: Rich Harris
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float scale; // = 4.0
uniform float smoothness; // = 0.01
uniform float seed; // = 12.9898

out vec4 outColor;

float random(vec2 co) {
    float a = seed;
    float b = 78.233;
    float c = 43758.5453;
    float dt = dot(co.xy, vec2(a, b));
    float sn = mod(dt, 3.14);
    return fract(sin(sn) * c);
}

float noise(in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

vec4 transition(vec2 uv) {
    vec4 from = texture(from, uv);
    vec4 to = texture(to, uv);
    float n = noise(uv * scale);
    float p = mix(-smoothness, 1.0 + smoothness, progress);
    float lower = p - smoothness;
    float higher = p + smoothness;
    float q = smoothstep(lower, higher, n);
    return mix(from, to, 1.0 - q);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}