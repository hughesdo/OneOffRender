#version 330 core

// Original author: slerpy
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/4dXBR8
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// https://www.shadertoy.com/view/4dXBR8
// Modified by ArthurTent
// Created by slerpy
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/

void main()
{
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    fragColor = vec4(0);
	vec2 uv = fragCoord.xy/iResolution.xy;
    float yoff = texture(iChannel0,vec2(uv.x/8.,1)).r/20.;
    fragColor += vec4(0.0); // iVideo disabled - no video texture in OneOffRender
    if(abs(3.*(uv.y-.5))>pow(max(.2,texture(iChannel0,vec2(uv.x,0)).r),3.))fragColor+=1.;
}