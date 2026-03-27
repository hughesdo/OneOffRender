#version 330 core

/*
    "Waveform" by @XorDev

    I wish Soundcloud worked on ShaderToy again

    Converted to OneOffRender format with Buffer A for scrolling trails effect
*/

out vec4 fragColor;

// Uniforms
uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0; // Buffer A output (scrolling waveform history)
uniform sampler2D iChannel1; // Audio texture (unused in image shader)

void mainImage(out vec4 O, vec2 I)
{
    // Y-flip to match Shadertoy coordinate system
    I.y = iResolution.y - I.y;

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

        // EXACT original ShaderToy code
        // Sample scrolling waveform from Buffer A with varying y for depth effect
        p.y += r + r - 4.0 * texture(iChannel0, vec2((p.x + 6.5) / 15.0, (-p.z - 3.0) * 5e1 / R.y)).r;

        // Step forward (reflections are softer)
        z += d = .1 * (.1 * r + abs(p.y) / (1.0 + r + r + r * r)
                       + max(d = p.z + 3.0, -d * .1));
    }

    // Tanh tonemapping
    O = tanh(O / 9e2);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
