// Direct test - bypass Buffer A and read audio texture directly
// iChannel0 = Audio texture

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture directly

#define FFT_BINS 512

void mainImage(out vec4 O, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Calculate bin number
    int bin = int(clamp(floor(uv.x * float(FFT_BINS)), 0.0, float(FFT_BINS-1)));

    // Read FFT DIRECTLY from audio texture row 0
    float s = texelFetch(iChannel0, ivec2(bin, 0), 0).x;

    // Same amplification as test shader
    float value = clamp(s * 5.0, 0.0, 1.0);

    // Simple bar from bottom
    float bar = step(1.0 - uv.y, value);

    // Color: first 32 bins in orange, rest in white
    vec3 col = vec3(bar);
    if (bin < 32) {
        col = vec3(bar, bar * 0.6, 0.0);
    }

    // Green lines every 10 bins
    if (mod(float(bin), 10.0) < 0.5) {
        col.g = 1.0;
    }

    O = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
