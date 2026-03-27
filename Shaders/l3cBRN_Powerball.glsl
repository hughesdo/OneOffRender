#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Powerball
// Created by diatribes
// Shadertoy ID: l3cBRN
// https://www.shadertoy.com/view/l3cBRN

#define s(x) sin((x)+iTime)

void main(){
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    const float z=35.0;
    vec2 uv=(u/iResolution.xy-.5)+cos(.5+iTime)*.0125;
    uv.x=uv.x*(iResolution.x/iResolution.y)+s(.05)*.0125;
    float d=length(vec3(z*uv.xy,1.0))-15.0+s(.0)*.2+.2;
    float r=distance(sin(d+z*uv)*uv+d,vec2(s(0.),s(0.)));
    float g=distance(.5*d+z*uv,vec2(0.,r));
    float b=distance(.5*d+z*uv,vec2(g,s(0.)));
    float v=16.0+(d<.0?-d*3.0:(1.0/d)*300.0)*abs(s(r)+s(g)+s(b)+s(z*uv.x)+s(z*uv.y));
    o=vec4(r/v,g/v+sqrt(.1/d),b/v,1.0);
    fragColor = o;
}

