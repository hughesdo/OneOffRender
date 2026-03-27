#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;
uniform vec4 iMouse;

out vec4 fragColor;

/* ORBITAL SINGULARITY
 * ===================
 * A black hole-like structure with orbiting energy debris and accretion disk.
 * Inspired by: Multiple orbiting spheres, glow accumulation, path functions
 *
 * Concept: A gravitational singularity with swirling matter, energy jets,
 * and orbiting fragments that react to different frequency bands.
 */

// ============================================================================
// TWEAKING VARIABLES
// ============================================================================

// MASTER CONTROLS
#define AUDIO_REACTIVE 1.0
#define AUDIO_SENSITIVITY 1.3

// SINGULARITY
#define CORE_SIZE 0.95             // Event horizon size
#define DISK_RADIUS 1.2            // Accretion disk outer radius
#define DISK_THICKNESS 0.08        // Disk vertical thickness
#define NUM_DEBRIS 8               // Number of orbiting fragments

// AUDIO RESPONSE
#define BASS_GRAVITY 0.4           // Bass affects gravitational pull
#define BASS_JET_POWER 2.0         // Bass powers energy jets
#define MID_DISK_SPIN 1.5          // Mids spin the disk faster
#define MID_DEBRIS_ORBIT 0.5       // Mids affect debris orbit speed
#define TREB_FLARE 1.5             // Treble creates flares
#define TREB_DEBRIS_GLOW 1.0       // Treble makes debris glow

// EFFECTS TOGGLES
#define ENABLE_DISK 1.0
#define ENABLE_JETS 1.0
#define ENABLE_DEBRIS 1.0
#define ENABLE_LENS_DISTORT 1.0
#define ENABLE_GLOW 1.0

// EFFECT AMOUNTS
#define DISK_BRIGHTNESS 1.5
#define JET_INTENSITY 0.8
#define DEBRIS_SIZE 0.06
#define LENS_STRENGTH 0.3
#define GLOW_INTENSITY 0.2

// COLORS
#define DISK_COLOR_INNER vec3(1.0, 0.9, 0.7)
#define DISK_COLOR_OUTER vec3(1.0, 0.3, 0.1)
#define JET_COLOR vec3(0.4, 0.6, 1.0)
#define DEBRIS_COLOR vec3(1.0, 0.5, 0.2)

// ============================================================================
// AUDIO
// ============================================================================

struct Audio {
    float bass, mid, treb;
};

Audio getAudio() {
    Audio a;
    float sens = AUDIO_SENSITIVITY * AUDIO_REACTIVE;
    a.bass = texture(iChannel0, vec2(0.05, 0.0)).x * sens;
    a.mid = texture(iChannel0, vec2(0.2, 0.0)).x * sens;
    a.treb = texture(iChannel0, vec2(0.6, 0.0)).x * sens;
    return a;
}

// ============================================================================
// UTILITIES
// ============================================================================

#define PI 3.14159265359
#define TAU 6.28318530718

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

vec3 hash3(float n) {
    return fract(sin(vec3(n, n + 1.0, n + 2.0)) * vec3(43758.5453, 22578.1459, 19642.3490));
}

// ============================================================================
// SDF PRIMITIVES
// ============================================================================

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

// ============================================================================
// SCENE COMPONENTS
// ============================================================================

// Accretion disk
float diskSDF(vec3 p, Audio audio) {
    if (ENABLE_DISK < 0.5) return 1e10;

    float spinSpeed = 1.0 + audio.mid * MID_DISK_SPIN;
    p.xz *= rot(iTime * spinSpeed * 0.5);

    // Warped disk
    float warp = sin(atan(p.z, p.x) * 3.0 + iTime * 2.0) * 0.02;
    p.y += warp;

    float r = length(p.xz);
    float diskDist = max(abs(p.y) - DISK_THICKNESS, abs(r - DISK_RADIUS * 0.6) - DISK_RADIUS * 0.4);

    // Hollow center (event horizon)
    diskDist = max(diskDist, -(length(p) - CORE_SIZE * 2.0));

    return diskDist;
}

// Energy jets
float jetSDF(vec3 p, Audio audio) {
    if (ENABLE_JETS < 0.5) return 1e10;

    float power = 0.5 + audio.bass * BASS_JET_POWER;

    // Top jet
    vec3 p1 = p - vec3(0.0, 0.0, 0.0);
    float jet1 = sdCapsule(p1, vec3(0.0, 0.2, 0.0), vec3(0.0, 1.5 * power, 0.0), 0.05);

    // Bottom jet
    float jet2 = sdCapsule(p1, vec3(0.0, -0.2, 0.0), vec3(0.0, -1.5 * power, 0.0), 0.05);

    // Add spiral detail
    float angle = atan(p.z, p.x);
    float spiral = sin(angle * 5.0 + p.y * 10.0 - iTime * 5.0) * 0.02;

    return min(jet1, jet2) + spiral;
}

// Orbiting debris
float debrisSDF(vec3 p, int idx, float t, Audio audio) {
    float fi = float(idx);
    vec3 h = hash3(fi);

    // Orbit parameters
    float orbitRadius = 0.5 + h.x * 0.8;
    float orbitSpeed = (0.3 + h.y * 0.4) * (1.0 + audio.mid * MID_DEBRIS_ORBIT);
    float orbitAngle = fi * TAU / float(NUM_DEBRIS) + t * orbitSpeed;

    // Inclined orbit
    float inclination = h.z * 0.5;
    vec3 orbitPos = vec3(
        cos(orbitAngle) * orbitRadius,
        sin(orbitAngle * 0.5) * inclination,
        sin(orbitAngle) * orbitRadius
    );

    // Pulsing size with audio
    float size = DEBRIS_SIZE * (0.5 + h.x * 0.5);
    size *= 1.0 + audio.treb * TREB_DEBRIS_GLOW * 0.3;

    return sdSphere(p - orbitPos, size);
}

// ============================================================================
// MAIN SCENE
// ============================================================================

float glow = 0.0;
int hitType = 0; // 0=none, 1=disk, 2=jet, 3=debris

float map(vec3 p, Audio audio) {
    // Gravitational lensing distortion
    if (ENABLE_LENS_DISTORT > 0.5) {
        float r = length(p);
        float gravity = CORE_SIZE / (r * r + 0.1);
        gravity *= 1.0 + audio.bass * BASS_GRAVITY;
        p += normalize(p) * gravity * LENS_STRENGTH;
    }

    float t = iTime;

    // Event horizon (sphere we can't enter)
    float core = sdSphere(p, CORE_SIZE);

    // Accretion disk
    float disk = diskSDF(p, audio);

    // Jets
    float jets = jetSDF(p, audio);

    // Debris
    float debris = 1e10;
    if (ENABLE_DEBRIS > 0.5) {
        for (int i = 0; i < NUM_DEBRIS; i++) {
            debris = min(debris, debrisSDF(p, i, t, audio));
        }
    }

    // Find minimum and track type
    float d = core;
    hitType = 0;

    if (disk < d) { d = disk; hitType = 1; }
    if (jets < d) { d = jets; hitType = 2; }
    if (debris < d) { d = debris; hitType = 3; }

    // Accumulate glow
    if (ENABLE_GLOW > 0.5) {
        glow += 0.01 / (0.01 + disk * disk) * (1.0 + audio.bass);
        glow += 0.02 / (0.01 + jets * jets) * (1.0 + audio.bass * BASS_JET_POWER);
        glow += 0.005 / (0.01 + debris * debris) * (1.0 + audio.treb);
    }

    return d;
}

vec3 normal(vec3 p, Audio audio) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy, audio) - map(p - e.xyy, audio),
        map(p + e.yxy, audio) - map(p - e.yxy, audio),
        map(p + e.yyx, audio) - map(p - e.yyx, audio)
    ));
}

// ============================================================================
// RENDERING
// ============================================================================

vec3 render(vec3 ro, vec3 rd, Audio audio) {
    vec3 col = vec3(0.0);
    float t = 0.0;
    glow = 0.0;

    for (int i = 0; i < 120; i++) {
        vec3 p = ro + rd * t;
        float d = map(p, audio);

        if (d < 0.001) {
            vec3 n = normal(p, audio);

            // Color based on what we hit
            if (hitType == 1) {
                // Disk - gradient from inner to outer
                float r = length(p.xz) / DISK_RADIUS;
                col = mix(DISK_COLOR_INNER, DISK_COLOR_OUTER, r) * DISK_BRIGHTNESS;
                col *= 1.0 + audio.bass * 0.5;
            }
            else if (hitType == 2) {
                // Jets
                col = JET_COLOR * JET_INTENSITY;
                col *= 1.0 + abs(p.y) * 2.0; // Brighter further out
                col += audio.treb * TREB_FLARE * vec3(0.5, 0.7, 1.0);
            }
            else if (hitType == 3) {
                // Debris
                col = DEBRIS_COLOR;
                col *= 1.0 + audio.treb * TREB_DEBRIS_GLOW;
            }
            else {
                // Core - pure black with edge glow
                float fresnel = pow(1.0 - abs(dot(n, -rd)), 3.0);
                col = vec3(fresnel) * DISK_COLOR_INNER * 0.5;
            }

            // Rim lighting
            float rim = pow(1.0 - abs(dot(n, -rd)), 2.0);
            col += rim * DISK_COLOR_INNER * 0.3;

            break;
        }

        if (t > 10.0) break;
        t += d * 0.8;
    }

    // Add accumulated glow
    vec3 glowCol = DISK_COLOR_INNER * glow * GLOW_INTENSITY;
    glowCol += JET_COLOR * glow * 0.5;
    col += glowCol;

    // Fog toward black hole
    float coreDist = length(ro + rd * min(t, 10.0));
    if (coreDist < 0.5) {
        col *= smoothstep(CORE_SIZE, 0.5, coreDist);
    }

    return col;
}

// ============================================================================
// MAIN
// ============================================================================

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    Audio audio = getAudio();

    // Camera orbits the singularity
    float camAngle = iTime * 0.15;
    float camDist = 3.0;
    float camHeight = sin(iTime * 0.1) * 0.5 + 0.5;

    vec3 ro = vec3(
        sin(camAngle) * camDist,
        camHeight,
        cos(camAngle) * camDist
    );
    vec3 ta = vec3(0.0);

    vec3 fw = normalize(ta - ro);
    vec3 rt = normalize(cross(vec3(0.0, 1.0, 0.0), fw));
    vec3 up = cross(fw, rt);

    vec3 rd = normalize(fw * 1.5 + uv.x * rt + uv.y * up);

    vec3 col = render(ro, rd, audio);

    // Star field background
    vec2 starUV = rd.xy * 5.0 + rd.z;
    float stars = pow(hash(dot(floor(starUV * 100.0), vec2(12.9898, 78.233))), 20.0);
    col += stars * 0.5;

    // Vignette
    float vig = 1.0 - length(uv) * 0.4;
    col *= vig;

    // Tone mapping
    col = 1.0 - exp(-col * 1.5);
    col = pow(col, vec3(0.9));

    fragColor = vec4(col, 1.0);
}
