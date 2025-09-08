#version 330 core

// Audio-Reactive Tunnel Shader - GLSL Version
// Organic tunnel effect with audio-reactive color modulation

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// ==== AUDIO REACTIVE PARAMETERS ====
// Adjust these values to control the intensity of audio effects

// Audio frequency sampling positions (0.0-1.0)
#define AUDIO_LOW_FREQ_POS 0.1     // Bass frequency sampling position
#define AUDIO_MID_FREQ_POS 0.5     // Mid frequency sampling position  
#define AUDIO_HIGH_FREQ_POS 0.9    // High frequency sampling position

// Audio effect intensities
#define BASS_COLOR_INTENSITY 4.0   // How much bass affects red channel
#define MID_COLOR_INTENSITY 4.0    // How much mid affects green channel
#define HIGH_COLOR_INTENSITY 9.0   // How much high affects blue channel
#define AUDIO_BRIGHTNESS_BOOST 0.5 // Audio-driven brightness multiplier
#define AUDIO_VIBRANCE_BOOST 0.9   // Audio-driven color vibrance boost

// Tunnel parameters
#define TUNNEL_SPEED 1.0           // Base tunnel movement speed
#define TUNNEL_LAYERS 85.0         // Number of tunnel layers (higher = more detail)
#define LAYER_STEP 0.0348          // Step size between layers
#define CELL_SIZE 0.471            // Size of tunnel cells
#define ORGANIC_SCALE 2.18         // Scale of organic distortion
#define ORGANIC_SECONDARY 0.34     // Secondary organic distortion
#define DISTANCE_BASE 0.0107       // Base distance value
#define DISTANCE_SCALE 0.423       // Distance scaling factor
#define COLOR_DIVISOR 500.0        // Color normalization divisor
#define BASE_BRIGHTNESS 0.8        // Base brightness level
#define GAMMA_CORRECTION 2.8       // Gamma correction value

#define PI 3.14159265359

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord.xy * 2. - iResolution.xy) / iResolution.y;
    vec3 c = vec3(0), p;
    float z = 0., d, org;
    
    // Sample audio from iChannel0 (assuming FFT data)
    float audioLow = texture(iChannel0, vec2(AUDIO_LOW_FREQ_POS, 0.0)).x; // Low frequencies (bass)
    float audioMid = texture(iChannel0, vec2(AUDIO_MID_FREQ_POS, 0.0)).x; // Mid frequencies
    float audioHigh = texture(iChannel0, vec2(AUDIO_HIGH_FREQ_POS, 0.0)).x; // High frequencies
    
    // Combine audio inputs for color modulation
    float audioIntensity = (audioLow + audioMid + audioHigh) / 3.0;
    
    for(float i = 0.; i < TUNNEL_LAYERS; i++) {
        z = i * LAYER_STEP;
        p = z * normalize(vec3(uv, 1.));
        p.z -= iTime * TUNNEL_SPEED;
        vec3 qp = ceil(p / CELL_SIZE) * CELL_SIZE;
        
        // Original organic effect
        org = dot(cos(p * ORGANIC_SCALE), sin(p.yzx * ORGANIC_SECONDARY));
        d = DISTANCE_BASE + abs(org) * DISTANCE_SCALE;
        z += d;
        
        // Modulate color with audio
        vec3 colorMod = vec3(
            cos(p.x + iTime * PI / 2.0 + audioLow * BASS_COLOR_INTENSITY),  // Bass affects red
            cos(p.y + iTime * PI / 2.0 + audioMid * MID_COLOR_INTENSITY),  // Mid affects green
            cos(p.z + iTime * PI / 2.0 + audioHigh * HIGH_COLOR_INTENSITY)  // High affects blue
        );
        c += (colorMod + 2.5) / d * (BASE_BRIGHTNESS + audioIntensity * AUDIO_BRIGHTNESS_BOOST); // Scale with audio intensity
    }
    
    // Final color with audio-driven vibrance
    c = abs(sin(c / COLOR_DIVISOR)) * (BASE_BRIGHTNESS + audioIntensity * AUDIO_VIBRANCE_BOOST);
    
    // Apply a slight gamma correction for better color blending
    c = pow(c, vec3(GAMMA_CORRECTION));
    
    fragColor = vec4(c, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}