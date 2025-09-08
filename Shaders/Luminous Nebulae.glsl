#version 330 core

// Luminous Nebulae with Audio-Reactive Colors
// Colors change based on treble frequencies from iChannel0

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// ===== TWEAKING VARIABLES =====
#define TREBLE_SENSITIVITY 1.0      // How responsive colors are to treble (0.5-2.0)
#define MID_TREBLE_INFLUENCE 0.3    // Mid-treble color variation strength (0.0-1.0)
#define AUDIO_INTENSITY_BOOST 0.8   // How much audio boosts nebula brightness (0.0-2.0)
#define PALETTE_BLEND_SPEED 0.5     // Speed of palette transitions (0.1-2.0)
#define GLOW_AUDIO_RESPONSE 0.5     // How much glow responds to audio (0.0-1.0)
#define HUE_SHIFT_TREBLE 0.5        // Treble hue shifting amount (0.0-1.0)
#define HUE_SHIFT_MID 0.3           // Mid-treble hue shifting amount (0.0-1.0)
#define COLOR_VARIATION_BOOST 0.1   // Extra color variation based on mid-treble (0.0-0.5)
#define NEBULA_DENSITY_MULT 1.8     // Nebula density multiplier (1.0-3.0)
#define ANIMATION_SPEED 1.0         // Overall animation speed multiplier (0.5-2.0)
// ==============================

float hash12(vec2 p){ 
    return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453123); 
}

mat2 rot(float a){ 
    float s=sin(a), c=cos(a); 
    return mat2(c,-s,s,c); 
}

float vnoise(vec2 p){
    vec2 i=floor(p);
    vec2 f=fract(p);
    vec2 u=f*f*(3.0-2.0*f);
    float a=hash12(i);
    float b=hash12(i+vec2(1,0));
    float c=hash12(i+vec2(0,1));
    float d=hash12(i+vec2(1,1));
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

float fbm(vec2 p){
    float s=0.0, a=0.5;
    mat2 m = mat2(1.8,1.2,-1.2,1.8);
    for(int i=0;i<6;i++){
        s += a*vnoise(p);
        p = m*p + 0.05;
        a *= 0.5;
    }
    return s;
}

// Cosine-based palette function
vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b * cos(6.283185 * (c * t + d));
}

// Audio analysis function
float getAudioTreble() {
    float treble = 0.0;
    // Sample high frequency range (treble) from audio texture
    for(float i = 0.7; i < 1.0; i += 0.05) {
        treble += texture(iChannel0, vec2(i, 0.25)).x;
    }
    return treble / 6.0; // Normalize
}

float getAudioMidTreble() {
    float midTreble = 0.0;
    // Sample mid-high frequency range
    for(float i = 0.5; i < 0.7; i += 0.05) {
        midTreble += texture(iChannel0, vec2(i, 0.25)).x;
    }
    return midTreble / 4.0; // Normalize
}

// Get audio-reactive palette based on treble intensity
void getAudioPalette(float treble, float midTreble, out vec3 a, out vec3 b, out vec3 c, out vec3 d) {
    // Select palette index based on treble intensity
    float paletteFloat = treble * TREBLE_SENSITIVITY * 7.99; // Scale to 0-7.99
    int paletteIndex = int(paletteFloat);
    float paletteMix = fract(paletteFloat) * PALETTE_BLEND_SPEED;
    
    // Define palettes using if/else to avoid 2D arrays
    vec3 pal_a, pal_b, pal_c, pal_d;
    vec3 next_a, next_b, next_c, next_d;
    
    // Current palette
    if (paletteIndex == 0) {
        // Classic
        pal_a = vec3(0.5, 0.5, 0.5); pal_b = vec3(0.5, 0.5, 0.5);
        pal_c = vec3(1.0, 1.0, 1.0); pal_d = vec3(0.0, 0.33, 0.67);
    } else if (paletteIndex == 1) {
        // Warm
        pal_a = vec3(0.5, 0.5, 0.5); pal_b = vec3(0.5, 0.5, 0.5);
        pal_c = vec3(1.0, 1.0, 1.0); pal_d = vec3(0.0, 0.10, 0.20);
    } else if (paletteIndex == 2) {
        // Earth
        pal_a = vec3(0.5, 0.5, 0.5); pal_b = vec3(0.5, 0.5, 0.5);
        pal_c = vec3(1.0, 1.0, 1.0); pal_d = vec3(0.30, 0.20, 0.20);
    } else if (paletteIndex == 3) {
        // Sunset
        pal_a = vec3(0.5, 0.5, 0.5); pal_b = vec3(0.5, 0.5, 0.5);
        pal_c = vec3(1.0, 1.0, 0.5); pal_d = vec3(0.80, 0.90, 0.30);
    } else if (paletteIndex == 4) {
        // Ocean
        pal_a = vec3(0.5, 0.5, 0.5); pal_b = vec3(0.5, 0.5, 0.5);
        pal_c = vec3(1.0, 0.7, 0.4); pal_d = vec3(0.0, 0.15, 0.20);
    } else if (paletteIndex == 5) {
        // Fire
        pal_a = vec3(0.5, 0.5, 0.5); pal_b = vec3(0.5, 0.5, 0.5);
        pal_c = vec3(2.0, 1.0, 0.0); pal_d = vec3(0.50, 0.20, 0.25);
    } else if (paletteIndex == 6) {
        // Neon
        pal_a = vec3(0.8, 0.5, 0.4); pal_b = vec3(0.2, 0.4, 0.2);
        pal_c = vec3(2.0, 1.0, 1.0); pal_d = vec3(0.0, 0.25, 0.25);
    } else {
        // Electric
        pal_a = vec3(0.3, 0.6, 0.8); pal_b = vec3(0.4, 0.3, 0.6);
        pal_c = vec3(1.8, 1.2, 0.8); pal_d = vec3(0.1, 0.4, 0.7);
    }
    
    // Next palette for blending
    int nextIndex = (paletteIndex + 1) % 8;
    if (nextIndex == 0) {
        next_a = vec3(0.5, 0.5, 0.5); next_b = vec3(0.5, 0.5, 0.5);
        next_c = vec3(1.0, 1.0, 1.0); next_d = vec3(0.0, 0.33, 0.67);
    } else if (nextIndex == 1) {
        next_a = vec3(0.5, 0.5, 0.5); next_b = vec3(0.5, 0.5, 0.5);
        next_c = vec3(1.0, 1.0, 1.0); next_d = vec3(0.0, 0.10, 0.20);
    } else if (nextIndex == 2) {
        next_a = vec3(0.5, 0.5, 0.5); next_b = vec3(0.5, 0.5, 0.5);
        next_c = vec3(1.0, 1.0, 1.0); next_d = vec3(0.30, 0.20, 0.20);
    } else if (nextIndex == 3) {
        next_a = vec3(0.5, 0.5, 0.5); next_b = vec3(0.5, 0.5, 0.5);
        next_c = vec3(1.0, 1.0, 0.5); next_d = vec3(0.80, 0.90, 0.30);
    } else if (nextIndex == 4) {
        next_a = vec3(0.5, 0.5, 0.5); next_b = vec3(0.5, 0.5, 0.5);
        next_c = vec3(1.0, 0.7, 0.4); next_d = vec3(0.0, 0.15, 0.20);
    } else if (nextIndex == 5) {
        next_a = vec3(0.5, 0.5, 0.5); next_b = vec3(0.5, 0.5, 0.5);
        next_c = vec3(2.0, 1.0, 0.0); next_d = vec3(0.50, 0.20, 0.25);
    } else if (nextIndex == 6) {
        next_a = vec3(0.8, 0.5, 0.4); next_b = vec3(0.2, 0.4, 0.2);
        next_c = vec3(2.0, 1.0, 1.0); next_d = vec3(0.0, 0.25, 0.25);
    } else {
        next_a = vec3(0.3, 0.6, 0.8); next_b = vec3(0.4, 0.3, 0.6);
        next_c = vec3(1.8, 1.2, 0.8); next_d = vec3(0.1, 0.4, 0.7);
    }
    
    // Blend between current and next palette
    a = mix(pal_a, next_a, paletteMix);
    b = mix(pal_b, next_b, paletteMix);
    c = mix(pal_c, next_c, paletteMix);
    d = mix(pal_d, next_d, paletteMix);
    
    // Add some variation based on mid-treble for extra color dynamics
    a += vec3(COLOR_VARIATION_BOOST) * sin(midTreble * 10.0) * midTreble;
    b *= 1.0 + midTreble * MID_TREBLE_INFLUENCE;
}

vec3 starfield(vec2 uv, float t){
    vec2 g = uv * 220.0;
    vec2 id = floor(g);
    vec2 f  = fract(g) - 0.5;
    float r = hash12(id);
    float sparkle = step(0.9975, r);
    float tw = 0.6 + 0.4*sin(t*8.0 + r*25.0);
    float fall = 1.0/(1.0 + dot(f,f)*1400.0);
    vec3 hue = mix(vec3(1.0,0.95,0.9), vec3(0.75,0.85,1.0), r);
    return hue * sparkle * tw * fall;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 R = iResolution.xy;
    vec2 uv = (fragCoord - 0.5*R)/max(R.x, R.y);
    float t = iTime * ANIMATION_SPEED;
    
    // Get audio analysis
    float treble = getAudioTreble();
    float midTreble = getAudioMidTreble();
    
    // No mouse interaction in OneOffRender
    
    // Nebula domain warp (unchanged animation)
    vec2 p = uv * 2.0;
    vec2 w1 = vec2(fbm(p*0.9 + vec2(0.0, t*0.09)),
                   fbm(p*1.0 - vec2(t*0.07, 0.0)));
    vec2 w2 = vec2(fbm(p*rot(1.3) + w1*1.5 + 0.31*t),
                   fbm(p*rot(-1.1) - w1*1.2 - 0.27*t));
    vec2 q = p + 1.10*w1 + 0.75*w2;
    
    float d1 = fbm(q*0.9 + 0.15*t);
    float d2 = fbm(q*1.7 - 0.12*t);
    float density = d1*0.7 + d2*0.6 - 0.45;
    density = smoothstep(0.0, 1.0, density*NEBULA_DENSITY_MULT);
    
    // Get audio-reactive palette
    vec3 a, b, c, d;
    getAudioPalette(treble, midTreble, a, b, c, d);
    
    // Color weaving with audio-reactive palettes
    float hueA = fract(0.35*d1 + 0.07*t + treble*HUE_SHIFT_TREBLE);
    float hueB = fract(0.45*d2 - 0.05*t + midTreble*HUE_SHIFT_MID);
    
    // Enhanced nebula with stronger audio-reactive colors
    vec3 nebA = palette(hueA, a, b, c, d);
    vec3 nebB = palette(hueB + 0.2, a*0.9, b*1.1, c*0.95, d + vec3(0.05));
    
    // Focus color changes on the smoke density
    float smokeAlpha = smoothstep(0.1, 0.8, density);
    vec3 nebula = mix(vec3(0.0), nebA*(0.8*density) + nebB*(0.6*density*density), smokeAlpha);
    
    // Add treble-reactive intensity boost
    nebula *= 1.0 + treble * AUDIO_INTENSITY_BOOST;
    
    // Clean dark background
    vec3 bgTex = vec3(0.02, 0.03, 0.05);
    
    // Stars (minimal, non-distracting)
    vec3 stars = starfield(uv + 0.2*w2 + 0.05*w1, t) * 0.3;
    
    // Focused glow only where smoke exists
    float rim = smoothstep(0.9, 0.1, length(uv));
    vec3 glowColor = palette(treble + t*0.1, a*0.7, b*0.8, c*1.1, d);
    vec3 glow = glowColor * (0.15*density*density*rim * (1.0 + treble*GLOW_AUDIO_RESPONSE));
    
    vec3 col = bgTex + nebula + glow + stars;
    
    // Gentle contrast and clamp
    col = tanh(col*1.25);
    col = clamp(col, 0.0, 1.0);

    fragColor = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}