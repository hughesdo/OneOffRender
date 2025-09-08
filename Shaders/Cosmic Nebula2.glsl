#version 330 core

// Cosmic Nebula — Deep space gas clouds with stellar formation (Audio Reactive)
// Influences acknowledged: Inigo Quilez (noise techniques), cosmic photography references

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// === AUDIO REACTIVE STAR PARAMETERS ===
#define AUDIO_BRIGHTNESS 2.5    // How much brighter stars get when reacting
#define AUDIO_FREQUENCY 8.0     // Base frequency for audio reactivity
#define STAR_REACT_CHANCE 0.15  // Probability a star will be audio reactive (0.0-1.0)
#define AUDIO_SPEED 1.2         // Speed of the audio-like pulsing
// =====================================

float hash11(float n){ return fract(sin(n)*43758.5453123); }
float hash12(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453123); }
mat2 rot(float a){ float s=sin(a), c=cos(a); return mat2(c,-s,s,c); }

float vnoise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f*f*(3.0-2.0*f);
    float a = hash12(i);
    float b = hash12(i+vec2(1,0));
    float c = hash12(i+vec2(0,1));
    float d = hash12(i+vec2(1,1));
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

float fbm(vec2 p){
    float s = 0.0;
    float a = 0.5;
    mat2 m = mat2(1.6,1.2,-1.2,1.6);
    for(int i=0;i<6;i++){
        s += a * vnoise(p);
        p = m*p + 0.07;
        a *= 0.48;
    }
    return s;
}

// Nebula color palette - deep space colors
vec3 nebulaPal(float x, float density){
    // Base nebula colors: deep reds, magentas, blues, and hot whites
    vec3 a = vec3(0.2,0.1,0.3);
    vec3 b = vec3(0.8,0.4,0.6);
    vec3 c = vec3(1.0,0.8,0.5);
    vec3 d = vec3(0.0,0.2,0.8);
    
    vec3 base = a + b*sin(6.28318*(c*x + d));
    
    // Add hot emission regions
    float hotSpots = pow(density, 3.0);
    vec3 emission = mix(vec3(1.0,0.3,0.1), vec3(0.1,0.4,1.0), x);
    
    return mix(base, emission, hotSpots * 0.7);
}

vec3 stars(vec2 uv, float t){
    vec2 grid = uv * vec2(200.0,150.0);
    vec2 id = floor(grid);
    vec2 f  = fract(grid);
    float r = hash12(id);
    
    // Skip some cells for sparse star distribution
    if(r < 0.85) return vec3(0.0);
    
    vec2 off = fract(vec2(hash12(id+11.3), hash12(id+27.1)));
    vec2 d = f - off;
    float di = dot(d,d);
    
    // Make stars more varied in size
    float starSize = 0.001 + 0.004 * pow(r, 3.0);
    float s = smoothstep(starSize, 0.0, di);
    
    // Subtle twinkling
    float tw = 0.7 + 0.3*sin(t*3.0 + r*6.28318);
    
    // Star color variation
    vec3 col = mix(vec3(0.8,0.9,1.2), vec3(1.2,0.7,0.4), pow(r, 0.5));
    col = mix(col, vec3(0.4,0.8,1.0), step(0.97, r)); // Blue giants
    
    return col * s * tw * (2.0 + 3.0*pow(r, 4.0));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 R = iResolution.xy;
    vec2 uv = (fragCoord - 0.5*R)/max(R.x, R.y);
    float t = iTime*0.08; // Slower movement for nebula
    
    // No mouse interaction in OneOffRender
    
    // Multiple layers of nebula gas at different scales
    vec2 p1 = uv * 2.5;
    vec2 p2 = uv * 1.2;
    vec2 p3 = uv * 4.0;
    
    // Slowly rotating gas clouds
    p1 *= rot(t*0.15);
    p2 *= rot(-t*0.08);
    p3 *= rot(t*0.25);
    
    // Multiple octaves of noise for complex structure
    float cloud1 = fbm(p1 + vec2(t*0.3, t*0.2));
    float cloud2 = fbm(p2 + vec2(-t*0.2, t*0.4));
    float cloud3 = fbm(p3 + vec2(t*0.1, -t*0.15));
    
    // Combine noise layers for complex density
    float density = cloud1*0.6 + cloud2*0.3 + cloud3*0.1;
    density = pow(max(0.0, density - 0.1), 1.5);
    
    // Create filamentary structure
    vec2 warpUv = uv + 0.2*vec2(cloud1, cloud2);
    float filaments = abs(sin(warpUv.x*8.0 + cloud2*4.0)) * abs(sin(warpUv.y*6.0 + cloud1*3.0));
    filaments = 1.0 - smoothstep(0.1, 0.8, filaments);
    density *= (1.0 + filaments*2.0);
    
    // Distance fade from center (nebula gets dimmer at edges)
    float centerFade = 1.0 - smoothstep(0.3, 1.5, length(uv + 0.1*vec2(cloud1, cloud2)));
    density *= centerFade;
    
    // Color the nebula
    float hueShift = 0.3*cloud1 + 0.1*t + 0.2*(uv.x + uv.y);
    vec3 nebulaColor = nebulaPal(hueShift, density);
    
    // Deep space background
    vec3 spaceColor = vec3(0.005, 0.008, 0.015);
    spaceColor += 0.02*vec3(0.3, 0.1, 0.4) * pow(density, 0.3); // Subtle background glow
    
    // Combine nebula with background
    vec3 col = mix(spaceColor, nebulaColor, density);
    
    // Add bright emission cores
    float brightCores = pow(density, 4.0);
    col += vec3(1.2, 0.4, 0.2) * brightCores * 0.8;
    
    // Add blue emission regions
    float blueEmission = pow(smoothstep(0.6, 1.0, cloud2), 3.0) * density;
    col += vec3(0.2, 0.6, 1.5) * blueEmission * 0.5;
    
    // Dust lanes (darker regions)
    float dust = smoothstep(0.4, 0.8, cloud3) * density;
    col *= (1.0 - dust*0.7);
    
    // Add stars
    vec3 starfield = stars(uv + 0.05*vec2(cloud1, cloud2), t);
    col += starfield;
    
    // Add distant background stars
    vec3 bgStars = stars(uv*0.7, t*0.5) * 0.3;
    col += bgStars;
    
    // Subtle color grading
    col = pow(col, vec3(0.9, 1.0, 1.1)); // Slight blue tint
    col = mix(col, col*col*(3.0-2.0*col), 0.3); // Contrast
    
    // Final tone mapping and clamp
    col = col / (1.0 + col*0.8); // Soft tone mapping
    col = clamp(col, 0.0, 1.0);

    fragColor = vec4(col,1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}