#version 330 core

// Sonic Nebula - Audio-Reactive Nebula Effect
// Converted for OneOffRender system

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

void main() {
    // Screen coordinates to UV with Y-flip for correct orientation
    vec2 FC = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);

    // === TWEAKABLE PARAMETERS ===
    const float ROTATION_SPEED1 = 0.3;     // Base rotation speed 1
    const float ROTATION_SPEED2 = 0.2;     // Base rotation speed 2
    const float BASS_ROTATION_MULT = 2.0;   // How much bass affects rotation
    const float TREBLE_ROTATION_MULT = 1.5; // How much treble affects rotation

    const float ANIMATION_SPEED = 0.5;      // Overall animation speed
    const float LOOP_COUNT = 80.0;          // Ray marching iterations
    const float FRACTAL_START = 4.0;        // Fractal noise start scale
    const float FRACTAL_END = 100.0;        // Fractal noise end scale
    const float FRACTAL_MULT = 1.7;         // Fractal scale multiplier

    const float COLOR_INTENSITY = 0.008;    // Base color intensity
    const float AUDIO_COLOR_MULT = 0.5;     // How much audio affects colors
    const float COLOR_SCALE = 0.3;          // Color pattern scale
    const float COLOR_SPEED = 0.5;          // Color animation speed
    const float COLOR_TREBLE_MULT = 4.0;    // Treble effect on colors

    const float BRIGHTNESS = 0.6;           // Base brightness
    const float BASS_BRIGHTNESS_MULT = 0.2; // Bass effect on brightness
    const float GAMMA = 0.8;                // Gamma correction (lower = more vibrant)
    const float PULSE_SPEED = 2.0;          // Pulse animation speed
    const float PULSE_AUDIO_MULT = 5.0;     // Audio effect on pulsing
    // === END PARAMETERS ===

    vec2 r = iResolution.xy;
    vec2 uv = (2.0*FC - r)/r.y;
    float t = iTime;
    
    // Audio input processing - fixed sampling to avoid vertical artifacts
    float audio = texture(iChannel0, vec2(0.5, 0.25)).x;  // Use fixed position instead of uv-based
    float bass = texture(iChannel0, vec2(0.2, 0.25)).x;
    float treble = texture(iChannel0, vec2(0.7, 0.25)).x;
    
    // Initial setup
    vec4 o = vec4(0);
    vec3 col = vec3(0);

    // Create swirling nebula effect with audio modulation
    for(float i=0., z=0.1, d, s; i<LOOP_COUNT; i++) { // Start z at 0.1 instead of 0
        vec3 p = z * normalize(vec3(uv, 1.0));

        // Static transformations - removed audio reactivity to prevent shaking
        float a1 = t*ROTATION_SPEED1;
        p.xy *= mat2(cos(a1), -sin(a1), sin(a1), cos(a1));

        float a2 = t*ROTATION_SPEED2;
        p.yz *= mat2(cos(a2), -sin(a2), sin(a2), cos(a2));

        p.z += t*ANIMATION_SPEED; // Remove audio modulation from position

        // Fractal noise layers - remove bass from position calculation
        for(d=FRACTAL_START; d<FRACTAL_END; d*=FRACTAL_MULT) {
            p += sin(p.yzx*d - t*ANIMATION_SPEED)/d; // Remove bass*3.0
        }

        // Fixed assignment - remove audio from position-dependent calculation
        s = 0.4 - abs(p.y); // Remove audio*0.1
        d = max(0.01, 0.01 + abs(s)/5.0); // Prevent d from being too small
        z += d;

        // Color with audio modulation - brighter and more vibrant
        vec3 layer = (cos(p/COLOR_SCALE + t*COLOR_SPEED - vec3(0,1,2) + bass*BASS_ROTATION_MULT) + 1.0)*0.5;
        layer *= 0.5 + 0.5*sin(vec3(1,2,3) + t*0.7 + treble*COLOR_TREBLE_MULT);

        // Increase intensity and add contrast
        float intensity = COLOR_INTENSITY / (1.0 + abs(s) + audio*AUDIO_COLOR_MULT);
        col += layer * layer * intensity / max(d * max(z, 0.1), 0.01); // Square layer for more contrast
    }

    // Final color processing - more vibrant
    col = pow(col, vec3(GAMMA)); // Gamma correction for more vibrant colors
    o.rgb = col * (BRIGHTNESS + bass*BASS_BRIGHTNESS_MULT); // Brighter base
    o.a = 1.0;

    // Subtle pulsing - removed audio reactivity to prevent shaking
    o.rgb *= 0.95 + 0.05*sin(t*PULSE_SPEED);

    fragColor = o;
}