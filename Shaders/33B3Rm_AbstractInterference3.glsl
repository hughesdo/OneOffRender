#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Abstract Interference 3
// Created by diatribes
// Shadertoy ID: 33B3Rm
// https://www.shadertoy.com/view/33B3Rm

#define W 1.75
#define H 1.75
#define L (25. + orb(p))

#define T ((sin(iTime*.2)+iTime*.2)) * 4.
#define rot(a) mat2(cos(a+vec4(0,33,11,0)))

#define P(z) (vec3(tanh(cos((z) * .3) * .4) * 6., \
                   tanh(cos((z) * .4) * .3) * 6., (z)))

float tunnel(vec3 p) {
    return .375 - length(p.xy - P(p.z).xy);
}

// o
float orb(vec3 p) {
    float t = T*2.5;
    return length(p - vec3(
            P(p.z).x+tanh(sin(p.z*1.7) * 1.25)*.25,
            P(p.z).y+sin(sin(p.z*.35)*2.5) *.2,
            1.+T+tan(cos(t*.15))*.75));
}

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    bool orbHit = false;
    float d = 0., i, s=.002, l, w, ws;
    vec3  e = vec3(.005,0,0);
    u = (u-iResolution.xy/2.)/iResolution.y;
    vec3  p = P(T),ro=p,
          Z = normalize( P(T+2.) - p)+sin(T)*.1,
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3( rot(sin(T*.3)) *u, 1) 
             * .8  * mat3(-X, cross(X, Z), Z);
    o-=o;
    
    // raymarch tunnel
    for(i = 0.; i++ < L && s > .001;)
        p = ro + D * d,
        d += (s = min(tunnel(p), orb(p)-.05))*.5,
        orbHit = s == orb(p) - .05,
        o.rgb += sin(p)*.01+.01;

    
    float orbDist;
    float tunnelDist = d;

    if (orbHit) {
        o.rgb += vec3(3,0,0);
        o.rgb = mix(o.rgb,abs(sin(p*8.) / dot(sin(iTime+p*128.),vec3(.5))),.9);
    } else {
        ro = p, s=.002,d=0.;
        for(int i = 0; i++<120 && s > .001;) {
            p = ro + D * d;
            orbDist = orb(p)-.05;
            p.x -= 1.5;
            w = (sin(p.z)*.15+.45);
            ws = .035;
            for (int j; j++ < 8; p *= l, w *= l )
                p  = abs(sin(p)) - 1.,
                l = (1.+ws)/dot(p,p),
                ws += ws;
            s = min(length(p)/w, orbDist);
            orbHit = s == orbDist,
            d += s;
            o.rgb += sin(p*log(l))*.06+.025;
            D += cross(D, o.rgb)*.001;
            if (orbHit) o.rgb += sin(p)*.03+.135;
        }
        o.rgb /= orbDist;
    }
    o.rgb *= exp(-(tunnelDist+d)/2.);
    o.rgb = pow(o.rgb, vec3(.45));
    
    fragColor = o;
}

