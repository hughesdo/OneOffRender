#version 330 core

// tdf-16ms_glsl-graphics-compo_nunu-00 - OneOffRender Version
// Converted from GLSL Sandbox format to OneOffRender
// Complex noise-based pattern shader (not audio reactive by design)

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// color palette
const vec4 c00 = vec4(0.9607843137254902, 0.7098039215686275, 0.6705882352941176, 1.0);
const vec4 c01 = vec4(0.6627450980392157, 0.803921568627451, 0.396078431372549, 1.0);
const vec4 c02 = vec4(0.9647058823529412, 0.8117647058823529, 0.8313725490196079, 1.0);
const vec4 c03 = vec4(1.0, 0.9254901960784314, 0.5568627450980392, 1.0);
const vec4 c04 = vec4(0.8117647058823529, 0.9019607843137255, 0.7647058823529411, 1.0);
const vec4 c05 = vec4(0.7529411764705882, 0.8901960784313725, 0.9607843137254902, 1.0);
const vec4 c06 = vec4(0.8823529411764706, 0.8313725490196079, 0.9098039215686274, 1.0);
const vec4 c07 = vec4(0.5568627450980392, 0.8117647058823529, 0.803921568627451, 1.0);
const vec4 c08 = vec4(0.9607843137254902, 0.6980392156862745, 0.6862745098039216, 1.0);
const vec4 c09 = vec4(0.8313725490196079, 0.8862745098039215, 0.44313725490196076, 1.0);
const vec4 c10 = vec4(0.9529411764705882, 0.6235294117647059, 0.5019607843137255, 1.0);
const vec4 c11 = vec4(0.7333333333333333, 0.7294117647058823, 0.8666666666666667, 1.0);
const vec4 c12 = vec4(0.9764705882352941, 0.807843137254902, 0.7254901960784313, 1.0);
const vec4 c13 = vec4(0.984313725490196, 0.788235294117647, 0.42745098039215684, 1.0);
const vec4 c14 = vec4(1.0, 0.9568627450980393, 0.8196078431372549, 1.0);
const vec4 c15 = vec4(0.7254901960784313, 0.8470588235294118, 0.9058823529411765, 1.0);
const vec4 c21 = vec4(0.5019607843137255, 0.803921568627451, 0.9137254901960784, 1.0);
const vec4 c22 = vec4(0.9607843137254902, 0.6862745098039216, 0.47843137254901963, 1.0);
const vec4 c23 = vec4(0.8274509803921568, 0.9019607843137255, 0.9647058823529412, 1.0);
const vec4 c24 = vec4(0.8509803921568627, 0.7294117647058823, 0.8470588235294118, 1.0);

// utilities
float smootherstep(float f){
    return f * f * f * (10.0 - 15.0 * f + 6.0 * f * f);
}

// hash functions
const uint UINT_MAX = 0xffffffffu;
uvec3 k = uvec3(0x456789abu, 0x6789ab45u, 0x89ab4567u);
uvec3 u = uvec3(1u, 2u, 3u);

uint uhash11(uint n){
    n ^= n << u.x;
    n ^= n >> u.x;
    n *= k.x;
    n ^= n << u.x;
    return n * k.x;
}

uvec3 uhash33(uvec3 n){
    n ^= n.yzx << u;
    n ^= n.yzx >> u;
    n *= k;
    n ^= n.yzx << u;
    return n * k;
}

float hash31(vec3 p){
    uvec3 n = floatBitsToUint(p);
    return float(uhash33(n).x) / float(UINT_MAX);
}

vec3 hash33(vec3 p){
    uvec3 n = floatBitsToUint(p);
    return vec3(uhash33(n)) / vec3(UINT_MAX);
}

// value noise
float vnoise31(vec3 p){
    vec3 n = floor(p);
    float v000 = hash31(n + vec3(0.0, 0.0, 0.0));
    float v100 = hash31(n + vec3(1.0, 0.0, 0.0));
    float v010 = hash31(n + vec3(0.0, 1.0, 0.0));
    float v001 = hash31(n + vec3(0.0, 0.0, 1.0));
    float v011 = hash31(n + vec3(0.0, 1.0, 1.0));
    float v101 = hash31(n + vec3(1.0, 0.0, 1.0));
    float v110 = hash31(n + vec3(1.0, 1.0, 0.0));
    float v111 = hash31(n + vec3(1.0, 1.0, 1.0));

    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float v00 = mix(v000, v100, f.x);
    float v10 = mix(v010, v110, f.x);
    float v01 = mix(v001, v101, f.x);
    float v11 = mix(v011, v111, f.x);

    float v0 = mix(v00, v10, f.y);
    float v1 = mix(v01, v11, f.y);

    return mix(v0, v1, f.z);
}

// gradient noise
float gnoise31(vec3 p){
    vec3 n = floor(p);
    vec3 f = fract(p);

    float v000 = dot(normalize(hash33(n + vec3(0.0, 0.0, 0.0)) - vec3(0.5)), f - vec3(0.0, 0.0, 0.0));
    float v100 = dot(normalize(hash33(n + vec3(1.0, 0.0, 0.0)) - vec3(0.5)), f - vec3(1.0, 0.0, 0.0));
    float v010 = dot(normalize(hash33(n + vec3(0.0, 1.0, 0.0)) - vec3(0.5)), f - vec3(0.0, 1.0, 0.0));
    float v001 = dot(normalize(hash33(n + vec3(0.0, 0.0, 1.0)) - vec3(0.5)), f - vec3(0.0, 0.0, 1.0));
    float v011 = dot(normalize(hash33(n + vec3(0.0, 1.0, 1.0)) - vec3(0.5)), f - vec3(0.0, 1.0, 1.0));
    float v101 = dot(normalize(hash33(n + vec3(1.0, 0.0, 1.0)) - vec3(0.5)), f - vec3(1.0, 0.0, 1.0));
    float v110 = dot(normalize(hash33(n + vec3(1.0, 1.0, 0.0)) - vec3(0.5)), f - vec3(1.0, 1.0, 0.0));
    float v111 = dot(normalize(hash33(n + vec3(1.0, 1.0, 1.0)) - vec3(0.5)), f - vec3(1.0, 1.0, 1.0));

    f = f * f * f * (10.0 - 15.0 * f + 6.0 * f * f);

    float v00 = mix(v000, v100, f.x);
    float v10 = mix(v010, v110, f.x);
    float v01 = mix(v001, v101, f.x);
    float v11 = mix(v011, v111, f.x);

    float v0 = mix(v00, v10, f.y);
    float v1 = mix(v01, v11, f.y);

    return 0.5 + 0.5 * mix(v0, v1, f.z);
}

// perlin noise
float gtable3(vec3 lattice, vec3 p){
    uvec3 n = floatBitsToUint(lattice);
    uint ind = uhash33(n).x >> 28;
    float u = ind < 8u ? p.x : p.y;
    float v = ind < 4u ? p.y : ind == 12u || ind == 14u ? p.x : p.z;
    return ((ind & 1u) == 0u? u: -u) + ((ind & 2u) == 0u? v : -v);
}

float pnoise31(vec3 p){
    vec3 n = floor(p);
    vec3 f = fract(p);
    float v000 = gtable3(n + vec3(0.0, 0.0, 0.0), f - vec3(0.0, 0.0, 0.0)) * 0.7071067811865475;
    float v100 = gtable3(n + vec3(1.0, 0.0, 0.0), f - vec3(1.0, 0.0, 0.0)) * 0.7071067811865475;
    float v010 = gtable3(n + vec3(0.0, 1.0, 0.0), f - vec3(0.0, 1.0, 0.0)) * 0.7071067811865475;
    float v001 = gtable3(n + vec3(0.0, 0.0, 1.0), f - vec3(0.0, 0.0, 1.0)) * 0.7071067811865475;
    float v011 = gtable3(n + vec3(0.0, 1.0, 1.0), f - vec3(0.0, 1.0, 1.0)) * 0.7071067811865475;
    float v101 = gtable3(n + vec3(1.0, 0.0, 1.0), f - vec3(1.0, 0.0, 1.0)) * 0.7071067811865475;
    float v110 = gtable3(n + vec3(1.0, 1.0, 0.0), f - vec3(1.0, 1.0, 0.0)) * 0.7071067811865475;
    float v111 = gtable3(n + vec3(1.0, 1.0, 1.0), f - vec3(1.0, 1.0, 1.0)) * 0.7071067811865475;

    f = f * f * f * (10.0 - 15.0 * f + 6.0 * f * f);

    float v00 = mix(v000, v100, f.x);
    float v10 = mix(v010, v110, f.x);
    float v01 = mix(v001, v101, f.x);
    float v11 = mix(v011, v111, f.x);

    float v0 = mix(v00, v10, f.y);
    float v1 = mix(v01, v11, f.y);

    return 0.5 + 0.5 * mix(v0, v1, f.z);
}

// domain warping
float warp31(vec3 p, float g){
    float val = 0.0;
    for (int i=0; i<4; i++){
        val = pnoise31(p + g * val);
    }
    return val;
}

void main(){
    vec2 p = (2.0 * gl_FragCoord.xy - iResolution.xy) / min(iResolution.x, iResolution.y);
    p *= 4.0;

    float d0, d1, d2, d3, d4, d5;
    float w;
    float t;
    float bw = 0.05;
    vec2 g;
    int k = 0;

    float b0, b1, b2, b3;

    // value noise
    w = 1.0e-4;
    t = iTime;
    t = floor(t) + smootherstep(fract(t));
    d0 = vnoise31(vec3(p.x+w, p.y, t));
    d1 = vnoise31(vec3(p.x-w, p.y, t));
    d2 = vnoise31(vec3(p.x, p.y+w, t));
    d3 = vnoise31(vec3(p.x, p.y-w, t));
    g = normalize(vec2(d0-d1, d2-d3));
    d4 = vnoise31(vec3(p.x+bw*g.x, p.y+bw*g.y, t));
    d5 = vnoise31(vec3(p.x-bw*g.x, p.y-bw*g.y, t));
    d4 -= 0.5;
    d5 -= 0.5;

    b0 = d4 * d5;
    k += d4 < 0.0 ? 0 : 1;

    // gradient noise
    w = 1.0e-4;
    t = iTime + 0.25;
    t = floor(t) + smootherstep(fract(t));
    d0 = gnoise31(vec3(p.x+w, p.y, t));
    d1 = gnoise31(vec3(p.x-w, p.y, t));
    d2 = gnoise31(vec3(p.x, p.y+w, t));
    d3 = gnoise31(vec3(p.x, p.y-w, t));
    g = normalize(vec2(d0-d1, d2-d3));
    d4 = gnoise31(vec3(p.x+bw*g.x, p.y+bw*g.y, t));
    d5 = gnoise31(vec3(p.x-bw*g.x, p.y-bw*g.y, t));
    d4 -= 0.5;
    d5 -= 0.5;

    b1 = d4 * d5;
    k += d4 < 0.0 ? 0 : 2;

    // perlin noise
    w = 1.0e-4;
    t = iTime + 0.5;
    t = floor(t) + smootherstep(fract(t));
    d0 = pnoise31(vec3(p.x+w, p.y, t));
    d1 = pnoise31(vec3(p.x-w, p.y, t));
    d2 = pnoise31(vec3(p.x, p.y+w, t));
    d3 = pnoise31(vec3(p.x, p.y-w, t));
    g = normalize(vec2(d0-d1, d2-d3));
    d4 = pnoise31(vec3(p.x+bw*g.x, p.y+bw*g.y, t));
    d5 = pnoise31(vec3(p.x-bw*g.x, p.y-bw*g.y, t));
    d4 -= 0.5;
    d5 -= 0.5;

    b2 = d4 * d5;
    k += d4 < 0.0 ? 0 : 4;

    // domain warping
    float v = 1.6;
    w = 1.0e-4;
    t = iTime + 0.75;
    t = floor(t) + smootherstep(fract(t));
    d0 = warp31(vec3(p.x+w, p.y, t), v);
    d1 = warp31(vec3(p.x-w, p.y, t), v);
    d2 = warp31(vec3(p.x, p.y+w, t), v);
    d3 = warp31(vec3(p.x, p.y-w, t), v);
    g = normalize(vec2(d0-d1, d2-d3));
    d4 = warp31(vec3(p.x+bw*g.x, p.y+bw*g.y, t), v);
    d5 = warp31(vec3(p.x-bw*g.x, p.y-bw*g.y, t), v);
    d4 -= 0.5;
    d5 -= 0.5;

    b3 = d4 * d5;
    k += d4 < 0.0 ? 0 : 8;

    // color selection
    if(b0 < 0.0){
        fragColor = c24;
    }
    else if(b1 < 0.0){
        fragColor = c23;
    }
    else if(b2 < 0.0){
        fragColor = c22;
    }
    else if(b3 < 0.0){
        fragColor = c21;
    }
    else{
        fragColor = k ==  0 ?   c00:
                    k ==  1 ?   c01:
                    k ==  2 ?   c02:
                    k ==  3 ?   c03:
                    k ==  4 ?   c04:
                    k ==  5 ?   c05:
                    k ==  6 ?   c06:
                    k ==  7 ?   c07:
                    k ==  8 ?   c08:
                    k ==  9 ?   c09:
                    k == 10 ?   c10:
                    k == 11 ?   c11:
                    k == 12 ?   c12:
                    k == 13 ?   c13:
                    k == 14 ?   c14:
                                c15;
    }
}
