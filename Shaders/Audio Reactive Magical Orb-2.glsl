#version 330 core

/*
    Audio Reactive Magical Orb-2 - OneOffRender Version
    Original orb by Chronos, edge detection mashup for bass-triggered rainbow waves
    Enhanced with object-aware lighting that makes the orb's glow stick to surfaces
    Beat-triggered rainbow waves with more colors and thickness
    Converted for OneOffRender with cubemap support
*/

// OneOffRender uniforms
uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;      // Audio texture
uniform samplerCube iChannel1;    // Cubemap texture (cobblestone_street_night)

out vec4 fragColor;

// ============ AUDIO REACTIVE ORB TWEAKING VARIABLES ============
const float ORB_BASE_RADIUS = 2.0;        // Base radius of the orb sphere
const float ORB_PULSE_AMOUNT = 1.5;       // How much orb grows/shrinks on beats
const float ORB_BOUNCE_SPEED = 5.0;       // Speed of bounce oscillation
const float ORB_BOUNCE_AMOUNT = 0.3;      // Amplitude of bounce effect
const float ORB_TURBULENCE_SPEED = 10.0;  // Speed of turbulence
const float ORB_TURBULENCE_AMOUNT = 0.2;  // Amplitude of turbulence
const float ORB_SMOOTH_FACTOR = 0.15;     // Smoothing factor (lower = smoother)
const float GLOW_INTENSITY = 8e-3;        // Volumetric glow intensity (increased 8x)
const float GLOW_AUDIO_MULT = 8.0;        // How much audio boosts glow (doubled)
const float OUTER_GLOW_INTENSITY = 0.4;   // Outer translucent glow shell intensity
const float OUTER_GLOW_FALLOFF = 3.0;     // How quickly outer glow fades
const float HUE_SHIFT_MULT = 10.0;        // Continuous hue shifting with audio
const float BASS_COLOR_JUMP = 20.0;       // Big color jumps on bass hits
const float BASS_FREQ = 0.1;              // Bass frequency sample point
const float MID_FREQ = 0.3;               // Mid frequency sample point
const float HIGH_FREQ = 0.7;              // High frequency sample point

// ============ ENVIRONMENT LIGHTING VARIABLES ============
const float CUBEMAP_BASE_DARKNESS = 0.35;     // Darker base for better contrast (was 1.0)
const float CUBEMAP_AUDIO_BOOST = 0.8;        // Continuous smooth audio brightening
const float CUBEMAP_BASS_FLASH = 2.5;         // Dramatic bass flash intensity
const float CUBEMAP_FADE_SPEED = 4.0;         // How fast bass flash fades (higher = faster)
const float CUBEMAP_SMOOTH_FACTOR = 0.12;     // Smoothing for continuous audio (lower = smoother)
const float SPOTLIGHT_STRENGTH = 6.0;         // Main spotlight beam intensity
const float SPOTLIGHT_TIGHTNESS = 25.0;       // How focused the spotlight is
const float SPOTLIGHT_SHARPNESS = 5.0;        // Directional falloff sharpness
const float AMBIENT_GLOW_STRENGTH = 0.3;      // Subtle ambient colored glow
const float RADIAL_FALLOFF_STRENGTH = 15.0;   // Screen-space radial falloff
const float DIFFUSE_SHARPNESS = 4.0;          // Physically-based directional sharpness
const float ORB_ENV_AUDIO_BOOST = 5.0;        // Extra light intensity on audio peaks
const float BASS_BRIGHTNESS_MULT = 3.0;       // Extra brightness boost on bass hits

// ============ CAMERA MOVEMENT VARIABLES ============
const float CAMERA_VERTICAL_AMPLITUDE = 0.2;  // Adjusts how far the camera moves up/down

// ============ EDGE RAINBOW WAVE VARIABLES ============
const float WAVE_SPEED_BASE = 2.0;        // Base speed for wave expansion
const float WAVE_SPEED_AUDIO_MULT = 3.0;  // How much audio affects wave speed
const float WAVE_WIDTH = 0.5;             // Width of the rainbow band (THICKER)
const float WAVE_FEATHER = 0.08;          // Soft edge on wave (slightly softer)
const float EDGE_DETECT_SCALE = 0.01;     // Scale for edge detection sampling (increased for wider surface capture)
const float EDGE_THRESHOLD = 0.10;        // Minimum edge strength to show rainbow (lowered to capture more surfaces)
const float EDGE_CONTRAST = 3.0;          // Edge detection contrast
const float RAINBOW_INTENSITY = 4.5;      // Overall rainbow brightness (BRIGHTER)
const float RAINBOW_MAX_ADD = 0.8;        // Per-channel cap on additive color
const float PERSISTENT_EDGE_GLOW = 0.2;   // Constant mild edge glow (0=off)
const float PERSISTENT_RADIUS = 0.6;      // Radius of persistent glow effect
const float WAVE_BASS_OFFSET = 0.0;       // Time offset for bass wave
const float WAVE_MID_OFFSET = 3.3;        // Time offset for mid wave
const float WAVE_HIGH_OFFSET = 6.6;       // Time offset for high wave
const float WAVE_CYCLE_LENGTH = 10.0;     // How far waves expand before cycling
const float WAVE_MIN_INTENSITY = 0.3;     // Minimum wave intensity (always visible)

const float PI = 3.14159265;

vec3 cmap1(float x) { return pow(.5+.5*cos(PI * x + vec3(1,2,3)), vec3(2.5)); }

vec3 cmap2(float x)
{
    vec3 col = vec3(.35, 1,1)*(cos(3.141592*x*vec3(1)+.75*vec3(2,1,3))*.5+.5);
    col *= col * col;
    return col;
}

vec3 cmap3(float x)
{
    vec3 yellow = vec3(1.,.9,0);
    vec3 purple = vec3(.75,0,1);
    vec3 col = mix(purple, yellow, cos(x/1.25)*.5+.5);
    col*=col*col;
    return col;
}

vec3 cmap(float x, float hueShift, float bassJump)
{
    float t = mod(iTime, 30.);
    float colorOffset = hueShift + bassJump;
    return
    (smoothstep(-1., 0., t)-smoothstep(9., 10., t)) * cmap1(x + colorOffset) + 
    (smoothstep(9., 10., t)-smoothstep(19., 20., t)) * cmap2(x + colorOffset) + 
    (smoothstep(19., 20., t)-smoothstep(29., 30., t)) * cmap3(x + colorOffset) +
    (smoothstep(29., 30., t)-smoothstep(39., 40., t)) * cmap1(x + colorOffset);
}

// Sobel edge detection on cubemap
float detectEdges(vec3 rd) {
    vec3 offset = vec3(EDGE_DETECT_SCALE);
    
    // Sample cubemap in a 3x3x3 pattern for edge detection
    vec3 c = texture(iChannel1, rd).rgb;
    
    // Sobel X
    vec3 sobelX = vec3(0.0);
    sobelX += texture(iChannel1, rd + vec3(-offset.x, -offset.y, 0)).rgb * -1.0;
    sobelX += texture(iChannel1, rd + vec3(-offset.x, 0, 0)).rgb * -2.0;
    sobelX += texture(iChannel1, rd + vec3(-offset.x, offset.y, 0)).rgb * -1.0;
    sobelX += texture(iChannel1, rd + vec3(offset.x, -offset.y, 0)).rgb * 1.0;
    sobelX += texture(iChannel1, rd + vec3(offset.x, 0, 0)).rgb * 2.0;
    sobelX += texture(iChannel1, rd + vec3(offset.x, offset.y, 0)).rgb * 1.0;
    
    // Sobel Y
    vec3 sobelY = vec3(0.0);
    sobelY += texture(iChannel1, rd + vec3(-offset.x, -offset.y, 0)).rgb * -1.0;
    sobelY += texture(iChannel1, rd + vec3(0, -offset.y, 0)).rgb * -2.0;
    sobelY += texture(iChannel1, rd + vec3(offset.x, -offset.y, 0)).rgb * -1.0;
    sobelY += texture(iChannel1, rd + vec3(-offset.x, offset.y, 0)).rgb * 1.0;
    sobelY += texture(iChannel1, rd + vec3(0, offset.y, 0)).rgb * 2.0;
    sobelY += texture(iChannel1, rd + vec3(offset.x, offset.y, 0)).rgb * 1.0;
    
    // Sobel Z
    vec3 sobelZ = vec3(0.0);
    sobelZ += texture(iChannel1, rd + vec3(0, -offset.y, -offset.z)).rgb * -1.0;
    sobelZ += texture(iChannel1, rd + vec3(0, 0, -offset.z)).rgb * -2.0;
    sobelZ += texture(iChannel1, rd + vec3(0, offset.y, -offset.z)).rgb * -1.0;
    sobelZ += texture(iChannel1, rd + vec3(0, -offset.y, offset.z)).rgb * 1.0;
    sobelZ += texture(iChannel1, rd + vec3(0, 0, offset.z)).rgb * 2.0;
    sobelZ += texture(iChannel1, rd + vec3(0, offset.y, offset.z)).rgb * 1.0;
    
    // Combine edge magnitudes
    vec3 edges = sqrt(sobelX * sobelX + sobelY * sobelY + sobelZ * sobelZ);
    float edgeStrength = dot(edges, vec3(0.299, 0.587, 0.114)); // Luminance
    
    // Apply contrast and threshold
    edgeStrength = pow(edgeStrength * EDGE_CONTRAST, 2.0);
    return smoothstep(EDGE_THRESHOLD, EDGE_THRESHOLD + 0.1, edgeStrength);
}

// Create orb-tinted rainbow palette with MORE COLORS
vec3 orbRainbow(float t, vec3 orbColor) {
    // Multi-frequency rainbow for more color bands
    vec3 rainbow = vec3(0.0);
    rainbow += 0.5 + 0.5 * cos(2.0 * PI * (t * 2.0 + vec3(0.0, 0.33, 0.67)));
    rainbow += 0.3 + 0.3 * cos(2.0 * PI * (t * 5.0 + vec3(0.2, 0.5, 0.8)));
    rainbow += 0.2 + 0.2 * cos(2.0 * PI * (t * 8.0 + vec3(0.1, 0.6, 0.9)));
    rainbow = rainbow / 2.0; // Normalize
    
    // Tint with orb color
    rainbow = mix(rainbow, orbColor, 0.3);
    rainbow *= orbColor + vec3(0.5); // Boost and add baseline
    return rainbow * rainbow * 2.0; // Enhance saturation and brightness
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;

    // Sample audio frequencies - OneOffRender convention uses y=0.0 for FFT spectrum
    float bass = texture(iChannel0, vec2(BASS_FREQ, 0.0)).x;
    float mid = texture(iChannel0, vec2(MID_FREQ, 0.0)).x;
    float high = texture(iChannel0, vec2(HIGH_FREQ, 0.0)).x;
    float audioLevel = (bass + mid + high) / 3.0;

    // Smooth audio for orb size (exponential moving average simulation using time-based smoothing)
    float smoothedAudio = audioLevel * ORB_SMOOTH_FACTOR + (1.0 - ORB_SMOOTH_FACTOR) * (0.5 + 0.5 * sin(iTime * 0.5));

    // Add turbulent bounce effect
    float bounce = sin(iTime * ORB_BOUNCE_SPEED + bass * 10.0) * ORB_BOUNCE_AMOUNT;
    float turbulence = sin(iTime * ORB_TURBULENCE_SPEED) * cos(iTime * ORB_TURBULENCE_SPEED * 0.8) * ORB_TURBULENCE_AMOUNT;

    // Combined audio-reactive orb radius with smoothing and turbulence
    float audioRadiusModulation = smoothedAudio * ORB_PULSE_AMOUNT + bounce + turbulence * audioLevel;

    // Continuous audio-reactive waves - three overlapping waves driven by different frequencies
    // Each wave expands continuously, modulated by its frequency band
    float bassWaveSpeed = WAVE_SPEED_BASE + bass * WAVE_SPEED_AUDIO_MULT;
    float midWaveSpeed = WAVE_SPEED_BASE + mid * WAVE_SPEED_AUDIO_MULT;
    float highWaveSpeed = WAVE_SPEED_BASE + high * WAVE_SPEED_AUDIO_MULT;

    // Calculate wave radii - continuous expansion with cycling
    float bassWaveRadius = mod((iTime + WAVE_BASS_OFFSET) * bassWaveSpeed, WAVE_CYCLE_LENGTH);
    float midWaveRadius = mod((iTime + WAVE_MID_OFFSET) * midWaveSpeed, WAVE_CYCLE_LENGTH);
    float highWaveRadius = mod((iTime + WAVE_HIGH_OFFSET) * highWaveSpeed, WAVE_CYCLE_LENGTH);

    // Wave intensities - always active, modulated by audio
    float bassWaveIntensity = WAVE_MIN_INTENSITY + bass * (1.0 - WAVE_MIN_INTENSITY);
    float midWaveIntensity = WAVE_MIN_INTENSITY + mid * (1.0 - WAVE_MIN_INTENSITY);
    float highWaveIntensity = WAVE_MIN_INTENSITY + high * (1.0 - WAVE_MIN_INTENSITY);

    vec2 uv = (2. * fragCoord - iResolution.xy)/iResolution.y;

    float focal = 1.;
    vec3 ro = vec3(0, 0, 6.+cos(iTime*.25)*.75);

    float time = iTime * .5;
    float c = cos(time), s = sin(time);
    ro.xz *= mat2(c,s,-s,c);

    // Add vertical oscillation: 4 full cycles per 360° rotation
    // Rotation frequency is 0.5, so vertical frequency is 2.0 (4x faster)
    ro.y += sin(iTime * 2.0) * CAMERA_VERTICAL_AMPLITUDE;

    vec3 rd = normalize(vec3(uv, -focal));
    rd.xz *= mat2(c,s,-s,c);

    vec3 color = vec3(0);

    // Calculate audio-reactive orb colors
    float hueShift = mid * HUE_SHIFT_MULT + high * 5.0;
    float bassJump = bass * BASS_COLOR_JUMP;
    vec3 orbColor = cmap(iTime, hueShift, bassJump);
    
    // Get orb position in screen space for wave origin
    vec2 orbUV = vec2(0.0); // Orb is at center

    // Dynamic audio-reactive cubemap brightness (Option 3: Hybrid approach)
    // Smooth continuous audio for breathing effect
    float smoothedCubemapAudio = audioLevel * CUBEMAP_SMOOTH_FACTOR + (1.0 - CUBEMAP_SMOOTH_FACTOR) * 0.5;

    // Bass flash with exponential decay - creates dramatic "lighting up" on bass hits
    float bassFlash = bass * CUBEMAP_BASS_FLASH * exp(-mod(iTime, 0.5) * CUBEMAP_FADE_SPEED);

    // Combine: darker base + smooth continuous audio + dramatic bass flashes
    float cubemapBrightness = CUBEMAP_BASE_DARKNESS
                            + smoothedCubemapAudio * CUBEMAP_AUDIO_BOOST
                            + bassFlash;

    // Background cubemap - now dynamically lit by music
    vec3 cubemapColor = pow(texture(iChannel1, rd).rgb, vec3(2.2));
    cubemapColor *= cubemapBrightness;

    // Detect edges in the cubemap at this pixel
    float edgeMask = detectEdges(rd);
    
    // Add surface detection - not just edges but also bright areas
    float luminance = dot(cubemapColor, vec3(0.299, 0.587, 0.114));
    float surfaceMask = smoothstep(0.1, 0.3, luminance); // Detect non-black areas
    float objectPresence = max(edgeMask, surfaceMask * 0.5); // Combine edge + surface
    
    // Create a more sophisticated surface presence
    float surfaceResponse = objectPresence * 0.8 + 0.2; // 20% base lighting + 80% on objects

    // Audio-reactive orb radius with turbulent bouncing and smoothing
    float orbRadius = ORB_BASE_RADIUS + audioRadiusModulation;

    vec3 orbPos = vec3(0, 0, 0);
    vec3 orbScreenDir = normalize(orbPos - ro);
    float angularDist = length(rd - orbScreenDir);

    float spotlightFalloff = 1.0 / (1.0 + angularDist * angularDist * SPOTLIGHT_TIGHTNESS);
    spotlightFalloff = pow(spotlightFalloff, 3.0);

    vec3 envSurfacePos = ro + rd * 50.0;
    vec3 toOrb = orbPos - envSurfacePos;
    vec3 lightDir = normalize(toOrb);
    float spotlightDirectional = pow(max(0.0, dot(lightDir, -rd)), SPOTLIGHT_SHARPNESS);

    float spotlightMask = spotlightFalloff * spotlightDirectional;

    float radialFalloff = pow(1.0 / (1.0 + angularDist * angularDist * RADIAL_FALLOFF_STRENGTH), 2.0);
    float radialDirectional = pow(max(0.0, dot(lightDir, -rd)), DIFFUSE_SHARPNESS);
    float radialMask = radialFalloff * radialDirectional;

    float distToOrb = length(toOrb);
    float ambientFalloff = 1.0 / (1.0 + distToOrb * distToOrb * 0.005);

    float baseIntensity = 1.0 + audioLevel * ORB_ENV_AUDIO_BOOST;
    float bassBrightness = 1.0 + bass * BASS_BRIGHTNESS_MULT;
    
    // Add musical modulation
    float musicPulse = 1.0 + sin(iTime * 10.0) * audioLevel * 0.3;
    float beatPulse = 1.0 + bass * 0.5 * exp(-mod(iTime, 0.5) * 5.0);
    
    // Add frequency-based color modulation
    vec3 freqColors = vec3(
        1.0 + bass * 1.5,    // Bass boosts reds
        1.0 + mid * 1.0,     // Mids boost greens  
        1.0 + high * 0.8     // Highs boost blues
    );

    // Apply surface-aware lighting
    vec3 spotlightLight = orbColor * freqColors * spotlightMask * SPOTLIGHT_STRENGTH * baseIntensity * bassBrightness * surfaceResponse * musicPulse;
    vec3 radialLight = orbColor * freqColors * radialMask * 2.0 * baseIntensity * surfaceResponse * beatPulse;
    
    // Ambient light gets less surface modulation to maintain some overall glow
    vec3 ambientLight = orbColor * ambientFalloff * AMBIENT_GLOW_STRENGTH * baseIntensity * (surfaceResponse * 0.5 + 0.5);

    cubemapColor += spotlightLight + radialLight + ambientLight;
    
    // Enhanced object-aware lighting with rim lighting effect
    float rimLight = pow(1.0 - abs(dot(lightDir, -rd)), 2.0) * objectPresence;
    vec3 objectGlow = orbColor * rimLight * baseIntensity * audioLevel * 2.0;
    cubemapColor += objectGlow;
    
    // Make empty space darker to emphasize lit objects
    if (objectPresence < 0.1) {
        cubemapColor *= 0.5; // Darken empty areas
    }
    
    // ============ CONTINUOUS AUDIO-REACTIVE EDGE RAINBOW WAVES ============
    // Only apply rainbow to detected edges
    if (edgeMask > 0.01) {
        float distFromOrb = length(uv - orbUV);
        vec3 totalWaveGlow = vec3(0.0);

        // BASS WAVE - Red/warm tinted
        {
            float waveDist = abs(distFromOrb - bassWaveRadius);
            float waveRingMask = 1.0 - smoothstep(WAVE_WIDTH * 0.5, WAVE_WIDTH * 0.5 + WAVE_FEATHER, waveDist);

            // Fade based on cycle position (fade out as wave reaches max radius)
            float cycleFade = 1.0 - smoothstep(WAVE_CYCLE_LENGTH * 0.7, WAVE_CYCLE_LENGTH, bassWaveRadius);
            waveRingMask *= cycleFade;

            // Only show on edges
            float finalWaveMask = waveRingMask * edgeMask * bassWaveIntensity;

            // Rainbow color with bass emphasis (warmer colors)
            float rainbowT = fract((distFromOrb - (bassWaveRadius - WAVE_WIDTH * 0.5)) / WAVE_WIDTH);
            vec3 rainbowColor = orbRainbow(rainbowT + 0.0, orbColor); // No offset for bass
            rainbowColor *= vec3(1.5, 1.0, 0.8); // Warm tint

            totalWaveGlow += rainbowColor * finalWaveMask * RAINBOW_INTENSITY * (1.0 + bass * 2.0);
        }

        // MID WAVE - Green/balanced tinted
        {
            float waveDist = abs(distFromOrb - midWaveRadius);
            float waveRingMask = 1.0 - smoothstep(WAVE_WIDTH * 0.5, WAVE_WIDTH * 0.5 + WAVE_FEATHER, waveDist);

            float cycleFade = 1.0 - smoothstep(WAVE_CYCLE_LENGTH * 0.7, WAVE_CYCLE_LENGTH, midWaveRadius);
            waveRingMask *= cycleFade;

            float finalWaveMask = waveRingMask * edgeMask * midWaveIntensity;

            float rainbowT = fract((distFromOrb - (midWaveRadius - WAVE_WIDTH * 0.5)) / WAVE_WIDTH);
            vec3 rainbowColor = orbRainbow(rainbowT + 0.33, orbColor); // Offset for variety
            rainbowColor *= vec3(0.9, 1.3, 0.9); // Green tint

            totalWaveGlow += rainbowColor * finalWaveMask * RAINBOW_INTENSITY * (1.0 + mid * 2.0);
        }

        // HIGH WAVE - Blue/cool tinted
        {
            float waveDist = abs(distFromOrb - highWaveRadius);
            float waveRingMask = 1.0 - smoothstep(WAVE_WIDTH * 0.5, WAVE_WIDTH * 0.5 + WAVE_FEATHER, waveDist);

            float cycleFade = 1.0 - smoothstep(WAVE_CYCLE_LENGTH * 0.7, WAVE_CYCLE_LENGTH, highWaveRadius);
            waveRingMask *= cycleFade;

            float finalWaveMask = waveRingMask * edgeMask * highWaveIntensity;

            float rainbowT = fract((distFromOrb - (highWaveRadius - WAVE_WIDTH * 0.5)) / WAVE_WIDTH);
            vec3 rainbowColor = orbRainbow(rainbowT + 0.67, orbColor); // Different offset
            rainbowColor *= vec3(0.8, 1.0, 1.5); // Cool tint

            totalWaveGlow += rainbowColor * finalWaveMask * RAINBOW_INTENSITY * (1.0 + high * 2.0);
        }

        // Apply combined wave glow with cap
        totalWaveGlow = min(totalWaveGlow, vec3(RAINBOW_MAX_ADD * 3.0)); // Higher cap for multiple waves
        cubemapColor += totalWaveGlow;

        // Persistent mild edge glow near orb (optional)
        if (PERSISTENT_EDGE_GLOW > 0.0) {
            float persistDist = length(uv - orbUV);
            float persistMask = 1.0 - smoothstep(0.0, PERSISTENT_RADIUS, persistDist);
            // Only on edges, modulated by distance
            vec3 persistColor = orbColor * edgeMask * persistMask * PERSISTENT_EDGE_GLOW * (1.0 + audioLevel);
            cubemapColor += persistColor;
        }
    }

    color += cubemapColor;

    // Original orb rendering (unchanged)
    time = iTime;
    {
        float orbRadiusSq = orbRadius * orbRadius;
        
        float t  = dot(0. - ro, rd);
        vec3 p   = t * rd + ro;
        float y2 = dot(p, p);
        float x2 = orbRadiusSq - y2;
        
        if(y2 <= orbRadiusSq)
        {
            float a = t-sqrt(x2);
            float b = t+sqrt(x2);

            color *= exp(-(b-a));

            t = a + 0.01;

            float glowMult = GLOW_INTENSITY * (1.0 + audioLevel * GLOW_AUDIO_MULT);

            for(int i = 0; i < 99 && t < b; i++)
            {
                vec3 p = t * rd + ro;

                float T = (t+time)/5.;
                float c = cos(T), s = sin(T);
                p.xy = mat2(c,-s,s,c) * p.xy;

                for(float f = 0.; f < 9.; f++)
                {
                    float a = exp(f)/exp2(f);
                    p += cos(p.yzx * a + time)/a;
                }
                
                float d = 1./100. + abs((ro -p-vec3(0,1,0)).y-1.)/10.;
                
                color += cmap(t, hueShift, bassJump) * glowMult / d;
                t += d*.25;
            }

            float R0 = 0.04;
            vec3 N = normalize(a * rd  + ro);
            float cosTheta = dot(-rd, N);
            float fresnel = R0 + (1.0 - R0) * pow(1.0 - cosTheta, 5.0);

            color *= 1.-fresnel;
            vec3 reflectionColor = pow(texture(iChannel1, reflect(rd, N)).rgb, vec3(2.2));
            reflectionColor *= cubemapBrightness;  // Use dynamic brightness for reflections too
            color += fresnel * reflectionColor;
        }

        // Add outer translucent glow shell that extends beyond the sphere surface
        // This creates a visible halo around the orb
        vec3 orbPos = vec3(0, 0, 0);
        float tGlow = dot(orbPos - ro, rd);
        vec3 closestPoint = ro + rd * tGlow;
        float distToOrb = length(closestPoint - orbPos);

        // Create glow that starts at orb surface and fades outward
        float glowDist = max(0.0, distToOrb - orbRadius);
        float outerGlow = exp(-glowDist * OUTER_GLOW_FALLOFF) * OUTER_GLOW_INTENSITY;
        outerGlow *= (1.0 + audioLevel * 2.0); // Audio-reactive intensity

        // Apply outer glow with orb color
        color += orbColor * outerGlow * (1.0 + bass * 1.5);
    }

    color = 1.-exp(-color);
    color *= 1.-dot(uv*.55,uv*.55)*.15;
    color = pow(color, vec3(1./2.2));

    color = clamp(color, 0., 1.);
    fragColor = vec4(color, 1);
}