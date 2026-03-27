// Test shader to visualize bin mapping
// iChannel0 = Buffer A

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform sampler2D iChannel0;

#define FFT_BINS 512

float spec(int i) {
    return texelFetch(iChannel0, ivec2(i, 1), 0).x;
}

void mainImage(out vec4 O, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Calculate bin number
    int bin = int(clamp(floor(uv.x * float(FFT_BINS)), 0.0, float(FFT_BINS-1)));

    // Read FFT value
    float s = spec(bin);

    // Amplify and clamp for visibility
    float value = clamp(s * 5.0, 0.0, 1.0);

    // Simple bar from bottom - FIX: invert Y so bars grow upward
    float bar = step(1.0 - uv.y, value);

    // Color based on bin number for debugging
    vec3 col = vec3(bar);

    // Highlight first 32 bins in RED
    if (bin < 32) {
        col.r = bar;
        col.g = bar * 0.5;
        col.b = 0.0;
    }

    // Draw vertical line every 10 bins for reference
    if (mod(float(bin), 10.0) < 0.5) {
        col.g = 1.0;
    }

    O = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
