#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// 3 from 1 Tunnel
// Created by diatribes
// Shadertoy ID: 3cS3WG
// https://www.shadertoy.com/view/3cS3WG

#define T (iTime * 8.)
#define P(z) (vec3(tanh(cos((z) * .1) * .4) * 12., \
                      tanh(cos((z) * .13) * .3) * 8., (z)))
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define R 1.25

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    vec2 r = iResolution.xy; 
         u = (u - r.xy / 2.) / r.y;
    vec3 p,
         ro = P(T),
         la = P(T+2.);
    vec3 laz = normalize(la - ro),
         lax = cross(laz, vec3(0.,-1., 0)),
         lay = cross(lax, laz),
         rd = vec3(rot(sin(T*.03)*1.5)*u, 1.) * mat3(-lax, lay, laz);
    float d = 0.,s;
    do {
        p = ro + rd * d;
        s = R - min(length(p.xy - P(p.z).x + R*.75),
                min(length(p.xy - P(p.z).xy),
                    length(p.xy - P(p.z).y + R*.75)));
        d += s;
    } while(d < 100. && s > .01);
    p = ro + rd * d;
    o = vec4(pow(abs(p / dot(sin(p),vec3(d))),vec3(.45)), 1);
    
    fragColor = o;
}

