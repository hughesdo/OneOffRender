#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // BufferA (audio analysis)
uniform samplerCube iChannel1; // Cubemap (Uffizi Gallery)

out vec4 fragColor;

/*
    CRYSTALLINE VOID - Audio Reactive Fractal Flythrough
    =====================================================

    Converted for OneOffRender by @OneHung
    Original Shadertoy: https://www.shadertoy.com/view/3cyfzm

    Inspired by Shane's "Fractal Flythrough" with a novel approach:
    - Crystalline/void aesthetic instead of steampunk
    - Audio-reactive geometry that breathes and pulses
    - Procedural iridescent materials
    - Smooth camera path through infinite recursive structure

    The geometry pulses with bass, color shifts with mids,
    and detail complexity increases with treble.
*/

const float FAR = 80.0;
const float PI = 3.14159265359;

// Audio values (fetched from Buffer A)
float gBass, gMid, gTreble, gTotal;
float gSmoothedBass, gSmoothedMid, gSmoothedTreble;

// Fetch audio data from Buffer A
void fetchAudio() {
    vec4 raw = texelFetch(iChannel0, ivec2(0, 0), 0);
    gBass = raw.x;
    gMid = raw.y;
    gTreble = raw.z;
    gTotal = raw.w;

    vec4 smoothed = texelFetch(iChannel0, ivec2(0, 1), 0);
    gSmoothedBass = smoothed.x;
    gSmoothedMid = smoothed.y;
    gSmoothedTreble = smoothed.z;
}

// Rotation matrix
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// Hash functions
float hash(float n) { return fract(sin(n) * 43758.5453); }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

vec3 hash3(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return fract(sin(p) * 43758.5453);
}



// Smooth min for organic blending
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// ============================================
// CAMERA PATH - Smooth spline through the void
// ============================================

vec3 cp[16];

void setCamPath() {
    float audioOffset = gSmoothedBass * 0.1;
    float s = 2.0 * 0.94;
    float b = 4.0 * 0.94;

    // Create a looping path through the crystal lattice
    cp[0] = vec3(0, 0, 0);
    cp[1] = vec3(0, audioOffset, b);
    cp[2] = vec3(s, 0, b);
    cp[3] = vec3(s, -audioOffset, s);
    cp[4] = vec3(s, s, s);
    cp[5] = vec3(-s, s + audioOffset, s);
    cp[6] = vec3(-s, 0, s);
    cp[7] = vec3(-s, -audioOffset, 0);
    cp[8] = vec3(0, 0, 0);
    cp[9] = vec3(0, audioOffset, -b);
    cp[10] = vec3(0, b, -b);
    cp[11] = vec3(-s, b - audioOffset, -b);
    cp[12] = vec3(-s, 0, -b);
    cp[13] = vec3(-s, audioOffset, 0);
    cp[14] = vec3(-s, -s, 0);
    cp[15] = vec3(0, -s - audioOffset, 0);
}

vec3 catmull(vec3 p0, vec3 p1, vec3 p2, vec3 p3, float t) {
    return (((-p0 + p1 * 3.0 - p2 * 3.0 + p3) * t * t * t +
             (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * t * t +
             (-p0 + p2) * t + p1 * 2.0)) * 0.5;
}

vec3 camPath(float t) {
    const int N = 16;
    t = fract(t / float(N)) * float(N);
    float seg = floor(t);
    float st = t - seg;

    int i0 = int(mod(seg - 1.0, float(N)));
    int i1 = int(mod(seg, float(N)));
    int i2 = int(mod(seg + 1.0, float(N)));
    int i3 = int(mod(seg + 2.0, float(N)));

    return catmull(cp[i0], cp[i1], cp[i2], cp[i3], st);
}

// ============================================
// DISTANCE FIELD - Crystalline Void Structure
// ============================================

float gObjID = 0.0;
vec3 gOrbPos = vec3(0.0); // Global orb position

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    return (p.x + p.y + p.z - s) * 0.57735027;
}

// Sphere distance function
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

// Calculate orb position based on time and audio
vec3 getOrbPosition(float t) {
    // Follow the camera path but offset ahead
    vec3 pathPos = camPath(t + 1.5);

    // Add oscillating movement based on audio
    float oscillation = sin(iTime * 1.3) + sin(iTime * 1.7) * 0.5;
    pathPos.x += oscillation * (0.5 + gSmoothedBass * 0.5);
    pathPos.y += cos(iTime * 2.0) * (0.3 + gSmoothedMid * 0.3);

    return pathPos;
}

// Novel fractal: Crystalline lattice with audio-reactive voids
float map(vec3 q) {
    // Audio modulation
    float bassBreath = 1.0 + gSmoothedBass * 0.15;
    float trebleDetail = 1.0 + gSmoothedTreble * 0.3;

    // === LAYER 1: Primary void structure ===
    vec3 p = abs(fract(q / 4.0) * 4.0 - 2.0);

    // Pulsing cross-section voids
    float voidSize = (4.0 / 3.0) * bassBreath;
    float primary = min(max(p.x, p.y), min(max(p.y, p.z), max(p.x, p.z))) - voidSize + 0.02;

    // === LAYER 2: Secondary crystalline structure ===
    p = abs(fract(q / 2.0) * 2.0 - 1.0);

    // Octahedral voids that breathe with bass
    float octaSize = 0.6 * bassBreath;
    float octa = sdOctahedron(p - 0.5, octaSize);

    // Combine with smooth blending
    float secondary = smin(max(p.x, p.y), smin(max(p.y, p.z), max(p.x, p.z), 0.08), 0.08) - (2.0 / 3.0);

    // === LAYER 3: Crystal formations ===
    vec3 p3 = abs(fract(q * 1.5) / 1.5 - 1.0 / 3.0);

    // Rotating crystal detail based on time and audio
    float rotAngle = iTime * 0.1 + gSmoothedMid * PI;
    p3.xy *= rot(rotAngle * 0.3);
    p3.yz *= rot(rotAngle * 0.2);

    float crystalSize = (2.0 / 9.0) * trebleDetail;
    float crystals = min(max(p3.x, p3.y), min(max(p3.y, p3.z), max(p3.x, p3.z))) - crystalSize + 0.03;

    // === LAYER 4: Fine detail (audio-reactive) ===
    vec3 p4 = abs(fract(q * 3.0) / 3.0 - 1.0 / 6.0);
    float fineDetail = sdOctahedron(p4, 0.12 * (1.0 + gSmoothedTreble * 0.5));

    // === Combine all layers ===
    float voidTunnel = max(primary, secondary);
    voidTunnel = max(voidTunnel, crystals);

    // Add floating crystal shards
    vec3 shardP = fract(q + 0.5) - 0.5;
    float shards = sdOctahedron(shardP, 0.08 + gSmoothedBass * 0.04) - 0.01;

    // Add the moving orb with gyroid pattern (inspired by Reflecting Crystals)
    vec3 orbP = q - gOrbPos;
    float orbRadius = 0.3 + gSmoothedBass * 0.1;
    float orb = sdSphere(orbP, orbRadius);

    // Add gyroid pattern to the orb surface
    vec3 gyroidP = orbP * 15.0;
    gyroidP.xy *= rot(iTime * 1.3);
    gyroidP.yz *= rot(iTime * 1.7);
    float gyroid = (abs(dot(sin(gyroidP), cos(gyroidP.yzx))) - 0.2) / 15.0;
    orb = max(orb, gyroid);

    // Determine material ID
    float d = voidTunnel;
    gObjID = 1.0; // Default: void walls

    if (orb < d) {
        d = orb;
        gObjID = 4.0; // Moving orb
    }

    if (shards < d) {
        d = shards;
        gObjID = 2.0; // Floating crystals
    }

    if (fineDetail < d - 0.05) {
        d = max(d, -fineDetail);
        gObjID = 3.0; // Fine crystal detail
    }

    return d;
}

// Raymarching
float trace(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 96; i++) {
        float h = map(ro + rd * t);
        if (abs(h) < 0.001 * (t * 0.2 + 1.0) || t > FAR) break;
        t += h * 0.75;
    }
    return t;
}

// Reflection trace (fewer iterations)
float refTrace(vec3 ro, vec3 rd) {
    float t = 0.0;
    for (int i = 0; i < 24; i++) {
        float h = map(ro + rd * t);
        if (h < 0.003 * (t * 0.2 + 1.0) || t > FAR * 0.5) break;
        t += h;
    }
    return t;
}

// Normal calculation
vec3 calcNormal(vec3 p) {
    const vec2 e = vec2(0.004, 0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

// Ambient occlusion
float calcAO(vec3 p, vec3 n) {
    float occ = 0.0, sca = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.01 + 0.12 * float(i);
        float d = map(p + n * h);
        occ += (h - d) * sca;
        sca *= 0.7;
    }
    return clamp(1.0 - 1.5 * occ, 0.0, 1.0);
}

// ============================================
// MATERIALS - Iridescent crystals
// ============================================

float gSmoothedTotal() {
    return gSmoothedBass + gSmoothedMid + gSmoothedTreble;
}

// Palette function for audio-reactive edge colors (inspired by the_fractal)
vec3 audioPalette(float t) {
    return 0.5 + 0.5 * cos(6.28 * (1.0 * t + vec3(0.0, 0.3, 0.7)));
}

vec3 iridescence(vec3 viewDir, vec3 normal, float intensity) {
    float ndv = 1.0 - max(dot(viewDir, normal), 0.0);
    ndv = pow(ndv, 2.0);

    // Audio-reactive color shift
    float hueShift = gSmoothedMid * 2.0 + iTime * 0.1;

    vec3 col;
    col.r = 0.5 + 0.5 * sin(ndv * 6.28 + hueShift);
    col.g = 0.5 + 0.5 * sin(ndv * 6.28 + hueShift + 2.09);
    col.b = 0.5 + 0.5 * sin(ndv * 6.28 + hueShift + 4.18);

    return mix(vec3(0.5), col, intensity);
}

vec3 getMaterial(float id, vec3 p, vec3 n, vec3 rd) {
    vec3 col;

    if (id < 1.5) {
        // Void walls - dark crystalline
        col = vec3(0.02, 0.03, 0.05);
        col += iridescence(-rd, n, 0.3) * 0.2;

        // Glowing veins pulsing with bass
        vec3 vein = fract(p * 2.0);
        float veinPattern = smoothstep(0.48, 0.5, max(vein.x, max(vein.y, vein.z)));
        col += vec3(0.1, 0.3, 0.8) * veinPattern * (0.5 + gSmoothedBass * 2.0);

        // Audio-reactive edge coloring (inspired by the_fractal)
        // Detect edges based on position variation
        vec3 edgeP = fract(p * 4.0);
        float edgeDist = min(min(edgeP.x, 1.0 - edgeP.x),
                            min(min(edgeP.y, 1.0 - edgeP.y),
                                min(edgeP.z, 1.0 - edgeP.z)));

        // Create edge glow that responds to audio
        float edgeGlow = smoothstep(0.15, 0.0, edgeDist);

        // Audio-reactive color palette
        float colorPhase = length(p) * 0.5 + iTime * 0.5;
        vec3 edgeColor = audioPalette(colorPhase);

        // Modulate with different audio frequencies
        edgeColor.r += gSmoothedBass * 0.5;
        edgeColor.g += gSmoothedMid * 0.5;
        edgeColor.b += gSmoothedTreble * 0.3;

        // Add subtle edge coloring
        col += edgeColor * edgeGlow * (0.3 + gSmoothedTotal() * 0.7);
    }
    else if (id < 2.5) {
        // Floating crystals - bright iridescent with enhanced reflectivity
        col = iridescence(-rd, n, 1.0);
        col *= 0.5 + gSmoothedTotal() * 0.5;

        // Inner glow with glue-like translucency
        col += vec3(0.5, 0.7, 1.0) * (0.2 + gSmoothedBass * 0.8);
    }
    else if (id < 3.5) {
        // Fine detail - emissive
        float pulse = 0.5 + 0.5 * sin(iTime * 4.0 + p.x * 10.0 + gSmoothedMid * 10.0);
        col = mix(vec3(0.8, 0.2, 0.5), vec3(0.2, 0.5, 0.9), pulse);
        col *= 1.0 + gSmoothedTreble * 2.0;
    }
    else {
        // Moving orb - glowing with audio-reactive colors
        float phase = length(p - gOrbPos) * 4.0 - iTime * 2.0;
        float hueShift = gSmoothedMid * 2.0;

        // HSV-like color cycling
        vec3 baseCol;
        baseCol.r = 0.5 + 0.5 * sin(phase + hueShift);
        baseCol.g = 0.5 + 0.5 * sin(phase + hueShift + 2.09);
        baseCol.b = 0.5 + 0.5 * sin(phase + hueShift + 4.18);

        col = mix(vec3(0.9), baseCol, 0.8);
        col += iridescence(-rd, n, 0.5) * 0.5;
    }

    return col;
}

// Get material properties for reflectivity (Fresnel factor and metalness)
void getMaterialProperties(float id, out float f0, out float metalness) {
    if (id < 1.5) {
        // Void walls - low reflectivity
        f0 = 0.04;
        metalness = 0.1;
    }
    else if (id < 2.5) {
        // Floating crystals - high reflectivity (glue-like)
        f0 = 0.8;
        metalness = 0.9;
    }
    else if (id < 3.5) {
        // Fine detail - medium reflectivity
        f0 = 0.2;
        metalness = 0.5;
    }
    else {
        // Moving orb - very high reflectivity
        f0 = 0.9;
        metalness = 0.95;
    }
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord - iResolution.xy * 0.5) / iResolution.y;

    // Fetch audio data
    fetchAudio();

    // Time with slight audio modulation
    float speed = iTime * 0.3 + 5.0;
    speed += gSmoothedBass * 0.1; // Bass pushes camera slightly

    // Initialize camera path
    setCamPath();

    // Calculate orb position (needs to be done before map() is called)
    gOrbPos = getOrbPosition(speed);

    // Camera setup - follow the orb
    vec3 ro = camPath(speed);
    vec3 lk = gOrbPos; // Look at the orb
    vec3 lp = gOrbPos + vec3(0, 0.5, 0); // Light position near orb

    // Camera matrix with stable up vector
    float FOV = 1.8 + gSmoothedBass * 0.2; // FOV breathes with bass
    vec3 fwd = normalize(lk - ro);
    vec3 rgt = normalize(cross(fwd, vec3(0, 1, 0)));
    vec3 up = cross(rgt, fwd);

    // Slight camera shake with treble
    float shake = gSmoothedTreble * 0.01;
    uv += vec2(hash(iTime) - 0.5, hash(iTime + 1.0) - 0.5) * shake;

    vec3 rd = normalize(fwd + FOV * (uv.x * rgt + uv.y * up));

    // Raymarch
    float t = trace(ro, rd);
    float saveID = gObjID;

    // Background - deep void
    vec3 col = vec3(0.0);
    vec3 bgCol = vec3(0.01, 0.02, 0.04);
    bgCol += vec3(0.05, 0.1, 0.2) * gSmoothedBass; // Background pulses

    if (t < FAR) {
        vec3 pos = ro + rd * t;
        vec3 nor = calcNormal(pos);

        // Lighting
        vec3 li = normalize(lp - pos);
        float lDist = length(lp - pos);
        float atten = 1.0 / (1.0 + lDist * 0.05 + lDist * lDist * 0.01);

        float ao = calcAO(pos, nor);
        float diff = max(dot(nor, li), 0.0);
        diff = pow(diff, 2.0) * 1.5;

        float spec = pow(max(dot(reflect(-li, nor), -rd), 0.0), 16.0);
        float fres = pow(1.0 - max(dot(nor, -rd), 0.0), 3.0);

        // Material color
        col = getMaterial(saveID, pos, nor, rd);

        // Get material properties for reflectivity
        float f0, metalness;
        getMaterialProperties(saveID, f0, metalness);

        // Schlick's approximation for Fresnel
        vec3 ref = reflect(rd, nor);
        float fresnel = f0 + (1.0 - f0) * pow(1.0 - max(dot(-rd, nor), 0.0), 5.0);

        // Apply lighting
        col *= (diff * (1.0 - metalness) + 0.15) * atten;
        col += spec * metalness * atten;

        // Fresnel rim light (audio reactive)
        vec3 rimColor = mix(vec3(0.3, 0.5, 0.8), vec3(0.8, 0.3, 0.5), gSmoothedMid);
        col += fres * rimColor * (0.3 + gSmoothedTreble);

        // Enhanced multi-bounce reflections for crystals (inspired by Reflecting Crystals)
        vec3 reflectionCol = vec3(0.0);
        vec3 reflectionAtten = vec3(1.0);
        vec3 rp = pos;
        vec3 rrd = ref;

        // Multiple reflection bounces for highly reflective materials
        int numBounces = (saveID > 1.5 && saveID < 2.5) ? 3 : 1; // More bounces for crystals

        for (int bounce = 0; bounce < 3; bounce++) {
            if (bounce >= numBounces) break;

            float rt = refTrace(rp + rrd * 0.01, rrd);
            if (rt < FAR * 0.5) {
                vec3 rpos = rp + rrd * rt;
                vec3 rnor = calcNormal(rpos);
                float rObjID = gObjID;

                // Get reflected material
                vec3 rCol = getMaterial(rObjID, rpos, rnor, rrd);

                // Calculate reflection contribution
                float rf0, rmetalness;
                getMaterialProperties(rObjID, rf0, rmetalness);
                float rfresnel = rf0 + (1.0 - rf0) * pow(1.0 - max(dot(-rrd, rnor), 0.0), 5.0);

                // Add to reflection color with attenuation
                reflectionCol += rCol * reflectionAtten * fresnel;

                // Update for next bounce
                reflectionAtten *= rCol * rfresnel * 0.5;
                rp = rpos;
                rrd = reflect(rrd, rnor);
            }
            else {
                // Hit background - add cubemap
                vec3 cubeRef = texture(iChannel1, rrd).rgb;
                reflectionCol += cubeRef * reflectionAtten * 0.3;
                break;
            }
        }

        col += reflectionCol;

        // Additional cubemap reflection for non-crystal materials
        if (saveID < 1.5 || saveID > 2.5) {
            vec3 cubeRef = texture(iChannel1, ref).rgb;
            col += cubeRef * fresnel * 0.15 * (1.0 + gSmoothedMid);
        }

        col *= ao;

        // Distance fog
        col = mix(col, bgCol, 1.0 - exp(-t * t / (FAR * FAR) * 8.0));
    }
    else {
        col = bgCol;
    }

    // Post-processing
    // Vignette
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.2);

    // Chromatic aberration on bass hits
    if (gBass > 0.5) {
        float aberr = (gBass - 0.5) * 0.01;
        // Simple fake chromatic shift in final color
        col.r *= 1.0 + aberr;
        col.b *= 1.0 - aberr;
    }

    // Gamma correction
    col = pow(max(col, 0.0), vec3(0.4545));

    // Subtle film grain
    col += (hash(fragCoord + iTime) - 0.5) * 0.03;

    fragColor = vec4(col, 1.0);
}
