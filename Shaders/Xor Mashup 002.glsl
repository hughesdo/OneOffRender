#version 330 core

// Mashup Created by PAEz in 2025-08-14
// https://www.shadertoy.com/view/WXVSWt
//
// This one is a mix of Radial and Siri by Xor
//
// https://x.com/XorDev/status/1955363029505413337
// https://x.com/XorDev/status/1950328339241316751
//
// Converted for OneOffRender system

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;


//======================================================================
//
//               CONFIGURABLE SHADER PARAMETERS
//
//======================================================================

// --- Camera & Raymarching ---
#define INITIAL_ROTATION     vec2(3.14159, -1.5708) // Initial camera angles (yaw, pitch)
#define FIELD_OF_VIEW        0.7                    // Camera field of view
#define MAX_STEPS            200                    // Max iterations for the raymarcher
#define MAX_DIST             200.0                  // Max render distance
#define HIT_THRESHOLD        0.0001                 // Precision threshold for a surface hit

// --- Shape & Animation ---
#define TIME_SPEED           0.5                    // Speed of the fractal animation
#define FEEDBACK_STRENGTH    0.30                    // Feedback amount for rotational chaos
#define ROTATION_VECTOR      vec3(0.0, 2.0, 4.0)    // Base vector for fractal rotation

// --- SDF (Signed Distance Function) ---
#define SPHERE_RADIUS        14.30                  // Outer boundary sphere radius
#define INNER_FRACTAL_RADIUS 8.5                    // Inner fractal core radius
#define FRACTAL_COMPLEXITY   0.91                    // Controls fractal detail; can be a float
#define FRACTAL_SCALE        0.5                    // Scale of the fractal pattern
#define FRACTAL_DETAIL_FACTOR 0.5                   // Multiplier for fractal surface noise
#define SDF_CLAMP            0.06                    // Clamps the minimum fractal distance
#define SHELL_OFFSET         1.0                    // Offset for the outer glowing shell
#define SHELL_FUZZ           0.2                    // Softness/thickness of the shell
#define DISTANCE_SCALE       0.20                    // Global scaler for the final distance estimation

// --- Color & Rendering ---
#define COLOR_FREQ           0.20                    // Frequency for the color pattern
#define COLOR_PHASE          vec4(0.0, 2.0, 4.0, 0.0) // Phase shift for color channels
#define GLOW_BRIGHTNESS      3.0                    // Brightness of the interior glow
#define TONE_MAP_SCALE       30000.0                // Tonemapping divisor to prevent over-exposure

// --- Background ---
#define BACKGROUND_LOOP_COUNT     6.0               // Number of concentric rings to draw
#define BACKGROUND_RING_SCALE     1.5               // Overall scale of the rings
#define BACKGROUND_RING_DENSITY   51.0              // Spacing between the rings
#define BACKGROUND_RING_WIDTH     2.02              // Thickness of the rings
#define BACKGROUND_ARM_COUNT      3.0               // Number of spiral arms
#define BACKGROUND_ARM_MASK_WIDTH 14.0               // Softness/width of the spiral arms
#define BACKGROUND_COLOR_OFFSET   vec4(0.0, 0.2, 0.5, 0.0) // Color phase for the background pattern
#define BACKGROUND_ATTENUATION    0.5               // How much the background is dimmed by the foreground

// --- Audio Reactivity ---
#define AUDIO_BASS_INFLUENCE     0.3                // How much bass affects the fractal
#define AUDIO_MID_INFLUENCE      0.15               // How much mids affect rotation speed
#define AUDIO_BRIGHTNESS_BOOST   0.2                // Audio brightness multiplier

//======================================================================
//
//                          MAIN SHADER LOGIC
//
//======================================================================

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    //------------------------------------------------------------------
    // AUDIO SAMPLING
    //------------------------------------------------------------------
    float bass = texture(iChannel0, vec2(0.1, 0.0)).x;
    float mid = texture(iChannel0, vec2(0.4, 0.0)).x;
    float kick = texture(iChannel0, vec2(0.02, 0.0)).x;
    
    // Gentle audio enhancement
    bass = bass * AUDIO_BASS_INFLUENCE;
    mid = mid * AUDIO_MID_INFLUENCE;
    kick = pow(kick, 2.0) * AUDIO_BRIGHTNESS_BOOST;
    
    //------------------------------------------------------------------
    // 1. CAMERA SETUP
    //------------------------------------------------------------------
    
    // Set camera orientation based on a fixed initial rotation
    vec2 rot = INITIAL_ROTATION;
    vec3 camPos = vec3(cos(rot.x)*cos(rot.y), sin(rot.y), sin(rot.x)*cos(rot.y)) * 25.0;
    
    // Define camera basis vectors (forward, right, up)
    vec3 camTarget = vec3(0.0);
    vec3 camDir = normalize(camTarget - camPos);
    vec3 camRight = normalize(cross(vec3(0.0, 1.0, 0.0), camDir));
    vec3 camUp = cross(camDir, camRight);

    // Calculate the direction of the ray for this fragment
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 rayDir = normalize(uv.x * camRight + uv.y * camUp + FIELD_OF_VIEW * camDir);

    //------------------------------------------------------------------
    // 2. RAYMARCHING LOOP
    //------------------------------------------------------------------
    float totalDist = 0.0;
    float s = 0.0;
    vec3 p, a;
    vec4 accumulatedColor = vec4(0.0);

    for (int i = 0; i < MAX_STEPS; i++) {
        p = camPos + totalDist * rayDir;

        // Animate and apply rotational transformation to the space
        // Add subtle audio modulation to rotation speed and feedback
        float audioTimeSpeed = TIME_SPEED * (1.0 + mid);
        float audioFeedback = FEEDBACK_STRENGTH * (1.0 + bass * 0.5);
        
        a = normalize(cos(ROTATION_VECTOR - iTime * audioTimeSpeed + s * audioFeedback));
        p = dot(a, p) * a - cross(a, p);
        s = length(p);

        // --- SDF: Calculate distance to the scene ---
        float distSphere = s - SPHERE_RADIUS;
        float distFractal = s - INNER_FRACTAL_RADIUS;

        // --- Calculate fractal detail with fractional complexity ---
        float fractalDetail = 0.0;
        vec3 iter_p = p;

        // Get the whole and fractional parts of the complexity value
        int full_iterations = int(FRACTAL_COMPLEXITY);
        float blend_factor = fract(FRACTAL_COMPLEXITY);

        // Calculate detail for the "floor" complexity level
        for (int j = 0; j < full_iterations; j++) {
            iter_p = dot(a, iter_p) * a - cross(a, iter_p);
            fractalDetail += abs(dot(iter_p, sin(iter_p * FRACTAL_SCALE).yzx));
        }

        // Calculate detail for the "ceiling" complexity level
        iter_p = dot(a, iter_p) * a - cross(a, iter_p);
        float nextIterationDetail = fractalDetail + abs(dot(iter_p, sin(iter_p * FRACTAL_SCALE).yzx));

        // Smoothly interpolate (mix) between the two detail levels
        fractalDetail = mix(fractalDetail, nextIterationDetail, blend_factor);

        // Normalize the accumulated detail
        if (FRACTAL_COMPLEXITY > 0.0) {
            fractalDetail = (fractalDetail / (floor(FRACTAL_COMPLEXITY) + blend_factor)) * FRACTAL_DETAIL_FACTOR;
        } else {
            fractalDetail = 0.0;
        }
        
        // --- Combine distances to form the final shape ---
        float finalDist = min(
            fractalDetail + max(distFractal, SDF_CLAMP),
            abs(distSphere - SHELL_OFFSET) + SHELL_FUZZ
        ) * DISTANCE_SCALE;

        // --- Step forward and accumulate color ---
        totalDist += finalDist;
        if (finalDist > 0.0) {
            vec4 glow = vec4(GLOW_BRIGHTNESS / (s * s));
            // Add subtle bass modulation to color pattern
            vec4 pattern = cos(p.x * COLOR_FREQ + COLOR_PHASE + bass * 2.0);
            accumulatedColor += max(pattern, glow) / (finalDist * finalDist);
        }

        // Exit loop if the ray hits a surface or goes too far
        if (totalDist > MAX_DIST || finalDist < HIT_THRESHOLD) {
            break;
        }
    }

    //------------------------------------------------------------------
    // 3. BACKGROUND GENERATION
    //------------------------------------------------------------------
    vec4 bgColor = vec4(0.0);
    float t = iTime;
    for (float i = 0.0; i < BACKGROUND_LOOP_COUNT; i++) {
        // Convert ray direction to spherical coordinates
        float phi = acos(rayDir.y); // Polar angle
        float ang = atan(rayDir.x, rayDir.z); // Azimuthal angle

        // Create concentric rings
        float dist = (phi / 3.1415926535) * BACKGROUND_RING_SCALE;
        float a = dist - i * i / BACKGROUND_RING_DENSITY;
        float ringShape = BACKGROUND_RING_WIDTH / (max(a, -a * 4.0) + 0.001);

        // Create spiral arms
        a = ang * BACKGROUND_ARM_COUNT + t * sin(i * i) + i * i;
        float armMask = smoothstep(0.0, BACKGROUND_ARM_MASK_WIDTH, cos(a));
        
        // Color the patterns and accumulate
        vec4 color = 1.0 + sin(a - i + BACKGROUND_COLOR_OFFSET);
        bgColor += ringShape * armMask * color;
    }

    //------------------------------------------------------------------
    // 4. FINAL COMPOSITION
    //------------------------------------------------------------------
    
    // Apply tonemapping to both foreground and background
    vec4 final3D = tanh(accumulatedColor / TONE_MAP_SCALE);
    vec4 finalBG = tanh(bgColor);

    // Attenuate the background where the foreground object is bright
    float attenuation = exp(-length(final3D.rgb) * BACKGROUND_ATTENUATION);
    
    fragColor = final3D + finalBG * attenuation;
    
    // Apply subtle audio brightness boost
    fragColor *= (1.0 + kick);
    fragColor.a = 1.0;
}