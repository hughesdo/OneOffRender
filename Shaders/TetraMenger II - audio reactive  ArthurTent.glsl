// https://www.shadertoy.com/view/7clXRN
// TetraMenger II - audio reactive  ArthurTent
// Converted to OneOffRender format

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

// Forked from "TetraMenger II - 35mm 1920" by sandefjord

#define FFT(a) pow(texelFetch(iChannel0, ivec2(a, 0), 0).x, 4.0)
#define M_STEPS 120
#define S_DIST 0.001
#define M_DIST 60.0
float snd = 0.;


// Set to 1 to enable vertical film scratches, 0 to disable
#define ENABLE_FILM_SCRATCHES 0
// Set to 1 to enable audio-reactive camera shake, 0 to disable
#define ENABLE_AUDIO_SHAKE 0

#define SHADERAMP 0
float gTime;


// --- style "Old Film" ---
float hash11(float p) {
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float scratchNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(hash21(i), hash21(i+vec2(1.0,0.0)),f.x),
               mix(hash21(i+vec2(0.0,1.0)), hash21(i+vec2(1.0,1.0)),f.x),f.y);
}

mat2 Rot(float a) { 
    float s = sin(a), c = cos(a); 
    return mat2(c, -s, s, c); 
}

vec3 gOrbitTrap = vec3(0.0);
float sdSierpinski(vec3 p, float s) {
    float scale = 2.1;
    int iterations = 5;
    vec3 v1 = vec3(1.0, 1.0, 1.0);
    gOrbitTrap = vec3(10.0); 
    p /= s;
    for(int n = 0; n < iterations; n++) {
        if(p.x + p.y < 0.0) p.xy = -p.yx;
        if(p.x + p.z < 0.0) p.xz = -p.zx;
        if(p.y + p.z < 0.0) p.yz = -p.zy;
        p = p * scale - v1 * (scale - 1.0);
        gOrbitTrap.y = min(gOrbitTrap.y, length(p.xy));
    }
    return (length(p) - 1.4) * pow(scale, -float(iterations)) * s;
}

float sdMenger(vec3 p, float s) {
    p /= s;
    vec3 d = abs(p) - 1.0;
    float res = min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
    float scale = 3.0;
    for(int n = 0; n < 4; n++) {
        vec3 a = mod(p * scale, 2.0) - 1.0;
        scale *= 3.0;
        vec3 r = abs(1.0 - 3.0 * abs(a));
        float da = max(r.x, r.y);
        float db = max(r.y, r.z);
        float dc = max(r.z, r.x);
        res = max(res, (min(da, min(db, dc)) - 1.0) / scale);
        gOrbitTrap.y = min(gOrbitTrap.y, length(a.xy) * 0.5);
    }
    return res * s;
}

float GetDist(vec3 p) {
    float time = gTime * 0.15;
    p.xy *= Rot(p.z * 0.05 + time);
    float repeatZ = 8.0;
    float zId = floor((p.z + repeatZ * 0.5) / repeatZ);
    vec3 p_local = p;
    p_local.z = mod(p_local.z + repeatZ * 0.5, repeatZ) - (repeatZ * 0.5);
    vec3 p_obj = p_local;
    p_obj.xz *= Rot(time * 1.5 + zId);
    p_obj.xy *= Rot(time * 0.8);
    float obj = (mod(zId, 2.0) == 0.0) ? sdSierpinski(p_obj, 1.2) : sdMenger(p_obj, 1.0);
    
    // --- Frequency based Circle Distortion ---
    float angle = atan(p.y, p.x);
    float freqIdx = (angle / 6.2831 + 0.5) * 511.0;
    float wave = FFT(int(freqIdx));
    float hole = length(p.xy) - (1.0 + wave * 2.0);
    
    return max(obj, -hole); 
}

vec3 GetNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(GetDist(p) - vec3(GetDist(p-e.xyy), GetDist(p-e.yxy), GetDist(p-e.yyx)));
}
//*====================================================================================*//
//                                                                                      //
//  _______ _______ _______ _______ _______ _______ _______ _____  _______ ______        //
// |   |   |   ___|_      _|   _   |_______|   |   |   _   |     \|   ___|   __ \      //
// |       |   ___| |   | |       |__     |       |       |  --  |   ___|      <        //
// |__|_|__|_______| |___| |___|___|_______|___|___|___|_____/|_______|___|__|          //
//                                                                                      //
//======================================================================================//
//:: [ Optimized for NVIDIA GeForce GeForce GTX 1080 Ti ] ::                            //
//======================================================================================//
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒//
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒//
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒░░░░░░░░░░░░░░░░ ░░░▒░░░░░░░░░░░░░░░▒▒▒▒▒▒//
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░▒▒░░░░░░░░░░░░░░░▒░░░░▒░░▒░░░░░░░░░▒▒░░░░░▒▒▒▒▒//
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒░░░░░░░░░░░░░░░░░░░░▒▒▒░░▒▒▒░░▒▒▒▒▒▒▒ ▒▒▒▒▒▒▒▒▒//
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░  ░░░░░░░░░▒▒▒░▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒ //
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒░░░░░░░░░ ░▒▒▒▒▒░ ░░░░░░░▒░░░░▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒//
//Processeur: AMD Ryzen 9 9950X3D2▒▒▒░ ▒░░░░░░░░░▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒//
//RAM installée 256,0 Go DDR5▒▒▒▒▒▒▒░▒▒▒▒░░░░░ ▒▒▓▒▓▒▒▒▒░░ ░░░░░░░▒▒░░░░░░░░░░░ ▒▒▒▒▒▒▒▒//
//Stockage: Sabrent 16 TB SSD▒▒▒▒▒▒▒░░▒▓▓ ░░░ ▒▒▒▓▓▒▒░▓▒░░ ░░░░░░░▒▒▒▒░░░░░░░░░░░ ▒▒▒▒▒▒//
//Video: NVIDIA GeForce RTX 5090▒▒▒▒▒░▒▓▒▒░░░▒▒▒▒▓▓▓░▓▓ ░░░░░░░░░▒▒▒▒▒▒░░░░░░░ ░░░░▒▒▒▒▒//
//Systeme: Kubuntu/Win11▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▓▒▓▓░▒▒▓▓▓▓▓▓░▓▓ ░ ░░░░░░▒▒▒▒▒▒▒▒░░░▒▒▒▒░░░░░▒▒▒▒//
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▓▒▓▓▒▓▓▓▓▓▓▓▒▒▓▓ ░▒░░░░░░▒▒▒▒▒▒▒▒░▒▒▒▒▒░ ░░░░░▒▒▒//
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▓░░░░▒░▓▓▓▓▓▓▓▓▒▒▒░░ ░░░░ ░▒▒▒▒▒▒▒▒░▓▒▒░░░▒▒▒▒▒░░▒▒▒//
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ ▓▓▓▓▓▓▓▒░░▒▒▒▒▒▒░░▒▒▒░  ▒ ░▒▒▒▒▒▒░▒▒░ ▒▒▒▒▒▒▒▒▒▒▒▒▒//
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░  ░▒▒▒▒▒▒▒▒▒▒▒▒░ ░░ ▒ ▒▒░ ░▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒ //
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ░▒▒▒▒▒▒▒▒░ ░░░░░▒ ▒▒░░▒▒░░░  ▒▒▒▒▒▒▒▒▒▒▒▒▒  //
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ░░░░░░░░░░  ░░▒▒▒▒░░ ▒▒▒▒▒▒▒ ▒▒▒▒▒▒▒▒▒▒▒▒ //
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░ ░   ░░▒▒▒▒▒▒░▒░░░░▒▒▒▒▒  ░░▒▒▒▒▒▒▒▒▒▒ //
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░ ░░     ░░░░░░░░ ░▒▒▒░ ░▒░░░▒░░░ ▒▒▒▒▒▒▒▒▒//
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░ ░▒▒▒▒▒▒░░░░░░░░░ ░░ ▒▒▒░░▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒ //
//▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒░░░░  ░ ░ ░▒▒░░░░░░░░▒▒▒░░░ ▒▒▒▒▒▒▒▒//
//======================================================================================//
//:: [ CREDITS ] ::                                                                      //
//======================================================================================//
//  >>  Author  : Patrick JAILLET                                                       //
//  >>  Email   : metashader@proton.me                                                  //
//  >>  Engine  : MetaShader                                                             //
//  >>  URL     : https://0110110101110011.netlify.app                                   //
//*====================================================================================*//
vec3 applyCRT(vec3 col, vec2 uv) {
    float scanline = sin(uv.y * iResolution.y * 1.5) * 0.1 + 0.9;
    float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y) * 15.0;
    return col * scanline * pow(vignette, 0.25);
}

void mainImage( out vec4 O, in vec2 fragCoord ) {
    gTime = iTime;
    #if SHADERAMP == 1
       gTime=iAmplifiedTime*1.3;
    #endif
    // --- EFFET CAMERA ANNEE 20 (Jump & Shake) ---
    float timeJump = floor(gTime * 12.0);
    int max_freq = 100;
    for(int i=1; i < max_freq; i++){
        snd +=FFT(i)*float(i);
    }
    snd /=float(max_freq*20);

    vec2 shake = vec2(hash11(timeJump), hash11(timeJump + 1.1)) - 0.5;
    
    #if ENABLE_AUDIO_SHAKE == 1
    shake *= (0.005 + snd * 0.08); 
    if(hash11(timeJump * 0.5) > 0.95) shake.y += (hash11(gTime) - 0.5) * (0.05 + snd * 0.15);
    #else
    shake *= 0.005; // Standard minor jitter without audio influence
    if(hash11(timeJump * 0.5) > 0.95) shake.y += (hash11(gTime) - 0.5) * 0.05;
    #endif

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv += shake; 
    
    vec2 crtUV = (fragCoord / iResolution.xy) + shake;
    
    vec3 ro = vec3(0.0, 0.0, gTime * 3.0);
    vec3 rd = normalize(vec3(uv, 1.2));
    rd.xy *= Rot(sin(gTime * 0.1) * 0.2);
    
    vec3 finalCol = vec3(0.0);
    float t = 0.0;
    
    for(int i = 0; i < 90; i++) {
        vec3 p = ro + rd * t;
        float d = GetDist(p);
        vec3 col = vec3(1.0);
        
        float rat = scratchNoise(p.xy * 3.0 + p.z);
        col *= (1.0 - smoothstep(0.4, 0.5, rat) * 0.5);
        
        col += exp(-gOrbitTrap.y * 10.0) * 1.5; 
        
        if(d < 0.005) {
            vec3 n = GetNormal(p);
            finalCol += col * max(dot(n, -rd), 0.0) * 0.1;
            d = 0.15; 
        }
        finalCol += col * exp(-d * 3.0) * 0.15;
        t += max(d * 1.5, 0.06);
        if(t > M_DIST) break;
    }

    float gray = dot(finalCol, vec3(0.299, 0.587, 0.114));
    gray = pow(gray, 0.5);
    gray *= 0.85 + 0.15 * hash11(gTime * 15.0);

    #if ENABLE_FILM_SCRATCHES == 1
    float scratch = hash11(floor(crtUV.x * 400.0 + gTime * 20.0));
    if(scratch > 0.98) gray = mix(gray, 0.8, hash11(crtUV.y + gTime));
    #endif

    gray += (hash21(uv + gTime) - 0.5) * 0.15;

    vec3 sepiaCol = vec3(gray) * vec3(1.2, 1.0, 0.8);
    vec3 col = applyCRT(sepiaCol, crtUV);
    
    O = vec4(col, 1.0);
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}