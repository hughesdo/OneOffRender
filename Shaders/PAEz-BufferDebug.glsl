// Debug what's actually in Buffer A
// iChannel0 = Buffer A

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform sampler2D iChannel0;

#define FFT_BINS 512

void mainImage(out vec4 O, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // Show different rows of the buffer
    if (uv.y > 0.9) {
        // Top 10%: Show row 0 (beat detection state)
        int x = int(fragCoord.x);
        vec4 pixel = texelFetch(iChannel0, ivec2(x, 0), 0);
        O = vec4(pixel.rgb, 1.0);
    } else if (uv.y > 0.8) {
        // Next 10%: Show row 1 (FFT spectrum) - AMPLIFIED
        int bin = int(clamp(floor(uv.x * float(FFT_BINS)), 0.0, float(FFT_BINS-1)));
        float s = texelFetch(iChannel0, ivec2(bin, 1), 0).x;
        float value = clamp(s * 5.0, 0.0, 1.0);
        O = vec4(vec3(value), 1.0);
    } else {
        // Bottom 80%: Render spectrum as bars
        int bin = int(clamp(floor(uv.x * float(FFT_BINS)), 0.0, float(FFT_BINS-1)));
        float s = texelFetch(iChannel0, ivec2(bin, 1), 0).x;
        float value = clamp(s * 5.0, 0.0, 1.0);
        float bar = step(1.0 - (uv.y / 0.8), value);

        vec3 col = vec3(bar);
        if (bin < 32) {
            col = vec3(bar, bar * 0.6, 0.0);
        }
        O = vec4(col, 1.0);
    }
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
