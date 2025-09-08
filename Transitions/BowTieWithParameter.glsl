// Author: KMojek
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float adjust; // = 0.5
uniform bool reverse; // = false

out vec4 outColor;

float check(vec2 p1, vec2 p2, vec2 p3)
{
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

bool pointInTriangle(vec2 pt, vec2 p1, vec2 p2, vec2 p3)
{
    bool b1 = check(pt, p1, p2) < 0.0;
    bool b2 = check(pt, p2, p3) < 0.0;
    bool b3 = check(pt, p3, p1) < 0.0;
    return b1 == b2 && b2 == b3;
}

const float height = 0.5;

vec4 transition_firstHalf(vec2 uv, float prog)
{
    if (uv.y < 0.5)
    {
        vec2 botLeft = vec2(-0., prog - height);
        vec2 botRight = vec2(1., prog - height);
        vec2 tip = vec2(adjust, prog);
        if (pointInTriangle(uv, botLeft, botRight, tip))
            return texture(to, uv);
    }
    else
    {
        vec2 topLeft = vec2(-0., 1. - prog + height);
        vec2 topRight = vec2(1., 1. - prog + height);
        vec2 tip = vec2(adjust, 1. - prog);
        if (pointInTriangle(uv, topLeft, topRight, tip))
            return texture(to, uv);
    }
    return texture(from, uv);
}

vec4 transition_secondHalf(vec2 uv, float prog)
{
    if (uv.x > adjust)
    {
        vec2 top = vec2(prog + height, 1.);
        vec2 bot = vec2(prog + height, -0.);
        vec2 tip = vec2(mix(adjust, 1.0, 2.0 * (prog - 0.5)), 0.5);
        if (pointInTriangle(uv, top, bot, tip))
            return texture(from, uv);
    }
    else
    {
        vec2 top = vec2(1.0 - prog - height, 1.);
        vec2 bot = vec2(1.0 - prog - height, -0.);
        vec2 tip = vec2(mix(adjust, 0.0, 2.0 * (prog - 0.5)), 0.5);
        if (pointInTriangle(uv, top, bot, tip))
            return texture(from, uv);
    }
    return texture(to, uv);
}

vec4 transition(vec2 uv) {
    float prog = clamp(progress, 0.0, 1.0);
    if (reverse)
        return (prog < 0.5) ? transition_secondHalf(uv, 1. - prog) : transition_firstHalf(uv, 1. - prog);
    else
        return (prog < 0.5) ? transition_firstHalf(uv, prog) : transition_secondHalf(uv, prog);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}