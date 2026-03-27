#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Bit Falls
// Created by diatribes
// Shadertoy ID: 3XjBWD
// https://www.shadertoy.com/view/3XjBWD

// I couldn't decide between 32. and 64. so this is what's happening now
#define PIXEL 42.

/*
    @moonlightoctopus and @msm01 gave me a couple tips,
    pixelate & posterize; i just took an old shader i had
    and added them to that, then tried to comment very
    soupy code i made a while ago D:
*/

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i, d, s, s1, s2, n, t=iTime*.65;
    vec3 p, q;
    
    // pixelate, ty @moonlightoctopus
    u = floor((u-iResolution.xy/2.)/iResolution.y*PIXEL)/PIXEL;
    
    for(o*=i; i++<128.; ) {
        // q = p = ro + rd * d
        q = p = vec3(u * d, d);
        
        // move water
        q.z += t*8.;
        
        // positon z
        p.z += 1e2;
        
        // position y
        p.y -= 1e1;
        
        // sample earth
        s2 = 50. + p.y - abs(cos(p.x*.1)*p.x*1.);
        
        // warp xy by z
        p.xy -= cos(vec2(.1,.2)*p.z*.09)*14.;
        
        // water turbulence
        p += cos(p.yzx)*.5;
        
        // sample water
        s1 = 47. + p.y - length(p.y);
        
        // noise
        for (n = .09; n < 4.; n += n )
            s2 += abs(dot(sin(p*n*1.), vec3(.23))) / n,
            s1 += abs(dot(sin(t+q*n*4.), vec3(.13))) / n;
            
        // distance to earth or water
        d += s = .001+abs(min(s1,s2))*.1;
        o += s/d;
    }
    
    // position moon
    u -= vec2(.1, .3);
    
    // colorize, moon, dist fade
    o = 1.5*(vec4(s1 > s2?6:4,5, s1 > s2?5:8,1)*o/d/length(u)*exp(-d/4e2));
    
    // posterize, ty @msm01
    o = tanh(0.2*floor(8.0*o));
    
    fragColor = o;
}

