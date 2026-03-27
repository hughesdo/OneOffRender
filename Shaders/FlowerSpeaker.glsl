#version 330 core

// Original author: coposuke
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/ttXczX
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// https://www.shadertoy.com/view/ttXczX
// Modified by ArthurTent
// Created by coposuke
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

#define PI (3.14159265357989)
#define TAU (PI * 2.0)


vec3 hsv2rgb(vec3 c)
{
	return c.b * ((clamp( abs( fract(c.r + vec3(0,2,1) / 3.0) * 6.0 - 3.0) - 1.0, 0.0, 1.0) - 1.0) * c.g + 1.0);
}

void main()
{
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    //vec2 uvSound = fragCoord.xy / iResolution.xy;
	//vec2 uv = (fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);
    vec2 uvSound = (fragCoord / iResolution).xy;
    vec2 uv = -2.+4.*(fragCoord / iResolution);

    vec2 uvCircle = vec2(
    	(atan(-uv.y, -uv.x) + PI) / TAU,
    	length(uv) * 1.5
    );

    const float CircleOffset = -0.5;
    const float CircleLevel = 5.5;
    float circleType = floor(uvCircle.y * CircleLevel + CircleOffset);

    int colorType = 0;
    float colorDepth = 0.0;

    if (circleType < 20.0)
    {
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

        for(float i=0.0; i<6.0; i++)
        {
            if(circleType - i < 9.0)
            {
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

                vec2 fftUV = vec2(uvCircle.x, 0.0);
                float fft1 = texture( iChannel0, fftUV ).x;
                float fft2 = texture( iChannel0, vec2(1.0 - fftUV.x, fftUV.y) ).x;
                float fft = fract(uvCircle.y * CircleLevel + CircleOffset);
                if( fft + i < fft1 * fft2 * mix(1.0, 50.0, (circleType - i) / 20.0) )
                {
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

                    colorType = int(circleType) - int(i);
                    colorDepth = smoothstep(0.0, 1.0, fft + i);
                }
            }
        }
    }


	vec3 col = vec3(0);

    float t = PI * float(colorType) / 20.0 + fract(iTime * 0.1);
    col += float(1 < colorType && colorType < 10) * hsv2rgb(vec3(fract(t), 1.75 - colorDepth, colorDepth));

    /*
    if(uvCircle.y < 0.5)
    {
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    	col = mix(col, vec3(0.2, 0.16, 0.15), smoothstep(0.3, 0.45, uvCircle.y) * smoothstep(0.5, 0.45, uvCircle.y));
    }
    */

    //float wave = texture( iChannel0, vec2(uvSound.x * 0.25, 1.0) ).x;
	//col += smoothstep(0.002, 0.001, abs(uvSound.y - wave)) * vec3(1.0, 1.0, 0.0);

	fragColor = vec4( col, 1.0 );
}
