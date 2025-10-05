/*
    "Waveform" by @XorDev
    
    I wish Soundcloud worked on ShaderToy again
*/

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;

void mainImage(out vec4 O, vec2 I)
{
    // Test 2 kept: no screen-space Y flip (matches Shadertoy math exactly)
    // I.y = iResolution.y - I.y;

    // Raymarch iterator, step distance, depth and reflection
    float i, d, z, r;

    // Clear fragcolor and raymarch 90 steps
    for (O *= i; i++ < 9e1;
         // Pick color and attenuate
         O += (cos(z * .5 + iTime + vec4(0, 2, 4, 3)) + 1.3) / d / z)
    {
        // Raymarch sample point
        vec3 R = iResolution.xyy;
        vec3 p = z * normalize(vec3(I + I, 0.0) - R);

        // Shift camera and get reflection coordinates
        r = max(-++p, 0.0).y;

        // --- TEST 3: Force sampling the waveform band (constant y) ---
        // We hold y at 0.5 so we always read waveform rows (2..255 repeated).
        // If the left-edge dip + ghost line disappear, the issue is the varying y.
        float x = (p.x + 6.5) / 15.0;
        float y = 0.5;  // waveform band center
        p.y += r + r - 4.0 * texture(iChannel0, vec2(x, y)).r;

        // Step forward (reflections are softer)
        z += d = .1 * (.1 * r + abs(p.y) / (1.0 + r + r + r * r)
                       + max(d = p.z + 3.0, -d * .1));
    }

    // Tanh tonemapping
    O = tanh(O / 9e2);
}

void main() {
    vec4 fragColor;
    mainImage(fragColor, gl_FragCoord.xy);
    gl_FragColor = fragColor;
}
