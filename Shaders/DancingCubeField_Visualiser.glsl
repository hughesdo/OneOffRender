#version 330 core

// Original author: Pelegefen
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/fl2XRm
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture
// uniform sampler2D iChannel1;  // Video texture (disabled - OneOffRender doesn't support video textures yet)

out vec4 fragColor;

// https://www.shadertoy.com/view/fl2XRm
// Modified by ArthurTent
// Created by Pelegefen
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/
uniform sampler2D iChannel1;

//!!!!!!!!EPILEPSY WARNING!!!!!!!FLASHING LIGHTS!!!!!!!!!!

//Made with love by Peleg Gefen <3

//song - Warp9 - Seems Like A Dream



//----------------------------------DEFINES------------------------------------------------

//#define Time_And_Zoom //SEIZURE INDUCING LOL - Allows you to use the horizontal mouse axis to "peek into the future" to
//see the full evolution of the wave. use the vertical axis for zoom in-and-out


//#define Mode2 //Freaky inverted cubes effect

//-----------------------------------------------------------------------------------------

#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

float freqs[4];
vec2 rot (vec2 p,float a)
{
    float c = cos(a);
    float s = sin(a);
    return p*mat2(c,s,-s,c);
}



float hexDist(vec2 p) {
    p = abs(p);
    //distance to the diagonal line
    float c = dot(p, normalize(vec2(1., 1.73)));

    // distance to the vertical line
    c = max(c, p.x);
    c += sin(iTime + 4000.) *5. +5.;
    return c;
  }

vec4 hexCoords(vec2 uv) {
    vec2 r = vec2(1., 1.73);
    vec2 h = r * 0.5;
    vec2 a = mod(uv, r) - h;
    vec2 b = mod(uv - h, r) - h;

    vec2 gv;
    if(length(a) < length(b))
      gv = a;
    else
      gv = b;

    float y = .5 - hexDist(gv);
    float x = atan(gv.x, gv.y);
    vec2 id = uv - gv;
    return vec4(x, y, id.x, id.y);

}

vec3 getTexture(vec2 p){
	vec4 s = texture(iChannel1, p);
    return s.xyz * s.w;
}


void main()
{
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;


    vec3 col_greenscreen = getTexture((fragCoord / iResolution));
    freqs[0] = texture( iChannel0, vec2( 0.01, 0.25 ) ).x;
	freqs[1] = texture( iChannel0, vec2( 0.07, 0.25 ) ).x;
	freqs[2] = texture( iChannel0, vec2( 0.15, 0.25 ) ).x;
	freqs[3] = texture( iChannel0, vec2( 0.30, 0.25 ) ).x;
    float avgFreq = (freqs[0] +freqs[1] +freqs[2] +freqs[3])/4.;


	float iTime = iTime * .25;
	iTime += 800.;
	vec2 u = (fragCoord / iResolution).xy * iResolution.xy;
	//vec2 uv = ( u.xy-.5*iResolution.xy)
	vec2 uv = (u-.5*iResolution.xy)/iResolution.y;
    vec2 uv2 = (fragCoord / iResolution) * 2. - 1.;


     vec4 col = vec4(0.);
     vec2 uv1 = uv;
     //uv *= 3.;
     uv *= ( sin(iTime+freqs[0])*8.5+8.5) + 5.;
     uv -= 8.0;

     uv += vec2(iTime *	 .01);

     #ifdef Time_And_Zoom
     iTime += vec4(iResolution.xy * 0.5, 0.0, 0.0).x * 10.;
     uv *=  vec4(iResolution.xy * 0.5, 0.0, 0.0).y * .007;
     #else
     uv -= (vec4(iResolution.xy * 0.5, 0.0, 0.0).xy / iResolution.xy ) * 2. ;
     #endif

     uv += rot(uv , (cos(iTime - (avgFreq * (3.1415*.5)))*.5+.5) );



     vec4 uvid = hexCoords(uv * 2.);

     float t = smoothstep(.5,.5
 	 	,uvid.y
 	 	* sin(( length(uvid.zw))
 	 	 * iTime *0.1)*.5+.5);


	col = vec4(
    t * tan(freqs[3])*.5+.5 * sin(freqs[0] * 2.5)*.5+.5
    , t*cos(freqs[2])*.5+.5* sin(freqs[1] * 5.)*.5+.5
    , t * sin(freqs[1])*.5+.5 * sin(freqs[2] * 10.)*.5+.5
    ,1.);

    col -= vec4(freqs[0],freqs[1],
         freqs[2],
         1.);



	//lit face
	col += vec4(smoothstep(.99,.991,uvid.x));


	//shading
	col += vec4(smoothstep(-1.,-1.,uvid.x)) * .6;


     float circle = sin(freqs[0]);

     float triangles = sin(freqs[1] / length(uvid.z/uvid.w))*.5+.5
     / cos(freqs[3] * length(uvid.z/uvid.w))*.5+.5 ;

     triangles = mix(-triangles,triangles,sin(iTime)*.5+.5);


 	 //hexagons shrinking and expanding, wave form
 	 col *= vec4(smoothstep(.000001,.00001
 	 	,uvid.y

        #ifdef Mode2
 	 	* uvid.x
        #endif
        * sin((( length(uvid.zw * freqs[1]) * mix(circle,triangles,freqs[3])))*.5+.5
 	 	 * (dot(freqs[1],length(uvid.zw) * .05) ))))* max(freqs[0] , .1) + .3;

 	 col = clamp(col,0.,1.);
	fragColor = vec4( col);
	fragColor += vec4(col_greenscreen, 1.);
    vec3 resultColorWithBorder = mix(vec3(0.),vec3(fragColor.x, fragColor.y, fragColor.z),pow(max(0.,1.5-length(uv2*uv2*uv2*vec2(2.0,2.0))),.3));
    fragColor = vec4(resultColorWithBorder,1.0);
}
