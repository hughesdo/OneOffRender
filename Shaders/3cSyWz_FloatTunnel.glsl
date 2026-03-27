#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Float Tunnel
// Created by diatribes
// Shadertoy ID: 3cSyWz
// https://www.shadertoy.com/view/3cSyWz

#define P(z) vec3(cos((z) * .04)* 8., cos((z) * .05)* 8., (z))
#define N(x,s) abs(dot(cos(x * n), vec3(s))) / n

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,n,s=.02,d, t = iTime;
    vec3  q,
          p = P(6.*t),ro=p,
          w,
          Z = normalize( P(6.*t+1.) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3((u-iResolution.xy/2.)/iResolution.y, 1) 
              * mat3(-X, cross(X, Z), Z);
    u = (u-iResolution.xy/2.)/iResolution.y;
    for (o*=i;i++<128. && s > .01; 
         d += s = min(s,.01+.7*abs(w.y-5.)),
         o += 2./d)
        for(p = w = ro + D * d * .7,
            q = P(p.z),
            s = 14. - length(p.xy - q.xy),
            p.xy -= q.xy,
            w.z -= t*8.,
            w.xy -= q.xy,
            w.y += cos(t+w.z*.2)*.2+cos(t+w.z*.3)*.3,
            n = 1.;
            n < 4.;
            w -= N(2.*t+w, .2),
            s += N(p, .1),
            n *= 1.4);
    o *= vec4(5,2,1,0);
    o = mix(o, o.yzxw, smoothstep(0., 1., length(u)));
    o = tanh(o / abs(w.y+N(p, 16.+sin(.1*p.z)*12.)) * d /2e2);
    
    fragColor = o;
}

