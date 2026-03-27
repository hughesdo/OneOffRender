#version 330 core

// Fireflies at Dusk - Summer evening with glowing insects
// Created by OneHung
// Audio reactive firefly intensity and ambient glow
// https://www.shadertoy.com/view/wcKczt

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float fireflyBlink(float time, float seed, float audioBoost) {
    float period = 2.0 + hash(vec2(seed, 0.0)) * 3.0;
    float phase = hash(vec2(seed, 0.5)) * 6.28;
    float t = mod(time + phase, period) / period;
    float blink = smoothstep(0.0, 0.05, t) * smoothstep(0.3, 0.1, t);
    if (hash(vec2(seed, 0.7)) > 0.6) {
        float t2 = mod(time + phase + 0.3, period) / period;
        blink += smoothstep(0.0, 0.05, t2) * smoothstep(0.2, 0.1, t2) * 0.7;
    }
    return blink * (1.0 + audioBoost * 0.5);
}

float grass(vec2 uv, float x, float seed, float t) {
    float h = 0.15 + hash(vec2(x, seed)) * 0.25;
    float lean = (hash(vec2(x + 0.1, seed)) - 0.5) * 0.3;
    float width = 0.003 + hash(vec2(x + 0.2, seed)) * 0.004;
    float sway = sin(t * 0.8 + x * 5.0 + seed) * 0.02;
    float bladeX = x + lean * uv.y / h + sway * uv.y / h;
    float blade = smoothstep(width, 0.0, abs(uv.x - bladeX));
    blade *= smoothstep(-0.02, 0.0, uv.y);
    blade *= smoothstep(h, h * 0.7, uv.y);
    return blade;
}

void main() {
    vec2 C = gl_FragCoord.xy;
    vec2 R = iResolution.xy;
    vec2 uv = (C - 0.5 * R) / R.y;
    float t = iTime;
    
    // Audio
    float bass = texture(iChannel0, vec2(0.05, 0.25)).x;
    float mid = texture(iChannel0, vec2(0.3, 0.25)).x;
    float treble = texture(iChannel0, vec2(0.7, 0.25)).x;
    bass = smoothstep(0.0, 0.6, bass);
    mid = smoothstep(0.0, 0.5, mid);
    treble = smoothstep(0.1, 0.4, treble);
    
    // Twilight sky gradient
    vec3 skyTop = vec3(0.15, 0.1, 0.25);
    vec3 skyMid = vec3(0.35, 0.2, 0.35);
    vec3 skyHorizon = vec3(0.6, 0.35, 0.25);
    vec3 skyLow = vec3(0.3, 0.15, 0.2);
    
    float skyPos = uv.y + 0.3;
    vec3 sky = mix(skyLow, skyHorizon, smoothstep(-0.1, 0.1, skyPos));
    sky = mix(sky, skyMid, smoothstep(0.1, 0.4, skyPos));
    sky = mix(sky, skyTop, smoothstep(0.4, 0.8, skyPos));
    vec3 col = sky;
    
    // Stars - twinkle with treble
    for (float i = 0.0; i < 40.0; i++) {
        vec2 starPos = vec2(hash(vec2(i, 1.3)) * 2.0 - 1.0, hash(vec2(i, 2.7)) * 0.5 + 0.3);
        starPos.x *= R.x / R.y;
        float starBright = hash(vec2(i, 3.1)) * smoothstep(0.2, 0.5, starPos.y);
        starBright *= 0.7 + 0.3 * sin(t * (2.0 + hash(vec2(i, 4.0))) + i) + treble * 0.2;
        float star = smoothstep(0.003, 0.0, length(uv - starPos));
        col += vec3(0.9, 0.85, 0.8) * star * starBright * 0.8;
    }
    
    // Distant tree line
    float treeLine = -0.15;
    for (float i = 0.0; i < 10.0; i++) {
        float x = (i / 10.0) * 2.5 - 1.25;
        float treeH = 0.1 + hash(vec2(i, 10.0)) * 0.15;
        float treeW = 0.05 + hash(vec2(i, 11.0)) * 0.08;
        float tree = smoothstep(treeW, 0.0, abs(uv.x - x));
        tree *= smoothstep(treeLine + treeH, treeLine, uv.y);
        tree *= smoothstep(treeLine - 0.02, treeLine + 0.02, uv.y);
        col = mix(col, vec3(0.02, 0.03, 0.05), tree);
    }
    
    // Grass field
    float groundLevel = -0.25;
    for (float layer = 0.0; layer < 3.0; layer++) {
        float layerY = groundLevel - layer * 0.08;
        float layerDensity = 80.0 - layer * 20.0;
        float darkness = 0.02 + layer * 0.015;
        for (float i = 0.0; i < 80.0; i++) {
            if (i >= layerDensity) break;
            float x = (i / layerDensity) * 2.4 - 1.2 + hash(vec2(i, layer + 20.0)) * 0.03;
            vec2 grassUV = uv - vec2(0.0, layerY);
            float g = grass(grassUV, x, layer * 100.0 + i, t);
            col = mix(col, vec3(darkness), g);
        }
    }
    col = mix(col, vec3(0.015, 0.02, 0.01), smoothstep(groundLevel, groundLevel - 0.05, uv.y));
    
    // FIREFLIES - audio reactive intensity
    for (float i = 0.0; i < 35.0; i++) {
        float seed = i * 127.1;
        vec2 basePos = vec2(hash(vec2(seed, 0.0)) * 2.0 - 1.0, hash(vec2(seed, 1.0)) * 0.4 - 0.3);
        basePos.x *= 0.9;
        vec2 drift = vec2(
            sin(t * 0.3 + seed) * 0.1 + sin(t * 0.7 + seed * 2.0) * 0.05,
            cos(t * 0.4 + seed) * 0.06 + sin(t * 0.2 + seed) * 0.03
        );
        vec2 fireflyPos = basePos + drift;
        float depth = 0.3 + hash(vec2(seed, 2.0)) * 0.7;
        float size = 0.008 / depth;
        
        // Audio affects blink intensity
        float audioMod = (i < 12.0) ? bass : (i < 24.0) ? mid : treble;
        float blink = fireflyBlink(t, seed, audioMod);
        
        float d = length(uv - fireflyPos);
        float core = smoothstep(size, 0.0, d) * blink;
        float glow = exp(-d * 40.0 * depth) * blink * 0.5;
        
        vec3 fireflyCol = vec3(0.7, 0.9, 0.3);
        fireflyCol = mix(fireflyCol, vec3(0.9, 0.8, 0.2), hash(vec2(seed, 3.0)) * 0.3);
        fireflyCol += vec3(bass * 0.1, mid * 0.05, 0.0); // Subtle color shift
        
        col += fireflyCol * core * 2.0;
        col += fireflyCol * glow * 0.8;
    }
    
    // Ambient glow - bass reactive
    float ambientGlow = smoothstep(0.0, -0.4, uv.y) * (0.03 + bass * 0.02);
    col += vec3(0.4, 0.5, 0.2) * ambientGlow;
    
    col *= 1.0 - length(uv) * 0.2;
    col = pow(col, vec3(0.95, 1.0, 1.05));
    
    fragColor = vec4(sqrt(max(col, 0.0)), 1.0);
}

