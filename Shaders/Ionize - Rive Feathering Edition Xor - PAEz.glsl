#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;
uniform vec4 iMouse;

out vec4 fragColor;

/*


    "Ionize" - Rive Feathering Edition (Rotated)
    Original by @XorDev
    Modified: Distance-based Vector Feathering + 3D Rotation + Bass Reactive
    
    SETUP: Set iChannel0 to "Soundcloud" or any audio input
*/

// ============ TWEAK THESE ============
#define INTENSITY      3.5      // Overall brightness (0.5 - 8.0)
#define SPEED          1.0      // Animation speed (0.1 - 3.0)
#define COMPLEXITY     0.2      // Pattern detail (0.05 - 0.5)
#define GLOW           1.07     // Surface emission (0.5 - 2.0)
#define FEATHER_MAX    0.65     // Edge softness (0.0 - 1.5)
#define BASS_GAIN      0.07      // Bass reactivity (0.0 - 3.0)
#define BASS_SMOOTH    0.7      // Bass smoothing (0.5 - 0.95)
// =====================================

#define DEPTH_START 6.0
#define DEPTH_END 15.0

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
    float sign_x = sign(x);
    x = abs(x);
    float t = 1.0 / (1.0 + p * x);
    float y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-x * x);
    return sign_x * y;
}

float getFeatheredDensity(float d, float r) {
    if (r < 0.000000001) {
        return 1.0 / (d + 0.0000000001);
    }
    float t = d / (r * 1.41421);
    return 0.5 * (1.0 - erf(t));
}

// Extract bass from iChannel0 audio texture
float getBass() {
    float bass = 0.0;
    // Sample low frequencies (bass range ~0-400Hz)
    bass += texture(iChannel0, vec2(0.01, 0.0)).x;
    bass += texture(iChannel0, vec2(0.02, 0.0)).x;
    bass += texture(iChannel0, vec2(0.03, 0.0)).x;
    bass += texture(iChannel0, vec2(0.05, 0.0)).x;
    bass += texture(iChannel0, vec2(0.08, 0.0)).x;
    bass += texture(iChannel0, vec2(0.10, 0.0)).x;
    return clamp(bass / 6.0 * BASS_GAIN, 0.0, 1.0);
}

void main()
{
    vec2 I = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec4 O;
    // Get bass level from audio
    float bass = getBass();

    float t = iTime;
    float i = 0.0;
    float z = 5.0;
    float d = 0.0;
    float s = 0.0;
    
    O *= 0.;
    
    // Bass-reactive speed boost
    float bassBoost = 1.0 + bass * 2.0;
    t = t * 2.33 * SPEED * bassBoost;
    
    vec2 uv = (I - iResolution.xy * 0.5) / iResolution.y;
    float centerDist = dot(uv, uv);
    
    // Mouse rotation control
    vec2 m = iMouse.xy / iResolution.xy;
    float rotX = (iMouse.z > 0.0) ? m.x * 6.28 : t * 0.03;
    float rotY = (iMouse.z > 0.0) ? m.y * 3.14 : t * 0.07;
    float complexity = COMPLEXITY;
    float detail = -0.6;
    
    // Bass-reactive intensity
    float bassIntensity = INTENSITY * (1.0 + bass * 3.0);
    
    for (i=0.; i++ < 50.0; )
    {
        vec3 p = z * normalize(vec3(I+I, 0) - iResolution.xyy);
        
        p.z += 1.1;
        
        p.xy *= rot(rotY);
        p.xz *= rot(rotX);
        
        vec3 v = p;
        float speed = 1.70001;
        
        for (d = 3.0; d < 20.0; d += d)
        {
            p += z * detail * complexity * sin(p.yzx * d + t * speed) / d;
        }
        
        // Bass-reactive center wave
        float centerWave = cos(t * 2.0 - centerDist * 5.0) * 0.15 * (1.0 + bass * 2.0);
        
        float boundary = 3.5 - length(v);
        float glowup = GLOW + bass * 0.5;
        float rawDist = 0.07 * (glowup + abs(s = dot(cos(p), sin(p / 0.5).yzx))
                        - min(boundary, -boundary * 0.10))
                        + centerWave;
        
        z += rawDist;
        d = rawDist;
        
        float depthFactor = smoothstep(DEPTH_START, DEPTH_END, z);
        float currentFeather = mix(0.0, FEATHER_MAX, depthFactor);
        
        float centerFade = smoothstep(0.0, 0.3, centerDist);
        
        // Bass-reactive color shift
        vec4 col = (cos(s / 0.5 + z + t * 0.51 + bass * 2.0 + vec4(2, 4, 5, 0)) + 1.2);
        
        float density = getFeatheredDensity(d, currentFeather);
        float depthAtten = 1.0 / (z + 1.0);
        
        O += col * density * depthAtten * bassIntensity * mix(0.3, 1.0, centerFade);
    }
    
    O = tanh(O / 1000.0);

    // Bass flash overlay
    O += vec4(1.0, 0.9, 0.8, 0.0) * bass * 0.15;
    fragColor = O;
}