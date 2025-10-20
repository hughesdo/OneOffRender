/*
    "Waveform3d" Buffer A by @XorDev
    
    Feedback buffer with vertical scrolling effect
    
    Converted for OneOffRender - GLSL 330 core
*/

#version 330 core

out vec4 fragColor;

// Uniforms
uniform vec2 iResolution;      // Resolution
uniform float iTime;           // Time (unused but available)
uniform sampler2D iChannel0;   // Previous frame of this buffer (feedback)
uniform sampler2D iChannel1;   // Audio FFT texture

void mainImage(out vec4 O, vec2 I)
{
    // Normalize coordinates to [0, 1]
    vec2 uv = I / iResolution.xy;
    
    // Vertical scroll amount per frame - adjust this to control scroll speed
    float scrollSpeed = 0.005;  // Smaller values = slower scroll
    
    // Sample from previous frame, shifted down to create scrolling history
    vec2 scrolledUV = uv;
    scrolledUV.y += scrollSpeed;
    
    // If we've scrolled past the top, we're in the "new data" region
    if (scrolledUV.y >= 1.0) {
        // New data region - sample from audio FFT texture
        // Use a thin horizontal band at the top for new waveform data
        O = texture(iChannel1, vec2(uv.x, 0.5));  // Sample audio across the band
        O *= 0.9;  // Slight decay to create ghosting effect
    } else {
        // History region - sample scrolled previous frame
        O = texture(iChannel0, scrolledUV);
        O *= 0.95;  // Fade the history slightly each frame
    }
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
