// FFT Diagnostic Shader
// Simple full-spectrum visualizer to verify FFT data
// iChannel0 = Audio texture

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;  // Audio texture

#define FFT_BINS 512

void mainImage(out vec4 O, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Map x coordinate to FFT bin (0-511)
    int bin = int(floor(uv.x * float(FFT_BINS)));
    bin = clamp(bin, 0, FFT_BINS - 1);

    // Read FFT value from row 0 of audio texture
    float fftValue = texelFetch(iChannel0, ivec2(bin, 0), 0).x;

    // Also try row 1 to see if there's a difference
    float fftValue1 = texelFetch(iChannel0, ivec2(bin, 1), 0).x;

    // Simple bar visualization
    float bar0 = step(uv.y, fftValue);
    float bar1 = step(uv.y, fftValue1);

    // Color: Green for row 0, Blue for row 1
    vec3 col = vec3(0.0);
    col.g = bar0;  // Row 0 in green
    col.b = bar1;  // Row 1 in blue (should be identical for FFT data)

    // Add grid lines every 64 bins for reference
    if (mod(float(bin), 64.0) < 1.0) {
        col.r = 0.3;
    }

    // Show bin numbers at bottom
    if (uv.y < 0.05) {
        col = vec3(0.1);
        if (mod(float(bin), 64.0) < 1.0) {
            col = vec3(1.0, 1.0, 0.0);  // Yellow markers every 64 bins
        }
    }

    O = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
