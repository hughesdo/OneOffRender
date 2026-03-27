#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Plasma outline
// Created by diatribes
// Shadertoy ID: lXKyRy
// https://www.shadertoy.com/view/lXKyRy

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float t = iTime / 2.0;
    vec2 uv = u / iResolution.xy - .5;
    uv.x *= iResolution.x/iResolution.y;
    uv *= 35.0;
    float r = distance(uv, vec2(sin(t), sin(1.0/t)*.1));
    float g = distance(uv, vec2(0, r)); 
    float b = distance(uv, vec2(r, sin(t)));
    float value = abs(sin(r+t) + sin(g+t) + sin(b+t) + sin(uv.x+t) + cos(uv.y+t));
    value *= (sin(t)*.5+.5)*100.0+10.0;
    r /= value;
    g /= value;
    b /= value;
    o = vec4 (r, g, b, 1.0);
    fragColor = o;
}

