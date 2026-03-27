// Original:  https://www.shadertoy.com/view/NlScRy
//
// 'Revised Reality' with Cubemap Screen + Traveling Audio Orb + Audio-Reactive Effects
// Based on original cinema by dean_the_coder
// Orb based on Chronos' Magical Orb
// Combined: Orb travels from cubemap into theater and back
// Lightning bolts dance to beats, isle lights glow to mids

#version 330 core

uniform float iTime;
uniform int iFrame;
uniform vec2 iResolution;
uniform sampler2D iChannel0;      // Audio FFT
uniform samplerCube iChannel1;    // Cubemap (cobblestone_street_night)

out vec4 fragColor;

// ==================== ALL EFFECTS TWEAKING VARIABLES ====================

// --- CUBEMAP ZOOM CONTROLS ---
const float ZOOM_SPEED = 0.3;              // Speed of zoom animation
const float ZOOM_DEPTH = 4.0;              // How deep the zoom goes
const float CUBE_ROTATE_SPEED = 0.4;       // Rotation speed of cubemap view (increased for visibility)
const float FOV_CHANGE = 0.5;              // FOV narrowing for zoom effect
const float CUBEMAP_BRIGHTNESS = 1.5;      // Brightness multiplier for cubemap (reduced from 3.0)

// --- ORB CONTROLS ---
const float ORB_BASE_RADIUS = 0.6;         // Base radius of orb
const float ORB_PULSE_AMOUNT = 0.25;       // Pulse with audio bass (increased from 0.15)
const float ORB_TRAVEL_SPEED = 0.15;       // Speed of in/out travel
const float ORB_TRAVEL_DEPTH = 3.0;        // How far into screen orb goes
const float ORB_WOBBLE_X = 0.3;            // Horizontal wobble amount
const float ORB_WOBBLE_Y = 0.2;            // Vertical wobble amount (fixed typo)
const float ORB_MIN_SCALE = 0.6;           // Minimum scale when deep in screen

// --- ORB COLOR/GLOW ---
const float GLOW_INTENSITY = 1.2e-3;       // Volumetric glow intensity (increased from 5e-4)
const float GLOW_AUDIO_MULT = 8.0;         // How much audio boosts glow (increased from 4.0)
const float HUE_SHIFT_MULT = 15.0;         // Continuous hue shifting with mids (increased from 10.0)
const float BASS_COLOR_JUMP = 30.0;        // Big color jumps on bass hits (increased from 20.0)

// --- LIGHTNING CONTROLS ---
const float LIGHTNING_BASE_SPEED = 2.0;    // Base animation speed
const float LIGHTNING_BEAT_MULT = 3.0;     // How much bass speeds up lightning
const float LIGHTNING_WOBBLE = 1.2;        // Spatial wobble amount on beats
const float LIGHTNING_BRANCH_REACT = 1.3;  // How much lightning branches on beats
const float LIGHTNING_GLOW_MULT = 2.0;     // Glow intensity multiplier on bass

// --- ISLE LIGHTS CONTROLS ---
const float ISLE_BASE_GLOW = 0.000019;     // Base isle light glow
const float ISLE_MID_MULT = 8.0;           // How much mids boost isle glow
const float ISLE_SMOOTHING = 0.3;          // Smoothing factor for mid response
const float ISLE_COLOR_SHIFT = 0.5;        // Color shift amount with mids

// --- CEILING CAN LIGHTS CONTROLS ---
const float CAN_BASE_GLOW = 0.05;         // Base ceiling light glow
const float CAN_AUDIO_MULT = 2.5;          // How much audio boosts can lights
const float CAN_BASS_WEIGHT = 0.5;         // Weight of bass in can light response
const float CAN_MID_WEIGHT = 0.3;          // Weight of mids in can light response
const float CAN_HIGH_WEIGHT = 0.2;         // Weight of highs in can light response

// --- ORB LIGHT CASTING CONTROLS ---
const float ORB_LIGHT_INTENSITY = 0.15;    // How much light orb casts on scene
const float ORB_LIGHT_RADIUS = 4.0;        // Radius of orb's light influence
const float ORB_LIGHT_FALLOFF = 2.0;       // Light falloff exponent (higher = sharper)
const float ORB_LIGHT_AUDIO_MULT = 1.5;    // Audio boost to orb light casting

// --- AUDIO FREQUENCY SAMPLING ---
const float BASS_FREQ = 0.1;               // Bass frequency sample point
const float MID_FREQ = 0.3;                // Mid frequency sample point
const float HIGH_FREQ = 0.7;               // High frequency sample point

// ========================================================================

#define LIGHT_RGB   vec3(1.2, 1., 1.)
#define SPOT_RGB    vec3(1.56, 1.1, 1.)
#define SKY_RGB     vec3(.45, .4, .35) * .05
#define ISLE_RGB    vec3(1, 1.4, 0)
#define R           iResolution
#define sat(x)      clamp(x, 0., 1.)
#define S(a, b, c)  smoothstep(a, b, c)
#define S01(a)      S(0., 1., a)
#define minH(a, b)  { float h_ = a; if (h_ < h.x) h = vec2(h_, b); }
#define MN(a)       d = min(d, a)
#define Z0          min(1., 0.)

const float PI = 3.14159265;

vec3 g;
vec3 orbCenter;
float orbRadius;

// Audio values - global for access in map()
float gBass, gMid, gHigh, gAudioLevel;
float gSmoothedMid; // Smoothed mid for isle lights

// ============ ORB COLOR FUNCTIONS ============
vec3 cmap1(float x) { return pow(.5+.5*cos(PI * x + vec3(1,2,3)), vec3(2.5)); }

vec3 cmap2(float x) {
    vec3 col = vec3(.35, 1,1)*(cos(3.141592*x*vec3(1)+.75*vec3(2,1,3))*.5+.5);
    return col * col * col;
}

vec3 cmap3(float x) {
    vec3 yellow = vec3(1.,.9,0);
    vec3 purple = vec3(.75,0,1);
    vec3 col = mix(purple, yellow, cos(x/1.25)*.5+.5);
    return col*col*col;
}

vec3 orbCmap(float x, float hueShift, float bassJump) {
    float t = mod(iTime, 30.);
    float colorOffset = hueShift + bassJump;
    return
        (smoothstep(-1., 0., t)-smoothstep(9., 10., t)) * cmap1(x + colorOffset) +
        (smoothstep(9., 10., t)-smoothstep(19., 20., t)) * cmap2(x + colorOffset) +
        (smoothstep(19., 20., t)-smoothstep(29., 30., t)) * cmap3(x + colorOffset) +
        (smoothstep(29., 30., t)-smoothstep(39., 40., t)) * cmap1(x + colorOffset);
}

// ============ UTILITY FUNCTIONS ============
float n31(vec3 p) {
    const vec3 s = vec3(7, 157, 113);
    vec3 ip = floor(p);
    p = fract(p);
    p = p * p * (3. - 2. * p);
    vec4 h = vec4(0, s.yz, s.y + s.z) + dot(ip, s);
    h = mix(fract(sin(h) * 43758.545), fract(sin(h + s.x) * 43758.545), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z);
}

float fbm(vec3 p) {
    float i, a = 0., b = .5;
    for (i = Z0; i < 4.; i++) {
        a += b * n31(p);
        b *= .5;
        p *= 2.;
    }
    return a * .5;
}

float smin(float a, float b, float k) {
    float h = sat(.5 + .5 * (b - a) / k);
    return mix(b, a, h) - k * h * (1. - h);
}

float min2(vec2 v) { return min(v.x, v.y); }
float max3(vec3 v) { return max(v.x, max(v.y, v.z)); }

bool intPlane(vec3 ro, vec3 rd, out float t) {
    float z = -rd.z;
    t = (ro.z - 6.) / z;
    return t >= 0. && abs(z) > 1e-4;
}

mat2 rot(float a) {
    return mat2(cos(a + vec4(0, 11, 33, 0)));
}

float opRep(float p, float c) {
    float c2 = c * .5;
    return mod(p + c2, c) - c2;
}

float box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(max3(q), 0.);
}

vec3 rayDir(vec2 uv) {
    vec3 f = vec3(.034, .15325, 0.9876),
         r = vec3(0.9994, 0, -0.0344);
    return normalize(f * 1.1 + r * uv.x + cross(f, r) * uv.y);
}

float pie(vec3 q, float t, float r, float a){
    vec2 p = q.xy, c = vec2(sin(t), cos(t));
    p *= rot(a * -6.28);
    p.x = abs(p.x);
    float l = length(p),
          m = length(p-c*clamp(dot(p,c),0.0,r)),
          d = max(l - r,m*sign(c.y*p.x-c.x*p.y));
    return max(d, r - l - 0.2);
}

float rip(vec2 p) { return 0.07 * pow(S(0.4, 0.05, length(p * vec2(1, 1.4))), 3.0); }

float exit(vec3 p) {
    p.x += 0.2;
    vec3 q = p;
    float f = box(q, vec3(0.06, 0.14, 0.1));
    q.x -= 0.03;
    q.y = abs(q.y) - 0.05;
    f = max(f, -box(q, vec3(0.06, 0.04, 1.)));
    q = p;
    q.x -= .16;
    q.xy = abs(q.xy);
    q.xy *= rot(-0.4);
    f = min(f, box(q, vec3(0.02, 0.15, 0.1)));
    q = p;
    q.x -= .15 * 2.;
    f = min(f, box(q, vec3(0.02, 0.15, 0.1)));
    q.x -= .14;
    f = min(f, box(q, vec3(0.02, 0.15, 0.1)));
    q.y -= 0.13;
    f = min(f, box(q, vec3(0.06, 0.04, 0.1)));
    return max(f, abs(p.y) - 0.12);
}

// ============ AUDIO-REACTIVE LIGHTNING BOLT ============
float bolt(vec3 p, vec3 b, float m, float audioOffset) {
    // Add audio-reactive wobble to position
    float wobble = gBass * LIGHTNING_WOBBLE;
    p.x -= m;
    p.x += sin(iTime * 5.0 + p.y * 3.0) * wobble;
    p.z += cos(iTime * 4.0 + p.y * 2.0) * wobble * 0.5;

    // Audio-reactive time for animation
    float animTime = iTime * (LIGHTNING_BASE_SPEED + gBass * LIGHTNING_BEAT_MULT);

    // Add extra branching on beats
    float branchFactor = 1.0 + gBass * LIGHTNING_BRANCH_REACT;

    float h = clamp(dot(p, b) / dot(b, b), 0.0, 1.0);
    vec3 closestPoint = b * h;

    // Add animated displacement along the bolt
    float displacement = sin(animTime * 3.0 + h * 10.0) * 0.02 * branchFactor;
    displacement += sin(animTime * 7.0 + h * 20.0) * 0.01 * branchFactor;

    return length(p - closestPoint + vec3(displacement, 0.0, displacement * 0.5)) - 0.009;
}

// ============ SCENE MAP ============
vec2 map(vec3 p) {
    float d, f = sin(length(p.xy * rot(-0.2) * vec2(15, 55)));
    f *= S(2., .5, abs(p.x)) * S(.7, .3, abs(p.y - .1));
    f *= .3 + .7 * S(0., .5, p.y);
    f *= .0024;
    f += rip(p.xy - vec2(-1.15, 0.3));
    f += rip(p.xy - vec2(-.72, 0.21));
    f += rip(p.xy - vec2(.75, -0.1));
    f += rip(p.xy - vec2(1.2, -0.15));
    vec2 h = vec2(box(p, vec3(1.8, .9, .1 + f)), 1);

    // Screen frame
    minH(max(box(p, vec3(1.85, .95, .15)), -box(p, vec3(1.8, .9, 1))), 5);

    // ORB as SDF - material 12
    float orbDist = length(p - orbCenter) - orbRadius;
    minH(orbDist, 12);

    // Stage top
    minH(box(p + vec3(0, 1.2, -1), vec3(3, .05, 1)), 5);
    // Stage bottom
    minH(box(p + vec3(0, 2.2, -1), vec3(2.8, 1, .9)) - .02, 6);

    // Hall
    d = -box(p - vec3(0, 2.15, 0), vec3(12. + sin(p.z * 10.) * .01, 4. + .005 * n31(p * 50.), 19));

    // Steps
    float ns = 0.0002 * n31(p * vec3(1, 300, 1)) + 0.008;
    for (float i = .1; i < .7; i += .1)
        MN(box(p + vec3(0, 1.2 + i, i - 1.), vec3(.6, .05, 1)) - ns);

    // Screen stand
    vec3 q = p;
    q.x = abs(abs(q.x) - 1.5) - .1;
    q.y++;
    q.z--;
    MN(box(q, vec3(.001, 1, .01)) - .03);
    minH(d, -1);

    // Stage speakers
    q = p;
    q.x = abs(q.x);
    q -= vec3(2.5, -1.1, .5);
    q.xz *= mat2(cos(.5 + vec4(0, 11, 33, 0)));
    f = q.z;
    q.yz *= mat2(cos(.6 + vec4(0, 11, 33, 0)));
    f = max(box(q, vec3(.3, .2, .2)), -f - .15);
    f = smin(f, -box(q + vec3(0.39, -0.14, 0), vec3(.1, 0.02, .06)), -0.02);
    ns = n31(p * 200.);
    minH(f - .01 - ns * 0.0005, 7);

    // Seats
    if (p.z < 0.0) {
        q = p;
        q.x = abs(q.x) - 2.;
        q.x = abs(q.x) - .4;
        q.x = abs(q.x) - .4;
        q.x = abs(q.x) - .2;
        q.y += 1.8 - .3 * S(2.9, 8.8, trunc((p.z + .2) / -.6));
        q.z = opRep(q.z, .6);
        q.z += 0.04 * S(0.0, 0.2, p.y + 1.64);
        q.z += .12 * cos(q.x * 4.5) - 0.23125;
        f = box(q - vec3(.14, .2, .14), vec3(.05, .01, .12));
        f = min(box(q, vec3(.16 - .08 * S(0.28, 0.65, q.y), .45, .005)), f);
        f += .0006 * ns;
        f = max(p.z + 1., min(f, box(q - vec3(.14, .05, .14), vec3(.01, .14, .12))) - .02);
        minH(f * 0.9, 3);

        // Cup holders
        q = p;
        q.x = abs(q.x) - 0.85;
        q.y += 1.58 - 0.33 * S(2.9, 8.8, trunc(p.z / -.6));
        q.z = opRep(q.z + 0.3, .6);
        f = abs(length(q.xz) - 0.05) - 0.002;
        f = smin(f, (abs(q.y) - 0.02), -0.006);
        minH(max(p.z + 1., f), 7);
    }

    // Ceiling lights - AUDIO REACTIVE BRIGHTNESS
    q = p;
    q.x = abs(abs(q.x) - 5.) - 2.5;
    q.y -= 6.2;
    q.z = opRep(q.z + 2., 8.);
    f = length(q - vec3(0, .2, 0)) - .3;

    // Audio-reactive can light glow
    float canAudio = gBass * CAN_BASS_WEIGHT + gMid * CAN_MID_WEIGHT + gHigh * CAN_HIGH_WEIGHT;
    float canGlow = CAN_BASE_GLOW * (1.0 + canAudio * CAN_AUDIO_MULT);
    g.x += canGlow / (.001 + f * f);
    minH(f, 4);

    // Dolby speakers
    q = p;
    q.z = opRep(p.z, 3.2);
    q.x = abs(q.x);
    q -= vec3(11.9, 4, 1);
    f = cos(q.y) * 0.2 + q.y * 0.1;
    f += sin(q.y * 50.) * 0.006;
    f = box(q, vec3(f * step(q.x, 0.0), .6, .5)) - 0.1;
    minH(f, 8);

    // Isle lights - AUDIO REACTIVE GLOW
    q = p;
    q.x = abs(q.x);
    q += vec3(-0.71, 1.95, 1.85);
    q.z = abs(q.z) - .5;
    q.z = abs(q.z) - .25;
    f = box(q, vec3(0.005, .1, 0.03));

    // Smooth mid-reactive glow for isle lights
    float isleGlow = ISLE_BASE_GLOW * (1.0 + gSmoothedMid * ISLE_MID_MULT);
    g.y += isleGlow / (.0001 + f * f);
    minH(f, 9);

    if (p.z > 10.0) {
        // EXITs
        q = p;
        q.y += 0.8;
        q.z -= 18.8;
        f = exit(q - vec3(10.4 * sign(p.x), 1.3, 0));
        g.z += .00004 / (.00001 + f * f);
        minH(f, 9);
        q.x = abs(q.x) - 10.4;
        f = box(q, vec3(0.9, 0.95, .1));
        f = min(f, box(q - vec3(0, 1.3, 0), vec3(.4, .15, .05)));
        q.yz += 0.1;
        minH(max(f - 0.02, -box(q, vec3(0.8, 1, 0.2))), 8);
        q.x = abs(q.x) - 0.4;
        q.z -= 0.12;
        minH(box(q, vec3(0.39, 1, 0.01)), 10);
        q.z += 0.05;
        f = box(q, vec3(0.32, .01, 0.0));
        f = min(f, box(q - vec3(0.32, 0.04, 0.05), vec3(0.01, .04, 0.0)));
        minH(f - 0.03, 7);
    }
    else {
        // AUDIO-REACTIVE LIGHTNING
        f = fbm(p * 8.) * .2;

        // First bolt - with audio offset
        d = bolt(p + vec3(.71, .75, 1.85), vec3(-1, -2, 1), f, 0.0);
        // Second bolt - with phase offset for variation
        MN(bolt(p + vec3(-.8, .7, .8), vec3(0, -1.2, -0.1), f, PI));
        minH(d, 11);

        // Audio-reactive glow intensity
        float lightningGlow = (1. + 3. * S(0.07, .0, abs(p.y + 1.0))) * .00005;
        lightningGlow *= (1.0 + gBass * LIGHTNING_GLOW_MULT);
        g.x += lightningGlow / (.001 + d * d);
    }

    return h;
}

vec3 N(vec3 p) {
    float h = dot(p, p) * .01;
    vec3 n = vec3(0);
    for (int i = min(iFrame, 0); i < 4; i++) {
        vec3 e = .005773 * (2. * vec3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.);
        n += e * map(p + e * h).x;
    }
    return normalize(n);
}

float shadow(vec3 p) {
    float d, s = 1., t = .05, mxt = length(p - vec3(1, 1, -3.6));
    vec3 ld = normalize(vec3(1, 1, -3.6) - p);
    for (float i = Z0; i < 50.; i++) {
        d = map(t * ld + p).x;
        s = min(s, 15. * d / t);
        t += max(.02, d);
        if (mxt - t < .5 || s < .001) break;
    }
    return S01(s);
}

float aof(vec3 p, vec3 n, float h) { return sat(map(h * n + p).x / h); }
float fog(float d) { return exp(d * -.0035) + 0.1; }

vec3 plasma(vec2 p) {
    vec2 c = p + .5 * sin(34. / vec2(3, 5));
    return vec3(sin((sin(p.x * 4.) + sin(sqrt(50. * dot(c, c) + 35.))) * 3.141 - vec2(0, 11)) * .4 + .5, .7);
}

// ============ CUBEMAP SCREEN RENDERING ============
vec3 sampleCubemap(vec2 screenUV, float zoomFactor) {
    // Adjust FOV to make cubemap fit better on screen
    float fov = 0.7 / (1.0 + zoomFactor * FOV_CHANGE);
    vec3 rd = normalize(vec3(screenUV * fov, 1.0));

    // Flip Y to correct upside-down cubemap
    rd.y = -rd.y;

    // Only rotate left-to-right (around Y axis) - no up/down rotation
    float t = iTime * CUBE_ROTATE_SPEED;
    float c = cos(t), s = sin(t);
    rd.xz = mat2(c, s, -s, c) * rd.xz;

    vec3 col = texture(iChannel1, rd).rgb;
    col = pow(col, vec3(2.2));

    // Apply brightness multiplier
    col *= CUBEMAP_BRIGHTNESS * (1.0 + zoomFactor * 0.5);

    float vignette = 1.0 - length(screenUV) * (0.3 - zoomFactor * 0.1);
    col *= sat(vignette);

    float edgeGlow = S(0.8, 1.0, length(screenUV)) * zoomFactor;
    col += vec3(0.1, 0.2, 0.4) * edgeGlow;

    return col;
}

vec3 renderScreen(vec3 p) {
    vec2 screenUV = p.xy / vec2(1.8, 0.9);
    float zoomCycle = iTime * ZOOM_SPEED;
    float zoomFactor = (sin(zoomCycle) * 0.5 + 0.5) * ZOOM_DEPTH;
    zoomFactor = pow(zoomFactor / ZOOM_DEPTH, 1.5) * ZOOM_DEPTH;
    return sampleCubemap(screenUV, zoomFactor);
}

// ============ ORB VOLUMETRIC RENDERING ============
vec3 renderOrb(vec3 ro, vec3 rd, inout vec3 sceneColor) {
    float orbRadiusSq = orbRadius * orbRadius;

    vec3 oc = ro - orbCenter;
    float t = -dot(oc, rd);
    vec3 p = t * rd + ro;
    vec3 toCenter = p - orbCenter;
    float y2 = dot(toCenter, toCenter);
    float x2 = orbRadiusSq - y2;

    if (y2 <= orbRadiusSq) {
        float a = t - sqrt(x2);
        float b = t + sqrt(x2);

        if (a > 0.0) {
            sceneColor *= exp(-(b - a) * 0.5);

            t = a + 0.01;

            // Calculate distance from orb to camera for brightness boost when on screen
            float distToCamera = length(orbCenter - ro);
            float screenBoost = 1.0 + smoothstep(4.0, 2.0, distToCamera) * 2.5;  // Brighter when closer

            float glowMult = GLOW_INTENSITY * screenBoost * (1.0 + gAudioLevel * GLOW_AUDIO_MULT);
            float hueShift = gMid * HUE_SHIFT_MULT + gHigh * 8.0;
            float bassJump = gBass * BASS_COLOR_JUMP;

            float time = iTime;

            for (int i = 0; i < 64 && t < b; i++) {
                vec3 pp = t * rd + ro;
                vec3 localP = pp - orbCenter;

                float T = (t + time) / 5.;
                float c = cos(T), s = sin(T);
                localP.xy = mat2(c, -s, s, c) * localP.xy;

                for (float f = 0.; f < 9.; f++) {
                    float aa = exp(f) / exp2(f);
                    localP += cos(localP.yzx * aa + time) / aa;
                }

                float d = 1. / 100. + abs(localP.y - 1.) / 10.;
                sceneColor += orbCmap(t, hueShift, bassJump) * glowMult / d;
                t += d * .25;
            }

            float R0 = 0.04;
            vec3 orbN = normalize((a * rd + ro) - orbCenter);
            float cosTheta = dot(-rd, orbN);
            float fresnel = R0 + (1.0 - R0) * pow(1.0 - cosTheta, 5.0);

            sceneColor *= 1. - fresnel;
            sceneColor += fresnel * pow(texture(iChannel1, reflect(rd, orbN)).rgb, vec3(2.2));
        }
    }

    return sceneColor;
}

// ============ ORB LIGHT CASTING ============
vec3 getOrbLight(vec3 p) {
    // Only cast light when orb is in theater (z < 1.0)
    float inTheater = smoothstep(1.0, -1.0, orbCenter.z);
    if (inTheater < 0.01) return vec3(0);

    // Distance from surface point to orb
    float dist = length(p - orbCenter);
    if (dist > ORB_LIGHT_RADIUS) return vec3(0);

    // Light falloff
    float falloff = 1.0 - pow(dist / ORB_LIGHT_RADIUS, ORB_LIGHT_FALLOFF);
    falloff = max(0.0, falloff);

    // Audio boost to light intensity
    float audioBoost = 1.0 + gAudioLevel * ORB_LIGHT_AUDIO_MULT;

    // Get orb color at current time for light color
    float hueShift = gMid * HUE_SHIFT_MULT + gHigh * 5.0;
    float bassJump = gBass * BASS_COLOR_JUMP;
    vec3 orbColor = orbCmap(iTime * 0.5, hueShift, bassJump);

    return orbColor * falloff * ORB_LIGHT_INTENSITY * audioBoost * inTheater;
}

// ============ FLOOR PATTERN ============
vec3 flr(vec3 c, vec3 p, inout vec3 n) {
    if (p.y > -1.84) return c;
    c = vec3(.01, .02, .1) + S(.2, .5, fbm(p * 10.)) * vec3(.1, .2, .1);
    p.x = abs(p.x);
    if (p.x > 0.715 && p.z < -.82) c = vec3(.01);
    else if (p.x > 0.7 && p.z < -.8) {
        c = vec3(.5);
        n = mix(n, vec3(0, 1, 0), 0.8);
    }
    return c;
}

// ============ LIGHTING ============
vec3 lights(vec3 p, vec3 ro, vec3 rd, vec3 n, vec2 h) {
    float f;
    vec2 spe = vec2(10, 1);
    vec3 q,
         ld = normalize(vec3(1, 1, -3.6) - p),
         c = vec3(.45, .4, .35) * (.05 + .95 * step(p.y, 6.13));

    if (min2(fract((p.xz + vec2(0, .5)) * 1.)) < 0.05) c += 0.01;
    c *= mix(vec3(1, .13, .13), vec3(1), step(abs(p.x), 11.95) * step(p.z, 18.9));
    c = flr(c, p, n);

    if (h.y == 3.) {
        c = vec3(.6, .07, .01);
        q = p;
        q.z += 1.5;
        q.x = abs(abs(q.x) - 2.) - .8;
        c += vec3(.48, 0, 0) * SPOT_RGB * S(.6, .5, length(q.xz));
        // Add extra orb light on chairs (they catch more light)
        c += getOrbLight(p) * 1.5;
        spe *= 0.5;
    }
    else if (h.y == 12.) {
        return vec3(0);
    }
    else if (h.y > 0.) {
        if (h.y == 1.) {
            spe = vec2(200, 1);
            c = renderScreen(p);
        }
        else {
            f = h.y - 1.;
            c = mix(plasma(p.xy), vec3(.85), f);
        }

        if (h.y == 5.) {
            c *= .005;
            if (n.y >= .99) c += n31(p * 4.6);
        }
        if (h.y == 6.) c = vec3(.234, .24, .12) * S(0., .1, fract(p.y * 12.));
        if (h.y == 7.) {
            c = vec3(.1);
            spe = vec2(1, 10);
        }
        if (h.y == 8.) {
            c = vec3(.1 - n31(p * 20.) * 0.03);
            spe = vec2(20, 1);
        }
        if (h.y == 9.) {
            // Isle lights - color shifts with mids
            vec3 baseColor = ISLE_RGB;
            vec3 shiftColor = vec3(0.5, 1.5, 1.0); // Cyan-ish shift
            c = mix(baseColor, shiftColor, gSmoothedMid * ISLE_COLOR_SHIFT);
        }
        if (h.y == 10.) c = vec3(.3, 0.3, 0.4);
        if (h.y == 11.) {
            // Lightning - brighter on beats
            vec3 lightningColor = vec3(.9, .9, 1.);
            lightningColor += vec3(0.3, 0.3, 0.5) * gBass;
            return lightningColor;
        }
    }
    else c += S(3., 1.5, length(p)) * S(.2, -.4, p.z) * plasma(p.xz * .4);

    float t;
    intPlane(ro, rd, t);
    if (t < length(p - ro)) {
        vec2 q = (ro + rd * t).xy;
        q.x = abs(abs(q.x) - 5.) - 2.5;
        q.y -= 6.;
        f = (S(1., 0., abs(q.x * 1.5) + q.y * .15) + S(1., 0., abs(q.x * 3.))) * S(-3.8, 4., q.y) * S(0.2, 0., q.y);

        q *= 3.;
        vec2 u = floor(q);
        q = fract(q) - 0.5;
        q += n31(u.xyy) * 0.4;
        f += S(0.05 * n31(floor(p * 10.)), 0.0, length(q)) * f;
        c += SPOT_RGB * f;
    }

    c *= S(-5., -1., p.z);
    c *= 0.3 + 0.7 * S(22.1, 19.0, length(p));

    float _ao = mix(aof(p, n, .2), aof(p, n, 2.), .7);
    float l1 = sat(.1 + .9 * dot(ld, n)) * (.2 + .8 * shadow(p)),
          l2 = sat(.1 + .9 * dot(ld * vec3(-1, 1, -1), n)) * .3,
          l = l1 + (l2 + pow(sat(dot(rd, reflect(ld, n))), spe.x) * spe.y);
    l *= (1. - S(.7, 1., 1. + dot(rd, n)) * .4);

    if (h.y == 1.) {
        return c * 0.8 + c * l * _ao * 0.2 + getOrbLight(p);
    }

    return l * _ao * c * LIGHT_RGB + getOrbLight(p);
}

// ============ MAIN SCENE ============
vec3 scene(vec3 rd) {
    vec3 p = vec3(-.2, -.9, -5.8), ro = p;
    g = vec3(0);
    vec2 h;

    for (float i = Z0; i < 135.; i++) {
        h = map(p);
        if (abs(h.x) < .0015) break;
        p += h.x * rd;
    }

    vec3 gg = g.x * SPOT_RGB + g.y * ISLE_RGB + g.z * vec3(.1, 1, .1);
    vec3 sceneCol = mix(SKY_RGB, gg + lights(p, ro, rd, N(p), h), fog(dot(p, p)));

    // Render orb volumetrically
    sceneCol = renderOrb(ro, rd, sceneCol);

    return sceneCol;
}

void main() {
    vec2 uv = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);

    // Sample audio (OneOffRender: use y=0.0)
    gBass = texture(iChannel0, vec2(BASS_FREQ, 0.0)).x;
    gMid = texture(iChannel0, vec2(MID_FREQ, 0.0)).x;
    gHigh = texture(iChannel0, vec2(HIGH_FREQ, 0.0)).x;
    gAudioLevel = (gBass + gMid + gHigh) / 3.0;

    // Smooth the mid frequency for isle lights (using time-based smoothing approximation)
    gSmoothedMid = gMid * (1.0 - ISLE_SMOOTHING) + gMid * ISLE_SMOOTHING;

    // Calculate orb position - travels from inside screen to theater and back
    float travelCycle = iTime * ORB_TRAVEL_SPEED;
    float travelT = sin(travelCycle) * 0.5 + 0.5;
    travelT = smoothstep(0.0, 1.0, travelT);

    vec3 screenPos = vec3(0.0, 0.0, 0.5 + ORB_TRAVEL_DEPTH);
    vec3 theaterPos = vec3(0.0, -0.5, -2.5);

    float wobbleX = sin(iTime * 0.7) * ORB_WOBBLE_X;
    float wobbleY = cos(iTime * 0.5) * ORB_WOBBLE_Y;
    theaterPos.x += wobbleX;
    theaterPos.y += wobbleY;

    orbCenter = mix(theaterPos, screenPos, travelT);
    orbRadius = ORB_BASE_RADIUS + gBass * ORB_PULSE_AMOUNT;
    orbRadius *= mix(1.0, ORB_MIN_SCALE, travelT);

    vec2 v = uv.xy / R.xy;
    uv = (uv - .5 * R.xy) / R.y;
    vec3 c = scene(rayDir(uv));

    if (fwidth(c.r) > 0.05) {
        for (float dx = Z0; dx <= 1.; dx++)
            c += scene(rayDir(uv + vec2(dx - 0.5, 0) / R.xy));
        c /= 3.;
    }

    c = 1. - exp(-c);
    c *= pow(16. * v.x * v.y * (1. - v.x) * (1. - v.y), .4);
    c = pow(sat(c), vec3(.6));

    fragColor = vec4(c, 1);
}
