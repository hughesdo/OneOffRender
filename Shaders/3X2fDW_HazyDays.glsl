#version 330 core

// Hazy Days - Blue Lake & Sky Scene with Sun
// Created by OneHung
// Water inspired by @FabriceNeyret2, Sky using BigWings' Perlin Noise
// https://www.shadertoy.com/view/3X2fDW

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

#define HASHSCALE .1031

vec4 renderWater(vec2 uv) {
    float s = 0.002, i = 0.0;
    vec4 col = vec4(0);
    vec3 p = vec3(0);
    uv.y -= 0.3;
    for(i = 0.0; i < 32.0 && s > 0.001; i++) {
        col += vec4(5,3,2,0) / length(uv - 0.1);
        p += vec3(uv * s, s);
        s = 1.0 + p.y;
        for(float n = 0.01; n < 1.0; n += n) {
            s += abs(dot(sin(p.z + iTime + p / n), vec3(1))) * n * 0.1;
        }
    }
    col = tanh(col / 5e2);
    col.rgb = col.bgr;
    col.rgb *= vec3(0.7, 0.9, 1.2);
    return col;
}

float hash(float p) {
    vec3 p3 = fract(vec3(p) * HASHSCALE);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(in vec3 x) {
    vec3 p = floor(x);
    vec3 k = fract(x);
    k *= k * k * (3.0 - 2.0 * k);
    float n = p.x + p.y * 57.0 + p.z * 113.0;
    float a = hash(n); float b = hash(n + 1.0);
    float c = hash(n + 57.0); float d = hash(n + 58.0);
    float e = hash(n + 113.0); float f = hash(n + 114.0);
    float g = hash(n + 170.0); float h = hash(n + 171.0);
    return mix(mix(mix(a, b, k.x), mix(c, d, k.x), k.y),
               mix(mix(e, f, k.x), mix(g, h, k.x), k.y), k.z);
}

float fbm(in vec3 p) {
    float f = 0.0;
    f += 0.5000 * noise(p); p *= 2.02; p -= iTime * 0.3;
    f += 0.2500 * noise(p); p *= 2.03; p += iTime * 0.2;
    f += 0.1250 * noise(p); p *= 2.01; p -= iTime * 0.25;
    f += 0.0625 * noise(p);
    return f / 0.9375;
}

void main() {
    vec2 C = gl_FragCoord.xy;
    C.y = iResolution.y - C.y;  // Flip Y-axis to correct orientation
    vec2 R = iResolution.xy;

    // Camera floating on water
    float wave1 = sin(iTime * 0.6) * 0.05;
    float wave2 = sin(iTime * 0.8 + 1.5) * 0.03;
    float wave3 = cos(iTime * 0.5 + 0.7) * 0.04;
    float cameraBob = wave1 + wave2 + wave3;
    float waveLeft = sin(iTime * 0.6 - 0.3) * 0.05 + sin(iTime * 0.8 + 1.2) * 0.03;
    float waveRight = sin(iTime * 0.6 + 0.3) * 0.05 + sin(iTime * 0.8 + 1.8) * 0.03;
    float cameraTilt = (waveRight - waveLeft) * 0.8;
    
    vec2 uv = (C - 0.5 * R) / R.y;
    vec2 uvNorm = C / R;
    
    float c = cos(cameraTilt), s = sin(cameraTilt);
    mat2 rotation = mat2(c, -s, s, c);
    uv = rotation * uv;
    uv.y -= cameraBob;
    
    // Audio for sun pulse
    float audioAvg = texture(iChannel0, vec2(0.1, 0.25)).x;
    audioAvg = smoothstep(0.0, 0.5, audioAvg);
    
    vec3 col;
    float horizon = 0.15 + sin(iTime * 0.3 + uv.x * 2.0) * 0.03;
    
    if (uv.y < horizon) {
        vec4 waterCol = renderWater(uv);
        col = waterCol.rgb;
    } else {
        vec2 sunPos = vec2(0.0, 0.25 + sin(iTime * 0.1) * 0.05);
        float sunDist = length(uv - sunPos);
        float sunCore = smoothstep(0.12, 0.0, sunDist);
        float sunGlow = smoothstep(0.4, 0.0, sunDist);
        
        vec3 sunColor = vec3(1.0, 0.85, 0.6);
        vec3 sunGlowColor = vec3(1.0, 0.7, 0.4);
        
        vec3 skyPos = vec3(uv * 3.0, iTime * 0.5);
        float clouds = fbm(skyPos);
        
        vec3 skyBlue = vec3(0.3, 0.5, 0.9);
        vec3 skyHorizon = vec3(0.6, 0.7, 0.9);
        vec3 cloudWhite = vec3(0.9, 0.95, 1.0);
        vec3 cloudGray = vec3(0.5, 0.55, 0.65);
        
        float skyGradient = smoothstep(0.0, 0.6, uv.y);
        vec3 skyBase = mix(skyHorizon, skyBlue, skyGradient);
        skyBase = mix(skyBase, sunGlowColor, sunGlow * 0.5);
        
        float cloudDensity = smoothstep(0.3, 0.7, clouds);
        vec3 cloudColor = mix(cloudGray, cloudWhite, clouds);
        float sunInfluence = smoothstep(0.6, 0.0, sunDist);
        cloudColor = mix(cloudColor, sunColor, sunInfluence * 0.4);
        
        col = skyBase;
        col += sunColor * sunCore * (1.0 - cloudDensity * 0.6);
        col += sunGlowColor * sunGlow * 0.3 * (1.0 - cloudDensity * 0.4);
        col = mix(col, cloudColor, cloudDensity * 0.6);
        
        // Sun pulse with audio
        col += sunCore * audioAvg * 0.2 * sunColor;
    }
    
    float vignette = 1.0 - length(uvNorm - 0.5) * 0.4;
    col *= vignette;
    
    fragColor = vec4(col, 1.0);
}

