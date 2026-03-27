#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Holographic Dataplane Transport
// Created by diatribes
// Shadertoy ID: 3cfBWB
// https://www.shadertoy.com/view/3cfBWB

#define P(z) vec3( cos( vec2(.15,.2)*(z) ) *8. , z )
void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i,d,s,n, T = iTime*4.;
    vec3  R = vec3(iResolution.xy, iResolution.y),
          p = P(T),
          t,
          Z = normalize( P(T+.1) - p ),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3(
              mat2( cos( tanh(sin(p.z*.1)*4.)*6. +vec4(0,33,11,0)))
              *(u-R.xy/2.)/R.y , 1 ) 
              * mat3(-X, cross(X, Z), Z );
              
    for( o*=i ; i++<1e2 ; o += ( 1. + cos(d + vec4(6,4,2,0)) ) / s) {
        p += D * s;
        t.xy = abs(p-P(p.z)).xy;
        s  = min(.1-t.x, .1-t.y);
        for( n = .1; n < 1.;
             s += abs( dot( step(.99, sin( .05*t + p/n )) , p-p+.3 ) ) * n,
             n += n 
           );
        d += s = .01 + .7 * abs(s);
        
    }
    o = tanh(o / 1e3 );
    
    fragColor = o;
}

