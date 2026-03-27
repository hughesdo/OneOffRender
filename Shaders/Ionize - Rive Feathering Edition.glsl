#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;
uniform vec4 iMouse;

out vec4 fragColor;

/*
    "Ionize" - Rive Feathering Edition (Rotated)
    Original by @XorDev
    Modified: Distance-based Vector Feathering + 3D Rotation
    Added: Structured particles + vibrant background layer
*/
// --- RIVE FEATHERING CONFIGURATION ---
#define FEATHER_MAX 0.65
#define INTENSITY 3.5
#define DEPTH_START 6.0
#define DEPTH_END 15.0

// --- ROTATION CONFIGURATION ---
#define ROTATION_SPEED_X 0.3
#define ROTATION_SPEED_Y 0.7

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

float erf(float x) {
    float a1 =  0.254829592;
    float a2 = -0.284496736;
    float a3 =  1.421413741;
    float a4 = -1.453152027;
    float a5 =  1.061405429;
    float p  =  0.3275911;
    float sign = sign(x);
    x = abs(x);
    float t = 1.0 / (1.0 + p * x);
    float y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-x * x);
    return sign * y;
}

float getFeatheredDensity(float d, float r) {
    if (r < 0.000000001) {
        return 1.0 / (d + 0.0000000001);
    }
    float t = d / (r * 1.41421);
    return 0.5 * (1.0 - erf(t));
}

// Hash for procedural variation
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

// Structured background
vec3 getBackground(vec2 uv, float time) {
    vec2 p = uv * 2.5;
    p *= rot(time * 0.08);
    
    // Layered plasma waves
    float wave1 = sin(p.x * 3.0 + time * 0.7) * sin(p.y * 2.0 - time * 0.5);
    float wave2 = sin(length(p) * 4.0 - time * 1.2);
    float spiral = sin(atan(p.y, p.x) * 3.0 + length(p) * 2.0 - time * 0.8);
    
    vec3 col1 = vec3(0.2, 0.1, 0.5);  // Deep purple
    vec3 col2 = vec3(0.1, 0.4, 0.7);  // Blue
    vec3 col3 = vec3(0.6, 0.2, 0.4);  // Magenta
    
    vec3 bg = col1 * wave1 + col2 * wave2 + col3 * spiral;
    bg = bg * 0.4 + 0.3;
    
    return bg;
}

void main()
{
    vec2 I = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec4 O;
    float t = iTime;
    float i = 0.;
    float z = 0.;
    float d = 0.;
    float s = 0.;
    
    O *= 0.;
    
    // --- REVERSED ANIMATION (positive instead of negative) ---
    t = t * 0.67;
    
    // --- NORMALIZED SCREEN COORDS FOR CENTER EFFECT ---
    vec2 uv = (I - iResolution.xy * 0.5) / iResolution.y;
    float centerDist = dot(uv, uv);
    
    // --- ADD BACKGROUND LAYER ---
    vec3 background = getBackground(uv, iTime);
    float bgStrength = smoothstep(0.25, 0.0, centerDist) * 0.7;
    O.rgb = background * bgStrength;
    
    // --- AUTOMATIC GENTLE ROTATION ---
    float rotX = -t * ROTATION_SPEED_X;
    float rotY = -t * ROTATION_SPEED_Y;
    
    float complexity = 0.2;
    float detail = 2.4;
    
    for (i=0.; i++ < 1e2; )
    {
        vec3 p = z * normalize(vec3(I+I, 0) - iResolution.xyy);
        
        p.z += 4.1;
        
        p.xy *= rot(rotY);
        p.xz *= rot(rotX);
        
        vec3 v = p;
        float speed = 1.70001;
        
        for (d = 6.0; d < 7.0; d += d)
        {
            p += z * detail * complexity * sin(p.yzx * d - t * speed) / d;
        }
        
        float boundary = 3.5 - length(v);
        float glowup = 0.07;
        float rawDist = 0.17 * (glowup + abs(s = dot(cos(p), sin(p / 0.5).yzx))
                        - min(boundary, -boundary * 0.20));
        
        z += rawDist;
        d = rawDist;
        
        // --- DYNAMIC FEATHERING LOGIC ---
        float depthFactor = smoothstep(DEPTH_START, DEPTH_END, z);
        float currentFeather = mix(0.0, FEATHER_MAX, depthFactor);
        
        // --- CENTER FADE (no snow, just opacity) ---
        float centerFade = smoothstep(0.0, 0.25, centerDist);
        
        // --- PARTICLE INTERNAL STRUCTURE ---
        // Create concentric rings within each particle
        float particleRadius = length(p - floor(p + 0.5));
        float rings = sin(particleRadius * 15.0 - iTime * 3.0) * 0.5 + 0.5;
        
        // Rotating energy pattern
        vec3 rotatedP = p;
        rotatedP.xy *= rot(iTime * 0.5 + z * 0.2);
        float pattern = sin(rotatedP.x * 8.0) * sin(rotatedP.y * 8.0) * 0.5 + 0.5;
        
        // Combine structures
        float structure = mix(rings, pattern, 0.5);
        
        // --- ENHANCED COLOR ---
        vec4 col = (cos(s / 0.5 + z - t * 0.51 + vec4(2, 4, 5, 0)) + 1.2);
        
        // Modulate color with internal structure
        col.rgb *= (0.7 + structure * 0.6);
        
        // Add chromatic variation based on depth
        col.r += sin(z * 0.5 + s) * 0.2;
        col.b += cos(z * 0.5 - s) * 0.2;
        col.g += sin(z * 0.3 + s * 2.0) * 0.15;
        
        // Boost saturation
        float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
        col.rgb = mix(vec3(lum), col.rgb, 1.4);
        
        float density = getFeatheredDensity(d, currentFeather);
        float depthAtten = 1.0 / (z + 1.0);
        
        // Modulate density with structure for more defined particles
        density *= (0.6 + structure * 0.8);
        
        O += col * density * depthAtten * INTENSITY * mix(0.4, 1.0, centerFade);
    }
    
    O = tanh(O / 1000.0);
    fragColor = O;
}