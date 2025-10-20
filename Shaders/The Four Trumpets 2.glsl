#version 330 core
// ============================================================================
// MAIN IMAGE - Display Buffer A Output
// ============================================================================

out vec4 fragColor;

// Uniforms
uniform vec2 iResolution;      // Resolution
uniform float iTime;           // Time (unused but available)
uniform sampler2D iChannel0;   // Audio FFT texture (unused in main image)
uniform sampler2D iChannel1;   // Buffer A output

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = fragCoord / iResolution.xy;
    vec3 col = texture(iChannel1, uv).rgb; // Display Buffer A output
    fragColor = vec4(col, 1.0);
}
