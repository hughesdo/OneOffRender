// https://www.shadertoy.com/view/ffjGW1
// 00 - kishimisu Bass-reactive remix
// Converted to OneOffRender format

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

/* Interference by @kishimisu (2026) - https://www.shadertoy.com/view/scSGD1
   Bass-reactive remix — set iChannel0 to an audio source

   TWEAKABLES
*/
#define BASS_ROT_AMT    0.6   // how much bass pushes xy rotation speed
#define BASS_GLOW_AMT   1.8   // bass multiplier on glow brightness
#define BASS_STEP_AMT   0.008 // bass influence on ray step size (subtle geometry pulse)
// FIXED: original 0.03 mapped to ~700Hz in our 48kHz/512-bin system (not bass).
// Multi-bin average across true sub-bass / kick range (50-350Hz).
#define BASS_BIN_A      0.003  // ~72Hz  sub-bass
#define BASS_BIN_B      0.008  // ~192Hz kick fundamental
#define BASS_BIN_C      0.014  // ~336Hz upper-bass

#define R(a) *= mat2(cos(a + vec4(0,33,11,0)))
#define L(x) length(x)

void mainImage(out vec4 O, vec2 F) {
    float a, r, t = iTime;

    // --- Bass sampling (multi-bin average across true bass range) ---
    float bass = (texture(iChannel0, vec2(BASS_BIN_A, 0.0)).x
               + texture(iChannel0, vec2(BASS_BIN_B, 0.0)).x
               + texture(iChannel0, vec2(BASS_BIN_C, 0.0)).x) / 3.0;
    bass = pow(bass, 1.5);                    // milder compression (was 2.0)
    float bassRot  = 1.0 + bass * BASS_ROT_AMT;
    float bassGlow = 1.0 + bass * BASS_GLOW_AMT;

    for (O *= a; a < 40.; a++) {
        vec3 i = iResolution.xyy, f,
             p = r * normalize(vec3((F+F-i.xy)/i.y, 1));

        p.z -= 3.;
        p.xz R(.3);
        p.zy R(sin(t/4.)*.3 + .9);
        p.xy R(t/4. * bassRot);              // bass speeds up xy spin
        p.x = abs(p.x) - 1.;

        O += bassGlow *                       // bass pumps the glow
             (.04 + .12*smoothstep(.9, 1., cos(L(p.xy+p.z)*2.-t)))*
             (1. + cos(L(p.xy)*2. + a*.2 + vec4(0,1,2,0)))/L(p.xy);

        p.yx R(atan(p.y, p.x));
        p.zx R(atan(max(p.z, 0.), p.x));

        f.x = pow(.67, floor(t - log(p.x)/.4) - t);
        r += min(L(p.xy), min(
             abs(L(p - f) - f.x*.2),
             abs(L(p - f*.67) - f.x*.134)
        )) + .01 + bass * BASS_STEP_AMT;    // subtle geometry pulse on beat
    }

    O = tanh(O);
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}