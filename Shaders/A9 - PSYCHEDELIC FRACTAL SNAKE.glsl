#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// ═══════════════════════════════════════════════════════════════════════════
// PSYCHEDELIC FRACTAL SNAKE - Audio Reactive Shadertoy  v2
// ═══════════════════════════════════════════════════════════════════════════
// iChannel0 = Audio (soundcloud or microphone)

// ═══════════════════════════════════════════════════════════════════════════
// TWEAKER VARIABLES
// ═══════════════════════════════════════════════════════════════════════════

// SNAKE MOVEMENT
#define SNAKE_SPEED          1.2       // How fast snake moves
#define SPIRAL_TIGHTNESS     2.5       // How tight the spiral is
#define SPIRAL_RADIUS        4.8       // Spiral radius  (was 3.5)
#define VERTICAL_RANGE       3.5       // Up-down movement  (was 2.5)
#define SEGMENT_COUNT        18        // Number of body segments

// SNAKE SEGMENTS
#define SEGMENT_SIZE         0.4       // Base segment size
#define SEGMENT_SPACING      0.05      // Distance between segments
#define FRACTAL_ITERATIONS   3         // Fractal detail level
#define ROTATION_SPEED       2.0       // Segment rotation speed
#define MORPH_SPEED          1.5       // Shape morphing speed

// SNAKE HEAD
#define HEAD_SIZE            0.6       // Head size
#define HEAD_EXTENSION       1.2       // How far ahead of body
#define EYE_GLOW             2.5       // Eye brightness
#define MANDIBLE_COUNT       6         // Number of jaw spikes

// PSYCHEDELIC EFFECTS
#define COLOR_SHIFT_SPEED    0.8       // How fast colors change
#define KALEIDOSCOPE_SCALE   4.0       // Pattern detail
#define ENERGY_FIELD         0.3       // Aura size
#define PULSE_INTENSITY      0.6       // Audio pulse amount  (was 0.4)

// AUDIO REACTIVITY
#define AUDIO_BASS_FREQ      0.05      // Bass sample point
#define AUDIO_MID_FREQ       0.25      // Mid sample point
#define AUDIO_HIGH_FREQ      0.55      // High sample point
#define AUDIO_MORPH          2.2       // Audio effect on shape  (was 1.5)
#define AUDIO_COLOR          2.8       // Audio effect on color  (was 2.0)

// PLATFORM OBJECTS
#define BOING_SIZE           0.5       
#define BOING_SPIN           2.2       // (was 1.2)
#define BOING_BOUNCE         0.75      // (was 0.4)
#define BOX_SIZE             0.35      
#define BOX_TWIST_RATE       3.0       // (was 1.5)

// WARP STARFIELD
#define STAR_COUNT           70        // Number of warp stars
#define STAR_SPEED_BASE      1.2       // Base warp speed
#define STAR_AUDIO_KICK      3.0       // Bass kick multiplier on speed

// ═══════════════════════════════════════════════════════════════════════════
#define PI 3.14159265359
#define TAU 6.28318530718
#define MAX_STEPS 150
#define MAX_DIST 50.0
#define SURF_DIST 0.0003

// Audio globals
float audioBass, audioMid, audioHigh, audioTotal;

void computeAudio() {
    audioBass = texture(iChannel0, vec2(AUDIO_BASS_FREQ, 0.0)).x;
    audioMid  = texture(iChannel0, vec2(AUDIO_MID_FREQ,  0.0)).x;
    audioHigh = texture(iChannel0, vec2(AUDIO_HIGH_FREQ, 0.0)).x;
    audioTotal = (audioBass + audioMid + audioHigh) / 3.0;
}

// ═══════════════════════════════════════════════════════════════════════════
// UTILITIES
// ═══════════════════════════════════════════════════════════════════════════
mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}

float hash(float n) { return fract(sin(n) * 43758.5453); }
float hash(vec3 p)  { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }

vec3 hash3(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return fract(sin(p) * 43758.5453);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f *= f * (3.0 - 2.0 * f);
    float n = i.x + i.y * 157.0 + i.z * 311.0;
    return mix(mix(mix(hash(n),       hash(n + 1.0),   f.x),
                   mix(hash(n+157.0), hash(n + 158.0), f.x), f.y),
               mix(mix(hash(n+311.0), hash(n + 312.0), f.x),
                   mix(hash(n+468.0), hash(n + 469.0), f.x), f.y), f.z);
}

vec3 spectrum(float x) {
    return 0.5 + 0.5 * cos(TAU * (vec3(0.0, 0.33, 0.67) + x));
}

vec3 psychedelicPalette(float t, float offset) {
    return 0.5 + 0.5 * cos(TAU * (vec3(0.8, 0.5, 0.3) * t + vec3(0.0, 0.33, 0.67) + offset));
}

// ═══════════════════════════════════════════════════════════════════════════
// WARP SPEED STARFIELD
// ═══════════════════════════════════════════════════════════════════════════
vec3 warpStarfield(vec2 uv, float t) {
    vec3 col = vec3(0.0);
    float speed = STAR_SPEED_BASE + audioBass * STAR_AUDIO_KICK;

    for (int i = 0; i < STAR_COUNT; i++) {
        float fi    = float(i);
        float angle = hash(fi * 1.618) * TAU;
        float lane  = hash(fi * 2.391 + 0.5);         // 0..1 radial lane seed
        float phase = fract(lane + t * speed * (0.4 + hash(fi * 3.7) * 0.9));

        float r     = phase * 1.8;                    // radius 0 → 1.8
        vec2  dir   = vec2(cos(angle), sin(angle));
        vec2  head  = dir * r;

        // perpendicular distance to the streak line
        vec2  toH   = uv - head;
        float along = dot(toH, -dir);
        float perp  = length(toH + along * dir);

        // trail length grows with phase (accelerating feel)
        float trailLen = 0.04 + phase * 0.22 * (1.0 + audioBass * 0.4);

        float streak = exp(-perp * 180.0)
                     * exp(-max(along, 0.0) * 18.0 / max(trailLen, 0.001))
                     * step(0.0, along)
                     * smoothstep(0.0, 0.08, phase);   // fade in from center

        // head dot
        float headDot = exp(-length(toH) * 80.0);

        // tint — mostly white-blue, occasional warm star
        vec3 tint = mix(vec3(0.7, 0.85, 1.0),
                        vec3(1.0, 0.9, 0.6),
                        step(0.85, hash(fi * 5.1)));

        col += tint * (streak * 0.7 + headDot * 1.2);
    }

    return col;
}

// ═══════════════════════════════════════════════════════════════════════════
// SDF PRIMITIVES
// ═══════════════════════════════════════════════════════════════════════════
float sdSphere(vec3 p, float r) { return length(p) - r; }

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    float m = p.x + p.y + p.z - s;
    vec3 q;
    if (3.0*p.x < m) q = p.xyz;
    else if (3.0*p.y < m) q = p.yzx;
    else if (3.0*p.z < m) q = p.zxy;
    else return m * 0.57735027;
    float k = clamp(0.5*(q.z-q.y+s), 0.0, s);
    return length(vec3(q.x, q.y-s+k, q.z-k));
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz)-t.x, p.y);
    return length(q) - t.y;
}

float sdHexPrism(vec3 p, vec2 h) {
    vec3 q = abs(p);
    return max(q.z-h.y, max((q.x*0.866025+q.y*0.5), q.y)-h.x);
}

// Fractal / Kaleidoscopic fold
vec3 kaleidoFold(vec3 p, float scale) {
    for (int i = 0; i < 4; i++) {
        p = abs(p);
        p.xy = p.x < p.y ? p.yx : p.xy;
        p.xz = p.x < p.z ? p.zx : p.xz;
        p.yz = p.y < p.z ? p.zy : p.yz;
        p = p * scale - vec3(scale-1.0);
    }
    return p;
}

// ═══════════════════════════════════════════════════════════════════════════
// PSYCHEDELIC SNAKE PATH  — untouched logic, wider range via defines above
// ═══════════════════════════════════════════════════════════════════════════
vec3 getSnakePath(float t) {
    float phase = t * SNAKE_SPEED;

    vec3 pos;
    pos.x = sin(phase * 0.7) * SPIRAL_RADIUS + cos(phase * 1.3) * 1.5;
    pos.y = sin(phase * 0.9) * VERTICAL_RANGE + cos(phase * 1.7) * 0.8;
    pos.z = cos(phase * 0.7) * SPIRAL_RADIUS  + sin(phase * 1.1) * 2.0;

    // secondary motion — slightly wider than original
    pos += vec3(
        sin(phase * 2.3) * 1.1,
        cos(phase * 3.1) * 0.7,
        sin(phase * 1.9) * 0.9
    );

    return pos;
}

vec3 getSegmentPosition(int idx, float t) {
    float delay = float(idx) * SEGMENT_SPACING;
    return getSnakePath(t - delay);
}

// ═══════════════════════════════════════════════════════════════════════════
// FRACTAL SNAKE SEGMENT
// ═══════════════════════════════════════════════════════════════════════════
float sdFractalSegment(vec3 p, vec3 center, float t, int idx) {
    vec3 local = p - center;

    float rot1 = t * ROTATION_SPEED + float(idx) * 0.8;
    float rot2 = t * ROTATION_SPEED * 0.7 + float(idx) * 1.2;
    local.xy *= rot(rot1 + audioBass * 2.0);
    local.yz *= rot(rot2 + audioHigh * 2.0);

    float morph = sin(t * MORPH_SPEED + float(idx) * 0.5) * 0.5 + 0.5;
    morph += audioMid * AUDIO_MORPH * 0.5;

    float size = SEGMENT_SIZE * (1.0 + audioTotal * PULSE_INTENSITY);
    float oct  = sdOctahedron(local, size);
    float sph  = sdSphere(local, size * 0.8);
    float base = mix(oct, sph, morph);

    vec3  kp     = kaleidoFold(local * 2.0, 1.8 + audioHigh * 0.3);
    float detail = sdSphere(kp, 0.15) * 0.5;

    return smax(base, -detail, 0.1);
}

// ═══════════════════════════════════════════════════════════════════════════
// PSYCHEDELIC SNAKE HEAD
// ═══════════════════════════════════════════════════════════════════════════
float sdPsychedelicHead(vec3 p, vec3 headPos, vec3 nextPos, float t) {
    vec3 dir   = normalize(headPos - nextPos);
    vec3 right = normalize(cross(dir, vec3(0.0, 1.0, 0.001)));
    vec3 up    = cross(right, dir);

    vec3 local = p - headPos;
    local = vec3(dot(local, right), dot(local, up), dot(local, dir));

    local.xy *= rot(t * 0.5 + audioBass);
    float head = sdOctahedron(local, HEAD_SIZE * (1.0 + audioTotal * 0.3));

    for (int i = 0; i < MANDIBLE_COUNT; i++) {
        float angle = float(i) * TAU / float(MANDIBLE_COUNT);
        float pulse = sin(t * 3.0 + float(i) * 0.5 + audioBass * 5.0) * 0.2;
        vec3  mandiblePos = vec3(
            cos(angle) * (0.4 + pulse),
            sin(angle) * (0.4 + pulse),
            0.3 + pulse
        );
        vec3 mp = local - mandiblePos;
        mp.xy *= rot(angle);
        float mandible = sdBox(mp, vec3(0.08, 0.08, 0.3));
        head = smin(head, mandible, 0.15);
    }

    for (int i = 0; i < 3; i++) {
        float angle  = float(i) * TAU / 3.0;
        vec3  eyePos = vec3(cos(angle)*0.35, sin(angle)*0.35, 0.15);
        float eye    = sdSphere(local - eyePos, 0.12);
        head = smin(head, eye, 0.08);
    }

    return head;
}

float nearEyes(vec3 p, vec3 headPos, vec3 nextPos) {
    vec3 dir   = normalize(headPos - nextPos);
    vec3 right = normalize(cross(dir, vec3(0.0, 1.0, 0.001)));
    vec3 up    = cross(right, dir);

    vec3  local   = p - headPos;
    local = vec3(dot(local, right), dot(local, up), dot(local, dir));

    float minDist = 999.0;
    for (int i = 0; i < 3; i++) {
        float angle  = float(i) * TAU / 3.0;
        vec3  eyePos = vec3(cos(angle)*0.35, sin(angle)*0.35, 0.15);
        minDist = min(minDist, length(local - eyePos));
    }
    return minDist;
}

// ═══════════════════════════════════════════════════════════════════════════
// COMPLETE PSYCHEDELIC SNAKE
// ═══════════════════════════════════════════════════════════════════════════
float sdPsychedelicSnake(vec3 p, float t, out float segID, out float energyField) {
    segID       = 0.0;
    energyField = 0.0;

    vec3 seg0    = getSegmentPosition(0, t);
    vec3 seg1    = getSegmentPosition(1, t);
    vec3 headDir = normalize(seg0 - seg1);
    vec3 headPos = seg0 + headDir * HEAD_EXTENSION;

    float d = sdPsychedelicHead(p, headPos, seg0, t);
    energyField += exp(-length(p - headPos) * 3.0) * 0.5;

    for (int i = 0; i < SEGMENT_COUNT; i++) {
        vec3  center = getSegmentPosition(i, t);
        float seg    = sdFractalSegment(p, center, t, i);

        if (seg < d) { segID = float(i); d = seg; }
        energyField += exp(-length(p - center) * 4.0) * 0.3;
    }

    return d;
}

// ═══════════════════════════════════════════════════════════════════════════
// PLATFORM OBJECTS  — more movement throughout
// ═══════════════════════════════════════════════════════════════════════════
float sdBoingBall(vec3 p, vec3 pos, float t) {
    vec3 local = p - pos;
    // bigger bounce arc, extra wobble
    local.y  -= abs(sin(t * 3.5 + audioBass * 6.0)) * BOING_BOUNCE;
    local.xz *= rot(t * BOING_SPIN);
    local.xy *= rot(0.3 + sin(t * 0.9) * 0.25);
    local.yz *= rot(t * BOING_SPIN * 0.8 + audioMid);
    return sdSphere(local, BOING_SIZE * (1.0 + audioBass * 0.3));
}

vec3 getBoingColor(vec3 p, vec3 pos, float t) {
    vec3 local = p - pos;
    local.y  -= abs(sin(t * 3.5 + audioBass * 6.0)) * BOING_BOUNCE;
    local.xz *= rot(t * BOING_SPIN);
    local.xy *= rot(0.3 + sin(t * 0.9) * 0.25);
    local.yz *= rot(t * BOING_SPIN * 0.8 + audioMid);
    vec3  n       = normalize(local);
    float u       = atan(n.x, n.z);
    float v       = asin(clamp(n.y, -1.0, 1.0));
    float checker = mod(floor(u*8.0/TAU+0.5)+floor(v*8.0/PI+0.5), 2.0);
    return mix(vec3(1.0, 0.15, 0.1), vec3(1.0, 1.0, 1.0), checker);
}

float sdTwistBox(vec3 p, vec3 pos, float t) {
    vec3  local = p - pos;
    // add a gentle orbit so it doesn't just sit still
    local.xz  -= vec2(sin(t * 0.7) * 0.2, cos(t * 0.5) * 0.15);
    float twist = local.y * 2.5 + t * BOX_TWIST_RATE + audioMid * 3.0;
    local.xz *= rot(twist);
    local.xy *= rot(t * 0.7 + audioHigh);
    local.yz *= rot(t * 0.5 + audioBass * 0.5);
    float size  = BOX_SIZE * (1.0 + audioMid * 0.4);
    return sdBox(local, vec3(size));
}

float sdPlatform(vec3 p, vec3 pos, float radius, float height) {
    vec3 local = p - pos;
    return sdHexPrism(local.xzy, vec2(radius, height));
}

float sdFloatingTorus(vec3 p, vec3 pos, float t) {
    vec3 local = p - pos;
    // more vertical travel + side-to-side drift
    local.y   -= sin(t * 2.0) * 0.4;
    local.x   -= cos(t * 1.3) * 0.25;
    local.xz  *= rot(t * 1.4 + audioHigh);
    local.xy  *= rot(sin(t * 0.9) * 0.5);
    float r    = 0.3 * (1.0 + audioHigh * 0.5);
    return sdTorus(local, vec2(r, 0.08));
}

float sdCrystalPyramid(vec3 p, vec3 pos, float t) {
    vec3 local = p - pos;
    local.xz  *= rot(t * 0.8 + audioBass * 0.5);
    local.xy  *= rot(sin(t * 0.6) * 0.35);
    local.y   -= sin(t * 2.5 + audioHigh * PI) * 0.18 * (1.0 + audioHigh);
    return sdOctahedron(local, 0.4 * (1.0 + audioHigh * 0.4));
}

// ═══════════════════════════════════════════════════════════════════════════
// SCENE MAP  — platforms float gently so objects drift in world space
// ═══════════════════════════════════════════════════════════════════════════
float map(vec3 p, out float matID, out float segID, out float energyField) {
    float t  = iTime;
    matID    = 0.0;
    segID    = 0.0;
    energyField = 0.0;

    // Snake
    float snake = sdPsychedelicSnake(p, t, segID, energyField);
    float d     = snake;

    // Check if near eyes
    vec3 seg0    = getSegmentPosition(0, t);
    vec3 seg1    = getSegmentPosition(1, t);
    vec3 headDir = normalize(seg0 - seg1);
    vec3 headPos = seg0 + headDir * HEAD_EXTENSION;
    float eyeDist = nearEyes(p, headPos, seg0);
    if (eyeDist < 0.18 && snake < 0.2) matID = 1.0;

    // Platform positions — gently floating
    vec3 plat1 = vec3(-4.0 + sin(t*0.31)*0.5,  -2.5 + sin(t*0.67)*0.25,  3.0 + cos(t*0.43)*0.4);
    vec3 plat2 = vec3( 4.5 + cos(t*0.27)*0.4,  -1.5 + sin(t*0.53)*0.3,  -2.0 + sin(t*0.38)*0.35);
    vec3 plat3 = vec3(-2.0 + sin(t*0.19)*0.45, -3.0 + cos(t*0.71)*0.2,  -5.0 + cos(t*0.29)*0.4);
    vec3 plat4 = vec3( 3.0 + cos(t*0.37)*0.35, -2.0 + sin(t*0.61)*0.3,   6.0 + sin(t*0.23)*0.5);

    // Platforms (static hex prisms at the same spot — just the objects above float)
    float platform1 = sdPlatform(p, plat1, 1.2, 0.3);
    float platform2 = sdPlatform(p, plat2, 1.0, 0.25);
    float platform3 = sdPlatform(p, plat3, 1.3, 0.35);
    float platform4 = sdPlatform(p, plat4, 0.9, 0.2);
    float platforms = min(min(platform1, platform2), min(platform3, platform4));
    if (platforms < d) { matID = 6.0; d = platforms; }

    // Objects
    float boing = sdBoingBall(p, plat1 + vec3(0.0, 0.8, 0.0), t);
    if (boing < d) { matID = 2.0; d = boing; }

    float box = sdTwistBox(p, plat2 + vec3(0.0, 0.6, 0.0), t);
    if (box < d) { matID = 3.0; d = box; }

    float torus = sdFloatingTorus(p, plat3 + vec3(0.0, 0.7, 0.0), t);
    if (torus < d) { matID = 4.0; d = torus; }

    float pyramid = sdCrystalPyramid(p, plat4 + vec3(0.0, 0.6, 0.0), t);
    if (pyramid < d) { matID = 5.0; d = pyramid; }

    // Snake takes priority when closer
    if (snake < d + 0.005) {
        d = snake;
        if (eyeDist < 0.18) matID = 1.0;
        else matID = 0.0;
    }

    return d;
}

// ═══════════════════════════════════════════════════════════════════════════
// NORMAL CALCULATION
// ═══════════════════════════════════════════════════════════════════════════
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    float m, s, ef;
    return normalize(vec3(
        map(p+e.xyy,m,s,ef) - map(p-e.xyy,m,s,ef),
        map(p+e.yxy,m,s,ef) - map(p-e.yxy,m,s,ef),
        map(p+e.yyx,m,s,ef) - map(p-e.yyx,m,s,ef)
    ));
}

// ═══════════════════════════════════════════════════════════════════════════
// PSYCHEDELIC SHADING
// ═══════════════════════════════════════════════════════════════════════════
vec3 shadeSnake(vec3 pos, vec3 nor, vec3 rd, float segID, float energyField) {
    float t = iTime;

    vec3  kp      = kaleidoFold(pos * KALEIDOSCOPE_SCALE, 2.0);
    float pattern = noise(kp + t * 0.5);

    float colorPhase = length(pos)*0.3 + t*COLOR_SHIFT_SPEED + segID*0.2;
    colorPhase += audioTotal * AUDIO_COLOR;
    vec3 baseCol = psychedelicPalette(colorPhase, pattern);

    float fresnel    = pow(1.0 - max(dot(nor,-rd), 0.0), 3.0);
    vec3  fresnelCol = spectrum(fresnel + t*0.5 + segID*0.1);

    float shimmer = sin(pattern*20.0 + t*3.0)*0.5 + 0.5;
    shimmer *= audioHigh;

    vec3 glow = psychedelicPalette(t*0.3, energyField) * energyField * 2.0;

    vec3 col  = baseCol * 0.6;
    col += fresnelCol * fresnel * 1.5;
    col += vec3(1.0, 0.8, 0.9) * shimmer * 0.8;
    col += glow;
    col *= 1.0 + audioTotal * 0.5;

    return col;
}

vec3 shadeEye(vec3 pos, vec3 nor, vec3 rd) {
    float t     = iTime;
    float pulse = sin(t*8.0 + audioBass*10.0)*0.5 + 0.5;
    vec3  col   = mix(vec3(1.0,0.2,0.8), vec3(0.2,1.0,0.9), pulse);
    col *= EYE_GLOW * (1.0 + audioBass*2.0);
    return col;
}

vec3 shadeBoing(vec3 pos, vec3 nor, vec3 rd, float t) {
    vec3 plat1   = vec3(-4.0 + sin(t*0.31)*0.5, -2.5 + sin(t*0.67)*0.25, 3.0 + cos(t*0.43)*0.4);
    vec3 baseCol = getBoingColor(pos, plat1 + vec3(0.0,0.8,0.0), t);
    vec3 light   = normalize(vec3(1.0,2.0,1.0));
    float diff   = max(dot(nor, light), 0.0);
    float spec   = pow(max(dot(reflect(-light,nor),-rd), 0.0), 32.0);
    vec3  col    = baseCol * (0.3 + diff*0.6);
    col += vec3(1.0) * spec * 0.5;
    col += baseCol * audioBass * 0.4;
    return col;
}

vec3 shadeBox(vec3 pos, vec3 nor, vec3 rd) {
    float fresnel = 1.0 - max(dot(nor,-rd), 0.0);
    vec3  col     = spectrum(pos.y*2.0 + iTime*0.5 + audioMid*2.5);
    col = mix(col, vec3(0.4,0.7,1.0), fresnel);
    col *= 0.6 + audioMid * 1.0;
    return col;
}

vec3 shadeTorus(vec3 pos, vec3 nor, vec3 rd) {
    float rim = pow(1.0 - max(dot(nor,-rd), 0.0), 2.0);
    vec3  col = vec3(1.0,0.3,0.7) * (0.4 + rim*1.5);
    col += vec3(0.3,0.6,1.0) * audioHigh * 2.0;
    return col;
}

vec3 shadePyramid(vec3 pos, vec3 nor, vec3 rd) {
    float fresnel = pow(1.0 - max(dot(nor,-rd), 0.0), 3.0);
    vec3  col     = vec3(0.5,0.8,1.0);
    col += spectrum(length(pos) + iTime*0.3) * 0.4;
    col += vec3(1.0) * fresnel * 2.0;
    col *= 0.5 + audioHigh * 1.4;
    return col;
}

vec3 shadePlatform(vec3 pos, vec3 nor, vec3 rd) {
    float diff = max(dot(nor, normalize(vec3(1.0,2.0,1.0))), 0.0);
    vec3  col  = vec3(0.85,0.82,0.78) * (0.5 + diff*0.5);
    col += vec3(0.1,0.08,0.06) * audioTotal * 0.3;
    return col;
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN IMAGE
// ═══════════════════════════════════════════════════════════════════════════
void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    computeAudio();

    // Camera orbits scene
    float camT    = iTime * 0.15;
    float camDist = 14.0 + sin(iTime*0.08) * 3.0;
    vec3  ro      = vec3(
        sin(camT)       * camDist,
        2.5 + cos(camT*0.6) * 2.0,
        cos(camT)       * camDist
    );
    vec3 lookAt = vec3(0.0, -0.5, 0.0);

    vec3 ww = normalize(lookAt - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0,1.0,0.0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x*uu + uv.y*vv + 1.6*ww);

    // ── Background: deep space tint + warp starfield ──
    vec3 col = vec3(0.02, 0.03, 0.08);
    col += psychedelicPalette(length(uv)*0.5 + iTime*0.1, 0.0) * 0.06;

    // Warp stars live in screen-UV space so they always fill the background
    vec3 stars = warpStarfield(uv, iTime);
    col += stars * 0.55;                // blend so they don't overpower 3D scene

    // ── Raymarch ──
    float t = 0.0;
    float matID, segID, energyField;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3  p = ro + t * rd;
        float d = map(p, matID, segID, energyField);
        if (d < SURF_DIST || t > MAX_DIST) break;
        t += d * 0.75;
    }

    if (t < MAX_DIST) {
        vec3 pos = ro + t * rd;
        vec3 nor = calcNormal(pos);

        if      (matID < 0.5) col = shadeSnake(pos, nor, rd, segID, energyField);
        else if (matID < 1.5) col = shadeEye(pos, nor, rd);
        else if (matID < 2.5) col = shadeBoing(pos, nor, rd, iTime);
        else if (matID < 3.5) col = shadeBox(pos, nor, rd);
        else if (matID < 4.5) col = shadeTorus(pos, nor, rd);
        else if (matID < 5.5) col = shadePyramid(pos, nor, rd);
        else                  col = shadePlatform(pos, nor, rd);

        // Depth fog with color
        vec3 fogCol = psychedelicPalette(iTime*0.2, 0.3) * 0.2;
        col = mix(col, fogCol, 1.0 - exp(-t*0.035));
    }

    // Post-process
    col  = pow(col, vec3(0.85));
    col *= 1.2;
    col  = mix(vec3(dot(col, vec3(0.299,0.587,0.114))), col, 1.3); // saturation

    // Vignette
    vec2 q = fragCoord / iResolution.xy;
    col *= pow(16.0 * q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1);

    fragColor = vec4(col, 1.0);
}
