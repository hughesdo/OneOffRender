#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;
uniform vec4 iMouse;

out vec4 fragColor;

/* RAINBOW PARTICLE VORTEX
 * =======================
 * A swirling rainbow galaxy vortex with sparkles and particles.
 * Inspired by the vibrant nebula/vortex aesthetic.
 */

// ============================================================================
// TWEAKING VARIABLES
// ============================================================================

// MASTER CONTROLS
#define AUDIO_REACTIVE 1.0
#define AUDIO_SENSITIVITY 1.5

// VORTEX
#define VORTEX_SPEED 0.4            // Rotation speed
#define VORTEX_PULL 2.0             // How strongly it pulls inward
#define SPIRAL_ARMS 3.0             // Number of spiral arms
#define SPIRAL_TIGHTNESS 4.0        // How tight the spiral is

// PARTICLES
#define PARTICLE_DENSITY 80.0       // Number of particle layers
#define PARTICLE_SIZE 0.015         // Size of sparkles
#define PARTICLE_BRIGHTNESS 1.5     // Sparkle brightness
#define PARTICLE_SPEED 0.3          // Particle movement speed

// COLORS
#define COLOR_SATURATION 1.0        // Color saturation (0-1)
#define COLOR_BRIGHTNESS 1.2        // Overall brightness
#define RAINBOW_SPEED 0.2           // How fast colors shift

// GLOW
#define GLOW_INTENSITY 0.4          // Center glow amount
#define GLOW_SIZE 0.5               // Size of center glow

// AUDIO RESPONSE
#define BASS_PULSE 0.3              // Bass pulses the vortex
#define MID_SPIRAL 0.5              // Mids affect spiral speed
#define TREB_SPARKLE 2.0            // Treble adds sparkles

// ============================================================================
// AUDIO
// ============================================================================

struct Audio {
    float bass, mid, treb;
};

Audio getAudio() {
    Audio a;
    float sens = AUDIO_SENSITIVITY * AUDIO_REACTIVE;
    a.bass = texture(iChannel0, vec2(0.05, 0.0)).x * sens;
    a.mid = texture(iChannel0, vec2(0.2, 0.0)).x * sens;
    a.treb = texture(iChannel0, vec2(0.6, 0.0)).x * sens;
    return a;
}

// ============================================================================
// UTILITIES
// ============================================================================

#define PI 3.14159265359
#define TAU 6.28318530718

// Hash functions for randomness
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

vec3 hash3(vec2 p) {
    vec3 q = vec3(dot(p, vec2(127.1, 311.7)),
                  dot(p, vec2(269.5, 183.3)),
                  dot(p, vec2(419.2, 371.9)));
    return fract(sin(q) * 43758.5453);
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// HSV to RGB conversion for rainbow colors
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// ============================================================================
// NOISE FUNCTIONS
// ============================================================================

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

float fbm(vec2 p) {
    float f = 0.0;
    f += 0.5000 * noise(p); p *= 2.02;
    f += 0.2500 * noise(p); p *= 2.03;
    f += 0.1250 * noise(p); p *= 2.01;
    f += 0.0625 * noise(p);
    return f / 0.9375;
}

// ============================================================================
// VORTEX & PARTICLES
// ============================================================================

// Create the swirling vortex pattern
vec3 vortex(vec2 uv, float time, Audio audio) {
    vec3 col = vec3(0.0);
    
    float r = length(uv);
    float a = atan(uv.y, uv.x);
    
    // Audio-reactive speed
    float speed = VORTEX_SPEED + audio.mid * MID_SPIRAL;
    float pulse = 1.0 + audio.bass * BASS_PULSE;
    
    // Spiral distortion
    float spiral = a + r * SPIRAL_TIGHTNESS - time * speed * TAU;
    
    // Create multiple spiral arms with rainbow colors
    for (float i = 0.0; i < SPIRAL_ARMS; i++) {
        float offset = i * TAU / SPIRAL_ARMS;
        float arm = sin(spiral + offset) * 0.5 + 0.5;
        arm = pow(arm, 3.0);
        
        // Rainbow hue based on angle and time
        float hue = fract(a / TAU + time * RAINBOW_SPEED + i / SPIRAL_ARMS);
        vec3 armCol = hsv2rgb(vec3(hue, COLOR_SATURATION, COLOR_BRIGHTNESS));
        
        // Fade with distance
        float fade = exp(-r * VORTEX_PULL / pulse);
        col += armCol * arm * fade * 0.6;
    }
    
    return col;
}

// Create sparkle particles
vec3 particles(vec2 uv, float time, Audio audio) {
    vec3 col = vec3(0.0);
    
    float sparkleBoost = 1.0 + audio.treb * TREB_SPARKLE;
    
    for (float i = 0.0; i < PARTICLE_DENSITY; i++) {
        // Random position for each particle
        float t = time * PARTICLE_SPEED + i * 0.1;
        vec2 seed = vec2(i * 0.123, i * 0.456);
        
        // Particle starts at random position and spirals inward
        float startAngle = hash(seed) * TAU;
        float startRadius = hash(seed.yx) * 1.5 + 0.2;
        float particleSpeed = hash(seed + 0.5) * 0.5 + 0.5;
        
        // Spiral motion
        float angle = startAngle + t * particleSpeed * 2.0;
        float radius = mod(startRadius - t * 0.3, 1.8);
        
        vec2 particlePos = vec2(cos(angle), sin(angle)) * radius;
        
        // Distance to particle
        float d = length(uv - particlePos);
        
        // Sparkle effect
        float sparkle = PARTICLE_SIZE / (d + 0.001);
        sparkle = pow(sparkle, 1.5);
        
        // Flicker
        float flicker = sin(t * 20.0 + i * 5.0) * 0.3 + 0.7;
        sparkle *= flicker * sparkleBoost;
        
        // Rainbow color for particle
        float hue = fract(hash(seed * 2.0) + time * RAINBOW_SPEED * 0.5);
        vec3 particleCol = hsv2rgb(vec3(hue, 0.8, 1.0));
        
        col += particleCol * sparkle * PARTICLE_BRIGHTNESS * 0.02;
    }
    
    return col;
}

// Nebula/cloud background
vec3 nebula(vec2 uv, float time, Audio audio) {
    vec2 p = uv;
    
    // Swirl the coordinates
    float r = length(p);
    float a = atan(p.y, p.x);
    a += time * VORTEX_SPEED * 0.5;
    a += (1.0 - r) * 2.0; // More swirl near center
    p = vec2(cos(a), sin(a)) * r;
    
    // Layered noise for nebula effect
    float n = 0.0;
    n += fbm(p * 3.0 + time * 0.1) * 0.5;
    n += fbm(p * 6.0 - time * 0.15) * 0.25;
    n += fbm(p * 12.0 + time * 0.2) * 0.125;
    
    // Rainbow coloring based on position and noise
    float hue = fract(a / TAU + n * 0.5 + time * RAINBOW_SPEED);
    float sat = COLOR_SATURATION * 0.9;
    float val = n * COLOR_BRIGHTNESS * 0.8;
    
    // Audio pulse
    val *= 1.0 + audio.bass * 0.5;
    
    return hsv2rgb(vec3(hue, sat, val));
}

// Center glow
vec3 centerGlow(vec2 uv, float time, Audio audio) {
    float r = length(uv);
    float glow = GLOW_SIZE / (r + 0.1);
    glow = pow(glow, 1.5) * GLOW_INTENSITY;
    
    // Pulse with bass
    glow *= 1.0 + audio.bass * 0.8;
    
    // Rainbow glow
    float hue = fract(time * RAINBOW_SPEED * 2.0);
    vec3 glowCol = hsv2rgb(vec3(hue, 0.6, 1.0));
    
    return glowCol * glow;
}

// ============================================================================
// MAIN
// ============================================================================

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;
    
    Audio audio = getAudio();
    float time = iTime;
    
    // Compose the effect
    vec3 col = vec3(0.0);
    
    // Layer 1: Nebula background
    col += nebula(uv, time, audio) * 0.5;
    
    // Layer 2: Vortex spirals
    col += vortex(uv, time, audio);
    
    // Layer 3: Sparkle particles
    col += particles(uv, time, audio);
    
    // Layer 4: Center glow
    col += centerGlow(uv, time, audio);
    
    // Add some overall sparkle noise
    float sparkleNoise = hash(uv * 100.0 + time * 10.0);
    sparkleNoise = pow(sparkleNoise, 20.0) * audio.treb * TREB_SPARKLE;
    col += vec3(sparkleNoise);
    
    // Vignette (subtle)
    float vig = 1.0 - length(uv) * 0.2;
    col *= vig;
    
    // Tone mapping
    col = col / (1.0 + col * 0.5);
    
    // Slight contrast boost
    col = pow(col, vec3(0.9));
    
    // Saturation boost
    float grey = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(grey), col, 1.3);
    
    fragColor = vec4(col, 1.0);
}
