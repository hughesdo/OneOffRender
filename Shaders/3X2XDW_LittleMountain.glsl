#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Little Mountain
// Created by diatribes
// Shadertoy ID: 3X2XDW
// https://www.shadertoy.com/view/3X2XDW

#define F sin(p.x*.03+1.5 + sin(p.x*.06) + sin(p.z*.03)) * \
               8. + sin(p.z*.014) *15. + abs(p.x*.07)

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s=.002,d=0.,i;
    vec3 r = vec3(iResolution.xy, iResolution.y);
    u = (u-r.xy/2.)/r.y;
    vec3 p = vec3(0,0,iTime*250.),ro = p,
         D = vec3(u, 1) - vec3(sin(p.z*.002)*.2,sin(p.z*.009)*.04+.5,0);
    o -= o;
    for(i = 0.; i++ < 160. && s > .001;) {
        p = ro + D * d;
        p.x += sin(p.z*.04)*6.;
        s = (sin(p.z*.005)*64.+96.) + p.y-F*8.;
        for (float a = .05; a < 1.;
            s += abs(dot(sin(p * a * 2.), vec3(.3))) / a *.2,
            a *= 1.4);
        o += s * 5e-4+.01;
        d += s*.55;
    }
    if (d > 2e3)
        o = vec4(.1, .3, 1., .6)/(length(.5*u-.23)*.6);
    o = tanh(pow(o, vec4(.45)));
    
    fragColor = o;
}

