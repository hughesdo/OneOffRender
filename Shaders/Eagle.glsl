#version 330 core
// Homeward - Main Image Pass
// by David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Do the crow in this buffer...

out vec4 fragColor;

// Uniforms
uniform vec2 iResolution;
uniform float iTime;
uniform vec4 iMouse;
uniform sampler2D iChannel0;   // Buffer A (data storage)
uniform sampler2D iChannel1;   // Buffer B (landscape/sky)
uniform sampler2D iChannel2;   // Noise texture (if needed)

#define PI 3.1415926535

mat3 crowDir;
vec4 flapping, headTilt;
float turn, specular;

//----------------------------------------------------------------------------------------
vec4 getStore(int num)
{
    //ivec2 loc = ivec2(num & 63, num/64); // Didn't need that many, doh!
    ivec2 loc = ivec2(num, 0);
    return  texelFetch(iChannel0, loc, 0);  // Buffer A is on iChannel0
}


//----------------------------------------------------------------------------------------

//----------------------------------------------------------------------------------------
float noise( in float p  )
{
    
    float f = fract(p);
    p = floor(p);
	f = f*f*(3.0-2.0*f);
	return mix(hash11(p),hash11(p+1.), f);
}

//----------------------------------------------------------------------------------------
float sMin( float a, float b, float k )
{
    
	float h = clamp(0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.-h);
}
//----------------------------------------------------------------------------------------
mat2 rot2D(float a)
{
	float si = sin(a);
	float co = cos(a);
	return mat2(co, si, -si, co);
}

//----------------------------------------------------------------------------------------
float  sphere( vec3 p, float s )
{
    return length(p)-s;
}

//----------------------------------------------------------------------------------------
float featherBox( vec3 p, vec3 b, float r )
{
    b.y-= smoothstep(3.75, -4.0, p.z)*noise(p.x*6.)*.56;

    p.y+=  smoothstep(1.5, .0, p.z)*noise(p.x*3.+crowPos.z*1.)*.35;
    return length(max(abs(p)-b,0.0))-r;
}

//----------------------------------------------------------------------------------------
float featherTailBox( vec3 p, vec3 b, float r )
{
    //b.x /= smoothstep(-10.,4.,p.z);
    p.x *= clamp((p.z+4.)/6., 0.1,2.5);
    b.y-= smoothstep(.75, .0, p.z)*noise(p.x*3.)*.3;
    
    p.y+=  smoothstep(1., -4.0, p.z)*noise(p.x*3.+crowPos.z*1.)*.5;
    return length(max(abs(p)-b,0.0))-r;
}

//----------------------------------------------------------------------------------------
float segment(vec3 p,  vec3 a, vec3 b, float r1, float r2)
{
	vec3 pa = p - a;
	vec3 ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r1 + r2*h;
}


//--------------------------------------------------------------------------
float noise( in vec3 p )
{
    vec3 f = fract(p);
    p = floor(p);
	f = f*f*(3.0-2.0*f);
	
	vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel2, (uv+ 0.5)/256.0, 0.0).yx;  // Noise texture
	return mix( rg.x, rg.y, f.z );
}

//----------------------------------------------------------------------------------------
vec3 getSky(vec3 dir, vec3 pos)
{
    vec3 col;
    vec3 clou = dir * 1. + pos*.025;
	float t = noise(clou);
    t += noise(clou * 2.1) * .5;
    t += noise(clou * 4.3) * .25;
    t += noise(clou * 7.9) * .125;
	col = mix(vec3(FOG_COLOUR), vec3(0.2, 0.2,.2),abs(dir.y))+ FOG_COLOUR *t*.4;
 
    return col;
}

//----------------------------------------------------------------------------------------
// Map a crow like asbtract bird thing...
float map(vec3 p, float t)
{
    float d, f;
    specular = .1;
    // Normalize rotation...
    vec3 q = crowDir*(p-crowPos);
    // Head...
    vec3 b = q- vec3(.0, 0, 2.8);
    b.yz = b.yz*rot2D(headTilt.x);
    b.xz = b.xz*rot2D(headTilt.y);
    d = segment(b,vec3(0,0,1), vec3(0,0,5.), 1.2, 3.); 

    // Body...
    b = q+vec3(0,1.,3);
  	d = sMin(d, segment(q, vec3(0), vec3(0,0,-14), 1.3, 11.5), 3.); 
    // Tail...
    b.xy = b.xy* rot2D(headTilt.w);
    d = sMin(d, featherTailBox(b, vec3(headTilt.z,.1,2.2), .3),4.3); 
    // Left wing...
    b = q + vec3(2.8,0,0);
    b.xy = rot2D(flapping.x)*b.xy;
    d = sMin(d, featherBox(b+(vec3(4,0,1.)), vec3(4,.05,2.5),.4), 2.);
    
    b =  b + vec3(8,0,0);
    b.xy = rot2D(flapping.y*1.5)*b.xy;
	f = featherBox(b+vec3(4,0,0), vec3(4,.05,3.5),.4);
    f = max(f, sphere(b+vec3(2,0,3), 5.));
    d = sMin(d, f, .1);
    
    // Right wing...
    b = q - vec3(2.8,0,0);
    b.xy = rot2D(-flapping.z)*b.xy;
    d = sMin(d, featherBox(b-(vec3(4,0,-1.)), vec3(4,.05,2.5),.4), 2.);
    
    
    b =  b - vec3(8,0,0);
    b.xy = rot2D(-flapping.w*1.5)*b.xy;
    f = featherBox(b-vec3(4,0,0), vec3(4,.05,3.5),.4);
    f = max(f, sphere(b-vec3(2,0,-3), 5.));
    d = sMin(d, f, .1);

    // Do some glassy eyes...
    b = q- vec3(.0, .0, 2.85);
    
    b.yz = b.yz*rot2D(headTilt.x);
    b.xz = b.xz*rot2D(headTilt.y);
	b.x = abs(b.x);

    f = sphere(b-vec3(.7,0.1,1.4), .25);
    if (f < d){ d = f; specular = 4.0;}

    
    return d;
}
//----------------------------------------------------------------------------------------
vec3 getNormal(vec3 p, float e)
{
    return normalize( vec3( map(p+vec3(e,0.0,0.0), e) - map(p-vec3(e,0.0,0.0), e),
                            map(p+vec3(0.0,e,0.0), e) - map(p-vec3(0.0,e,0.0), e),
                            map(p+vec3(0.0,0.0,e), e) - map(p-vec3(0.0,0.0,e), e) ) );
}

//----------------------------------------------------------------------------------------
vec3 lighting(in vec3 pos, in vec3 normal, in vec3 eyeDir, in float d)
{
	;
   	normal = reflect(eyeDir, normal); // Specular...
    vec3 col = pow(max(dot(sunLight, normal), 0.0), 10.0)  * SUN_COLOUR * specular;


	return min(col, 1.0);
}


//----------------------------------------------------------------------------------------
float marchScene(in vec3 rO, in vec3 rD, vec2 co, float t)
{
	t += .5*hash12(co);
    
    for( int j=0; j < 30; j++ )
	{
		if (t >= FAR) break;
		float h = map( rO + t*rD, t*0.012);
 		if(h < 0.03)
		{
  
            break;
	     }
        t += h + t*.005;
	}
    return t;
}

//----------------------------------------------------------------------------------------
vec3 lenseFlare(vec2 uv,vec3 dir, mat3 camMat)
{

    vec3 col = vec3(0);
    float bri = dot(dir, sunLight)*.7;
	if (bri > 0.0)
	{
		vec2 sunPos = vec2(dot( sunLight, camMat[0] ),dot( sunLight, camMat[1] ) );
        //sunPos = clamp(sunPos,-.5,.5);
        //sunPos *= vec2(iResolution.y/iResolution.x, 1.);
	    float z = textureLod(iChannel1,(sunPos+1.)*.5, 0.).w;  // Buffer B (landscape/sky)
       	vec2 uvT = uv-sunPos;
        if (z >= FAR)
        {
            uvT = uvT*(length(uvT));
            bri = pow(bri, 6.0)*.7;

            // glare = the red shifted blob...
            float glare1 = max(dot(dir,sunLight),0.0)*1.4;
            // glare2 is the yellow ring...
            float glare2 = max(1.-length(uvT+sunPos*.4)*4.0, 0.0);
            uvT = mix (uvT, uv, -2.3);
            // glare3 is a splodge...
            float glare3 = max(1.-pow(length(uvT+sunPos*2.5)*3., 2.), 0.0);

            col += bri * vec3(1.0, .0, .0)  * pow(glare1, 12.5)*.05;
            col += bri * vec3(1.0, 1.0, .1) * pow(glare2, 2.0)*2.5;
            col += bri * SUN_COLOUR * pow(glare3, 3.)*3.0;
        }
	}
    return col;
}


//----------------------------------------------------------------------------------------
void mainImage( out vec4 colOut, in vec2 fragCoord )     
{
    vec2 uv = (-iResolution.xy + 2.0 * fragCoord ) / iResolution.y;

    vec3 col;

	    // Camera and sun state from Buffer A (no crow usage)
	    sunLight   = getStore(SUN_DIRECTION).xyz;
	    vec3 camPos = getStore(CAMERA_POS).xyz;
	    vec3 camTar = getStore(CAMERA_TAR).xyz;

	    mat3 camMat = setCamMat(camPos, camTar, (camTar.x - camPos.x) * .02);
		    // Match Buffer B: remove fisheye radial warp in the view ray to avoid
		    // faint concentric circles. Use a simple perspective direction.
		    vec3 dir    = camMat * normalize(vec3(uv, 1.0));

		    // Just show Buffer B (landscape/sky) as the base image  no crow overlay
		    vec4 scene  = texelFetch(iChannel1, ivec2(fragCoord), 0);  // Buffer B: rgb=color, a=depth
		    col         = scene.xyz;

		    // DEBUG: Bypass grading/dithering/vignette so we see exactly what
		    // Buffer B is producing.
			colOut = vec4(col, 1.0);
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    // Y-flip to match Shadertoy coordinate system
    fragCoord.y = iResolution.y - fragCoord.y;
    mainImage(fragColor, fragCoord);
}