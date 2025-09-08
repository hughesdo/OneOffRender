#version 330 core

//  Original Created by diatribes in 2025-06-20
// https://www.shadertoy.com/view/wcGXWR
// Bubble Colors
// Converted for OneOffRender system

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

void main()
{
    vec2 u = gl_FragCoord.xy;
    float i = 0.0, r, s, d = 0.0, n, t = iTime;
    vec3  p = vec3(iResolution, 1.0);
    u = (u-p.xy/2.)/p.y;

    vec4 o = vec4(0.0);
    
    // Subtle audio sampling - just bass for gentle pulsing
    float bass = texture(iChannel0, vec2(0.1, 0.0)).x;
    float kick = texture(iChannel0, vec2(0.02, 0.0)).x;
    
    // Gentle audio enhancement
    bass = bass * 1.6;
    kick = pow(kick, 2.0) * 1.8;
    
    o *= i;
    for (int iter = 0; iter < 90; iter++) {
        i++;

        d += s = .005 + abs(r)*.2;
        o += (1.+cos(.1*p.z+vec4(3,1,0,0))) / s;

        p = vec3(u * d, d + t*16.);
        r = 50.-abs(p.y)+ cos(t - dot(u,u) * 6. + bass * 2.0)*3.3;  // Slight bass modulation

        for(n = .08; n < .8; n *= 1.4) {
            r -= abs(dot(sin(.3*t+.8*p*n), .7 +p-p )) / n;
        }
    }

    // Subtle color shift and brightness boost on kicks
    o = tanh(o / 2e3) * (1.0 + kick * 0.15);

    fragColor = o;
}