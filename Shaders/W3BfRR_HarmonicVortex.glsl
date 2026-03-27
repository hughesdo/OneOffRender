#version 330 core

// Harmonic Vortex - Audio Reactive
// Created by OneHung
// Flowing tunnel with audio-reactive distortion and frequency-based coloring
// https://www.shadertoy.com/view/W3BfRR

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

#define PI 3.14159265359
#define hue(v) (.6 + .6 * cos(6.28318 * (v) + vec3(0, -2.094, 2.094)))

float bass() { return texture(iChannel0, vec2(0.02, 0.25)).x; }
float mid() { return texture(iChannel0, vec2(0.15, 0.25)).x; }
float treble() { return texture(iChannel0, vec2(0.6, 0.25)).x; }
float sample1(float f) { return texture(iChannel0, vec2(f, 0.25)).x; }

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1, 0));
    float c = hash21(i + vec2(0, 1));
    float d = hash21(i + vec2(1, 1));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.;
    float a = 0.5;
    for(int i = 0; i < 4; i++) {
        v += noise(p) * a;
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec2 uv0 = uv;
    
    float b = bass() * 3.0;
    float m = mid() * 2.5;
    float t = treble() * 2.0;
    
    vec3 col = vec3(0);
    
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    
    float distortion = fbm(uv * 3.0 + iTime * 0.3) * (0.5 + m * 0.5);
    angle += distortion * 0.5;
    radius += sin(angle * 8.0 + iTime * 2.0) * 0.05 * b;
    
    vec2 tunnelUV = vec2(angle / PI, 0.5 / radius);
    tunnelUV.x += iTime * 0.3;
    tunnelUV.y += iTime * 0.5 + b * 0.2;
    
    for(float layer = 0.; layer < 3.; layer++) {
        vec2 tuv = tunnelUV * (2.0 + layer);
        vec2 gv = fract(tuv) - 0.5;
        vec2 id = floor(tuv);
        
        float freqSample = sample1(fract(layer * 0.333 + 0.1));
        
        float d = length(gv) - 0.3;
        d = abs(d) - 0.05 - freqSample * 0.1;
        
        float bars = abs(gv.x) - 0.02;
        bars = min(bars, abs(gv.y) - 0.02);
        
        float pattern = min(d, bars);
        pattern = smoothstep(0.02, 0.0, pattern);
        
        float glow = 0.02 / (abs(d) + 0.01);
        glow += 0.01 / (abs(bars) + 0.01);
        
        float pulse = sin(length(id) * 0.5 + iTime * 2.0 + b * 2.0) * 0.5 + 0.5;
        pulse = pow(pulse, 2.0);
        
        vec3 layerCol = hue(layer * 0.3 + tunnelUV.y * 0.5 + iTime * 0.1);
        vec3 freqCol = hue(freqSample + iTime * 0.2);
        layerCol = mix(layerCol, freqCol, 0.5);
        
        col += layerCol * (pattern + glow * 0.5) * (0.5 + pulse * 0.5);
    }
    
    float waves = sin(radius * 20.0 - iTime * 5.0 + b * 5.0);
    waves *= sin(radius * 15.0 + iTime * 3.0);
    waves = smoothstep(0.0, 1.0, waves);
    col += waves * 0.3 * hue(iTime * 0.3) * b;
    
    float ringDist = abs(radius - 0.5) - 0.02;
    if(ringDist < 0.1) {
        float ringAngle = (angle + PI) / (2.0 * PI);
        float freqVis = sample1(fract(ringAngle)) * 2.0;
        float ringGlow = exp(-abs(ringDist) * 50.0) * freqVis;
        col += ringGlow * hue(ringAngle + iTime * 0.1);
    }
    
    for(float i = 0.; i < 5.; i++) {
        float spiralAngle = angle + radius * 3.0 - iTime + i * 6.28318 / 5.0;
        float spiral = sin(spiralAngle * 1.0) * 0.5 + 0.5;
        spiral = pow(spiral, 10.0 + t * 5.0);
        spiral *= exp(-radius * 1.5);
        col += spiral * hue(i * 0.2 + iTime * 0.15) * t;
    }
    
    float center = exp(-radius * 3.0) * (1.0 + b * 2.0);
    col += center * hue(iTime * 0.5);
    
    float vignette = 1.0 - pow(length(uv0) * 0.7, 2.0);
    vignette *= 1.0 + sin(iTime * 8.0) * 0.1 * b;
    col *= vignette;
    
    if(b > 2.0) {
        float flash = (b - 2.0) * 0.5;
        col += flash;
    }
    
    float edge = smoothstep(0.3, 0.8, length(uv0));
    col.r *= 1.0 + edge * m * 0.1;
    col.b *= 1.0 + edge * t * 0.1;
    
    float scanline = sin(fragCoord.y * 2.0 + iTime * 100.0);
    col *= 1.0 + scanline * 0.02 * m;
    
    col = pow(col, vec3(0.9 - b * 0.1));
    
    fragColor = vec4(col, 1.0);
}

