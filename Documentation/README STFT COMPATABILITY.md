# README TTF COMPATABILITY
date: 2025-10-04

## summary of what we did
we diagnosed a visual artifact in audio‑reactive shaders when run in a desktop moderngl renderer versus shadertoy. the artifact appeared as a leftmost dip and a secondary ghost line in xordev’s waveform shader. tests isolated the cause to how the shader sampled the audio texture along the y coordinate, not the shader’s core math or the fft itself.

we ran three incremental tests:

- test 1: clamp audio uvs at the edges to rule out wrap or border blend — no change
- test 2: remove screen‑space y flip to match shadertoy math exactly — no change, but image flipped
- test 3: force y to 0.5 so sampling stays inside the waveform band (rows 2..255) — issue resolved

## root cause
- original shader sampled the audio texture with a varying y:
  `y = (-p.z - 3.0) * 50.0 / R.y`
- shadertoy’s audio texture has a hard seam between row 1 (spectrum) and row 2 (waveform). with linear filtering, sampling near that seam blends spectrum and waveform.
- the varying y occasionally crossed the seam, so samples mixed in spectrum, causing the leftmost dip and ghost line.
- forcing `y = 0.5` kept sampling in the middle of the waveform band, far from any seam, removing artifacts.

this can affect any shader that:
- samples `iChannel0` with a varying y, and
- expects the sampled region to be uniform across rows.

shadertoy usually looks fine because waveform rows are identical and most code samples them squarely. when y skims the seam, linear filtering bites.

## what to do going forward
two complementary actions: harden the renderer and standardize shader helpers.

### A) keep shaders seam‑safe
include a small helper header and use it for all audio samples.

```glsl
// audio_layout.glsl
#ifndef AUDIO_LAYOUT_GLSL
#define AUDIO_LAYOUT_GLSL

uniform sampler2D iChannel0;

const float AUDIO_TEX_H = 256.0;
const float Y_SPEC0     = 0.0;               // exact center of row 0
const float Y_SPEC1     = 1.0 / AUDIO_TEX_H; // exact center of row 1
const float Y_WAVE_MIN  = 2.5 / AUDIO_TEX_H; // row 2 + half pix (guard)
const float Y_WAVE_MAX  = (AUDIO_TEX_H - 0.5) / AUDIO_TEX_H;

float sampleSpectrum(float x) {
    return texture(iChannel0, vec2(x, Y_SPEC0)).r;
}

float sampleWaveform(float x) {
    return texture(iChannel0, vec2(x, 0.5)).r; // mid of waveform band
}

// vary within waveform rows but never touch the seam
float sampleWaveformVarying(float x, float t) {
    float y = mix(Y_WAVE_MIN, Y_WAVE_MAX, clamp(t, 0.0, 1.0));
    return texture(iChannel0, vec2(x, y)).r;
}

#endif
```

in xordev’s shader, replace the music fetch with:

```glsl
float x = (p.x + 6.5) / 15.0;
// original varying y remapped to a safe 0..1 range
float t = clamp((-p.z - 3.0) * 50.0 / R.y, 0.0, 1.0);
p.y += r + r - 4.0 * sampleWaveformVarying(x, t);
```

this preserves the original intent while avoiding the spectrum‑waveform seam.

### B) lock down renderer texture setup
ensure the audio texture settings avoid edge issues.

- filtering: linear, no mipmaps
- wrap: clamp to edge
- no gamma conversions
- fill all rows 2..255 with the identical waveform line

moderngl example:

```python
# after creating tex = ctx.texture((512, 256), 1, data, dtype='f1' or 'f2')
tex.filter = (moderngl.LINEAR, moderngl.LINEAR)
tex.repeat_x = False
tex.repeat_y = False

# if your api exposes mipmap flags:
# tex.build_mipmaps(False)
# tex.base_level = 0; tex.max_level = 0  # if available
# tex.anisotropy = 1.0
```

optional hardening:
- when packing rows, write a guard band of waveform values into rows 2–4, then the same waveform everywhere below. this gives extra distance from the seam even if a shader maps y loosely.

## upright image without reintroducing the bug
keep mainImage math identical to shadertoy. flip at the call site only.

```glsl
void main() {
    vec2 I = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec4 fragColor;
    mainImage(fragColor, I);
    gl_FragColor = fragColor;
}
```

## working shader example
this is the successful test 3 version, made upright via the call‑site flip, with high precision.

```glsl
/*
    Waveform by @XorDev
    parity‑fixed for desktop ModernGL
*/

#ifdef GL_ES
precision highp float;
#endif

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;

void mainImage(out vec4 O, vec2 I)
{
    // shadertoy‑parity math (no screen‑space flip here)

    float i, d, z, r;
    for (O *= i; i++ < 9e1;
         O += (cos(z * .5 + iTime + vec4(0, 2, 4, 3)) + 1.3) / d / z)
    {
        vec3 R = iResolution.xyy;
        vec3 p = z * normalize(vec3(I + I, 0.0) - R);

        r = max(-++p, 0.0).y;

        // seam‑safe waveform sampling: constant y in waveform band
        float x = (p.x + 6.5) / 15.0;
        float y = 0.5; // center of waveform rows (2..255)
        p.y += r + r - 4.0 * texture(iChannel0, vec2(x, y)).r;

        z += d = .1 * (.1 * r + abs(p.y) / (1.0 + r + r + r * r)
                       + max(d = p.z + 3.0, -d * .1));
    }

    O = tanh(O / 9e2);
}

void main() {
    // flip only at presentation, not inside mainImage math
    vec2 I = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec4 fragColor;
    mainImage(fragColor, I);
    gl_FragColor = fragColor;
}
```

## doc block to paste in any project
- iChannel0 layout: 512×256 R texture
  - row 0 = spectrum
  - row 1 = spectrum duplicate
  - rows 2..255 = waveform repeated
- never sample near the y seam between rows 1 and 2 with a varying y
- use helpers:
  - sampleSpectrum(x) at y=0
  - sampleWaveform(x) at y=0.5
  - sampleWaveformVarying(x, t) with t in [0..1] mapped to rows 2.5..255.5
- renderer params: linear filtering, clamp to edge, no mipmaps
- keep shader math shadertoy‑parity and flip only at the call site or in vertex

## included reference text
the following section reproduces the detailed notes for completeness.

---

Boom — you nailed the root cause.

Why Test 3 fixed it

Your original shader samples the audio texture with a varying y:
y = (-p.z - 3.0) * 50.0 / R.y

Shadertoy’s audio texture has a hard seam between row 1 (spectrum) and row 2 (waveform). With linear filtering, sampling anywhere near that seam blends spectrum and waveform.

Your varying y occasionally crosses that seam, so some samples mix in spectrum — that shows up as the leftmost dip and the ghost line.

Forcing y = 0.5 keeps sampling inside the middle of the waveform band (safe distance from any seam), so the artifacts disappear.

This can affect any shader that:

samples iChannel0 with a varying y, and

expects the region to be visually uniform across rows.

Shadertoy gets away with it because those waveform rows are identical and you usually hit them squarely. But as soon as y skims a seam, linear filtering bites.

What to do going forward

You have two good paths. I recommend both: change the renderer a tiny bit and standardize shader helpers.

A) Keep shaders seam-safe

Add tiny GLSL helpers and use them everywhere for audio sampling:

// audio_layout.glsl (include in every shader)
#ifndef AUDIO_LAYOUT_GLSL
#define AUDIO_LAYOUT_GLSL

uniform sampler2D iChannel0;

const float AUDIO_TEX_H = 256.0;
const float Y_SPEC0     = 0.0;               // exact center of row 0
const float Y_SPEC1     = 1.0 / AUDIO_TEX_H; // exact center of row 1
const float Y_WAVE_MIN  = 2.5 / AUDIO_TEX_H; // row 2 + half pix (guard)
const float Y_WAVE_MAX  = (AUDIO_TEX_H - 0.5) / AUDIO_TEX_H;

float sampleSpectrum(float x) {
    return texture(iChannel0, vec2(x, Y_SPEC0)).r;
}

float sampleWaveform(float x) {
    return texture(iChannel0, vec2(x, 0.5)).r; // mid of waveform band
}

// Use t in [0..1] to vary within waveform rows but never touch the seam
float sampleWaveformVarying(float x, float t) {
    float y = mix(Y_WAVE_MIN, Y_WAVE_MAX, clamp(t, 0.0, 1.0));
    return texture(iChannel0, vec2(x, y)).r;
}

#endif


In XorDev’s shader, replace the music fetch with:

float x = (p.x + 6.5) / 15.0;
// original varying y remapped to a safe 0..1 range
float t = clamp((-p.z - 3.0) * 50.0 / R.y, 0.0, 1.0);
p.y += r + r - 4.0 * sampleWaveformVarying(x, t);


That preserves the intent of varying y, but never hits the spectrum–waveform seam.

B) Lock down renderer texture setup

Make sure your audio texture won’t introduce extra edge issues:

filtering: linear, no mipmaps

wrap: clamp to edge

no gamma conversions

fill all rows 2..255 with the identical waveform line

ModernGL example (python side):

# after creating `tex` = ctx.texture((512, 256), 1, data, dtype='f1' or 'f2')
tex.filter = (moderngl.LINEAR, moderngl.LINEAR)
tex.repeat_x = False
tex.repeat_y = False

# if your API exposes mipmap flags, ensure no mipmaps are built:
# tex.build_mipmaps(False)     # or skip mipmap creation entirely
# also consider forcing base/max level to 0 if available
# tex.anisotropy = 1.0         # not needed for 1D-like lookups


Optional renderer tweak to further harden it:

when packing rows, write a guard band of waveform values into rows 2–4, then the same waveform everywhere below. That gives extra distance from the seam even if a shader maps y loosely.

Upright image without re-introducing the bug

Keep mainImage math identical to Shadertoy (no I.y flip inside), and just flip at the call site:

void main() {
    vec2 I = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec4 fragColor;
    mainImage(fragColor, I);
    gl_FragColor = fragColor;
}

Full shader file you can keep

This is your working Test 3, made upright via the call-site flip, plus highp precision.

/*
    Waveform by @XorDev
    parity-fixed for desktop ModernGL
*/

#ifdef GL_ES
precision highp float;
#endif

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;

void mainImage(out vec4 O, vec2 I)
{
    // Shadertoy-parity math (no screen-space flip here)

    float i, d, z, r;
    for (O *= i; i++ < 9e1;
         O += (cos(z * .5 + iTime + vec4(0, 2, 4, 3)) + 1.3) / d / z)
    {
        vec3 R = iResolution.xyy;
        vec3 p = z * normalize(vec3(I + I, 0.0) - R);

        r = max(-++p, 0.0).y;

        // Seam-safe waveform sampling: constant y in waveform band
        float x = (p.x + 6.5) / 15.0;
        float y = 0.5; // center of waveform rows (2..255)
        p.y += r + r - 4.0 * texture(iChannel0, vec2(x, y)).r;

        z += d = .1 * (.1 * r + abs(p.y) / (1.0 + r + r + r * r)
                       + max(d = p.z + 3.0, -d * .1));
    }

    O = tanh(O / 9e2);
}

void main() {
    // Flip only at presentation, not inside mainImage math
    vec2 I = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec4 fragColor;
    mainImage(fragColor, I);
    gl_FragColor = fragColor;
}

Doc block you can paste in every project

iChannel0 layout: 512×256 R texture
row 0 = spectrum, row 1 = spectrum duplicate, rows 2..255 = waveform repeated

never sample near y rows [0..2] seam with a varying y

use helpers:

sampleSpectrum(x) at y=0

sampleWaveform(x) at y=0.5

sampleWaveformVarying(x, t) with t in [0..1] mapped to rows 2.5..255.5

renderer params: linear filtering, clamp to edge, no mipmaps

keep shader math Shadertoy-parity and flip only at the call site or in the vertex

If you want, I can also drop a tiny patch for your render_shader.py that writes a guard band and enforces the ModernGL texture parameters exactly.
