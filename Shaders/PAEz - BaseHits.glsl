// Image Shader (Visualizer)
// iChannel0 = Audio texture (reading FFT directly - Buffer A disabled)

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;  // Audio texture directly

#define FFT_BINS 512

// Must match settings in Buffer A
#define LOW_START   3
#define LOW_END     30
#define HIGH_START  3
#define HIGH_END    10

// Read spectrum from Row 1 of Buffer A
// Buffer stores FFT data in first 512 pixels of row 1
float spec(int i) {
    return texelFetch(iChannel0, ivec2(i, 1), 0).x;
}

void mainImage(out vec4 O, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. No beat detection for now - simplified version

    // 2. Spectrum Visualization - Read FFT directly from audio texture row 0
    int bin = int(clamp(floor(uv.x * float(FFT_BINS)), 0.0, float(FFT_BINS-1)));
    float s = texelFetch(iChannel0, ivec2(bin, 0), 0).x;  // Read from audio row 0

    // Apply same amplification as buffer debug
    float value = clamp(s * 5.0, 0.0, 1.0);
    float bar = step(1.0 - uv.y, value);

    // 3. Simple coloring like buffer debug
    vec3 col = vec3(bar);
    if (bin < 32) {
        col = vec3(bar, bar * 0.6, 0.0);  // Orange for first 32 bins
    }

    // 4. Highlight Bands (keeping for beat indication)
    float inLow  = step(float(LOW_START),  float(bin)) * step(float(bin), float(LOW_END));
    float inHigh = step(float(HIGH_START), float(bin)) * step(float(bin), float(HIGH_END));
    if (inLow > 0.5) col *= vec3(1.2, 0.8, 0.5);  // Slight tint for low band
    if (inHigh > 0.5) col *= vec3(0.8, 1.2, 1.2);  // Slight tint for high band

    // 5. Flash Effect - DISABLED FOR TESTING
    // Red for Major beats (>0.75), White for Minor beats (>0.25)
    //vec3 flash = (beatType > 0.75) ? vec3(1.0, 0.2, 0.2) :
    //             (beatType > 0.25) ? vec3(1.0) :
    //                                 vec3(0.0);
    //col += flash * 2.15;

    O = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
