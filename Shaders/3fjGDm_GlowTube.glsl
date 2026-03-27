#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Glow Tube
// Created by diatribes
// Shadertoy ID: 3fjGDm
// https://www.shadertoy.com/view/3fjGDm

#define T (iTime * 10.)
#define path1(z) (vec3(tanh(cos((z) * .04) * 1.) * 16., \
                      tanh(cos((z) * .03) * 1.2) * 6., (z)))  
#define path2(z) (vec3(tanh(cos((z) * .247) * 2.) * 12., \
                      tanh(cos((z) * .07) * .5) * 12., (z)))
           
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

float map(vec3 p, out vec3 rgb) {
    vec3 sp = sin(p);
    sp = abs(sin(sp+p))/clamp(abs(sp.x*sp.y),
                       abs(sp.y*sp.z)+sin(p.x),
                       abs(sp.z*sp.y)+cos(p.y) -
                       sin(sp.z)) * 6.;
    sp = abs(sp);
    sp *= sin(sp.x)+sin(sp.y)+sin(sp.z);
    rgb = abs(sp);
    return 3. - min(length(p.xy - path1(p.z).xy),
                 length(p.y - path2(p.z).y+4.));
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    vec2 r = iResolution.xy; 
         u = (u - r.xy / 2.) / r.x;
    vec3 p, rgb,
         ro = path1(T),
         la = path1(T+5.);
    vec3 laz = normalize(la - ro) *.6,
         lax = normalize(cross(laz, vec3(0.,-1., 0))),
         lay = cross(lax, laz);
    vec3 rd = vec3(rot(sin(T*.02)*1.35)*u, 1.) * mat3(-lax, lay, laz);
    float d = 0.,s;
    do {
        p = ro + rd * d;
        s = map(p, rgb);
        d += s;
    } while(d < 150. && s > .01);
    o.rgb = rgb*vec3(d+s);
    o.rgb /= pow(d,2.25);
    o = vec4(pow(o.rgb, vec3(.45)), 1.) - dot(u,u)*.4;
    
    fragColor = o;
}

