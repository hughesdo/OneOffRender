#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// iso color
// Created by diatribes
// Shadertoy ID: lXVcDR
// https://www.shadertoy.com/view/lXVcDR

const mat2 isometricMat = mat2(vec2(-0.5, 0.5), vec2(1.0));
vec2 CartesianToIsometric(in vec2 cartesian) {
    return isometricMat * cartesian;
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    vec2 uv = u/iResolution.xy-.5;
    float t = iTime / 8.0;
    uv *= 8.0;
    uv.x *= iResolution.x / iResolution.y;
    uv = CartesianToIsometric(uv);
    float x = fract(uv.x+t);
    float y = fract(uv.y+t);
    vec3 col = vec3(sin(t)*.5+.5+.5);
    col[0] += x + y; 
    col[1] += x - y;
    col[2] += x + x;
    uv += t;
    col *= vec3(CartesianToIsometric(fract((uv)+t*2.0)),.5);
    o = vec4(col,1.0);
    fragColor = o;
}

