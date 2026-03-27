#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Digital Phoenix
// Created by diatribes
// Shadertoy ID: 3XlBRH
// https://www.shadertoy.com/view/3XlBRH

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,x,d=1e1,s,r,t = iTime;
    vec3 p = vec3(iResolution.xy, iResolution.y);
    u = (u-p.xy/2.)/p.y;
    for(o*=i; i++<64.;
        d += s = min(.004+.6*abs(x), .015+.6*abs(6. - length(p.xy*.2))),
        o += vec4(9,4,2,0)/s*d/1e1)
        for(p = vec3(u * d, d),
            x = sin(t)*2.+4.+(64. + 32. * sin(t+t))*u.y - abs(p.x),
            p.z += t*1e1,
            s = .01; s < 1.; s += s )
                p.yz += abs(dot(round(sin(p.x+p.y+t + .2*p / s )), vec3(5))) * s,
                x    -= abs(dot(round(sin(p.x+p.y+t + .5*p / s )), vec3(1))) * s,
                p.y--;
    o = tanh(o*o/2e9*exp(d/16.));
    
    fragColor = o;
}

