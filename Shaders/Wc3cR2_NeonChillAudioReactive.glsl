#version 330 core

// Neon Chill - Audio Reactive
// Created by OneHung
// Original by diatribes (ID: tcXfW8)
// Audio-reactive enhancement inspired by Bigwings
// https://www.shadertoy.com/view/Wc3cR2

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    
    // Audio sampling
    float bass = texture(iChannel0, vec2(0.01, 0.25)).x;
    float mids = texture(iChannel0, vec2(0.1, 0.25)).x;
    float highs = texture(iChannel0, vec2(0.3, 0.25)).x;
    float kick = texture(iChannel0, vec2(0.0, 0.25)).x;
    
    // Smooth the audio values
    bass = smoothstep(0.0, 0.5, bass);
    mids = smoothstep(0.1, 0.6, mids);
    highs = smoothstep(0.2, 0.7, highs);
    kick = smoothstep(0.0, 0.3, kick);
    
    // Time flow
    float t = iTime * (.2 + bass * .1);
    
    // Setup coordinates
    vec3 p = vec3(iResolution, 1.0);
    u = (u + u - p.xy) / p.y;
    
    // Audio-reactive rotation
    float rotBase = length(u * (3.5 - bass * 1.5)) + mids * .5;
    u *= mat2(cos(rotBase + vec4(0, 33, 11, 0)));
    
    // Wave amplitudes modulated by audio
    float amp1 = .1 + mids * .15 + highs * .05;
    float amp2 = .2 + mids * .2 + bass * .1;
    float amp3 = .3 + bass * .2 + mids * .1;
    float amp4 = .4 + bass * .3 + kick * .2;
    
    // Line thickness responds to kick
    float thickness = 1.0 + kick * .5 + bass * .2;
    
    // Color intensity boosted by high frequencies
    float colorBoost = 1.0 + highs * .5 + mids * .2;
    
    // Build the neon waves
    vec4 wave1 = vec4(.5, .1, 2, 0) * colorBoost / 
                 (.001 * thickness * length(u.x + sin(8. * t - u.y * 1.) * amp1));
    
    vec4 wave2 = vec4(1, .1, 0, 0) * (colorBoost + highs * .3) / 
                 (.002 * thickness * length(u.x + sin(4. * t - u.y * 2.) * amp2));
    
    vec4 wave3 = vec4(1, .6, 0, 0) * (colorBoost + mids * .2) / 
                 (.003 * thickness * length(u.x + sin(3. * t - u.y * 4.) * amp3));
    
    vec4 wave4 = vec4(1, 2, 0, 0) * (colorBoost + bass * .3) / 
                 (.004 * thickness * length(u.x + sin(2. * t - u.y * 8.) * amp4));
    
    // Combine waves
    float brightness = 2e4 / (1.0 + bass * .3 + mids * .2);
    
    // Glow pulse on strong beats
    vec4 glowPulse = vec4(1, .5, 2, 0) * kick * .02;
    
    // Final composition
    o = tanh((wave1 + wave2 + wave3 + wave4) / brightness + glowPulse);
    
    // Subtle color shift based on audio energy
    float audioEnergy = (bass + mids + highs) / 3.0;
    o.rgb = mix(o.rgb, o.rbg, audioEnergy * .1);
    
    fragColor = o;
}

