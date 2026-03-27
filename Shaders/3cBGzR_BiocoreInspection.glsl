#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Biocore Inspection
// Created by diatribes
// Shadertoy ID: 3cBGzR
// https://www.shadertoy.com/view/3cBGzR

// Rounded cylinder sdf from iq
// https://iquilezles.org/articles/distfunctions/

#define T (iTime * 7.)
#define path(z) (vec3(tanh(cos((z) * .09) * .35) * 11., \
                      tanh(cos((z) * .1) * .23) * 12., (z)))
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

float sdRoundedCylinder( vec3 p, float ra, float rb, float h ){
    vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    vec2 r = iResolution.xy; 
         u = (u - r.xy / 2.) / r.y;
    vec3 p,
         ro = path(T),
         la = path(T+.1);
    vec3 laz = normalize(la - ro),
         lax = normalize(cross(laz, vec3(0.,- 1., 0))),
         lay = cross(lax, laz),
         rgb, disc;
    vec3 rd = vec3(rot(sin(T*.05)*.5)*u, 1.) * mat3(-lax, lay, laz);
    float d = 0.,s, tx, ty, rails, c, dd;
    do {
        p = ro + rd * d;
        disc = p - vec3(path(p.z).xy,
                        18.+T+tan(cos(T*.03)*1.)*10.);
        
        // rotated for tubes
        vec3 rp = p;
        rp.xy *= rot(sin(p.z*.2)*.4);
        p.xy -= rp.xy*.5;
        
        // tubes
        rails = length(
           (mod(vec3(rp.xy - path(rp.z).xy,rp.z),2.5) - .5*2.5).xy
        ) - .1;
        
        // walls
        tx = 3.-length(p.x- path(p.z).x);
        ty = 3.-length(p.y- path(p.z).y);

        // hit
        s = min(sdRoundedCylinder(disc,.225,.05,.025), min(rails, min(tx, ty)));
        d += s;
    } while(d < 100. && s > .001);
        
    // disc
    dd = length(disc)-.3;
         
    p = sin(ro + rd * d);

    for (float i = 0.; i < 4.; i++) {
        float n = abs(p.x*p.y*p.z*c);
        p  = abs(p)/clamp(n,.4,.7)-1.75;
        c += dot(sin(p.xy), vec2(1.));
    }  
    c = abs(sin(p.x)+sin(p.y)+sin(c));
    rgb = vec3((s==rails?.75:0.)+c+sin(p.z*.2),c*cos(p.z*.1),s==dd?1.:c);
    rgb = rgb/pow(dd,2.25);
    o = d>150.?vec4(.02):vec4(pow(rgb, vec3(.45)), 1.);
    
    fragColor = o;
}

