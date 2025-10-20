// yonatan and diatribs insprire
// Colorful audio-reactive version inspired by https://x.com/zozuar/status/1621229990267310081
// Set iChannel0 to Soundcloud, Microphone, or any audio input!

#version 330 core

// Uniforms
uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio FFT texture

// Output
out vec4 fragColor;

// === TWEAK THESE VALUES ===
#define BASS_WAVE_BOOST 0.3       // How much bass hits perturb the wave
#define KICK_THRESHOLD 0.5        // Threshold for detecting kicks
#define KICK_DECAY 3.0            // How fast kick impulse fades
#define COLOR_SPEED_R 0.5         // Red channel color cycle speed
#define COLOR_SPEED_G 0.7         // Green channel color cycle speed
#define COLOR_SPEED_B 0.9         // Blue channel color cycle speed
#define BRIGHTNESS 1.3            // Overall brightness
#define KICK_BRIGHTNESS 0.3       // Extra brightness on kicks
#define ITERATIONS 32.0           // Number of iterations (higher = more detail)

vec3 tanh3(vec3 x) {
    vec3 ex = exp(2.0 * x);
    return (ex - 1.0) / (ex + 1.0);
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    // Sample bass frequencies
    float bass = texture(iChannel0, vec2(0.02, 0.25)).x;
    float bassKick = texture(iChannel0, vec2(0.05, 0.25)).x;
    
    // Detect kick hits and create decaying impulse
    float kickHit = smoothstep(KICK_THRESHOLD, KICK_THRESHOLD + 0.1, bassKick);
    float kickImpulse = kickHit * exp(-KICK_DECAY * fract(iTime));
    
    // Bass creates a wave perturbation, not a time shift
    float bassWave = pow(bass, 2.0) * BASS_WAVE_BOOST;
    
    float s = 4.;
    vec2 q = vec2(0.0), p = u.xy/iResolution.y - 0.5;
    
    vec3 color = vec3(0.0);
    
    // Normal animation continues at regular speed
    for(float i = 0.; i < ITERATIONS; i += 1.0) {
        p *= mat2(cos(1. + vec4(0, 33, 11, 0)));
        
        // Bass adds to the wave, doesn't control it
        q += cos(2.*iTime - dot(cos(4.*iTime + p + cos(q)), p) + s * p + i*i) 
           + sin(s*p + q.yx) * (1.0 + bassWave + kickImpulse);
        
        s *= 1.3;
        float dist = length(q*q / s);
        
        // Different color channels with phase offsets
        color.r += dist * (0.5 + 0.5 * sin(iTime * COLOR_SPEED_R + i * 0.3));
        color.g += dist * (0.5 + 0.5 * sin(iTime * COLOR_SPEED_G + i * 0.3 + 2.1));
        color.b += dist * (0.5 + 0.5 * sin(iTime * COLOR_SPEED_B + i * 0.3 + 4.2));
    }
    
    // Apply tanh normalization
    color = tanh3(color / 10.0);
    
    // Add some saturation boost and color shifts
    vec3 colorShift = vec3(
        sin(iTime * 0.3) * 0.2,
        sin(iTime * 0.5 + 2.0) * 0.2,
        sin(iTime * 0.7 + 4.0) * 0.2
    );
    color += colorShift;
    
    // Vibrant color enhancement with kick flash
    color = pow(color, vec3(0.8));
    color *= BRIGHTNESS + kickImpulse * KICK_BRIGHTNESS;

    o = vec4(color, 1.0);
    fragColor = o;
}