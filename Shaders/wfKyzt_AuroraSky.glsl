#version 330 core

// Aurora Sky - Northern lights dancing over a dark horizon
// Created by OneHung
// Audio reactive aurora intensity and colors
// https://www.shadertoy.com/view/wfKyzt

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float f = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        f += amp * noise(p);
        p *= 2.1;
        amp *= 0.5;
    }
    return f;
}

float aurora(vec2 uv, float t, float offset, float audioMod) {
    float wave = sin(uv.x * 2.0 + t * 0.3 + offset) * (0.3 + audioMod * 0.1);
    wave += sin(uv.x * 4.5 - t * 0.2 + offset * 2.0) * 0.15;
    wave += sin(uv.x * 1.2 + t * 0.5 + offset * 0.5) * 0.2;
    float noiseVal = fbm(vec2(uv.x * 3.0 + t * 0.1, t * 0.05 + offset));
    float curtainY = 0.3 + wave + noiseVal * 0.2;
    float curtain = smoothstep(curtainY + 0.4, curtainY, uv.y);
    curtain *= smoothstep(curtainY - 0.05, curtainY + 0.1, uv.y);
    float rays = noise(vec2(uv.x * 20.0, uv.y * 2.0 + t * 0.5));
    rays = pow(rays, 2.0);
    return curtain * (0.5 + rays * 0.5);
}

void main() {
    vec2 C = gl_FragCoord.xy;
    vec2 R = iResolution.xy;
    vec2 uv = (C - 0.5 * R) / R.y;
    
    // Audio
    float bass = texture(iChannel0, vec2(0.05, 0.25)).x;
    float mid = texture(iChannel0, vec2(0.3, 0.25)).x;
    float treble = texture(iChannel0, vec2(0.7, 0.25)).x;
    bass = smoothstep(0.0, 0.6, bass);
    mid = smoothstep(0.0, 0.5, mid);
    treble = smoothstep(0.1, 0.4, treble);
    
    float t = iTime * 0.5;
    
    // Night sky gradient
    vec3 col = mix(vec3(0.01, 0.01, 0.03), vec3(0.02, 0.03, 0.05), smoothstep(0.5, -0.3, uv.y));
    
    // Stars - twinkle with treble
    for (float i = 0.0; i < 80.0; i++) {
        vec2 starPos = vec2(hash(vec2(i, 0.0)) * 2.4 - 1.2, hash(vec2(i, 1.0)) * 1.0 + 0.1);
        float starSize = hash(vec2(i, 2.0)) * 0.002 + 0.001;
        float twinkle = sin(t * 3.0 + i * 1.7) * 0.3 + 0.7 + treble * 0.2;
        float star = smoothstep(starSize, 0.0, length(uv - starPos));
        col += vec3(0.8, 0.9, 1.0) * star * twinkle;
    }
    
    // Aurora layers - bass affects intensity
    float auroraIntensity = 1.0 + bass * 0.5;
    float a1 = aurora(uv, t, 0.0, bass) * auroraIntensity;
    float a2 = aurora(uv * 0.8 + vec2(0.3, 0.0), t * 0.8, 2.0, mid);
    float a3 = aurora(uv * 1.2 + vec2(-0.2, 0.05), t * 1.1, 4.5, treble);
    
    // Aurora colors - mid shifts hue
    vec3 auroraCol1 = vec3(0.2, 0.9 + mid * 0.1, 0.4);
    vec3 auroraCol2 = vec3(0.3, 0.7, 0.5 + treble * 0.2);
    vec3 auroraCol3 = vec3(0.5 + bass * 0.2, 0.3, 0.7);
    
    float heightFactor = smoothstep(0.0, 0.5, uv.y);
    vec3 auroraMix = mix(auroraCol1, auroraCol3, heightFactor);
    
    col += auroraMix * a1 * 0.6;
    col += mix(auroraCol2, auroraCol1, 0.5) * a2 * 0.4;
    col += auroraCol3 * a3 * 0.3;
    
    float baseGlow = smoothstep(0.3, -0.1, uv.y) * (a1 + a2 * 0.5);
    col += vec3(0.1, 0.3, 0.15) * baseGlow * 0.5;
    
    // Ground
    float ground = smoothstep(-0.25, -0.28, uv.y);
    float trees = 0.0;
    for (float i = 0.0; i < 8.0; i++) {
        float x = uv.x * (3.0 + i * 0.5) + i * 1.7;
        float treeHeight = -0.25 + sin(x * 2.0) * 0.02 + noise(vec2(x * 5.0, i)) * 0.04;
        trees = max(trees, smoothstep(treeHeight, treeHeight - 0.02, uv.y));
    }
    col = mix(col, vec3(0.005, 0.008, 0.01), ground);
    col = mix(col, vec3(0.0, 0.005, 0.005), trees);
    
    float reflection = smoothstep(-0.35, -0.28, uv.y) * (1.0 - trees);
    col += (auroraCol1 * a1 + auroraCol2 * a2) * 0.1 * reflection;
    
    fragColor = vec4(sqrt(max(col, 0.0)), 1.0);
}

