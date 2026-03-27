#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Mycorrhizae [294]
// Created by diatribes
// Shadertoy ID: 33VGzW
// https://www.shadertoy.com/view/33VGzW

/*
        -1 chars from @FabriceNeyret2
        
        Thanks!  :D
*/

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i, // iterator
          d, // total distance
          s, // signed distance
          n, // noise iterator
          t = iTime;
    // p is temporarily resolution,
    // then raymarch position
    vec3 p;
    
    // scale coords
    u = (u-iResolution.xy/2.)/iResolution.y;
    
    // clear o, up to 100, accumulate distance, grayscale color
    for(o*=i; i++<1e2;d += s = .01+abs(s)*.8, o += 1./s)
        // march, equivalent to p = ro + rd * d, p.z += d+t+t
        for (p = vec3(u * d, d+t+t),
             // twist by p.z, equivalent to p.xy *= rot(p.z*.2)
             p.xy *= mat2(cos(p.z*.2+vec4(0,33,11,0))),
             // dist to our spiral'ish thing that will be distorted by noise
             s = sin(p.y+p.x),
             // start noise at 1, until 32, grow by n+=n
             n = 1.; n < 32.; n += n )
                 // subtract noise from s, pass .3*t+ through sin for some movement
                 s -= abs(dot(cos(.3*t+p*n), vec3(.3))) / n;
    // divide down brightness and make a light in the center
    o = tanh(o/2e4/length(u));
    
    fragColor = o;
}

