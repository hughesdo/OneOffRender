#version 330 core
// Buffer A - Data Storage Pass
// by David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// These are indices into the variable data in this buffer...

out vec4 fragColor;

// Uniforms
uniform vec2 iResolution;
uniform float iTime;
uniform vec4 iMouse;
uniform sampler2D iChannel0;   // Self-feedback (previous frame)

//----------------------------------------------------------------------------------------
float noise( in float p  )
{
    float f = fract(p);
    p = floor(p);
	f = f*f*(3.0-2.0*f);
	return mix(hash11(p),hash11(p+1.), f);
}
//----------------------------------------------------------------------------------------
float noiseTilt( in float p  )
{
    float f = fract(p);
    p = floor(p);
	f = f*f*(3.0-2.0*f);
    
    f = f*f*f*f;
	return mix(hash11(p),hash11(p+1.), f);
}
//----------------------------------------------------------------------------------------
float grabTime()
{
  	float m = (iMouse.x/iResolution.x)*80.0;
	return (iTime+m+110.)*32.;
}

//----------------------------------------------------------------------------------------
int StoreIndex(ivec2 p)
{
	return p.x + 64 * p.y;
}

//----------------------------------------------------------------------------------------
vec4 getStore(int num)
{
   	//ivec2 loc = ivec2(num & 63, num/64); // Didn't need that many, doh!
    ivec2 loc = ivec2(num, 0);
    return  texelFetch(iChannel0, loc, 0);  // Self-feedback on iChannel0
}

//----------------------------------------------------------------------------------------
void mainImage( out vec4 fragColour, in vec2 fragCoord )
{
    ivec2 pos = ivec2(fragCoord);
    vec4 col = vec4(0.);
	float gTime = grabTime();
    
    int num = StoreIndex(pos);
    if (num > CROW_CLIMBING) discard;
    
    vec4 diff = (getStore(CROW_HEADING) - getStore(CROW_POS)) * vec4(-.07,.3, 1,1);
    float climb  = diff.y;
    float oldClimb  = getStore(CROW_CLIMBING).x;

    switch (num)
    {
        case CAMERA_POS:
        {
	            // Original shader adds a fairly large sinusoidal offset here:
	            //   cameraPath(gTime) + vec3(sin(r*0.64)*12, cos(r*0.3)*12, 0)
	            // which creates a noticeable "handheld camera" wobble,
	            // especially when flying through the tunnel.
	            // For a smoother flight path we keep the authored cameraPath
	            // but remove the extra wobble term.
	        	col.xyz = cameraPath(gTime);
        }
    		break;
        case CAMERA_TAR:
            col.xyz = cameraPath(gTime + 20.);
        	break;
        case SUN_DIRECTION:
        	col.xyz  = normalize( vec3(  0.7, .8,  0.3 ) );
    		break;
       	case CROW_POS:
        {
        	float r = gTime / 200.-10.;
        	col.xyz = cameraPath(gTime + 45.+ sin(r*.5)* 30.)+vec3(sin(r)*15.0, cos(r*.2)*12.0, 0.0);
            float sp = pow((clamp(oldClimb+.1,0.0, .5)), 2.2)*3.;
            
            //col.y-= sin(gTime*.25)*sp;
            vec2 ax = vec2(sin(diff.x), cos(diff.x));
            col.xy+= -ax*sin(gTime*.25)*sp;
        }
        	break;
        case CROW_HEADING:
        {
        	float r = gTime / 200.-10.;
        	col.xyz = cameraPath(gTime + 50.+ sin(r*.5)* 30.)+vec3(sin(r)*15.0, cos(r*.2)*12.0, 0.0);
        }
         	break;
        case CROW_FLAPPING:
        {
            float sp = pow((clamp(oldClimb+.1,0.0, .5)), 2.2)*3.5;
   
        	col.x  = sin(gTime*.25)*sp+ noise(gTime*.1)*.35;
            col.y  = sin(gTime*.25-1.)*sp*.5+smoothstep(0.5,.0,sp)*.1;
            
            col.z  = sin(gTime*.25)*sp+ noise(gTime*.1+8.)*.35;
            col.w  = sin(gTime*.25-1.)*sp*.5+smoothstep(0.5,.0,sp)*.1;
        }
        	break;
        case CROW_HEADTILT:
        	col.x = noiseTilt(gTime*.01+8.)*.5;
        	col.y = noiseTilt(gTime*.05+111.)-.5;
        	col.z = noiseTilt(gTime*.03)*.8+.2;
        	col.w = (noiseTilt(gTime*.04)-.5);
        	break;
        case CROW_TURN:
        	col = diff;
        	break;
        case CROW_CLIMBING:
        	// IIR leaky integrator for smoothing wing power...
        	col.x = oldClimb *.99+climb *.01;
        	break;
        

    }
    fragColour = col;
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}