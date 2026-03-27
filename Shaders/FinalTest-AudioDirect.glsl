// Final test - read audio texture row 0 AND row 1 to compare
// NO BUFFER - direct audio only

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Should be audio texture when no buffer exists

#define FFT_BINS 512

void mainImage(out vec4 O, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    int bin = int(clamp(floor(uv.x * float(FFT_BINS)), 0.0, float(FFT_BINS-1)));

    // Read from BOTH row 0 and row 1 of audio texture
    float row0 = texelFetch(iChannel0, ivec2(bin, 0), 0).x;
    float row1 = texelFetch(iChannel0, ivec2(bin, 1), 0).x;

    // Split screen: top half shows row 0, bottom half shows row 1
    float value;
    if (uv.y > 0.5) {
        value = clamp(row0 * 5.0, 0.0, 1.0);
    } else {
        value = clamp(row1 * 5.0, 0.0, 1.0);
    }

    float bar = step(1.0 - mod(uv.y, 0.5) * 2.0, value);

    vec3 col = vec3(bar);
    if (bin < 32) {
        col = vec3(bar, bar * 0.6, 0.0);
    }

    // Label: white line at y=0.5
    if (abs(uv.y - 0.5) < 0.005) {
        col = vec3(1.0);
    }

    O = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
