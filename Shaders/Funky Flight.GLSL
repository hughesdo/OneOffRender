#version 330 core

/*
Funky Flight
Original Author: diatribes
ShaderToy id: tfsBzn
Created: 2025-09-08
Link: https://www.shadertoy.com/view/tfsBzn
Converted for OneOffRender system
*/

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture (required but not used)
out vec4 fragColor;

#define T (iTime)
#define P(z) (vec3((cos((z) * .4) * .3) * 6., \
                   (cos((z) * .3) * .3) * 6., (z)))
#define R(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize

// Custom tanh implementation for compatibility
vec4 tanh4(vec4 x) {
    vec4 exp2x = exp(2.0 * x);
    return (exp2x - 1.0) / (exp2x + 1.0);
}

float tunnel(vec3 p, float r) {
    p.xy -= P(p.z).xy;
    return r - abs(p.y);
}

float gyroid(vec3 p) {
    p.z *= .3;
    return dot(cos(p), sin(p + cos(p.yzx)));
}

float map(vec3 p) {
    return min(tunnel(p, 6.),
           max(tunnel(p, .3), gyroid(p)));
}

void mainImage(out vec4 o, in vec2 u) {
    float s = .02, d = 0., i = 0., a;
    vec2 r = iResolution;
    u = (u - r.xy / 2.) / r.y;

    vec3 e = vec3(.001, 0, 0),
         p = P(T), ro = p,
         Z = N(P(T + 1.) - p),
         X = N(vec3(Z.z, 0, -Z.x)),
         D = vec3(R(sin(T * .2) * .4) * u, 1)
            * mat3(-X, cross(X, Z), Z);

    o *= 0.;
    while(i++ < 128. && s > .005) {
        p = ro + D * d * .7;
        d += s = map(p);
    }

    o = vec4(4, 2, 8, 0) / d;
    i = 32.;
    o += 4. * abs(vec4(32, 12, 4, 0) / d / dot(sin(.15 * p * i), cos(p.yzx))) / i;
    o += 2. * (vec4(12, 32, 4, 0) / d / dot(sin(.3 * p * i), cos(p.zxy))) / i;
    o += 1. * (vec4(4, 32, 12, 0) / d / dot(sin(.3 * p * i), cos(p.zxy))) / i;

    d = min(1.0, (d - 4.) * .05);
    o = mix(o, vec4(3, 8, 4, 0) * vec4(0.2 + d), d);

    o = tanh4(o / max(d, 4.));

    // Ensure alpha is 1.0
    o.a = 1.0;
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}