#version 330 core

// High-Resolution FFT Demo Shader - Showcases 1024-point FFT capabilities
// Demonstrates Shadertoy-compatible audio analysis with 512 frequency bins

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // High-resolution audio texture (512x256)

out vec4 fragColor;

// Audio sampling functions for high-resolution FFT
float getFrequency(float freq_normalized) {
    // Sample from row 0 of the 512-wide texture
    // freq_normalized: 0.0 = 0Hz, 1.0 = Nyquist frequency
    return texture(iChannel0, vec2(freq_normalized, 0.0)).r;
}

float getFrequencyBin(int bin) {
    // Direct bin access (0-511)
    float x = (float(bin) + 0.5) / 512.0;
    return texture(iChannel0, vec2(x, 0.0)).r;
}

// Get frequency ranges
float getBass() {
    // Low frequencies (0-64 bins, roughly 0-1.4kHz at 44.1kHz)
    float sum = 0.0;
    for (int i = 0; i < 32; i++) {
        sum += getFrequencyBin(i);
    }
    return sum / 32.0;
}

float getMids() {
    // Mid frequencies (64-256 bins, roughly 1.4-5.5kHz at 44.1kHz)
    float sum = 0.0;
    for (int i = 64; i < 256; i += 4) {  // Sample every 4th bin for performance
        sum += getFrequencyBin(i);
    }
    return sum / 48.0;  // 192/4 = 48 samples
}

float getTreble() {
    // High frequencies (256-512 bins, roughly 5.5-22kHz at 44.1kHz)
    float sum = 0.0;
    for (int i = 256; i < 512; i += 4) {  // Sample every 4th bin for performance
        sum += getFrequencyBin(i);
    }
    return sum / 64.0;  // 256/4 = 64 samples
}

// Smooth frequency analysis
float getSmoothFrequency(float center_freq, float bandwidth) {
    // Get a smooth frequency response around a center frequency
    // center_freq: 0.0-1.0 (normalized frequency)
    // bandwidth: width of the frequency band to sample
    
    float sum = 0.0;
    int samples = 8;
    
    for (int i = 0; i < samples; i++) {
        float offset = (float(i) / float(samples - 1) - 0.5) * bandwidth;
        float freq = clamp(center_freq + offset, 0.0, 1.0);
        sum += getFrequency(freq);
    }
    
    return sum / float(samples);
}

// Visualize the full spectrum
vec3 drawSpectrum(vec2 uv) {
    if (uv.y < 0.1 && uv.y > 0.0 && uv.x >= 0.0 && uv.x <= 1.0) {
        // Draw frequency spectrum as a bar graph
        float freq_value = getFrequency(uv.x);
        float bar_height = freq_value * 10.0;  // Scale for visibility
        
        if (uv.y * 10.0 < bar_height) {
            // Color code the spectrum
            if (uv.x < 0.125) {
                return vec3(1.0, 0.2, 0.2);  // Red for bass
            } else if (uv.x < 0.5) {
                return vec3(0.2, 1.0, 0.2);  // Green for mids
            } else {
                return vec3(0.2, 0.2, 1.0);  // Blue for treble
            }
        }
    }
    return vec3(0.0);
}

// Main visual effect using high-resolution audio data
vec3 audioReactiveEffect(vec2 uv) {
    float time = iTime;
    
    // Get detailed frequency analysis
    float bass = getBass();
    float mids = getMids();
    float treble = getTreble();
    
    // Get specific frequency bands for detailed control
    float sub_bass = getSmoothFrequency(0.02, 0.04);      // Very low frequencies
    float kick = getSmoothFrequency(0.08, 0.06);          // Kick drum range
    float snare = getSmoothFrequency(0.25, 0.1);          // Snare range
    float hi_hat = getSmoothFrequency(0.7, 0.2);          // Hi-hat range
    
    // Create audio-reactive patterns
    vec2 center = vec2(0.5, 0.5);
    float dist = length(uv - center);
    
    // Bass-driven pulsing circles
    float bass_pulse = sin(time * 2.0 + bass * 10.0) * bass * 0.3;
    float circle1 = smoothstep(0.2 + bass_pulse, 0.25 + bass_pulse, dist);
    
    // Mid-frequency rotating patterns
    float angle = atan(uv.y - center.y, uv.x - center.x);
    float spiral = sin(angle * 8.0 + time * 3.0 + mids * 15.0) * mids;
    
    // Treble-driven noise and details
    float noise = fract(sin(dot(uv * 50.0, vec2(12.9898, 78.233))) * 43758.5453);
    float treble_detail = noise * treble * 0.5;
    
    // Specific frequency band effects
    float kick_flash = kick * smoothstep(0.4, 0.6, dist) * (1.0 - smoothstep(0.6, 0.8, dist));
    float snare_rays = snare * abs(sin(angle * 16.0 + time * 4.0)) * smoothstep(0.1, 0.9, dist);
    float hihat_sparkle = hi_hat * noise * smoothstep(0.7, 1.0, dist);
    
    // Combine effects
    vec3 color = vec3(0.0);
    color += vec3(1.0, 0.3, 0.3) * (1.0 - circle1) * bass;           // Bass circles
    color += vec3(0.3, 1.0, 0.3) * spiral * 0.5;                     // Mid spiral
    color += vec3(0.3, 0.3, 1.0) * treble_detail;                    // Treble detail
    color += vec3(1.0, 0.8, 0.2) * kick_flash;                       // Kick flash
    color += vec3(0.8, 0.8, 1.0) * snare_rays * 0.3;                 // Snare rays
    color += vec3(1.0, 1.0, 0.8) * hihat_sparkle * 0.2;              // Hi-hat sparkle
    
    return color;
}

void main() {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 centered_uv = (gl_FragCoord.xy - 0.5 * iResolution.xy) / iResolution.y;
    
    vec3 color = vec3(0.0);
    
    // Draw the spectrum analyzer at the bottom
    color += drawSpectrum(uv);
    
    // Main audio-reactive effect
    color += audioReactiveEffect(centered_uv);
    
    // Add some overall brightness based on total audio energy
    float total_energy = (getBass() + getMids() + getTreble()) / 3.0;
    color *= (0.5 + total_energy * 0.5);
    
    fragColor = vec4(color, 1.0);
}
