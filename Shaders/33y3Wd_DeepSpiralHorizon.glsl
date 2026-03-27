#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Deep Spiral Horizon
// Created by diatribes
// Shadertoy ID: 33y3Wd
// https://www.shadertoy.com/view/33y3Wd

// went through soooo many variations,
// little tweaks can make a big difference

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i, d, s=.1, n, t=mod(iTime*.2, 360.); // goes crazy after too long :)
    vec3 p;
    u = (u-iResolution.xy/2.)/iResolution.y;
    
    // stolen from @Shane :)
    // make cinema bars at top and bottom
    if(abs(u.y)>.4){ o = vec4(0); fragColor = o; return; }
    u += vec2(cos(t)*.3, cos(t*1.3)*.2);
    
    // clear o, 100 steps, accumulate distance, accumulate brightness
    for(o*=i; i++<64. && s > .001;d += s = (.004+abs(s)*.8), o += 1./s)
        // march and move backwards
        for (p = vec3(u * d, d - t),
             // twist (p.z) and spin (t)
             p.xy *= mat2(cos(.2*t-p.z*.3+vec4(0,33,11,0))),
             // mirror p, move it around
             p = abs(64.*sin(t*.02)+p),
             // untwist things by commenting out the rotation 3 lines above
             // to see what it all looks like under the hood
             s = max(.05, max(sin(p.y) , cos(p.x))),
             // vary noise start, up to 64., grow by n += n
             n = 4.+sin(t*.4); n < 64.; n += n )
                 // apply noise
                 s -= abs(dot(sin(p*n), vec3(.25))) / n;
                 
    // divide down brightness, put a light in the center
    o = o/5e4/pow(dot(u,u),.3);
    // @Shane depth based color tip :)
    // Colorize
    o = pow(o.xxxx, vec4(1, 12, 2, 0))*5.;
    // Depth based color and tanh tone mapping
    o = tanh(mix(o, o.yzxw, length(u)));
    
    fragColor = o;
}

