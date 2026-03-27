#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Plasma Cathederal
// Created by diatribes
// Shadertoy ID: 3f23RK
// https://www.shadertoy.com/view/3f23RK

#define T (iTime * 6.)
#define path1(z) (vec3(tanh(cos((z) * .05) * 1.2) * 6., \
                      tanh(cos((z) * .03) * 1.2) * 6., (z))) 
#define path2(z) (vec3(path1(z).xy+sin(z*.02)*.1, z+sin(z*.03))) 

#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
float length2(vec2 p){
    p = pow(abs(p), vec2(10.));
    return pow(p.x + p.y, 1./10.);
}

vec3 plasma(vec3 p) {
    float t = p.z + sin(T*.1);
    p *= 10.;
    float r = distance(p.xz, vec2(sin(t), sin(t)));
    float g = distance(p.xz, vec2(0, 3.));
    float b = distance(p.xz, vec2(r, sin(t)*25.));
    float value = abs(sin(r+t) + sin(g+t) + sin(b+t) + sin(p.x+t) + cos(p.y+t));
    return vec3(r,g,b)/value*.15;
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    vec2 r = iResolution.xy; 
         u = (u - r.xy / 2.) / r.x;
    vec3 p,
         ro = path1(T),
         la = path1(T+5.);
    vec3 laz = normalize(la - ro) *.6,
         lax = normalize(cross(laz, vec3(0.,-1., 0))),
         lay = cross(lax, laz);
    vec3 rd = vec3(rot(sin(T*.03)*.5)*u, 1.) * mat3(-lax, lay, laz);
    float d = 0.,s;
    do {
        p = ro + rd * d;
        
        s = 4. - min(length2(p.xy - path1(p.z).xy),
                     length(p.xy - path2(p.z).xy)) +
                     dot(sin(p * .03)*2.7, sin(p*.15));
        d += s;
    } while(d < 200. && s > .01);
    vec3 sp = sin(p);
    vec3 f = abs(sin(sp+p)) / 
             clamp(abs(sp.x*sp.y),
                   abs(sp.y*sp.z)*.1+.4,
                   abs(sp.z*sp.y) - sin(sp.z)) * 10.;
    o =vec4(pow(
                plasma(sp)*abs(f)/d,
                vec3(.45)
            ), 1.
       );

    o = vec4(pow(o.rgb, vec3(.45)), 1.);
    
    fragColor = o;
}

