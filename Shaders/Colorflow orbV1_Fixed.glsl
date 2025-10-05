#version 330 core

// Colorflow orbV1 - OneOffRender Version
// Converted from Shadertoy format to OneOffRender
// Audio-reactive orb effects with enhanced glow and turbulence

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// === TWEAKING VARIABLES ===
#define AUDIO_SENSITIVITY 0.9
#define VOLUME_SCALE_AMOUNT 0.35
#define SPHERE_SIZE_SCALE 2.5
#define TURBULENCE_AUDIO_MIX 1.4
#define GLOW_AUDIO_MIX 0.9
#define AUDIO_SMOOTHING 0.45
#define BASE_SPHERE_SIZE 6.0
#define TURBULENCE_STRENGTH 0.2
#define COLOR_INTENSITY 8e7

// Audio-reactive functions
float getFFT(float freq) {
    return texture(iChannel0, vec2(freq, 0.0)).r;
}

float getFFTSmoothed(float freq) {
    float sum = 0.0;
    float samples = 5.0;
    for(float i = 0.0; i < samples; i++) {
        float offset = (i - samples * 0.5) * 0.02;
        sum += texture(iChannel0, vec2(clamp(freq + offset, 0.0, 1.0), 0.0)).r;
    }
    return sum / samples;
}

// Enhanced audio sampling for multiple frequency ranges
float getAudioLow() {
    return getFFTSmoothed(0.06);  // Bass frequencies
}

float getAudioMid() {
    return getFFTSmoothed(0.25);  // Mid frequencies
}

float getAudioHigh() {
    return getFFTSmoothed(0.5);   // High frequencies
}

void main() {
    // Fix coordinate system for OneOffRender
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 u = fragCoord;
    vec4 o = vec4(0.0);
    
    vec3 q, p = vec3(iResolution, 0.0);
    
    // === AUDIO SAMPLING ===
    // Sample multiple frequency ranges for smoother audio response
    float audioLow = getAudioLow();
    float audioMid = getAudioMid();
    float audioHigh = getAudioHigh();
    
    // Combine audio channels for overall volume
    float volume = (audioLow + audioMid + audioHigh) * 0.33 * AUDIO_SENSITIVITY;
    volume = smoothstep(0.0, 1.0, volume);
    
    // Enhanced beat detection - use raw volume for immediate response
    float beatVolume = pow(volume, 1.5); // Emphasize peaks for beat detection
    
    // Smooth audio response over time for some effects
    float smoothVolume = mix(volume, sin(iTime * 0.5) * 0.1 + 0.1, AUDIO_SMOOTHING);
    
    // Audio-reactive noise sampling
    float audioNoise = getFFT(fract(u.x * 0.001 + u.y * 0.001)) * 0.1;
    float d = 0.1 * audioNoise;
    float t = iTime;
    
    // Add subtle audio-based time modulation
    float audioTime = t + smoothVolume * 0.2;
          
    // scale coords
    u = (u + u - iResolution.xy) / iResolution.y;
    
    float i = 0.0;
    float s;
    
    for(o *= i; i < 1e2; i++) {
        
        // shorthand for standard raymarch sample, then move forward:
        // p = ro + rd * d, p.z -= 16.;
        q = p = vec3(u * d, d - 16.);
        
        // rot xy by time and p.z (with subtle audio modulation)
        float c = cos(audioTime + p.z * 0.2);
        float s_rot = sin(audioTime + p.z * 0.2 + 0.33);
        float c2 = cos(audioTime + p.z * 0.2 + 0.11);
        float s2 = sin(audioTime + p.z * 0.2);
        
        mat2 rotMat = mat2(c, s_rot, -s2, c2);
        p.xy = rotMat * p.xy;
        
        // === ENHANCED TURBULENCE (audio reactive) ===
        float turbulenceAmount = TURBULENCE_STRENGTH + smoothVolume * TURBULENCE_AUDIO_MIX * 2.0;
        
        for (float turb_s = 1.; turb_s < 6.; turb_s++) {
            q += sin(0.3 * audioTime + p.xzy * turb_s * 0.3) * turbulenceAmount;
            p += sin(0.4 * audioTime + q.yzx * turb_s * 0.4) * turbulenceAmount;
        }
        
        // === AUDIO REACTIVE SPHERE SIZES ===
        // Only the outer circle (q) gets audio reactive sizing - use beatVolume for immediate response
        float outerSphereSize = BASE_SPHERE_SIZE + beatVolume * VOLUME_SCALE_AMOUNT * SPHERE_SIZE_SCALE;
        
        // distance to spheres and light field
        vec3 pFloor = abs(p - floor(p) - 0.5);
        float innerDist = dot(pFloor, vec3(1));
        float outerDist = max(length(p) - BASE_SPHERE_SIZE, length(q) - outerSphereSize);
        s = abs(min(innerDist, outerDist));
        
        // warp by u
        s = 0.005 + abs(mix(s, 0.001 / abs(p.y), length(u)));
        
        // accumulate distance
        d += s;
        
        // === ENHANCED GLOW (audio reactive) ===
        // Only the outer circle (q) gets enhanced audio-reactive glow
        float outerGlowBoost = 1.0 + volume * GLOW_AUDIO_MIX * 2.4; // Extra glow for outer circle, doubled effect
        
        // color with audio-enhanced glow only on outer circle
        vec4 innerColor = (1.0 + cos(p.z + vec4(6, 4, 2, 0))) / s;
        vec4 outerColor = (1.0 + cos(q.z + vec4(3, 1, 0, 0))) / s * outerGlowBoost;
        
        o += innerColor + outerColor;
    }
    
    // tonemap and divide brightness (with subtle audio brightness boost)
    float brightnessBoost = 1.0 + smoothVolume * 0.1;
    o = tanh(o * o / COLOR_INTENSITY * brightnessBoost);
    
    fragColor = o;
}
