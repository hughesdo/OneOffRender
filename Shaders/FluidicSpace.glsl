#version 330 core

// Original author: EnigmaCurry
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/tdS3DD
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// https://www.shadertoy.com/view/tdS3DD
// Modified by ArthurTent
// Created by EnigmaCurry
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/

// Fluidic Space - EnigmaCurry
// Adapted from Simplicity by JoshP
// https://www.shadertoy.com/view/lslGWr
// http://www.fractalforums.com/new-theories-and-research/very-simple-formula-for-fractal-patterns/
float field(in vec3 p) {
	float strength = 4. + .03 * log(1.e-6 + fract(sin(iTime) * 4373.11));
	float accum = 0.;
	float prev = 0.;
	float tw = 1.11;
	for (int i = 0; i < 32; ++i) {
		float mag = dot(p/1.3, p/1.3);
		p = abs(p) / mag + vec3(-.5, -.4, -1.5);
		float w = exp(-float(i) / 777.);
		accum += w * exp(-strength * pow(abs(mag - prev), 1.9));
		tw += w;
		prev = mag;
	}
	return max(0., 4. * accum / tw - .5);
}

vec4 simplicity(vec2 fragCoord, float fft) {
	//vec2 uv = 2. * fragCoord.xy / iResolution.xy - 1.;
    vec2 uv = fragCoord - 0.45;
	//vec2 uvs = uv * iResolution.xy / max(iResolution.x, iResolution.y);
    vec2 uvs = uv;// * iResolution.xy / max(iResolution.x, iResolution.y);
	vec3 p = vec3(uvs / 3., 0) + vec3(1., 1.01, 0.);
	p += 2. * vec3(sin(iTime / 39.), cos(iTime / 2100.)-2.,  sin(iTime / 18.)-8.);
	float t = field(p);
	float v = (1. - exp((abs(uv.x) - 1.) * 6.)) * (1. - exp((abs(uv.y) - 1.) * 6.));
	return mix(.4, 1., v) * vec4(1.8 * t * t * t, 1.4 * t * t, t, 1.0) * fft;
}

vec4 simplicity2(vec2 fragCoord, float fft) {
    float fmod = tan(fft/21222.);
	//vec2 uv = 2. * fragCoord.xy / iResolution.xy - 1.;
    vec2 uv = fragCoord - 0.45;
	vec2 uvs = uv * iResolution.xy / max(iResolution.x, iResolution.y);
	vec3 p = vec3(uvs / 333., 0) + vec3(1., 0.1, 0.);
	p += tan(fmod) * vec3(cos(iTime / 39.), tan(iTime / 2100.)-2.,  sin(iTime / 18.)-8.);
	float t = field(p);
	float v = (1. - exp((abs(uv.x) - 1.) * 6.)) * (1. - exp((abs(uv.y) - 1.) * 6.));
	return mix(.4, 1., v) * vec4(1.8 * t * t * t, 1.4 * t * t, t, 1.0) * fft;
}

vec4 simplicity3(vec2 fragCoord, float fft) {
    float fmod = cos(fft*13.);
	//vec2 uv = 2. * fragCoord.xy / iResolution.xy - 1.;
    vec2 uv = fragCoord - 0.45;

	vec2 uvs = uv * iResolution.xy / max(iResolution.x, iResolution.y);
	vec3 p = vec3(uvs / 1., 0) + vec3(1., 0.01, 0.);
	p += 2.19 * vec3(cos(iTime / 3900.), tan(iTime / 2100.)-2.,  sin(iTime / 18.)-8.);
	float t = field(p);
	float v = (1. - exp((abs(uv.x) - 1.) * 6.)) * (1. - exp((abs(uv.y) - 1.) * 6.));
	return mix(sin(fmod)+8.8, 1., v) * vec4(0.8 * t * p.x * t, 0.9 * t, t, 1.0) * fft;
}


void main() {
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    float fft = clamp(texture( iChannel0, vec2(0.1,0.1) ).x * 12., 0.2, 99999.);
    fragCoord =  -1.0 + 2.0 *(fragCoord / iResolution) +.5;
	fragColor += sqrt(simplicity(fragCoord, fft));
    fragColor += sqrt(simplicity2(fragCoord, fft));
    fragColor += sqrt(simplicity3(fragCoord, fft));
}
