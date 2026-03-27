// Audio Tunnel v7 - TWEAKABLE
// iChannel0 = Audio
// iChannel1 = Texture
// iChannel2 = Environment map (Uffizi Gallery Blurred.png)

#version 330 core

// Uniforms
uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture
uniform sampler2D iChannel1;  // Triplanar wall texture
uniform sampler2D iChannel2;  // 2D environment map (Uffizi Gallery Blurred)

// Output
out vec4 fragColor;
// ============================================
//          RAYMARCH  These are the three most important steps
// ============================================
#define MAX_STEPS        90       // Raymarch iterations
#define MIN_DIST         0.0035   // Minimum step
#define STEP_SCALE       0.15     // Step size multiplier


// ============================================
//          TOGGLE EFFECTS ON/OFF
// ============================================
#define USE_AUDIO        1    // 0 = use fallback animation
#define USE_TEXTURES     1    // Triplanar textures
#define USE_CUBEMAP      1    // Reflection/refraction
#define USE_SPARKLES     0    // All sparkle effects
#define USE_GLOW         1    // Volumetric glow accumulation
#define USE_IRIDESCENCE  1    // Color shift by fresnel
#define USE_CAMERA_SHAKE 1    // Bass shake
#define USE_VIGNETTE     1    // Dark edges
#define USE_CONTRAST     1    // S-curve + black crush

// ============================================
//          MOVEMENT / SPEED
// ============================================
#define SPEED            5.0   // Forward travel speed
#define TIME_SCALE       1.0   // Overall time multiplier

// ============================================
//          TUNNEL SHAPE
// ============================================
#define TUNNEL_RADIUS    1.2   // Base tunnel size
#define TUNNEL_BREATHE   1.5   // How much bass affects radius
#define TUNNEL_WAVE_AMP  0.3   // Z-axis waviness
#define TUNNEL_WAVE_FREQ 0.3   // Z-axis wave frequency
#define RIPPLE_AMP       0.1   // Wall ripple strength
#define RIPPLE_FREQ      2.0   // Wall ripple frequency
#define SPIRAL_AMP       0.05  // Spiral groove depth
#define SPIRAL_FREQ      6.0   // Spiral groove count

// ============================================
//          NOISE
// ============================================
#define NOISE_OCTAVES    32.0  // Max noise iterations (powers of 2)
#define NOISE_SCALE      0.1   // Base noise amount
#define NOISE_AUDIO_MULT 0.3   // How much highs boost noise

// ============================================
//          COLORS
// ============================================
#define COLOR_SPEED      0.05  // Hue cycle speed
#define COLOR_DEPTH_MULT 0.01  // Hue shift by depth
#define SATURATION       1.4   // Color saturation (1.0 = normal)
#define IRIDESCENCE_AMT  0.3   // Fresnel color shift amount

// ============================================
//          GLASSY / PLASTIC
// ============================================
#define FRESNEL_POWER    4.0   // Rim sharpness (higher = sharper)
#define FRESNEL_STRENGTH 0.3   // White rim amount
#define SPEC_POWER       64.0  // Specular sharpness
#define SPEC_STRENGTH    0.6   // Specular brightness
#define SPEC2_POWER      16.0  // Soft spec sharpness
#define SPEC2_STRENGTH   0.2   // Soft spec brightness
#define REFLECTION_AMT   0.5   // Cubemap reflection
#define REFRACTION_AMT   0.15  // Cubemap refraction
#define TEXTURE_AMT      0.2   // Triplanar texture blend

// ============================================
//          SPARKLES
// ============================================
#define SPARKLE1_FREQ    50.0  // Main sparkle frequency
#define SPARKLE1_POWER   8.0   // Main sparkle sharpness
#define SPARKLE1_AMT     2.0   // Main sparkle brightness
#define SPARKLE2_FREQ    80.0  // White sparkle frequency  
#define SPARKLE2_POWER   12.0  // White sparkle sharpness
#define SPARKLE2_AMT     2.0   // White sparkle brightness
#define EDGE_SPARKLE_AMT 0.5   // Edge sparkle brightness

// ============================================
//          GLOW
// ============================================
#define GLOW_FALLOFF     40.0  // Glow distance falloff
#define GLOW_BRIGHTNESS  5000.0 // Glow divisor (higher = dimmer)

// ============================================
//          AUDIO RESPONSE
// ============================================
#define BASS_BRIGHTNESS  0.6   // Brightness pulse on bass
#define BASS_SATURATION  0.5   // Saturation boost on bass
#define MID_COLOR_SHIFT  0.25  // RGB shift on mids
#define HIGH_SPARKLE     3.0   // Sparkle boost on highs
#define BEAT_FLASH       0.2   // White flash on beat

// ============================================
//          CONTRAST / FINAL
// ============================================
#define BLACK_CRUSH      0.04  // Subtract from darks
#define BLACK_SCALE      1.08  // Scale after crush
#define VIGNETTE_AMT     0.4   // Edge darkening
#define GAMMA            0.48  // Final gamma (lower = darker)




// ============================================
//          CODE BELOW - TWEAK ABOVE
// ============================================

const float PI = 3.14159265;

vec3 Spectrum(float x) {
    return (vec3( 1.220023e0,-1.933277e0, 1.623776e0)
          +(vec3(-2.965000e1, 6.806567e1,-3.606269e1)
          +(vec3( 5.451365e2,-7.921759e2, 6.966892e2)
          +(vec3(-4.121053e3, 4.432167e3,-4.463157e3)
          +(vec3( 1.501655e4,-1.264621e4, 1.375260e4)
          +(vec3(-2.904744e4, 1.969591e4,-2.330431e4)
          +(vec3( 3.068214e4,-1.698411e4, 2.229810e4)
          +(vec3(-1.675434e4, 7.594470e3,-1.131826e4)
          + vec3( 3.707437e3,-1.366175e3, 2.372779e3)
            *x)*x)*x)*x)*x)*x)*x)*x)*x;
}

#define N(x,r) abs(dot(sin(t*.1 + p*x), r + p-p)) / x

vec2 scene(vec3 p, float t, vec3 a) {
    float s, n;
    float idx = 0.;
    
    float radius = TUNNEL_RADIUS + a.x * TUNNEL_BREATHE + sin(p.z * TUNNEL_WAVE_FREQ + t) * TUNNEL_WAVE_AMP;
    s = radius - length(p.xy);
    
    s += sin(p.z * RIPPLE_FREQ + t * 2. + a.x * 10.) * RIPPLE_AMP * (1. + a.y);
    s += sin(atan(p.y, p.x) * SPIRAL_FREQ + p.z + t) * SPIRAL_AMP * (1. + a.z * 2.);
    
    for(n = 1.; n < NOISE_OCTAVES; n += n) {
        float noise = N(n, NOISE_SCALE + a.z * NOISE_AUDIO_MULT);
        if(noise > .05) idx = mod(n + p.z * .5, 5.);
        s -= noise * (1. + a.y * .5);
    }
    
    return vec2(s, idx);
}

vec3 norm(vec3 p, float t, vec3 a) {
    vec2 e = vec2(.005, 0);
    return normalize(scene(p, t, a).x - vec3(
        scene(p - e.xyy, t, a).x,
        scene(p - e.yxy, t, a).x,
        scene(p - e.yyx, t, a).x
    ));
}

vec3 triTex(sampler2D tex, vec3 p, vec3 n) {
    vec3 w = abs(n);
    w /= w.x + w.y + w.z + .001;
    return texture(tex, p.yz * .15).rgb * w.x +
           texture(tex, p.xz * .15).rgb * w.y +
           texture(tex, p.xy * .15).rgb * w.z;
}

// Convert a 3D direction vector to 2D equirectangular UV for the
// Uffizi Gallery Blurred environment map (same mapping as SIG15 EntryLevel).
vec2 envMap(vec3 d)
{
    d = normalize(d);
    float phi   = atan(d.z, d.x);
    float theta = asin(clamp(d.y, -1.0, 1.0));
    return vec2(phi / (2.0 * PI) + 0.5,
                theta / PI + 0.5);
}

void mainImage(out vec4 o, vec2 u) {
    float i, d, s, t = iTime * TIME_SCALE;
    vec3 p, n, ro, rd;
    vec2 res = iResolution;
    vec2 hit;
    
    // Audio
    vec3 a = vec3(
        pow(texture(iChannel0, vec2(.02, .25)).x, 1.5),
        pow(texture(iChannel0, vec2(.15, .25)).x, 1.3),
        pow(texture(iChannel0, vec2(.4, .25)).x, 1.2)
    );
    float beat = texture(iChannel0, vec2(.01, .25)).x;
    
    // Fallback
    #if USE_AUDIO == 0
    a = vec3(.4) + .2*sin(t*2. + vec3(0, 2, 4));
    beat = .3 + .2*sin(t*3.);
    #else
    a = mix(vec3(.4) + .2*sin(t*2. + vec3(0, 2, 4)), a, step(.01, length(a)));
    beat = mix(.3 + .2*sin(t*3.), beat, step(.01, beat));
    #endif
    
    // UV
    u = (u - res.xy / 2.) / res.y;
    
    // Camera shake
    #if USE_CAMERA_SHAKE
    u += vec2(sin(t*30.), cos(t*43.)) * beat * .01;
    #endif
    
    // Ray
    ro = vec3(0, 0, t * SPEED);
    rd = normalize(vec3(u, 1.2 - dot(u,u) * .4));
    
    // Raymarch
    vec3 glowAccum = vec3(0);
    
    for(o *= i; i++ < float(MAX_STEPS); d += s = MIN_DIST + STEP_SCALE * abs(s)) {
        p = ro + rd * d;
        hit = scene(p, t, a);
        s = hit.x;
        
        #if USE_GLOW
        vec3 glowCol = Spectrum(fract(hit.y * .2 + d * .02 + t * .1));
        glowAccum += glowCol * (1. + beat * 2.) / (abs(s) * GLOW_FALLOFF + 1.);
        #endif
    }
    
    n = norm(p, t, a);
    
    vec3 ref = reflect(rd, n);
    vec3 refr = refract(rd, n, .85);
    
    // === COLORS ===
    float hue = fract(hit.y * .15 + d * COLOR_DEPTH_MULT + t * COLOR_SPEED + a.x * .5);
    vec3 baseCol = Spectrum(hue);
    vec3 iriCol = Spectrum(fract(hue + IRIDESCENCE_AMT + a.y * .2));
    
    // === GLASSY ===
    float fresnel = pow(1. - abs(dot(n, -rd)), FRESNEL_POWER);
    float fresnel2 = pow(1. - abs(dot(n, -rd)), 2.);
    
    vec3 lightDir = normalize(vec3(1, 1, -1));
    vec3 h = normalize(lightDir - rd);
    float spec = pow(max(dot(n, h), 0.), SPEC_POWER) * (1. + a.z * 2.);
    float spec2 = pow(max(dot(n, h), 0.), SPEC2_POWER);
    
    // === BUILD COLOR ===
    #if USE_IRIDESCENCE
    vec3 col = mix(baseCol, iriCol, fresnel2) * .7;
    #else
    vec3 col = baseCol * .7;
    #endif
    
    #if USE_TEXTURES
    vec3 texCol = triTex(iChannel1, p * (1. + a.y * .5), n);
    col += texCol * TEXTURE_AMT * baseCol;
    #endif
    
    #if USE_CUBEMAP
    // Sample 2D environment map using spherical mapping from direction
    vec3 refCol  = texture(iChannel2, envMap(ref)).rgb;
    vec3 refrCol = texture(iChannel2, envMap(refr)).rgb;
    col = mix(col, refCol, fresnel * REFLECTION_AMT);
    col += refrCol * (1. - fresnel) * REFRACTION_AMT * iriCol;
    #endif
    
    // Plastic highlights
    col = mix(col, vec3(1), fresnel * FRESNEL_STRENGTH);
    col += spec * vec3(1) * SPEC_STRENGTH;
    col += spec2 * baseCol * SPEC2_STRENGTH;
    
    // Glassy tint
    col = mix(col, baseCol * .4, abs(n.y) * .2);
    col = mix(iriCol * .2, col, .3 + abs(n.z) * .7);
    
    // Diffuse
    float diff = max(dot(n, normalize(ro - p)), .05);
    col *= .3 + diff * .7;
    
    // Rim light
    vec3 rimCol = Spectrum(fract(t * .2 + a.x));
    col += fresnel * rimCol * (1. + a.y * 2.) * .4;
    
    // Glow
    #if USE_GLOW
    col += glowAccum / GLOW_BRIGHTNESS * (1. + beat);
    #endif
    
    // === SPARKLES ===
    #if USE_SPARKLES
    // Main sparkle
    float sparkle = sin(p.x * SPARKLE1_FREQ + t * 3.) * sin(p.y * SPARKLE1_FREQ * .94 + t * 2.7) * sin(p.z * SPARKLE1_FREQ * 1.06 + t * 3.3);
    sparkle = pow(max(sparkle, 0.), SPARKLE1_POWER) * fresnel * (SPARKLE1_AMT + a.z * HIGH_SPARKLE * 2.);
    col += sparkle * Spectrum(fract(p.z * .3 + t * .5));
    
    // White sparkle
    float sparkle2 = sin(p.x * SPARKLE2_FREQ + t * 5.) * sin(p.y * SPARKLE2_FREQ * .96 + t * 4.5) * sin(p.z * SPARKLE2_FREQ * 1.04 + t * 5.5);
    sparkle2 = pow(max(sparkle2, 0.), SPARKLE2_POWER) * a.z * SPARKLE2_AMT;
    col += sparkle2 * vec3(1);
    
    // Edge sparkle
    float edgeSparkle = sin(dot(n, vec3(30., 27., 33.)) + t * 4.);
    edgeSparkle = pow(max(edgeSparkle, 0.), 10.) * fresnel * (1. + a.z * HIGH_SPARKLE);
    col += edgeSparkle * iriCol * EDGE_SPARKLE_AMT;
    #endif
    
    // === AUDIO REACTIVE ===
    col *= 1. + beat * BASS_BRIGHTNESS;
    col = mix(vec3(dot(col, vec3(.3))), col, 1.2 + a.x * BASS_SATURATION);
    col = mix(col, col.gbr, a.y * MID_COLOR_SHIFT);
    col += fresnel * a.z * Spectrum(fract(p.z * .5 + t)) * .3;
    col += vec3(1) * pow(beat, 4.) * BEAT_FLASH;
    
    // === CONTRAST ===
    #if USE_CONTRAST
    col = max(col - BLACK_CRUSH, 0.) * BLACK_SCALE;
    col = col * col * (3. - 2. * col);
    #endif
    
    // Saturation
    vec3 gray = vec3(dot(col, vec3(.299, .587, .114)));
    col = mix(gray, col, SATURATION);
    
    // Vignette
    #if USE_VIGNETTE
    float vig = 1. - dot(u, u) * VIGNETTE_AMT;
    col *= vig;
    #endif
    
    // Gamma
    o.rgb = pow(clamp(col, 0., 1.), vec3(GAMMA));
    o.a = 1.;
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    vec4 color;
    mainImage(color, fragCoord);
    fragColor = color;
}
