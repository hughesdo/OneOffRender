// ============================================================
// Plasma Spectrograph — Flowing Audio-Reactive Plasma Field
// For oneoff.py — iChannel0 = audio texture
//
// NOT particles. Continuous fibrous plasma with directional
// FBM noise. The music spectrum paints itself as color bands:
// magenta(bass) → purple → blue → cyan → green(highs)
// flowing through a turbulent plasma stream.
// ============================================================

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;

// -------------------- TWEAKABLES ----------------------------
#define FLOW_ANGLE       -0.35      // stream direction (radians)
#define FLOW_SPEED        0.4       // base scroll speed
#define STREAM_WIDTH      0.55      // cross-stream spread
#define STREAM_CENTER     vec2(-0.1, -0.05) // stream center offset

#define FBM_OCTAVES       6         // fibrous detail layers
#define FBM_STRETCH       4.0       // anisotropy: stretch along flow
#define FBM_SCALE         3.5       // base noise frequency
#define FBM_GAIN          0.5       // octave amplitude decay
#define FBM_LACUNARITY    2.2       // octave frequency growth

#define WARP_STRENGTH     0.45      // domain warp intensity
#define WARP_SCALE        1.8       // domain warp noise scale
#define WARP_SPEED        0.15      // domain warp animation

#define GLOW_POWER        2.5       // overall glow multiplier
#define CORE_INTENSITY    5.0       // hot core brightness
#define CORE_SIZE         0.12      // hot core radius
#define BAND_SOFTNESS     0.4       // color band blending width
#define TENDRIL_FADE      2.5       // how fast tendrils fade at edges

#define AUDIO_BRIGHTNESS  3.0       // audio → overall brightness
#define AUDIO_SPREAD      1.2       // audio → stream width
#define AUDIO_WARP        1.5       // audio → turbulence boost
#define AUDIO_FLOW_BOOST  1.5       // audio → flow speed boost

// -------------------- NOISE ---------------------------------

// 2D value noise
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p3) {
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

// Smooth 2D noise
float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    float a = hash12(i);
    float b = hash12(i + vec2(1, 0));
    float c = hash12(i + vec2(0, 1));
    float d = hash12(i + vec2(1, 1));
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 3D gradient noise for richer warping
vec3 hash33(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453);
}

float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(dot(hash33(i), f),
                       dot(hash33(i + vec3(1,0,0)), f - vec3(1,0,0)), u.x),
                   mix(dot(hash33(i + vec3(0,1,0)), f - vec3(0,1,0)),
                       dot(hash33(i + vec3(1,1,0)), f - vec3(1,1,0)), u.x), u.y),
               mix(mix(dot(hash33(i + vec3(0,0,1)), f - vec3(0,0,1)),
                       dot(hash33(i + vec3(1,0,1)), f - vec3(1,0,1)), u.x),
                   mix(dot(hash33(i + vec3(0,1,1)), f - vec3(0,1,1)),
                       dot(hash33(i + vec3(1,1,1)), f - vec3(1,1,1)), u.x), u.y), u.z);
}

// -------------------- DIRECTIONAL FBM ------------------------
// Stretched along flow direction to create fibrous striations

float fibrousFBM(vec2 p, vec2 flowDir, float time) {
    // Rotate into flow-aligned space
    vec2 perpDir = vec2(-flowDir.y, flowDir.x);
    vec2 aligned = vec2(dot(p, flowDir), dot(p, perpDir));
    
    // Stretch along flow direction → creates striations
    aligned.x *= 1.0 / FBM_STRETCH;
    
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = FBM_SCALE;
    float t = time;
    
    for (int i = 0; i < FBM_OCTAVES; i++) {
        // Use 3D noise with time for animation
        vec3 noiseP = vec3(aligned * frequency, t * (0.3 + float(i) * 0.1));
        float n = noise3(noiseP);
        
        // Higher octaves get progressively more stretched
        // for that fine filament look at small scales
        value += amplitude * n;
        
        amplitude *= FBM_GAIN;
        frequency *= FBM_LACUNARITY;
        
        // Slightly rotate each octave for richer texture
        aligned = vec2(aligned.x * 1.02 + aligned.y * 0.05,
                       aligned.y * 1.02 - aligned.x * 0.05);
    }
    
    return value;
}

// -------------------- DOMAIN WARP ----------------------------

vec2 domainWarp(vec2 p, float time, float audioWarp) {
    float warpAmp = WARP_STRENGTH * (1.0 + audioWarp * AUDIO_WARP);
    
    float wx = noise3(vec3(p * WARP_SCALE, time * WARP_SPEED));
    float wy = noise3(vec3(p * WARP_SCALE + 50.0, time * WARP_SPEED + 30.0));
    
    // Second layer of warp for more organic feel
    float wx2 = noise3(vec3((p + vec2(wx, wy) * 0.3) * WARP_SCALE * 1.5, time * WARP_SPEED * 0.7 + 100.0));
    float wy2 = noise3(vec3((p + vec2(wx, wy) * 0.3) * WARP_SCALE * 1.5 + 80.0, time * WARP_SPEED * 0.7 + 130.0));
    
    return vec2(wx + wx2 * 0.5, wy + wy2 * 0.5) * warpAmp;
}

// -------------------- AUDIO ----------------------------------

// Sample audio in frequency bands
float audioBand(float lo, float hi) {
    float sum = 0.0;
    float count = 0.0;
    for (float f = lo; f < hi; f += 1.0/512.0) {
        sum += texture(iChannel0, vec2(f, 0.0)).x;
        count += 1.0;
        if (count > 30.0) break; // keep it bounded
    }
    return sum / max(count, 1.0);
}

// 5 bands: sub-bass, bass, low-mid, high-mid, highs
float getSubBass()  { return audioBand(0.0/512.0,  6.0/512.0); }
float getBass()     { return audioBand(6.0/512.0,  20.0/512.0); }
float getLowMid()   { return audioBand(20.0/512.0, 60.0/512.0); }
float getHighMid()  { return audioBand(60.0/512.0, 140.0/512.0); }
float getHighs()    { return audioBand(140.0/512.0, 300.0/512.0); }

// Continuous spectrum sample at position 0-1
float spectrumAt(float t) {
    // Map 0-1 to useful frequency range
    float freq = t * 0.4; // 0 to ~200 bins
    return texture(iChannel0, vec2(freq, 0.0)).x;
}

// -------------------- COLOR PALETTE --------------------------

// Maps a cross-stream position (0=magenta/bass, 1=green/highs)
// to the spectral color, modulated by that band's audio level
vec3 spectrumColor(float bandPos, float audioLevel) {
    // Clamp
    float t = clamp(bandPos, 0.0, 1.0);
    
    // 5-stop gradient: magenta → purple → blue → cyan → green
    vec3 c;
    if (t < 0.2) {
        float s = t / 0.2;
        c = mix(vec3(1.0, 0.15, 0.65),   // hot magenta
                vec3(0.6, 0.08, 0.85),    // purple
                s);
    } else if (t < 0.4) {
        float s = (t - 0.2) / 0.2;
        c = mix(vec3(0.6, 0.08, 0.85),   // purple
                vec3(0.15, 0.2, 0.95),    // blue
                s);
    } else if (t < 0.6) {
        float s = (t - 0.4) / 0.2;
        c = mix(vec3(0.15, 0.2, 0.95),   // blue
                vec3(0.0, 0.7, 0.9),      // cyan
                s);
    } else if (t < 0.8) {
        float s = (t - 0.6) / 0.2;
        c = mix(vec3(0.0, 0.7, 0.9),     // cyan
                vec3(0.05, 0.85, 0.5),    // teal-green
                s);
    } else {
        float s = (t - 0.8) / 0.2;
        c = mix(vec3(0.05, 0.85, 0.5),   // teal-green
                vec3(0.15, 0.7, 0.25),    // deep green
                s);
    }
    
    return c * audioLevel;
}

// -------------------- MAIN IMAGE -----------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // ---- Audio analysis ----
    float subBass = getSubBass();
    float bass    = getBass();
    float lowMid  = getLowMid();
    float highMid = getHighMid();
    float highs   = getHighs();
    float total   = (subBass + bass + lowMid + highMid + highs) / 5.0;
    
    // Audio array for per-band lookup
    float bands[5];
    bands[0] = subBass;
    bands[1] = bass;
    bands[2] = lowMid;
    bands[3] = highMid;
    bands[4] = highs;
    
    // ---- Flow direction ----
    float angle = FLOW_ANGLE + sin(iTime * 0.05) * 0.1 + bass * 0.15;
    vec2 flowDir = vec2(cos(angle), sin(angle));
    vec2 perpDir = vec2(-flowDir.y, flowDir.x);
    
    // ---- Stream-local coordinates ----
    vec2 centered = uv - STREAM_CENTER;
    // Shift center with audio
    centered -= perpDir * (bass - 0.3) * 0.15;
    
    float alongStream = dot(centered, flowDir);  // position along flow
    float crossStream = dot(centered, perpDir);   // position across flow (spectrogram axis)
    
    // ---- Stream envelope: Gaussian cross-section ----
    float width = STREAM_WIDTH * (1.0 + total * AUDIO_SPREAD);
    float envelope = exp(-crossStream * crossStream / (width * width));
    // Elongated along stream, taper at ends
    float alongFade = smoothstep(-2.0, -0.5, alongStream) * smoothstep(2.5, 0.8, alongStream);
    envelope *= alongFade;
    
    // Early out if way outside stream
    if (envelope < 0.005) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    
    // ---- Domain warping for organic turbulence ----
    float flowTime = iTime * (FLOW_SPEED + total * FLOW_SPEED * AUDIO_FLOW_BOOST);
    vec2 warpedUV = centered + domainWarp(centered * 1.2, iTime, total);
    
    // Scroll along flow direction
    warpedUV += flowDir * flowTime;
    
    // ---- Fibrous noise texture ----
    float fibrous = fibrousFBM(warpedUV, flowDir, iTime * 0.4);
    
    // Second layer at different scale for micro-detail
    float fineDetail = fibrousFBM(warpedUV * 2.5 + 10.0, flowDir, iTime * 0.35);
    fibrous = fibrous * 0.7 + fineDetail * 0.3;
    
    // Remap to 0-1 range with contrast
    fibrous = smoothstep(-0.3, 0.7, fibrous);
    
    // ---- Map cross-stream position to frequency bands ----
    // Normalize cross-stream: -width..+width → 0..1
    // Magenta(bass) at one edge, green(highs) at the other
    float bandPosition = (crossStream / width) * 0.5 + 0.5;
    // Add noise-based displacement so bands aren't perfectly straight
    bandPosition += fibrous * 0.15 - 0.075;
    bandPosition = clamp(bandPosition, 0.0, 1.0);
    
    // ---- Sample audio for this position's frequency band ----
    // Continuous spectrum sampling based on band position
    float audioAtPos = spectrumAt(bandPosition);
    
    // Also blend in the nearest discrete band for punch
    int bandIdx = int(bandPosition * 4.99);
    float discreteAudio;
    if (bandIdx == 0) discreteAudio = bands[0];
    else if (bandIdx == 1) discreteAudio = bands[1];
    else if (bandIdx == 2) discreteAudio = bands[2];
    else if (bandIdx == 3) discreteAudio = bands[3];
    else discreteAudio = bands[4];
    
    float finalAudio = mix(audioAtPos, discreteAudio, 0.4);
    
    // ---- Color: spectrum mapped to position ----
    vec3 col = spectrumColor(bandPosition, finalAudio * AUDIO_BRIGHTNESS);
    
    // ---- Apply fibrous texture ----
    // The fibrous noise modulates brightness to create the striation look
    float fibrousMask = fibrous * fibrous; // squared for more contrast
    col *= fibrousMask;
    
    // ---- Extra detail: thin bright filaments ----
    float filament = smoothstep(0.55, 0.75, fibrous);
    col += spectrumColor(bandPosition, finalAudio) * filament * 1.5;
    
    // ---- Apply stream envelope ----
    col *= envelope;
    
    // ---- Tendril edges: noise modulates the falloff ----
    float edgeNoise = noise3(vec3(warpedUV * 3.0, iTime * 0.2));
    float tendrilMask = smoothstep(0.0, 0.3, envelope + edgeNoise * 0.15);
    col *= tendrilMask;
    
    // ---- Hot core: bright white/magenta nucleus ----
    float coreDist = length(centered - flowDir * 0.1 + perpDir * (crossStream * 0.3));
    float coreSize = CORE_SIZE * (1.0 + bass * 1.5);
    float core = exp(-coreDist * coreDist / (coreSize * coreSize));
    core *= (subBass + bass) * CORE_INTENSITY;
    
    // Core color: white at center, magenta at edges
    vec3 coreCol = mix(vec3(1.0, 0.3, 0.7), vec3(1.0, 0.9, 0.95), core);
    col += coreCol * core * envelope;
    
    // ---- Secondary glow: softer bloom around the whole thing ----
    float bloom = exp(-length(centered) * 1.5);
    vec3 bloomCol = spectrumColor(0.5, total) * 0.15;
    col += bloomCol * bloom * total;
    
    // ---- Faint outer haze ----
    float haze = exp(-length(centered) * 0.8);
    float hazeNoise = noise3(vec3(centered * 2.0, iTime * 0.1));
    haze *= hazeNoise * 0.5 + 0.5;
    col += vec3(0.03, 0.01, 0.05) * haze * total * 2.0;
    
    // ---- Final glow boost ----
    col *= GLOW_POWER;
    
    // ---- Tonemap ----
    col = 1.0 - exp(-col * 1.2);
    col = pow(col, vec3(0.88));

    fragColor = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
