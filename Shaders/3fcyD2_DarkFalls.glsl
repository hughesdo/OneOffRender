#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Dark Falls
// Created by diatribes
// Shadertoy ID: 3fcyD2
// https://www.shadertoy.com/view/3fcyD2

float mist(vec3 p) {
    
    float i,d,s,t = iTime;
    vec4 o = vec4(0);
    mat2 r = mat2(cos(1.2+vec4(0,33,11,0)));
    
    p.z -= 4e1;
    p.yz *= r;
    p.z += t*2e1;

    for(s = .03; s < 4.; s += s )
        p.yz -= abs(dot(sin(.5*t+.32*p / s ), vec3(s)));

    p *= vec3(.2, .6, 1),
    d += s = .1+.2*abs(2. - length(p.xy));
    return s;
    
}


void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float w,d,a,i,s,t = iTime*.5;
    vec3  p = vec3(iResolution.xy, iResolution.y);    
    u = (u+u-p.xy)/p.y;
    
    if (abs(u.x) > 1.25) { o *= 0.; fragColor = o; return; }
 
    for(o*=i; i++<1e2;
        d += s = min(w, .1+.3*abs(s)),
        o += mix(5e3/(s), 1e1/w, .98))
        for(p = vec3(u*d,d),
            w = mist(p),
            s = 2e1 - abs(p.x),
            a = .03; a < 1.; a += a)
            s += abs(dot(sin(.05*p.z+.2*p / a ), a+a+p-p));
    
    o = tanh(o*o/4e9+.1);
    
    fragColor = o;
}

