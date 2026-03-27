// Audio Reactive Lava Tunnel Shader for Shadertoy
// SETUP: Add an audio input (iChannel0) - click iChannel0 and select "Soundcloud" or "Microphone"

// ============================================
// TWEAKABLE VARIABLES - Adjust these!
// ============================================

// Audio Reactivity Multipliers (how much each frequency band affects glow)
#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

// ============================================
// ROTATION CONTROLS
// ============================================
#define ROTATION_SPEED 0.2          // Speed of full-screen rotation (lower = slower, try 0.05-0.3)
#define ROTATION_DIRECTION 1.0      // 1.0 = clockwise, -1.0 = counter-clockwise

#define BASS_MULT 2.5           // Low frequencies (kick drums, bass) -> RED/ORANGE glow
#define MID_MULT 2.0            // Mid frequencies (vocals, guitars) -> PURPLE/MAGENTA glow  
#define HIGH_MULT 1.8           // High frequencies (hi-hats, cymbals) -> BLUE/CYAN glow

// Frequency Band Ranges (0.0 - 1.0 across spectrum)
#define BASS_FREQ 0.05          // Sample point for bass
#define MID_FREQ 0.25           // Sample point for mids
#define HIGH_FREQ 0.6           // Sample point for highs

// Base Glow Intensities (without audio)
#define BASE_GLOW_RED 0.3       // Minimum red/orange glow
#define BASE_GLOW_PURPLE 0.2    // Minimum purple glow
#define BASE_GLOW_BLUE 0.25     // Minimum blue/cyan glow

// Visual Parameters
#define TUNNEL_SPEED 3.0        // How fast camera moves through tunnel
#define MORPH_SPEED 0.4         // How fast the surface morphs
#define NOISE_SCALE 1.5         // Scale of displacement noise
#define DISPLACEMENT_AMT 0.7    // Amount of surface displacement
#define BLOOM_INTENSITY 0.5     // Glow/bloom amount
#define FOG_DENSITY 0.08        // How quickly tunnel fades to black

// ============================================
// SHADER CODE
// ============================================

#define MAX_STEPS 80
#define MAX_DIST 30.0
#define SURF_DIST 0.002

mat2 rot2D(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

// Better hash
float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// Smooth noise
float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    return mix(
        mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
            mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
        mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
            mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y),
        f.z);
}

// Ridged multifractal for sharp peaks
float ridgedNoise(vec3 p) {
    return 1.0 - abs(noise(p) * 2.0 - 1.0);
}

// FBM with domain warping
float fbm(vec3 p) {
    float t = iTime * MORPH_SPEED;
    
    // Domain warping for liquid look
    vec3 q = p + noise(p + t) * 0.5;
    
    float f = 0.0;
    float amp = 0.5;
    for(int i = 0; i < 5; i++) {
        f += amp * ridgedNoise(q);
        q = q * 2.1 + t * 0.3;
        amp *= 0.5;
    }
    return f;
}

// Get audio levels for each frequency band
vec3 getAudio() {
    #ifdef iChannel0
    float bass = texture(iChannel0, vec2(BASS_FREQ, 0.0)).x;
    float mid = texture(iChannel0, vec2(MID_FREQ, 0.0)).x;
    float high = texture(iChannel0, vec2(HIGH_FREQ, 0.0)).x;
    return vec3(bass, mid, high);
    #else
    // Fake audio for preview (sine wave simulation)
    float t = iTime;
    float bass = 0.5 + 0.5 * sin(t * 2.0);
    float mid = 0.5 + 0.5 * sin(t * 3.7 + 1.0);
    float high = 0.5 + 0.5 * sin(t * 5.3 + 2.0);
    return vec3(bass, mid, high);
    #endif
}

// Tunnel SDF
float map(vec3 p) {
    float t = iTime * TUNNEL_SPEED;
    p.z += t;
    
    // Twist the tunnel
    float twist = sin(p.z * 0.1) * 0.3;
    p.xy *= rot2D(twist);
    
    // Base cylinder (inverted - we're inside)
    float tunnel = -(length(p.xy) - 2.0);
    
    // Displacement
    vec3 np = p * NOISE_SCALE;
    float disp = fbm(np) * DISPLACEMENT_AMT;
    
    tunnel += disp;
    
    return tunnel;
}

// Get displacement value for coloring
float getDisplacement(vec3 p) {
    float t = iTime * TUNNEL_SPEED;
    p.z += t;
    float twist = sin(p.z * 0.1) * 0.3;
    p.xy *= rot2D(twist);
    vec3 np = p * NOISE_SCALE;
    return fbm(np);
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.002, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

float raymarch(vec3 ro, vec3 rd) {
    float d = 0.0;
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d;
        float ds = map(p);
        d += ds * 0.8; // Slow down for accuracy
        if(d > MAX_DIST || abs(ds) < SURF_DIST) break;
    }
    return d;
}

// Color palette based on height + audio
vec3 getColor(float h, vec3 audio) {
    // Audio-driven glow multipliers
    float bassGlow = BASE_GLOW_RED + audio.x * BASS_MULT;
    float midGlow = BASE_GLOW_PURPLE + audio.y * MID_MULT;
    float highGlow = BASE_GLOW_BLUE + audio.z * HIGH_MULT;
    
    // Color zones based on displacement height
    // Low = blue/cyan (high freq), Mid = purple (mid freq), High = orange/red (bass)
    
    vec3 blue = vec3(0.0, 0.6, 1.0) * highGlow;      // Cyan - highs
    vec3 purple = vec3(0.6, 0.0, 1.0) * midGlow;     // Purple - mids
    vec3 orange = vec3(1.0, 0.4, 0.0) * bassGlow;    // Orange - bass
    vec3 yellow = vec3(1.0, 0.9, 0.2) * bassGlow;    // Yellow peaks - bass
    
    vec3 col;
    if(h < 0.35) {
        col = mix(vec3(0.0), blue, smoothstep(0.1, 0.35, h));
    } else if(h < 0.5) {
        col = mix(blue, purple, smoothstep(0.35, 0.5, h));
    } else if(h < 0.7) {
        col = mix(purple, orange, smoothstep(0.5, 0.7, h));
    } else {
        col = mix(orange, yellow, smoothstep(0.7, 0.9, h));
    }
    
    return col;
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // ========================================
    // FULL SCREEN ROTATION
    // ========================================
    float rotAngle = iTime * ROTATION_SPEED * ROTATION_DIRECTION;
    uv *= rot2D(rotAngle);
    
    // Get audio
    vec3 audio = getAudio();
    
    // Camera
    vec3 ro = vec3(0.0, 0.0, 0.0);
    vec3 rd = normalize(vec3(uv, 0.9)); // Wider FOV
    
    // Subtle camera sway
    float sway = iTime * 0.3;
    rd.xy *= rot2D(sin(sway) * 0.05);
    
    vec3 col = vec3(0.0);
    float d = raymarch(ro, rd);
    
    if(d < MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p);
        
        // Get height for coloring
        float h = getDisplacement(p);
        
        // Base color from palette
        vec3 baseCol = getColor(h, audio);
        
        // Fresnel
        float fresnel = pow(1.0 - abs(dot(-rd, n)), 2.0);
        
        // Specular highlight
        vec3 lightDir = normalize(vec3(0.5, 0.5, -1.0));
        float spec = pow(max(dot(reflect(rd, n), lightDir), 0.0), 32.0);
        vec3 specCol = vec3(1.0, 0.95, 0.8) * spec * 2.0;
        
        // Reflection
        vec3 reflDir = reflect(rd, n);
        float reflDist = raymarch(p + n * 0.02, reflDir);
        vec3 reflCol = vec3(0.0);
        if(reflDist < MAX_DIST * 0.5) {
            vec3 reflP = p + reflDir * reflDist;
            float reflH = getDisplacement(reflP);
            reflCol = getColor(reflH, audio) * 0.5;
        }
        
        // Combine
        col = baseCol + specCol;
        col = mix(col, reflCol, fresnel * 0.4);
        
        // Distance fog
        float fog = exp(-d * FOG_DENSITY);
        col *= fog;
        
        // Ambient occlusion (fake)
        float ao = smoothstep(0.0, 0.5, h);
        col *= 0.5 + 0.5 * ao;
    }
    
    // Audio-reactive bloom
    float bloomAmt = BLOOM_INTENSITY * (1.0 + (audio.x + audio.y) * 0.5);
    col += col * col * bloomAmt;
    
    // Vignette
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.4 + 0.6 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.25);
    
    // Tone mapping
    col = 1.0 - exp(-col * 1.2);
    
    // Gamma
    col = pow(col, vec3(0.4545));
    
    // Subtle chromatic aberration
    vec2 caUV = uv * 0.005;
    
    fragColor = vec4(col, 1.0);
}
