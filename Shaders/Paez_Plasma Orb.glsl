// Plasma Orb - Bass Reactive
// Set iChannel0 to an audio source
// Converted from Shadertoy for OneOffRender

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;

// TWEAKABLES
#define BASS_SPEED     0.7    // how much bass pushes animation speed
#define BASS_BRIGHT    2.0    // glow pump on the beat
#define BASS_WARP      0.15   // extra UV warp strength on beat
#define BASS_ZOOM      0.12   // orb "inhale" on beat (zooms in slightly)

vec4 render(vec2 u, float t, float bass)
{
    vec4 o = vec4(0.0);

    float tDriven = t + bass * BASS_SPEED;  // beat-driven time offset

    for(float i = 1.0; i < 12.0; i++)
    {
        o += 0.015 / length(sin(u*4.0 + i*1.5 + tDriven*2.0))
             * (cos(i*0.4 + vec4(4,5,6,0) + tDriven) + 1.0);

        // bass swells the warp amount
        float warp = 0.3 + bass * BASS_WARP;
        u = (u + warp * sin(u.yx*4.0 + i + tDriven*1.5)).yx;
    }

    // bass briefly tightens the vignette (orb pulses outward)
    o *= 1.0 - length(u) * (0.3 - bass * BASS_ZOOM);

    // bass pumps brightness
    o = tanh(o * (1.5 + bass * BASS_BRIGHT));

    return o;
}

void mainImage(out vec4 O, vec2 C)
{
    // Y-flip to match Shadertoy coordinate system
    C.y = iResolution.y - C.y;

    float t = iTime;
    vec2 r = iResolution.xy;

    // --- Bass sampling: average 5 nearby bins for a smooth envelope ---
    float bass = 0.0;
    bass += texture(iChannel0, vec2(0.01, 0.25)).x;
    bass += texture(iChannel0, vec2(0.02, 0.25)).x;
    bass += texture(iChannel0, vec2(0.03, 0.25)).x;
    bass += texture(iChannel0, vec2(0.05, 0.25)).x;
    bass += texture(iChannel0, vec2(0.07, 0.25)).x;
    bass /= 5.0;
    bass = pow(bass, 1.5);   // softer sharpening — less frame-to-frame spike

    // slight zoom on beat — orb breathes inward/outward
    float zoom = 0.4 - bass * 0.04;
    vec2 u = (C*2.0 - r) / r.y / zoom;

    float s = 0.5; // AA sample offset
    O = (render(u + vec2(s,-s)/r.y, t, bass) +
         render(u + vec2(s,s)/r.y, t, bass) +
         render(u + vec2(-s,-s)/r.y, t, bass) +
         render(u + vec2(-s,s)/r.y, t, bass)) * 0.25;
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
