#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Frunnel 5: Glow Flip
// Created by diatribes
// Shadertoy ID: 3fsSDM
// https://www.shadertoy.com/view/3fsSDM

#define T (iTime*1.)
#define DIST_MAX 55.
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define P1(z) (vec3(tanh(cos((z) * .21) * .25) * 15., \
                    tanh(cos((z) * .39) * .24) * 32., (z)))
float map(vec3 p) {
    p.xy -= P1(p.z).xy;
    float s = 3.5 - length(p.xy);
    p.xy = mod(p.xy+1., 6.) - 3.;
    p.x -= 1.3;
    p.y += .3;
    p.z = mod(p.z, 6.) - 3.;
    vec4 q = vec4(p, 1.);
    for (float i = 0.; i < 8.; i++) {
        q.xyz  = abs(sin(q.xyz)) - 1.;
        q = 1.3*q/pow(length(q.xyz),2.) -
            vec4(.0, .0, .0, 0.);
    } 
    return min(s,length(q.xyz)/q.w - .01);
}

vec3 normal(vec3 p) {
    vec2 e = vec2(.01, 0);
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
         u = (u - r.xy / 2.) / r.x;
    vec4 q;
    vec3 p,
         ro = P1(T),
         la = P1(T+4.);
    vec3 laz = normalize(la - ro),
         lax = normalize(cross(laz, vec3(0.,-1., 0))),
         lay = cross(lax, laz),
         rd = vec3(rot(sin(T*.5)*.5)*u, 1.) * mat3(-lax, lay, laz);
    float d = 0.,s;
    float steps = 0.;
    do{
        p = ro + rd * d;
        s = map(p);
        d += s;
        steps++;
    } while (steps < 100. && d < DIST_MAX && s > .01);
    vec3 f = sin(p*10.)*.1;
    for (float i = 0.; i < 5.; i++) {
        float n = abs(f.x*f.y*f.z);
        f  = abs(f)/clamp(n,.5, .8);
    }
    o.rgb = vec3(1.)*max(dot(normal(p), normalize(ro-p)), .0);
    p = sin(p);
    o.rgb = mix(f,abs(p / dot(sin(p*8.),vec3(2./d))),.6);
    o.rgb *= exp(-d/.7);
    o.rgb = pow(o.rgb, vec3(.45));
    
    fragColor = o;
}

