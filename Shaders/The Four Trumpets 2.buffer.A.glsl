#version 330 core
// ============================================================================
// BUFFER A - Quasi-Crystal with Audio-Reactive Trails
// This buffer renders to itself (feedback loop via ping-pong)
// ============================================================================

out vec4 fragColor;

// Uniforms
uniform vec2 iResolution;      // Resolution
uniform float iTime;           // Time
uniform sampler2D iChannel0;   // Audio FFT texture (512x256)
uniform sampler2D iChannel1;   // Previous frame of this buffer (feedback)

// ------- Configurable Parameters -------
#define PINCH_BASE   1.0
#define PINCH_TARGET 10.0
#define SUCK_BASE    1.2
#define SUCK_TARGET  0.5

// FFT band ranges
#define LOW_START    0
#define LOW_END      30
#define LOW_COUNT   (LOW_END-LOW_START)
#define MID_START    150
#define MID_END      350
#define MID_COUNT   (MID_END-MID_START)
#define HIGH_START   479
#define HIGH_END     512
#define HIGH_COUNT  (HIGH_END-HIGH_START)

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;

    // ===== Band-Averaged Audio Analysis =====
    float lowSum = 0.0;
    for (int i = LOW_START; i < LOW_END; ++i) {
        lowSum += texelFetch(iChannel0, ivec2(i, 0), 0).r;
    }
    float midSum = 0.0;
    for (int i = MID_START; i < MID_END; ++i) {
        midSum += texelFetch(iChannel0, ivec2(i, 0), 0).r;
    }
    float highSum = 0.0;
    for (int i = HIGH_START; i < HIGH_END; ++i) {
        highSum += texelFetch(iChannel0, ivec2(i, 0), 0).r;
    }

    float audioLow  = (LOW_COUNT  > 0) ? (lowSum  / float(LOW_COUNT))  : 0.0;
    float audioMid  = (MID_COUNT  > 0) ? (midSum  / float(MID_COUNT))  : 0.0;
    float audioHigh = (HIGH_COUNT > 0) ? (highSum / float(HIGH_COUNT)) : 0.0;

    // ===== Audio-Reactive Parameters =====
    // Low frequencies control PINCH (radial distortion)
    float PINCH = mix(PINCH_BASE, PINCH_TARGET, audioLow);
    // High frequencies control SUCK (center attraction)
    float SUCK  = mix(SUCK_BASE,  SUCK_TARGET,  audioHigh);

    float k = 3.0;         // Number of plane waves
    float stripes = 4.0;   // Stripes per wave

    // ===== Log-Polar Quasi-Crystal Generation =====
    vec2 uv = (fragCoord - 0.5 * iResolution) / min(iResolution.x, iResolution.y);

    float theta = atan(uv.y, uv.x);  // Angle [-π, π]
    float r = log(length(uv) + SUCK + 1e-5);  // Log-radius with audio reactivity

    // Sum of plane waves in log-polar coordinates
    float C = 0.0;
    for (float t = 0.0; t < 3.1415926535; t += 3.1415926535 / k) {
        C += cos((theta * cos(t) - r * PINCH * sin(t)) * stripes + iTime * 1.0);
    }

    float intensity = (C + k) / (2.0 * k);

    // ===== HSV Coloring with Mid-Frequency Brightness Boost =====
    float hue = intensity * 1.0 + iTime * 0.1;
    float saturation = 0.8 + 0.2 * sin(r * 0.5);
    float value = 1.0;
    if (intensity > 0.3 && intensity < 0.6) {
        value += audioMid * 7.0;  // Mid frequencies boost specific intensity ranges
    }
    vec3 color = hsv2rgb(vec3(fract(hue), saturation, value));

    // ===== Black and White Stripes =====
    float numStripes = 6.0;
    float bw = mod(floor(intensity * numStripes), 2.0);
    vec3 finalColor = mix(vec3(0.0), color, bw);  // Black opaque, white reveals color

    // ===== Feedback Trails with Curved Smear =====
    vec2 p = (fragCoord - 0.5 * iResolution) / min(iResolution.x, iResolution.y);

    // Rotation and zoom parameters
    float ang  = 0.0015;                      // Curl amount
    float zoom = 1.0905 + audioLow * 0.001;   // Subtle audio-reactive zoom

    // Rotation matrix
    float cs = cos(ang), sn = sin(ang);
    mat2 rot = mat2(cs, -sn, sn, cs);
    vec2 p2 = rot * (p * zoom);

    // Convert back to UV space and clamp
    vec2 uvW = p2 * (min(iResolution.x, iResolution.y) / iResolution) + 0.5;
    uvW = clamp(uvW, 0.0, 1.0);

    // Sample previous frame from this buffer (feedback)
    vec3 prev = texture(iChannel1, uvW).rgb;

    // Non-darkening composite (mix new content with trails)
    vec3 accum = mix(finalColor, prev, 0.73);

    fragColor = vec4(accum, 1.0);
}
