// ============================================================================
// MILKDROP TRIBUTE - Audio Reactive Visualization
// Classic MilkDrop aesthetics with modern GLSL implementation
// ============================================================================
//
// BUFFER A: Beat Detection & Shape Memory
// Detects beats, stores history, and maintains persistent shapes
// ============================================================================

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // BufferA feedback (self)
uniform sampler2D iChannel1; // Audio FFT

out vec4 fragColor;

// Audio beat detection with hysteresis
float getBeat(sampler2D ch) {
    float bass = texelFetch(ch, ivec2(4, 0), 0).r;
    float prevBass = texelFetch(ch, ivec2(4, 1), 0).r;
    float threshold = 0.65;
    
    // Detect rising edge above threshold
    if (bass > threshold && prevBass <= threshold) {
        return 1.0;
    }
    return 0.0;
}

// Cosine palette (Inigo Quilez style)
vec3 palette(float t, float phase) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557) + phase;
    return a + b * cos(6.28318 * (c * t + d));
}

// Smooth noise function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

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

// Fractal noise for organic shapes
float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 6; i++) {
        if (i >= octaves) break;
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = fragCoord / iResolution.xy;
    vec2 texel = 1.0 / iResolution.xy;

    // Audio analysis - OneOffRender: Audio is in iChannel1, not iChannel0
    float bass = texelFetch(iChannel1, ivec2(4, 0), 0).r;
    float mid = texelFetch(iChannel1, ivec2(32, 0), 0).r;
    float high = texelFetch(iChannel1, ivec2(64, 0), 0).r;
    float treble = texelFetch(iChannel1, ivec2(96, 0), 0).r;
    float energy = (bass + mid + high + treble) * 0.25;

    float beat = getBeat(iChannel1);
    
    // Time evolution
    float t = iTime;
    
    // =========================================================================
    // BEAT HISTORY (first 64 pixels of row 0)
    // =========================================================================
    
    if (fragCoord.y < 1.0 && fragCoord.x < 64.0) {
        int idx = int(fragCoord.x);
        
        // Scroll beat history left
        vec2 readUV = vec2((float(idx) + 1.0) / 64.0, 0.5);
        float prevHistory = texture(iChannel0, readUV).r;
        
        // Add new beat detection
        float newHistory = (idx == 0) ? beat : prevHistory;
        
        // Decay history
        newHistory *= 0.98;
        
        fragColor = vec4(newHistory, energy, bass, 1.0);
    }
    
    // =========================================================================
    // SHAPE PARAMETERS (pixels 64-127 of row 0)
    // =========================================================================
    
    else if (fragCoord.y < 1.0 && fragCoord.x >= 64.0 && fragCoord.x < 128.0) {
        int idx = int(fragCoord.x) - 64;
        
        // Generate evolving parameters
        float seed = float(idx) * 73.0 + t * 0.3;
        float baseVal = hash(vec2(seed, t * 0.1));
        
        // Audio influence on parameters
        float audioMod = mix(baseVal, hash(vec2(seed * energy, t * 0.2)), energy * 0.7);
        
        // Store: x = rotation offset, y = scale, z = alpha, w = color phase
        vec4 params;
        
        if (idx == 0) params = vec4(t * 0.1, 0.5 + bass * 0.5, 0.3 + mid * 0.4, t * 0.05);
        else if (idx == 1) params = vec4(-t * 0.15, 0.3 + mid * 0.3, 0.4 + high * 0.3, t * 0.07);
        else if (idx == 2) params = vec4(t * 0.2, 0.4 + treble * 0.4, 0.5 + bass * 0.3, t * 0.03);
        else if (idx == 3) params = vec4(-t * 0.08, 0.6 + energy * 0.4, 0.2 + high * 0.5, t * 0.1);
        else params = vec4(audioMod, baseVal, hash(vec2(seed * 1.5, t * 0.1)), hash(vec2(seed * 2.0, t)));
        
        fragColor = params;
    }
    
    // =========================================================================
    // PERSISTENT SHAPE MEMORY (main buffer area)
    // =========================================================================
    
    else {
        // Get previous frame for shape persistence
        vec4 prev = texture(iChannel0, uv);
        
        // Coordinate transformation for pattern
        vec2 p = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
        
        // Apply audio-reactive wave displacement
        float wave1 = sin(p.y * 8.0 + t * 2.0 + bass * 3.0) * (0.02 + bass * 0.03);
        float wave2 = sin(p.x * 6.0 + t * 1.5 + mid * 2.0) * (0.02 + mid * 0.03);
        p += vec2(wave1, wave2);
        
        // Polar coordinates
        float r = length(p);
        float a = atan(p.y, p.x);
        
        // Rotating pattern
        float rotSpeed = 0.2 + energy * 0.5;
        a += t * rotSpeed;
        
        // MilkDrop-style concentric patterns
        float pattern1 = sin(r * 20.0 - t * 3.0 + bass * 5.0);
        float pattern2 = sin(a * 6.0 + t * 2.0 + mid * 3.0);
        float pattern3 = sin((p.x + p.y) * 15.0 - t * 2.5 + high * 4.0);
        
        // Combine patterns
        float combined = pattern1 * 0.5 + pattern2 * 0.3 + pattern3 * 0.2;
        
        // Shape intensity with audio boost
        float intensity = smoothstep(-0.5, 1.0, combined) * (0.5 + energy * 1.5);
        
        // Beat flash
        float beatFlash = beat * (0.3 + bass * 0.7);
        
        // Color from palette
        vec3 color = palette(intensity + t * 0.1, t * 0.02);
        
        // Add glow effect
        color *= 1.0 + intensity * 2.0 + beatFlash;
        
        // Blend with previous frame for trails
        float decay = 0.92 - energy * 0.1;
        color = mix(color, prev.rgb, decay);
        
        // Brightness based on audio
        color *= 0.7 + energy * 0.6;
        
        fragColor = vec4(color, 1.0);
    }
}
