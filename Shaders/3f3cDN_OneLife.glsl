#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// One Life
// Created by diatribes
// Shadertoy ID: 3f3cDN
// https://www.shadertoy.com/view/3f3cDN

// golf welcome
// 32 steps so hope it runs well for you :)

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    
    float i,d,s,t = iTime;
    
    vec3 p;
    
    u = (u+u-iResolution.xy)/iResolution.y;
    
    u += vec2(cos(t*.4)*.1, cos(t*.3)*.05);
        
    for(o=vec4(0); i++<32.;) {
        p = vec3(u * d, d + t * 4.);
        
        for(s = .01; s < 1.; s += s )
            p.yz -= abs(dot(sin(t+.22*p / s ), vec3(s)));
        
        p *= vec3(.2, .6, 1),
        d += s = .25+.4*abs(5. - length(p.xy)),
        o += 1./s + .3*vec4(1,2,5,0)/length(u);
    }
    
    o = tanh(mix(o=vec4(8,2,1,0)*o*o/4e4,
                 o.yzxw, smoothstep(.2, 1., length(u))));
    
    fragColor = o;
}

