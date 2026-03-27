#version 330 core

//CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/
//To the extent possible under law, Blackle Mori has waived all copyright and related or neighboring rights to this work.
// Converted for OneOffRender system

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(ax,p)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

float box(vec2 p, vec2 d) {
    p = abs(p)-d;
    return length(max(p,0.))+min(0.,max(p.x,p.y));
}

float blob(vec3 p) {
    p =asin(sin(p*10.))/10.;
    return length(p);
}

float wallthing;
float light;
float t;
float scene(vec3 p) {
    vec2 tdim = vec2(3.,1.5);
    float tdist = length(vec2(length(p.xy)-tdim.x,p.z))-tdim.y;
    
    vec3 pring = vec3(normalize(p.xy)*tdim.x,0);
    vec3 pax = normalize(cross(pring,vec3(0,0,1)));
    vec3 poff = p-pring;
    float pang = atan(pring.x,pring.y);
    float prot = sin(iTime+pang);
    poff = erot(poff,pax,prot);
    vec3 ploc = pring+poff;
    vec3 pclos = pring+normalize(poff)*tdim.y;
    
    float wdth = dot(sin(pclos*2.),cos(pclos*2.))*.5+.3;
    float blb = blob(pclos);
    wallthing = box(vec2(blb,tdist), vec2(wdth,.2))-.05;
    wallthing = min(wallthing, box(vec2(blb,tdist), vec2(.04,.4+sin(t*5.)*.2))-.01);
    vec3 rtd=vec3(asin(sin(ploc.xy*2.))/2.,ploc.z);
    float pillar = length(rtd.xy)-.02;
    pillar = min(pillar, box(vec2(pillar,asin(sin(rtd.z*10.+t*6.))/10.),vec2(0.03,0.02))-.01);
    light = length(vec2(wallthing,tdist))-.02;
    light = min(light, box(vec2(pillar,asin(sin(rtd.z*10.+t*6.+11.))/10.),vec2(0.03,0.02))-.01);
    
    wallthing *= .9;
    
    return min(min(min(-tdist,wallthing), pillar),light);
}

vec3 norm (vec3 p) {
    mat3 k = mat3(p,p,p)-mat3(0.01);
    return normalize(scene(p)-vec3(scene(k[0]),scene(k[1]),scene(k[2])));
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;

    t = iTime/60.*135.;
    t = pow(sin(fract(t)*3.1415/2.)*.5+.5,10.)+floor(t);
    vec3 cam = normalize(vec3(1.-dot(uv,uv)*.9+sin(t*1.5)*.4,uv));
    vec3 init = vec3(-3.5,0,0)+cam*.1;
    
    cam = erot(cam, vec3(1,0,0), cos(t/2.)*.5);
    cam = erot(cam, vec3(0,0,1), t/4.);
    cam = erot(cam, vec3(0,0,1), .7+sin(t)*.5);
    init = erot(init, vec3(0,0,1), t/4.);
    
    
    vec3 p = init;
    bool hit = false;
    float dist;
    float glo = 0.;
    for (int i = 0; i < 200 && !hit; i++) {
        dist = scene(p);
        hit = dist*dist < 1e-6;
        glo += .05/(1.+abs(light)*30.);
        p+=dist*cam*.7;
    }
    bool wt = wallthing == dist;
    bool lt = light == dist;
    vec3 n = norm(p);
    vec3 r = reflect(cam,n);
    float ao = smoothstep(-.1,.1,scene(p+n*.1));
    float ro = smoothstep(-.1,.1,scene(p+r*.1));
    float spec = length(sin(r*3.)*.5+.5)/sqrt(3.);
    float diff = length(sin(n*2.)*.4+.6)/sqrt(3.);
    float fres = 1.-abs(dot(n,cam))*.98;
    vec3 matcol = wt ? vec3(0.9,0.2,0.8) : vec3(0.04);
    vec3 col = diff*matcol*ao + pow(spec,10.)*fres*ro;
    col = abs(erot(col, normalize(sin(p*2.+iTime*2.+r)),1.));
    if (lt) col = vec3(1);
    fragColor.xyz = hit ? col : vec3(0.01);
    fragColor.xyz = sqrt(fragColor.xyz+ glo*glo + glo*vec3(.2,.5,1));
    fragColor.xyz *= 1.-dot(uv,uv)*.7;
    fragColor.xyz *= 1.1;
    fragColor.xyz = smoothstep(0.,1.,fragColor.xyz);
}