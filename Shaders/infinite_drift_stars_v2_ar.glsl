// ============================================================
// Infinite Drift — Smooth Scrolling Starfield v2
// Audio-reactive glow on select stars only
// For oneoff.py — iChannel0 = audio texture
//
// Color palette: magenta → purple → blue → cyan → green
// Scrolls diagonally (X+Y) continuously. Never jolts.
// Some stars "click" into brightness with the music.
// ============================================================

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;

// -------------------- TWEAKABLES ----------------------------
#define SCROLL_SPEED_X     0.55     // horizontal drift (cells/sec)
#define SCROLL_SPEED_Y     0.35     // vertical drift (cells/sec)

#define NUM_LAYERS         6        // depth layers
#define STAR_DENSITY       0.88     // 0-1, higher = more stars
#define BASE_STAR_SIZE     0.025    // dim star radius
#define BRIGHT_STAR_SIZE   0.055    // brighter star radius
#define BASE_BRIGHTNESS    1.2      // dim star brightness floor
#define TWINKLE_SPEED      1.2      // idle shimmer speed
#define TWINKLE_AMOUNT     0.1      // idle shimmer depth

// Audio-reactive star controls
#define REACTIVE_FRACTION  0.15     // 15% of stars react to audio
#define REACTIVE_GLOW_MULT 6.0      // brightness boost when hit
#define REACTIVE_SIZE_MULT 0.25     // TINY size growth when hit
#define REACTIVE_HALO_SIZE 0.018    // soft halo radius
#define REACTIVE_SNAP      3.5      // onset sharpness

// Glow
#define GLOW_FALLOFF       2.0      // point glow tightness
#define DIM_GLOW_RADIUS    0.06     // faint glow on dim stars

// Background
#define BG_NEBULA_STRENGTH 0.01     // subtle color wash
#define VIGNETTE_STRENGTH  0.25     // edge darkening

// -------------------- HASH -----------------------------------

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
    float n = hash21(p);
    return vec2(n, hash21(p + n + 7.77));
}

vec3 hash23(vec2 p) {
    float a = hash21(p);
    float b = hash21(p + 31.41);
    float c = hash21(p + 67.89);
    return vec3(a, b, c);
}

// -------------------- AUDIO ----------------------------------

float getFreqAt(float f) {
    return texture(iChannel0, vec2(f, 0.0)).x;
}

// -------------------- COLOR PALETTE --------------------------

vec3 starColor(float id) {
    float t = fract(id * 3.17 + 0.1);
    
    vec3 c;
    if (t < 0.2) {
        c = mix(vec3(1.0, 0.2, 0.65),    // magenta
                vec3(0.6, 0.1, 0.85),     // purple
                t / 0.2);
    } else if (t < 0.4) {
        c = mix(vec3(0.6, 0.1, 0.85),    // purple
                vec3(0.15, 0.25, 0.95),   // blue
                (t - 0.2) / 0.2);
    } else if (t < 0.6) {
        c = mix(vec3(0.15, 0.25, 0.95),  // blue
                vec3(0.0, 0.75, 0.9),     // cyan
                (t - 0.4) / 0.2);
    } else if (t < 0.8) {
        c = mix(vec3(0.0, 0.75, 0.9),    // cyan
                vec3(0.1, 0.85, 0.45),    // green
                (t - 0.6) / 0.2);
    } else {
        c = mix(vec3(0.1, 0.85, 0.45),   // green
                vec3(1.0, 0.2, 0.65),     // magenta
                (t - 0.8) / 0.2);
    }
    return c;
}

// -------------------- STAR LAYER -----------------------------

vec3 starLayer(vec2 uv, float layerIndex, float time) {
    vec3 col = vec3(0.0);
    
    // Depth: 1 = front, 0 = back
    float depth = 1.0 - layerIndex / float(NUM_LAYERS);
    float layerScale = mix(80.0, 25.0, depth);
    float sizeScale = mix(0.35, 1.4, depth);
    float brightnessScale = mix(0.15, 1.0, depth * depth);
    
    // Parallax: front scrolls faster, back slower
    float parallax = mix(0.4, 1.0, depth);
    
    // THE SCROLL: constant diagonal motion applied to the grid
    // This offsets which cells are visible, creating endless drift
    vec2 scroll = vec2(SCROLL_SPEED_X, SCROLL_SPEED_Y) * time * parallax;
    
    // UV in grid space, scrolled
    vec2 gridUV = uv * layerScale + scroll;
    
    vec2 cell = floor(gridUV);
    vec2 localUV = fract(gridUV) - 0.5;
    
    for (int x = -1; x <= 1; x++)
    for (int y = -1; y <= 1; y++) {
        vec2 neighbor = vec2(float(x), float(y));
        vec2 cellId = cell + neighbor;
        
        vec3 rnd = hash23(cellId + layerIndex * 100.0);
        
        // Density cull
        if (rnd.x > STAR_DENSITY) continue;
        
        // Star position within cell
        vec2 starPos = neighbor + hash22(cellId + layerIndex * 50.0) - 0.5;
        vec2 delta = localUV - starPos;
        float dist = length(delta);
        
        // Star identity
        float starId = hash21(cellId + layerIndex * 200.0);
        bool isReactive = (starId < REACTIVE_FRACTION);
        
        // Base properties
        float starSize = mix(BASE_STAR_SIZE, BRIGHT_STAR_SIZE, rnd.y) * sizeScale;
        float brightness = mix(BASE_BRIGHTNESS, 1.0, rnd.z) * brightnessScale;
        
        // Gentle idle twinkle (no audio, just life)
        float twinkle = sin(time * TWINKLE_SPEED * (1.0 + rnd.y * 2.0) + starId * 6.28);
        brightness *= 1.0 + twinkle * TWINKLE_AMOUNT;
        
        // ---- Audio reactivity (selected stars only) ----
        float reactiveGlow = 0.0;
        float reactiveSizeMult = 1.0;
        
        if (isReactive) {
            float freqPos = fract(starId * 7.13 + 0.05);
            float audioVal = getFreqAt(freqPos * 0.5);
            
            // Sharp "click" onset
            float clickedOn = pow(clamp(audioVal * 2.0, 0.0, 1.0), 1.0 / REACTIVE_SNAP);
            
            // Brightness boost
            brightness += clickedOn * REACTIVE_GLOW_MULT * brightnessScale;
            
            // Tiny size growth
            reactiveSizeMult = 1.0 + clickedOn * REACTIVE_SIZE_MULT;
            
            reactiveGlow = clickedOn;
        }
        
        float finalSize = starSize * reactiveSizeMult / layerScale;
        
        // ---- Render star ----
        // Core
        float core = smoothstep(finalSize, finalSize * 0.1, dist);
        
        // Point glow
        float glow = exp(-dist * GLOW_FALLOFF * layerScale / sizeScale);
        glow *= brightness * 0.25;
        
        // Dim ambient glow
        float dimGlow = exp(-dist * layerScale / (DIM_GLOW_RADIUS * layerScale * sizeScale));
        dimGlow *= brightness * 0.08;
        
        // Reactive halo (only when audio-active)
        float halo = 0.0;
        if (isReactive && reactiveGlow > 0.01) {
            float haloR = REACTIVE_HALO_SIZE * reactiveSizeMult / layerScale;
            halo = exp(-dist * dist / (haloR * haloR));
            halo *= reactiveGlow;
        }
        
        // Color
        vec3 sCol = starColor(starId);
        vec3 coreColor = mix(sCol, vec3(1.0), 0.5 * reactiveGlow);
        
        // Composite
        vec3 starContrib = vec3(0.0);
        starContrib += coreColor * core * brightness;
        starContrib += sCol * glow;
        starContrib += sCol * dimGlow;
        starContrib += sCol * halo * 2.0;
        
        col += starContrib;
    }
    
    return col;
}

// -------------------- MAIN -----------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Constant smooth time — audio NEVER touches the scroll
    float time = iTime;
    
    // Accumulate layers
    vec3 col = vec3(0.0);
    for (int i = 0; i < NUM_LAYERS; i++) {
        col += starLayer(uv, float(i), time);
    }
    
    // Subtle background nebula (non-reactive ambiance)
    {
        vec2 bgUV = uv + vec2(SCROLL_SPEED_X, SCROLL_SPEED_Y) * time * 0.1;
        float n1 = sin(bgUV.x * 1.5 + bgUV.y * 0.8) * 0.5 + 0.5;
        float n2 = sin(bgUV.y * 2.0 - bgUV.x * 1.2) * 0.5 + 0.5;
        vec3 nebulaCol = mix(
            vec3(0.04, 0.01, 0.07),
            vec3(0.01, 0.03, 0.05),
            uv.x * 0.5 + 0.5
        );
        col += nebulaCol * n1 * n2 * BG_NEBULA_STRENGTH;
    }
    
    // Vignette
    float vignette = 1.0 - dot(uv, uv) * VIGNETTE_STRENGTH;
    col *= max(vignette, 0.0);
    
    // Tonemap
    col = 1.0 - exp(-col * 1.5);
    col = pow(col, vec3(0.92));

    fragColor = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
