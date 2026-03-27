// ============================================================
// Saw Wave Particle Stream — Audio-Reactive 3D Plasma Flow
// For oneoff.py — iChannel0 = audio texture
// ============================================================

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;

// -------------------- TWEAKABLES ----------------------------
#define NUM_LAYERS        8        // depth layers
#define PARTICLES_PER_CELL 1       // density control
#define BASE_SIZE         0.018    // base particle radius
#define GLOW_STRENGTH     2.8      // bloom intensity
#define GLOW_FALLOFF      4.5      // bloom tightness
#define CORE_HOTNESS      3.0      // white-hot center multiplier
#define SAW_FREQUENCY     2.5      // sawtooth color repetitions
#define SAW_SHARPNESS     0.7      // 0=smooth ramp, 1=hard saw edge
#define FLOW_SPEED        0.25     // stream velocity
#define TURBULENCE_AMP    0.35     // curl noise displacement
#define TURBULENCE_FREQ   2.5      // curl noise scale
#define STREAM_WIDTH      0.6      // vertical spread of stream
#define STREAM_ANGLE      -0.3     // tilt angle (radians)
#define CAMERA_DIST       3.0      // camera pullback
#define AUDIO_GLOW_MULT   4.0      // audio → glow
#define AUDIO_SIZE_MULT   2.5      // audio → particle grow
#define AUDIO_SAW_MULT    1.5      // audio → saw frequency shift
#define AUDIO_SPREAD_MULT 1.5      // audio → stream spread
#define AUDIO_FLOW_MULT   2.0      // audio → flow speed boost

// -------------------- NOISE ---------------------------------

// Simplex-ish 3D noise for turbulence
vec3 hash3(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(dot(hash3(i + vec3(0,0,0)), f - vec3(0,0,0)),
                       dot(hash3(i + vec3(1,0,0)), f - vec3(1,0,0)), u.x),
                   mix(dot(hash3(i + vec3(0,1,0)), f - vec3(0,1,0)),
                       dot(hash3(i + vec3(1,1,0)), f - vec3(1,1,0)), u.x), u.y),
               mix(mix(dot(hash3(i + vec3(0,0,1)), f - vec3(0,0,1)),
                       dot(hash3(i + vec3(1,0,1)), f - vec3(1,0,1)), u.x),
                   mix(dot(hash3(i + vec3(0,1,1)), f - vec3(0,1,1)),
                       dot(hash3(i + vec3(1,1,1)), f - vec3(1,1,1)), u.x), u.y), u.z);
}

// Curl noise for organic flow — returns displacement vector
vec3 curlNoise(vec3 p) {
    float e = 0.01;
    float n1, n2;
    vec3 curl;
    
    n1 = noise3(p + vec3(0, e, 0));
    n2 = noise3(p - vec3(0, e, 0));
    float dz_dy = (n1 - n2) / (2.0 * e);
    n1 = noise3(p + vec3(0, 0, e));
    n2 = noise3(p - vec3(0, 0, e));
    float dy_dz = (n1 - n2) / (2.0 * e);
    curl.x = dz_dy - dy_dz;
    
    n1 = noise3(p + vec3(0, 0, e));
    n2 = noise3(p - vec3(0, 0, e));
    float dx_dz = (n1 - n2) / (2.0 * e);
    n1 = noise3(p + vec3(e, 0, 0));
    n2 = noise3(p - vec3(e, 0, 0));
    float dz_dx = (n1 - n2) / (2.0 * e);
    curl.y = dx_dz - dz_dx;
    
    n1 = noise3(p + vec3(e, 0, 0));
    n2 = noise3(p - vec3(e, 0, 0));
    float dy_dx = (n1 - n2) / (2.0 * e);
    n1 = noise3(p + vec3(0, e, 0));
    n2 = noise3(p - vec3(0, e, 0));
    float dx_dy = (n1 - n2) / (2.0 * e);
    curl.z = dy_dx - dx_dy;
    
    return curl;
}

// Fast hash
float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float hash31(vec3 p) {
    p = fract(p * vec3(123.34, 456.21, 789.92));
    p += dot(p, p.yzx + 45.32);
    return fract(p.x * p.y * p.z);
}

vec3 hash33(vec3 p) {
    return vec3(hash31(p), hash31(p + 77.7), hash31(p + 155.5));
}

// -------------------- AUDIO ----------------------------------

float getAudioBass() {
    float v = 0.0;
    for (int i = 0; i < 10; i++)
        v += texture(iChannel0, vec2(float(i) / 512.0, 0.0)).x;
    return v / 10.0;
}

float getAudioMid() {
    float v = 0.0;
    for (int i = 20; i < 80; i++)
        v += texture(iChannel0, vec2(float(i) / 512.0, 0.0)).x;
    return v / 60.0;
}

float getAudioHigh() {
    float v = 0.0;
    for (int i = 100; i < 200; i++)
        v += texture(iChannel0, vec2(float(i) / 512.0, 0.0)).x;
    return v / 100.0;
}

float getFreqAt(float f) {
    return texture(iChannel0, vec2(f, 0.0)).x;
}

// -------------------- SAW WAVE COLOR -------------------------

// The magic: sawtooth ramp through magenta→purple→blue→cyan→green
// with sharp "reset" edges like a saw oscillator
vec3 sawColor(float t, float audioMod) {
    // Sawtooth: fract gives us the 0→1 ramp that resets sharply
    float sawFreq = SAW_FREQUENCY + audioMod * AUDIO_SAW_MULT;
    float saw = fract(t * sawFreq);
    
    // Sharpen the ramp edges
    saw = mix(saw, step(0.5, saw), SAW_SHARPNESS * 0.3);
    saw = smoothstep(0.0, 1.0, saw); // slight ease within each tooth
    
    // Map saw ramp to our color palette:
    // 0.0 = magenta/hot pink
    // 0.25 = purple  
    // 0.5 = blue
    // 0.75 = cyan
    // 1.0 = green
    vec3 c;
    if (saw < 0.25) {
        float s = saw / 0.25;
        c = mix(vec3(1.0, 0.05, 0.6),   // magenta
                vec3(0.55, 0.05, 0.85),  // purple
                s);
    } else if (saw < 0.5) {
        float s = (saw - 0.25) / 0.25;
        c = mix(vec3(0.55, 0.05, 0.85),  // purple
                vec3(0.1, 0.2, 0.95),    // blue
                s);
    } else if (saw < 0.75) {
        float s = (saw - 0.5) / 0.25;
        c = mix(vec3(0.1, 0.2, 0.95),    // blue
                vec3(0.0, 0.8, 0.85),    // cyan
                s);
    } else {
        float s = (saw - 0.75) / 0.25;
        c = mix(vec3(0.0, 0.8, 0.85),    // cyan
                vec3(0.1, 0.9, 0.3),     // green
                s);
    }
    return c;
}

// -------------------- STREAM DENSITY -------------------------

// Defines the flowing stream shape — high near stream center, falls off
float streamDensity(vec3 p, float bass, float mid) {
    // Rotate to stream angle
    float ca = cos(STREAM_ANGLE), sa = sin(STREAM_ANGLE);
    vec2 rp = vec2(ca * p.x - sa * p.y, sa * p.x + ca * p.y);
    
    // Stream is elongated along X, narrow in Y/Z
    float width = STREAM_WIDTH * (1.0 + bass * AUDIO_SPREAD_MULT);
    float yDist = abs(rp.y) / width;
    float zDist = abs(p.z) / (width * 1.5);
    
    // Gaussian-ish falloff from stream center
    float density = exp(-yDist * yDist * 3.0 - zDist * zDist * 2.0);
    
    // Taper at the ends
    float xFade = smoothstep(-2.5, -1.0, rp.x) * smoothstep(2.5, 1.0, rp.x);
    density *= xFade;
    
    return density;
}

// -------------------- MAIN IMAGE -----------------------------

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Audio
    float bass = getAudioBass();
    float mid  = getAudioMid();
    float high = getAudioHigh();
    float audioAll = (bass * 2.0 + mid + high) / 4.0;
    
    // ---- Camera: slow orbit with audio sway ----
    float camT = iTime * 0.06;
    float camAngle = camT + bass * 0.2;
    float camPitch = 0.15 + sin(iTime * 0.1) * 0.1 + mid * 0.1;
    vec3 camPos = vec3(
        CAMERA_DIST * cos(camAngle) * cos(camPitch),
        CAMERA_DIST * sin(camPitch) * 0.4 + 0.2,
        CAMERA_DIST * sin(camAngle) * cos(camPitch)
    );
    vec3 target = vec3(0.0, -0.1, 0.0);
    
    vec3 fwd = normalize(target - camPos);
    vec3 rgt = normalize(cross(fwd, vec3(0,1,0)));
    vec3 up  = cross(rgt, fwd);
    
    float fov = 1.6 - bass * 0.2;
    vec3 rd = normalize(uv.x * rgt + uv.y * up + fov * fwd);
    
    // ---- Accumulate particles ----
    vec3 col = vec3(0.0);
    
    float flowT = iTime * (FLOW_SPEED + bass * FLOW_SPEED * AUDIO_FLOW_MULT);
    
    for (int layer = 0; layer < NUM_LAYERS; layer++) {
        float fl = float(layer);
        float layerDepth = 0.8 + fl * 0.65;
        // Jitter depth slightly per-pixel for less banding
        layerDepth += hash21(uv * 37.7 + fl) * 0.15;
        
        vec3 pos = camPos + rd * layerDepth;
        
        // ---- Apply flow: stream along tilted axis ----
        float ca = cos(STREAM_ANGLE), sa = sin(STREAM_ANGLE);
        vec2 flowDir = vec2(ca, sa);
        pos.xy += flowDir * flowT * (0.8 + fl * 0.1);
        
        // ---- Curl noise turbulence ----
        vec3 turbP = pos * TURBULENCE_FREQ + iTime * 0.15;
        vec3 curl = curlNoise(turbP);
        float turbAmp = TURBULENCE_AMP * (1.0 + bass * 0.8);
        pos += curl * turbAmp;
        
        // ---- Check if we're in the stream ----
        float density = streamDensity(pos, bass, mid);
        if (density < 0.01) continue;
        
        // ---- Particle grid ----
        float cellSize = 0.18;
        vec3 cell = floor(pos / cellSize);
        vec3 localP = fract(pos / cellSize);
        
        for (int cx = -1; cx <= 1; cx++)
        for (int cy = -1; cy <= 1; cy++) {
            vec3 cid = cell + vec3(float(cx), float(cy), 0.0);
            vec3 layerCid = cid + vec3(0, 0, fl * 11.11);
            
            float rnd = hash31(layerCid);
            // Cull for performance + natural sparse look
            if (rnd > 0.55 + density * 0.4) continue;
            
            vec3 rnd3 = hash33(layerCid);
            vec2 pOff = rnd3.xy;
            
            // Particle position in cell
            vec2 pPos = vec2(float(cx) + pOff.x, float(cy) + pOff.y);
            
            // Micro-animation
            float freqVal = getFreqAt(fract(rnd * 0.5 + 0.02));
            pPos += 0.06 * sin(iTime * (1.0 + rnd * 3.0) + rnd3.xy * 6.28);
            pPos += freqVal * 0.04 * vec2(cos(rnd * 40.0), sin(rnd * 40.0));
            
            vec2 delta = localP.xy - pPos;
            float dist = length(delta);
            
            // ---- Size: grows with audio & density ----
            float pSize = BASE_SIZE * (0.4 + rnd * 1.2);
            pSize *= (1.0 + freqVal * AUDIO_SIZE_MULT);
            pSize *= (0.5 + density);
            
            // ---- Core ----
            float core = smoothstep(pSize, pSize * 0.15, dist);
            
            // ---- Glow halo ----
            float glow = exp(-dist * GLOW_FALLOFF / max(pSize, 0.001));
            glow *= GLOW_STRENGTH * (1.0 + freqVal * AUDIO_GLOW_MULT);
            
            // ---- SAW WAVE COLOR ----
            // Color position based on stream-local coordinate + depth
            // The saw ramp runs along the stream axis
            float colorPos = (pos.x * ca + pos.y * sa) * 0.3  // along stream
                           + fl * 0.12                          // depth offset
                           + iTime * 0.15                       // scroll
                           + freqVal * 0.3;                     // audio jitter
            
            vec3 pCol = sawColor(colorPos, audioAll);
            
            // ---- Hot core: particles near stream center glow white-hot ----
            float hotness = density * density * CORE_HOTNESS;
            hotness *= (1.0 + bass * 2.0);
            vec3 hotCol = mix(pCol, vec3(1.0, 0.85, 0.95), clamp(hotness * core, 0.0, 0.85));
            
            // ---- Compose ----
            float brightness = core * (1.0 + hotness) + glow * 0.4;
            brightness *= density; // fade out at stream edges
            
            // Depth fog
            float fog = exp(-layerDepth * 0.08);
            
            vec3 contrib = hotCol * core * (1.0 + hotness)
                         + pCol * glow * 0.5
                         + pCol * 1.3 * brightness * 0.15; // fill light
            contrib *= fog * density;
            
            col += contrib;
        }
    }
    
    // ---- Scattered trailing wisps (outer particles) ----
    for (int i = 0; i < 40; i++) {
        float fi = float(i);
        vec3 rh = hash33(vec3(fi * 1.23, fi * 4.56, fi * 7.89));
        
        // Spread along stream direction
        vec2 wispUV = (rh.xy - 0.5) * vec2(3.0, 1.2);
        // Tilt with stream
        float ca2 = cos(STREAM_ANGLE), sa2 = sin(STREAM_ANGLE);
        wispUV = vec2(ca2 * wispUV.x - sa2 * wispUV.y,
                       sa2 * wispUV.x + ca2 * wispUV.y);
        
        // Drift
        wispUV += vec2(ca2, sa2) * flowT * 0.3 * (0.5 + rh.z);
        wispUV = mod(wispUV + 2.0, 4.0) - 2.0; // wrap
        
        // Turbulence
        wispUV += 0.1 * sin(iTime * 0.3 + fi * 2.0 + rh.xy * 10.0);
        
        float d = length(uv - wispUV);
        float freqVal = getFreqAt(fract(fi * 0.029 + 0.01));
        
        float wSize = 0.004 + 0.008 * freqVal * AUDIO_SIZE_MULT * 0.5;
        float wCore = smoothstep(wSize, 0.0, d);
        float wGlow = exp(-d * 30.0) * (0.3 + freqVal * 2.0);
        
        // Saw color for wisps too
        float wColorPos = (wispUV.x * ca2 + wispUV.y * sa2) * 0.5 + iTime * 0.1 + fi * 0.1;
        vec3 wCol = sawColor(wColorPos, audioAll);
        
        col += wCol * (wCore * 1.5 + wGlow * 0.4);
    }
    
    // ---- Saw wave color bands: subtle background streaks ----
    {
        float ca3 = cos(STREAM_ANGLE), sa3 = sin(STREAM_ANGLE);
        float streamCoord = uv.x * ca3 + uv.y * sa3;
        float bgSaw = fract(streamCoord * SAW_FREQUENCY * 0.8 + iTime * 0.05);
        vec3 bgCol = sawColor(streamCoord * 0.5 + iTime * 0.05, audioAll * 0.5);
        
        // Only visible near the stream
        float bgMask = exp(-abs(uv.y * ca3 - uv.x * sa3) * 2.0 / STREAM_WIDTH);
        bgMask *= 0.015 * (1.0 + bass * 2.0);
        
        col += bgCol * bgMask;
    }
    
    // ---- Tonemap ----
    col = 1.0 - exp(-col * 1.5);
    col = pow(col, vec3(0.9));

    fragColor = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
