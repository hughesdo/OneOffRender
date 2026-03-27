#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Coffee Clouds
// Created by diatribes
// Shadertoy ID: 33GGWd
// https://www.shadertoy.com/view/33GGWd

// tinkering with the forked shader over 0xc0ffee

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,a,d,s,t=iTime*.3;
    vec3  p;
    u = (u-iResolution.xy/2.)/iResolution.y;
    if (abs(u.y) > .4) { o = vec4(0); fragColor = o; return; }
    u += vec2(cos(t*.4)*.3, cos(t*.8)*.1);
    for(o*=i; i++<1e2;
        d += s = .03 + abs(s)*.2,
        o += 1./s)
        for (p = vec3(u*d,d+t),
            p.x *= .8,
            p.x += t*4.,
            s = 4.+p.y,
            a = .05; a < 2.; a += a)
            s -= abs(dot(sin(t+p * a * 8.), .04+p-p)) / a;
    u -= (u.yx*.7+.2-vec2(-.2,.1));
    o = tanh(vec4(5,2,1,0)*o /3e4 / pow(dot(u,u), 1.9));
    
    fragColor = o;
}

