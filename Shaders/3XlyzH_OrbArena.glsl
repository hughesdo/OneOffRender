#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Orb Arena
// Created by diatribes
// Shadertoy ID: 3XlyzH
// https://www.shadertoy.com/view/3XlyzH

#define O(Z,c) ( length(                 \
          p - vec3( sin( T*c*6. ) * 3. ,        \
                    sin( T*c*4. ) * 2. + 1.5,  \
                    Z +5.  +cos(T*.5) *16. )  ) - c )

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float d,i,e,s,w,l, T = iTime;
    vec3  p = vec3(iResolution.xy, iResolution.y);
    u = ( u - p.xy/2. ) / p.y;
    u.y += .3;
    
    for(o*=i; i++ < 128.; o += d / s + 1e5/e) {
        p = vec3( u*d, d ),
        e = max( .8* min( O( 17., .1),
                     min( O( 16., .2),
                          O( 14., .3) )), .001 ),
        s = max(1.+p.y, .001);
        p *= .1; p.xy += 1.5, w = .35;
        for (int i; i++ < 7; w *= l )
            p *= l = 3./dot( p = sin(p) , p);

        d += s = min( min(e,s),
                      length(p)/w );
    } 
    o = tanh(vec4(1,2,3,0)*o/1e7);
    
    fragColor = o;
}

