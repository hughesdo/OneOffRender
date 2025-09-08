#version 330 core

// Cellular Aurora Storm - A hybrid combining wavelet cellular patterns, curl flow fields, and auroral ridge enhancement (Audio Reactive)
// Unique concept: Aurora-like veils flowing through cellular wavelet structures with turbulent curl-driven motion

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// === TWEAKING VARIABLES ===
// Camera Movement
#define CAMERA_ROTATION_SPEED 0.2
#define CAMERA_RADIUS 3.0

// Frequency Color Shifting
#define FREQ_COLOR_INTENSITY 0.03
#define FREQ_BASS_CHANNEL 0.05
#define FREQ_MID_CHANNEL 0.3
#define FREQ_HIGH_CHANNEL 0.7
#define FREQ_COLOR_SMOOTHING 0.8
#define FREQ_HUE_SHIFT_AMOUNT 0.4

// Storm Intensity & Flow
#define BASE_STORM_INTENSITY 2.5
#define CURL_BASE_AMPLITUDE 0.3
#define CURL_LAYERS 3
#define CURL_AMPLITUDE_DECAY 0.6
#define CURL_SCALE_BASE 0.8
#define CURL_SCALE_INCREMENT 1.2
#define CURL_SPEED_BASE 0.15
#define CURL_SPEED_INCREMENT 0.08
#define CURL_OFFSET_MULTIPLIER 2.1

// Cellular Pattern
#define CELLULAR_WARP_AMOUNT 0.4
#define CELLULAR_SCALE 2.0
#define CELLULAR_TIME_SCALE 0.8
#define CELLULAR_SCALE_FACTOR 1.35
#define CELLULAR_LOWER_BOUND -0.1
#define CELLULAR_UPPER_BOUND 0.4
#define CELLULAR_SHARP_LOWER 0.9
#define CELLULAR_SHARP_UPPER 0.3

// Aurora Layers
#define AURORA_LAYERS 3
#define RIDGE_SCALE 1.8
#define RIDGE_TIME_SCALE 0.3
#define RIDGE_LAYER_OFFSET 0.5
#define RIDGE_SHARPNESS_BASE 0.8
#define RIDGE_SHARPNESS_INCREMENT 0.2
#define AURORA_CURL_INFLUENCE 0.3
#define HEIGHT_FREQUENCY 1.5
#define HEIGHT_SPEED -0.6
#define HEIGHT_LAYER_OFFSET 1.2
#define HEIGHT_CELLULAR_INFLUENCE 2.0
#define FALLOFF_DISTANCE 0.9
#define FALLOFF_SMOOTHNESS 0.3
#define FALLOFF_LAYER_OFFSET 0.1

// Color Enhancement
#define BASE_COLOR_NOISE_SCALE 0.3
#define BASE_COLOR_LAYER_SCALE 0.15
#define BASE_COLOR_TIME_SCALE 0.08
#define BASE_COLOR_CELLULAR_SCALE 0.3
#define COLOR_SATURATION_BASE 1.2
#define COLOR_STORM_BOOST 0.5
#define STORM_COLOR_TIME_SCALE 0.15
#define STORM_COLOR_CURL_SCALE 0.4
#define STORM_COLOR_LAYER_SCALE 0.25
#define LAYER_MIX_STORM_INFLUENCE 0.3
#define LAYER_INTENSITY_BASE 0.8
#define LAYER_INTENSITY_DECAY 0.15
#define GLOW_ACCUMULATION_BASE 0.6
#define GLOW_ACCUMULATION_DECAY 0.1

// Flow Highlights
#define FLOW_HIGHLIGHT_COLOR_BASE 0.3
#define FLOW_HIGHLIGHT_COLOR_SCALE 1.0
#define FLOW_HIGHLIGHT_TIME_SCALE 0.15
#define FLOW_HIGHLIGHT_SMOOTHSTEP_LOWER 0.0
#define FLOW_HIGHLIGHT_SMOOTHSTEP_UPPER 0.6
#define FLOW_HIGHLIGHT_INTENSITY 0.6

// Final Composition
#define GLOW_FLOW_CONTRIBUTION 0.4
#define GLOW_TIME_SCALE 0.2
#define GLOW_TIME_OFFSET 0.15
#define GLOW_INTENSITY 0.3
#define CONTRAST_MIX 0.6
#define BRIGHTNESS_BOOST 1.3
#define GAMMA_CORRECTION 0.85

// Vignette & Final
#define VIGNETTE_INNER 0.8
#define VIGNETTE_OUTER 1.3
#define VIGNETTE_CELLULAR_INFLUENCE 0.1
#define DEPTH_SHADE_BASE 0.8
#define DEPTH_SHADE_AMOUNT 0.4
#define FINAL_BRIGHTNESS_BASE 0.85
#define FINAL_BRIGHTNESS_VARIATION 0.5
#define FINAL_BRIGHTNESS_TIME_SCALE 0.1

// === WAVELET SYSTEM (from Meditative Veils) ===
mat2 myRot(float a){ 
    float s=sin(a), c=cos(a); 
    return mat2(c,-s,s,c); 
}

float myHash21(vec2 p){
    p = fract(p*vec2(123.34, 345.45));
    p += dot(p, p+34.345);
    return fract(p.x*p.y);
}

float myWaveletLayer(vec2 p, float z){
    vec2 id = floor(p);
    vec2 f = fract(p) - 0.5;
    float n = myHash21(id);
    f *= myRot(n*987.123);
    float d = sin(f.x*8.0 + z);
    d *= smoothstep(0.25, 0.0, dot(f,f));
    return d;
}

float myWaveletNoise(vec2 p, float z, float scaleFactor){
    float d=0.0, s=1.0, m=0.0;
    for(int i=0;i<4;i++){
        d += myWaveletLayer(p*s, z)/s;
        p = p*mat2(0.54,-0.84,0.84,0.54) + float(i);
        m += 1.0/s;
        s *= scaleFactor;
    }
    return d/max(m, 1e-3);
}

// === CURL FLOW SYSTEM (from Curl Tides) ===
float myNoise2d(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f*f*(3.0-2.0*f);
    float a = myHash21(i + vec2(0.0,0.0));
    float b = myHash21(i + vec2(1.0,0.0));
    float c = myHash21(i + vec2(0.0,1.0));
    float d = myHash21(i + vec2(1.0,1.0));
    float x1 = mix(a,b,u.x);
    float x2 = mix(c,d,u.x);
    return mix(x1,x2,u.y);
}

vec2 myGrad2d(vec2 p){
    float e = 0.001;
    float n1 = myNoise2d(p + vec2( e, 0.0));
    float n2 = myNoise2d(p + vec2(-e, 0.0));
    float n3 = myNoise2d(p + vec2(0.0,  e));
    float n4 = myNoise2d(p + vec2(0.0, -e));
    vec2 g = vec2(n1 - n2, n3 - n4) / (2.0*e);
    return g;
}

vec2 myCurl2d(vec2 p){
    vec2 g = myGrad2d(p);
    return vec2(g.y, -g.x);
}

// === AURORAL RIDGE SYSTEM (from Auroral Veils) ===
float myFbm2d(vec2 p) {
    float s = 0.0;
    float a = 0.5;
    mat2 r = myRot(0.5);
    for(int i=0;i<5;i++){
        s += a * myNoise2d(p);
        p = r * p * 2.03 + vec2(37.0, 17.0);
        a *= 0.5;
    }
    return s;
}

// === ENHANCED PALETTE SYSTEM ===
vec3 myPal(float t, vec3 a, vec3 b, vec3 c, vec3 d){
    return a + b*cos(6.2831853*(c*t + d));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;
    float t = iTime;
    
    // === CIRCULAR CAMERA MOVEMENT ===
    float cameraAngle = t * CAMERA_ROTATION_SPEED;
    vec2 cameraOffset = vec2(cos(cameraAngle), sin(cameraAngle)) * CAMERA_RADIUS;
    uv += cameraOffset;
    
    // === FREQUENCY ANALYSIS ===
    float bassFreq = texture(iChannel0, vec2(FREQ_BASS_CHANNEL, 0.25)).x;
    float midFreq = texture(iChannel0, vec2(FREQ_MID_CHANNEL, 0.25)).x;
    float highFreq = texture(iChannel0, vec2(FREQ_HIGH_CHANNEL, 0.25)).x;
    
    // Smooth frequency changes
    bassFreq = mix(bassFreq, smoothstep(0.0, 1.0, bassFreq), FREQ_COLOR_SMOOTHING);
    midFreq = mix(midFreq, smoothstep(0.0, 1.0, midFreq), FREQ_COLOR_SMOOTHING);
    highFreq = mix(highFreq, smoothstep(0.0, 1.0, highFreq), FREQ_COLOR_SMOOTHING);
    
    // Create frequency-based color shifts
    float freqHueShift = (bassFreq * 0.0 + midFreq * 0.33 + highFreq * 0.67) * FREQ_HUE_SHIFT_AMOUNT;
    float freqSatBoost = (bassFreq + midFreq + highFreq) * FREQ_COLOR_INTENSITY;
    
    // === MULTI-SCALE CURL WARPING ===
    vec2 curlWarp = vec2(0.0);
    float curlAmp = CURL_BASE_AMPLITUDE * BASE_STORM_INTENSITY;
    for(int i=0;i<CURL_LAYERS;i++){
        float scale = CURL_SCALE_BASE + CURL_SCALE_INCREMENT*float(i);
        float speed = CURL_SPEED_BASE + CURL_SPEED_INCREMENT*float(i);
        curlWarp += myCurl2d(uv*scale + vec2(0.0, t*speed) + float(i)*CURL_OFFSET_MULTIPLIER)*curlAmp;
        curlAmp *= CURL_AMPLITUDE_DECAY;
    }
    
    // === CELLULAR WAVELET STRUCTURE ===
    vec2 cellularUV = uv + CELLULAR_WARP_AMOUNT*curlWarp;
    float cellPattern = myWaveletNoise(cellularUV*CELLULAR_SCALE, t*CELLULAR_TIME_SCALE, CELLULAR_SCALE_FACTOR);
    
    // Create cellular mask - sharper boundaries
    float cellMask = smoothstep(CELLULAR_LOWER_BOUND, CELLULAR_UPPER_BOUND, cellPattern);
    cellMask *= smoothstep(CELLULAR_SHARP_LOWER, CELLULAR_SHARP_UPPER, cellPattern);
    
    // === AURORAL RIDGE FLOW ===
    vec3 finalColor = vec3(0.0);
    float totalGlow = 0.0;
    
    for(int k=0;k<AURORA_LAYERS;k++){
        float fk = float(k);
        vec2 flowUV = cellularUV + curlWarp*AURORA_CURL_INFLUENCE*(fk+1.0);
        
        // Create ridge-enhanced FBM that follows cellular structure
        float ridgeNoise = myFbm2d(flowUV*RIDGE_SCALE + vec2(0.0, t*RIDGE_TIME_SCALE + fk*RIDGE_LAYER_OFFSET));
        float ridge = 1.0 - abs(2.0*ridgeNoise - 1.0);
        ridge = pow(clamp(ridge, 0.0, 1.0), RIDGE_SHARPNESS_BASE + fk*RIDGE_SHARPNESS_INCREMENT);
        
        // Combine with cellular pattern for unique effect
        float aurora = ridge * cellMask;
        
        // Add height modulation influenced by wavelets
        float height = 0.5 + 0.5*sin(HEIGHT_FREQUENCY*flowUV.y + HEIGHT_SPEED*t + fk*HEIGHT_LAYER_OFFSET + cellPattern*HEIGHT_CELLULAR_INFLUENCE);
        aurora *= height;
        
        // Distance falloff
        float falloff = smoothstep(FALLOFF_DISTANCE, FALLOFF_SMOOTHNESS, length(uv)*0.8 + fk*FALLOFF_LAYER_OFFSET);
        aurora *= falloff;
        
        // Enhanced color palette with frequency-based color shifts
        vec3 baseCol = myPal(
            BASE_COLOR_NOISE_SCALE*ridgeNoise + BASE_COLOR_LAYER_SCALE*fk + BASE_COLOR_TIME_SCALE*t + BASE_COLOR_CELLULAR_SCALE*cellPattern + freqHueShift,
            vec3(0.2,0.3,0.5) + vec3(0.15*fk, 0.05*fk, -0.1*fk) + vec3(bassFreq*0.1, midFreq*0.1, highFreq*0.1),
            vec3(0.8,0.7,0.6) * (COLOR_SATURATION_BASE + COLOR_STORM_BOOST*BASE_STORM_INTENSITY + freqSatBoost),
            vec3(1.2,0.8,1.3),
            vec3(0.0 + 0.15*fk, 0.2 + 0.1*fk, 0.7 - 0.1*fk)
        );
        
        // More vibrant storm colors with frequency enhancement
        vec3 stormCol = myPal(
            STORM_COLOR_TIME_SCALE*t + STORM_COLOR_CURL_SCALE*length(curlWarp) + fk*STORM_COLOR_LAYER_SCALE + freqHueShift*2.0,
            vec3(0.05,0.1,0.15) + vec3(bassFreq*0.05, midFreq*0.05, highFreq*0.1),
            vec3(1.2,0.9,0.7) * (1.0 + freqSatBoost*0.8),
            vec3(1.5,1.0,0.6),
            vec3(0.0,0.3,0.9)
        );
        
        vec3 layerColor = mix(baseCol, stormCol, LAYER_MIX_STORM_INFLUENCE*BASE_STORM_INTENSITY*aurora);
        finalColor += layerColor * aurora * (LAYER_INTENSITY_BASE - LAYER_INTENSITY_DECAY*fk);
        totalGlow += aurora * (GLOW_ACCUMULATION_BASE - GLOW_ACCUMULATION_DECAY*fk);
    }
    
    // === CELLULAR STORM ENHANCEMENT ===
    // Add flowing cellular highlights with frequency-reactive colors
    float cellFlow = length(curlWarp) * cellMask;
    vec3 flowColor = myPal(FLOW_HIGHLIGHT_COLOR_BASE + FLOW_HIGHLIGHT_COLOR_SCALE*cellFlow + FLOW_HIGHLIGHT_TIME_SCALE*t + freqHueShift*3.0, 
                          vec3(0.02), vec3(1.0,1.2,1.4) * (1.0 + freqSatBoost), vec3(1.3,0.9,0.4), vec3(0.1,0.4,0.8));
    finalColor += flowColor * smoothstep(FLOW_HIGHLIGHT_SMOOTHSTEP_LOWER, FLOW_HIGHLIGHT_SMOOTHSTEP_UPPER, cellFlow) * FLOW_HIGHLIGHT_INTENSITY;
    
    // === FINAL COMPOSITION ===
    // More vibrant glow based on total activity with frequency colors
    float glow = clamp(totalGlow + cellFlow*GLOW_FLOW_CONTRIBUTION, 0.0, 1.0);
    vec3 glowCol = myPal(GLOW_TIME_SCALE*t + GLOW_TIME_OFFSET + freqHueShift*1.5, 
                        vec3(0.05,0.08,0.1) + vec3(bassFreq*0.02, midFreq*0.02, highFreq*0.05), 
                        vec3(1.0,0.8,1.2) * (1.0 + freqSatBoost*0.5), 
                        vec3(0.9,1.3,0.7), vec3(0.0,0.15,0.5));
    finalColor += glowCol * glow * GLOW_INTENSITY;
    
    // Sharper contrast with storm influence
    finalColor = finalColor*CONTRAST_MIX + (1.0-CONTRAST_MIX)*finalColor*finalColor*(3.0 - 2.0*finalColor);
    
    // Boost overall saturation and brightness with frequency enhancement
    finalColor *= BRIGHTNESS_BOOST * (1.0 + freqSatBoost*0.2);
    finalColor = pow(finalColor, vec3(GAMMA_CORRECTION));
    
    // Vignette with cellular variation
    float r = length(uv);
    float vign = smoothstep(VIGNETTE_INNER, VIGNETTE_OUTER, r) * (1.0 - VIGNETTE_CELLULAR_INFLUENCE*cellPattern);
    float depthShade = DEPTH_SHADE_BASE - DEPTH_SHADE_AMOUNT*vign;
    finalColor *= depthShade;
    
    // Final brightness modulation
    finalColor *= FINAL_BRIGHTNESS_BASE + FINAL_BRIGHTNESS_VARIATION*(0.5 + 0.5*sin(t*FINAL_BRIGHTNESS_TIME_SCALE)) * BASE_STORM_INTENSITY;
    
    finalColor = clamp(finalColor, 0.0, 1.0);
    fragColor = vec4(finalColor, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}