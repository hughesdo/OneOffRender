#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

vec2	march(vec3 pos, vec3 dir);
vec3	camera(vec2 uv);
void	rotate(inout vec2 v, float angle);
float 	t;			// time



vec3	ret_col;	// torus color
vec3	h; 			// light amount

#define I_MAX		400.
#define E			0.00001
#define FAR			50.
#define PI			3.14

// blackbody by aiekick : https://www.shadertoy.com/view/lttXDn

// -------------blackbody----------------- //

// return color from temperature
//http://www.physics.sfasu.edu/astro/color/blackbody.html
//http://www.vendian.org/mncharity/dir3/blackbody/
//http://www.vendian.org/mncharity/dir3/blackbody/UnstableURLs/bbr_color.html

vec3 blackbody(float Temp)
{
	vec3 col = vec3(255.);
    col.x = 56100000. * pow(Temp,(-3. / 2.)) + 148.;
   	col.y = 100.04 * log(Temp) - 623.6;
   	if (Temp > 6500.) col.y = 35200000. * pow(Temp,(-3. / 2.)) + 184.;
   	col.z = 194.18 * log(Temp) - 1448.6;
   	col = clamp(col, 0., 255.)/255.;
    if (Temp < 1000.) col *= Temp/1000.;
   	return col;
}

// -------------blackbody----------------- //


    t  = iTime*.125;
    vec3	col = vec3(0., 0., 0.);
	vec2 R = iResolution.xy;
	//vec2 uv  = vec2(f-R/2.) / R.y;


void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

	//vec2 uv  = (fragCoord / iResolution); // ganz ok
	vec2 uv = -1.0 + 3.0* (fragCoord / iResolution);
    uv.x *= R.x / R.y;

	vec3	dir = camera(uv);
    vec3	pos = vec3(.0, .0, 0.0);

    pos.z = 4.5+1.5*sin(t*10.);    // add camera movement

    h*=0.;
    vec2	inter = (march(pos, dir));
    col.xyz = ret_col*(1.-inter.x*.0125);
    col += h * .4;
    fragColor =  vec4(col,1.0);
}