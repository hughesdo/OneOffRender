// Author: huynx
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution

out vec4 outColor;

float check(vec2 p1, vec2 p2, vec2 p3)
{
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
}

bool PointInTriangle(vec2 pt, vec2 p1, vec2 p2, vec2 p3)
{
    bool b1 = check(pt, p1, p2) < 0.0;
    bool b2 = check(pt, p2, p3) < 0.0;
    bool b3 = check(pt, p3, p1) < 0.0;
    return ((b1 == b2) && (b2 == b3));
}

bool in_top_triangle(vec2 p) {
    float prog = clamp(progress, 0.0, 1.0);
    vec2 vertex1 = vec2(0.5, prog);
    vec2 vertex2 = vec2(0.5 - prog, 0.0);
    vec2 vertex3 = vec2(0.5 + prog, 0.0);
    return PointInTriangle(p, vertex1, vertex2, vertex3);
}

bool in_bottom_triangle(vec2 p) {
    float prog = clamp(progress, 0.0, 1.0);
    vec2 vertex1 = vec2(0.5, 1.0 - prog);
    vec2 vertex2 = vec2(0.5 - prog, 1.0);
    vec2 vertex3 = vec2(0.5 + prog, 1.0);
    return PointInTriangle(p, vertex1, vertex2, vertex3);
}

float blur_edge(vec2 bot1, vec2 bot2, vec2 top, vec2 testPt)
{
    vec2 lineDir = bot1 - top;
    vec2 perpDir = vec2(lineDir.y, -lineDir.x);
    vec2 dirToPt1 = bot1 - testPt;
    float dist1 = abs(dot(normalize(perpDir), dirToPt1));

    lineDir = bot2 - top;
    perpDir = vec2(lineDir.y, -lineDir.x);
    dirToPt1 = bot2 - testPt;
    float min_dist = min(abs(dot(normalize(perpDir), dirToPt1)), dist1);

    if (min_dist < 0.005) {
        return min_dist / 0.005;
    }
    else {
        return 1.0;
    }
}

vec4 transition(vec2 uv) {
    float prog = clamp(progress, 0.0, 1.0);
    if (in_top_triangle(uv))
    {
        if (prog < 0.1)
        {
            return texture(from, uv);
        }
        if (uv.y < 0.5)
        {
            vec2 vertex1 = vec2(0.5, prog);
            vec2 vertex2 = vec2(0.5 - prog, 0.0);
            vec2 vertex3 = vec2(0.5 + prog, 0.0);
            return mix(
                texture(from, uv),
                texture(to, uv),
                blur_edge(vertex2, vertex3, vertex1, uv)
            );
        }
        else
        {
            if (prog > 0.0)
            {
                return texture(to, uv);
            }
            else
            {
                return texture(from, uv);
            }
        }
    }
    else if (in_bottom_triangle(uv))
    {
        if (uv.y >= 0.5)
        {
            vec2 vertex1 = vec2(0.5, 1.0 - prog);
            vec2 vertex2 = vec2(0.5 - prog, 1.0);
            vec2 vertex3 = vec2(0.5 + prog, 1.0);
            return mix(
                texture(from, uv),
                texture(to, uv),
                blur_edge(vertex2, vertex3, vertex1, uv)
            );
        }
        else
        {
            return texture(from, uv);
        }
    }
    else {
        return texture(from, uv);
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}