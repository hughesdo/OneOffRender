// ============================================================
// Particle Nebula — Audio-Reactive 3D with Fresnel Glow
// For oneoff.py — iChannel0 = audio texture
// ============================================================

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;

// -------------------- TWEAKABLES ----------------------------
#define NUM_LAYERS        7        // particle cloud layers
#define PARTICLE_DENSITY  80.0     // particles per cell
#define BASE_PARTICLE_SIZE 0.025   // base dot radius
#define GLOW_INTENSITY    2.5      // bloom multiplier
#define GLOW_FALLOFF      3.0      // glow sharpness (higher = tighter)
#define FRESNEL_POWER     3.0      // edge fresnel exponent
#define FRESNEL_STRENGTH  1.8      // fresnel glow brightness
#define CLOUD_SPEED       0.12     // drift speed
#define COLOR_SHIFT_RATE  0.3      // hue rotation speed
#define AUDIO_GLOW_MULT   3.0      // audio → glow boost
#define AUDIO_SIZE_MULT   2.0      // audio → particle size boost
#define AUDIO_FRESNEL_MULT 2.5     // audio → fresnel boost
#define CAMERA_DIST       3.5      // camera distance from origin
#define FOG_DENSITY       0.06     // depth fog

// -------------------- HELPERS --------------------------------

// Hash functions for pseudo-random particles
float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
    float n = hash21(p);
    return vec2(n, hash21(p + n));
}

float hash31(vec3 p) {
    p = fract(p * vec3(123.34, 456.21, 789.92));
    p += dot(p, p.yzx + 45.32);
    return fract(p.x * p.y * p.z);
}

vec3 hash33(vec3 p) {
    float n = hash31(p);
    return vec3(n, hash31(p + n), hash31(p + n * 2.0));
}

// -------------------- AUDIO ----------------------------------

float getAudioBass() {
    float bass = 0.0;
    for (int i = 0; i < 8; i++) {
        bass += texture(iChannel0, vec2(float(i) / 512.0, 0.0)).x;
    }
    return bass / 8.0;
}

float getAudioMid() {
    float mid = 0.0;
    for (int i = 20; i < 80; i++) {
        mid += texture(iChannel0, vec2(float(i) / 512.0, 0.0)).x;
    }
    return mid / 60.0;
}

float getAudioHigh() {
    float hi = 0.0;
    for (int i = 100; i < 200; i++) {
        hi += texture(iChannel0, vec2(float(i) / 512.0, 0.0)).x;
    }
    return hi / 100.0;
}

float getFreqAt(float f) {
    return texture(iChannel0, vec2(f, 0.0)).x;
}

// -------------------- COLOR PALETTE --------------------------

vec3 particleColor(float id, float depth, float audioVal) {
    // Base: green/teal at "top", blue/purple at "bottom" — like the reference
    float hue = mix(0.45, 0.72, depth) + id * 0.1 + audioVal * COLOR_SHIFT_RATE * 0.2;
    hue = fract(hue);
    float sat = mix(0.5, 0.9, id);
    float val = mix(0.4, 1.0, audioVal);

    // HSV to RGB
    vec3 c = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return val * mix(vec3(1.0), c, sat);
}

// -------------------- 3D PARTICLE FIELD ----------------------

// Returns: x = closest particle distance, y = particle id, z = depth factor
vec4 particleField(vec3 p, float audio) {
    vec4 result = vec4(1e6, 0.0, 0.0, 0.0);
    
    // Scale the space into cells
    float cellSize = 1.0 / (PARTICLE_DENSITY / 20.0);
    vec3 cell = floor(p / cellSize);
    vec3 localP = fract(p / cellSize) - 0.5;
    
    // Check neighboring cells
    for (int x = -1; x <= 1; x++)
    for (int y = -1; y <= 1; y++)
    for (int z = -1; z <= 1; z++) {
        vec3 neighbor = vec3(float(x), float(y), float(z));
        vec3 cellId = cell + neighbor;
        
        // Random offset within cell
        vec3 rnd = hash33(cellId) - 0.5;
        
        // Particle position with flow animation
        vec3 offset = neighbor + rnd;
        offset += 0.15 * sin(iTime * CLOUD_SPEED * (1.0 + rnd * 2.0) + rnd * 6.28);
        
        // Audio-reactive displacement
        float freqSample = getFreqAt(fract(hash31(cellId) * 0.5));
        offset += 0.08 * freqSample * normalize(rnd + 0.001);
        
        float dist = length(localP - offset);
        
        if (dist < result.x) {
            result.x = dist * cellSize; // real-space distance
            result.y = hash31(cellId);  // particle ID
            result.z = rnd.z + 0.5;    // depth factor 0-1
            result.w = freqSample;      // per-particle audio
        }
    }
    
    return result;
}

// -------------------- MAIN IMAGE -----------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Audio analysis
    float bass = getAudioBass();
    float mid  = getAudioMid();
    float high = getAudioHigh();
    float audioTotal = (bass + mid + high) / 3.0;
    
    // ---- Camera with slow orbit ----
    float camAngle = iTime * 0.08 + bass * 0.3;
    float camPitch = 0.2 + mid * 0.15;
    vec3 camPos = vec3(
        CAMERA_DIST * cos(camAngle) * cos(camPitch),
        CAMERA_DIST * sin(camPitch) * 0.5,
        CAMERA_DIST * sin(camAngle) * cos(camPitch)
    );
    vec3 target = vec3(0.0, 0.0, 0.0);
    
    // Camera matrix
    vec3 forward = normalize(target - camPos);
    vec3 right   = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
    vec3 up      = cross(right, forward);
    
    // Ray direction
    vec3 rd = normalize(uv.x * right + uv.y * up + (1.5 - bass * 0.3) * forward);
    
    // ---- Accumulate particles along ray ----
    vec3 col = vec3(0.0);
    float totalAlpha = 0.0;
    
    for (int layer = 0; layer < NUM_LAYERS; layer++) {
        float t = 0.5 + float(layer) * 0.7 + hash21(uv * 100.0 + float(layer)) * 0.2;
        vec3 pos = camPos + rd * t;
        
        // Add flow drift
        pos += vec3(
            sin(iTime * CLOUD_SPEED * 0.7 + pos.z) * 0.3,
            cos(iTime * CLOUD_SPEED * 0.5 + pos.x) * 0.2,
            sin(iTime * CLOUD_SPEED * 0.3 + pos.y) * 0.3
        );
        
        // ---- Inner particle grid per layer ----
        float cellSize = 0.25;
        vec3 cell = floor(pos / cellSize);
        vec3 localP = fract(pos / cellSize);
        
        for (int cx = -1; cx <= 1; cx++)
        for (int cy = -1; cy <= 1; cy++) {
            vec3 cellId = cell + vec3(float(cx), float(cy), 0.0);
            float rnd = hash31(cellId + float(layer) * 7.77);
            
            // Skip some cells for varied density
            if (rnd > 0.7) continue;
            
            vec2 rnd2 = hash22(cellId.xy + float(layer) * 3.33);
            vec3 particlePos = vec3(
                (float(cx) + rnd2.x) * cellSize,
                (float(cy) + rnd2.y) * cellSize,
                0.0
            );
            
            // Per-particle audio reactivity
            float freqSample = getFreqAt(fract(rnd * 0.5 + 0.01));
            float particleAudio = freqSample;
            
            // Animated offset
            particlePos.xy += 0.03 * sin(iTime * (0.5 + rnd * 2.0) + rnd * 6.28);
            particlePos.xy += particleAudio * 0.02 * vec2(sin(rnd * 20.0), cos(rnd * 20.0));
            
            vec2 delta = localP.xy - particlePos.xy;
            float dist = length(delta);
            
            // ---- Particle size: base + audio grow ----
            float pSize = BASE_PARTICLE_SIZE * (0.5 + rnd * 1.0);
            pSize += pSize * particleAudio * AUDIO_SIZE_MULT;
            
            // ---- Bright core ----
            float core = smoothstep(pSize, pSize * 0.2, dist);
            
            // ---- Glow halo ----
            float glow = exp(-dist * GLOW_FALLOFF / pSize);
            glow *= GLOW_INTENSITY * (1.0 + particleAudio * AUDIO_GLOW_MULT);
            
            // ---- Fresnel: edge glow based on view angle ----
            // Treat each particle as a tiny sphere
            float fresnelDist = dist / max(pSize * 3.0, 0.001);
            float fresnelAngle = sqrt(max(1.0 - fresnelDist * fresnelDist, 0.0));
            float fresnel = pow(1.0 - fresnelAngle, FRESNEL_POWER);
            fresnel *= FRESNEL_STRENGTH;
            // Audio-reactive fresnel boost
            fresnel *= (1.0 + particleAudio * AUDIO_FRESNEL_MULT);
            
            // ---- Color ----
            float depthFactor = float(layer) / float(NUM_LAYERS);
            vec3 pCol = particleColor(rnd, depthFactor, particleAudio);
            
            // Brighter particles get a white-ish core
            float brightness = core + glow * 0.3 + fresnel * 0.5;
            vec3 finalPCol = mix(pCol, vec3(1.0, 1.0, 1.0), core * 0.6);
            finalPCol += pCol * glow;
            finalPCol += mix(pCol * 1.5, vec3(0.7, 0.9, 1.0), 0.3) * fresnel;
            
            // ---- Depth fog ----
            float fog = exp(-t * FOG_DENSITY);
            finalPCol *= fog;
            
            // ---- Accumulate ----
            float alpha = clamp(brightness * fog, 0.0, 1.0);
            col += finalPCol * alpha * (1.0 - totalAlpha);
            totalAlpha = min(totalAlpha + alpha * 0.3, 1.0);
        }
    }
    
    // ---- Scattered bright "star" particles ----
    for (int i = 0; i < 30; i++) {
        float fi = float(i);
        vec2 starHash = hash22(vec2(fi * 1.23, fi * 4.56));
        vec2 starUV = (starHash - 0.5) * 2.2;
        
        // Slow drift
        starUV += 0.1 * sin(iTime * 0.2 + fi);
        
        float starDist = length(uv - starUV);
        float freqVal = getFreqAt(fract(fi * 0.037));
        
        // Star size pulses with audio
        float starSize = 0.003 + 0.005 * freqVal * AUDIO_SIZE_MULT;
        float starCore = smoothstep(starSize, 0.0, starDist);
        float starGlow = exp(-starDist * 40.0) * (0.5 + freqVal * AUDIO_GLOW_MULT);
        
        // Star fresnel halo ring
        float starFresnel = smoothstep(starSize * 4.0, starSize * 2.0, starDist)
                          * smoothstep(starSize * 0.5, starSize * 1.5, starDist);
        starFresnel *= FRESNEL_STRENGTH * (1.0 + freqVal * AUDIO_FRESNEL_MULT) * 0.5;
        
        // Color: white core with teal/blue glow
        float hue = mix(0.5, 0.65, starHash.y) + freqVal * 0.1;
        vec3 starColor = 0.5 + 0.5 * cos(6.28 * (hue + vec3(0.0, 0.33, 0.67)));
        
        vec3 starContrib = vec3(1.0) * starCore * 2.0
                         + starColor * starGlow
                         + starColor * 1.5 * starFresnel;
        
        col += starContrib * (1.0 - totalAlpha * 0.5);
    }
    
    // ---- Global Fresnel vignette: edges glow with audio ----
    float edgeDist = length(uv);
    float edgeFresnel = smoothstep(0.4, 1.2, edgeDist);
    edgeFresnel *= bass * AUDIO_FRESNEL_MULT * 0.15;
    vec3 edgeColor = mix(vec3(0.1, 0.3, 0.5), vec3(0.2, 0.5, 0.3), sin(iTime * 0.3) * 0.5 + 0.5);
    col += edgeColor * edgeFresnel;
    
    // ---- Subtle background nebula wash ----
    float nebula = 0.0;
    vec2 nUV = uv * 1.5 + iTime * 0.02;
    nebula += sin(nUV.x * 3.0 + nUV.y * 2.0 + iTime * 0.1) * 0.5 + 0.5;
    nebula *= sin(nUV.y * 4.0 - nUV.x * 1.5 + iTime * 0.15) * 0.5 + 0.5;
    nebula *= 0.02 * (1.0 + bass * 1.5);
    vec3 nebulaColor = mix(vec3(0.05, 0.02, 0.1), vec3(0.02, 0.08, 0.05), uv.y * 0.5 + 0.5);
    col += nebulaColor * nebula;
    
    // ---- Tone mapping & output ----
    col = 1.0 - exp(-col * 1.2);  // soft tonemap
    col = pow(col, vec3(0.92));    // slight gamma lift

    fragColor = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
