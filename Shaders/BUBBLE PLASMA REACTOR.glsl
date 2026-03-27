#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;
uniform vec4 iMouse;

out vec4 fragColor;

/*
 * BUBBLE PLASMA REACTOR
 * =====================
 * A fusion reactor core with bubbling plasma and iridescent membranes.
 * Inspired by: Bubble Plasma Giant, Bubble Heaven, MilkDrop plasma
 *
 * Concept: A pulsating energy core surrounded by floating bubble membranes
 * with thin-film interference coloring. Energy tendrils connect bubbles.
 * Deep, organic, and alive with the music.
 */

// ============================================================================
// TWEAKING VARIABLES - Adjust these to customize the experience
// ============================================================================

// MASTER CONTROLS
#define AUDIO_REACTIVE 1.0      // 0.0 = static, 1.0 = audio reactive
#define AUDIO_SENSITIVITY 1.3   // Overall audio response multiplier

// REACTOR CORE
#define CORE_SIZE 0.3           // Central core radius
#define CORE_PULSE_SPEED 2.0    // Base pulse animation speed
#define CORE_INTENSITY 1.5      // Core brightness multiplier

// BUBBLES
#define NUM_BUBBLES 12          // Number of floating bubbles (5-20)
#define BUBBLE_SIZE_MIN 0.08    // Minimum bubble radius
#define BUBBLE_SIZE_MAX 0.2     // Maximum bubble radius
#define BUBBLE_ORBIT_RADIUS 0.7 // How far bubbles orbit from center
#define BUBBLE_SPEED 0.3        // Orbital speed

// PLASMA
#define PLASMA_LAYERS 4         // Number of plasma layers (2-6)
#define PLASMA_SCALE 3.0        // Plasma pattern scale
#define PLASMA_SPEED 1.0        // Plasma animation speed

// TENDRILS
#define TENDRIL_COUNT 6         // Energy tendril count
#define TENDRIL_WIDTH 0.03      // Tendril thickness
#define TENDRIL_INTENSITY 0.8   // Tendril brightness

// AUDIO RESPONSE AMOUNTS
#define BASS_CORE_PULSE 0.5     // Bass pulses the core
#define BASS_BUBBLE_PUSH 0.3    // Bass pushes bubbles outward
#define MID_PLASMA_SPEED 1.0    // Mids speed up plasma
#define MID_COLOR_TEMP 0.3      // Mids shift color temperature
#define TREB_TENDRIL_ENERGY 1.5 // Treble energizes tendrils
#define TREB_IRIDESCENCE 0.5    // Treble intensifies bubble iridescence

// EFFECTS TOGGLES (1.0 = on, 0.0 = off)
#define ENABLE_CORE 1.0         // Central reactor core
#define ENABLE_BUBBLES 1.0      // Floating bubble membranes
#define ENABLE_PLASMA 1.0       // Background plasma field
#define ENABLE_TENDRILS 1.0     // Energy connections
#define ENABLE_IRIDESCENCE 1.0  // Thin-film bubble coloring
#define ENABLE_GLOW 1.0         // Post-process glow
#define ENABLE_PARTICLES 1.0    // Floating energy particles

// EFFECT AMOUNTS
#define IRIDESCENCE_STRENGTH 1.0   // How vivid the rainbow effect is
#define GLOW_RADIUS 0.02           // Glow spread
#define PARTICLE_COUNT 50.0        // Number of floating particles

// COLORS
#define CORE_COLOR vec3(1.0, 0.6, 0.2)      // Hot orange core
#define PLASMA_COLOR_1 vec3(0.8, 0.2, 1.0)  // Purple plasma
#define PLASMA_COLOR_2 vec3(0.2, 0.5, 1.0)  // Blue plasma
#define TENDRIL_COLOR vec3(0.5, 0.8, 1.0)   // Cyan tendrils

// ============================================================================
// AUDIO ANALYSIS
// ============================================================================

struct AudioData {
    float bass;
    float mid;
    float treb;
    float bassSmooth;
    float midSmooth;
    float trebSmooth;
    float total;
    float waveform[8]; // Sample waveform for tendril modulation
};

AudioData getAudio() {
    AudioData a;

    a.bass = texture(iChannel0, vec2(0.05, 0.0)).x;
    a.mid = texture(iChannel0, vec2(0.2, 0.0)).x;
    a.treb = texture(iChannel0, vec2(0.6, 0.0)).x;

    a.bassSmooth = texture(iChannel0, vec2(0.03, 0.0)).x;
    a.midSmooth = texture(iChannel0, vec2(0.18, 0.0)).x;
    a.trebSmooth = texture(iChannel0, vec2(0.55, 0.0)).x;

    // Sample waveform for tendril animation
    for (int i = 0; i < 8; i++) {
        a.waveform[i] = texture(iChannel0, vec2(float(i) / 8.0, 0.0)).x;
    }

    a.total = (a.bass + a.mid + a.treb) / 3.0;

    float sens = AUDIO_SENSITIVITY * AUDIO_REACTIVE;
    a.bass *= sens; a.mid *= sens; a.treb *= sens;
    a.bassSmooth *= sens; a.midSmooth *= sens; a.trebSmooth *= sens;
    a.total *= sens;

    return a;
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

#define PI 3.14159265359
#define TAU 6.28318530718

mat2 rot2(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

vec3 hash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

// ============================================================================
// IRIDESCENCE (Thin-Film Interference)
// ============================================================================

vec3 iridescence(float thickness, float angle, float intensity) {
    if (ENABLE_IRIDESCENCE < 0.5) return vec3(1.0);

    // Optical path difference
    float delta = thickness * cos(angle) * 1000.0;

    // Interference for RGB wavelengths
    vec3 color = vec3(
        0.5 + 0.5 * cos(delta / 650.0 * TAU + 0.0),
        0.5 + 0.5 * cos(delta / 510.0 * TAU + 2.0),
        0.5 + 0.5 * cos(delta / 475.0 * TAU + 4.0)
    );

    return mix(vec3(1.0), color, intensity * IRIDESCENCE_STRENGTH);
}

// ============================================================================
// PLASMA FIELD
// ============================================================================

float plasma(vec2 p, float t, AudioData audio) {
    if (ENABLE_PLASMA < 0.5) return 0.0;

    float speed = PLASMA_SPEED * (1.0 + audio.midSmooth * MID_PLASMA_SPEED);

    float v = 0.0;

    // Multiple sine waves at different frequencies
    for (int i = 0; i < PLASMA_LAYERS; i++) {
        float fi = float(i);
        float freq = 1.0 + fi * 0.5;
        float phase = fi * 0.7;

        v += sin(p.x * PLASMA_SCALE * freq + t * speed + phase);
        v += sin(p.y * PLASMA_SCALE * freq * 0.7 + t * speed * 0.8 + phase);
        v += sin((p.x + p.y) * PLASMA_SCALE * freq * 0.5 + t * speed * 0.6);
        v += sin(length(p) * PLASMA_SCALE * freq + t * speed * 1.2);
    }

    v /= float(PLASMA_LAYERS) * 4.0;

    return v * 0.5 + 0.5;
}

vec3 plasmaColor(float v, AudioData audio) {
    // Temperature shift with mids
    float temp = 0.5 + audio.midSmooth * MID_COLOR_TEMP;

    vec3 col = mix(PLASMA_COLOR_1, PLASMA_COLOR_2, v);
    col = mix(col, CORE_COLOR, (1.0 - v) * temp * 0.3);

    return col * v * 0.5;
}

// ============================================================================
// REACTOR CORE
// ============================================================================

vec3 renderCore(vec2 uv, float t, AudioData audio) {
    if (ENABLE_CORE < 0.5) return vec3(0.0);

    float d = length(uv);

    // Pulsing size
    float pulse = sin(t * CORE_PULSE_SPEED) * 0.5 + 0.5;
    pulse = 0.7 + pulse * 0.3;
    pulse += audio.bassSmooth * BASS_CORE_PULSE;

    float coreSize = CORE_SIZE * pulse;

    // Core glow
    float core = 1.0 - smoothstep(0.0, coreSize, d);
    float glow = exp(-d * 3.0 / coreSize);

    // Animated surface detail
    float angle = atan(uv.y, uv.x);
    float surface = sin(angle * 8.0 + t * 3.0) * 0.5 + 0.5;
    surface *= sin(angle * 5.0 - t * 2.0) * 0.5 + 0.5;

    vec3 col = CORE_COLOR * (core + glow * 0.5);
    col += CORE_COLOR * surface * core * 0.5;

    // Hot white center
    col += vec3(1.0) * pow(core, 3.0);

    return col * CORE_INTENSITY;
}

// ============================================================================
// BUBBLES
// ============================================================================

struct Bubble {
    vec2 pos;
    float radius;
    float phase;
};

Bubble getBubble(int index, float t, AudioData audio) {
    Bubble b;

    float fi = float(index);
    vec3 h = hash31(fi);

    // Orbital position
    float orbitSpeed = BUBBLE_SPEED * (0.5 + h.x);
    float orbitAngle = fi * TAU / float(NUM_BUBBLES) + t * orbitSpeed;

    // Audio pushes bubbles outward
    float orbitRadius = BUBBLE_ORBIT_RADIUS * (1.0 + audio.bassSmooth * BASS_BUBBLE_PUSH);
    orbitRadius *= 0.7 + h.y * 0.6;

    // Slight vertical oscillation
    float vertOffset = sin(t * 0.5 + fi) * 0.1;

    b.pos = vec2(
        cos(orbitAngle) * orbitRadius,
        sin(orbitAngle) * orbitRadius + vertOffset
    );

    // Size varies
    b.radius = mix(BUBBLE_SIZE_MIN, BUBBLE_SIZE_MAX, h.z);
    b.phase = h.x * TAU;

    return b;
}

vec3 renderBubble(vec2 uv, Bubble b, float t, AudioData audio) {
    vec2 p = uv - b.pos;
    float d = length(p);

    if (d > b.radius * 1.5) return vec3(0.0);

    // Bubble membrane
    float edge = abs(d - b.radius);
    float membrane = smoothstep(0.015, 0.0, edge);

    // Interior fade
    float interior = smoothstep(b.radius, b.radius * 0.3, d);

    // Viewing angle for iridescence
    float angle = acos(clamp(1.0 - d / b.radius, 0.0, 1.0));

    // Film thickness varies across bubble
    float thickness = 0.5 + 0.5 * sin(atan(p.y, p.x) * 3.0 + t + b.phase);
    thickness *= 1.0 + audio.trebSmooth * TREB_IRIDESCENCE;

    vec3 iriCol = iridescence(thickness, angle, 1.0);

    // Specular highlight
    vec2 lightDir = normalize(vec2(1.0, 1.0));
    float spec = max(dot(normalize(p), lightDir), 0.0);
    spec = pow(spec, 16.0);

    vec3 col = iriCol * membrane * 0.8;
    col += vec3(1.0) * spec * membrane;
    col += iriCol * interior * 0.1;

    return col;
}

vec3 renderAllBubbles(vec2 uv, float t, AudioData audio) {
    if (ENABLE_BUBBLES < 0.5) return vec3(0.0);

    vec3 col = vec3(0.0);

    for (int i = 0; i < NUM_BUBBLES; i++) {
        Bubble b = getBubble(i, t, audio);
        col += renderBubble(uv, b, t, audio);
    }

    return col;
}

// ============================================================================
// ENERGY TENDRILS
// ============================================================================

float tendril(vec2 uv, vec2 start, vec2 end, float t, int index, AudioData audio) {
    vec2 pa = uv - start;
    vec2 ba = end - start;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    vec2 closest = start + ba * h;

    // Add wave displacement
    float wave = sin(h * 20.0 + t * 5.0 + float(index)) * 0.02;
    wave *= audio.trebSmooth * TREB_TENDRIL_ENERGY;

    // Use waveform data for organic movement
    int waveIdx = int(h * 7.99);
    wave += (audio.waveform[waveIdx] - 0.5) * 0.03;

    vec2 perpendicular = normalize(vec2(-ba.y, ba.x));
    closest += perpendicular * wave;

    float d = length(uv - closest);

    // Tendril intensity fades at ends
    float fade = smoothstep(0.0, 0.2, h) * smoothstep(1.0, 0.8, h);

    return smoothstep(TENDRIL_WIDTH, 0.0, d) * fade;
}

vec3 renderTendrils(vec2 uv, float t, AudioData audio) {
    if (ENABLE_TENDRILS < 0.5) return vec3(0.0);

    vec3 col = vec3(0.0);

    // Connect core to bubbles
    for (int i = 0; i < TENDRIL_COUNT; i++) {
        if (i >= NUM_BUBBLES) break;

        Bubble b = getBubble(i, t, audio);

        // Tendril from core to bubble
        float ten = tendril(uv, vec2(0.0), b.pos * 0.8, t, i, audio);

        vec3 tenCol = TENDRIL_COLOR * ten * TENDRIL_INTENSITY;
        tenCol *= 1.0 + audio.trebSmooth;

        col += tenCol;
    }

    return col;
}

// ============================================================================
// FLOATING PARTICLES
// ============================================================================

vec3 renderParticles(vec2 uv, float t, AudioData audio) {
    if (ENABLE_PARTICLES < 0.5) return vec3(0.0);

    vec3 col = vec3(0.0);

    for (float i = 0.0; i < PARTICLE_COUNT; i++) {
        vec3 h = hash31(i + 100.0);

        // Particle position - orbit and drift
        float angle = h.x * TAU + t * (0.1 + h.y * 0.2);
        float radius = 0.3 + h.z * 0.8;
        radius *= 1.0 + audio.bassSmooth * 0.3;

        vec2 pos = vec2(cos(angle), sin(angle)) * radius;
        pos.y += sin(t * 0.5 + i) * 0.1;

        float d = length(uv - pos);

        // Small glowing point
        float particle = smoothstep(0.015, 0.0, d);
        particle *= 0.5 + 0.5 * sin(t * 3.0 + i);
        particle *= 0.3 + audio.trebSmooth * 0.7;

        col += TENDRIL_COLOR * particle * 0.5;
    }

    return col;
}

// ============================================================================
// MAIN RENDER
// ============================================================================

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    AudioData audio = getAudio();
    float t = iTime;

    vec3 col = vec3(0.0);

    // Background plasma
    float p = plasma(uv, t, audio);
    col += plasmaColor(p, audio);

    // Energy tendrils (behind bubbles)
    col += renderTendrils(uv, t, audio);

    // Floating particles
    col += renderParticles(uv, t, audio);

    // Bubbles
    col += renderAllBubbles(uv, t, audio);

    // Reactor core (on top)
    col += renderCore(uv, t, audio);

    // Global glow pass
    if (ENABLE_GLOW > 0.5) {
        vec3 glow = vec3(0.0);
        for (float a = 0.0; a < TAU; a += TAU / 8.0) {
            vec2 offset = vec2(cos(a), sin(a)) * GLOW_RADIUS;
            glow += renderCore(uv + offset, t, audio) * 0.125;
        }
        col += glow * 0.5;
    }

    // Vignette
    float vig = 1.0 - length(uv) * 0.3;
    col *= vig;

    // Tone mapping
    col = 1.0 - exp(-col * 1.5); // Exponential
    col = pow(col, vec3(0.9));   // Gamma

    fragColor = vec4(col, 1.0);
}
