#version 330 core

// Original author: nshelton
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/4scGW2
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// https://www.shadertoy.com/view/4scGW2
// Modified by ArthurTent
// frequency balls by nshelton
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/


float sphere(vec3 c, float r, vec3 p) {
	return length(p-c) - r;   
}

float DE(vec3 p) {
    //vec4 n1 = texture(iChannel0, vec2(0.2));
    //vec4 n2 = texture(iChannel1, vec2(0.3));

    float min_d = 100.;

    for ( int i = 0 ; i < 20; i ++ ) {
        float t = float(i)/20. ;
        float freq = pow(texture(iChannel0, vec2(t, 0.)).r, 3.0) * 2.;

		float t_tex =  t + iTime/100.;
        //vec4 n0 = texture(iChannel0, vec2(cos(t_tex), sin(t_tex)));
		//n0= n0 * 3. - 1.5;
        //n0.y *=2.;
        vec3 c = vec3(t * 10. - 5. , 0., 0.);// + n0.xyz;
		min_d = min ( min_d, sphere(c, freq, p));

    }
        return min_d;
}

vec3 grad(vec3 p) {
 vec2 eps = vec2(0.01, 0.0);
 
    return normalize(vec3(
        DE(p + eps.xyy) -  DE(p - eps.xyy),
        DE(p + eps.yxy) -  DE(p - eps.yxy),
        DE(p + eps.yyx) -  DE(p - eps.yyx)));
}

void main()
{
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

	//vec2 uv = fragCoord.xy / iResolution.xy ;
    vec2 uvCoord = fragCoord / iResolution;
    //vec2 uv = -1.0 + 2.0 *uvCoord -.5;
    vec2 uv = -1.0 + 2.0 *uvCoord +.35;
	uv = uv *2. - 1.;
    uv.x *= iResolution.x/iResolution.y;

    vec3 ray = normalize(vec3(uv, 1.));
    //vec3 camera = vec3(0.0, 0.0, sin(iTime)-4.);
    vec3 camera = vec3(sin(iTime)*.4,cos(iTime), sin(iTime)-4.);

    float iter = 0.;
    float t = 0.;
   	vec3 point;
 	bool hit = false;
    for ( int i = 0; i < 10; i ++) {
    	point = camera + ray * t;

        float d = DE(point);

        if (DE(point) < 0.1){
         	hit = true;
            break;
        }

        iter += 0.1;
        t += d;
    }
    vec3 color = vec3(0., 0., 0.);
    if ( hit) {
    	color = vec3(dot(ray, -grad(point))) * vec3(1.-(cos(iTime)+sin(iTime)), sin(iTime), cos(iTime)) ;
    	color *= 1. - iter;
    }

    fragColor = vec4(color, 1.0);

}