#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

/*
 * SDF RAINBOW VORTEX
 * ==================
 * A swirling vortex with crystalline particles using SDF techniques.
 * Audio reactive in COLOR only.
 */

// ============================================================================
// TWEAKING VARIABLES
// ============================================================================

#define VORTEX_SPEED 0.3           // Rotation speed
#define SPIRAL_TIGHTNESS 3.0       // How tight the spiral winds
#define PARTICLE_LAYERS 12.0       // Number of particle layers
#define PARTICLES_PER_LAYER 40.0   // Particles per layer
#define PARTICLE_LENGTH 0.08       // Length of crystal particles
#define PARTICLE_WIDTH 0.008       // Width of crystal particles

// COLOR (audio reactive)
#define HUE_SHIFT_SPEED 0.15       // Base rainbow cycling speed
#define AUDIO_HUE_SHIFT 0.3        // How much audio shifts hue
#define AUDIO_SATURATION 0.2       // Audio effect on saturation
#define AUDIO_BRIGHTNESS 0.4       // Audio effect on brightness

// AUDIO
#define AUDIO_SENSITIVITY 1.5

// ============================================================================
// AUDIO
// ============================================================================

struct Audio {
    float bass, mid, treb, total;
};

Audio getAudio() {
    Audio a;
    float sens = AUDIO_SENSITIVITY;
    a.bass = texture(iChannel0, vec2(0.05, 0.25)).x * sens;
    a.mid = texture(iChannel0, vec2(0.2, 0.25)).x * sens;
    a.treb = texture(iChannel0, vec2(0.6, 0.25)).x * sens;
    a.total = (a.bass + a.mid + a.treb) / 3.0;
    return a;
}

// ============================================================================
// UTILITIES
// ============================================================================

#define PI 3.14159265359
#define TAU 6.28318530718

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// ============================================================================
// SDF FUNCTIONS
// ============================================================================

// SDF for a line segment (capsule)
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// SDF for an oriented box (rectangle)
float sdOrientedBox(vec2 p, vec2 a, vec2 b, float th) {
    float l = length(b - a);
    vec2 d = (b - a) / l;
    vec2 q = p - (a + b) * 0.5;
    q = mat2(d.x, -d.y, d.y, d.x) * q;
    q = abs(q) - vec2(l * 0.5, th);
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

// ============================================================================
// VORTEX PARTICLE SYSTEM
// ============================================================================

vec4 vortexParticles(vec2 uv, float time, Audio audio) {
    vec3 col = vec3(0.0);
    float totalAlpha = 0.0;

    // Process multiple layers of particles
    for (float layer = 0.0; layer < PARTICLE_LAYERS; layer++) {
        float layerDepth = layer / PARTICLE_LAYERS;
        float layerScale = 0.5 + layerDepth * 1.5; // Particles get larger further out

        for (float i = 0.0; i < PARTICLES_PER_LAYER; i++) {
            float id = layer * PARTICLES_PER_LAYER + i;

            // Random seed for this particle
            float seed = hash(id);
            float seed2 = hash(id + 100.0);
            float seed3 = hash(id + 200.0);

            // Particle orbit parameters
            float baseRadius = 0.1 + seed * 1.4;
            float orbitSpeed = 0.5 + seed2 * 0.5;
            float startAngle = seed3 * TAU;

            // Spiral inward motion
            float t = time * VORTEX_SPEED * orbitSpeed;
            float radius = mod(baseRadius - t * 0.15, 1.5);
            float angle = startAngle + t * (2.0 + (1.5 - radius) * SPIRAL_TIGHTNESS);

            // Particle position
            vec2 pos = vec2(cos(angle), sin(angle)) * radius;

            // Particle orientation follows the spiral tangent
            float tangentAngle = angle + PI * 0.5 + (1.0 - radius) * 0.5;
            vec2 dir = vec2(cos(tangentAngle), sin(tangentAngle));

            // Particle endpoints
            float len = PARTICLE_LENGTH * (0.5 + seed * 0.5) * layerScale;
            vec2 a = pos - dir * len * 0.5;
            vec2 b = pos + dir * len * 0.5;

            // SDF distance to particle
            float width = PARTICLE_WIDTH * layerScale;
            float d = sdSegment(uv, a, b) - width;

            // Particle color - AUDIO REACTIVE
            float baseHue = fract(angle / TAU + time * HUE_SHIFT_SPEED + radius * 0.3);

            // Audio shifts the hue
            float hue = baseHue + audio.total * AUDIO_HUE_SHIFT;

            // Audio affects saturation
            float sat = 0.7 + audio.mid * AUDIO_SATURATION;

            // Audio affects brightness
            float val = 0.8 + audio.treb * AUDIO_BRIGHTNESS;

            vec3 particleCol = hsv2rgb(vec3(hue, sat, val));

            // Glow and solid core
            float glow = 0.003 / (d + 0.003);
            float core = smoothstep(0.002, 0.0, d);

            // Depth fade
            float depthFade = 0.3 + 0.7 * (1.0 - layerDepth);

            // Distance from center fade
            float centerFade = smoothstep(1.8, 0.0, radius);

            col += particleCol * (glow * 0.15 + core * 0.8) * depthFade * centerFade;
            totalAlpha += core * depthFade * centerFade;
        }
    }

    return vec4(col, totalAlpha);
}

// ============================================================================
// BACKGROUND SPIRAL
// ============================================================================

vec3 spiralBackground(vec2 uv, float time, Audio audio) {
    float r = length(uv);
    float a = atan(uv.y, uv.x);

    // Spiral pattern
    float spiral = sin(a * 3.0 - r * SPIRAL_TIGHTNESS * 2.0 + time * VORTEX_SPEED * TAU);
    spiral = spiral * 0.5 + 0.5;
    spiral = pow(spiral, 4.0);

    // Fade toward center and edges
    float fade = smoothstep(0.0, 0.3, r) * smoothstep(2.0, 0.5, r);

    // Audio reactive color
    float hue = fract(a / TAU + time * HUE_SHIFT_SPEED + audio.bass * AUDIO_HUE_SHIFT);
    float sat = 0.8 + audio.mid * AUDIO_SATURATION * 0.5;
    float val = spiral * fade * 0.15 * (1.0 + audio.total * AUDIO_BRIGHTNESS);

    return hsv2rgb(vec3(hue, sat, val));
}

// ============================================================================
// CENTER GLOW
// ============================================================================

vec3 centerGlow(vec2 uv, float time, Audio audio) {
    float r = length(uv);
    float glow = 0.15 / (r + 0.15);
    glow = pow(glow, 2.0) * 0.3;

    // Audio reactive glow color
    float hue = fract(time * HUE_SHIFT_SPEED * 2.0 + audio.bass * 0.5);
    vec3 glowCol = hsv2rgb(vec3(hue, 0.5 + audio.mid * 0.3, 1.0));

    return glowCol * glow * (1.0 + audio.total * AUDIO_BRIGHTNESS);
}

// ============================================================================
// MAIN
// ============================================================================

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    Audio audio = getAudio();
    float time = iTime;

    vec3 col = vec3(0.0);

    // Layer 1: Subtle spiral background
    col += spiralBackground(uv, time, audio);

    // Layer 2: SDF particles
    vec4 particles = vortexParticles(uv, time, audio);
    col += particles.rgb;

    // Layer 3: Center glow
    col += centerGlow(uv, time, audio);

    // Subtle vignette
    float vig = 1.0 - length(uv) * 0.15;
    col *= vig;

    // Tone mapping
    col = col / (1.0 + col * 0.3);
    col = pow(col, vec3(0.95));

    fragColor = vec4(col, 1.0);
}
