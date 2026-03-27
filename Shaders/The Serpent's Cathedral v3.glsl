#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;
uniform vec4 iMouse;

out vec4 fragColor;

/** KaliTrace+Light - The Serpent's Cathedral v3

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;


    Original: https://www.shadertoy.com/view/MsKSDG
    (cc) 2016, stefan berke

    IMPROVEMENTS:
    - Enhanced reflectivity with micro-bump normals
    - Better environment map with reflected light gathering
    - Safer camera path with collision-aware corridor design
    - Improved specular and fresnel effects
*/

// ============== TWEAKABLES ==============
#define AUDIO_STRENGTH      1.6
#define BASS_MULT           0.8
#define MID_MULT            0.6
#define HIGH_MULT           0.7

#define SERPENT_BASE_RADIUS 0.03
#define SERPENT_AUDIO_PULSE 0.015
#define SERPENT_WAVE_AMP    0.12
#define SERPENT_WAVE_FREQ   2.5
#define SERPENT_WAVE_SPEED  2.0

#define SCALE_DEPTH         0.003
#define SCALE_COUNT         40.0

#define KALI_ITERATIONS     9
#define LIGHT_GLOW          0.3
#define LIGHT_AUDIO_BOOST   0.25

#define SKULL_DENSITY       0.95
#define SKULL_SCALE         5.0
#define SKULL_EYE_GLOW      0.5

#define CAM_SPEED           0.14

// === NEW: Reflection quality settings ===
#define REFLECTION_TRACE_STEPS  15   // Steps for reflected light gathering
#define MICRO_BUMP_STRENGTH     0.04 // Micro-bump intensity for sparkle
#define BUMP_SCALE_1            0.1  // Primary bump displacement
#define BUMP_SCALE_2            30.0 // Micro-bump frequency
// ========================================

// Audio
vec3 audio;
void sampleAudio() {
    audio = vec3(
        texture(iChannel0, vec2(0.05, 0.0)).x * BASS_MULT,
        texture(iChannel0, vec2(0.2, 0.0)).x * MID_MULT,
        texture(iChannel0, vec2(0.5, 0.0)).x * HIGH_MULT
    ) * AUDIO_STRENGTH;
}

// Utilities
mat2 rot2(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

// ============== SKULL FEATURES FOR WALLS ==============
float skullSMin(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k*h*(1.0-h);
}

float skullSMax(float d1, float d2, float k) {
    float h = clamp(0.5 - 0.5*(d2+d1)/k, 0.0, 1.0);
    return mix(d2, -d1, h) + k*h*(1.0-h);
}

float skullSphere(vec3 p, float s) {
    return length(p) - s;
}

float skullEllipsoid(vec3 p, vec3 r) {
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float skullCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}

float skullHollowSphere(vec3 p, float r, float h, float t) {
    float w = sqrt(r*r - h*h);
    vec2 q = vec2(length(p.xz), p.y);
    return ((h*q.x < w*q.y) ? length(q - vec2(w,h)) : abs(length(q) - r)) - t;
}

float skullRBox(vec3 p, vec3 b, float r) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

float skull(vec3 p) {
    p *= 20.0;
    float d = 1e10;
    
    float head = skullEllipsoid(p, vec3(0.9, 1.1, 1.2));
    float cutB = p.y + 0.7 + sin(p.x * 21.0) * 0.02;
    cutB = skullSMin(cutB, skullEllipsoid(p - vec3(0.0, -0.3, -0.2), vec3(0.7)), 0.0);
    cutB = skullSMin(cutB, skullEllipsoid(p - vec3(0.0, -0.24, 0.5), vec3(0.51)), 0.1);
    head = skullSMax(cutB, head, 0.05);
    head = skullSMax(-p.z + 1.1, head, 0.2);
    
    float tempCut = skullCapsule(vec3(-abs(p.x), p.yz), vec3(-1.0, -1.0, 0.8), vec3(-1.8, 3.0, 0.0), 0.5);
    head = skullSMax(tempCut, head, 0.3);
    float sideCut = skullCapsule(p, vec3(-2.0, -1.1, 0.6), vec3(2.0, -1.1, 0.6), 0.6);
    head = skullSMax(sideCut, head, 0.3);
    d = head;
    
    vec3 pz = vec3(abs(p.x), p.yz);
    pz.x += sin(pz.z * 4.0 + 3.14159) * 0.08;
    pz.y += cos(pz.z * 9.0) * 0.03;
    float zyg = skullCapsule(pz, vec3(0.5, -0.3, 0.8), vec3(0.75, -0.3, 0.1), pz.z * 0.1);
    d = skullSMin(d, zyg, 0.06);
    
    vec3 pj = p - vec3(0.0, -0.5, 0.7);
    float ujaw = skullEllipsoid(pj, vec3(0.4, 0.2, 0.35));
    ujaw = skullSMax(p.z - 0.6, ujaw, 0.05);
    
    vec3 pjc = vec3(abs(p.x), p.yz);
    float ca = cos(-1.0), sa = sin(-1.0);
    pjc.xy = mat2(ca, -sa, sa, ca) * pjc.xy;
    ca = cos(-0.4); sa = sin(-0.4);
    pjc.yz = mat2(ca, -sa, sa, ca) * pjc.yz;
    pjc.y += 0.3;
    ujaw = skullSMax(pjc.y, ujaw, 0.04);
    
    d = skullSMin(ujaw, d, 0.1);
    d -= sin(10.0 * p.x) * sin(8.0 * p.y) * sin(7.0 * p.z) * 0.01;
    
    vec3 pe = p - vec3(0.0, 0.3, 0.0);
    float cheek = skullEllipsoid(vec3(abs(pe.x), pe.yz) + vec3(-0.34, 0.5, -0.87), vec3(0.25, 0.24, 0.2));
    cheek += sin(12.0 * p.x) * sin(9.0 * p.y) * sin(13.0 * p.z) * 0.05;
    d = skullSMin(cheek, d, 0.2);
    
    vec3 peye = p;
    peye += sin(peye.x * 29.0 + cos(peye.y * 32.0)) * 0.008;
    float eye = skullEllipsoid(vec3(abs(peye.x), peye.y - 0.4, peye.z) + vec3(-0.29, 0.49, -1.1), vec3(0.21, 0.25, 0.25));
    eye = skullSMin(eye, skullSphere(vec3(abs(p.x), p.yz) - vec3(0.25, 0.0, 0.7), 0.35), 0.05);
    eye = skullSMax(-peye.y, eye, 0.2);
    d = skullSMax(eye, d, 0.05);
    
    vec3 pnb = p - vec3(0.0, -0.15, 0.95);
    float nbone = skullCapsule(pnb, vec3(0.0, 0.15, 0.0), vec3(0.0, -0.1, 0.15), 0.06);
    d = skullSMin(d, nbone, 0.05);
    
    vec3 pn = vec3(abs(p.x), p.yz);
    float ca3 = cos(-0.4), sa3 = sin(-0.4);
    pn.xy = mat2(ca3, -sa3, sa3, ca3) * pn.xy;
    float nose = skullEllipsoid(pn - vec3(-0.1, -0.3, 1.0), vec3(0.05, 0.12, 0.15));
    d = skullSMax(nose, d, 0.06);
    
    vec3 pL = p;
    pL.z -= 0.5;
    pL.y += 0.4;
    float ca2 = cos(-0.15), sa2 = sin(-0.15);
    pL.yz = mat2(ca2, -sa2, sa2, ca2) * pL.yz;
    pL.z += 0.5;
    pL.y -= 0.4;
    
    float chin = skullSphere(pL + vec3(0.0, 0.65, -0.6), 0.25);
    vec3 pJs = vec3(abs(pL.x), pL.yz);
    float jawSide = skullCapsule(pJs, vec3(0.15, 0.5, -0.5), vec3(0.55, 0.1, 0.1), 0.1);
    float ljaw = skullSMin(chin, jawSide, 0.15);
    ljaw = skullSMax(pL.y + 0.85, ljaw, 0.02);
    d = skullSMin(ljaw, d, 0.08);
    
    vec3 pt = p - vec3(0.0, -0.65, 0.85);
    float teethRidge = skullRBox(pt, vec3(0.25, 0.08, 0.05), 0.02);
    teethRidge = max(teethRidge, -p.z + 0.7);
    d = min(d, teethRidge);
    
    return d / 20.0;
}

float wallSkulls(vec3 p) {
    vec3 cellSize = vec3(0.35, 0.3, 0.4);
    vec3 cellId = floor(p / cellSize);
    vec3 cellP = mod(p, cellSize) - cellSize * 0.5;
    
    float hash = fract(sin(dot(cellId, vec3(127.1, 311.7, 74.7))) * 43758.5453);
    if (hash > SKULL_DENSITY) return 100.0;
    
    float angle = hash * 6.28;
    float ca = cos(angle), sa = sin(angle);
    cellP.xz = mat2(ca, -sa, sa, ca) * cellP.xz;
    
    float tilt = (hash - 0.5) * 0.3;
    float ct = cos(tilt), st = sin(tilt);
    cellP.yz = mat2(ct, -st, st, ct) * cellP.yz;
    cellP.z = -cellP.z;
    
    float scale = SKULL_SCALE * 0.08 * (0.8 + hash * 0.4);
    return skull(cellP / scale) * scale;
}

// ============== IMPROVED SERPENT ==============

vec3 serpentSpine(float u, float time, int id) {
    float t = time * 0.3;
    float phase = float(id) * 3.14159;
    
    vec3 p;
    if (id == 0) {
        p = vec3(
            sin(u * 0.5 + t) * 0.3,
            0.06 + 0.04 * sin(u * 0.8),
            u * 0.12 - 0.8
        );
    } else {
        p = vec3(
            cos(u * 0.4 + t + phase) * 0.25 - 0.05,
            0.10 + 0.03 * sin(u * 0.9 + phase),
            u * 0.10 - 0.5
        );
    }
    
    float wave = sin(u * SERPENT_WAVE_FREQ - time * SERPENT_WAVE_SPEED);
    p.x += wave * SERPENT_WAVE_AMP * smoothstep(0.0, 2.0, u);
    p.y += wave * SERPENT_WAVE_AMP * 0.3 * sin(u * 0.5);
    
    return p;
}

vec3 serpentTangent(float u, float time, int id) {
    float eps = 0.01;
    return normalize(serpentSpine(u + eps, time, id) - serpentSpine(u - eps, time, id));
}

float serpentRadius(float u, float pathLen) {
    float t = u / pathLen;
    float head = 1.0 + 0.4 * exp(-pow((t - 0.02) * 15.0, 2.0));
    float neck = 1.0 - 0.2 * exp(-pow((t - 0.08) * 12.0, 2.0));
    float body = 1.0 + 0.15 * exp(-pow((t - 0.35) * 4.0, 2.0));
    float tail = smoothstep(1.0, 0.7, t);
    float headTip = smoothstep(0.0, 0.04, t);
    
    float r = SERPENT_BASE_RADIUS + SERPENT_AUDIO_PULSE * audio.x;
    return r * head * neck * body * tail * headTip;
}

float scalePattern(float u, float angle, float pathLen) {
    float scaleU = u * SCALE_COUNT;
    float scaleV = angle * 8.0;
    scaleV += mod(floor(scaleU), 2.0) * 0.5;
    vec2 scaleUV = fract(vec2(scaleU, scaleV)) - 0.5;
    float scale = abs(scaleUV.x) + abs(scaleUV.y);
    return SCALE_DEPTH * smoothstep(0.5, 0.2, scale);
}

float serpentSDF(vec3 p, float time, int id, out float bodyU, out vec3 closestPoint) {
    float pathLen = (id == 0) ? 12.0 : 10.0;
    float u = clamp((p.z + 0.8) / 0.12, 0.0, pathLen);
    
    for (int i = 0; i < 4; i++) {
        vec3 spine = serpentSpine(u, time, id);
        vec3 tang = serpentTangent(u, time, id);
        vec3 delta = p - spine;
        float correction = dot(delta, tang);
        u = clamp(u + correction * 0.8, 0.0, pathLen);
    }
    
    vec3 spine = serpentSpine(u, time, id);
    vec3 toPoint = p - spine;
    float dist = length(toPoint);
    
    vec3 tang = serpentTangent(u, time, id);
    vec3 norm1 = normalize(cross(tang, vec3(0.0, 1.0, 0.0)));
    vec3 norm2 = cross(tang, norm1);
    float angle = atan(dot(toPoint, norm2), dot(toPoint, norm1));
    
    float r = serpentRadius(u, pathLen);
    float scales = scalePattern(u, angle, pathLen);
    
    bodyU = u;
    closestPoint = spine;
    
    return dist - r - scales;
}

float serpent(vec3 p, float time, int id) {
    float u;
    vec3 cp;
    return serpentSDF(p, time, id, u, cp);
}

// ============== KALI CATHEDRAL ==============

vec3 kali(vec3 pos, vec3 param) {
    vec4 p = vec4(pos, 1.0);
    vec3 d = vec3(100.0);
    for (int i = 0; i < KALI_ITERATIONS; i++) {
        p.xyz = abs(p.xyz);
        p /= dot(p.xyz, p.xyz);
        d = min(d, p.xyz / p.w);
        p.xyz -= param;
    }
    return d;
}

vec4 light;
vec3 kaliLight(vec3 pos, vec3 param) {
    vec4 p = vec4(pos, 1.0);
    vec3 d = vec3(100.0);
    for (int i = 0; i < KALI_ITERATIONS; i++) {
        p.xyz = abs(p.xyz);
        p /= dot(p.xyz, p.xyz);
        vec3 s = p.xyz / p.w;
        d = min(d, s);
        
        if (i == 3) {
            vec3 lc = 0.5 + 0.5 * sin(pos.xzx * vec3(8.0, 9.0, 19.0) + audio.z * 3.0);
            float lsize = 0.003 + 0.002 * audio.x;
            light = vec4(lc, length(s.xz) - lsize);
        }
        p.xyz -= param;
    }
    return d;
}

// ============== SCENE ==============

float DE(vec3 p, vec3 param, float time) {
    float d = min(p.y, -p.y + 0.22);
    vec3 k = kali(p * vec3(1.0, 2.0, 1.0), param);
    d -= k.x;
    
    float skulls = wallSkulls(p);
    d = min(d, skulls);
    
    float s1 = serpent(p, time, 0);
    float s2 = serpent(p, time, 1);
    
    return min(d, min(s1, s2));
}

vec3 lightAccum;
float DElight(vec3 p, vec3 param, float time) {
    float d = min(p.y, -p.y + 0.22);
    vec3 k = kaliLight(p * vec3(1.0, 2.0, 1.0), param);
    d -= k.x;
    
    float skulls = wallSkulls(p);
    d = min(d, skulls);
    
    float s1 = serpent(p, time, 0);
    float s2 = serpent(p, time, 1);
    
    return min(d, min(s1, s2));
}

float getMat(vec3 p, vec3 param, float time) {
    float d = min(p.y, -p.y + 0.22);
    vec3 k = kali(p * vec3(1.0, 2.0, 1.0), param);
    d -= k.x;
    
    float skulls = wallSkulls(p);
    float s1 = serpent(p, time, 0);
    float s2 = serpent(p, time, 1);
    
    if (s1 < d && s1 < s2 && s1 < skulls) return 1.0;
    if (s2 < d && s2 < s1 && s2 < skulls) return 2.0;
    if (skulls < d && skulls < s1 && skulls < s2) return 3.0;
    return 0.0;
}

vec3 calcNorm(vec3 p, vec3 param, float time) {
    vec2 e = vec2(0.0001, 0.0);
    return normalize(vec3(
        DE(p + e.xyy, param, time) - DE(p - e.xyy, param, time),
        DE(p + e.yxy, param, time) - DE(p - e.yxy, param, time),
        DE(p + e.yyx, param, time) - DE(p - e.yyx, param, time)
    ));
}

float calcAO(vec3 p, vec3 n, vec3 param, float time) {
    float ao = 0.0, t = 0.01;
    for (int i = 0; i < 5; i++) {
        float d = DE(p + t * n, param, time);
        ao += d / t;
        t += d;
    }
    return min(1.0, ao / 5.0);
}

// ============== IMPROVED CAMERA PATH ==============
// Key insight: Stay in the SAFE CORRIDOR between floor (y=0) and ceiling (y=0.22)
// Serpents live at y=0.06-0.10, so camera stays at y=0.13-0.17 (above serpents)

vec3 camPath(float ti) {
    ti *= CAM_SPEED;  // Use the defined speed
    
    // Y: Constrained to safe corridor (0.13 to 0.17) - ABOVE serpent level
    // This is the KEY to not hitting things - careful Y bounds like the original
    float safeY = 0.15 + 0.02 * sin(ti * 2.3);
    
    // X: Gentle sway, smaller amplitude to avoid walls
    // The Kali geometry is densest near abs(x) > 0.4
    float safeX = sin(ti * 0.8) * 0.18 + cos(ti * 0.3) * 0.08;
    
    // Z: Smooth forward/backward motion
    float safeZ = -0.25 * cos(ti * 0.7) + 0.1 * sin(ti * 1.1);
    
    return vec3(safeX, safeY, safeZ);
}

vec3 camLook(float ti) {
    ti *= CAM_SPEED;
    
    // Look slightly ahead and DOWN toward the serpents
    return vec3(
        sin(ti * 0.8 + 0.5) * 0.22,  // Ahead of camera X
        0.07,                         // Look DOWN at serpent level
        -0.25 * cos(ti * 0.7 + 0.6) + 0.15  // Ahead in Z
    );
}

// ============== IMPROVED ENVIRONMENT MAP WITH REFLECTION TRACING ==============

vec3 envMap(vec3 ro, vec3 rd, vec3 param, float time) {
    // Background from Kali set (like original)
    vec3 par = vec3(1.2, 1.01, 0.71);
    vec3 c = kali(rd * 2.0, par);
    c = vec3(0.9 * c.x, 0.7, 1.0) * pow(vec3(c.x), vec3(0.7, 0.5, 0.5));
    c *= 0.5 + 0.2 * audio.y;
    
    // === NEW: Trace reflected lights (like original shader) ===
    // This is what makes reflections "catch" the lights
    vec3 lc = vec3(0.0);
    float t = 0.001;
    float maxT = 1.0;
    
    for (int i = 0; i < REFLECTION_TRACE_STEPS; i++) {
        vec3 p = ro + rd * t;
        float d = DElight(p, param, time);
        
        if (abs(d) <= 0.0001 || t >= maxT)
            break;
        
        // Accumulate light from nearby "bulbs"
        lc += light.xyz * max(0.0, 0.4 - 9.0 * light.w);
        d = min(d, light.w);  // Step toward lights
        t += d;  // No fudging in reflection - some artifacts are OK
    }
    
    // Blend in gathered light (this creates the reflective light catching)
    c += 0.7 * min(vec3(1.0), lc / (maxT - t + 0.1));
    
    return clamp(c, 0.0, 1.0);
}

// ============== RENDERING ==============

float trace(vec3 ro, vec3 rd, vec3 param, float time) {
    lightAccum = vec3(0.0);
    float t = 0.001;
    
    for (int i = 0; i < 70; i++) {
        vec3 p = ro + rd * t;
        float d = DElight(p, param, time);
        
        if (abs(d) < 0.0001 || t > 1.2) break;
        
        float glow = LIGHT_GLOW + LIGHT_AUDIO_BOOST * audio.z;
        lightAccum += (0.2 + 0.5 * light.xyz) * max(0.0, 0.3 - 6.0 * light.w) * glow / 2.5;
        
        d = min(d, light.w * 0.5);
        t += d * 0.5;
    }
    return t;
}

vec3 serpentColor(vec3 p, vec3 n, vec3 rd, float mat, float time) {
    vec3 col = vec3(0.85, 0.88, 0.92);
    if (mat > 1.5) {
        col = vec3(0.88, 0.85, 0.82);
    }
    
    float fresnel = 1.0 - max(0.0, dot(-rd, n));
    vec3 irid = 0.5 + 0.5 * sin(vec3(0.0, 2.0, 4.0) + fresnel * 6.0 + p.z * 20.0);
    col = mix(col, irid, 0.15 + 0.1 * audio.y);
    col *= 0.9 + 0.1 * sin(p.z * 30.0 + time);
    
    return col * 0.35;
}

vec3 rayColor(vec3 ro, vec3 rd, float time) {
    // Scene geometry params
    vec3 par1 = vec3(1.0, 0.7 + 0.6 * sin(time / 39.0) + 0.15 * audio.x, 1.0);
    // === Bump/normal displacement params (secondary Kali for micro-bumps) ===
    vec3 par2 = vec3(0.63, 0.55, 0.73);
    
    float t = trace(ro, rd, par1, time);
    vec3 p = ro + t * rd;
    float d = DE(p, par1, time);
    
    vec3 col = vec3(0.0);
    
    if (d < 0.03) {
        vec3 n = calcNorm(p, par1, time);
        float mat = getMat(p, par1, time);
        
        // === IMPROVED: Enhanced micro-bump normals for ALL surfaces ===
        if (mat < 0.5) {
            // Cathedral: Two-layer bump mapping (like original)
            // Layer 1: Large-scale displacement based on secondary Kali params
            n = normalize(n + min(p.y + 0.05, 0.02) * calcNorm(p + BUMP_SCALE_1 * n, par2, time));
            // Layer 2: Micro-bumps for sparkle (high frequency)
            n = normalize(n + MICRO_BUMP_STRENGTH * calcNorm(sin(p * BUMP_SCALE_2 + n * 10.0), par2, time));
        } else if (mat < 2.5) {
            // Serpent: Subtle micro-bumps on scales
            n = normalize(n + 0.02 * calcNorm(sin(p * 50.0), par2, time));
        } else {
            // Skull: Fine bone texture bumps
            n = normalize(n + 0.015 * calcNorm(sin(p * 80.0 + n * 5.0), par2, time));
        }
        
        vec3 refl = reflect(rd, n);
        vec3 lightDir = normalize(vec3(0.7, 0.2, 0.0) - p);
        float ao = calcAO(p, n, par1, time);
        
        vec3 surf;
        if (mat > 2.5) {
            // Skull - golden
            vec3 gold = vec3(0.95, 0.6, 0.1);
            vec3 hal = normalize(lightDir - rd);
            float spec = pow(max(0.0, dot(n, hal)), 8.0);
            
            // === IMPROVED: Better environment reflection ===
            vec3 ref = envMap(p + 0.01 * n, refl, par1, time);
            
            float amb = clamp(-n.x, 0.0, 1.0) * 0.3 + 0.1;
            surf = gold;
            surf *= 32.0 * spec + amb;
            surf *= ref;
            surf *= ao;
            surf += gold * 0.1 * audio.y;
            
        } else if (mat > 0.5) {
            // Serpent
            surf = serpentColor(p, n, rd, mat, time);
            
            // === IMPROVED: Sharper specular ===
            float spec = pow(max(0.0, dot(refl, lightDir)), 64.0);
            surf += spec * 2.2 * (1.0 + audio.z * 0.5);
            
            // === IMPROVED: Environment map with light tracing ===
            surf += ao * envMap(p + 0.01 * n, refl, par1, time) * 0.9;
            
            // Enhanced fresnel rim
            float fres = pow(1.0 - max(0.0, dot(-rd, n)), 4.0);
            surf += fres * vec3(0.6, 0.7, 0.9) * 0.7;
            
        } else {
            // Cathedral walls
            surf = 0.1 * mix(vec3(1.0, 1.4, 1.0), vec3(3.0), ao);
            surf += 0.25 * ao * max(0.0, dot(n, lightDir));
            
            // === IMPROVED: Two-term specular (diffuse + sharp) ===
            float spec = max(0.0, dot(refl, lightDir));
            surf += ao * (0.5 * spec + 0.8 * pow(spec, 12.0));
            
            // === IMPROVED: Environment with full light tracing ===
            surf += ao * envMap(p + 0.01 * n, refl, par1, time);
        }
        
        col = surf * (1.0 - t / 1.2);
    }
    
    col += lightAccum;
    
    return col;
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 suv = fragCoord / iResolution.xy;
    vec2 uv = (fragCoord - iResolution.xy * 0.5) / iResolution.y * 2.0;
    
    sampleAudio();
    
    float time = iTime + 99.0;
    
    // Improved camera with safe path
    vec3 ro = camPath(time);
    vec3 look = camLook(time + 1.5);
    
    float turn = sin(time / 6.1) * 0.3;
    float fov = 1.6;
    
    vec3 fwd = normalize(look - ro);
    vec3 rgt = normalize(vec3(fwd.z, turn, -fwd.x));
    vec3 up = cross(fwd, rgt);
    
    vec3 rd = normalize(fwd + fov * (uv.x * rgt + uv.y * up));
    
    vec3 col = rayColor(ro, rd, time);
    
    // Vignette
    col *= pow(1.0 - dot(suv - 0.5, suv - 0.5) / 0.5, 0.6);
    
    // Tone mapping
    col = col / (col + 0.6) * 1.1;
    
    fragColor = vec4(col, 1.0);
}
