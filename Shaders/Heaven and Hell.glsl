#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Buffer A (beat detection)
uniform sampler2D iChannel1;  // Buffer B (sky/bloom)

out vec4 fragColor;

/*
================================================================================
    CRYSTAL NEBULA SPHERE - Reflection Opacity + Brightness
================================================================================
*/
#define PI 3.14159265359
#define SPHERE_ROTATION_SPEED 0.12
#define CAMERA_ORBIT_SPEED 0.05
#define BLOOM_BASE_INTENSITY 0.35
// Glow Settings (Start=Max, End=Zero)
#define GLOW_START_DIST 0.0 // Inner radius (max intensity)
#define GLOW_END_DIST 1.0 // Outer radius (zero intensity)
#define GLOW_FALLOFF 6.0 // Fade curve (1.0=linear, 0.5=fast, 3.0=slow)
#define GLOW_INTENSITY 1.5 // Brightness
#define GLOW_COLOR vec3(1.0, 0.4, 0.4)
// Reflection Controls
#define REFLECTION_OPACITY 0.5 // Transparency (0.0 = see floor, 1.0 = full reflection)
#define REFLECTION_BRIGHTNESS 0.5 // Intensity (0.0 = black, 1.0 = normal, 2.0 = bright)
#define REFLECT_GLOW 1 // 1 = enable glow in reflection
// Pre-calculated IOR constants
const float IOR = 1.0 / 1.45;
const float IOR_R = (1.0 / 1.45) * 0.98;
const float IOR_G = (1.0 / 1.45) * 1.00;
const float IOR_B = (1.0 / 1.45) * 1.02;
// Add these new defines near the top, right after your existing glow defines
#define SPHERE_RADIUS          1.2     // <-- change this value to resize everything correctly

// Relative fractions (computed from original hardcoded values at radius 1.2)
#define GLOW_START_REL         0.0
#define GLOW_END_REL           0.83
#define INTERIOR_MAX_REL       0.70
#define CRACK_GLOW_MIN_REL      0.583
#define CRACK_GLOW_MAX_REL     0.9383
#define NEBULA_FALLOFF_IN      0.8166
#define NEBULA_FALLOFF_OUT     0.16
// ============================================================================
// ROTATION MATRICES
// ============================================================================
mat3 rotate_x(float a) {
    float sa = sin(a), ca = cos(a);
    return mat3(1., 0., 0., 0., ca, sa, 0., -sa, ca);
}
mat3 rotate_y(float a) {
    float sa = sin(a), ca = cos(a);
    return mat3(ca, 0., sa, 0., 1., 0., -sa, 0., ca);
}
mat3 rotate_z(float a) {
    float sa = sin(a), ca = cos(a);
    return mat3(ca, sa, 0., -sa, ca, 0., 0., 0., 1.);
}
// ============================================================================
// NOISE FUNCTIONS
// ============================================================================
float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
vec3 hash33(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}
float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f*f*(3.0-2.0*f);
    return mix(mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
                   mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
                   mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
float fbm(vec3 p) {
    float f = 0.0, a = 0.5;
    for(int i = 0; i < 4; i++) {
        f += a * noise(p);
        p *= 2.0; a *= 0.5;
    }
    return f;
}
// ============================================================================
// 3D VORONOI
// ============================================================================
vec3 voronoi3D(vec3 p) {
    vec3 n = floor(p), f = fract(p);
    float minDist = 10.0, minDist2 = 10.0;
   
    for(int k = -1; k <= 1; k++)
    for(int j = -1; j <= 1; j++)
    for(int i = -1; i <= 1; i++) {
        vec3 g = vec3(float(i), float(j), float(k));
        vec3 o = hash33(n + g) * 0.5 + 0.5;
        vec3 r = g + o - f;
        float d = dot(r, r);
        if(d < minDist) { minDist2 = minDist; minDist = d; }
        else if(d < minDist2) { minDist2 = d; }
    }
    return vec3(sqrt(minDist), sqrt(minDist2), sqrt(minDist2) - sqrt(minDist));
}
// ============================================================================
// SPACE-SPECIFIC FUNCTIONS
// ============================================================================
float getCrackPattern(vec3 p) {
    return voronoi3D(p * 3.5).z;
}
vec3 getCrackOffset(vec3 p, float crack) {
    return (crack < 0.12) ? hash33(p * 10.0) * smoothstep(0.12, 0.0, crack) * 0.15 : vec3(0.0);
}
vec3 getNebulaColor(vec3 p, float time) {
    vec3 q = p + vec3(time * 1.02, sin(time * 0.05) * 0.1, cos(time * 0.03) * 0.1);
    float n1 = fbm(q * 1.8);
    float n2 = fbm(q * 2.8 + 100.0);
    float n3 = fbm(q * 1.4 - 50.0);
    vec3 deepBlue = vec3(0.05, 0.25, 0.5)*8.5;
    vec3 purple = vec3(0.5, 0.15, 0.6)*8.5;
    vec3 pink = vec3(0.85, 0.35, 0.35)*3.5;
    vec3 cyan = vec3(0.15, 0.7, 0.9)*8.5;
    vec3 cream = vec3(0.98, 0.9, 0.8)*8.5;
    vec3 nebula = pink;
    nebula = mix(nebula, purple, smoothstep(0.1, 0.9, n1*1.3));
    //nebula = mix(nebula, pink, smoothstep(0.4, 0.6, n2) * 0.6);
    nebula = mix(nebula, cyan, smoothstep(0.35, 0.55, n3) * 0.6)*0.5;
    nebula = mix(nebula, cream, smoothstep(0.5, 0.7, n1 * n2) * 0.95);
    float density = smoothstep(0.2, 0.75, n1 * 0.5 + n2 * 0.35 + 0.25);
    float sparkle = pow(noise(q * 10.0 + time), 1.0);
    //nebula += vec3(1.0) * sparkle * 0.5;
    return pow(nebula * density,vec3(2.0))*0.6;
}
// ============================================================================
// ENVIRONMENT SAMPLING
// ============================================================================
vec3 sampleEnv(vec3 dir) {
    // Procedural environment (no cubemap needed)
    vec3 col = vec3(0.02, 0.03, 0.05);
    col += vec3(0.9, 0.95, 1.0) * pow(max(dot(dir, normalize(vec3(1, 1, 0.5))), 0.0), 32.0) * 1.5;
    col += vec3(0.4, 0.5, 0.7) * pow(max(dot(dir, normalize(vec3(-1, 0.5, 0.3))), 0.0), 16.0) * 0.3;
    return col;
}
// ============================================================================
// CORE RENDERING UTILITIES
// ============================================================================
vec2 raySphere(vec3 ro, vec3 rd, float r) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - r * r;
    float h = b * b - c;
    if(h < 0.0) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b - h, -b + h);
}
vec3 marchInterior(vec3 pos1, vec3 pos2, float time, int steps) {
    vec3 interior = vec3(0.0);
   
    for(int i = 0; i < steps; i++) {
        float t = float(i) / float(steps);
        vec3 p = mix(pos1, pos2, t);
        float dist = length(p);
       
        if(dist < SPHERE_RADIUS * INTERIOR_MAX_REL) {
            vec3 nebSample = getNebulaColor(p, time);
            float falloff = smoothstep(SPHERE_RADIUS * NEBULA_FALLOFF_IN, SPHERE_RADIUS * NEBULA_FALLOFF_OUT, dist);
            interior += nebSample * falloff * (7.8 / float(float(steps)*0.9));
        }
       
        if(dist < SPHERE_RADIUS * CRACK_GLOW_MAX_REL && dist > SPHERE_RADIUS * CRACK_GLOW_MIN_REL) {
            vec3 v = voronoi3D(p * 2.8);
            if(v.z < 0.28) {
                float edgeGlow = smoothstep(0.08, 0.00, v.z);
                float hue = fract(dot(v, vec3(0.3, 0.5, 0.7)) + time * 0.1);
                vec3 rainbow = 0.5 + 0.5 * cos(2.0 * PI * (hue + vec3(0.0, 0.33, 0.67)));
                interior += rainbow * edgeGlow * 0.05;
            }
        }
    }
    return interior;
}
// Calculate volumetric glow
float calculateGlow(vec3 ro_obj, vec3 rd_obj) {
    float b = dot(ro_obj, rd_obj);
    float closestDist2 = dot(ro_obj, ro_obj) - b * b;
    float closestDist = sqrt(max(0.0, closestDist2));
    
    float surface = SPHERE_RADIUS;
    float distFromSurface = abs(closestDist - surface);
    
    float startD = GLOW_START_REL * surface;
    float endD   = GLOW_END_REL   * surface;
    
    if (distFromSurface <= startD) {
        return 1.0;
    } else if (distFromSurface >= endD) {
        return 0.0;
    } else {
        float t = (distFromSurface - startD) / (endD - startD);
        return pow(1.0 - t, GLOW_FALLOFF);
    }
}
vec3 renderSphere(vec3 ro_obj, vec3 rd_obj, float time,
                  mat3 rotM, bool isReflection, int marchSteps, float specPower) {
    vec3 color = vec3(0.0);
    vec2 t = raySphere(ro_obj, rd_obj, SPHERE_RADIUS);
   
    if(t.x <= 0.0) return color;
   
    vec3 pos1_obj = ro_obj + rd_obj * t.x;
    vec3 n1_obj = normalize(pos1_obj);
   
    float crack = getCrackPattern(pos1_obj);
    vec3 crackOff = getCrackOffset(pos1_obj, crack);
    n1_obj = normalize(n1_obj + crackOff);
   
    float fresnel1 = max(0.0, dot(-rd_obj, n1_obj));
   
    vec3 refr1_obj = refract(rd_obj, n1_obj, IOR);
    vec3 refl1_obj = reflect(rd_obj, n1_obj);
   
    vec2 tInner = raySphere(pos1_obj + refr1_obj * 0.001, refr1_obj, SPHERE_RADIUS);
    vec3 pos2_obj = pos1_obj + refr1_obj * tInner.y;
    vec3 n2_obj = normalize(pos2_obj);
   
    float fresnel2 = max(0.0, dot(-refr1_obj, -n2_obj));
    vec3 refl2_obj = reflect(refr1_obj, -n2_obj);
   
    vec3 interior = marchInterior(pos1_obj, pos2_obj, time, marchSteps);
   
    vec3 refl1_world = normalize(rotM * refl1_obj);
    vec3 refl2_world = normalize(rotM * refl2_obj);
   
    vec3 refrR_world = normalize(rotM * refract(refr1_obj, -n2_obj, IOR_R));
    vec3 refrG_world = normalize(rotM * refract(refr1_obj, -n2_obj, IOR_G));
    vec3 refrB_world = normalize(rotM * refract(refr1_obj, -n2_obj, IOR_B));
   
    vec3 envExit = vec3(sampleEnv(refrR_world).r,
                        sampleEnv(refrG_world).g,
                        sampleEnv(refrB_world).b);
   
    if(dot(refrR_world, refrR_world) == 0.0) envExit = sampleEnv(refl2_world);
   
    vec3 glassInt = mix(sampleEnv(refl2_world), envExit * 0.3 + interior, pow(fresnel2, 0.3));
    vec3 reflEnv = sampleEnv(refl1_world);
    color = mix(reflEnv, glassInt, sqrt(fresnel1)*1.0);

    if(crack < 0.72) {
        float intensity = smoothstep(0.12, 0.0, crack);
        float hue = fract(pos1_obj.x*0.5 + pos1_obj.y*0.3 + pos1_obj.z*0.4 + time*0.1);
        vec3 rainbow = 0.0 + 0.4*cos(2.0*PI*(hue + vec3(0.0, 0.33, 0.67)));
        color += mix(rainbow, vec3(1.0), smoothstep(0.04, 0.0, crack)) * intensity * 0.7;
    }
   
    vec3 light_obj = transpose(rotM) * normalize(vec3(1.0, 1.5, 1.0));
    vec3 h = normalize(light_obj - rd_obj);
    color += vec3(0.95, 0.97, 1.0) * pow(max(dot(n1_obj, h), 0.0), specPower) * (isReflection ? 1.2 : 2.5);
    color += vec3(0.95, 0.97, 1.0) * pow(max(dot(n1_obj, h), 0.0), 32.0) * 0.2;
   
    color += vec3(0.1, 0.15, 0.25) * pow(1.0-fresnel1, 3.0) * 0.5;
    color += vec3(0.01, 0.012, 0.015);
   
    return color;
}
// ============================================================================
// MAIN IMAGE
// ============================================================================
void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float time = iTime;
    float glassRot = time * SPHERE_ROTATION_SPEED;
    mat3 rotM = rotate_y(glassRot) * rotate_x(glassRot * 0.3) * rotate_z(glassRot * 0.15);
    mat3 rotM_inv = rotate_z(-glassRot * 0.15) * rotate_x(-glassRot * 0.3) * rotate_y(-glassRot);
   
    float camDist = 3.5;
    float camAngle = time * CAMERA_ORBIT_SPEED;
    float camHeight = 0.2 + sin(time * 0.07) * 0.15;
    vec3 ro = vec3(sin(camAngle) * camDist, camHeight, cos(camAngle) * camDist);
    vec3 lookAt = vec3(0.0, -0.05, 0.0);
   
    vec3 fwd = normalize(lookAt - ro);
    vec3 rgt = normalize(cross(vec3(0, 1, 0), fwd));
    vec3 up = cross(fwd, rgt);
    vec3 rd_world = normalize(fwd + uv.x * rgt + uv.y * up);
   
    vec3 ro_obj = rotM_inv * ro;
    vec3 rd_obj = rotM_inv * rd_world;
   
    // Calculate primary ray glow
    float primaryGlow = calculateGlow(ro_obj, rd_obj);
   
    vec3 col = renderSphere(ro_obj, rd_obj, time, rotM, false, 24, 256.0);
    bool hitSphere = (col != vec3(0.0));
   
    if(col == vec3(0.0)) {
       
        // Floor reflection
        float groundY = -1.4;
        if(rd_world.y < 0.0) {
            float t = (groundY - ro.y) / rd_world.y;
            if(t > 0.0) {
                vec3 gp = ro + rd_world * t;
                vec3 reflRd = reflect(rd_world, vec3(0, 1, 0));
               
                vec3 r_ro_obj = rotM_inv * gp;
                vec3 r_rd_obj = rotM_inv * reflRd;
               
                // Calculate reflection glow
                float reflGlow = calculateGlow(r_ro_obj, r_rd_obj);
               
                vec2 tRefl = raySphere(r_ro_obj, r_rd_obj, SPHERE_RADIUS);
               
                // Floor base color without reflection
                vec3 floorColor = vec3(0.003);
                vec3 finalFloor = floorColor;
               
                if(tRefl.x > 0.0 && length(gp.xz) < 4.0) {
                    vec3 reflSphere = renderSphere(r_ro_obj, r_rd_obj, time, rotM, true, 12, 128.0);
                   
                    // Apply brightness to reflection
                    reflSphere *= REFLECTION_BRIGHTNESS;
                   
                    float reflFalloff = exp(-length(gp.xz) * 0.25) * smoothstep(4.0, 1.0, length(gp.xz));
                   
                    // Blend with floor based on opacity (transparency)
                    finalFloor = mix(floorColor, reflSphere, REFLECTION_OPACITY * reflFalloff);
                }
               
                // Add reflection glow (always additive on top)
                #if REFLECT_GLOW
                float reflFalloff = exp(-length(gp.xz) * 0.25) * smoothstep(4.0, 1.0, length(gp.xz));
                finalFloor += GLOW_COLOR * reflGlow * GLOW_INTENSITY * reflFalloff;
                #endif
               
                col = finalFloor;
               
                col += vec3(0.008, 0.01, 0.012) * exp(-length(gp.xz) * 0.3);
                col *= exp(-length(gp.xz) * 0.08);
            }
        }
    }
   
    // Add primary glow
    col += GLOW_COLOR * primaryGlow * GLOW_INTENSITY;
   
    // Bloom from Buffer B (sky/ground extraction)
    vec3 bloom = texture(iChannel1, fragCoord / iResolution.xy).rgb;
    col += bloom * BLOOM_BASE_INTENSITY;
    col += (hash(vec3(fragCoord, time * 60.0)) - 0.5) * 0.015;
 
    col = col * (2.51 * col + 0.03) / (col * (2.43 * col + 0.59) + 0.14);
    col = pow(clamp(col, 0.0, 1.0), vec3(0.5));
   
    vec2 q = fragCoord / iResolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), 0.2);
   
    fragColor = vec4(col, 1.0);
}