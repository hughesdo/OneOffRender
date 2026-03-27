#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Fractal Pew Pew
// Created by diatribes
// Shadertoy ID: 3fXXzH
// https://www.shadertoy.com/view/3fXXzH

// I started with a minimal/deconstructed version
// of Tangled Sierpinski by pb here
// https://www.shadertoy.com/view/NsXcDs
// thanks @pb :)

// Fractals are crazy, you change the slightest thing
// and it's a completely different image

#define T (iTime*1.)
#define DIST_MAX 25.
#define P1(z) (vec3(0., 0., (z)))

float map(vec3 p) {
    const float mscale = 2.05;
    p = mod(p + 1.0, 2.0) - 1.0;
    vec4 q = vec4(p, 1.0);
    for(int i = 0; i < 15; i++) {
        q.xyz = abs(q.xyz);
        q = q/pow(length(q.xyz),2.);
        q *= mscale;
        q.xyz -= .45;
    }
    return length(q.xyz)/q.w - .001;
}

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    vec2 r = iResolution.xy; 
         u = (u - r.xy / 2.) / r.x;
    vec3 p,
         ro = P1(T),
         la = P1(T+1.);
    vec3 laz = normalize(la - ro),
         lax = normalize(cross(laz, vec3(0.,-1., 0))),
         lay = cross(lax, laz),
         rd = vec3(u, 1.);
    float d = 0.,s,steps=0.;
    do{
        p = ro + rd * d;
        s = map(p);
        d += (s+d*.01);
        steps++;

    } while (steps < 100. && d < DIST_MAX && s > .001);

    vec3 c = vec3(.5,.25, .5);
    c += sin(d)+sin(p);
    o = vec4(vec3(c/d), 1.);
    o.rgb = pow(o.rgb, vec3(.4154545));
    
    fragColor = o;
}

