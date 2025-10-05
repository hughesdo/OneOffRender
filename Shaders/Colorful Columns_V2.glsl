#version 330 core

// Audio-Reactive Colorful Columns V2 - Anti-Flickering Version
// Improved version with smoother audio processing to reduce flickering
// Converted for OneOffRender system

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

// ===== TWEAK VARIABLES =====
#define CAMERA_HEIGHT 11.0
#define CAMERA_DISTANCE 11.0
#define CAMERA_SPEED 0.3
#define COLUMN_SPACING 5.0
#define AUDIO_HEIGHT_MIN 0.25
#define AUDIO_HEIGHT_MAX 4.0
#define RAY_STEPS 120
#define HIT_THRESHOLD 0.003
#define STEP_SIZE 0.6
#define MAX_DISTANCE 80.0

// Expanded color palette - 12 distinct vibrant colors
#define COLOR_1 vec3(0.1, 0.3, 1.0)     // Deep blue
#define COLOR_2 vec3(1.0, 0.2, 0.1)     // Bright red
#define COLOR_3 vec3(0.1, 1.0, 0.3)     // Bright green  
#define COLOR_4 vec3(1.0, 0.8, 0.1)     // Yellow
#define COLOR_5 vec3(0.9, 0.1, 0.9)     // Magenta
#define COLOR_6 vec3(0.1, 0.9, 0.9)     // Cyan
#define COLOR_7 vec3(1.0, 0.5, 0.0)     // Orange
#define COLOR_8 vec3(0.6, 0.1, 1.0)     // Purple
#define COLOR_9 vec3(0.0, 0.8, 0.4)     // Emerald
#define COLOR_10 vec3(1.0, 0.0, 0.5)    // Hot pink
#define COLOR_11 vec3(0.4, 0.8, 1.0)    // Sky blue
#define COLOR_12 vec3(0.8, 1.0, 0.2)    // Lime green
#define COLOR_13 vec3(1.0, 0.3, 0.7)    // Rose
#define COLOR_14 vec3(0.2, 0.6, 0.9)    // Ocean blue
#define COLOR_15 vec3(0.9, 0.6, 0.1)    // Amber
#define COLOR_16 vec3(0.5, 0.9, 0.8)    // Mint

#define BACKGROUND_TOP vec3(0.1, 0.15, 0.3)
#define BACKGROUND_BOT vec3(0.05, 0.1, 0.2)

// ----- Utility Functions -----
float saturate(float x) { return clamp(x, 0.0, 1.0); }
vec3 saturate3(vec3 v) { return clamp(v, 0.0, 1.0); }

// Domain repetition
vec3 repeat(vec3 p, vec3 c) {
    return mod(p + 0.5*c, c) - 0.5*c;
}

// Enhanced hash functions for better randomization
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(269.5, 183.3))) * 37652.2463);
}

float hash3(vec2 p) {
    return fract(sin(dot(p, vec2(419.2, 271.9))) * 28953.9712);
}

// Get distinct color for each column based on its cell ID with better randomization
vec3 getColumnColor(vec2 cellID) {
    // Multiple hash values for better randomization
    float h1 = hash(cellID);
    float h2 = hash2(cellID + vec2(1.3, 2.7));
    float h3 = hash3(cellID + vec2(5.1, 8.9));
    float h4 = hash(cellID * 3.14159 + vec2(0.577, 1.414));
    
    // Use a combination of hashes to select color more randomly
    float colorSelect = fract(h1 * 7.0 + h2 * 13.0 + h3 * 17.0);
    float colorIndex = floor(colorSelect * 16.0); // 16 colors available
    
    vec3 baseColor;
    if (colorIndex < 1.0) baseColor = COLOR_1;
    else if (colorIndex < 2.0) baseColor = COLOR_2;
    else if (colorIndex < 3.0) baseColor = COLOR_3;
    else if (colorIndex < 4.0) baseColor = COLOR_4;
    else if (colorIndex < 5.0) baseColor = COLOR_5;
    else if (colorIndex < 6.0) baseColor = COLOR_6;
    else if (colorIndex < 7.0) baseColor = COLOR_7;
    else if (colorIndex < 8.0) baseColor = COLOR_8;
    else if (colorIndex < 9.0) baseColor = COLOR_9;
    else if (colorIndex < 10.0) baseColor = COLOR_10;
    else if (colorIndex < 11.0) baseColor = COLOR_11;
    else if (colorIndex < 12.0) baseColor = COLOR_12;
    else if (colorIndex < 13.0) baseColor = COLOR_13;
    else if (colorIndex < 14.0) baseColor = COLOR_14;
    else if (colorIndex < 15.0) baseColor = COLOR_15;
    else baseColor = COLOR_16;
    
    // Add more variation using additional hash values
    vec3 variation = vec3(h1, h2, h3) * 0.3 + 0.85;
    baseColor *= variation;
    
    // Add some subtle hue shifting for even more variety
    float hueShift = h4 * 0.2 - 0.1;
    baseColor = saturate3(baseColor + vec3(hueShift, -hueShift * 0.5, hueShift * 0.3));
    
    return baseColor;
}

// ----- Distance Field Primitives -----
float sdRoundBox(vec3 p, vec3 b, float r) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    float m = p.x + p.y + p.z - s;
    vec3 q = max(p - s*0.57735026919, 0.0);
    return min(max(m, 0.0), 0.0) + length(q);
}

// ----- Boolean Operations -----
float opSmoothUnion(float d1, float d2, float k) {
    float h = saturate(0.5 + 0.5*(d2 - d1)/k);
    return mix(d2, d1, h) - k*h*(1.0 - h);
}

float opSmoothSub(float d1, float d2, float k) {
    float h = saturate(0.5 - 0.5*(d2 + d1)/k);
    return mix(d1, -d2, h) + k*h*(1.0 - h);
}

// ----- Scene SDF -----
struct MapResult { 
    float d; 
    vec2 cellID; // Store cell ID for coloring
};

// ANTI-FLICKERING: Improved audio-reactive column heights with smoother processing
float getAudioHeight(vec2 cellID, vec3 worldPos, vec3 cameraPos) {
    // Calculate distance from camera to this column
    float distanceFromCamera = length(worldPos.xz - cameraPos.xz);
    
    // Map distance to frequency range (0.0 = low freq, 1.0 = high freq)
    // Closer columns = lower frequencies, farther = higher frequencies
    float normalizedDistance = saturate(distanceFromCamera / 25.0); // Adjust 25.0 to change frequency spread
    
    // Map to frequency bands - closer columns get bass, farther get treble
    float freq = normalizedDistance * 0.8; // Use most of the frequency spectrum
    
    // ANTI-FLICKERING FIX 1: Use averaged sampling instead of max()
    float audioLevel = 0.0;
    float sampleCount = 0.0;
    
    // Primary frequency sample - averaged sampling for smoother response
    audioLevel += texture(iChannel0, vec2(freq, 0.0)).r;
    audioLevel += texture(iChannel0, vec2(freq, 0.25)).r;
    audioLevel += texture(iChannel0, vec2(freq, 0.5)).r;
    audioLevel += texture(iChannel0, vec2(freq, 0.75)).r;
    sampleCount += 4.0;
    
    // Add some neighboring frequency data for smoother response
    float freqSpread = 0.03;
    audioLevel += texture(iChannel0, vec2(clamp(freq - freqSpread, 0.0, 1.0), 0.0)).r;
    audioLevel += texture(iChannel0, vec2(clamp(freq + freqSpread, 0.0, 1.0), 0.0)).r;
    sampleCount += 2.0;
    
    // Average all samples
    audioLevel /= sampleCount;
    
    // Simple test pattern that's much weaker - always present but subtle
    float testFreq = normalizedDistance * 6.28318;
    float testPattern = sin(iTime * 1.5 + testFreq) * 0.5 + 0.5;
    audioLevel = mix(audioLevel, testPattern * 0.2, 0.1); // Blend instead of max
    
    // Add bass boost for closer columns and treble emphasis for farther ones
    if (normalizedDistance < 0.3) {
        // Bass boost for close columns - reduced intensity
        audioLevel *= 1.15;
    } else if (normalizedDistance > 0.7) {
        // Treble emphasis for far columns - reduced intensity
        audioLevel *= 1.1;
    }
    
    // Some variation per column but maintain frequency organization
    float h1 = hash(cellID);
    float heightVariation = 0.9 + h1 * 0.2; // Less random variation to preserve frequency order
    
    // ANTI-FLICKERING FIX 2: Gentler audio processing
    audioLevel = pow(audioLevel, 0.9) * 1.2; // Less aggressive amplification
    
    // ANTI-FLICKERING FIX 3: Smoother curve with less aggressive smoothstep
    audioLevel = mix(audioLevel, smoothstep(0.1, 0.9, audioLevel), 0.7);
    
    // ANTI-FLICKERING FIX 4: Add temporal smoothing based on time
    float timeSmoothing = sin(iTime * 0.5) * 0.05 + 0.95;
    audioLevel *= timeSmoothing;
    
    return audioLevel * (AUDIO_HEIGHT_MAX - AUDIO_HEIGHT_MIN) * heightVariation + AUDIO_HEIGHT_MIN;
}

MapResult map(vec3 p, vec3 mover, vec3 cameraPos) {
    // Repeating columns with audio-reactive heights
    vec3 cell = vec3(COLUMN_SPACING, 100.0, COLUMN_SPACING);
    vec3 pr = repeat(p, cell);

    // Get the cell ID for this column
    vec2 cellID = floor((p.xz + 0.5*cell.xz) / cell.xz);

    // Calculate world position of this column center
    vec3 columnWorldPos = vec3(cellID.x * COLUMN_SPACING, 0.0, cellID.y * COLUMN_SPACING);

    // Get frequency-organized audio-reactive height for this column
    float audioHeight = getAudioHeight(cellID, columnWorldPos, cameraPos);

    // Add some random shape variation (reduced to preserve frequency organization)
    float shapeVar = hash(cellID) * 0.2 + 0.9;

    // Scale octahedron and box based on audio with shape variation
    float dOct = sdOctahedron(pr, 1.4 * shapeVar * (0.5 + 0.5 * audioHeight / AUDIO_HEIGHT_MAX));
    float dBox = sdRoundBox(pr, vec3(0.8 * shapeVar, audioHeight, 0.8 * shapeVar), 0.2);
    float dCol = opSmoothUnion(dOct, dBox, 0.5);

    // Ground plane
    float dGround = p.y + 1.3;

    // Moving void
    float dMover = sdRoundBox(p - mover, vec3(0.6, 0.8, 0.6), 0.3);

    // Combine
    float dStruct = min(dCol, dGround);
    float dScene = opSmoothSub(dStruct, dMover, 0.6);

    MapResult result;
    result.d = dScene;
    result.cellID = cellID;
    return result;
}

// ----- Normal Calculation -----
vec3 getNormal(vec3 p, vec3 mover, vec3 cameraPos) {
    const float e = 0.002; // Stable epsilon
    return normalize(vec3(
        map(p + vec3(e, 0, 0), mover, cameraPos).d - map(p - vec3(e, 0, 0), mover, cameraPos).d,
        map(p + vec3(0, e, 0), mover, cameraPos).d - map(p - vec3(0, e, 0), mover, cameraPos).d,
        map(p + vec3(0, 0, e), mover, cameraPos).d - map(p - vec3(0, 0, e), mover, cameraPos).d
    ));
}

// ----- Ambient Occlusion -----
float ambientOcclusion(vec3 p, vec3 n, vec3 mover, vec3 cameraPos) {
    float occ = 0.0;
    float sca = 1.0;
    for (int i = 1; i <= 4; i++) {
        float h = 0.02*float(i*i);
        float d = map(p + n*h, mover, cameraPos).d;
        occ += (h - d)*sca;
        sca *= 0.7;
    }
    return saturate(1.0 - 1.5*occ);
}

// ----- Soft Shadows -----
float softShadow(vec3 ro, vec3 rd, vec3 mover, vec3 cameraPos, float mint, float maxt) {
    float res = 1.0;
    float t = mint;
    for (int i = 0; i < 16; i++) {
        float h = map(ro + rd*t, mover, cameraPos).d;
        res = min(res, 8.0*h/t);
        t += clamp(h, 0.02, 0.2);
        if (res < 0.005 || t > maxt) break;
    }
    return saturate(res);
}

// ----- Camera Matrix -----
mat3 cameraMatrix(vec3 ro, vec3 ta) {
    vec3 fw = normalize(ta - ro);
    vec3 rt = normalize(cross(vec3(0, 1, 0), fw));
    vec3 up = normalize(cross(fw, rt));
    return mat3(rt, up, fw);
}

void main() {
    // Camera setup
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // Simple but interesting camera motion
    float t = iTime * 0.3;
    vec3 cPath = vec3(sin(t) * 3.0, sin(t * 0.7) * 1.0, cos(t) * 3.0);
    vec3 ro = cPath + vec3(0.0, 8.0, 15.0);
    vec3 ta = cPath + vec3(0.0, 0.0, 0.0);

    mat3 cam = cameraMatrix(ro, ta);
    vec3 rd = normalize(cam * vec3(uv, 1.6));

    // Moving object with more interesting motion
    vec3 mover = vec3(
        sin(t * 1.2) * 3.0 + cos(t * 0.8) * 1.0,
        sin(t * 0.9) * 2.0,
        cos(t * 1.1) * 3.0 + sin(t * 0.6) * 1.0
    );

    // Ray marching - simpler and more stable
    float rayT = 0.02;
    vec3 col = vec3(0.0);

    for (int i = 0; i < RAY_STEPS; i++) {
        vec3 pos = ro + rd * rayT;
        MapResult r = map(pos, mover, ro);

        if (r.d < HIT_THRESHOLD) {
            // Hit surface - use the marching position directly
            vec3 n = getNormal(pos, mover, ro);

            // Get the unique color for this column
            vec3 baseColor = getColumnColor(r.cellID);

            // Two light sources
            vec3 lightDir1 = normalize(vec3(0.5, 1.0, 0.3));
            vec3 lightPos2 = mover + vec3(0.0, 2.0, 0.0);
            vec3 lightDir2 = normalize(lightPos2 - pos);

            float light1 = saturate(dot(n, lightDir1));
            float light2 = saturate(dot(n, lightDir2));

            // Calculate soft shadows
            float shadow1 = softShadow(pos + n*0.02, lightDir1, mover, ro, 0.02, 10.0);
            float shadow2 = softShadow(pos + n*0.02, lightDir2, mover, ro, 0.02, length(lightPos2 - pos));

            // Calculate ambient occlusion
            float ao = ambientOcclusion(pos, n, mover, ro);

            // Get audio level for additional color modulation
            vec3 columnWorldPos = vec3(r.cellID.x * COLUMN_SPACING, 0.0, r.cellID.y * COLUMN_SPACING);
            float audioLevel = getAudioHeight(r.cellID, columnWorldPos, ro) / AUDIO_HEIGHT_MAX;

            // ANTI-FLICKERING FIX 5: Gentler color modulation
            vec3 finalColor = baseColor * (1.0 + audioLevel * 0.4); // Reduced from 0.8 to 0.4

            // Height-based color variation (subtle)
            float height = saturate(0.5 + 0.5*pos.y/4.0);
            finalColor = mix(finalColor, finalColor * 1.3, height * 0.3);

            // Simple specular
            vec3 H1 = normalize(lightDir1 - rd);
            float spec1 = pow(saturate(dot(n, H1)), 20.0);

            col = finalColor * (0.3 + 0.6*light1*shadow1 + 0.3*light2*shadow2) * ao +
                  vec3(0.9, 0.9, 1.0) * 0.3 * spec1 * shadow1;

            break;
        }

        // Simple, stable step size
        rayT += r.d * STEP_SIZE;
        if (rayT > MAX_DISTANCE) break;
    }

    // Background gradient
    if (length(col) < 0.01) {
        float bgGrad = rd.y * 0.5 + 0.5;
        col = mix(BACKGROUND_BOT, BACKGROUND_TOP, bgGrad);
    }

    // Slight color boost for better visibility
    col = pow(col, vec3(0.9));

    fragColor = vec4(saturate3(col), 1.0);
}
