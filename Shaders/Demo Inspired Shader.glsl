// Audio-Reactive Demo Inspired Shader
// Combines fractal noise, mandala overlays, and dynamic lighting
// Add audio to iChannel0

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;


#define PI 3.14159265359
#define TAU 6.28318530718
#define fs(i) (fract(sin((i)*114.514)*1919.810))

// Rotation matrix
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

// 3D Rotation
mat3 rotX(float a) {
    float c = cos(a), s = sin(a);
    return mat3(1,0,0, 0,c,-s, 0,s,c);
}

mat3 rotY(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c,0,s, 0,1,0, -s,0,c);
}

// Noise function
float hash(vec3 p) {
    p = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p += dot(p, p.yzx + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    return mix(
        mix(mix(hash(i), hash(i + vec3(1,0,0)), f.x),
            mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
        mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
            mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y),
        f.z);
}

// FBM Noise from original
vec3 fbm3d(vec3 p) {
    vec3 n = vec3(0.0);
    float amp = 0.5;
    float freq = 1.0;
    
    for(int i = 0; i < 6; i++) {
        p = rotY(0.5) * rotX(0.3) * p * 1.7;
        p += sin(p.zxy * freq);
        n += sin(cross(cos(p), sin(p.yzx))) * amp;
        amp *= 0.5;
        freq *= 1.3;
    }
    return n;
}

// Mandala SDF (from shader 18)
float mandala(vec2 p, float rotation, float segments, float innerCut, float outerRad, float innerRad, float thickness) {
    p = rot(rotation) * p;
    float angle = atan(p.y, p.x);
    float segAngle = TAU / segments;
    p = rot(-floor((angle + segAngle/2.0) / segAngle) * segAngle) * p;
    angle = atan(p.y, p.x);
    p = rot(-sign(angle) * min(abs(angle), innerCut)) * p;
    p.x -= outerRad;
    p.x -= sign(p.x) * min(abs(p.x), innerRad);
    return length(p) - thickness;
}

// Multiple rotating mandalas
float mandalas(vec2 p, float time) {
    float d = 1e9;
    float t = time;
    
    d = min(d, mandala(p, t*0.1, 4.0, PI/8.0, 0.7, 0.0, 0.02));
    d = min(d, mandala(p, t*0.1 + PI/4.0, 4.0, PI/8.0, 0.72, 0.0, 0.02));
    d = min(d, mandala(p, t*0.1, 8.0, PI/19.0, 0.76, 0.002, 0.0));
    d = min(d, mandala(p, -t*0.1, 8.0, PI/9.0, 0.79, 0.01, 0.0));
    d = min(d, mandala(p, t*0.04, 48.0, 0.002, 0.82, 0.008, 0.0));
    d = min(d, mandala(p, t*0.2, 4.0, PI/4.2, 0.925, 0.002, 0.0));
    d = min(d, mandala(p, -t*0.1, 8.0, PI/8.5, 0.95, 0.007, 0.0));
    
    return d;
}

// Main SDF scene
float scene(vec3 p, float audioLow, float audioMid, float audioHigh) {
    // Distort space with noise and audio
    vec3 noiseP = p * 0.5 + iTime * 0.2;
    vec3 distort = fbm3d(noiseP) * (0.3 + audioMid * 0.4);
    p += distort;
    
    // Rotating sphere with audio-reactive size
    float d = length(p) - (1.5 + audioLow * 0.5);
    
    // Add bumps
    float bumps = sin(p.x * 15.0 + audioHigh * 10.0) * sin(p.y * 15.0) * sin(p.z * 15.0) * 0.05;
    d += bumps;
    
    // Ground plane
    float ground = p.y + 2.0;
    
    return min(d, ground);
}

vec3 getNormal(vec3 p, float audioLow, float audioMid, float audioHigh) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        scene(p + e.xyy, audioLow, audioMid, audioHigh) - scene(p - e.xyy, audioLow, audioMid, audioHigh),
        scene(p + e.yxy, audioLow, audioMid, audioHigh) - scene(p - e.yxy, audioLow, audioMid, audioHigh),
        scene(p + e.yyx, audioLow, audioMid, audioHigh) - scene(p - e.yyx, audioLow, audioMid, audioHigh)
    ));
}

// Audio sampling
vec4 getAudio() {
    float low = texture(iChannel0, vec2(0.05, 0.0)).x;
    float mid = texture(iChannel0, vec2(0.15, 0.0)).x;
    float high = texture(iChannel0, vec2(0.35, 0.0)).x;
    float bass = texture(iChannel0, vec2(0.01, 0.0)).x;
    return vec4(low, mid, high, bass) * 2.0;
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    
    // Get audio
    vec4 audio = getAudio();
    float audioLow = audio.x;
    float audioMid = audio.y;
    float audioHigh = audio.z;
    float audioBass = audio.w;
    
    // Camera
    float camAngle = iTime * 0.3 + audioLow * 0.3;
    float camDist = 4.0 + sin(iTime * 0.5) * 0.5;
    vec3 ro = vec3(
        sin(camAngle) * camDist,
        1.0 + audioMid * 0.5,
        cos(camAngle) * camDist
    );
    
    vec3 target = vec3(0, 0, 0);
    vec3 forward = normalize(target - ro);
    vec3 right = normalize(cross(vec3(0,1,0), forward));
    vec3 up = cross(forward, right);
    vec3 rd = normalize(forward + uv.x * right + uv.y * up);
    
    // Raymarching
    float t = 0.0;
    vec3 p = ro;
    int steps = 0;
    
    for(int i = 0; i < 80; i++) {
        steps = i;
        p = ro + rd * t;
        float d = scene(p, audioLow, audioMid, audioHigh);
        if(d < 0.001) break;
        if(t > 20.0) break;
        t += d * 0.7;
    }
    
    vec3 col = vec3(0.0);
    
    if(t < 20.0) {
        // Hit
        vec3 normal = getNormal(p, audioLow, audioMid, audioHigh);
        
        // Lighting
        vec3 light1 = normalize(vec3(sin(iTime), 0.7, cos(iTime)));
        vec3 light2 = normalize(vec3(-sin(iTime * 0.7), 0.5, -cos(iTime * 0.7)));
        
        float diff1 = max(dot(normal, light1), 0.0);
        float diff2 = max(dot(normal, light2), 0.0) * 0.5;
        
        vec3 viewDir = -rd;
        vec3 h1 = normalize(light1 + viewDir);
        float spec1 = pow(max(dot(normal, h1), 0.0), 40.0);
        
        // Audio-reactive colors
        vec3 baseColor = mix(
            vec3(0.1, 0.5, 1.0),
            vec3(1.0, 0.3, 0.7),
            sin(iTime + audioMid * TAU) * 0.5 + 0.5
        );
        
        // Add noise-based coloring
        float colorNoise = fbm3d(p * 2.0 + iTime * 0.1).x;
        baseColor = mix(baseColor, baseColor.zxy, colorNoise * audioHigh);
        
        // Ambient occlusion
        float ao = 1.0 - float(steps) / 80.0;
        ao = pow(ao, 2.0);
        
        // Fresnel
        float fresnel = pow(1.0 - max(dot(normal, viewDir), 0.0), 3.0);
        
        // Combine
        col = baseColor * (diff1 * 0.7 + diff2 * 0.4 + 0.15);
        col += vec3(1.0) * spec1 * 0.6;
        col += fresnel * vec3(0.2, 0.6, 1.0) * (0.3 + audioHigh * 0.5);
        col *= ao;
        
        // Fog
        float fog = 1.0 - exp(-0.05 * t);
        col = mix(col, vec3(0.05, 0.1, 0.2), fog * 0.5);
    } else {
        // Background
        float bg = length(uv) * 0.5;
        col = mix(vec3(0.02, 0.05, 0.1), vec3(0.1, 0.2, 0.4), bg);
        col += vec3(0.05, 0.15, 0.3) * audioBass * 0.3;
    }
    
    // Mandala overlay
    float mandalaDist = mandalas(uv * 0.65, iTime + audioLow);
    float mandalaEdge = smoothstep(2.0/iResolution.y, 0.0, mandalaDist);
    vec3 mandalaColor = mix(col, vec3(0.5) - 0.3 * col.yzx, mandalaEdge);
    col = mix(col, mandalaColor, 0.6 + audioMid * 0.3);
    
    // Audio-reactive pulse
    float pulse = audioBass * 0.15 * (1.0 - length(uv) * 0.5);
    col += vec3(0.1, 0.3, 0.6) * pulse;
    
    // Vignette
    float vignette = 1.0 - dot(uv * 0.6, uv * 0.6);
    col *= 0.3 + 0.7 * vignette;
    
    // Color grading
    col = pow(col, vec3(0.85));
    col = col * col * (3.0 - 2.0 * col); // S-curve
    
    fragColor = vec4(col, 1.0);
}
