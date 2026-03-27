#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;
uniform vec4 iMouse;

out vec4 fragColor;

// "Frequency Cathedral" - Audio Reactive Shader v2
// An infinite crystalline structure that breathes with sound
// Set iChannel0 to Soundcloud or Microphone

#define FAR 80.0
#define PI 3.14159265359
#define TAU 6.28318530718

// ===============================================================
// TWEAKING VARIABLES - Adjust these to fine-tune the dance!
// ===============================================================

// Size reactivity per shape type (how much shapes grow with audio)
const float OCTA_SIZE_REACT = 0.45;      // Octahedron bass reaction (was 0.4)
const float CUBE_SIZE_REACT = 0.35;      // Frame cube mid reaction (was 0.3)
const float BEAM_SIZE_REACT = 0.12;      // Cross beams high reaction (was 0.08)
const float SPHERE_SIZE_REACT = 0.25;    // Sphere presence reaction (was 0.2)

// Position/wobble reactivity (NEW - makes shapes dance in place)
const float OCTA_POS_REACT = 0.15;       // Octahedron position wobble
const float CUBE_POS_REACT = 0.12;       // Cube position wobble  
const float BEAM_POS_REACT = 0.08;       // Beam position wobble
const float SPHERE_POS_REACT = 0.18;     // Sphere position wobble

// Rotation reactivity (how much audio affects spin)
const float ROT_REACT_MULT = 2.5;        // Rotation multiplier (was 2.0)

// Glow intensities per frequency
const float GLOW_BASS = 0.020;           // Bass glow intensity (was fixed 0.015)
const float GLOW_MID = 0.018;            // Mid glow intensity
const float GLOW_HIGH = 0.015;           // High glow intensity
const float PARTICLE_GLOW = 0.35;        // Particle glow (was 0.3)

// Breathing (global pulse on kick)
const float BREATHE_AMOUNT = 0.18;       // How much kick affects scale (was 0.15)

// Light pulse amounts per frequency
const float LIGHT_BASS_PULSE = 0.3;      // How much bass pulses lights
const float LIGHT_MID_PULSE = 0.2;       // How much mid pulses lights
const float LIGHT_HIGH_PULSE = 0.25;     // How much high pulses lights

// ===============================================================
// AUDIO ANALYSIS
// ===============================================================

float bass, mid, high, presence;
float kick, energy;
float[8] spectrum;

void analyzeAudio() {
    // Frequency bands
    bass = texture(iChannel0, vec2(0.02, 0.0)).x;
    mid = texture(iChannel0, vec2(0.2, 0.0)).x;
    high = texture(iChannel0, vec2(0.5, 0.0)).x;
    presence = texture(iChannel0, vec2(0.8, 0.0)).x;
    
    // Kick detection (bass transient)
    kick = smoothstep(0.3, 0.6, bass) * bass;
    
    // Overall energy
    energy = (bass + mid + high + presence) * 0.25;
    
    // Spectrum array for detailed reactions
    for(int i = 0; i < 8; i++) {
        spectrum[i] = texture(iChannel0, vec2(float(i) / 8.0, 0.0)).x;
    }
}

// ===============================================================
// UTILITIES
// ===============================================================

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 palette(float t, float audioMod) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 0.7, 0.4);
    vec3 d = vec3(0.0, 0.15, 0.20) + vec3(bass * 0.2, mid * 0.1, high * 0.3);
    return a + b * cos(TAU * (c * t + d + audioMod));
}

float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// ===============================================================
// DISTANCE FUNCTIONS
// ===============================================================

float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    return (p.x + p.y + p.z - s) * 0.577350269;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// The infinite cathedral structure
float glow1 = 0.0, glow2 = 0.0, glow3 = 0.0;
vec3 hitColor = vec3(0.0);
float hitFreqType = 0.0; // Track which frequency band hit

float map(vec3 p) {
    float t = iTime * 0.3;
    
    // Breathing scale with bass
    float breathe = 1.0 + kick * BREATHE_AMOUNT;
    
    // Create infinite lattice
    vec3 id = floor(p / 4.0);
    vec3 q = mod(p, 4.0) - 2.0;
    
    // Vary cell properties by position
    float cellHash = hash(id);
    int cellType = int(cellHash * 4.0);
    
    // Audio-reactive rotation per cell - enhanced
    float specIdx = int(mod(id.x + id.y, 8.0));
    float rotAmount = spectrum[int(specIdx)] * ROT_REACT_MULT;
    q.xy *= rot(t + rotAmount + id.z * 0.5);
    q.yz *= rot(t * 0.7 + rotAmount);
    
    // Different geometry per cell type
    float d = FAR;
    
    if (cellType == 0) {
        // Octahedron - reacts to bass
        float size = 0.6 + bass * OCTA_SIZE_REACT;
        
        // NEW: Position wobble on bass
        vec3 wobble = vec3(
            sin(t * 4.0 + id.x) * bass * OCTA_POS_REACT,
            cos(t * 3.5 + id.y) * bass * OCTA_POS_REACT,
            sin(t * 3.0 + id.z) * kick * OCTA_POS_REACT
        );
        
        d = sdOctahedron(q + wobble, size * breathe);
        hitColor = palette(cellHash + t * 0.1, bass);
        hitFreqType = 0.0; // bass
    } 
    else if (cellType == 1) {
        // Frame cube - reacts to mid
        float size = 0.5 + mid * CUBE_SIZE_REACT;
        
        // NEW: Position wobble on mid frequencies
        vec3 wobble = vec3(
            cos(t * 3.0 + id.x * 2.0) * mid * CUBE_POS_REACT,
            sin(t * 2.5 + id.y * 2.0) * mid * CUBE_POS_REACT,
            cos(t * 2.8 + id.z * 2.0) * mid * CUBE_POS_REACT
        );
        
        vec3 qw = q + wobble;
        float outer = sdBox(qw, vec3(size) * breathe);
        float inner = sdBox(qw, vec3(size * 0.7) * breathe);
        d = max(outer, -inner);
        hitColor = palette(cellHash + 0.3 + t * 0.1, mid);
        hitFreqType = 1.0; // mid
    }
    else if (cellType == 2) {
        // Cross beams - react to high
        float size = 0.12 + high * BEAM_SIZE_REACT;
        
        // NEW: Subtle position pulse on high frequencies
        vec3 wobble = vec3(
            sin(t * 6.0 + id.x * 3.0) * high * BEAM_POS_REACT,
            cos(t * 5.5 + id.y * 3.0) * high * BEAM_POS_REACT,
            sin(t * 5.0 + id.z * 3.0) * high * BEAM_POS_REACT
        );
        
        vec3 qw = q + wobble;
        float beamX = sdBox(qw, vec3(1.2, size, size) * breathe);
        float beamY = sdBox(qw, vec3(size, 1.2, size) * breathe);
        float beamZ = sdBox(qw, vec3(size, size, 1.2) * breathe);
        d = min(min(beamX, beamY), beamZ);
        hitColor = palette(cellHash + 0.6 + t * 0.1, high);
        hitFreqType = 2.0; // high
    }
    else {
        // Sphere cluster - reacts to presence
        float r = 0.25 + presence * SPHERE_SIZE_REACT;
        
        // NEW: Position dance on presence (most movement for spheres)
        vec3 wobble = vec3(
            sin(t * 2.0 + id.x) * presence * SPHERE_POS_REACT,
            cos(t * 2.2 + id.y) * presence * SPHERE_POS_REACT * 1.2,
            sin(t * 1.8 + id.z) * presence * SPHERE_POS_REACT
        );
        
        vec3 qw = q + wobble;
        d = length(qw) - r * breathe;
        
        // Satellite spheres also wobble
        vec3 q2 = qw - vec3(0.5 + sin(t * 3.0) * presence * 0.1, 0.0, 0.0);
        d = min(d, length(q2) - r * 0.6 * breathe);
        q2 = qw + vec3(0.5 + cos(t * 3.0) * presence * 0.1, 0.0, 0.0);
        d = min(d, length(q2) - r * 0.6 * breathe);
        hitColor = palette(cellHash + 0.9 + t * 0.1, presence);
        hitFreqType = 3.0; // presence
    }
    
    // Connective tissue between cells - thin beams with more reaction
    vec3 qBeam = mod(p, 4.0) - 2.0;
    
    // Beams pulse to different frequencies
    float beamPulse1 = 0.03 + bass * 0.025;
    float beamPulse2 = 0.03 + mid * 0.02;
    float beamPulse3 = 0.03 + high * 0.015;
    
    float beam = sdBox(qBeam, vec3(beamPulse1, 0.03, 2.5));
    beam = min(beam, sdBox(qBeam, vec3(2.5, beamPulse2, 0.03)));
    beam = min(beam, sdBox(qBeam, vec3(0.03, 2.5, beamPulse3)));
    
    if (beam < d) {
        hitColor = vec3(0.2, 0.4, 0.8) + vec3(high, mid, bass) * 0.5;
        hitFreqType = -1.0; // connector
    }
    d = min(d, beam);
    
    // Frequency-differentiated glow accumulation
    float glowDist = 0.015 + d * d;
    glow1 += (GLOW_BASS + bass * 0.01) / glowDist;     // Bass glow
    glow2 += (GLOW_MID + mid * 0.008) / glowDist;      // Mid glow  
    glow3 += (GLOW_HIGH + high * 0.006) / glowDist;    // High glow
    
    // Floating particles in empty space - more reactive
    vec3 particleP = mod(p + vec3(t * 0.5, sin(t) * 0.3, t * 0.3), 2.0) - 1.0;
    float particle = length(particleP) - 0.02 - energy * 0.04;
    float particleGlow = 0.002 / (0.002 + particle * particle);
    glow1 += particleGlow * PARTICLE_GLOW * (0.5 + bass * 0.5);
    
    return d * 0.8;
}

// ===============================================================
// RENDERING
// ===============================================================

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

float calcAO(vec3 p, vec3 n) {
    float ao = 0.0;
    float scale = 1.0;
    for(int i = 0; i < 5; i++) {
        float hr = 0.01 + 0.12 * float(i);
        float dd = map(p + n * hr);
        ao += (hr - dd) * scale;
        scale *= 0.7;
    }
    return clamp(1.0 - ao * 2.0, 0.0, 1.0);
}

vec3 render(vec3 ro, vec3 rd) {
    float t = iTime;
    
    // Sky/void background
    vec3 col = vec3(0.01, 0.01, 0.03);
    col += palette(rd.y * 0.5 + t * 0.05, energy) * 0.08;
    
    // Distant grid lines in background
    vec2 bgGrid = abs(fract(rd.xz * 10.0 + t * 0.1) - 0.5);
    float gridLine = smoothstep(0.02, 0.0, min(bgGrid.x, bgGrid.y));
    col += gridLine * 0.05 * vec3(0.3, 0.5, 0.8);
    
    glow1 = 0.0;
    glow2 = 0.0;
    glow3 = 0.0;
    
    // Raymarch
    float td = 0.0;
    vec3 lastHitColor = vec3(0.0);
    float lastHitFreq = 0.0;
    
    for(int i = 0; i < 120; i++) {
        vec3 p = ro + rd * td;
        float d = map(p);
        
        if(d < 0.001) {
            lastHitColor = hitColor;
            lastHitFreq = hitFreqType;
            vec3 n = calcNormal(p);
            float ao = calcAO(p, n);
            
            // ENHANCED LIGHTING - Different lights pulse to different frequencies
            vec3 lightDir1 = normalize(vec3(1.0 + bass * 0.3, 2.0, -1.0));
            vec3 lightDir2 = normalize(vec3(-1.0, 1.5 + mid * 0.4, 1.0));
            vec3 lightDir3 = normalize(vec3(0.0, -1.0, 1.0 + high * 0.3));
            
            // Light colors that shift with audio
            vec3 light1Col = vec3(1.0, 0.9, 0.8) * (1.0 + bass * LIGHT_BASS_PULSE);
            vec3 light2Col = vec3(0.8, 0.9, 1.0) * (1.0 + mid * LIGHT_MID_PULSE);
            vec3 light3Col = vec3(0.9, 0.8, 1.0) * (1.0 + high * LIGHT_HIGH_PULSE);
            
            float diff1 = max(dot(n, lightDir1), 0.0);
            float diff2 = max(dot(n, lightDir2), 0.0) * 0.5;
            float diff3 = max(dot(n, lightDir3), 0.0) * 0.3;
            
            float spec = pow(max(dot(reflect(-lightDir1, n), -rd), 0.0), 32.0);
            
            // Fresnel
            float fresnel = pow(1.0 - abs(dot(n, -rd)), 3.0);
            
            // Surface color with multi-light contribution
            col = lastHitColor * 0.15;
            col += lastHitColor * diff1 * light1Col * 0.5;
            col += lastHitColor * diff2 * light2Col * 0.3;
            col += lastHitColor * diff3 * light3Col * 0.2;
            col += vec3(0.8, 0.9, 1.0) * spec * 0.5;
            col += lastHitColor * fresnel * 0.4;
            col *= ao;
            
            // Edge glow - enhanced and frequency-specific
            col += lastHitColor * 0.15 * energy;
            col += lastHitColor * 0.1 * (lastHitFreq == 0.0 ? bass : 
                                          lastHitFreq == 1.0 ? mid :
                                          lastHitFreq == 2.0 ? high : presence);
            
            break;
        }
        
        if(td > FAR) break;
        td += d;
    }
    
    // Add frequency-differentiated glows
    vec3 glow1Col = palette(t * 0.2, bass) * glow1 * 0.012;           // Bass - warm
    vec3 glow2Col = palette(t * 0.2 + 0.33, mid) * glow2 * 0.010;    // Mid - shifted hue
    vec3 glow3Col = palette(t * 0.2 + 0.66, high) * glow3 * 0.008;   // High - cool
    col += glow1Col + glow2Col + glow3Col;
    
    // Extra glow pulse on kick
    col += vec3(0.1, 0.05, 0.02) * kick * 0.15;
    
    // Fog
    col = mix(col, vec3(0.02, 0.03, 0.08) + palette(t * 0.1, energy) * 0.05, 
              1.0 - exp(-td * 0.015));
    
    return col;
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime;
    
    analyzeAudio();
    
    // ===========================================================
    // CAMERA - Orbits outside the structure, never enters
    // ===========================================================
    
    // Large orbital radius keeps camera safely outside
    float orbitRadius = 12.0 + sin(t * 0.1) * 3.0;
    
    // Smooth orbital motion with audio influence
    float orbitSpeed = 0.15 + energy * 0.05;
    float orbitAngle = t * orbitSpeed;
    float verticalMotion = sin(t * 0.13) * 4.0;
    
    // Camera position - circular orbit
    vec3 ro = vec3(
        cos(orbitAngle) * orbitRadius,
        verticalMotion + sin(t * 0.2) * 2.0,
        sin(orbitAngle) * orbitRadius + t * 2.0  // Slow drift forward
    );
    
    // Look toward center with some variation
    vec3 target = ro + vec3(
        -cos(orbitAngle) * 5.0,
        sin(t * 0.3) * 2.0,
        -sin(orbitAngle) * 5.0 + 5.0
    );
    
    // Camera shake on kick
    ro += vec3(
        sin(t * 50.0) * kick * 0.05,
        cos(t * 50.0) * kick * 0.05,
        0.0
    );
    
    // Build camera matrix
    vec3 fw = normalize(target - ro);
    vec3 rt = normalize(cross(vec3(0.0, 1.0, 0.0), fw));
    vec3 up = cross(fw, rt);
    
    // Roll with audio
    float roll = sin(t * 0.5) * 0.1 + bass * 0.05;
    rt = rt * cos(roll) + up * sin(roll);
    up = cross(fw, rt);
    
    // Ray direction with subtle lens distortion on bass
    float fov = 0.8 - bass * 0.1;
    vec3 rd = normalize(uv.x * rt + uv.y * up + fov * fw);
    
    // ===========================================================
    // RENDER
    // ===========================================================
    
    vec3 col = render(ro, rd);
    
    // Chromatic aberration on high energy
    if(energy > 0.4) {
        float aberr = (energy - 0.4) * 0.008;
        vec3 rd2 = normalize((uv.x + aberr) * rt + uv.y * up + fov * fw);
        vec3 rd3 = normalize((uv.x - aberr) * rt + uv.y * up + fov * fw);
        col.r = render(ro, rd2).r;
        col.b = render(ro, rd3).b;
    }
    
    // Post-processing
    // Contrast boost
    col = smoothstep(0.0, 1.0, col);
    
    // Brightness pulse with kick
    col *= 1.0 + kick * 0.3;
    
    // Color grading - push toward complementary colors based on audio
    col = mix(col, col * vec3(1.1, 0.95, 0.9), bass * 0.3);
    col = mix(col, col * vec3(0.9, 0.95, 1.1), high * 0.3);
    
    // Vignette
    float vig = 1.0 - dot(uv, uv) * 0.3;
    col *= vig;
    
    // Film grain
    float grain = hash(vec3(fragCoord, t)) * 0.03;
    col += grain;
    
    // Gamma
    col = pow(col, vec3(0.9));
    
    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
