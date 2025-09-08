#version 330 core

// Base Vortex - Audio-Reactive Tunnel Effect
// Converted for OneOffRender system

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

// 2D rotation matrix function
mat2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

void main() {
    // Screen coordinates to UV with Y-flip for correct orientation
    vec2 FC = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 r = iResolution.xy;
    float t = iTime;
    
    // Improved audio input processing - sample from consistent positions
    float audio = texture(iChannel0, vec2(0.25, 0.0)).x; // Fixed sample position
    float bass = texture(iChannel0, vec2(0.1, 0.0)).x;
    float mid = texture(iChannel0, vec2(0.5, 0.0)).x;
    
    // Smooth and clamp audio to prevent extreme values
    audio = smoothstep(0.0, 1.0, audio) * 0.5; // Limit audio influence
    bass = smoothstep(0.0, 1.0, bass) * 0.3;   // Limit bass influence
    mid = smoothstep(0.0, 1.0, mid) * 0.2;
    
    // Add some temporal smoothing to prevent flickering
    float audioSmooth = audio * 0.7 + sin(t * 0.5) * 0.1;
    float bassSmooth = bass * 0.8 + sin(t * 0.3) * 0.1;
    
    vec4 o = vec4(0);
    for(float i=0., z=0., d, s; i++<1e2;) {
        vec3 p = z * normalize(vec3(FC.xy*2.-r, r.y));

        // Audio-reactive distortion with reduced influence
        p.xy *= rotate2D(t*.5 + bassSmooth*1.5);
        p.xz *= rotate2D(t*.3 + audioSmooth*0.8);

        // Create tunnel structure with controlled audio influence
        for(d=4.; d<1e2; d+=d) {
            p += sin(p.yzx*d - t*2. + bassSmooth*2.0)/d;
        }

        // Prevent extreme distortion that causes blanking
        z += d = .005 + abs(s=.3-abs(p.y + audioSmooth*.1))/4.;

        // More stable color calculation
        vec4 col = (cos(s/.1+p.x+t-vec4(0,1,2,3)-3.)+1.5) *
                   exp(s*9. - audioSmooth*1.5)/d; // Reduced audio influence on brightness

        // Smoother color modulation
        col.rgb *= .6+.4*sin(vec3(1,2,3)+t+bassSmooth*3.0 + mid*2.0);

        // Ensure minimum brightness to prevent complete blanking
        col = max(col, vec4(0.01));

        o += col;
    }

    // Final output with controlled audio influence
    o = tanh(o*o/2e8 * (1.2 + bassSmooth*.3));

    // Ensure output doesn't go completely black
    o = max(o, vec4(0.02, 0.01, 0.01, 0.0));

    fragColor = o;
}