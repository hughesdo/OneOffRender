// Image Shader (Visualizer)
// iChannel0 = Buffer A (Consolidated Logic + Spectrum)

#define FFT_BINS 512

// Must match settings in Buffer A
#define LOW_START   3
#define LOW_END     30
#define HIGH_START  3
#define HIGH_END    10

// Read spectrum from Row 1 of Buffer A (formerly Buffer A)
float spec(int i) { return texelFetch(iChannel0, ivec2(i, 1), 0).x; }

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    // 1. Read Beat Result
    // In our new consolidated Buffer A, beat result is stored at pixel (2,0)
    float beatType = texelFetch(iChannel0, ivec2(2,0), 0).r;

    // 2. Spectrum Visualization
    int bin = int(clamp(floor(uv.x * float(FFT_BINS)), 0.0, float(FFT_BINS-1)));
    float s = spec(bin);

    // Apply gamma for visibility
    float y = pow(s, 1.6);
    float bar = smoothstep(uv.y, uv.y + 0.01, y);

    // 3. Highlight Bands
    // We use defines directly instead of texture lookups for performance
    float inLow  = step(float(LOW_START),  float(bin)) * step(float(bin), float(LOW_END));
    float inHigh = step(float(HIGH_START), float(bin)) * step(float(bin), float(HIGH_END));

    // 4. Coloring
    vec3 col = vec3(0.02);
    col += vec3(0.15, 0.35, 0.90) * bar;                     // base spectrum
    col = mix(col, vec3(1.0, 0.55, 0.10), 0.35 * inLow  * bar); // low band tint
    col = mix(col, vec3(0.20, 1.0, 0.95), 0.35 * inHigh * bar); // high band tint

    // 5. Flash Effect
    // Red for Major beats (>0.75), White for Minor beats (>0.25)
    vec3 flash = (beatType > 0.75) ? vec3(1.0, 0.2, 0.2) :
                 (beatType > 0.25) ? vec3(1.0) :
                                     vec3(0.0);
    
    col += flash * 2.15;

    fragColor = vec4(col, 1.0);
}