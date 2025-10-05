#version 330 core

// Quasi Crystals2 - OneOffRender Version
// Converted from Shadertoy format to OneOffRender
// Quasi-crystals as sums of plane waves in log-polar coordinates

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// HSV to RGB conversion function
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    // Fix coordinate system for OneOffRender
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    
    float k = 5.0;      // Number of plane waves
    float stripes = 16.0; // Number of stripes per wave
    
    // Normalized coordinates centered at (0,0)
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
    
    // Raw log-polar coordinates (no seam adjustments)
    float theta = atan(uv.y, uv.x); // Ranges from -π to π
    float r = log(length(uv) + 1e-5); // Add epsilon to avoid log(0)
    
    // Accumulator
    float C = 0.0;
    
    // Sum over plane waves
    for (float t = 0.0; t < 3.1415926535; t += 3.1415926535 / k) {
        C += cos((theta * cos(t) - r * sin(t)) * stripes + iTime * 2.0); // Animated phase
    }
    
    // Normalize to [0,1]
    float intensity = (C + k) / (2.0 * k);
    
    // HSV coloring based on intensity and radial modulation
    float hue = intensity * 1.0 + iTime * 0.1;
    float saturation = 0.8 + 0.2 * sin(r * 8.0);
    float value = 0.95;
    vec3 color = hsv2rgb(vec3(fract(hue), saturation, value));

    // Multiple black and white stripes: scale intensity and alternate with mod
    float numStripes = 8.0; // Adjust this for more/fewer stripe pairs
    float bw = mod(floor(intensity * numStripes), 2.0); // Alternates 0 (black) and 1 (white)

    // Mix: black is opaque black; white is see-through (transparent)
    vec3 finalColor = mix(vec3(0.0), color, bw); // Black on bw=0, color on bw=1

    // Output with alpha
    fragColor = vec4(finalColor, 1.0);
}
