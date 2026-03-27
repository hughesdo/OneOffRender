#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Frunnel 9: Insomnia
// Created by diatribes
// Shadertoy ID: wcfXRf
// https://www.shadertoy.com/view/wcfXRf

#define T (4.*iTime+tanh(cos((iTime*1.5)*.2)*1.6)*10.)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define P1(z) (vec3(tanh(cos((z) * .21) * .25) * 16., \
                    tanh(cos((z) * .19) * .21) * 16.,\
                    (z)))
vec3 orb(vec3 p) {
    float t = iTime*3.;
    return p-vec3(
            P1(p.z).x+tanh(cos(t*1.1)*1.95)*.4,
            P1(p.z).y+tanh(cos(t*1.3)*1.6)*.6,
            .5+T+tanh(cos(t*.3)*1.6)*2.
        );
}

float map(vec3 p) {
    
    float s,w = 1., l;
    s = 3. - length(p.xy - P1(p.z).xy);
               
    p.xy -= P1(p.z).xy;
    p.y -= 1.5;
    p.z *= 1.5;
    
    for (int i; i++ < 16; p *= l, w *= l )
        p  = abs(sin(p)) - 1.,
        l = .9/dot(p,p);
    
    return min(s, length(p.xz)/w - .001);
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    vec2 r = iResolution.xy; 
         u = (u - r.xy / 2.) / r.y;
    vec3 p,
         ro = P1(T),
         la = P1(T+2.);
    vec3 laz = normalize(la - (orb(ro)*1.) - ro),
         lax = normalize(cross(laz, vec3(0.,-1., 0))),
         lay = cross(lax, laz),
         rd = vec3(rot(sin(T*.15)*.3)*u, 1.) * mat3(-lax, lay, laz);

    float d = 0.,s = .1;
    int i;
    for(i = 0; i++ < 80 && s > .001;
        p = ro + rd * d,
        d += s = map(p)); 
    o.rgb = vec3(1.);
    o.rgb *= exp(-length(orb(p))/.5);
    o.rgb = pow(o.rgb, vec3(.45));
    
    fragColor = o;
}

