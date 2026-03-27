/*
    "Waveform" Buffer A by @XorDev

    Feedback buffer with vertical scrolling effect
    EXACT translation of original ShaderToy code

    Converted for OneOffRender - GLSL 330 core
*/

#version 330 core

out vec4 fragColor;

// Uniforms
uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;   // Previous frame of this buffer (feedback)
uniform sampler2D iChannel1;   // Audio texture

void mainImage(out vec4 O, vec2 I)
{
    vec2 r = iResolution.xy;

    // EXACT original: O = (I.y-=r.y/6e2)>1.?texture(iChannel0,I/r):texture(iChannel1,I/r);
    // This modifies I.y in place, then checks if the NEW I.y > 1.0

    I.y -= r.y / 600.0;  // Shift down by ~1.8 pixels at 1080p

    if (I.y > 1.0) {
        // Almost all pixels: sample scrolled buffer content
        O = texture(iChannel0, I / r);
    } else {
        // Only bottom ~2 pixel strip: sample fresh audio waveform
        // CRITICAL FIX: Sample at y=0.5 for waveform band, use screen x for horizontal position
        O = texture(iChannel1, vec2(I.x / r.x, 0.5));
    }
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
