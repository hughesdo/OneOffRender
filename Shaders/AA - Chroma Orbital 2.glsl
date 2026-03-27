// ============================================================================
// CHROMA ORBITAL - Diverse Shapes Edition
// Varied orbiting objects: Boing, RubberCube, Gyroid, Torus, and more
// Audio-reactive on iChannel0
// ============================================================================

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT

out vec4 fragColor;

#define PI 3.14159265359
#define TAU 6.28318530718
#define EPSILON 0.0001
#define MAX_STEPS 128
#define MAX_DIST 100.0
#define MAX_BOUNCES 4

// ============================================================================
//                          TWEAKING VARIABLES
// ============================================================================

// --- SCENE SETTINGS ---
const float CENTER_SPHERE_SIZE = 2.2;
const float ORBIT_RADIUS = 5.0;

// --- AUDIO REACTIVITY ---
const float BASS_PULSE_STRENGTH = 0.5;
const float MID_ORBIT_INFLUENCE = 0.6;
const float HIGH_SPARKLE_AMOUNT = 1.2;

// --- LIGHTING ---
const float KEY_LIGHT_INTENSITY = 2.5;
const float FILL_LIGHT_INTENSITY = 1.0;
const float RIM_LIGHT_INTENSITY = 3.0;
const float SPECULAR_POWER = 64.0;
const float AMBIENT_INTENSITY = 0.25;

// --- CAMERA ---
const float CAMERA_ORBIT_SPEED = 0.5;
const float CAMERA_MIN_DISTANCE = 11.0;
const float CAMERA_MAX_DISTANCE = 22.0;
const float CAMERA_HEIGHT_BASE = 5.0;

// --- POST PROCESSING ---
const float EXPOSURE = 1.15;
const float CONTRAST = 1.25;
const float SATURATION = 1.3;
const float VIGNETTE_STRENGTH = 0.3;

// --- COLORS ---
const vec3 KEY_LIGHT_COLOR = vec3(1.0, 0.98, 0.95);
const vec3 FILL_LIGHT_COLOR = vec3(0.7, 0.85, 1.0);
const vec3 AMBIENT_COLOR = vec3(0.12, 0.1, 0.18);

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 getPsychedelicColor(vec3 p, float t, float audio) {
    float hue = atan(p.z, p.x) / TAU + 0.5 + t * 0.15 + audio * 0.4;
    return hsv2rgb(vec3(hue, 0.9, 1.0));
}

mat2 rot2D(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// Audio bands
vec3 getAudioBands() {
    float bass = texture(iChannel0, vec2(0.03, 0.0)).x;
    float mid = texture(iChannel0, vec2(0.12, 0.0)).x;
    float high = texture(iChannel0, vec2(0.35, 0.0)).x;
    return vec3(bass, mid, high);
}

vec3 sceneAudio;

// ============================================================================
// SDF PRIMITIVES
// ============================================================================

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    return (p.x + p.y + p.z - s) * 0.57735027;
}

// Gyroid - triply periodic minimal surface
float sdGyroid(vec3 p, float scale, float thickness) {
    p *= scale;
    return (abs(dot(sin(p), cos(p.zxy))) - thickness) / scale;
}

// ============================================================================
// BOING BALL (raymarched checkered sphere)
// ============================================================================

float sdBoingSphere(vec3 p, float r) {
    return length(p) - r;
}

vec3 getBoingColor(vec3 p, float r, float t) {
    // Normalize point on sphere surface
    vec3 n = normalize(p);
    
    // Rotate the pattern
    float angle = 0.3046;
    float rotSpeed = t * 0.5;
    n.xz *= rot2D(rotSpeed);
    n.xy *= rot2D(angle);
    
    // Spherical coordinates for checkered pattern
    float u = atan(n.z, n.x) / PI;
    float v = asin(n.y) / PI + 0.5;
    
    // Checkered pattern - 8 columns, 6 rows
    float checker = mod(floor(u * 8.0) + floor(v * 6.0), 2.0);
    
    // Intensity based on distance from center
    float intensity = 1.2 - length(p) / r * 0.3;
    
    if (checker < 0.5) {
        return vec3(1.0) * intensity;  // White
    } else {
        return vec3(1.0, 0.15, 0.1) * intensity;  // Red
    }
}

// ============================================================================
// RUBBER CUBE (twisted raymarched cube)
// ============================================================================

vec3 twistCube(vec3 p, float t) {
    float twist = sin(t * 0.3) * 1.5;
    float c = cos(twist * p.y);
    float s = sin(twist * p.y * 0.5);
    mat2 m = mat2(c, -s, s, c);
    return vec3(m * p.xz, p.y);
}

float sdRubberCube(vec3 p, float size, float t) {
    p = twistCube(p, t);
    
    // Rotate the cube
    float rotAngle = t * 0.4;
    p.xy *= rot2D(rotAngle);
    p.yz *= rot2D(rotAngle * 0.7);
    
    return sdBox(p, vec3(size)) - 0.05;  // Rounded edges
}

vec3 getRubberCubeColor(vec3 p, float t) {
    vec3 twisted = twistCube(p, t);
    float rotAngle = t * 0.4;
    twisted.xy *= rot2D(rotAngle);
    twisted.yz *= rot2D(rotAngle * 0.7);
    
    // Face pattern - diagonal stripes
    vec2 uv = twisted.xy;
    float pattern = mod(floor((uv.x + uv.y) * 4.0), 2.0);
    
    // Patriotic colors
    if (pattern < 0.5) {
        return vec3(0.9, 0.1, 0.1);  // Red
    } else {
        return vec3(0.95, 0.95, 0.95);  // White
    }
}

// ============================================================================
// CRYSTAL SHARD (elongated octahedron)
// ============================================================================

float sdCrystal(vec3 p, float size, float t) {
    // Rotate
    p.xz *= rot2D(t * 0.3);
    p.yz *= rot2D(t * 0.2);
    
    // Elongate vertically
    p.y *= 0.6;
    
    return sdOctahedron(p, size);
}

// ============================================================================
// SCENE DEFINITION
// ============================================================================

// Material IDs
#define MAT_NONE 0
#define MAT_CENTER_MIRROR 1
#define MAT_BOING 2
#define MAT_RUBBER_CUBE 3
#define MAT_GYROID 4
#define MAT_TORUS 5
#define MAT_CRYSTAL 6
#define MAT_FLOATING 7

// Orbit object positions
vec3 getOrbitPos(int index, float t, float bass, float mid) {
    float count = 5.0;
    float angle = t * (0.25 + float(index) * 0.04) + float(index) * TAU / count;
    float radius = ORBIT_RADIUS + mid * MID_ORBIT_INFLUENCE * (float(index) - 2.0);
    float yOffset = sin(t * 0.5 + float(index) * 1.3) * 2.0;
    return vec3(cos(angle) * radius, 3.0 + yOffset, sin(angle) * radius);
}

// Main scene SDF
vec2 mapScene(vec3 p) {
    float t = iTime;
    float bass = sceneAudio.x;
    float mid = sceneAudio.y;
    float high = sceneAudio.z;
    
    float d = MAX_DIST;
    float mat = float(MAT_NONE);
    
    // --- CENTER MIRROR SPHERE ---
    float pulse = 1.0 + bass * BASS_PULSE_STRENGTH;
    vec3 centerPos = vec3(0.0, 3.0 + sin(t * 0.3) * 0.4, 0.0);
    float dCenter = sdSphere(p - centerPos, CENTER_SPHERE_SIZE * pulse);
    if (dCenter < d) { d = dCenter; mat = float(MAT_CENTER_MIRROR); }
    
    // --- ORBITING OBJECT 1: BOING BALL ---
    vec3 boingPos = getOrbitPos(0, t, bass, mid);
    float boingSize = 1.0 + high * 0.3;
    float dBoing = sdBoingSphere(p - boingPos, boingSize);
    if (dBoing < d) { d = dBoing; mat = float(MAT_BOING); }
    
    // --- ORBITING OBJECT 2: RUBBER CUBE ---
    vec3 cubePos = getOrbitPos(1, t, bass, mid);
    float cubeSize = 0.7 + bass * 0.2;
    float dCube = sdRubberCube(p - cubePos, cubeSize, t);
    if (dCube < d) { d = dCube; mat = float(MAT_RUBBER_CUBE); }
    
    // --- ORBITING OBJECT 3: GYROID ---
    vec3 gyroidPos = getOrbitPos(2, t, bass, mid);
    vec3 gp = p - gyroidPos;
    gp.xz *= rot2D(t * 0.35);
    gp.yz *= rot2D(t * 0.25);
    float gyroidScale = 3.0;
    float gyroidThick = 0.3 + high * 0.15;
    // Bound the gyroid to a sphere
    float dGyroidBound = sdSphere(p - gyroidPos, 1.2);
    float dGyroid = max(sdGyroid(gp, gyroidScale, gyroidThick), dGyroidBound);
    if (dGyroid < d) { d = dGyroid; mat = float(MAT_GYROID); }
    
    // --- ORBITING OBJECT 4: TORUS ---
    vec3 torusPos = getOrbitPos(3, t, bass, mid);
    vec3 tp = p - torusPos;
    tp.xz *= rot2D(t * 0.4);
    tp.xy *= rot2D(t * 0.3 + PI * 0.25);
    float torusR = 0.8 + mid * 0.2;
    float dTorus = sdTorus(tp, vec2(torusR, 0.25 + high * 0.1));
    if (dTorus < d) { d = dTorus; mat = float(MAT_TORUS); }
    
    // --- ORBITING OBJECT 5: CRYSTAL SHARD ---
    vec3 crystalPos = getOrbitPos(4, t, bass, mid);
    float crystalSize = 0.9 + bass * 0.25;
    float dCrystal = sdCrystal(p - crystalPos, crystalSize, t);
    if (dCrystal < d) { d = dCrystal; mat = float(MAT_CRYSTAL); }
    
    // --- INNER FLOATING SPHERES (keep 2 small ones) ---
    for (int i = 0; i < 2; i++) {
        float fAngle = -t * 0.5 + float(i) * PI;
        float fRadius = 4.0 + bass * 1.5;
        float fY = cos(t * 0.9 + float(i) * 2.5) * 1.2;
        float fSize = 0.4 + high * 0.25;
        vec3 fPos = vec3(sin(fAngle) * fRadius, 3.0 + fY, cos(fAngle) * fRadius);
        float dFloat = sdSphere(p - fPos, fSize);
        if (dFloat < d) { d = dFloat; mat = float(MAT_FLOATING); }
    }
    
    return vec2(d, mat);
}

// Normal calculation
vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        mapScene(p + e.xyy).x - mapScene(p - e.xyy).x,
        mapScene(p + e.yxy).x - mapScene(p - e.yxy).x,
        mapScene(p + e.yyx).x - mapScene(p - e.yyx).x
    ));
}

// ============================================================================
// RAYMARCHING
// ============================================================================

vec2 raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    float mat = 0.0;
    
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * t;
        vec2 res = mapScene(p);
        float d = res.x;
        mat = res.y;
        
        if (d < EPSILON) break;
        if (t > MAX_DIST) { mat = 0.0; break; }
        
        t += d * 0.8;
    }
    
    return vec2(t, mat);
}

// ============================================================================
// ENVIRONMENT & LIGHTING
// ============================================================================

vec3 getEnvironment(vec3 rd) {
    float t = iTime;
    float bass = sceneAudio.x;
    float high = sceneAudio.z;
    
    // Psychedelic gradient sky
    float y = 0.5 * (rd.y + 1.0);
    vec3 sky = mix(vec3(0.7, 0.2, 0.7), vec3(0.08, 0.08, 0.25), y);
    
    // Swirling colors
    float swirl = sin(rd.x * 5.0 + t * 0.4) * sin(rd.z * 5.0 + t * 0.35);
    vec3 swirlCol = getPsychedelicColor(rd * 3.0, t * 0.15, bass);
    sky = mix(sky, swirlCol, smoothstep(0.3, 0.9, swirl) * 0.35);
    
    // Sun
    vec3 sunDir = normalize(vec3(0.4, 0.6, 0.2));
    float sunDot = max(dot(rd, sunDir), 0.0);
    sky += vec3(1.0, 0.95, 0.8) * pow(sunDot, 400.0) * (1.0 + high);
    sky += vec3(1.0, 0.8, 0.5) * pow(sunDot, 20.0) * 0.4;
    
    // Rainbow rim
    float rim = pow(1.0 - max(rd.y, 0.0), 3.0);
    sky += getPsychedelicColor(rd * 4.0, t * 0.2, bass) * rim * 0.25;
    
    return sky;
}

vec3 getLighting(vec3 p, vec3 n, vec3 rd, vec3 baseColor, int matType) {
    vec3 viewDir = -rd;
    
    // Key light
    vec3 l1 = normalize(vec3(6.0, 12.0, 4.0) - p);
    float diff1 = max(dot(n, l1), 0.0);
    float spec1 = pow(max(dot(reflect(-l1, n), viewDir), 0.0), SPECULAR_POWER);
    vec3 key = baseColor * diff1 * KEY_LIGHT_COLOR * KEY_LIGHT_INTENSITY +
               KEY_LIGHT_COLOR * spec1 * KEY_LIGHT_INTENSITY * 0.6;
    
    // Fill light
    vec3 l2 = normalize(vec3(-6.0, 8.0, -4.0) - p);
    float diff2 = max(dot(n, l2), 0.0);
    vec3 fill = baseColor * diff2 * FILL_LIGHT_COLOR * FILL_LIGHT_INTENSITY * 0.4;
    
    // Rim light (rainbow)
    vec3 rimCol = getPsychedelicColor(p, iTime, sceneAudio.x);
    float rim = pow(1.0 - max(dot(n, viewDir), 0.0), 3.0);
    vec3 rimLight = rimCol * rim * RIM_LIGHT_INTENSITY * (0.5 + sceneAudio.z);
    
    // Ambient
    vec3 ambient = AMBIENT_COLOR * baseColor * AMBIENT_INTENSITY;
    
    return ambient + key + fill + rimLight;
}

// Fresnel
float fresnel(vec3 n, vec3 v, float ior) {
    float r0 = (1.0 - ior) / (1.0 + ior);
    r0 *= r0;
    return r0 + (1.0 - r0) * pow(1.0 - max(dot(n, v), 0.0), 5.0);
}

// ============================================================================
// MAIN RENDER
// ============================================================================

vec3 render(vec3 ro, vec3 rd) {
    vec3 color = vec3(0.0);
    vec3 throughput = vec3(1.0);
    float t = iTime;
    
    for (int bounce = 0; bounce < MAX_BOUNCES; bounce++) {
        vec2 res = raymarch(ro, rd);
        float dist = res.x;
        int mat = int(res.y);
        
        if (mat == MAT_NONE) {
            color += throughput * getEnvironment(rd);
            break;
        }
        
        vec3 p = ro + rd * dist;
        vec3 n = getNormal(p);
        vec3 baseColor = vec3(1.0);
        float reflectivity = 0.0;
        float refractivity = 0.0;
        float ior = 1.5;
        
        // Get orbit position for coloring
        float bass = sceneAudio.x;
        float mid = sceneAudio.y;
        float high = sceneAudio.z;
        
        // Material properties based on type
        if (mat == MAT_CENTER_MIRROR) {
            baseColor = getPsychedelicColor(p, t, bass);
            reflectivity = 0.95;
        }
        else if (mat == MAT_BOING) {
            vec3 boingPos = getOrbitPos(0, t, bass, mid);
            float boingSize = 1.0 + high * 0.3;
            baseColor = getBoingColor(p - boingPos, boingSize, t);
            reflectivity = 0.15;
        }
        else if (mat == MAT_RUBBER_CUBE) {
            vec3 cubePos = getOrbitPos(1, t, bass, mid);
            baseColor = getRubberCubeColor(p - cubePos, t);
            reflectivity = 0.1;
        }
        else if (mat == MAT_GYROID) {
            // Iridescent gyroid
            float hue = dot(n, vec3(1.0)) * 0.5 + t * 0.1 + high * 0.3;
            baseColor = hsv2rgb(vec3(hue, 0.8, 1.0));
            reflectivity = 0.3;
            refractivity = 0.5;
            ior = 1.4;
        }
        else if (mat == MAT_TORUS) {
            // Golden torus
            baseColor = vec3(1.0, 0.85, 0.4);
            reflectivity = 0.6;
        }
        else if (mat == MAT_CRYSTAL) {
            // Prismatic crystal
            float hue = atan(n.z, n.x) / TAU + 0.5 + t * 0.08;
            baseColor = hsv2rgb(vec3(hue, 0.7, 1.0));
            reflectivity = 0.4;
            refractivity = 0.4;
            ior = 1.8;
        }
        else if (mat == MAT_FLOATING) {
            // Glass spheres
            float hue = length(p.xz) * 0.1 + t * 0.1;
            baseColor = hsv2rgb(vec3(hue, 0.85, 1.0));
            reflectivity = 0.2;
            refractivity = 0.6;
            ior = 1.5;
        }
        
        // Lighting
        vec3 lighting = getLighting(p, n, rd, baseColor, mat);
        float directWeight = max(0.0, 1.0 - reflectivity - refractivity);
        color += throughput * lighting * directWeight;
        
        // Reflection/refraction
        float fres = fresnel(n, -rd, ior);
        
        if (reflectivity > 0.1) {
            throughput *= reflectivity * mix(0.5, 1.0, fres);
            rd = reflect(rd, n);
            ro = p + n * EPSILON * 3.0;
        }
        else if (refractivity > 0.1) {
            vec3 refractDir = refract(rd, n, 1.0 / ior);
            if (length(refractDir) == 0.0) {
                refractDir = reflect(rd, n);
                ro = p + n * EPSILON * 3.0;
            } else {
                ro = p - n * EPSILON * 3.0;
            }
            throughput *= refractivity * baseColor * (1.0 - fres);
            rd = refractDir;
        }
        else {
            break;
        }
        
        // Early exit for dim rays
        if (max(max(throughput.r, throughput.g), throughput.b) < 0.05) break;
    }
    
    return color;
}

// ============================================================================
// CAMERA
// ============================================================================

vec3 getCameraPos(float t) {
    float angle = t * CAMERA_ORBIT_SPEED;
    float phase = t * 0.12;
    float dist = mix(CAMERA_MAX_DISTANCE, CAMERA_MIN_DISTANCE, 0.5 + 0.5 * sin(phase));
    dist += sceneAudio.x * 1.5;
    
    float height = CAMERA_HEIGHT_BASE + sin(t * 0.2) * 2.5 + sceneAudio.y * 1.0;
    
    return vec3(cos(angle) * dist, height, sin(angle) * dist);
}

mat3 getCameraMatrix(vec3 ro, vec3 target) {
    vec3 forward = normalize(target - ro);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);
    return mat3(right, up, forward);
}

// ============================================================================
// POST PROCESSING
// ============================================================================

vec3 postProcess(vec3 col, vec2 uv) {
    // Bloom
    float bright = dot(col, vec3(0.299, 0.587, 0.114));
    col += col * smoothstep(0.6, 1.0, bright) * 0.2;
    
    // Contrast & saturation
    col = mix(vec3(0.5), col, CONTRAST);
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(lum), col, SATURATION);
    
    // Exposure & tone mapping
    col *= EXPOSURE;
    col = col / (col + vec3(0.8));
    
    // Gamma
    col = pow(col, vec3(1.0 / 2.2));
    
    // Vignette
    col *= 1.0 - VIGNETTE_STRENGTH * dot(uv, uv);
    
    return col;
}

// ============================================================================
// MAIN
// ============================================================================

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    sceneAudio = getAudioBands();

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.x;
    
    // Chromatic aberration
    float aber = 0.012 * (1.0 + sceneAudio.z * 1.5);
    
    vec3 ro = getCameraPos(iTime);
    vec3 target = vec3(0.0, 3.0 + sceneAudio.x * 0.4, 0.0);
    mat3 cam = getCameraMatrix(ro, target);
    
    // Three rays for chromatic aberration
    vec3 rdR = cam * normalize(vec3(uv + uv * aber, 1.5));
    vec3 rdG = cam * normalize(vec3(uv, 1.5));
    vec3 rdB = cam * normalize(vec3(uv - uv * aber, 1.5));
    
    vec3 colR = render(ro, rdR);
    vec3 colG = render(ro, rdG);
    vec3 colB = render(ro, rdB);
    
    vec3 color = vec3(colR.r, colG.g, colB.b);
    
    // Chromatic boost
    color.r += colG.g * sceneAudio.z * 0.06;
    color.b += colG.g * sceneAudio.z * 0.06;
    
    color = postProcess(color, uv);
    
    fragColor = vec4(color, 1.0);
}
