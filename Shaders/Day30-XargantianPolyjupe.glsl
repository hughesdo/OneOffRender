#version 330 core

// Original author: jeyko
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/tlG3RV
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// https://www.shadertoy.com/view/tlG3RV
// Modified by ArthurTent
// Created by jeyko
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/

#define mx (10.*vec4(iResolution.xy * 0.5, 0.0, 0.0).x/iResolution.y)
#define TIME_OFFSET (iTime - 25. + mx)
vec3 getRd(vec3 ro,vec3 lookAt,vec2 uv){
	vec3 dir = normalize(lookAt - ro);
	vec3 right = normalize(cross(vec3(0,1,0), dir));
	vec3 up = normalize(cross(dir, right));
	return dir + right*uv.x + up*uv.y;
}
#define dmin(a,b) a.x < b.x ? a : b
#define pmod(p,x) mod(p, x) - x*0.5

vec4 r14c(float i){return texture(iChannel0, vec2(i));}

float sdBox(vec3 p, vec3 s){
	p = abs(p) - s;
    return max(p.x, max(p.y, p.z));
}
#define pi acos(-1.)
#define tau (2.*pi)
#define rot(x) mat2(cos(x),-sin(x),sin(x),cos(x))
#define tunnRotRate

vec2 id;
vec2 map(vec3 p){
	vec2 d = (vec2(10e7));

    p.xy *= rot(0. + p.z*0.1 + 0.1*TIME_OFFSET);


    for (float i = 0.; i < 4.; i++){
    	p = abs(p);
    	p.xy *= rot(0.4*pi );
        p.x -= 0.2;
        p.x *= 1. + 0.4*atan(p.x, p.y)/pi;
        //p.y += 0.1;
    }

    p.xy -= 2.0;


    p.y = abs(p.y);


    p.y -= 1. + sin(TIME_OFFSET*0.1)*0.2;

    #define modSz 0.5
    id = floor(p.xz/modSz);
    //vec2

    p.xy -= 0.8;
    p.xz = pmod(p.xz, modSz);

    for (float i = 0.; i < 5.; i++){
    	p = abs(p);
        p.y -= 0.28 - sin(TIME_OFFSET*0.2)*0.08 - 0.1;
        p.x += 0.04;
    	p.xy *= rot(0.6*pi + id.y*6.  + 0.9);
        if (i == 3.){
        	p.xz *= rot(TIME_OFFSET*2. + id.y);
        }
    }

    d = dmin(d, vec2(sdBox(p, vec3(modSz*0.25 + sin(TIME_OFFSET*0.26)*0.1)), 1.));

    d.x *= 0.25;
    return d;
}
/*
vec3 getNormal(vec3 p){
	vec2 t = vec2(0.001,0);
    return normalize(map(p).x - vec3(
    	map(p - t.xyy).x,
    	map(p - t.yxy).x,
    	map(p - t.yyx).x
    ));
}*/

vec3 glow = vec3(0);

//#define pal(q,w,e,r,t) (q + w*sin(e*r + t))
void main(  )
{
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    //vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;
    vec2 uv = -1.0 + 2.0* (fragCoord / iResolution);

    vec3 col = vec3(0);

    vec3 ro = vec3(0.,0,0);
    ro.z += TIME_OFFSET*3. + mx;

    float rate = ro.z*0.1 + 0.1*TIME_OFFSET;

    ro.xy += vec2(sin(rate), cos(rate))*2.;

    vec3 lookAt = ro + vec3(0,0,4);
    float rotRate = TIME_OFFSET*0.3 + sin(TIME_OFFSET*0.3)*0.0;
    lookAt.xz += vec2(
    	sin(rotRate),
    	cos(rotRate)
    );

    vec3 rd = getRd(ro, lookAt, uv);

    vec3 p = ro; float t = 0.;
    for (int i = 0; i < 250; i++){
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    	vec2 d = map(p);
        #define pal(q,w,e,r,t) (q + w*cos( tau*(e*r + t))
        //glow += exp(-d.x*70.)* pal(vec3(0.5,0.6,0.7)*1., 0.35, id.y*0.2 + iTime*0.4 + 1.*p.z*(sin(iTime)*0.001), vec3(0.4, 0.9,0.2), 0. + p.z*0.02));
        //glow += exp(-d.x*20.)* pal(vec3(0.5,0.6,0.7)*1., 0.45, id.y*0.2 + iTime*0.4 + 0.*p.z*(sin(iTime)*0.001), vec3(0.4, 0.9,0.2), 0. + p.z*0.02));
        //zglow += exp(-d.x*20.)* pal(vec3(0.5,0.6,0.7)*0.2, 0.95, id.y*0.05 + iTime*1. + 0.*p.z*(sin(iTime)*0.001), vec3(0.1, 0.9,0.2), 0.5 + p.z*0.02));
        //glow += exp(-d.x*60.)* pal(0.5, 0.45, id.y*0.2 + iTime*2., vec3(0.1, 0.4,0.8), 0.5)) ;
        glow += exp(-d.x*60.)* pal(1., 0.95, id.y*0.004 , vec3(0.4, 0.97,0.9), 0.9 + p.z*0.02 + TIME_OFFSET*.1)) ;
        if(d.x < 0.0005){
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

            /*
            vec3 n = getNormal(p);
            vec3 l = normalize(vec3(1));
            vec3 h = normalize(l - rd);
            float diff = max(dot(n,l),0.);
            float spec = max(dot(n,h),0.);
            float fres = pow(1. - max(dot(n,-rd), 0.),5.);
            */
            //col += fres*diff*3.;

        	break;
        }
        if (t > 100.){
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

        	break;
        }
        t += d.x;
        p = ro + rd*t;
    }

    float bass = pow(texture(iChannel0, vec2(0.,0.14)).x, 4.);
    float mid = pow(texture(iChannel0, vec2(0.,0.5)).x, 4.);
    float high = pow(texture(iChannel0, vec2(0.,0.86)).x, 4.);

    col += glow*(0.01 + bass*0.1 + mid*0.1 + high*0.1);

    col = mix(col, vec3(0), pow(clamp(t*.02 - 0.1, 0., 1.), 2.));
    //col = mix(col, vec3(0), pow(clamp(t*.02 - 0.1+bass, 0.+mid, 1.+high), 2.));
    col = smoothstep(0.,1., col);
    //col = smoothstep(0.,1., col);

    //col = pow(col , vec3(1.8,1.0,1.));


    //col.g = pow(col.g, 2. - 0.5*( col.r + col.b*0.1));

    fragColor = vec4(col,1.0);
}
