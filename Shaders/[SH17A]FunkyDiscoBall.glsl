#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture
uniform sampler2D iChannel1;  // Sky texture

out vec4 fragColor;

// https://www.shadertoy.com/view/wd3XzS
// Modified by ArthurTent
// Created by knarkowicz
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/deed.en
float sample_at(float f)
{
    return texture(iChannel0, vec2(f / 16.0, 0.)).x;
}

void main(  )
{
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    //vec2 p = iResolution.xy;
    /*
    vec2 p = fragCoord / iResolution;
    vec2 f = -1.0 + 2.0* fragCoord / iResolution;
    */
    /*
    vec2 p = fragCoord / iResolution * 2. - 1.
    vec2 f = fragCoord / iResolution;

    //vec2 uv =  2.0*vec2(fragCoord.xy - 0.5*iResolution.xy)/iResolution.y;
	vec2 uv = -1.0 + 2.0* fragCoord / iResolution;
    */
    vec2 p = fragCoord / iResolution ;
    vec2 f = -1.0 + 2.0* fragCoord / iResolution+ vec2(.25   ,0.25);

    float d = length( p = ( f + f - p ) / p.y ) / .9,
          l = ceil( d ),
          t = iTime / ( 1.5 - l ) * .3 + (iResolution.xy * 0.5).x / 1e3;

    p = p * asin( d / l ) / d - 5.;

    p.x -= t;
	f = min( abs( fract( p *= 6. ) - .1 ) * 9., 1. );
    p = ceil( p ) / 6.;
    p.x += t;
    float bass = sample_at(0.1);
    fragColor = texture( iChannel1, p * .1 )
        * f.x * f.y * bass
        //* ( l > 1. ? texture( iChannel0, p ).x : 1.5 );
        * ( l > 1. ? texture( iChannel0, vec2(t / 16.0, 0.) ).x : 1.5 );
}