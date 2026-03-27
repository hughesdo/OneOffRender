#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// orignial Diatribes: https://www.shadertoy.com/view/scfGWr
// Audio-Reactive Smooth Fractal — iChannel0 = sound/mic
// Tweakables
#define BASS_PULSE_STR    0.4    // how much bass expands the fractal boundary
#define MID_WARP_STR      0.3    // mid-freq domain distortion amount
#define HIGH_COLOR_STR    1.5    // treble boost on color intensity
#define BASS_FREQ         0.05   // frequency sample point for bass
#define MID_FREQ          0.25   // frequency sample point for mids
#define HIGH_FREQ         0.55   // frequency sample point for highs
#define SMOOTH_ROW        0.75   // row 0.75 = smoothed waveform in shadertoy
#define FFT_ROW           0.25   // row 0.25 = FFT data in shadertoy
#define AUDIO_SMOOTH       0.6   // mix factor: higher = smoother audio response

// Grab audio with some smoothing baked in
float aud(float freq) {
    float fft  = texture(iChannel0, vec2(freq, FFT_ROW)).x;
    float wave = texture(iChannel0, vec2(freq, SMOOTH_ROW)).x;
    return mix(fft, wave, AUDIO_SMOOTH);
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    // Sample audio bands
    float bass = aud(BASS_FREQ);
    float mid  = aud(MID_FREQ);
    float high = aud(HIGH_FREQ);

    float i = 0.0, d, s;
    vec3 r = vec3(iResolution, 1.0);
    vec3 a = cos(vec3(2,3,1) + iTime/3.);
    vec3 p;

    // Bass gently nudges the rotation axis
    a += 0.15 * bass * sin(vec3(1,2,3) * iTime * 0.5);

    fragColor = vec4(0.0);
    for(fragColor *= i; i++ < 1e2;
        fragColor += 6.*vec4(1,2,8,0)
           + (1. + cos(.3*i + vec4(6,4,2,0))) / s * (1. + high * HIGH_COLOR_STR)
           + min(vec4(8,2,5,0)*d, 2e2)
    )
        p = vec3((fragCoord+fragCoord - r.xy)/r.y * d, d - 5.),
        p = abs(a*dot(a,p) - cross(a,p)),

        // Fractal boundary breathes with bass (preserves original smooth sin motion)
        s = max(p.x, max(p.y, p.z))
          - .8 - (.3 + bass * BASS_PULSE_STR) * sin(sin(iTime) + iTime/2.),

        // Domain distortion — mids ride on top of the original time-based warp
        p += cos(iTime*2. + p.yzx/2.) * (1. + mid * MID_WARP_STR),
        p = abs(fract(p/s)*s - s*.5),

        s = min(max(p.x, p.y), min(max(p.x, p.z), max(p.y, p.z))) - s/12.,
        s = .001 + .3*abs(s),
        d += s;

    fragColor = tanh(fragColor*fragColor / 6e8);
}