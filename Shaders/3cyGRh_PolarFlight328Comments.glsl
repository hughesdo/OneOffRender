#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Polar Flight (328) Comments
// Created by diatribes
// Shadertoy ID: 3cyGRh
// https://www.shadertoy.com/view/3cyGRh

/*
    Playing with turbulence and translucency from
    @Xor's recent shaders, e.g.
        https://www.shadertoy.com/view/wXjSRt
        https://www.shadertoy.com/view/wXSXzV


    The general idea is two planes, clouds and ground.
    one noise loop distorts them a little differently
    to make something that resembles translucent
    mountains and clouds.
*/

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,d,s,t=iTime*3.;
    vec3  q,p;
    u = (u-iResolution.xy/2.)/iResolution.y;
    for(o*=i; i++<128.;
    
        // Accumulate dist, get signed dist to two planes (q.y and p.y)
        // note dist is abs()'d and attenuated:  a + abs(s) * b
        d += s = .01 + min(.02+abs(9.- q.y)*.1,.01+abs(5.+p.y)*.2),
        
        // Grayscale color
        o += 1. / s)
        
        // march, it's just p = ro + rd * d
        for (q = p = vec3(u*d,d+t),
             
             // start noise at .01, up to 2.
             s = .01; s < 2.;
             
             // the mountain plane is turbulence + noise
             // could #define the abs() stuff to golf further
             // cos() is the turbulence, abs() is the noise
             p += cos(p.yzx*.2)*.3+abs(dot(sin(p * s *32.), vec3(.007))) / s,
             
             // the cloud plane is just noise
             // could #define the abs() stuff to golf further
             q += abs(dot(sin(.2*t+q * s * 32.), vec3(.005))) / s,
             
             // increment noise
             s += s);
             
    // tanh() to tonemap, divide brightness down
    o = tanh(o / 1e3);
    
    fragColor = o;
}

