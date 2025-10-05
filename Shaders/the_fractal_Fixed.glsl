#version 330 core

// the_fractal - OneOffRender Version
// Converted from GLSL Sandbox format to OneOffRender
// Menger sponge fractal with audio reactivity

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

float crossDist( in vec3 p ) {
    vec3 absp = abs(p);
    float d = 0.0;
    for(float i = 0.0, m; i++ < 3.0;){
        d += step(m = max(absp.y, absp.z), absp.x) * m;
        absp.xyz = absp.yzx;
    }
    float cr = 1.0 - d;
    float cu = max(max(absp.x, absp.z), absp.y) - 3.0;
    return max(cr, cu);
}

// menger sponge fractal
float fractal( in vec3 p ) {
    vec3 pp = p;
    float scale = 1.0;
    float dist = 0.0;
    for (int i = 0 ; i < 4 ; i++) {
        dist = max(dist, crossDist(p) * scale);
        p = fract((p - 1.0) * 0.5) * 6.0 - 3.0;
        scale /= 3.0;
    }
    return dist;
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

vec3 pal(float t) {
    return 0.5 + 0.5 * cos(6.28 * (1.0 * t + vec3(0.0, 0.3, 0.7)));
}

void main() {
    vec2 r = iResolution;
    vec2 uv = (gl_FragCoord.xy * 2.0 - r) / min(r.x, r.y);
    
    // Audio-reactive speedup instead of mouse control
    bool speedup = getFFT(0.1) > 0.3;
    
    vec3 col = vec3(0.0);
    float rnd = fract(758.7 * sin(dot(uv, vec2(486.426, 751.953))));
    vec3 p, d = normalize(vec3(uv, 0.8 - 0.05 * sqrt(max(0.1, length(uv) - 0.3)) * rnd));
    
    float t = iTime * 0.2;
    
    // Audio-reactive time modulation
    t += getFFTSmoothed(0.05) * 2.0;
    
    t *= 2.0;
    t = floor(t) + pow(fract(t), 0.05);
    t += iTime * 0.2;
    t = speedup ? iTime : t;
    
    for(float i, e, g; i++ < 50.0;) {
        p = d * g;
        vec3 op = p;
        
        // Audio-reactive movement patterns
        float audioMod = getFFT(0.2) * 10.0;
        
        if(mod(t, (speedup ? 12.0 : 6.0)) < 2.0) {
            p.x += 20.0 + 10.0 * ((t * 0.5)) + audioMod;
            p.yz *= rot(t + getFFTSmoothed(0.1) * 2.0);
        }
        else if(mod(t, (speedup ? 12.0 : 6.0)) < 4.0) { 
            p.y += 20.0 + 10.0 * ((t * 0.5)) + audioMod; 
            p.xz *= rot(t + getFFTSmoothed(0.15) * 2.0);
        }
        else { 
            p.xy *= rot(t + p.z * 0.1 + rnd * 0.025 * sqrt(length(uv)) + getFFT(0.3) * 1.0); 
            p.z += 20.0 + 10.0 * ((t * 0.5)) + audioMod;  
            p.x += sin(t) + getFFTSmoothed(0.25) * 3.0;
        }
        
        p.zxy = asin(sin(p.zxy / 1.8)) * 1.8;
        
        float h = max(abs(p.z) - 3.0, fractal(p));
        
        g += e = max(0.0001, abs(h));
        float tt = tanh(sin(length(p) + rnd * 0.01) * 5.0);
        
        // Audio-reactive coloring
        vec3 baseColor = pal(0.9 + rnd * 0.1 + tt + t * 2.0 + length(p));
        baseColor += getFFT(0.1) * vec3(1.0, 0.5, 0.8);
        
        vec3 fractalColor = vec3(0.0015) * fract(105.0 * dot(floor(p * 5.0) / 10.0, vec3(225.35, 355.35, 953.35)));
        fractalColor += getFFTSmoothed(0.2) * vec3(0.5, 1.0, 0.3);
        
        col += mix(baseColor * 0.05, fractalColor, clamp(tt, 0.0, 1.0)) / exp((1.0 - fract(-op.z * 0.1 + t * 2.0)) * e * i * i);
    }
    
    fragColor = vec4(sqrt(col), 1.0);
}
