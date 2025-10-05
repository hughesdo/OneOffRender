//  Spectrum test By @OneHung but.. inspired by @PAEz 
// (Thanks @PAEz, I need all the help I can get, this stuff is slightly above my pay grade.)

/*
    Debugging Audio Texture Feed — What to Look For
    -----------------------------------------------

    • If red looks like a flat line but blue shows music,
      your spectrum isn’t at y = 0.

    • If green shows the spectrum but red is blank,
      your spectrum is on row 1.

    • If everything is upside down, you need to flip y when sampling:
        texture(iChannel0, vec2(x, 1.0 - y));

    ---------------------------------------------------------------
    2) Sample what the original shader expects

    XorDev’s shader samples a y that varies with scene depth:

        texture(iChannel0,
                vec2((p.x + 6.5) / 15.0,
                     (-p.z - 3.0) * 50.0 / R.y)).r;

    On Shadertoy this lands in waveform rows because rows 2..255
    repeat the oscilloscope line. If your packer only put waveform
    in some other band, or your texture is flipped, the motion will differ.

    Quick test overrides:

        // Force spectrum only
        float music = texture(iChannel0,
                              vec2((p.x+6.5)/15., 0.0)).r;

        // Force waveform only at a known row
        float music = texture(iChannel0,
                              vec2((p.x+6.5)/15., 0.5)).r;

    If one of these matches Shadertoy exactly, your y addressing is the issue.

    ---------------------------------------------------------------
    3) Coordinate System Alignment

    Screen-space Y flip is fine for positions:
        I.y = iResolution.y - I.y;

    But don’t apply that flip to audio texture coordinates unless
    your upload matches. In OpenGL, y = 0.0 samples the bottom row
    unless you flipped the pixels during upload.

    Fixes:
    • Flip the audio image buffer once before creating the texture
    • OR in GLSL, sample with y = 1.0 - y

    ---------------------------------------------------------------
    4) Match Shadertoy Scaling and Smoothing

    • FFT size: 1024 → keep 512 bins
    • Exponential smoothing ≈ 0.8
    • Normalize like Shadertoy (avoid clipping/auto-gain)
    • Use single-channel R8 or R16F normalized 0..1

    ---------------------------------------------------------------
    5) Texture Parameters

    Shadertoy uses:
        GL_TEXTURE_MIN_FILTER = GL_LINEAR
        GL_TEXTURE_MAG_FILTER = GL_LINEAR
        GL_TEXTURE_WRAP_S = GL_CLAMP_TO_EDGE
        GL_TEXTURE_WRAP_T = GL_CLAMP_TO_EDGE

    Using NEAREST will cause aliasing and look different.

    ---------------------------------------------------------------
    6) Precision

    On desktop, use highp to mirror Shadertoy:

        #ifdef GL_ES
        precision highp float;
        #endif

    Ensure your ModernGL program links with high precision defaults.

    ---------------------------------------------------------------
    7) Time / Frame Sync

    Desync between iTime and audio frame index causes visual drift.
    Drive both from the same frame counter:

        idx = frame_number
        time_seconds = frame_number / fps
        audio slice for idx → texture for that frame

    ---------------------------------------------------------------
    8) Quick Sanity Checklist

    [ ] Spectrum at y=0.0
    [ ] Waveform around y=0.5 (or flipped accordingly)
    [ ] Linear filtering + clamp-to-edge
    [ ] FFT, windowing, smoothing = Shadertoy
    [ ] No unintended gamma conversions
    [ ] iResolution in pixels, gl_FragCoord in pixels, no double Y-flip
    [ ] iChannel0 bound to unit 0, uniform updated before draw
*/



#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D iChannel0;
uniform vec2 iResolution;

void main() {
    vec2 uv = gl_FragCoord.xy / iResolution;

    float sp0 = texture(iChannel0, vec2(uv.x, 0.0)).r;  // expect spectrum row 0
    float sp1 = texture(iChannel0, vec2(uv.x, 1.0/255.0)).r; // expect spectrum row 1
    float wav = texture(iChannel0, vec2(uv.x, 0.5)).r;  // expect waveform band

    vec3 c = vec3(0.0);
    if (uv.y < 0.33)       c = vec3(sp0, 0.0, 0.0);   // red = row 0
    else if (uv.y < 0.66)  c = vec3(0.0, sp1, 0.0);   // green = row 1
    else                   c = vec3(0.0, 0.0, wav);   // blue  = waveform

    gl_FragColor = vec4(c, 1.0);
}
