#version 330 core

// the_grid - OneOffRender Version
// Converted from GLSL Sandbox format to OneOffRender
// Classic grid/tunnel effect with audio reactivity

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// Audio-reactive functions
float getFFT(float freq) {
    return texture(iChannel0, vec2(freq, 0.0)).r;
}

float getFFTSmoothed(float freq) {
    float sum = 0.0;
    float samples = 5.0;
    for(float i = 0.0; i < samples; i++) {
        float offset = (i - samples * 0.5) * 0.02;
        sum += texture(iChannel0, vec2(clamp(freq + offset, 0.0, 1.0), 0.0)).r;
    }
    return sum / samples;
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

void main()
{ 
    vec2 r = iResolution;
    
    // Audio-reactive mouse replacement
    vec2 audioOffset = vec2(getFFT(0.1), getFFTSmoothed(0.15)) * 0.5;
    vec2 uv = (gl_FragCoord.xy * 2.0 - r) / min(r.x, r.y) + audioOffset;
    
    vec3 col = vec3(0.0);
    float aa = 0.0, rnd;
    
    // Audio-reactive depth of field
    float dofMod = 0.8 - tanh(0.5 * sin(iTime + 0.1 * dot(sin(floor(uv * 9.5)), cos(floor(uv.yx * 7.0)))) * 25.0 + uv.x);
    dofMod += getFFT(0.2) * 0.5;
    
    vec3 p, d = normalize(vec3(uv, 1.0 - dofMod * 0.8 * sqrt(length(uv * 0.8))));
    float g = 0.0;
    
    // Audio-reactive BPM modulation
    float bpm = floor(iTime) + pow(fract(iTime), 0.7 - 0.1 * fract(542.4 * sin(dot(uv, vec2(243.4, 578.4525)))));
    bpm *= 5.0;
    bpm += getFFTSmoothed(0.05) * 10.0; // Audio-reactive BPM
    
    for(float i = 0.0, e; i++ < 20.0;) {
        for(aa = 0.0; aa++ < 3.0;) {
            vec3 p = d * g;
            vec3 oop = p;
            p.z += iTime;
            
            // Audio-reactive path modulation
            float pathMod = getFFT(0.3) * 2.0;
            float path = (1.0 - tanh(1.0 - abs(p.x - sin(p.z * 0.5) * 2.1 + cos(p.z * 0.3) * 0.37 + pathMod)));
            
            vec3 op = p;
            p.y = -(abs(p.y) + (0.5 + asin(sin(p.z)) * 0.25)) + path;
            p.y -= -2.5;
            
            float qq = sign(p.y);
            p.y = abs(p.y) - 1.05;
            
            if(qq < 0.0) {
                // Audio-reactive rotation
                p.xz *= rot(0.785 + getFFTSmoothed(0.1) * 1.0);
            }
            
            vec2 id = floor(p.xz);
            p.xz = fract(p.xz) - 0.5;
            
            // Audio-reactive grid thickness
            float thickness = 0.012 + getFFT(0.25) * 0.02;
            float h = min(length(p.yz), length(p.xy)) - thickness;
            
            g += e = max(0.001, abs(h) * 0.6);
            
            // Audio-reactive pattern modulation
            float audioPattern = getFFTSmoothed(0.2) * 3.0;
            float q = e <= 0.021 ? 
                length(asin(sin((mod(iTime, 6.28 * 2.0) > 6.28 ? length(id) : 0.0) + 
                oop.xz * 0.25 + vec2(asin(sin(bpm * 0.5)) - path, bpm * 1.0) + rnd + audioPattern))) * 2.0 : 0.5;
            
            // Audio-reactive coloring
            vec3 baseColor = vec3(1.0) * 0.75;
            baseColor += getFFT(0.1) * vec3(1.0, 0.5, 0.8);
            
            col += max(vec3(0.0), baseColor / exp(0.25 * i * i * e + q));
        }
    }
    
    // Audio-reactive background color
    vec3 bgColor = vec3(0.1, 0.1, 0.25);
    bgColor += getFFTSmoothed(0.05) * vec3(0.3, 0.6, 1.0);
    
    col = mix(col / aa, bgColor, 0.75 - exp2(-g));
    
    fragColor = vec4(col, 1.0);
}
