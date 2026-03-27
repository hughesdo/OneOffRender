#version 330 core

// Original author: gam0022
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/Xtd3W7
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture
uniform sampler2D iChannel1;  // Video texture

out vec4 fragColor;

// copied from QuantumSuper <3
#define getDat(addr) texture(iChannel0, vec2(float(addr) / 512.0, 0.25)).x

void main() {
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = fragCoord / iResolution.xy;
    vec2 uv2 = -1.0 + 2.0 * uv;
    vec4 color = texture(iChannel1, uv);
    float gray = length(color.rgb);
    fragColor = vec4(vec3(step(0.06, length(vec2(dFdx(gray), dFdy(gray))))), 1.0);
    fragColor += vec4(getDat(gray* 5.), getDat(gray* 2.5), getDat(gray*1.05), 0.5);

    // copied from db0x90 "ShitJustGotReal"
    vec3 resultColor = mix(vec3(0.),vec3(fragColor.x, fragColor.y, fragColor.z),pow(max(0.,1.5-length(uv2*uv2*uv2*vec2(2.0,2.0))),.3));
    fragColor = vec4(resultColor, 1.0);
}