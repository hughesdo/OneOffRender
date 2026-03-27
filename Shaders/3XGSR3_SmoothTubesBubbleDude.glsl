#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Smooth Tubes & Bubble Dude
// Created by diatribes
// Shadertoy ID: 3XGSR3
// https://www.shadertoy.com/view/3XGSR3

// similar to the forked, but no noise on the tubes
// and some more color :)

#define P(z) vec3(cos((z) * .11)  * 4., \
                  cos((z) * .13)  * 4., (z))
#define R(a) mat2(cos(a+vec4(0,33,11,0)))
#define T iTime * 6.

float light = 0.;

float sdfWisp(vec3 p) {

    // subtract path xy from p.xy
    p.xy -= P(p.z).xy;
    
    // move wisp left, right, up, down, back, and forth
    return length(p - vec3(
                    // X
                    sin(sin(T*.5)+T*.6)*1.,
                    // Y
                    sin(sin(T*.5)+T*.6)*1.,
                    // Z + T
                    T+16.+cos(T*.1)*10.))-.5;
                    
}

float sdfTube(vec3 p){
    // subtract path xy from p.xy
    p.xy -= P(p.z).xy;
    // repeat
    p.xy = mod(p.xy ,6.) - 3.;
    // distance to a cylinder relative to p.xy
    return length(p.xy) - 2.;
}

float map(vec3 p) {

    // wisp distance
    float wisp = sdfWisp(p);
    // sample a bit for light
    light += wisp * .0125;
    
    // tube distance
    float tube = sdfTube(p);

    // return distance to tunnel, tube, or wisp
    return min(.001+abs(wisp*.8), .0005+abs(tube));
}

void main()
{
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float s, d=0.,i=0.;
    vec3  r = vec3(iResolution.xy, iResolution.y);
    u = (u-r.xy/2.)/r.y;
    
    vec3  p = P(T),ro=p,
          Z = normalize( P(T+3.) - p),
          X = normalize(vec3(Z.z,0,-Z)),
          D = vec3(R(sin(p.z*.07)*1.5)* u, 1) 
              * mat3(-X, cross(X, Z), Z);
    if(abs(u.y)>.4){ o = vec4(0); fragColor = o; return; }

    for(o *= i; i++ < 1e2;o += 1./s)
        p = ro + D * d * .9,
        d += s = map(p),
        o += (1.+cos(.2*p.z+vec4(3,1,0,0))/s);
        
    o = vec4(tanh(o*vec4(8,d/4.,i/d*4.,0)/light/1e4));
    
    fragColor = o;
}

