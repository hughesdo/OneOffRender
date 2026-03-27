#version 330 core

// Original author: Passion
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/MsBSzw
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// https://www.shadertoy.com/view/MsBSzw
// Modified by ArthurTent
// Created by Passion
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/
uniform sampler2D iChannel1;

void main()
{
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;
    //vec2 p = (fragCoord.xy-.5*iResolution.xy)/min(iResolution.x,iResolution.y);
    //vec2 p =  (fragCoord / iResolution) - .5;
    vec2 p =  (fragCoord / iResolution)-0.5;

    vec3 c = vec3(0.0);
    //vec2 uv = fragCoord.xy / iResolution.xy;
    //vec2 uv = fragCoord / iResolution.xy;
    //vec2 uv =  -1. + 2.* (fragCoord / iResolution);
    vec2 uv =  (fragCoord / iResolution);
    float wave = texture( iChannel0, vec2(uv.x,0.75) ).x;

    for(int i = 1; i<20; i++)
    {
        float time = 2.*3.14*float(i)/20.* (iTime*.9);
        float x = sin(time)*1.8*smoothstep( 0.0, 0.15, abs(wave - uv.y));
        float y = sin(.5*time) *smoothstep( 0.0, 0.15, abs(wave - uv.y));
        y*=.5;
        vec2 o = .4*vec2(x*cos(iTime*.5),y*sin(iTime*.3));
        float red = fract(time);
        float green = 1.-red;
        c+=0.016/(length(p-o))*vec3(red,green,sin(iTime));
    }
    fragColor = vec4(c,1.0);
}
//2014 - Passion
//References  - https://www.shadertoy.com/view/Xds3Rr
//            - tokyodemofest.jp/2014/7lines/index.html


