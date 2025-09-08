// Author: Thibaut Foussard
// Based on Directional transition by Gaëtan Renaudeau
// https://gl-transitions.com/editor/Directional
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform vec2 direction; // = vec2(0.0, 1.0)
uniform float scale; // = 0.7

out vec4 outColor;

#define PI acos(-1.0)

float parabola(float x) {
    float y = pow(sin(x * PI), 1.0);
    return y;
}

vec4 transition(vec2 uv) {
    float easedProgress = pow(sin(progress * PI / 2.0), 3.0);
    vec2 p = uv + easedProgress * sign(direction);
    vec2 f = fract(p);
    
    float s = 1.0 - (1.0 - (1.0 / scale)) * parabola(progress);
    f = (f - 0.5) * s + 0.5;
    
    float mixer = step(0.0, p.y) * step(p.y, 1.0) * step(0.0, p.x) * step(p.x, 1.0);
    vec4 col = mix(texture(to, f), texture(from, f), mixer);
    
    float border = step(0.0, f.x) * step(0.0, (1.0 - f.x)) * step(0.0, f.y) * step(0.0, 1.0 - f.y);
    col *= border;
    
    return col;
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}