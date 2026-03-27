#version 330 core

// Original author: s23b
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/4dcSRj
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format

// https://www.shadertoy.com/view/4dcSRj
// Modified by ArthurTent
// Created by s23b
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture
uniform sampler2D iChannel1;  // Video texture

out vec4 fragColor;

void main( )
{
	//vec2 uv = fragCoord.xy / iResolution.xy * 2. - 1.;
	vec2 uv = -1.0 + 2.0* gl_FragCoord.xy / iResolution;
    uv.x *= iResolution.x / iResolution.y;

    // mirror everything across x and y axex
    uv = abs(uv);

    // init to black
    fragColor = vec4(vec3(0), 1);

    // add horizontal and vertical scrolling sine waves
    fragColor.rgb += smoothstep(.2, .24, sin(uv.x + iTime * vec3(1, 2, 4)) + .5 - uv.y);
    fragColor.rgb += smoothstep(.2, .24, sin(uv.y * 2. + iTime * vec3(1, 2, 4)) / 2. + 1. - uv.x);

    // flip colors that are out of bounds
    fragColor.rgb = abs(1. - fragColor.rgb);

    // rotate space around the center
    float angel = iTime * .2,
        s = sin(angel),
        c = cos(angel);
    uv *= mat2(c, -s, s, c);

    // multiply by video texture
    fragColor *= texture(iChannel1, abs(.5 - fract(uv)) * 2.);

    // offset space according to spikes in fft data
    uv *= 10. + texture(iChannel0, vec2(.3, .25)).x * 5.;

    // add morphing sine grid
    fragColor *= clamp(sin(uv.x) * sin(uv.y) * 20. + sin(iTime) * 5., 0., 1.) + .5;

}