#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// Layer 1: Chromatic Flowing Waves
// Raymarched undulating surface with rich rainbow color blending
// Optimized for sharper colors and better performance

// --- Noise functions ---
float hash(vec3 p) {
    p = fract(p * vec3(443.897, 441.423, 437.195));
    p += dot(p, p.yzx + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float n000 = hash(i);
    float n100 = hash(i + vec3(1,0,0));
    float n010 = hash(i + vec3(0,1,0));
    float n110 = hash(i + vec3(1,1,0));
    float n001 = hash(i + vec3(0,0,1));
    float n101 = hash(i + vec3(1,0,1));
    float n011 = hash(i + vec3(0,1,1));
    float n111 = hash(i + vec3(1,1,1));
    
    return mix(
        mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
        mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
        f.z
    );
}

float fbm(vec3 p) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100.0);
    mat3 rot = mat3(
        cos(0.5), sin(0.5), 0,
        -sin(0.5), cos(0.5), 0,
        0, 0, 1
    );
    for (int i = 0; i < 5; i++) {  // Reduced from 6 to 5
        v += a * noise3D(p);
        p = rot * p * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

// Sharper, more vibrant palette
vec3 palette(float t) {
    // Vibrant: deep blue -> cyan -> magenta -> orange -> yellow -> back
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.5, 1.2, 1.8);  // Increased frequency for more color variation
    vec3 d = vec3(0.0, 0.1, 0.2);
    return a + b * cos(6.28318 * (c * t + d));
}

vec3 palette2(float t) {
    // Hot palette: red -> orange -> gold -> green -> cyan
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(2.0, 1.5, 1.0);
    vec3 d = vec3(0.0, 0.33, 0.67);
    return a + b * cos(6.28318 * (c * t + d));
}

// SDF for the wave surface
float waveSurface(vec3 p) {
    float t = iTime * 0.3;
    
    float waves = 0.0;
    
    // Primary large waves
    waves += sin(p.x * 0.8 + t * 1.2) * cos(p.z * 0.6 + t * 0.8) * 0.5;
    waves += sin(p.x * 1.3 - t * 0.9 + p.z * 0.4) * 0.35;
    
    // Secondary rolling waves
    waves += sin(p.x * 2.1 + t * 1.5 + p.z * 1.8) * 0.15;
    waves += cos(p.z * 2.5 - t * 1.1 + p.x * 0.7) * 0.12;
    
    // Reduced FBM turbulence for cleaner look
    float turb = fbm(p * 0.5 + vec3(t * 0.2, 0.0, t * 0.15)) * 0.4;
    waves += turb;
    
    // Curling wave crests
    float curl = sin(p.x * 1.5 + t + waves * 2.0) * 0.2;
    curl *= smoothstep(0.0, 0.5, waves + 0.3);
    waves += curl;
    
    return p.y - waves;
}

// Optimized color with sharper contrast
vec3 waveColor(vec3 p) {
    float t = iTime * 0.15;
    
    // Reduced FBM calls for performance
    float c1 = fbm(p * 0.4 + vec3(t, t * 0.7, -t * 0.5));
    float c2 = fbm(p * 0.6 + vec3(-t * 0.8, t * 0.3, t * 0.6));
    
    // Mix vibrant palettes
    vec3 col1 = palette(c1 + p.x * 0.15 + t);
    vec3 col2 = palette2(c2 + p.z * 0.2 - t * 0.5);
    
    // Sharper mixing with higher contrast
    vec3 col = mix(col1, col2, smoothstep(0.3, 0.7, c1));
    
    // Add deep contrast in troughs - sharper transition
    float trough = smoothstep(0.2, -0.4, p.y);
    col = mix(col, vec3(0.02, 0.05, 0.2), trough * 0.7);
    
    // Bright highlights on crests - more intense
    float crest = smoothstep(0.2, 0.6, p.y + fbm(p * 0.8) * 0.25);
    col += vec3(0.5, 0.35, 0.15) * crest;
    
    return col;
}

// Optimized normal calculation
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.003, 0.0);
    return normalize(vec3(
        waveSurface(p + e.xyy) - waveSurface(p - e.xyy),
        waveSurface(p + e.yxy) - waveSurface(p - e.yxy),
        waveSurface(p + e.yyx) - waveSurface(p - e.yyx)
    ));
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Camera setup
    float camT = iTime * 0.1;
    vec3 ro = vec3(sin(camT) * 2.0, 3.5 + sin(iTime * 0.2) * 0.5, -5.0 + cos(camT) * 2.0);
    vec3 target = vec3(0.0, 0.0, 0.0);
    
    vec3 fwd = normalize(target - ro);
    vec3 right = normalize(cross(fwd, vec3(0, 1, 0)));
    vec3 up = cross(right, fwd);
    vec3 rd = normalize(fwd * 1.5 + right * uv.x + up * uv.y);
    
    // Raymarching - reduced iterations, faster stepping
    float t = 0.0;
    float d;
    vec3 p;
    bool hit = false;
    
    for (int i = 0; i < 80; i++) {  // Reduced from 120 to 80
        p = ro + rd * t;
        d = waveSurface(p);
        if (abs(d) < 0.002) {
            hit = true;
            break;
        }
        t += d * 0.7;  // Faster stepping
        if (t > 25.0) break;
    }
    
    vec3 col = vec3(0.0);
    
    if (hit) {
        vec3 n = calcNormal(p);
        
        vec3 baseCol = waveColor(p);
        
        // Stronger lighting for color pop
        vec3 lightDir1 = normalize(vec3(0.5, 1.0, -0.3));
        vec3 lightDir2 = normalize(vec3(-0.8, 0.5, 0.6));
        
        float diff1 = max(dot(n, lightDir1), 0.0);
        float diff2 = max(dot(n, lightDir2), 0.0);
        
        // Specular
        vec3 viewDir = normalize(ro - p);
        vec3 halfDir1 = normalize(lightDir1 + viewDir);
        float spec1 = pow(max(dot(n, halfDir1), 0.0), 48.0);
        
        vec3 halfDir2 = normalize(lightDir2 + viewDir);
        float spec2 = pow(max(dot(n, halfDir2), 0.0), 24.0);
        
        // Fresnel
        float fresnel = pow(1.0 - max(dot(n, viewDir), 0.0), 2.5);
        
        // Sharper color composition
        col = baseCol * 0.25;  // Increased ambient
        col += baseCol * diff1 * 0.7 * vec3(1.0, 0.95, 0.85);
        col += baseCol * diff2 * 0.35 * vec3(0.7, 0.8, 1.0);
        col += spec1 * vec3(1.0, 0.9, 0.8) * 0.6;
        col += spec2 * vec3(0.6, 0.7, 1.0) * 0.3;
        
        // Iridescent fresnel edge - more vibrant
        vec3 iridescentEdge = palette(fresnel * 3.0 + iTime * 0.15 + p.x * 0.15);
        col += iridescentEdge * fresnel * 0.5;
        
        // Reduced fog for sharper colors
        float fog = exp(-t * 0.05);
        col *= fog;
        
        // Stronger saturation boost
        float grey = dot(col, vec3(0.299, 0.587, 0.114));
        col = mix(vec3(grey), col, 1.8);  // Increased from 1.4 to 1.8
    }
    
    // Vignette
    float vig = 1.0 - 0.35 * length(uv);
    col *= vig;
    
    // Sharper tone mapping - preserve more color
    col = col / (col + 0.5);  // Less crushing
    col = pow(col, vec3(0.85));  // Less gamma
    
    // Slight bloom effect for color pop
    col += col * col * 0.15;
    
    fragColor = vec4(col, 1.0);
}