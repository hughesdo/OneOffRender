#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Parasitic End
// Created by diatribes
// Shadertoy ID: 3XlfWX
// https://www.shadertoy.com/view/3XlfWX

#define T iTime

vec3 rgb = vec3(0);

float M(vec3 p) {
    float t = T,
          g = dot(sin(1.35*p*.3)+sin(p),cos(t+p))+
              dot(sin(1.6*p*1.3),cos(p*2.4)),
    s = (sin(t)*1.)+4. - length(p)-g*.2;
    
    p.z += T * .2;
    for (float a = .01; a < 1.;
        s -= abs(dot(sin(p/a), vec3(.3))) * a,
        a += a);
    
    vec3 q = p;
    float qs = 0.;
    
    q.xy *= mat2(cos(.3*t+q.z*.6+vec4(0,33,11,0)));
    
    q.y += sin(p.z)*g*.25 + sin(12.*t+p.z*6.)*.1
        + sin(p.z)*g*.15 + sin(4.*t+p.z*2.)*.1;
    for (float a = .5; a < 4.;
        qs -= abs(dot(sin(t+t+p * a *16.), vec3(.01))) / a,
        a += a);
    s = min(s, qs+length(
        (mod(q,1.) - .5).xy
    ) - .1);
    
    return s;
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,d,s;
    vec3  p = vec3(iResolution.xy, iResolution.y);
    u = (u-p.xy/2.)/p.y;
    for(o*=i; i++<128.;
        d += s = M(p),
        o += vec4(1,2,5,0)/s)
        p = vec3(u*d,d+T*.5);
    o = tanh(o / 1e3);
    
    fragColor = o;
}

