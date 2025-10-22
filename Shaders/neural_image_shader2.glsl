#version 330 core

uniform float iTime;
uniform vec2  iResolution;
uniform sampler2D iChannel0; // Audio FFT
uniform sampler2D iChannel1; // Image texture

out vec4 fragColor;

// ================= TWEAKABLE PARAMETERS =================
// Morphing & Displacement
#define MORPH_STRENGTH        0.18
#define NEURAL_ZOOM           3.0
#define FACE_MORPH_FACTOR     0.15     // much less morph on face (protect face/teeth/eyes)
#define OUTER_MORPH_FACTOR    2.2      // more morph on background

// Audio Reactivity
#define AUDIO_BOOST           40.0
#define BASS_MORPH_POWER      1.2
#define AUDIO_SPEED_MULT      4.5

// Visual Effects
#define GLOW_THRESHOLD        0.12
#define GLOW_INTENSITY        0.50
#define GLOW_PULSE_SPEED      10.0
#define NEURAL_BLEND          0.50
#define WHITE_GLOW_THRESHOLD  1.80
#define DARK_GLOW_THRESHOLD   0.60

// Coordinate Eyes
#define EYE1_SCALE            2.5
#define EYE2_OSCILLATION      2.0

// Visual Effects (simplified)
#define FACE_GLOW_GAIN        0.35
#define EDGE_GLOW_GAIN        0.50
// ========================================================

#define FFT(a) pow(texelFetch(iChannel0, ivec2(a, 0), 0).x, 5.)

float snd = 0.0;
float iAmplifiedTime = 0.0;

// ---------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------
float saturate(float x){ return clamp(x, 0.0, 1.0); }
vec2  saturate(vec2 v){ return clamp(v, 0.0, 1.0); }
vec3  saturate(vec3 v){ return clamp(v, 0.0, 1.0); }

vec3 rgb2hsv(vec3 c){
    vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r),  vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y)/(6.0*d + e)), d/(q.x + e), q.x);
}

float luminance(vec3 c){ return dot(c, vec3(0.299, 0.587, 0.114)); }

// Base image sampler
vec4 sampleImage(vec2 uv){ return texture(iChannel1, uv); }

// Image-edge strength from gradients
float edgeStrength(vec2 uv){
    vec3 c  = texture(iChannel1, uv).rgb;
    vec3 dx = dFdx(c);
    vec3 dy = dFdy(c);
    return clamp(length(dx) + length(dy), 0.0, 1.5);
}

// Background hue masks
float hueBand(float h, float center, float spread){
    float d = abs(fract(h - center + 0.5) - 0.5);   // circular distance in hue
    return saturate(1.0 - d/spread);
}



// Audio sampler
float sampleAudio(){
    float a0 = texture(iChannel0, vec2(0.02, 0.25)).x;
    float a1 = texture(iChannel0, vec2(0.08, 0.25)).x;
    float a2 = texture(iChannel0, vec2(0.20, 0.25)).x;
    float a  = a0*0.5 + a1*0.35 + a2*0.15;
    return saturate(pow(a, 0.9)*1.5);
}

// ---------------------------------------------------------------------
// Neural core (your original block, intact)
// ---------------------------------------------------------------------
vec4 r(vec2 pp, float t, vec2 q) {
    vec4 p = vec4(pp, q.yx * EYE1_SCALE);
    p *= 1. + snd * NEURAL_ZOOM;

    vec4 f0_0 = sin(p.x*vec4(-1.21,-.03,1.20,-1.17)+p.y*vec4(-.28,1.35,1.36,-1.23)+p.z*vec4(-.12,-.05,-.04,-.06)+p.w*vec4(-.18,-.12,-.13,-.48)+vec4(-.46,1.24,.40,-.30));
    f0_0 /= 1. + snd;
    vec4 f0_1=sin(p.x*vec4(-1.56,1.50,.48,1.36)+p.y*vec4(.10,-.75,.31,1.04)+p.z*vec4(-.27,-.03,-.03,-.05)+p.w*vec4(.01,-.16,-.41,.29)+vec4(.22,.21,.81,-1.16));
    vec4 f0_2=sin(p.x*vec4(-.94,-.22,1.00,1.10)+p.y*vec4(.38,-.74,.05,-1.54)+p.z*vec4(.04,-.05,-.06,-.06)+p.w*vec4(-.46,-.18,.20,.27)+vec4(.12,.97,.20,-.44));
    vec4 f0_3=sin(p.x*vec4(-1.13,-.72,.47,-1.66)+p.y*vec4(.24,.01,1.57,.56)+p.z*vec4(-.07,.04,-.10,-.00)+p.w*vec4(.32,.30,.08,-.04)+vec4(-.85,.37,-1.02,-1.29));

    vec4 f1_0=sin(mat4(.10,.41,-.34,-.20,.07,-.10,.07,-.20,.24,-.24,-.21,-.11,-.17,.23,-.06,-.16)*f0_0+
        mat4(.05,.25,-.19,-.24,-.24,.01,-.27,.28,-.03,.03,-.08,.06,.07,.01,-.01,.25)*f0_1+
        mat4(.07,.08,.01,.02,-.18,-.10,-.04,-.24,-.12,-.39,.10,.14,-.15,.35,-.29,.19)*f0_2+
        mat4(.15,.02,-.32,.04,-.08,.22,.24,.21,.02,.23,-.07,-.07,.36,.24,-.15,.03)*f0_3+
        vec4(-.18,-.33,.29,-.03))/1.00+f0_0;

    vec4 f1_1=sin(mat4(-.31,.19,.11,-.31,.35,-.03,-.24,-.17,.20,.07,-.38,.08,.09,-.04,.16,.21)*f0_0+
        mat4(-.53,-.09,-.17,.22,-.31,-.08,.23,-.33,-.11,-.17,-.40,.23,.12,.27,-.04,-.72)*f0_1+
        mat4(-.47,-.17,-.36,-.02,-.09,-.14,-.17,.37,.29,-.11,-.09,-.02,-.28,.15,.30,.13)*f0_2+
        mat4(-.30,.25,.06,-.26,-.10,.12,.18,.26,-.26,-.02,-.46,-.03,.44,.09,.08,-.19)*f0_3+
        vec4(.06,.12,-.26,.19))/1.00+f0_1;

    vec4 f1_2=sin(mat4(-.42,-.18,.15,-.15,-.22,-.34,.12,-.10,-.04,-.21,-.38,.15,-.32,.04,.25,.40)*f0_0+
        mat4(-.25,-.37,-.44,-.09,-.04,.12,-.07,-.17,-.05,-.25,.16,.72,.13,.10,.28,-.07)*f0_1+
        mat4(-.73,.12,.23,-.17,.08,-.28,-.02,.32,.25,-.47,-.23,.42,.24,.29,.07,.02)*f0_2+
        mat4(-.03,.38,.04,-.19,.04,.02,.14,.32,.22,.33,-.02,-.14,.16,.33,.06,-.27)*f0_3+
        vec4(.19,.03,.17,.31))/1.00+f0_2;

    vec4 f1_3=sin(mat4(-.17,.11,.22,.05,-.07,-.14,-.01,-.15,-.11,-.22,-.46,.37,.18,.02,.23,-.09)*f0_0+
        mat4(.14,-.17,.31,-.31,.22,-.16,-.32,.44,.39,-.27,-.13,.02,.19,-.17,-.03,.24)*f0_1+
        mat4(-.13,.47,.27,-.30,-.05,-.25,-.08,-.09,.15,-.27,-.65,.02,.13,-.02,.05,-.10)*f0_2+
        mat4(-.54,.12,-.03,-.23,.21,-.14,.26,-.21,-.07,-.27,.20,-.19,.20,.17,-.01,.22)*f0_3+
        vec4(.12,-.20,-.05,.07))/1.00+f0_3;

    vec4 f2_0=sin(mat4(-.23,-.03,.42,-.06,.55,-.30,.10,.25,.07,-.36,.13,.40,.23,.64,.17,-.47)*f1_0+
        mat4(.55,-.44,-1.00,-.09,.27,.02,.14,-.16,1.11,.25,-1.03,.20,.52,-.25,.44,.69)*f1_1+
        mat4(.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31)*f1_2+
        mat4(.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31)*f1_3+
        vec4(.31,-.31,.31,-.31))/1.41+f1_0;

    vec4 f2_1=sin(mat4(.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31)*f1_0+
        mat4(.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31)*f1_1+
        mat4(.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31)*f1_2+
        mat4(.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31,.31,-.31)*f1_3+
        vec4(.31,-.31,.31,-.31))/1.41+f1_1;

    return vec4(
        dot(f2_0,vec4(-.26,-.04,.04,-.04)) + dot(f2_1,vec4(-.20,-.01,-.00,-.06)) + -0.04,
        dot(f2_0,vec4(-.21,-.06,.06,-.06)) + dot(f2_1,vec4(-.26,.14,-.14,.06)) + -0.04,
        dot(f2_0,vec4(-.21,-.04,.05,-.06)) + dot(f2_1,vec4(-.23,.24,-.11,.07)) + 0.04,
        1.0);
}

// ---------------------------------------------------------------------
// Main with added image-driven mapping
// ---------------------------------------------------------------------
void mainImage(out vec4 outColor, in vec2 fragCoord){
    // audio accumulation same as your version
    int max_freq = 100;
    for(int i = 1; i < max_freq; i++){
        snd += FFT(i) * float(i);
    }
    snd /= float(max_freq * AUDIO_BOOST);
    iAmplifiedTime = iTime + snd * AUDIO_SPEED_MULT;

    vec2 uv = fragCoord / iResolution.xy;

    // pn for neural input (kept)
    vec2 pn = uv.yx + vec2(snd * cos(iAmplifiedTime / 2.0) * EYE2_OSCILLATION,
                           sin(iTime / 3.0) * EYE2_OSCILLATION);

    // build neural effect from your r()
    vec4 neuralEffect = r(((uv) * vec2(2.0, -2.0) + vec2(-1.0, 1.0))
                          * vec2(iResolution.x / iResolution.y, 1.0),
                          iAmplifiedTime, pn);

    // morph base from neural xy
    float bassBoost = 1.0 + snd * BASS_MORPH_POWER;
    vec2 displacement = neuralEffect.xy * MORPH_STRENGTH * bassBoost;

    // use simple UV for analysis (same coordinate system as working version)
    vec2 texUV = uv;

    // image features
    vec4 img0 = texture(iChannel1, vec2(texUV.x, 1.0 - texUV.y));
    float lum0 = luminance(img0.rgb);
    float edg0 = edgeStrength(vec2(texUV.x, 1.0 - texUV.y));
    vec3 hsv0 = rgb2hsv(img0.rgb);

    // simple uniform morphing (no face detection)
    float regionScale = 1.0;

    // compose final uv warp (simplified to fix the image sampling)
    vec2 morphedUV = uv + displacement * regionScale;

    // sample final color with proper Y-flip
    morphedUV.y = 1.0 - morphedUV.y;
    vec4 imageColor = sampleImage(clamp(morphedUV, 0.0, 1.0));

    // red-dominant glow for eyes and mouth
    float red_intensity = max(0.0, imageColor.r - max(imageColor.g, imageColor.b));
    if(red_intensity > GLOW_THRESHOLD){
        float glowPulse = GLOW_INTENSITY + 0.2 * sin(iAmplifiedTime * GLOW_PULSE_SPEED);
        imageColor += vec4(red_intensity, -red_intensity*0.5, -red_intensity*0.5, 0.0)
                      * glowPulse * (1.0 + snd * 2.0);
    }



    // white pop for teeth and speculars
    float l = luminance(imageColor.rgb);
    float whitePop = smoothstep(WHITE_GLOW_THRESHOLD, WHITE_GLOW_THRESHOLD + 0.6, l * 3.0);
    imageColor.rgb += whitePop * 0.12;

    // dark emboss for cross and choker
    float darkPop = smoothstep(DARK_GLOW_THRESHOLD, 0.0, l);
    imageColor.rgb += darkPop * vec3(0.05, 0.02, 0.02);

    // edge-reactive brightening
    float edg1 = edgeStrength(morphedUV);
    imageColor.rgb *= 1.0 + EDGE_GLOW_GAIN * edg1;

    // blend with neural field like your original
    float audioBlend = NEURAL_BLEND + snd * 0.3;
    outColor = mix(imageColor, neuralEffect * 0.8 + snd * 1.5, audioBlend);
}

void main(){
    mainImage(fragColor, gl_FragCoord.xy);
}
