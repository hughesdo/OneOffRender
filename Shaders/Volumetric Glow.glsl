#version 330 core

/*
    Volumetric Glow - Audio-Reactive Volumetric Effects
    Converted for OneOffRender system

    Original code by Xor
    \Volumetric: Glow
    https://x.com/XorDev/status/1959077729082462559
    https://t.co/Mikpt1ZVHw

    Mosaic
    https://x.com/XorDev/status/1933267977136443558

    Made Audio Reactive and tweaked to perfection by PAEz ;P
    OH and Grok, good Grok.
*/

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

// Background Shader Defines (Audio-Reactive)
#define P_SCALE 3.0
#define CENTER_SCALE 2.0
#define ASPECT_DIV vec2(1.0, 1.0) // Use .x for /r.x, .y for /r.y; here default to /r.y
#define TIME_OFFSET vec2(0.0, 0.0) // Offset added to time before multiplying cos
#define RES_OFFSET vec2(0.0, 0.0) // Offset added to resolution in cos arg
#define CEIL_OFFSET 0.0 // Offset inside ceil
#define P_MUL 2.0 // Multiplier for p in v (p + p = 2.0 * p)
#define COS_ARG_OFFSET vec2(0.0, 0.0) // Additional offset in cos arg for v
#define SWIZZLE .yx // Swizzle for cos result in v
#define P_X_COEFF 0.6 // Coefficient for p.x in inner cos
#define V_Y_SIN_COEFF 0.3 // Coefficient for sin(v.y) in inner cos
#define PHASE_R 0.0
#define PHASE_G 1.0
#define PHASE_B 2.0
#define PHASE_A 3.0
#define COS_ADD 1.0 // Added to cos result
#define OUTER_MUL 0.1 // Multiplier for the entire expression before tanh
#define LEN_BASE 0.9 // Base added to sin(v) in length
#define LEN_OFFSET vec2(0.0, 0.0) // Offset added to sin(v) in length
#define SIN_V_OFFSET vec2(0.0, 0.0) // Offset inside sin(v)

// Audio reactivity defines for background
#define TREBLE_FREQ_START_BIN 510.0 // The first bin to include in the sum for treble
#define TREBLE_FREQ_END_BIN 511.0 // The last bin to include in the sum for treble
#define BASS_FREQ_START_BIN 2.0 // The first bin to include in the sum for bass
#define BASS_FREQ_END_BIN 5.0 // The last bin to include in the sum for bass
#define INTENSITY_FREQ_START_BIN 0.0 // The first bin to include in the sum for overall intensity
#define INTENSITY_FREQ_END_BIN 511.0 // The last bin to include in the sum for overall intensity
#define WAV_BLEED 0.2 // Setting this above 0 will make it use some of the wave value
#define FFT_SIZE 512.0 // The width of the FFT texture
#define MIN_SIN_FREQ 5.0 // Minimum value for SIN_FREQ
#define MAX_SIN_FREQ 17.0 // Maximum value for SIN_FREQ

// Movement defines for background
#define MOVE_AMPLITUDE_X 0.5 // Amplitude of horizontal movement
#define MOVE_AMPLITUDE_Y 0.5 // Amplitude of vertical movement
#define MOVE_SPEED 1.0 // Speed of time-based movement
#define AUDIO_MOVE_SCALE 0.5 // How much audio intensity affects movement

// Volumetric Glow Shader Defines (Non-Bass Reactive)
#define BRIGHTNESS 0.002 // Output brightness
#define STEPS 50.0 // Raymarching steps
#define FOV 1.0 // Camera y Field Of View ratio
#define ROTATION_SPEED 0.5 // Speed of rotation for the volumetric effect
#define CAMERA_Z -8.0 // Camera Z position
#define COLOR_OFFSET 1.2 // Offset for sine wave coloring
#define TONEMAP_SCALE 0.002 // Scale for tanh tonemapping

// Start settings for bass (bass = 0)
#define START_DENSITY 5.0
#define START_VOLUME_SCALE 33.0
#define START_VOLUME_THRESHOLD 10.0
#define START_VOLUME_SPHERE_RADIUS 4.0
#define START_GLOW_REACH 0.8
#define START_GLOW_DENSITY_SCALE 1.4

// End settings for bass (bass = 1)
#define END_DENSITY 4.0
#define END_VOLUME_SCALE 12.0
#define END_VOLUME_THRESHOLD 1.0
#define END_VOLUME_SPHERE_RADIUS 6.0
#define END_GLOW_REACH 1.5
#define END_GLOW_DENSITY_SCALE 2.0

// 3D rotation function (from XorDev's post)
vec3 rotate(vec3 p, vec3 a) {
    return a * dot(p, a) + cross(p, a);
}

// Volume function for volumetric glow with extended reach
float volume(vec3 p, float density, float volume_scale, float volume_threshold, float volume_sphere_radius, float glow_density_scale) {
    float l = length(p);
    vec3 v = cos(abs(p) * volume_scale / max(volume_threshold, l) + iTime);
    float vol_density = length(vec4(max(v, v.yzx) - 0.9, l - volume_sphere_radius)) / (density * glow_density_scale);
    return vol_density;
}

// Background shader function (audio-reactive)
vec4 backgroundShader(vec2 fragCoord, float t, vec2 r, float treble, float bass, float intensity) {
    // Compute dynamic SIN_FREQ using smoothstep (using treble)
    float SIN_FREQ = smoothstep(0.0, 1.0, treble) * (MAX_SIN_FREQ - MIN_SIN_FREQ) + MIN_SIN_FREQ;
    
    // Add movement to p with time-based and audio-reactive components (using treble)
    vec2 move = vec2(
        MOVE_AMPLITUDE_X * sin(t * MOVE_SPEED) + AUDIO_MOVE_SCALE * treble,
        MOVE_AMPLITUDE_Y * cos(t * MOVE_SPEED) + AUDIO_MOVE_SCALE * treble
    );
    vec2 p = P_SCALE * (fragCoord * CENTER_SCALE - r) / (r * ASPECT_DIV).y + move;
    
    vec2 v = P_MUL * p + (t + TIME_OFFSET + r) * cos(RES_OFFSET + r + ceil(CEIL_OFFSET + p + sin(p * SIN_FREQ + COS_ARG_OFFSET))) SWIZZLE;
    vec4 phase = vec4(PHASE_R, PHASE_G, PHASE_B, PHASE_A);
    return tanh(OUTER_MUL * (cos(P_X_COEFF * p.x + V_Y_SIN_COEFF * sin(v.y) + phase) + COS_ADD) / length(LEN_BASE + sin(v + SIN_V_OFFSET) + LEN_OFFSET));
}

// Main image function
void main() {
    // Screen coordinates to UV with Y-flip for correct orientation
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 r = iResolution.xy;
    float t = iTime;
    
    // Simplified audio processing for OneOffRender compatibility
    // Sample treble (high frequencies) - simplified approach
    float treble = texture(iChannel0, vec2(0.9, 0.0)).r; // High frequencies

    // Sample bass (low frequencies) - simplified approach
    float bass = texture(iChannel0, vec2(0.1, 0.0)).r; // Low frequencies

    // Sample overall intensity (mid frequencies) - simplified approach
    float intensity = texture(iChannel0, vec2(0.5, 0.0)).r; // Mid frequencies

    // Apply smoothing and clamping for stability
    treble = smoothstep(0.0, 1.0, treble) * 0.8;
    bass = smoothstep(0.0, 1.0, bass) * 0.6;
    intensity = smoothstep(0.0, 1.0, intensity) * 0.7;
    
    // Render background shader (pass treble, bass, intensity - though only treble is used currently)
    vec4 background = backgroundShader(fragCoord, t, r, treble, bass, intensity);
    
    // Interpolate volumetric parameters based on bass (0 = start, 1 = end)
    float density = mix(START_DENSITY, END_DENSITY, bass);
    float volume_scale = mix(START_VOLUME_SCALE, END_VOLUME_SCALE, bass);
    float volume_threshold = mix(START_VOLUME_THRESHOLD, END_VOLUME_THRESHOLD, bass);
    float volume_sphere_radius = mix(START_VOLUME_SPHERE_RADIUS, END_VOLUME_SPHERE_RADIUS, bass);
    float glow_reach = mix(START_GLOW_REACH, END_GLOW_REACH, bass);
    float glow_density_scale = mix(START_GLOW_DENSITY_SCALE, END_GLOW_DENSITY_SCALE, bass);
    
    // Center coordinates for volumetric effect
    vec2 center = 2.0 * fragCoord - r;
    
    // Rotation axis for volumetric effect
    vec3 axis = normalize(cos(vec3(ROTATION_SPEED * t + vec3(0, 2, 4))));
    // Rotate ray direction for volumetric effect
    vec3 dir = rotate(normalize(vec3(center, FOV * r.y)), axis);
    
    // Camera position for volumetric effect
    vec3 cam = rotate(vec3(0, 0, CAMERA_Z), axis);
    // Raymarch sample point for volumetric effect
    vec3 pos = cam;
    
    // Output color for volumetric effect
    vec3 col = vec3(0.0);
    
    // Glow raymarch loop for volumetric effect with extended reach
    for (float i = 0.0; i < STEPS; i++) {
        float vol = volume(pos, density, volume_scale, volume_threshold, volume_sphere_radius, glow_density_scale);
        pos += dir * vol * glow_reach; // Extend the reach by multiplying the step distance
        col += (cos(pos.z / (1.0 + vol) + t + vec3(6, 1, 2)) + COLOR_OFFSET) / vol;
    }
    
    // Tanh tonemapping for volumetric effect
    col = tanh(TONEMAP_SCALE * col);
    
    // Combine volumetric effect with background
    fragColor = vec4(col, 1.0) + background;
}