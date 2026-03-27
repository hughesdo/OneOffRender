#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// Audio-Reactive Mirrored Room — Shadertoy (iChannel0 = Audio)
// Original: https://www.shadertoy.com/view/ss2cz3
// Modified: floor & ceiling tiles react to bass hits via iChannel0
//
// SETUP: Set iChannel0 to "Music" or any audio source in Shadertoy

// ============================================================
// TWEAKABLES — adjust these to taste
// ============================================================
#define BASS_COLOR_INTENSITY   2.5    // how much bass shifts tile hue
#define BASS_SCALE_AMOUNT      0.4    // how much bass warps tile scale
#define BASS_BRIGHTNESS_BOOST  3.5    // brightness punch on hits
#define BASS_BLINK_INTENSITY   4.0    // blink node brightness on hits
#define BASS_SMOOTH            0.25   // smoothing (lower = snappier)
#define BASS_FREQ_LO           0.01   // low end of bass sample range
#define BASS_FREQ_HI           0.12   // high end of bass sample range
#define MID_FREQ_LO            0.15   // mid freq sample start
#define MID_FREQ_HI            0.35   // mid freq sample end

// --- PLASMA RAINBOW CONTROLS ---
#define PLASMA_INTENSITY       1.0    // 0=off, 1=full rainbow plasma overlay
#define PLASMA_SPEED           1.2    // swirl speed of plasma field
#define PLASMA_SCALE           3.5    // spatial frequency of plasma waves
#define PLASMA_BASS_WARP       2.0    // how much bass distorts plasma field
#define PLASMA_HUE_SPREAD      1.0    // rainbow spread (higher = more colors)
#define PLASMA_SATURATION      0.85   // color richness (0=grey, 1=vivid)
#define PLASMA_GLOW_ON_HIT     2.5    // extra glow multiplier on bass hits

#define PI  3.141592654
#define BlackRegionSize  0.03
#define L2(x)  dot(x, x)
#define RotObj  rot_x(iTime/2.)*rot_z(iTime/3.)
#define PolyhedraEdgeSize  0.02
#define PolyhedraFaceOffset  0.
#define RoomSize  vec3(5, 2.5, 5)
#define RoomFrameSize  0.5
#define WindowFrameSize vec2(RoomFrameSize*1.2, 0)
#define MAX_TILING_REFLECTIONS 12
#define MAX_TRACE_STEPS  128
#define MAX_RAY_BOUNCES  15
#define PRECISION        1e-3
#define MAX_MARCH_STEP   1.0

const vec3 pqr_wythoff = vec3(5, 2, 3);
const vec3 bary = vec3(1, 1, 1);

mat3 matS, triS;
vec3 v0S;

// ============================================================
// Audio helpers
// ============================================================
float getBass() {
    float b = 0.0;
    b += texture(iChannel0, vec2(BASS_FREQ_LO, 0.25)).x;
    b += texture(iChannel0, vec2(0.05, 0.25)).x;
    b += texture(iChannel0, vec2(BASS_FREQ_HI, 0.25)).x;
    return b / 3.0;
}

float getMids() {
    float m = 0.0;
    m += texture(iChannel0, vec2(MID_FREQ_LO, 0.25)).x;
    m += texture(iChannel0, vec2(0.25, 0.25)).x;
    m += texture(iChannel0, vec2(MID_FREQ_HI, 0.25)).x;
    return m / 3.0;
}

float getHighs() {
    float h = 0.0;
    h += texture(iChannel0, vec2(0.5, 0.25)).x;
    h += texture(iChannel0, vec2(0.65, 0.25)).x;
    h += texture(iChannel0, vec2(0.8, 0.25)).x;
    return h / 3.0;
}

// ============================================================
// HSV conversion for vivid rainbow
// ============================================================
vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0/3.0, 1.0/3.0)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

// ============================================================
// Audio-reactive rainbow plasma field
// Returns vivid rainbow color based on position + audio
// ============================================================
vec3 plasma_rainbow(vec2 uv, float count, float bass, float mids, float highs, float phaseOffset) {
    float t = iTime * PLASMA_SPEED;
    
    // Warp the UV field with bass — makes plasma breathe/surge
    vec2 warpUV = uv * PLASMA_SCALE;
    warpUV += bass * PLASMA_BASS_WARP * vec2(
        sin(uv.y * 4.0 + t * 0.7),
        cos(uv.x * 3.5 - t * 0.6)
    );
    
    // Multi-layer plasma field
    float p1 = sin(warpUV.x * 1.2 + t) + sin(warpUV.y * 1.5 - t * 0.8);
    float p2 = sin(length(warpUV - vec2(sin(t*0.3), cos(t*0.4))) * 2.5);
    float p3 = sin(warpUV.x * sin(t * 0.2) * 1.5 + warpUV.y * cos(t * 0.3) * 1.5);
    float p4 = sin(length(warpUV) * 3.0 - t * 1.5 + bass * 6.0);
    
    // Combine plasma layers — mids and highs shape the blend
    float plasma = (p1 + p2 + p3 + p4) / 4.0;
    plasma += mids * sin(count * 2.0 + t); // tile-count modulation from mids
    
    // Rainbow hue: cycles through full spectrum, bass shifts it
    float hue = fract(plasma * 0.5 * PLASMA_HUE_SPREAD 
                     + bass * 1.5 
                     + count * 0.12 
                     + phaseOffset
                     + highs * 0.3);
    
    // Saturation: stays vivid, slight mids modulation
    float sat = PLASMA_SATURATION + mids * 0.15;
    sat = clamp(sat, 0.0, 1.0);
    
    // Value/brightness: pulses on bass, baseline from plasma field
    float val = 0.5 + 0.3 * plasma;
    val += bass * 0.4; // brighten on hits
    val = clamp(val, 0.15, 1.0);
    
    // Extra glow punch on bass hits
    float glow = smoothstep(0.4, 0.8, bass) * PLASMA_GLOW_ON_HIT;
    
    vec3 rgb = hsv2rgb(vec3(hue, sat, val));
    rgb += rgb * glow; // additive glow on hits
    
    return rgb;
}

// ============================================================
// Spherical geometry / Wythoff
// ============================================================
void init_spherical() {
    vec3 c = cos(PI / pqr_wythoff);
    float sp = sin(PI / pqr_wythoff.x);
    vec3 m1 = vec3(1, 0, 0);
    vec3 m2 = vec3(-c.x, sp, 0);
    float x3 = -c.z;
    float y3 = -(c.y + c.x*c.z)/sp;
    float z3 = sqrt(1.0 - x3*x3 - y3*y3);
    vec3 m3 = vec3(x3, y3, z3);
    matS = mat3(m1, m2, m3);
    triS[0] = normalize(cross(m2, m3));
    triS[1] = normalize(cross(m3, m1));
    triS[2] = normalize(cross(m1, m2));
    v0S = normalize(bary * inverse(matS));
}

vec3 fold_spherical(vec3 p) {
    for (int i = 0; i < 5; i++)
    for (int j = 0; j < 3; j++) {
        p -= 2. * min(dot(p, matS[j]), 0.) * matS[j];
    }
    return p;
}

// ============================================================
// Rotation helpers
// ============================================================
mat2 rot2(in float a) {
    float c = cos(a), s = sin(a); return mat2(c, -s, s, c);
}

mat3 rot_x(in float t) {
    float cx = cos(t), sx = sin(t);
    return mat3(1., 0,  0,
                0, cx, sx,
                0, -sx, cx);
}

mat3 rot_y(in float t) {
    float cy = cos(t), sy = sin(t);
    return mat3(cy, 0, -sy,
                0, 1., 0,
                sy, 0, cy);
}

mat3 rot_z(in float t) {
    float cz = cos(t), sz = sin(t);
    return mat3(cz, -sz, 0.,
                sz, cz, 0.,
                0., 0., 1.);
}

// ============================================================
// SDF primitives
// ============================================================
float sBox(in vec2 p, in vec2 b) {
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.) + length(max(d, 0.));
}

float lBox(vec2 p, vec2 a, vec2 b, float ew) {
    float ang = atan(b.y - a.y, b.x - a.x);
    p = rot2(ang)*(p - mix(a, b, .5));
    vec2 l = vec2(length(b - a), ew);
    return sBox(p, (l + ew)/2.);
}

float sdBoxFrame(vec3 p, vec3 b, vec3 e) {
    p = abs(p) - b;
    vec3 q = abs(p + e) - e;
    return min(min(
        length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
        length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
        length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float sdPolyhedraEdges(vec3 p) {
    float d = 1e5;
    for (int i = 0; i < 3; i++) {
        d = min(d, L2(p - min(0., dot(p, matS[i])) * matS[i]));
    }
    return sqrt(d) - PolyhedraEdgeSize;
}

float sdPolyhedraFaces(vec3 p) {
   return max(dot(p, triS[0]), max(dot(p, triS[1]), dot(p, triS[2]))) - PolyhedraFaceOffset;
}

// ============================================================
// Complex math
// ============================================================
vec2 cMul(vec2 a, vec2 b) {
    return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}

vec2 cDiv( vec2 a, vec2 b ) {
    float d = dot(b, b);
    return vec2(dot(a, b), a.y*b.x - a.x*b.y ) / d;
}

vec2 cInv(vec2 a) {
    return vec2(a.x, -a.y) / dot(a, a);
}

// ============================================================
// Jacobi elliptic functions (from @mla)
// ============================================================
void sncndn(float u, float k2,
            out float sn, out float cn, out float dn) {
    float emc = 1.0 - k2;
    float a = 1.0, b, c;
    const int N = 4;
    float em[N], en[N];
    dn = 1.0;
    for (int i = 0; i < N; i++) {
        em[i] = a;
        emc = sqrt(emc);
        en[i] = emc;
        c = 0.5*(a + emc);
        emc *= a;
        a = c;
    }
    u = c*u;
    sn = sin(u);
    cn = cos(u);
    if (sn != 0.0) {
        a = cn / sn;
        c *= a;
        for(int i = N - 1; i >= 0; i--) {
            b = em[i];
            a *= c;
            c *= dn;
            dn = (en[i] + a) / (b + a);
            a = c/b;
        }
        a = 1.0 / sqrt(c*c + 1.0);
        if (sn < 0.0)
            sn = -a;
        else
            sn = a;
        cn = c * sn;
    }
}

vec2 cn(vec2 z, float k2) {
    float snu, cnu, dnu, snv, cnv, dnv;
    sncndn(z.x, k2, snu, cnu, dnu);
    sncndn(z.y, 1.0-k2, snv, cnv, dnv);
    return vec2(cnu * cnv, -snu*dnu*snv*dnv) / (1. - dnu*dnu*snv*snv);
}

vec2 square_to_disc(vec2 z) {
    z = cDiv(z, vec2(1));
    z -= vec2(1, 0);
    z *= 1.854;
    z = cn(z, 0.5);
    z = cMul(z, vec2(0.70711));
    return z;
}

// ============================================================
// FLOOR TILES — bass-reactive {2,3,7} hyperbolic tiling
// ============================================================
vec3 get_floor_color(vec2 z, float bass, float mids, float highs) {
    const float P = 2.;
    const float Q = 3.;
    const float R = 7.;
    const float cp = cos(PI / P), sp = sin(PI / P);
    const vec2 mB = vec2(-cp, sp);
    const float k1 = cos(PI / Q);
    const float k2 = (cos(PI / R) + cp * k1) / sp;
    const float rad = 1. / sqrt(k1 * k1 + k2 * k2 - 1.);
    const vec2 cen = vec2(k1 * rad, k2 * rad);
    const vec2 v0 = vec2(0, cen.y - sqrt(rad * rad - cen.x * cen.x));
    const vec2 n_ = vec2(-mB.y, mB.x);
    const float b_ = dot(cen, n_);
    const float c_ = dot(cen, cen) - rad * rad;
    const float k_ = b_ + sqrt(b_ * b_ - c_);
    const vec2 m0 = k_ * n_;

    // --- BASS-REACTIVE: scale the UV by bass amount ---
    float scaleWarp = 1.0 + bass * BASS_SCALE_AMOUNT;
    vec2 p = square_to_disc(z * scaleWarp);

    vec2 invCtr = vec2(1);
    float t = 1. / dot(p - invCtr, p - invCtr);
    p = mix(invCtr, p, t);
    p.x = -p.x;
    // --- BASS-REACTIVE: rotation speed modulated by mids ---
    p = rot2(iTime/12. + mids * 0.3) * p;

    if (length(p) > 1.)
        p /= dot(p, p);

    float count = 0.;
    for (int i = 0; i < MAX_TILING_REFLECTIONS; i++) {
        if (p.x < 0.) {
            p.x = -p.x;
            count += 1.;
        }
        float k = dot(p, mB);
        if (k < 0.) {
            p -= 2. * k * mB;
            count += 1.;
        }
        float d = length(p - cen) - rad;
        if (d < 0.) {
            p -= cen;
            p *= rad * rad / dot(p, p);
            p += cen;
            count += 1.;
        }
    }

    float ln = 1e5, ln2 = 1e5, pnt = 1e5;
    ln = min(ln, lBox(p, vec2(0), v0, .007));
    ln = min(ln, lBox(p, vec2(0), m0, .007));
    ln = min(ln, length(p - cen) - rad - 0.007);
    ln2 = min(ln2, lBox(p, vec2(0), m0, .007));
    pnt = min(pnt, length(p - v0));
    pnt = min(pnt, length(p - m0));

    float sf = 2. / iResolution.y;

    // --- BASS-REACTIVE: replace time-based rnd with bass-driven pulse ---
    float rnd = smoothstep(0.3, 0.7, bass);

    // --- BASS-REACTIVE: hue shift driven by bass ---
    float hueShift = bass * BASS_COLOR_INTENSITY;
    vec3 oCol = .55 + .45 * cos(count * PI / 4. + hueShift + vec3(0, 1, 2));
    oCol = mix(oCol * 0.1, clamp(oCol * BASS_BRIGHTNESS_BOOST, 0., 1.), rnd);

    // --- RAINBOW PLASMA OVERLAY ---
    vec3 plasmaCol = plasma_rainbow(p, count, bass, mids, highs, 0.0);
    oCol = mix(oCol, plasmaCol, PLASMA_INTENSITY);
    // Extra saturation boost on bass hits
    oCol = mix(oCol, oCol * 1.8, smoothstep(0.5, 0.9, bass) * 0.5);

    float pat = smoothstep(0., .25, abs(fract(ln2 * 50. - .2) - .5) * 2. - .2);
    float sh = clamp(.65 + ln / v0.y * 4., 0., 1.);
    vec3 col = min(oCol * (pat * .2 + .9) * sh, 1.);

    col = mix(col, vec3(0), 1. - smoothstep(0., sf, ln));
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, -(ln - BlackRegionSize)));

    pnt -= .032;
    pnt = min(pnt, length(p) - .032);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, pnt));

    // --- BASS-REACTIVE: blink nodes pulse with rainbow plasma ---
    float blinkPulse = smoothstep(0.35, 0.75, bass);
    vec3 blink = hsv2rgb(vec3(fract(iTime * 0.15 + count * 0.1 + bass), 0.9, 1.0));
    blink = mix(blink * 0.5, blink * BASS_BLINK_INTENSITY, blinkPulse);
    blink += plasma_rainbow(p * 2.0, count, bass, mids, highs, 0.5) * blinkPulse;
    col = mix(col, blink, 1. - smoothstep(0., sf, pnt + .02));

    return col;
}

// ============================================================
// CEILING TILES — bass-reactive {3,3,3} Euclidean tiling
// ============================================================
vec3 get_ceil_color(vec2 p, float bass, float mids, float highs) {
    const float P = 3.;
    const float Q = 3.;
    const float R = 3.;
    const float cp = cos(PI / P), sp = sin(PI / P);
    const float cq = cos(PI / Q), cr = cos(PI / R);
    const vec2 mB = vec2(-cp, sp);
    const vec3 mC = vec3(-cr, -(cq + cr * cp) / sp, 1.);
    const vec2 v0 = vec2(0, -1./mC.y);
    const float k_ = mB.x / mB.y;
    const float x_ = 1. / (k_ * mC.y - mC.x);
    const float y_ = -k_ * x_;
    const vec2 m0 = vec2(x_, y_);

    // --- BASS-REACTIVE: warp ceiling tile scale with bass ---
    float scaleWarp = 1.0 - bass * BASS_SCALE_AMOUNT * 0.6;
    p *= scaleWarp;

    p = rot2(iTime/12. - mids * 0.2) * p;

    float count = 0.;
    for (int i = 0; i < MAX_TILING_REFLECTIONS; i++) {
        if (p.x < 0.) {
            p.x = -p.x;
            count += 1.;
        }
        float k = dot(p, mB);
        if (k < 0.) {
            p -= 2. * k * mB;
            count += 1.;
        }
        k = dot(vec3(p, 1.), mC);
        if (k < 0.) {
            p -= 2. * k * mC.xy;
            count += 1.;
        }
    }

    float ln = 1e5, ln2 = 1e5, pnt = 1e5;
    ln = min(ln, lBox(p, v0, m0, .05));
    ln2 = min(ln2, lBox(p, vec2(0), m0, .007));
    pnt = min(pnt, length(p - v0));
    pnt = min(pnt, length(p - m0));

    float sf = 2. / iResolution.y;

    // --- BASS-REACTIVE: pulse driven by bass ---
    float rnd = smoothstep(0.3, 0.7, bass);

    // --- BASS-REACTIVE: hue shift driven by bass ---
    float hueShift = bass * BASS_COLOR_INTENSITY * 1.2;
    vec3 oCol = .55 + .45 * cos(count * PI / 8. + hueShift + vec3(0, 1, 2)).yzx;
    oCol = mix(oCol * 0.1, clamp(oCol * (1.5 + bass * 1.5), 0., 1.), rnd);

    // --- RAINBOW PLASMA OVERLAY (phase-shifted from floor for contrast) ---
    vec3 plasmaCol = plasma_rainbow(p * 0.8, count, bass, mids, highs, 3.14);
    oCol = mix(oCol, plasmaCol, PLASMA_INTENSITY);
    oCol = mix(oCol, oCol * 1.8, smoothstep(0.5, 0.9, bass) * 0.5);

    float pat = smoothstep(0., .25, abs(fract(ln2 * 15. - .2) - .5) * 2. - .2);
    float sh = clamp(.65 + ln / v0.y * 4., 0., 1.);
    vec3 col = min(oCol * (pat * .2 + .9) * sh, 1.);

    col = mix(col, vec3(0), 1. - smoothstep(0., sf, ln));
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, -(ln - BlackRegionSize * 16.)));

    pnt -= .15;
    pnt = min(pnt, length(p) - .15);
    col = mix(col, vec3(0), 1. - smoothstep(0., sf, pnt));

    // --- BASS-REACTIVE: ceiling blink nodes — rainbow plasma ---
    float blinkPulse = smoothstep(0.3, 0.65, bass);
    vec3 blink = hsv2rgb(vec3(fract(iTime * 0.2 + count * 0.15 + bass * 0.8), 0.9, 1.0));
    blink = mix(blink * 0.5, blink * BASS_BLINK_INTENSITY, blinkPulse);
    blink += plasma_rainbow(p * 1.5, count, bass, mids, highs, 1.57) * blinkPulse;
    col = mix(col, blink, 1. - smoothstep(0., sf, pnt + .02));

    return col;
}

// ============================================================
// Room geometry SDFs
// ============================================================
float sdMirror(vec3 p) {
    vec2 d = RoomSize.xz - abs(p.xz);
    return min(d.x, d.y);
}

float sdFloor(vec3 p) {
    return RoomSize.y - abs(p.y);
}

float sdRoomFrame(vec3 p) {
    return sdBoxFrame(p, RoomSize, vec3(RoomFrameSize));
}

float sdMirrorFrame(vec3 p) {
    float d1 = sdBoxFrame(p, RoomSize, WindowFrameSize.xyy);
    float d2 = sdBoxFrame(p, RoomSize, WindowFrameSize.yxy);
    float d3 = sdBoxFrame(p, RoomSize, WindowFrameSize.yyx);
    return min(d1, min(d2, d3));
}

vec2 sdPolyhedra(vec3 p) {
    p *= RotObj;
    p = fold_spherical(p);
    p -= v0S;
    float d1 = sdPolyhedraFaces(p);
    float d2 = sdPolyhedraEdges(p);
    float d = min(d1, d2);
    float id = d1 < d2 ? 1. : 2.;
    return vec2(d, id);
}

float sdScene(vec3 p) {
    float d1 = sdMirror(p);
    float d2 = sdFloor(p);
    float d3 = sdRoomFrame(p);
    float d4 = sdMirrorFrame(p);
    float d5 = sdPolyhedra(p).x;
    return min(d1, min(d2, min(d3, min(d4, d5))));
}

// ============================================================
// Raymarching
// ============================================================
vec3 trace(vec3 pos, vec3 rd) {
    float h = 1.0;
    for (int i = 0; i < MAX_TRACE_STEPS; i++) {
        if (h < PRECISION)
            break;
        h = sdScene(pos);
        pos += rd * min(h, MAX_MARCH_STEP);
    }
    return pos;
}

float soft_shadow(vec3 pos, vec3 lp) {
    const float softness = 16.;
    const float shadowStartDistance = .1;
    const int shadowLoopCount = 16;
    vec3 ld = lp - pos;
    float ldist = max(length(lp), 0.001);
    ld /= ldist;
    float t = shadowStartDistance;
    float h = 1.;
    float shade = 1.0;
    for (int i = 0; i < shadowLoopCount; i++) {
        if (h < .001 || t > ldist)
            break;
        h = sdScene(pos + ld * t);
        shade = min(shade, smoothstep(0.0, 1.0, softness*h/t));
        t += h;
    }
    return clamp(shade + 0.25, 0., 1.);
}

vec3 get_normal(vec3 p) {
    const vec2 d = vec2(-1, 1) * .001;
    return normalize(
            sdScene(p + d.xxx)*d.xxx +
            sdScene(p + d.yyx)*d.yyx +
            sdScene(p + d.yxy)*d.yxy +
            sdScene(p + d.xyy)*d.xyy);
}

// ============================================================
// Lighting
// ============================================================
struct Light {
    vec3 pos;
    vec3 col;
};

Light lights[3];

void init_lights(float bass) {
    // --- BASS-REACTIVE: lights pulse brighter on hits ---
    float boost = 1.0 + bass * 1.5;
    lights[0] = Light(vec3(2.5, 2.2, 2.5), vec3(1) * 5. * boost);
    lights[1] = Light(vec3(-1, -.5, -1), vec3(1) * boost);
    lights[2] = Light(vec3(-2.5,-1.9,-2.5), vec3(0, .3, 1) * boost);
}

void ray_bounce(in vec3 p,
                in vec3 rd,
                out vec3 diffuse,
                out vec3 ref_dir,
                out vec3 bounceTint,
                in vec3 normal,
                float bass,
                float mids,
                float highs) {

    vec3 bCol = vec3(0);
    for (int i = 0; i < 3; i++) {
        vec3 ld = lights[i].pos - p;
        float ldist = max(length(ld), 0.001);
        ld /= ldist;
        float diff = max(0., dot(normal, ld));
        float at = 1.5 / (1. + ldist * 0.3 + ldist * ldist * 0.1);
        float sh = soft_shadow(p, lights[i].pos);
        bCol += lights[i].col * sh * (.2 + diff) * at;
    }

    vec3 ao = vec3(.03,.05,.07);
    ao *= exp2(min(0., sdScene(p + normal * 0.3) / 0.3 - 1.));
    ao *= exp2(min(0., sdScene(p + normal * .15) / .15 - 1.));
    ao *= exp2(min(0., sdScene(p + normal * .07) / .07 - 1.));
    bCol += ao;

    vec3 albedo = vec3(.3,.5,.6) * .4;
    vec4 specLevel = vec4(0.9, 0.9, 0.9, 1);
    // Use iChannel0 texture for specular variation (audio texture doubles as noise)
    specLevel.rgb = vec3(mix(.8, .95, texture(iChannel0, vec2(p.y, p.x+p.z)/2.).g));

    float d1 = sdMirror(p);
    float d2 = sdFloor(p);
    float d3 = sdRoomFrame(p);
    float d4 = sdMirrorFrame(p);
    vec2 sdPoly = sdPolyhedra(p);
    float d5 = sdPoly.x, id = sdPoly.y;
    float d = min(d1, min(min(d2, d3), min(d4, d5)));

    if (d == d3) {
        albedo = vec3(.25);
        specLevel = vec4(0.08);
    }
    else if (d == d4) {
        albedo = vec3(0.01);
        specLevel = vec4(0.2, 0.2, 0.2, 1.);
    }
    else if (d == d5) {
        if (id == 2.) {
            albedo = vec3(0.15, 0.3, 0.8);
            specLevel = vec4(vec3(0.05), 1.);
        }
        else {
            specLevel = vec4(0.7);
        }
    }
    else if (d == d2) {
        vec2 uv = p.xz;
        // --- BASS-REACTIVE: pass audio data into tile color functions ---
        albedo = p.y < 0.
            ? get_floor_color(uv / (RoomSize.x - RoomFrameSize), bass, mids, highs)
            : get_ceil_color(uv * 2., bass, mids, highs);
        float ior = 1.33;
        float schlick = pow((ior - 1.) / (ior + 1.), 2.);
        specLevel = vec4(vec3(schlick), 1);
        specLevel *= mix(.2, .7, p.x);
        normal = normalize(normal + (texture(iChannel0, vec2(p.xz)/2.).rgb - .5) * .005);
    }

    float fresnel = pow(dot(normal, rd) + 1., 5.);
    vec3 spec = mix(specLevel.xyz, specLevel.www, fresnel);

    bounceTint = spec;
    diffuse = albedo * (vec3(1) - spec) * bCol;
    ref_dir = reflect(rd, normal);
}

vec3 get_ray_color(vec3 ro, vec3 rd, float bass, float mids, float highs) {
    vec3 pos = ro;
    vec3 tint = vec3(1);
    vec3 col = vec3(0);
    for (int i = 0; i < MAX_RAY_BOUNCES; i++) {
        pos = trace(pos, rd);
        vec3 normal = get_normal(pos);
        vec3 bounceTint, diffuse;
        ray_bounce(pos, rd, diffuse, rd, bounceTint, normal, bass, mids, highs);
        pos += normal * PRECISION * 2.;
        col += diffuse * tint;
        tint *= bounceTint;
        if (length(tint) < .01)
            break;
    }
    return col;
}

// ============================================================
// Camera
// ============================================================
mat3 camera_matrix(vec3 eye, vec3 lookat, vec3 up) {
    vec3 forward = normalize(lookat - eye);
    vec3 right = normalize(cross(forward, up));
    up = normalize(cross(right, forward));
    return mat3(right, up, -forward);
}

// ============================================================
// Main
// ============================================================
void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    // Sample audio
    float bass = getBass();
    float mids = getMids();
    float highs = getHighs();

    init_lights(bass);
    init_spherical();

    vec2 uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
    vec2 movement = vec2(iTime * 0.2, sin(iTime * 0.2) * 0.5);
    vec3 eye = 2.5 * vec3(
        cos(movement.x) * cos(movement.y),
        0.5*sin(movement.y),
        sin(movement.x) * cos(movement.y));
    eye += vec3(1, 0.3, 1) * cos(vec3(0.75, 0.3, 0.2) * iTime);

    // No mouse interaction in OneOffRender
    vec3 lookat = vec3(0);
    vec3 up = vec3(0, 1, 0);
    mat3 M = camera_matrix(eye, lookat, up);

    vec3 ray = M * normalize(vec3(uv, -2.));
    vec3 col = get_ray_color(eye, ray, bass, mids, highs);
    fragColor = vec4(clamp(sqrt(col), 0., 1.), 1.);
}
