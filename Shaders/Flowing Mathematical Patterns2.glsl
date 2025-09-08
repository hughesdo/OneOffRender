#version 330 core

// Flowing Mathematical Patterns - Audio-Reactive Version - Adapted for OneOffRender
// Set iChannel0 to audio input for bass-reactive color shifting

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// ==== CONFIGURABLE PARAMETERS ====
#define FLOW_SPEED 1.7          // Flow animation speed
#define COMPLEXITY 8.0          // Pattern complexity level
#define TURBULENCE 1.5          // Turbulence intensity
#define BASE_COLOR_SHIFT 0.0    // Base color shift (overridden by audio)

// Audio reactivity settings
#define BASS_SENSITIVITY 2.0    // How sensitive to bass hits (1.0-5.0)
#define BASS_THRESHOLD 0.15     // Minimum bass level to trigger effect (0.1-0.8)
#define COLOR_SHIFT_RANGE 3.0   // Maximum color shift from audio (0.0-5.0)
#define BASS_SMOOTHING 0.75     // Bass response smoothing (0.5-0.95)
#define BEAT_DECAY 0.95         // How quickly beats fade (0.9-0.99)
#define MIN_BEAT_INTERVAL 0.1   // Minimum time between beats (seconds)

// Mathematical constants
#define PI 3.14159265359
#define PHI 1.6180339887
#define PHI_INV 0.6180339887
#define E 2.7182818285

// Global variables for beat tracking
float smoothedBass = 0.0;
float lastBeatTime = 0.0;
float beatEnergy = 0.0;

// Rotation matrix
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// Hash function for noise
float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

// Smooth noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Fractal Brownian Motion
float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < octaves; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

// Audio sampling function with beat detection - OneOffRender format
float getBass() {
    return texture(iChannel0, vec2(0.125, 0.5)).r;  // Bass region in OneOffRender format
}

// Get previous bass level for beat detection (simulate with slight offset)
float getPreviousBass() {
    return texture(iChannel0, vec2(0.0625, 0.5)).r;  // Lower bass region
}

// Multi-method beat detection for reliability across different music types
float detectBeat() {
    float currentBass = getBass();
    float prevBass = getPreviousBass();
    
    // Method 1: Velocity-based detection (good for punchy beats)
    float bassIncrease = max(0.0, currentBass - prevBass);
    float velocity = bassIncrease * 8.0;
    
    // Method 2: Threshold with auto-adaptation (good for consistent levels)
    float adaptiveThreshold = BASS_THRESHOLD + smoothedBass * 0.2;
    float thresholdHit = smoothstep(adaptiveThreshold, adaptiveThreshold + 0.1, currentBass);
    
    // Method 3: Relative peak detection (good for varying dynamics)
    float avgBass = (currentBass + prevBass + smoothedBass) / 3.0;
    float relativePeak = max(0.0, (currentBass - avgBass * 1.2)) * 5.0;
    
    // Method 4: Frequency band analysis (broader spectrum) - OneOffRender format
    float midBass = texture(iChannel0, vec2(0.25, 0.5)).r;   // Mid-bass region
    float subBass = texture(iChannel0, vec2(0.03125, 0.5)).r; // Sub-bass region
    float combinedLow = (currentBass * 0.6 + midBass * 0.3 + subBass * 0.1);
    float bandHit = smoothstep(0.2, 0.5, combinedLow);
    
    // Combine methods with weights
    float combinedBeat = velocity * 0.4 + thresholdHit * 0.3 + relativePeak * 0.2 + bandHit * 0.1;
    
    // Time-based beat limiting to prevent over-triggering
    float timeSinceLastBeat = iTime - lastBeatTime;
    float timeGate = smoothstep(0.0, MIN_BEAT_INTERVAL, timeSinceLastBeat);
    
    return clamp(combinedBeat * timeGate, 0.0, 1.0);
}

// Flow field based on mathematical functions
vec2 flowField(vec2 p) {
    float t = iTime * FLOW_SPEED;
    
    // Golden ratio spiral influence
    float angle = atan(p.y, p.x);
    float radius = length(p);
    float spiral = angle + log(radius + 0.1) * PHI_INV;
    
    // Multiple mathematical influences
    float flow1 = sin(p.x * COMPLEXITY + t) * cos(p.y * COMPLEXITY * PHI_INV + t * 0.7);
    float flow2 = sin(spiral * 2.0 + t * 1.3) * 0.5;
    float flow3 = fbm(p * 0.5 + t * 0.2, 3) * TURBULENCE;
    
    // Audio-reactive interaction instead of mouse
    float audioInfluence = getBass() * 0.5;

    vec2 flow = vec2(
        flow1 + flow2 + flow3 + audioInfluence * sin(t * 2.0),
        cos(p.y * COMPLEXITY * E + t * 0.9) * cos(p.x * COMPLEXITY + t * 1.1) +
        flow3 * 0.7 + audioInfluence * cos(t * 1.7)
    );
    
    return flow * 0.3;
}

// Advanced color mapping with audio-reactive color shift
vec3 getColor(float value, vec2 pos) {
    float t = iTime * 0.3;
    
    // Multi-method beat detection for better reliability
    float beatDetection = detectBeat();
    
    // Update beat tracking
    if (beatDetection > 0.5) {
        lastBeatTime = iTime;
        beatEnergy = max(beatEnergy, beatDetection);
    }
    
    // Decay beat energy over time
    beatEnergy *= BEAT_DECAY;
    
    // Smooth the combined response
    float finalBeatSignal = max(beatDetection, beatEnergy * 0.7);
    smoothedBass = mix(smoothedBass, finalBeatSignal, 1.0 - BASS_SMOOTHING);
    
    // Color shift rotates gently from 0-3 on bass hits only
    float audioColorShift = smoothedBass * COLOR_SHIFT_RANGE * BASS_SENSITIVITY;
    float totalColorShift = BASE_COLOR_SHIFT + audioColorShift;
    
    // Multi-layered color composition
    vec3 color1 = vec3(0.5 + 0.5 * sin(value * 6.28 + t + totalColorShift),
                      0.5 + 0.5 * sin(value * 6.28 + t + totalColorShift + 2.09),
                      0.5 + 0.5 * sin(value * 6.28 + t + totalColorShift + 4.18));
    
    vec3 color2 = vec3(0.5 + 0.5 * cos(value * 3.14 * PHI + t * 1.3 + totalColorShift),
                      0.5 + 0.5 * cos(value * 3.14 * PHI + t * 1.3 + totalColorShift + 1.57),
                      0.5 + 0.5 * cos(value * 3.14 * PHI + t * 1.3 + totalColorShift + 3.14));
    
    // Golden ratio based mixing
    float mixFactor = 0.5 + 0.5 * sin(length(pos) * PHI + t);
    vec3 finalColor = mix(color1, color2, mixFactor);
    
    // Sparkle effect removed
    
    // Add subtle bass-reactive brightness boost
    finalColor *= 1.0 + smoothedBass * 0.3;
    
    return finalColor;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord.xy - iResolution.xy * 0.5) / iResolution.y;
    vec2 originalUv = uv;
    
    float t = iTime * FLOW_SPEED;
    
    // Create flowing distortion
    vec2 flow = vec2(0.0);
    float amplitude = 1.0;
    
    for(int i = 0; i < 5; i++) {
        vec2 currentFlow = flowField(uv * amplitude);
        flow += currentFlow / amplitude;
        uv += currentFlow * 0.1;
        amplitude *= 1.7;
    }
    
    // Calculate final pattern value
    float pattern = 0.0;
    
    // Layer 1: Primary flow pattern
    pattern += sin(uv.x * 8.0 + flow.x * 5.0) * cos(uv.y * 8.0 + flow.y * 5.0) * 0.5;
    
    // Layer 2: Golden ratio based interference
    float goldenAngle = atan(uv.y, uv.x) * PHI;
    pattern += sin(goldenAngle + length(uv) * 10.0 + t) * 0.3;
    
    // Layer 3: Turbulent details
    pattern += fbm(uv * 5.0 + flow, 4) * 0.4;
    
    // Layer 4: Radial waves
    float radius = length(uv);
    pattern += sin(radius * 15.0 - t * 3.0) * exp(-radius * 0.5) * 0.6;
    
    // Normalize and enhance
    pattern = (pattern + 1.0) * 0.5;
    pattern = pow(pattern, 0.8);
    
    // Generate final color
    vec3 color = getColor(pattern, originalUv);
    
    // Add depth and atmosphere
    float depth = 1.0 - length(originalUv) * 0.3;
    color *= depth;
    
    // Final brightness adjustment
    color = pow(color, vec3(0.9));
    
    fragColor = vec4(color, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}