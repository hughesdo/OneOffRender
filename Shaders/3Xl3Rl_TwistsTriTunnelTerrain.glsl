#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Twists Tri Tunnel Terrain
// Created by diatribes
// Shadertoy ID: 3Xl3Rl
// https://www.shadertoy.com/view/3Xl3Rl

#define T (iTime*1.75)
#define P(z) (vec3(tanh(cos((z) * .2) * .3) * 16., \
                5.+tanh(cos((z) * .1) * .6) * 16., (z)))
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize

vec3 tri(in vec3 x){return abs(x-floor(x)-.5);}

vec3 rgb = vec3(0);

float triSurface(vec3 p) {
    return (1. -  dot(tri(p*.25+tri(p*.2))+
                      tri(p)*.2,
                      vec3(1.5)));
}

float orb(vec3 p) {
    float t = T*.5;
    return length(p - vec3(
            P(p.z).x+tanh(sin(p.z*.7) * 1.25)*.5,
            P(p.z).y+sin(sin(p.z*.5)*2.5) *.75,
            3.5+T+tan(cos(t*.25))*3.));
}

float spiral(vec3 p, float xoffs, float yoffs,
             float gap) {
    p.xy -= P(p.z).xy;
    p.x += xoffs;
    p.y += yoffs;
    p.z = mod(p.z,gap) - gap/2.;
    return length(p)-.3;
}

float map(vec3 p) {
    float n, s = (sin(p.z*.2)*.5+.8)  - length(p.xy - P(p.z).xy);
    for (n = .175; n < 2.;
        s -= abs(dot(sin(p * n *32.), vec3(.007))) / n,
        n += n);
    s += triSurface(p)*.5;
    s = min(s, orb(p)-.1);
    s = min(s, spiral(p, 3., 0., 6.));
    s = min(s, spiral(p, -3., 0., 6.));
    s = min(s, spiral(p, 0., 3., 6.));
    s = min(s, spiral(p, 0., -3., 6.));
    return s;
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s,d,i;
    vec3  r = vec3(iResolution.xy, iResolution.y),
          e = vec3(.001,0,0),
          p = P(T),ro=p,
          Z = N( P(T+1.) - p),
          X = N(vec3(Z.z,0,-Z)),
          D = vec3(rot(sin(T*.1)*.3)*(u-r.xy/2.)/r.y, 1) 
             * mat3(-X, cross(X, Z), Z);
    o = vec4(0);
    for(;i++ < 128. && d < 1e2;)
        p = ro + D * d,
        d += s = .001+.75*abs(map(p)),
        o += vec4(2,1,5,0)/s;
    vec3 n = map(p) - vec3(
        map(p-e.xyy),
        map(p-e.yxy),
        map(p-e.yyx));
    o.rgb *= max(dot(N(n), N(ro-p)), .0);
    o = tanh(o/2e5);
    
    fragColor = o;
}

