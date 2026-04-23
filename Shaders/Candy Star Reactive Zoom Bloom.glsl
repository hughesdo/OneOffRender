// https://www.shadertoy.com/view/7fB3Dt
// Candy Star Reactive Zoom Bloom - audio reactive
// Converted to OneOffRender format

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

void mainImage(out vec4 O, in vec2 fragCoord)
{
    // Centered screen coordinates
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    // Sample bass from audio FFT texture (row 0)
    float bass =
          texture(iChannel0, vec2(0.01, 0.0)).x
        + texture(iChannel0, vec2(0.02, 0.0)).x
        + texture(iChannel0, vec2(0.03, 0.0)).x
        + texture(iChannel0, vec2(0.04, 0.0)).x;

    bass *= 0.25;
    bass = pow(bass, 0.7);

    // Sample treble from higher FFT bins (row 0)
    float treble =
          texture(iChannel0, vec2(0.70, 0.0)).x
        + texture(iChannel0, vec2(0.78, 0.0)).x
        + texture(iChannel0, vec2(0.86, 0.0)).x
        + texture(iChannel0, vec2(0.94, 0.0)).x;

    treble *= 0.25;
    treble = pow(treble, 0.8);

    // Base zoom plus bass reactivity
    float baseZoom = 0.6;
    float bassAmount = 0.25;

    // Smaller uv = larger center
    float zoomScale = baseZoom - bass * bassAmount;
    zoomScale = max(zoomScale, 0.25);

    uv *= zoomScale;

    // Polar coordinates
    float r = max(length(uv), 0.0001);
    float a = atan(uv.y, uv.x);

    // Slight rotation over time
    a += iTime * 0.20;

    // Log-polar coordinates
    vec2 logPolar = 7.0 * vec2(log(r) - iTime * 0.3, a);

    vec2 J = logPolar;
    vec2 I = logPolar;

    // Domain warping loop
    for (float n = 1.0; n <= 8.0; n += 1.0)
    {
        I += 0.9 * cos(I.yx * n + iTime * 1.1) * sin(I.x * 0.2) / n;
    }

    // Color generation
    vec4 colorPhase = vec4(1.0, 3.0, 3.90, 0.0);
    vec4 colorBase = 1.0 + sin(I.x + colorPhase);

    // Intensity modulation
    float intensity = 0.5 + 0.5 * sin(4.0 * length(I - J) - iTime * 0.5);

    // Treble controls this influence
    float trebAmount = 7.5;
    float trebInfluence = 0.5 + treble * trebAmount;

float rMask = smoothstep(0.05, 0.45, colorBase.r);
float bMask = smoothstep(0.05, 0.45, colorBase.b);
float gMask = smoothstep(0.00, 0.00, colorBase.g);

float mask = rMask * bMask * gMask;

// Make sure this is 0.0 when there is no treble
float trebEffect = max(trebInfluence - 3.0, 0.0);

// Apply only the extra amount caused by treble
colorBase.rb *= 1.1 + mask * trebEffect;
    // Final output
    O = tanh(colorBase / max(intensity, 0.08) / 3.0);
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}