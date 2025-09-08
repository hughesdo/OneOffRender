#version 330 core

// Audio-Reactive Cosmic Energy Streams - Converted for OneOffRender
// Recreates flowing energy tendrils with dynamic lighting and audio-reactive particles

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

// ====== TWEAKABLE VARIABLES ======
#define NUM_STREAMS 8             // Number of energy streams (4-16 recommended)

// Stream Properties
#define STREAM_BASE_RADIUS 0.3     // Base orbital radius of streams (0.2-0.5)
#define STREAM_RADIUS_VAR 0.2      // Radius variation amplitude (0.1-0.3)
#define STREAM_FLOW_SPEED 2.0      // Speed of stream flow (1.0-4.0)
#define STREAM_THICKNESS 20.0      // Stream thickness multiplier (15.0-30.0)
#define STREAM_BRIGHTNESS 0.01      // Base stream brightness (0.1-0.6)
#define STREAM_PULSE_AMP 0.2       // Stream pulsing amplitude (0.1-0.4)

// Movement & Animation
#define FLOW_COMPLEXITY_X 8.0      // Horizontal flow complexity (4.0-12.0)
#define FLOW_COMPLEXITY_Y 6.0      // Vertical flow complexity (4.0-10.0)
#define SECONDARY_FLOW_X 12.0      // Secondary horizontal movement (8.0-16.0)
#define SECONDARY_FLOW_Y 10.0      // Secondary vertical movement (6.0-14.0)
#define CAMERA_SHAKE_X 0.1         // Camera horizontal shake (0.0-0.2)
#define CAMERA_SHAKE_Y 0.05        // Camera vertical shake (0.0-0.1)
#define CAMERA_ZOOM 1.2            // Camera zoom level (1.0-2.0)

// Explosion Effect
#define ENABLE_EXPLOSION false      // Enable/disable radiating circles (true/false)
#define EXPLOSION_FREQUENCY 12.0   // Explosion ring frequency (8.0-16.0)
#define EXPLOSION_SPEED 8.0        // Explosion wave speed (4.0-12.0)
#define EXPLOSION_DECAY 2.0        // Explosion decay rate (1.0-4.0)
#define EXPLOSION_INTENSITY 0.6    // Explosion brightness (0.3-1.0)

// Color Properties
#define COLOR_INTENSITY_POWER 0.7  // Color intensity curve (0.5-1.0)
#define CORE_BRIGHTNESS 0.3        // Central core brightness (0.2-0.6)
#define CORE_SIZE 2.0              // Central core size (1.0-4.0)
#define STREAM_HIGHLIGHT 0.8       // Stream highlight intensity (0.5-1.2)

// Audio-Reactive Particles & Effects
#define PARTICLE_DENSITY 20.0      // Particle grid density (15.0-30.0)
#define PARTICLE_SIZE 80.0         // Particle size multiplier (60.0-100.0)
#define PARTICLE_THRESHOLD 0.95    // Particle spawn threshold (0.9-0.99)
#define PARTICLE_BRIGHTNESS 2.0    // Particle brightness multiplier (1.0-3.0)
#define SPARKLE_SPEED 8.0          // Particle twinkling speed (4.0-12.0)

// Audio Reactivity Settings
#define AUDIO_REACTIVITY 2.0       // Overall audio sensitivity (1.0-4.0)
#define BASS_FREQUENCY 0.1         // Bass frequency simulation (0.05-0.2)
#define MID_FREQUENCY 0.3          // Mid frequency simulation (0.2-0.5)
#define HIGH_FREQUENCY 0.8         // High frequency simulation (0.5-1.2)
#define AUDIO_SMOOTH 0.1           // Audio smoothing factor (0.05-0.2)
#define PARTICLE_AUDIO_SCALE 3.0   // How much audio affects particle size (1.0-5.0)
#define PARTICLE_AUDIO_THRESH 1.5  // Audio threshold multiplier for particles (1.0-3.0)

// Noise & Texture
#define NOISE_SCALE 4.0            // Noise texture scale (2.0-8.0)
#define NOISE_SPEED 0.5            // Noise animation speed (0.2-1.0)
#define NOISE_INTENSITY 0.3        // Noise contribution (0.1-0.5)
#define FRACTAL_OCTAVES 5          // Noise detail levels (3-6)

// Post-Processing
#define GAMMA_CORRECTION 0.8       // Gamma correction (0.6-1.0)
#define BRIGHTNESS_BOOST 1.2       // Overall brightness (0.8-1.5)
#define GLOW_INTENSITY 0.5         // Glow effect strength (0.2-0.8)

// Background
#define STAR_DENSITY 100.0         // Star field density (50.0-200.0)
#define STAR_THRESHOLD 0.98        // Star spawn threshold (0.95-0.99)
#define STAR_BRIGHTNESS 0.5        // Star brightness (0.3-0.8)

#define PI 3.14159265359

// ====== SHADER CODE ======

// Hash function for noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D noise function
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

// Fractal noise
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for(int i = 0; i < FRACTAL_OCTAVES; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    
    return value;
}

// Real audio analysis from OneOffRender system
vec3 getAudioLevels(float time) {
    // Sample audio from Channel0 - real audio data
    float bass = texture(iChannel0, vec2(0.02, 0.0)).x;      // Low frequencies
    float mid = texture(iChannel0, vec2(0.1, 0.0)).x;       // Mid frequencies
    float high = texture(iChannel0, vec2(0.3, 0.0)).x;      // High frequencies

    // Apply audio reactivity scaling
    return vec3(bass, mid, high) * AUDIO_REACTIVITY;
}

// Generate flowing stream path
vec2 streamPath(float t, float streamId, float time) {
    float angle = streamId * PI * 2.0 / float(NUM_STREAMS);
    float radius = STREAM_BASE_RADIUS + STREAM_RADIUS_VAR * sin(time * 0.5 + streamId);
    
    vec2 center = vec2(cos(angle) * radius, sin(angle) * radius);
    
    // Add flowing motion
    float flow = time * STREAM_FLOW_SPEED + streamId * 10.0;
    vec2 offset = vec2(
        cos(flow + t * FLOW_COMPLEXITY_X) * 0.1,
        sin(flow * 1.3 + t * FLOW_COMPLEXITY_Y) * 0.1
    );
    
    return center + offset + vec2(
        cos(t * SECONDARY_FLOW_X + streamId * 5.0) * 0.05,
        sin(t * SECONDARY_FLOW_Y + streamId * 3.0) * 0.05
    );
}

// Distance to stream
float distToStream(vec2 pos, float streamId, float time) {
    float minDist = 10.0;
    
    for(float t = 0.0; t < 1.0; t += 0.02) {
        vec2 streamPos = streamPath(t, streamId, time);
        float dist = distance(pos, streamPos);
        minDist = min(minDist, dist);
    }
    
    return minDist;
}

// Generate energy field with explosion effect
float energyField(vec2 pos, float time) {
    float field = 0.0;
    
    // Explosion effect - expanding rings from center (optional)
    float explosion = 0.0;
    if(ENABLE_EXPLOSION) {
        float centerDist = length(pos);
        float explosionWave = sin(centerDist * EXPLOSION_FREQUENCY - time * EXPLOSION_SPEED) * exp(-centerDist * EXPLOSION_DECAY);
        explosion = max(0.0, explosionWave) * EXPLOSION_INTENSITY;
    }
    
    for(int i = 0; i < NUM_STREAMS; i++) {
        float streamId = float(i);
        float dist = distToStream(pos, streamId, time);
        
        // Stream intensity with pulsing
        float pulse = sin(time * 4.0 + streamId * 2.0) * 0.5 + 0.5;
        float intensity = exp(-dist * STREAM_THICKNESS) * (STREAM_BRIGHTNESS + STREAM_PULSE_AMP * pulse);
        
        field += intensity;
    }
    
    return field + explosion;
}

// Color mapping for energy streams - richer, more saturated colors
vec3 energyColor(float intensity, float time, vec2 pos) {
    // More saturated base colors
    vec3 color1 = vec3(1.0, 0.6, 0.0);  // Deep orange-gold
    vec3 color2 = vec3(0.0, 0.8, 0.6);  // Teal
    vec3 color3 = vec3(0.9, 0.1, 0.7);  // Hot magenta
    vec3 color4 = vec3(0.6, 0.1, 1.0);  // Deep purple
    vec3 color5 = vec3(0.2, 1.0, 0.3);  // Electric green
    
    // Mix colors based on position and time
    float colorMix1 = sin(time * 2.0 + pos.x * 8.0) * 0.5 + 0.5;
    float colorMix2 = cos(time * 1.5 + pos.y * 6.0) * 0.5 + 0.5;
    float colorMix3 = sin(time * 3.0 + length(pos) * 10.0) * 0.5 + 0.5;
    
    vec3 mixedColor = mix(
        mix(color1, color2, colorMix1),
        mix(color3, mix(color4, color5, colorMix3), colorMix2),
        sin(time * 0.8 + pos.x * pos.y * 20.0) * 0.5 + 0.5
    );
    
    // Apply intensity more carefully to preserve color richness
    return mixedColor * pow(intensity, COLOR_INTENSITY_POWER);
}

// Audio-reactive particle sparkles
float audioParticles(vec2 pos, float time, vec3 audioLevels) {
    vec2 gridPos = pos * PARTICLE_DENSITY;
    vec2 cellPos = fract(gridPos);
    vec2 cellId = floor(gridPos);
    
    float h = hash(cellId);
    
    // Determine which frequency band affects this particle based on its hash
    float freqSelect = fract(h * 3.0);
    float audioLevel;
    vec3 particleColor;
    
    if(freqSelect < 0.33) {
        // Bass-reactive particles (larger, slower)
        audioLevel = audioLevels.x;
        particleColor = vec3(1.0, 0.3, 0.1); // Red-orange for bass
    } else if(freqSelect < 0.66) {
        // Mid-reactive particles (medium)
        audioLevel = audioLevels.y;
        particleColor = vec3(0.1, 0.8, 1.0); // Cyan for mids
    } else {
        // High-reactive particles (smaller, faster)
        audioLevel = audioLevels.z;
        particleColor = vec3(1.0, 1.0, 0.2); // Yellow for highs
    }
    
    // Audio-reactive threshold - particles appear more with higher audio levels
    float audioThreshold = PARTICLE_THRESHOLD - (audioLevel * 0.15);
    if(h < audioThreshold) return 0.0;
    
    // Animated particle position within cell - affected by audio
    float audioMotion = audioLevel * 0.4;
    vec2 particlePos = vec2(
        0.5 + (0.3 + audioMotion) * sin(time * (3.0 + audioLevel * 2.0) + h * 100.0),
        0.5 + (0.3 + audioMotion) * cos(time * (2.5 + audioLevel * 1.5) + h * 150.0)
    );
    
    float dist = distance(cellPos, particlePos);
    
    // Audio-reactive particle size
    float audioSize = PARTICLE_SIZE * (1.0 + audioLevel * PARTICLE_AUDIO_SCALE);
    float sparkle = exp(-dist * audioSize);
    
    // Audio-reactive twinkling with different speeds per frequency band
    float sparkleSpeed = SPARKLE_SPEED;
    if(freqSelect < 0.33) sparkleSpeed *= 0.7;      // Slower for bass
    else if(freqSelect >= 0.66) sparkleSpeed *= 1.5; // Faster for highs
    
    float twinkle = sin(time * sparkleSpeed + h * 200.0 + audioLevel * 10.0) * 0.5 + 0.5;
    
    // Boost twinkle intensity with audio level
    twinkle = pow(twinkle, 1.0 / (1.0 + audioLevel * 0.5));
    
    return sparkle * twinkle * (1.0 + audioLevel * PARTICLE_AUDIO_THRESH);
}

void main() {
    // Screen coordinates to UV with Y-flip for correct orientation
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float time = iTime;
    
    // Get simulated audio levels
    vec3 audioLevels = getAudioLevels(time);
    
    // Add camera movement - slightly audio-reactive
    uv *= CAMERA_ZOOM * (1.0 + audioLevels.x * 0.1);
    uv.x += sin(time * 0.3) * CAMERA_SHAKE_X * (1.0 + audioLevels.y * 0.5);
    uv.y += cos(time * 0.4) * CAMERA_SHAKE_Y * (1.0 + audioLevels.z * 0.5);
    
    // Generate energy field
    float energy = energyField(uv, time);
    
    // Add noise for texture
    float noiseVal = fbm(uv * NOISE_SCALE + time * NOISE_SPEED) * NOISE_INTENSITY;
    energy += noiseVal;
    
    // Get base color from energy
    vec3 color = energyColor(energy, time, uv);
    
    // Add central bright core - slightly audio-reactive
    float centerDist = length(uv);
    float core = exp(-centerDist * CORE_SIZE) * CORE_BRIGHTNESS * (1.0 + audioLevels.x * 0.3);
    color += vec3(1.0, 0.9, 0.7) * core;
    
    // Add audio-reactive particle sparkles
    float sparkles = audioParticles(uv, time, audioLevels);
    
    // Color particles based on their audio reactivity
    vec3 sparkleColor = vec3(1.0, 1.0, 0.8);
    
    // Add slight color variation based on audio levels
    sparkleColor.r += audioLevels.x * 0.2;
    sparkleColor.g += audioLevels.y * 0.3;
    sparkleColor.b += audioLevels.z * 0.4;
    
    color += sparkleColor * sparkles * PARTICLE_BRIGHTNESS;
    
    // Add flowing streams highlights
    for(int i = 0; i < NUM_STREAMS; i++) {
        float streamId = float(i);
        float dist = distToStream(uv, streamId, time);
        float streamHighlight = exp(-dist * 25.0) * STREAM_HIGHLIGHT;
        
        // Stream-specific colors
        vec3 streamColor = energyColor(1.0, time + streamId, uv + vec2(streamId));
        color += streamColor * streamHighlight;
    }
    
    // Add glow and bloom effect - enhanced by audio
    float glow = energy * GLOW_INTENSITY * (1.0 + (audioLevels.x + audioLevels.y + audioLevels.z) * 0.1);
    color += color * glow * glow;
    
    // Dark space background with subtle stars
    vec3 background = vec3(0.02, 0.01, 0.03);
    float stars = noise(uv * STAR_DENSITY) > STAR_THRESHOLD ? STAR_BRIGHTNESS : 0.0;
    background += vec3(stars * 0.5);
    
    color += background;
    
    // Final color grading
    color = pow(color, vec3(GAMMA_CORRECTION)); // Gamma correction
    color *= BRIGHTNESS_BOOST; // Brightness boost
    
    fragColor = vec4(color, 1.0);
}