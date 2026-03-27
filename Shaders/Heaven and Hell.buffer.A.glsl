#version 330 core

// Buffer A: Beat/State Detection
// OneOffRender channel mapping:
//   iChannel0 = self-feedback (previous frame)
//   iChannel1 = audio texture

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Self-feedback
uniform sampler2D iChannel1;  // Audio texture
uniform int iFrame;

out vec4 fragColor;

#define iTimeDelta (1.0/60.0)

#define FFT_BINS 512

#define COPY_FFT_ROW   1
#define COPY_WAVE_ROW  0

#define FFT_ROW_Y   0
#define WAVE_ROW_Y  1
#define EXTRAS_Y 2

#define BASS_START  3
#define BASS_END    15

#define BASS_GAIN          0.9
#define THRESHOLD_DECAY    5.0
#define THRESHOLD_MIN      0.20
#define REFRACTORY_JUMP    0.70
#define MIN_BEAT_INTERVAL  0.14
#define TOOSOON_RAISE      0.95

#define SMOOTH_HZ_BASS     12.0

#define FLASH_GAIN         1.2
#define FLASH_DECAY        8.0

float alphaHz(float hz, float dt)
{
    return 1.0 - exp(-hz * dt);
}

float musicFFT(int i)
{
    // Audio is on iChannel1 in OneOffRender buffer convention
    return texelFetch(iChannel1, ivec2(i, 0), 0).x;
}

float musicWave(int i)
{
    return texelFetch(iChannel1, ivec2(i, 1), 0).x;
}

float bandAvgMusic(int startBin, int width)
{
    float s = 0.0;
    for (int k = 0; k < FFT_BINS; k++)
    {
        if (k >= width) break;
        s += musicFFT(startBin + k);
    }
    return s / float(width);
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    ivec2 p = ivec2(fragCoord);

#if COPY_FFT_ROW
    if (p.y == FFT_ROW_Y && p.x >= 0 && p.x < FFT_BINS)
    {
        fragColor = vec4(musicFFT(p.x), 0.0, 0.0, 1.0);
        return;
    }
#endif

#if COPY_WAVE_ROW
    if (p.y == WAVE_ROW_Y && p.x >= 0 && p.x < FFT_BINS)
    {
        fragColor = vec4(musicWave(p.x), 0.0, 0.0, 1.0);
        return;
    }
#endif

    if (p.y != EXTRAS_Y || p.x > 4)
    {
        fragColor = vec4(0.0);
        return;
    }

    float dt = max(iTimeDelta, 1e-6);

    int wB = BASS_END - BASS_START;
    int sB = BASS_START;

    if (p.x == 4)
    {
        fragColor = vec4(float(sB), float(sB + wB), 1.0, 1.0);
        return;
    }

    if (p.x == 1)
    {
        float eB = bandAvgMusic(sB, wB);
        if (iFrame == 0)
        {
            fragColor = vec4(eB, 0.0, 0.0, 1.0);
            return;
        }

        // Self-feedback is on iChannel0 in OneOffRender buffer convention
        vec4 prev = texelFetch(iChannel0, ivec2(1, EXTRAS_Y), 0);
        float smB = mix(prev.r, eB, alphaHz(SMOOTH_HZ_BASS, dt));
        fragColor = vec4(smB, 0.0, 0.0, 1.0);
        return;
    }

    if (p.x == 0)
    {
        if (iFrame == 0)
        {
            fragColor = vec4(0.0, 1e9, 0.5, 0.0);
            return;
        }

        // Self-feedback is on iChannel0
        vec4 st = texelFetch(iChannel0, ivec2(0, EXTRAS_Y), 0);
        float flash   = st.r;
        float silence = st.g;
        float thresh  = st.b;

        flash *= exp(-FLASH_DECAY * dt);

        float prevBass = texelFetch(iChannel0, ivec2(1, EXTRAS_Y), 0).r;

        float eB  = bandAvgMusic(sB, wB);
        float smB = mix(prevBass, eB, alphaHz(SMOOTH_HZ_BASS, dt));

        float fluxB = max(0.0, smB - prevBass) / dt;
        float combinedFlux = fluxB * BASS_GAIN;

        thresh = max(THRESHOLD_MIN, thresh * exp(-THRESHOLD_DECAY * dt));
        silence += dt;

        float hit = 0.0;

        if (combinedFlux > thresh)
        {
            bool tooSoon = (silence < MIN_BEAT_INTERVAL);

            if (tooSoon)
            {
                thresh = max(thresh, combinedFlux * TOOSOON_RAISE);
            }
            else
            {
                silence = 0.0;
                thresh  = max(thresh, combinedFlux * REFRACTORY_JUMP);

                float strength = combinedFlux;
                flash = max(flash, clamp(strength * FLASH_GAIN, 0.0, 1.0));
                hit = 1.0;
            }
        }

        fragColor = vec4(flash, silence, thresh, hit);
        return;
    }

    fragColor = vec4(0.0);
}
