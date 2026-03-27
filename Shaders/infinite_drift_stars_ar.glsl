// ============================================================
// Infinite Drift — Smooth Scrolling Starfield
// Audio-reactive glow on select stars only
// For oneoff.py — iChannel0 = audio texture
//
// Color palette: magenta → purple → blue → cyan → green
// Scrolls diagonally (X+Y) at constant speed. Never jolts.
// Some stars "click" into brightness with the music.
// ============================================================

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;

// -------------------- TWEAKABLES ----------------------------
#define SCROLL_SPEED_X     0.035    // horizontal drift speed
#define SCROLL_SPEED_Y     0.02     // vertical drift speed

#define NUM_LAYERS         5        // depth layers of stars
#define STAR_DENSITY       0.65     // 0-1, higher = more stars per cell
#define BASE_STAR_SIZE     0.0015   // smallest dim stars
#define BRIGHT_STAR_SIZE   0.004    // larger bright stars
#define BASE_BRIGHTNESS    0.3      // dim star brightness floor
#define TWINKLE_SPEED      1.5      // subtle idle twinkle rate
#define TWINKLE_AMOUNT     0.15     // subtle idle twinkle depth

// Audio-reactive star controls
#define REACTIVE_FRACTION  0.2      // fraction of stars that react (0.0–1.0)
#define REACTIVE_GLOW_MULT 8.0      // how much brighter reactive stars get
#define REACTIVE_SIZE_MULT 3.0      // how much bigger reactive stars get
#define REACTIVE_HALO_SIZE 0.025    // glow halo radius on reactive stars
#define REACTIVE_HALO_FALL 6.0      // halo falloff sharpness
#define REACTIVE_SNAP      4.0      // how fast the "click" onset is (higher = snappier)

// Glow
#define GLOW_FALLOFF       12.0     // point-star glow tightness
#define DIM_GLOW_RADIUS    0.008    // faint glow around dim stars

// Background
#define BG_NEBULA_STRENGTH 0.012    // subtle background color wash
#define VIGNETTE_STRENGTH  0.3      // edge darkening

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

float getAudioBass() {
    float v = 0.0;
    for (int i = 0; i < 10; i++)
        v += texture(iChannel0, vec2(float(i) / 512.0, 0.0)).x;
    return v / 10.0;
}

float getAudioMid() {
    float v = 0.0;
    for (int i = 25; i < 80; i++)
        v += texture(iChannel0, vec2(float(i) / 512.0, 0.0)).x;
    return v / 55.0;
}

float getAudioHigh() {
    float v = 0.0;
    for (int i = 100; i < 200; i++)
        v += texture(iChannel0, vec2(float(i) / 512.0, 0.0)).x;
    return v / 100.0;
}

// -------------------- COLOR PALETTE --------------------------

vec3 starColor(float id) {
    // Map star ID (0-1) to our palette
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
                vec3(1.0, 0.2, 0.65),     // back to magenta
                (t - 0.8) / 0.2);
    }
    return c;
}

// -------------------- STAR LAYER -----------------------------

vec3 starLayer(vec2 uv, float layerIndex, float time) {
    vec3 col = vec3(0.0);
    
    // Layer properties: deeper layers have smaller, dimmer, denser stars
    float depth = 1.0 - layerIndex / float(NUM_LAYERS);  // 1=front, 0=back
    float layerScale = mix(60.0, 20.0, depth);            // cell grid density
    float sizeScale = mix(0.4, 1.5, depth);               // front stars bigger
    float brightnessScale = mix(0.2, 1.0, depth * depth); // front stars brighter
    
    // Parallax: front layers scroll faster
    float parallax = mix(0.3, 1.0, depth);
    vec2 scroll = vec2(SCROLL_SPEED_X, SCROLL_SPEED_Y) * time * parallax;
    
    vec2 scrolledUV = uv * layerScale + scroll;
    vec2 cell = floor(scrolledUV);
    vec2 localUV = fract(scrolledUV) - 0.5;
    
    // Check this cell and neighbors for smooth star edges
    for (int x = -1; x <= 1; x++)
    for (int y = -1; y <= 1; y++) {
        vec2 neighbor = vec2(float(x), float(y));
        vec2 cellId = cell + neighbor;
        
        // Deterministic star properties from cell ID
        vec3 rnd = hash23(cellId + layerIndex * 100.0);
        
        // Density cull: skip cells with no star
        if (rnd.x > STAR_DENSITY) continue;
        
        // Star position within cell
        vec2 starPos = neighbor + hash22(cellId + layerIndex * 50.0) - 0.5;
        vec2 delta = localUV - starPos;
        float dist = length(delta);
        
        // ---- Star identity ----
        float starId = hash21(cellId + layerIndex * 200.0);
        bool isReactive = (starId < REACTIVE_FRACTION);
        
        // ---- Base star properties ----
        float starSize = mix(BASE_STAR_SIZE, BRIGHT_STAR_SIZE, rnd.y) * sizeScale;
        float brightness = mix(BASE_BRIGHTNESS, 1.0, rnd.z) * brightnessScale;
        
        // Subtle idle twinkle (NOT audio — just gentle shimmer)
        float twinkle = sin(time * TWINKLE_SPEED * (1.0 + rnd.y * 2.0) + starId * 6.28);
        brightness *= 1.0 + twinkle * TWINKLE_AMOUNT;
        
        // ---- Audio reactivity for selected stars ----
        float reactiveGlow = 0.0;
        float reactiveSizeMult = 1.0;
        
        if (isReactive) {
            // Each reactive star listens to a specific frequency
            float freqPos = fract(starId * 7.13 + 0.05);
            float audioVal = getFreqAt(freqPos * 0.5);
            
            // "Click" into brightness — sharp onset via pow
            float clickedOn = pow(clamp(audioVal * 2.0, 0.0, 1.0), 1.0 / REACTIVE_SNAP);
            
            // Boost brightness
            brightness += clickedOn * REACTIVE_GLOW_MULT * brightnessScale;
            
            // Grow size
            reactiveSizeMult = 1.0 + clickedOn * REACTIVE_SIZE_MULT;
            
            // Halo intensity
            reactiveGlow = clickedOn;
        }
        
        float finalSize = starSize * reactiveSizeMult / layerScale;
        
        // ---- Star rendering ----
        // Sharp bright core
        float core = smoothstep(finalSize, finalSize * 0.1, dist);
        
        // Point glow falloff
        float glow = exp(-dist * GLOW_FALLOFF * layerScale / sizeScale);
        glow *= brightness * 0.3;
        
        // Dim star gentle glow
        float dimGlow = exp(-dist * layerScale / (DIM_GLOW_RADIUS * layerScale * sizeScale));
        dimGlow *= brightness * 0.1;
        
        // Audio-reactive halo (only on reactive stars when active)
        float halo = 0.0;
        if (isReactive && reactiveGlow > 0.01) {
            float haloRadius = REACTIVE_HALO_SIZE * reactiveSizeMult / layerScale;
            halo = exp(-dist * dist / (haloRadius * haloRadius));
            halo *= reactiveGlow;
        }
        
        // ---- Color ----
        vec3 sCol = starColor(starId);
        
        // Reactive stars push toward white when fully "clicked"
        vec3 coreColor = mix(sCol, vec3(1.0), 0.4 * reactiveGlow);
        
        // ---- Composite ----
        vec3 starContrib = vec3(0.0);
        starContrib += coreColor * core * brightness;
        starContrib += sCol * glow;
        starContrib += sCol * dimGlow;
        starContrib += sCol * halo * 2.5;
        
        // Small cross-flare on bright reactive stars
        if (isReactive && reactiveGlow > 0.3) {
            float flareX = exp(-abs(delta.y) * layerScale * 8.0) * exp(-abs(delta.x) * layerScale * 1.5);
            float flareY = exp(-abs(delta.x) * layerScale * 8.0) * exp(-abs(delta.y) * layerScale * 1.5);
            float flare = (flareX + flareY) * reactiveGlow * 0.4 * brightnessScale;
            starContrib += sCol * flare;
        }
        
        col += starContrib;
    }
    
    return col;
}

// -------------------- MAIN -----------------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // ---- Constant smooth time — no audio influence on scroll ----
    float time = iTime;
    
    // ---- Accumulate star layers ----
    vec3 col = vec3(0.0);
    
    for (int i = 0; i < NUM_LAYERS; i++) {
        col += starLayer(uv, float(i), time);
    }
    
    // ---- Subtle background nebula wash (non-reactive, just ambiance) ----
    {
        float n1 = sin(uv.x * 1.5 + uv.y * 0.8 + time * 0.01) * 0.5 + 0.5;
        float n2 = sin(uv.y * 2.0 - uv.x * 1.2 + time * 0.015) * 0.5 + 0.5;
        float nebula = n1 * n2;
        vec3 nebulaCol = mix(
            vec3(0.05, 0.01, 0.08),  // dark purple
            vec3(0.01, 0.04, 0.06),  // dark teal
            uv.x * 0.5 + 0.5 + sin(time * 0.02) * 0.3
        );
        col += nebulaCol * nebula * BG_NEBULA_STRENGTH;
    }
    
    // ---- Vignette ----
    float vignette = 1.0 - dot(uv, uv) * VIGNETTE_STRENGTH;
    col *= max(vignette, 0.0);
    
    // ---- Tonemap ----
    col = 1.0 - exp(-col * 1.5);
    col = pow(col, vec3(0.92));

    fragColor = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
