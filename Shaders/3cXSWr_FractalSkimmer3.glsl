#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Fractal Skimmer 3
// Created by diatribes
// Shadertoy ID: 3cXSWr
// https://www.shadertoy.com/view/3cXSWr

// I started with a minimal/deconstructed version
// of Tangled Sierpinski by pb here
// https://www.shadertoy.com/view/NsXcDs
// thanks @pb :)

// Fractals are crazy, you change the slightest thing
// and it's a completely different image

#define T (iTime*3.)
#define DIST_MAX 36.
#define P1(z) (vec3(tanh(cos((z) * .37) * .17) * 1.5, 2.+sin(T*.2)*.35, (z)))
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

vec3 plasma(vec3 p) {
    float t = p.z ;
    p *= 10.;
    float r = distance(p.xz, vec2(sin(t), sin(t)));
    float g = distance(p.xz, vec2(0, 3.));
    float b = distance(p.xz, vec2(r, sin(t)*25.));
    float value = abs(sin(r+t) + sin(g+t) + sin(b+t) + sin(p.x+t) + cos(p.y+t));
    return vec3(r,g,b)/value*.125;
}

float map(vec3 p) {
    const float mscale = 3.75;
    
    p.xy = mod(p.xy, 2.0) - 1.;
    p.z = mod(p.z, 4.) - 2.;
    vec4 q = vec4(p, 1.);
    for (float i = 0.; i < 18.; i++) {
        q.xyz  = abs(q.xyz)-1.;
        q += mscale*q/clamp(pow(length(q.xyz),2.), .1, 9.);
    } 
    float s = length(q.xyz)/q.w - .001;
              

    return s;
}

vec3 normal(vec3 p) {
    vec2 e = vec2(.1, 0);
    vec3 n = map(p) - vec3(
        map(p-e.xyy),
        map(p-e.yxy),
        map(p-e.yyx));

    return normalize(n);
}

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    vec2 r = iResolution.xy; 
         u = (u - r.xy / 2.) / r.y;
    vec3 p,
         ro = P1(T),
         la = P1(T+4.);
    vec3 laz = normalize(la - ro),
         lax = normalize(cross(laz, vec3(0.,-1., 0))),
         lay = cross(lax, laz),
         rd = vec3(rot(sin(T*.15)*.25)*u, 1.) * mat3(-lax, lay, laz);
    float d = 0.,s;
    float steps = 0.;
    do{
        p = ro + rd * d;
        s = map(p);
        d += s;
        steps++;
    } while (steps < 75. && d < DIST_MAX && s > .001);
    if (d < DIST_MAX && steps < 75.) {
        vec3 c = vec3(.1,.25, .5);
        c += sin(p)+sin(p.x)+sin(p.y)+sin(p.z);
        o.rgb = c*vec3(c/d);
        o.rgb *= plasma(sin(2.*p+T*.1));
        
        o.rgb = pow(o.rgb/d, vec3(.45));
    } else {
        o.rgb = plasma(sin(p));
    }
    
    fragColor = o;
}

