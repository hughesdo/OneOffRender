// https://www.shadertoy.com/view/t3Kyzd
// A8 - Kimi test 2 - Liquid Chrome Worm
// Converted to OneOffRender format with audio-reactive color & turbulence

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

// ===== AUDIO REACTIVITY TWEAKS =====
#define AUDIO_COLOR_SHIFT    0.3   // How much bass shifts the color palette hue
#define AUDIO_IRIDESCENCE    0.5   // How much mids affect iridescence intensity
#define AUDIO_RIPPLE_AMP     2.0   // How much highs amplify surface ripple/turbulence
#define AUDIO_GLOW_AMT       0.4   // How much bass pumps the overall brightness
#define AUDIO_SPECTRUM_PUSH  0.6   // How much mids push spectrum color intensity

// Audio helpers
float getBass()  { return (texture(iChannel0, vec2(0.02, 0.0)).x + texture(iChannel0, vec2(0.04, 0.0)).x) * 0.5; }
float getMid()   { return (texture(iChannel0, vec2(0.15, 0.0)).x + texture(iChannel0, vec2(0.25, 0.0)).x) * 0.5; }
float getHigh()  { return (texture(iChannel0, vec2(0.5, 0.0)).x  + texture(iChannel0, vec2(0.7, 0.0)).x)  * 0.5; }

#define PI 3.14159265359
#define TAU 6.28318530718
#define MAX_STEPS 128
#define MAX_DIST 40.0
#define SURF_DIST 0.0005

// Rotation
mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

// Smooth minimum for liquid blending
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

// Hash
float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

float hash(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

// Spectrum
vec3 spectrum(float x) {
    return 0.5 + 0.5 * cos(TAU * (vec3(0.0, 0.33, 0.67) + x));
}

// Noise
float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f *= f * (3.0 - 2.0 * f);
    float n = i.x + i.y * 157.0 + i.z * 311.0;
    return mix(mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
                   mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y),
               mix(mix(hash(n + 311.0), hash(n + 312.0), f.x),
                   mix(hash(n + 468.0), hash(n + 469.0), f.x), f.y), f.z);
}

// FBM
float fbm(vec3 p) {
    float v = 0.0, a = 0.5;
    for(int i = 0; i < 4; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// Palettes
vec3 winterPal(float t) {
    return 0.5 + 0.5 * cos(TAU * (vec3(0.5, 0.6, 0.7) * t + vec3(0.0, 0.1, 0.2)));
}

vec3 iridescent(float cosTheta, float thickness) {
    float phase = thickness * 20.0;
    return 0.5 + 0.5 * cos(TAU * (vec3(0.8, 0.5, 0.3) * phase + cosTheta));
}

// SDF Primitives
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// The Liquid Chrome Soft-Body
float sdLiquidWorm(vec3 p) {
    float t = iTime * 0.8;
    vec3 q = p;
    
    float travel = sin(t * 0.5) * 8.0;
    float d = 100.0;
    float k = 0.8;
    
    for(int i = 0; i < 8; i++) {
        float fi = float(i);
        float phase = fi * 0.8 + t * 2.0;
        
        vec3 center;
        center.x = 8.0 - mod(fi * 1.5 + t * 3.0, 16.0) + travel * 0.3;
        center.y = sin(phase) * 0.8 + cos(phase * 0.5) * 0.4;
        center.z = cos(phase * 0.7) * 1.5;
        
        float r = 0.6 + 0.2 * sin(phase * 2.0) + 0.1 * noise(q * 3.0 + t);
        float sphere = sdSphere(q - center, r);
        d = smin(d, sphere, k);
    }
    
    float high = getHigh();
    float ripple = noise(q * 15.0 - t * 2.0) * 0.02 * (1.0 + high * AUDIO_RIPPLE_AMP);
    return d - ripple;
}

// Background crystal snake
float sdCrystalSnake(vec3 p) {
    float t = p.z * 0.3;
    vec3 pos = p;
    pos.x += sin(t) * 2.0;
    pos.y += cos(t * 0.7) * 0.5;
    
    float seg = 5.0;
    float zig = mod(pos.z, seg) - seg * 0.5;
    vec3 local = vec3(pos.x, pos.y, zig);
    
    local.xy *= rot(zig * 0.4);
    local.y -= 1.5;
    
    return sdBox(local, vec3(0.3, 0.1, 0.4));
}

// Ice trees
float sdIceTree(vec3 p, vec3 treePos) {
    vec3 local = p - treePos;
    float bend = sin(local.y * 0.5) * 0.3;
    local.x += bend;
    
    float thickness = 0.1 * (1.0 - smoothstep(0.0, 8.0, local.y));
    float d = length(local.xz) - thickness;
    d = max(d, local.y - 8.0);
    d = max(d, -local.y);
    
    if(local.y > 2.0 && local.y < 6.0) {
        vec3 branch = local;
        branch.y = mod(branch.y, 2.0) - 1.0;
        branch.x -= 0.5;
        branch.z *= 0.2;
        float br = sdBox(branch, vec3(0.4, 0.02, 0.02));
        d = min(d, br);
    }
    return d;
}

// Scene mapping
float map(vec3 p, out float mat) {
    mat = 0.0;
    
    float worm = sdLiquidWorm(p);
    if(worm < 0.1) {
        mat = 0.0;
        return worm;
    }
    
    float snake = sdCrystalSnake(p);
    float trees = 100.0;
    
    for(int i = 0; i < 3; i++) {
        float fi = float(i);
        vec3 tp = vec3(
            sin(fi * 2.0) * 4.0,
            0.0,
            -5.0 + fi * 8.0 + floor(iTime * 0.2) * 8.0
        );
        trees = min(trees, sdIceTree(p, tp));
    }
    
    float env = min(snake, trees);
    if(env < worm) mat = (env == snake) ? 1.0 : 2.0;
    
    return min(worm, env);
}

// Normal calculation
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    float m;
    return normalize(vec3(
        map(p + e.xyy, m) - map(p - e.xyy, m),
        map(p + e.yxy, m) - map(p - e.yxy, m),
        map(p + e.yyx, m) - map(p - e.yyx, m)
    ));
}

void mainImage(out vec4 O, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Audio sampling
    float bass = getBass();
    float mid  = getMid();
    float high = getHigh();

    float camT = iTime * 0.15;
    vec3 ro = vec3(sin(camT) * 2.0, 1.0 + cos(camT * 0.5) * 0.5, -5.0);
    vec3 lookAt = vec3(0.0, 0.0, 5.0);

    vec3 ww = normalize(lookAt - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + 1.5 * ww);

    vec3 col = vec3(0.85, 0.9, 0.95);
    float t = 0.0;
    float mat;

    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + t * rd;
        float d = map(p, mat);

        if(d < SURF_DIST || t > MAX_DIST) break;
        t += d * 0.8;
    }

    if(t < MAX_DIST) {
        vec3 pos = ro + t * rd;
        vec3 nor = calcNormal(pos);

        if(mat < 0.5) {
            // Liquid Chrome — audio shifts color
            vec3 view = -rd;
            vec3 tangent = normalize(vec3(
                cos(pos.z * 2.0 + iTime),
                sin(pos.z * 1.5),
                1.0
            ));

            vec3 halfVec = normalize(view + vec3(0.5, 1.0, 0.3));
            float TdotH = dot(tangent, halfVec);
            float NdotH = max(dot(nor, halfVec), 0.001);
            float aniso = exp(-2.0 * (TdotH * TdotH) / (0.3 * NdotH));

            float fresnel = 1.0 - max(dot(nor, view), 0.0);
            vec3 fCol;
            fCol.r = pow(fresnel, 2.0);
            fCol.g = pow(fresnel, 2.5);
            fCol.b = pow(fresnel, 3.0);

            // Audio: bass shifts iridescence, mid pushes film
            float filmOffset = mid * AUDIO_IRIDESCENCE;
            float film = iridescent(fresnel, length(pos) * 0.5 + iTime + filmOffset).x;
            vec3 ref = reflect(rd, nor);
            vec3 sky = winterPal(ref.y * 0.5 + iTime * 0.1 + bass * AUDIO_COLOR_SHIFT);

            vec3 baseMetal = vec3(0.9, 0.95, 1.0);
            col = baseMetal * 0.3 + fCol * film * 2.0 + sky * fresnel * 0.5;
            col += spectrum(aniso + iTime * 0.2 + bass * AUDIO_COLOR_SHIFT) * aniso * fresnel * (3.0 + mid * AUDIO_SPECTRUM_PUSH);

        } else if(mat < 1.5) {
            // Crystal Snake
            vec3 light = normalize(vec3(1.0, 2.0, 1.0));
            float diff = max(dot(nor, light), 0.0);
            col = vec3(0.7, 0.85, 0.9) * (0.2 + diff * 0.8);
            col += winterPal(length(pos) * 0.1 + bass * AUDIO_COLOR_SHIFT) * 0.1;

        } else {
            // Ice Trees
            col = vec3(0.9, 0.95, 1.0) * (0.5 + 0.5 * nor.y);
        }

        col = mix(col, vec3(0.9, 0.95, 1.0), smoothstep(5.0, MAX_DIST, t));
    }

    col = pow(col, vec3(0.9));
    col *= 1.2 + bass * AUDIO_GLOW_AMT;

    vec2 q = fragCoord / iResolution.xy;
    col *= pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.1);

    O = vec4(col, 1.0);
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}