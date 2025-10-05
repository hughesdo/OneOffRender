#version 330 core

/*
    "Molten Heart with Speak Overlay"
    Combines "Molten Heart of a Techno God" as background with "Speak" shader on top
    https://x.com/XorDev/status/1950246183219175512
    https://shadertoy.com/view/33tSzl

    <512 playlist: https://www.shadertoy.com/playlist/N3SyzR

    Its ALL Xor!  Bow to Xor!
*/

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

void main()
{
    vec2 I = gl_FragCoord.xy;
    // Fix Y-coordinate flip for OneOffRender compatibility
    I.y = iResolution.y - I.y;

    /*
    ================================================
    SECTION 1: VARIABLE DECLARATIONS & TIME
    ================================================
    */
    float t = iTime;
    float z;  // Current distance along our ray
    float d;  // Step distance
    float s;  // Signed distance
    float i;  // Loop counter
    
    /* 
    ================================================
    SECTION 2: AUDIO SAMPLING & SMOOTHING
    ================================================
    */
    float bass = 0.0;
    float treble = 0.0;
    
    // Sample audio at current time (x=0.5)
    bass = texture(iChannel0, vec2(0.1, 0.0)).r;
    treble = texture(iChannel0, vec2(0.9, 0.0)).r;
    
     
    // Process audio with smoothstep for natural response
    bass = smoothstep(0.0, 1.0, bass * 1.2);
    treble = smoothstep(0.0, 1.0, treble * 0.75);
    
    /* 
    ================================================
    SECTION 3: BACKGROUND (MOLTEN HEART) SETUP
    ================================================
    */
    float baseRadius_bg = 3.0 + bass * 0.74;
    float ringWidth_bg = 0.1 + bass * 0.025;
    
    vec4 colorShift_bg = vec4(
        3.0,                  // RED offset
        8.5 + treble * 0.03,  // GREEN offset
        1.0 + treble * 0.05,  // BLUE offset
        0.0                   // ALPHA
    );
    
    // Background output
    vec4 O_bg = vec4(0);
    
    /* 
    ================================================
    SECTION 4: BACKGROUND (MOLTEN HEART) RAYMARCHING
    ================================================
    */
    // Raymarch 50 steps for background
    for(i = 0.0; i < 50.0; i++)
    {
        // Sample point (from ray direction)
        vec3 p = z * normalize(vec3(I + I, 0) - iResolution.xyy);
        // CRITICAL: Move camera BACK 5.0 units (larger z = farther away)
        p.z += 5.0;
        
        // Rotation axis
        vec3 a = normalize(cos(vec3(5, 0, 1) + t * 0.1 - d * 4.0));
        
        // Rotated coordinates
        a = a * dot(a, p) - cross(a, p);
        
        // Turbulence loop with bass reactivity
        for(d = 1.0; d++ < 9.0;)
        {
            a -= sin(a * d + t).zxy / d + bass * 0.015;
            a += sin(a * d + t).zxy / d + 0.1 + bass * 0.045;
        }
        
        // Distance to ring
        float ringDist = ringWidth_bg * abs(length(p) - 3.8);
        
        // Spherical detail
        s = length(a) - baseRadius_bg - sin(texture(iChannel0, vec2(1, s) * 0.1).r / 0.1);
        float sphereDist = 0.01 * abs(cos(s));
        
        // Raymarching step
        d = ringDist + sphereDist;
        z += d;
        
        // Color calculation
        O_bg += (cos(s + colorShift_bg) + 1.00) / d;
    }
    
    // Apply tonemapping to background
    O_bg = tanh(O_bg / 5000.0);
    
    /* 
    ================================================
    SECTION 5: FOREGROUND (SPEAK) SETUP
    ================================================
    */
    float baseRadius_fg = 3.0 + bass * 0.6;
    float sphereThickness_fg = 0.1 + bass * 0.02;
    
    vec4 colorShift_fg = vec4(
        6.0,                  // RED offset
        1.0 + treble * 0.04,  // GREEN offset
        2.0 + treble * 0.06,  // BLUE offset
        0.0                   // ALPHA
    );
    
    // Foreground output
    vec4 O_fg = vec4(0);
    z = 0.0; // Reset raymarch depth
    i = 0.0; // Reset iterator
    
    /* 
    ================================================
    SECTION 6: FOREGROUND (SPEAK) RAYMARCHING (FIXED)
    ================================================
    */
    for(O_fg *= i; i++ < 60.0; O_fg += (cos(i * 0.1 + t + colorShift_fg) + 1.0) / d)
    {
        // Sample point (from ray direction)
        vec3 p = z * normalize(vec3(I + I, 0) - iResolution.xyy),
        // Rotation axis
        a = normalize(cos(vec3(0, 2, 4) + t + 0.1 * i));
        // CRITICAL FIX #1: Move camera BACK 3.0 units (smaller z = closer camera)
        p.z += 7.0,
        // Rotated coordinates
        a = a * dot(a, p) - cross(a, p);
        
        // Turbulence loop with bass reactivity
        for(d = 0.6; d < 9.0; d += d) {
            a -= cos(a * d + t - 0.1 * i).zxy / d + bass * 0.1;
        }
        
        // Distance to hollow, distorted sphere with audio reactive parameters
        s = length(a) - baseRadius_fg - sin(texture(iChannel0, vec2(1, s) * 0.1).r / 0.1);
        z += d = sphereThickness_fg * abs(s);
    }
    
    // Apply tonemapping to foreground
    //O_fg = vec4(0.,0,0,0);
    O_fg = tanh(O_fg / 3000.0);
    
    /* 
    ================================================
    SECTION 7: LAYER BLENDING & FINAL OUTPUT
    ================================================
    */
    // Blend the layers with proper transparency
    // The foreground naturally has transparency from raymarching
    vec4 O = O_bg * (1.0 - min(length(O_fg), 0.)) + O_fg;

    // Add a subtle bass pulse effect to the entire composition
    O *= 1.0 + bass * 0.2;

    fragColor = O;
}