#version 330 core

// Petal Drift — drifting Gaussian petals with gentle lighting (Audio Reactive)
// Influences acknowledged: ideas from Inigo Quilez (analytic gradients), P_Malin (color sensibility), BigWings (motion layering concepts). Original implementation.

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// ===== TWEAKABLE PARAMETERS =====

// Animation speeds
const float GLOBAL_ROTATION_SPEED = 0.21;     // Overall scene rotation
const float RING1_ROTATION_SPEED = -0.25;     // First petal ring rotation (negative = clockwise)
const float RING2_ROTATION_SPEED = 0.18;      // Second petal ring rotation (positive = counter-clockwise)
const float PETAL_ANIMATION_SPEED = 0.35;     // Individual petal animation
const float CENTRAL_GLOW_SPEED = 0.2;         // Central glow pulsing

// Ring properties
const float RING1_BASE_RADIUS = 0.38;         // First ring base radius
const float RING1_RADIUS_VARIATION = 0.07;    // How much the radius oscillates
const float RING2_BASE_RADIUS = 0.66;         // Second ring base radius
const float RING2_RADIUS_VARIATION = 0.06;    // How much the radius oscillates
const int RING1_PETAL_COUNT = 14;             // Number of petals in first ring
const int RING2_PETAL_COUNT = 9;              // Number of petals in second ring

// Petal appearance
const float RING1_MIN_SHARPNESS = 18.0;       // Minimum petal sharpness (higher = smaller)
const float RING1_MAX_SHARPNESS = 42.0;       // Maximum petal sharpness
const float RING2_MIN_SHARPNESS = 14.0;       // Second ring min sharpness
const float RING2_MAX_SHARPNESS = 30.0;       // Second ring max sharpness
const float RING1_BASE_WEIGHT = 0.8;          // Base brightness of first ring petals
const float RING1_WEIGHT_VARIATION = 0.2;     // Brightness variation
const float RING2_BASE_WEIGHT = 0.7;          // Base brightness of second ring petals
const float RING2_WEIGHT_VARIATION = 0.3;     // Brightness variation

// Central glow
const float CENTRAL_GLOW_BASE_SHARPNESS = 10.0;   // Base sharpness of central glow
const float CENTRAL_GLOW_VARIATION = 6.0;         // How much it varies
const float CENTRAL_GLOW_INTENSITY = 0.55;        // Overall intensity

// Lighting
const vec3 LIGHT_DIRECTION = vec3(0.35, 0.42, 1.0);   // Light source direction
const float HIGHLIGHT_POWER = 24.0;                   // Specular highlight sharpness
const float HIGHLIGHT_INTENSITY = 0.25;               // Specular highlight strength
const vec3 HIGHLIGHT_COLOR = vec3(0.8, 0.85, 0.9);    // Specular highlight tint

// Color palette (custom palette)
const vec3 PALETTE_A = vec3(0.5, 0.5, 0.5);           // Base color
const vec3 PALETTE_B = vec3(0.5, 0.5, 0.5);           // Amplitude
const vec3 PALETTE_C = vec3(1.0, 1.0, 1.0);           // Frequency
const vec3 PALETTE_D = vec3(0.00, 0.33, 0.67);        // Phase

// Post-processing
const float FIELD_MULTIPLIER = 4.0;           // Overall field intensity
const float AMBIENT_LIGHT = 0.60;             // Base lighting level
const float DIRECTIONAL_LIGHT = 0.40;         // Directional lighting contribution
const float VIGNETTE_STRENGTH = 0.28;         // Edge darkening
const float VIGNETTE_POWER = 1.25;            // Vignette falloff curve

// Audio reactivity
const float AUDIO_BASS_SENSITIVITY = 0.3;     // How much bass affects central glow
const float AUDIO_MID_SENSITIVITY = 0.2;      // How much mids affect petal animation
const float AUDIO_HIGH_SENSITIVITY = 0.15;    // How much highs affect petal sharpness
const float AUDIO_GLOBAL_SENSITIVITY = 0.1;   // How much overall audio affects rotation
const float AUDIO_RING_SENSITIVITY = 0.25;    // How much audio affects ring radius
const float AUDIO_WEIGHT_SENSITIVITY = 0.2;   // How much audio affects petal brightness
const float AUDIO_SMOOTH_FACTOR = 0.7;        // Audio smoothing (0=raw, 1=very smooth)
const float BASS_HIT_THRESHOLD = 0.7;         // Bass level needed to trigger palette change
const float PALETTE_HOLD_TIME = 0.5;          // How long to hold new palette (seconds)

// Color palettes (7 different palettes that cycle on bass hits)
const vec3 PALETTE_1_A = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_1_B = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_1_C = vec3(1.0, 1.0, 1.0);   const vec3 PALETTE_1_D = vec3(0.00, 0.33, 0.67);
const vec3 PALETTE_2_A = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_2_B = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_2_C = vec3(1.0, 1.0, 1.0);   const vec3 PALETTE_2_D = vec3(0.00, 0.10, 0.20);
const vec3 PALETTE_3_A = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_3_B = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_3_C = vec3(1.0, 1.0, 1.0);   const vec3 PALETTE_3_D = vec3(0.30, 0.20, 0.20);
const vec3 PALETTE_4_A = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_4_B = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_4_C = vec3(1.0, 1.0, 0.5);   const vec3 PALETTE_4_D = vec3(0.80, 0.90, 0.30);
const vec3 PALETTE_5_A = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_5_B = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_5_C = vec3(1.0, 0.7, 0.4);   const vec3 PALETTE_5_D = vec3(0.00, 0.15, 0.20);
const vec3 PALETTE_6_A = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_6_B = vec3(0.5, 0.5, 0.5);   const vec3 PALETTE_6_C = vec3(2.0, 1.0, 0.0);   const vec3 PALETTE_6_D = vec3(0.50, 0.20, 0.25);
const vec3 PALETTE_7_A = vec3(0.8, 0.5, 0.4);   const vec3 PALETTE_7_B = vec3(0.2, 0.4, 0.2);   const vec3 PALETTE_7_C = vec3(2.0, 1.0, 1.0);   const vec3 PALETTE_7_D = vec3(0.00, 0.25, 0.25);

// ===== END TWEAKABLE PARAMETERS =====

const float TAU = 6.28318530718;

mat2 R(float a){ 
    float s=sin(a), c=cos(a); 
    return mat2(c,-s,s,c); 
}

vec3 pal3(float t, vec3 a, vec3 b, vec3 c, vec3 d){ 
    return a + b*cos(TAU*(c*t + d)); 
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;
    
    // Sample audio data from different frequency ranges
    float bassLevel = texture(iChannel0, vec2(0.1, 0.25)).x;
    float midLevel = texture(iChannel0, vec2(0.3, 0.25)).x;
    float highLevel = texture(iChannel0, vec2(0.7, 0.25)).x;
    float globalLevel = texture(iChannel0, vec2(0.5, 0.25)).x;
    
    // Detect bass hits for palette switching using a simple approach
    float rawBass = texture(iChannel0, vec2(0.05, 0.25)).x;
    
    // Create a simple palette selector that only changes when bass is very high
    // and changes slowly to avoid rapid switching
    float bassBoost = smoothstep(BASS_HIT_THRESHOLD, BASS_HIT_THRESHOLD + 0.1, rawBass);
    float paletteFloat = floor(iTime * 0.5 + bassBoost * 10.0); // Slow base progression, fast on bass
    int paletteIndex = int(mod(paletteFloat, 7.0));
    
    // Smooth the audio data to reduce harsh jumps
    bassLevel = mix(bassLevel, texture(iChannel0, vec2(0.05, 0.25)).x, AUDIO_SMOOTH_FACTOR);
    midLevel = mix(midLevel, texture(iChannel0, vec2(0.25, 0.25)).x, AUDIO_SMOOTH_FACTOR);
    highLevel = mix(highLevel, texture(iChannel0, vec2(0.65, 0.25)).x, AUDIO_SMOOTH_FACTOR);
    globalLevel = mix(globalLevel, texture(iChannel0, vec2(0.45, 0.25)).x, AUDIO_SMOOTH_FACTOR);
    
    // Apply global rotation with subtle audio influence
    float rotationSpeed = GLOBAL_ROTATION_SPEED * (1.0 + globalLevel * AUDIO_GLOBAL_SENSITIVITY);
    uv *= R(0.08*sin(iTime*rotationSpeed));
    
    // Audio-reactive ring radii
    float audioRingMod1 = 1.0 + bassLevel * AUDIO_RING_SENSITIVITY * 0.5;
    float audioRingMod2 = 1.0 + midLevel * AUDIO_RING_SENSITIVITY * 0.3;
    float R1 = (RING1_BASE_RADIUS + RING1_RADIUS_VARIATION*sin(iTime*0.23)) * audioRingMod1;
    float R2 = (RING2_BASE_RADIUS + RING2_RADIUS_VARIATION*sin(iTime*0.17 + 1.3)) * audioRingMod2;
    
    float field = 0.0;
    vec2  grad  = vec2(0.0);
    
    // first ring with audio-reactive animation
    for(int k=0;k<RING1_PETAL_COUNT;k++){
        float t = (float(k)/float(RING1_PETAL_COUNT))*TAU;
        float audioWeight = 1.0 + midLevel * AUDIO_WEIGHT_SENSITIVITY;
        float w = (RING1_BASE_WEIGHT + RING1_WEIGHT_VARIATION*sin(iTime*PETAL_ANIMATION_SPEED + float(k)*1.13)) * audioWeight;
        vec2 pos = R1 * vec2(cos(t + iTime*RING1_ROTATION_SPEED), sin(t + iTime*RING1_ROTATION_SPEED));
        vec2 d = uv - pos;
        float audioSharp = 1.0 + highLevel * AUDIO_HIGH_SENSITIVITY;
        float sharp = mix(RING1_MIN_SHARPNESS, RING1_MAX_SHARPNESS, 0.5 + 0.5*sin(iTime*0.3 + float(k))) * audioSharp;
        float g = exp(-sharp*dot(d,d));
        field += w*g;
        grad  += -2.0*sharp*g*d*w;
    }
    
    // second ring with different audio response
    for(int k=0;k<RING2_PETAL_COUNT;k++){
        float t = (float(k)/float(RING2_PETAL_COUNT))*TAU;
        float audioWeight = 1.0 + bassLevel * AUDIO_WEIGHT_SENSITIVITY * 0.7;
        float w = (RING2_BASE_WEIGHT + RING2_WEIGHT_VARIATION*sin(iTime*0.29 + float(k)*0.91)) * audioWeight;
        vec2 pos = R2 * vec2(cos(t + iTime*RING2_ROTATION_SPEED), sin(t + iTime*RING2_ROTATION_SPEED));
        vec2 d = uv - pos;
        float audioSharp = 1.0 + highLevel * AUDIO_HIGH_SENSITIVITY * 0.8;
        float sharp = mix(RING2_MIN_SHARPNESS, RING2_MAX_SHARPNESS, 0.5 + 0.5*sin(iTime*0.27 + float(k))) * audioSharp;
        float g = exp(-sharp*dot(d,d));
        field += w*g;
        grad  += -2.0*sharp*g*d*w;
    }
    
    // central glow with strong bass response
    float audioCentralMod = 1.0 + bassLevel * AUDIO_BASS_SENSITIVITY;
    float cgSharp = (CENTRAL_GLOW_BASE_SHARPNESS + CENTRAL_GLOW_VARIATION*sin(iTime*CENTRAL_GLOW_SPEED)) / audioCentralMod;
    float cg = exp(-cgSharp*dot(uv,uv));
    float centralIntensity = CENTRAL_GLOW_INTENSITY * (1.0 + bassLevel * AUDIO_BASS_SENSITIVITY * 2.0);
    field += centralIntensity*cg;
    grad  += -2.0*cgSharp*cg*uv*centralIntensity;
    
    // normalize field
    float maxExpect = float(RING1_PETAL_COUNT + RING2_PETAL_COUNT) * 1.1;
    float h = clamp(field / maxExpect * FIELD_MULTIPLIER, 0.0, 1.0);
    
    // gentle "lighting" from analytic gradient
    vec3 N = normalize(vec3(grad, 1.0));
    vec3 L = normalize(LIGHT_DIRECTION);
    float ndl = clamp(dot(N,L), 0.0, 1.0);
    
    // Select palette based on bass hits
    vec3 palA, palB, palC, palD;
    if(paletteIndex == 0) { palA = PALETTE_1_A; palB = PALETTE_1_B; palC = PALETTE_1_C; palD = PALETTE_1_D; }
    else if(paletteIndex == 1) { palA = PALETTE_2_A; palB = PALETTE_2_B; palC = PALETTE_2_C; palD = PALETTE_2_D; }
    else if(paletteIndex == 2) { palA = PALETTE_3_A; palB = PALETTE_3_B; palC = PALETTE_3_C; palD = PALETTE_3_D; }
    else if(paletteIndex == 3) { palA = PALETTE_4_A; palB = PALETTE_4_B; palC = PALETTE_4_C; palD = PALETTE_4_D; }
    else if(paletteIndex == 4) { palA = PALETTE_5_A; palB = PALETTE_5_B; palC = PALETTE_5_C; palD = PALETTE_5_D; }
    else if(paletteIndex == 5) { palA = PALETTE_6_A; palB = PALETTE_6_B; palC = PALETTE_6_C; palD = PALETTE_6_D; }
    else { palA = PALETTE_7_A; palB = PALETTE_7_B; palC = PALETTE_7_C; palD = PALETTE_7_D; }
    
    // Apply selected palette with subtle audio-reactive hue shift
    float audioHueShift = globalLevel * 0.1;
    vec3 col = pal3(h + audioHueShift, palA, palB, palC, palD);
    
    // apply lighting and a soft highlight without hard branches
    col *= AMBIENT_LIGHT + DIRECTIONAL_LIGHT*ndl;
    float highlight = pow(ndl, HIGHLIGHT_POWER);
    col += highlight * HIGHLIGHT_COLOR * HIGHLIGHT_INTENSITY;
    
    // airy vignette
    float vig = 1.0 - VIGNETTE_STRENGTH*pow(length(uv), VIGNETTE_POWER);
    col *= vig;
    
    // final soft clamp
    col = clamp(tanh(col), 0.0, 1.0);
    fragColor = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}