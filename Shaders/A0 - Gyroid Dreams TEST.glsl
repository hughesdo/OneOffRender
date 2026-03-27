#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// Gyroid Dreams v9 — Original Gyroid + Carved Tube Path
// Keep the full gyroid structure, but carve a guaranteed-clear path through it

// ===== TWEAKABLES =====
#define ORB_DISTANCE     10.0    // How far ahead the orb is (was 2.5)
#define ORB_CORE_BRIGHT  1.5    // Core brightness (was 3.0)
#define ORB_GLOW_BRIGHT  0.6    // Glow brightness (was 1.5)
#define ORB_SIZE         0.15    // Base orb radius
#define ORB_PULSE        0.03   // How much orb pulses with time
#define ORB_AUDIO_REACT  0.22   // How much orb reacts to audio
#define ORB_WOBBLE       0.32   // Side-to-side wobble amount
#define CAMERA_SPEED     3.0    // Forward travel speed
#define TUBE_RADIUS      0.7    // Radius of carved path

mat2 rot(float a){ float c=cos(a), s=sin(a); return mat2(c,-s,s,c); }

// ===== AUDIO =====
float getAudio(float freq) {
    return texture(iChannel0, vec2(freq, 0.0)).x;
}
float getBass() { return getAudio(0.05) + getAudio(0.1); }
float getMid() { return getAudio(0.25) + getAudio(0.35); }
float getHigh() { return getAudio(0.6) + getAudio(0.75); }

// ===== THE PATH we carve through the gyroid =====
vec3 tunnelPath(float z) {
    return vec3(
        2.0 * sin(z * 0.12) + 1.0 * cos(z * 0.19),
        1.5 * cos(z * 0.14) + 0.7 * sin(z * 0.23),
        z
    );
}

// ===== GYROID FIELD =====
float gyroidField(vec3 p){
    return sin(p.x)*cos(p.y) + sin(p.y)*cos(p.z) + sin(p.z)*cos(p.x);
}

// ===== SCENE DISTANCE =====
float sceneDist(vec3 p){
    // Original gyroid - exactly as you had it
    float scale = 1.25;
    vec3 q = p / scale;
    float gyroid = (abs(gyroidField(q)) - 0.28) / 1.7 * scale;
    gyroid += sin(q.x*4.)*sin(q.y*4.)*sin(q.z*4.) * 0.015 * scale;
    
    // Tube carved along path
    vec3 pathCenter = tunnelPath(p.z);
    float distToPath = length(p.xy - pathCenter.xy);
    float tube = TUBE_RADIUS - distToPath;  // Positive inside tube (open space)
    
    // Union: open space where EITHER gyroid channel OR tube
    // max() gives union of open regions in SDF
    return max(gyroid, tube);
}

vec3 sceneNormal(vec3 p){
    vec2 e = vec2(0.001, 0.);
    return normalize(vec3(
        sceneDist(p+e.xyy) - sceneDist(p-e.xyy),
        sceneDist(p+e.yxy) - sceneDist(p-e.yxy),
        sceneDist(p+e.yyx) - sceneDist(p-e.yyx)
    ));
}

// ===== CAMERA AND ORB =====
void getCameraState(float time, out vec3 camPos, out vec3 camDir, out vec3 orbPos) {
    float z = time * CAMERA_SPEED;
    
    // Camera on the path
    camPos = tunnelPath(z);
    
    // Orb ahead on the path
    orbPos = tunnelPath(z + ORB_DISTANCE);
    
    // Small orb wobble
    orbPos.x += sin(time * 2.5) * ORB_WOBBLE;
    orbPos.y += cos(time * 2.1) * ORB_WOBBLE;
    
    // Look at orb
    camDir = normalize(orbPos - camPos);
}

// ===== ORB GLOW =====
vec3 renderOrb(vec3 ro, vec3 rd, vec3 orbCenter, float hitT) {
    vec3 co = orbCenter - ro;
    float t = dot(co, rd);
    vec3 closest = ro + rd * max(t, 0.0);
    float dist = length(closest - orbCenter);
    
    float bass = getBass();
    float mid = getMid();
    float high = getHigh();
    
    float radius = ORB_SIZE + ORB_PULSE * sin(iTime * 5.0) + bass * ORB_AUDIO_REACT;
    
    vec3 col1 = vec3(1.0, 0.2, 0.5);
    vec3 col2 = vec3(0.2, 0.8, 1.0);
    vec3 col3 = vec3(1.0, 1.0, 0.3);
    
    vec3 orbCol = col1 * (0.6 + bass * 0.8) + 
                  col2 * (0.4 + mid * 0.6) + 
                  col3 * (high * 0.5);
    
    float core = smoothstep(radius * 2.0, 0.0, dist);
    core = pow(core, 2.0);
    
    float glow = exp(-dist * 2.5 / radius);
    
    vec3 result = orbCol * (core * ORB_CORE_BRIGHT + glow * ORB_GLOW_BRIGHT);
    
    if(t < 0.0) result *= 0.3;
    
    float orbDist = length(orbCenter - ro);
    if(orbDist > hitT) result *= 0.2;
    
    return result;
}

// ===== SCENE LIGHTING =====
float softShadow(vec3 ro, vec3 rd, float k){
    float res = 1.0, t = 0.02;
    for(int i=0; i<32; i++){
        float h = sceneDist(ro + rd*t);
        if(h < 0.001) return 0.0;
        res = min(res, k*h/t);
        t += clamp(h, 0.02, 0.3);
        if(t > 20.) break;
    }
    return clamp(res, 0., 1.);
}

vec3 shadeWalls(vec3 p, vec3 rd, vec3 orbPos){
    vec3 n = sceneNormal(p);

    vec3 ld1 = normalize(vec3(-0.5, 1.0, -0.3));
    vec3 ld2 = normalize(vec3(0.7, 0.3, 0.6));

    float diff1 = max(dot(n, ld1), 0.0);
    float diff2 = max(dot(n, ld2), 0.0);

    vec3 r = reflect(-ld1, n);
    float spec = pow(max(dot(r, -rd), 0.0), 20.0);

    vec3 base = 0.5 + 0.5 * cos(vec3(0.0, 2.0, 4.0) + p * 1.2 + iTime * 0.2);

    float sh1 = softShadow(p + n*0.01, ld1, 6.0);
    float sh2 = softShadow(p + n*0.01, ld2, 6.0);

    vec3 col = base * (0.25 + 0.85*diff1*sh1 + 0.5*diff2*sh2);
    col += 0.35 * spec * sh1;

    vec3 toOrb = orbPos - p;
    float orbDist = length(toOrb);
    vec3 orbDir = toOrb / orbDist;
    float orbDiff = max(dot(n, orbDir), 0.0);

    vec3 orbLightCol = vec3(1.0, 0.5, 0.8) * (0.5 + getBass()) +
                       vec3(0.3, 0.7, 1.0) * (0.4 + getMid() * 0.4);

    float orbLight = orbDiff / (1.0 + orbDist * orbDist * 0.2);
    col += orbLightCol * orbLight * 0.8;

    float ao = 0.7 + 0.3 * clamp(sceneDist(p + n*0.15) / 0.15, 0.0, 1.0);
    col *= ao;

    return col;
}

// ===== MAIN =====
void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;

    float bass = getBass();
    float mid = getMid();
    float audio = (bass + mid) * 0.5;

    vec3 camPos, camDir, orbPos;
    getCameraState(iTime, camPos, camDir, orbPos);

    vec3 up = vec3(0, 1, 0);
    vec3 right = normalize(cross(camDir, up));
    up = normalize(cross(right, camDir));

    float fov = 80.0 * 3.14159 / 180.0;
    vec3 rd = normalize(camDir + uv.x * right * tan(fov*0.5) + uv.y * up * tan(fov*0.5));

    float t = 0.0;
    vec3 col = vec3(0.0);
    float hitT = 100.0;

    for(int i = 0; i < 120; i++){
        vec3 p = camPos + rd * t;
        float d = sceneDist(p);
        if(d < 0.001){
            col = shadeWalls(p, rd, orbPos);
            float fog = 1.0 - exp(-0.012 * t);
            col = mix(col, vec3(0.08, 0.1, 0.15), fog * 0.2);
            hitT = t;
            break;
        }
        t += d * 0.9;
        if(t > 50.) break;
    }

    if(hitT > 50.0) {
        col = vec3(0.04, 0.06, 0.1);
    }

    vec3 orbGlow = renderOrb(camPos, rd, orbPos, hitT);
    col += orbGlow;

    col *= 1.0 - 0.1 * dot(uv, uv);
    col *= 1.0 + audio * 0.15;
    col = pow(col, vec3(0.8));

    fragColor = vec4(col, 1.0);
}
