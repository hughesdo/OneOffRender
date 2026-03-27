// Debug version of PAEz to see what's in Buffer A
// iChannel0 = Buffer A

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;  // Buffer A

#define FFT_BINS 512

// Read spectrum from Row 1 of Buffer A
float spec(int i) { return texelFetch(iChannel0, ivec2(i, 1), 0).x; }

void mainImage(out vec4 O, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Map x to bin number
    int bin = int(clamp(floor(uv.x * float(FFT_BINS)), 0.0, float(FFT_BINS-1)));

    // Read FFT value
    float fftValue = spec(bin);

    // Simple bar - NO gamma, NO smoothstep, just raw value
    float bar = step(uv.y, fftValue * 2.0);  // Scale by 2 for visibility

    // Show the bin value
    vec3 col = vec3(bar);

    // Add grid every 64 bins
    if (mod(float(bin), 64.0) < 1.0) {
        col.r = 1.0;
    }

    // Debug: Show first 32 bins in green, rest in white
    if (bin < 32) {
        col.g = bar;
        col.b = 0.0;
    }

    O = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
