#version 330 core

// Iridescent Breathing Orbs - Audio-reactive shader adapted for OneOffRender
// Original Shadertoy shader converted to work with OneOffRender audio texture format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// ---- knobs ----
#define TEX_BINS       512.0
#define BAND_SAMPLES   24
#define NOISE_FLOOR    0.02
#define ENERGY_GAIN    1.8
#define BEAT_THRESH    0.03
#define BEAT_GAIN      1.2
#define FLOW_GAIN      0.12
#define RADIUS_GAIN    0.12
#define HUE_TREBLE     0.05
#define HUE_BEAT       0.03
#define SHEEN_GAIN     0.40
#define POP_GAIN       0.18

float hash12(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7)))*43758.5453123); }
mat2 rot(float a){ float s=sin(a), c=cos(a); return mat2(c,-s,s,c); }

float vnoise(vec2 p){
    vec2 i=floor(p), f=fract(p);
    vec2 u=f*f*(3.0-2.0*f);
    float a=hash12(i);
    float b=hash12(i+vec2(1,0));
    float c=hash12(i+vec2(0,1));
    float d=hash12(i+vec2(1,1));
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}
float fbm(vec2 p){
    float s=0.0, a=0.5;
    mat2 m = mat2(1.7,1.2,-1.2,1.7);
    for(int i=0;i<5;i++){
        s += a*vnoise(p);
        p = m*p + 0.07;
        a *= 0.5;
    }
    return s;
}

vec3 palette(float h){
    vec3 A=vec3(0.50,0.50,0.50);
    vec3 B=vec3(0.45,0.35,0.55);
    vec3 C=vec3(1.00,0.90,0.80);
    vec3 D=vec3(0.05,0.15,0.25);
    return A + B*cos(6.28318*(C*h + D));
}

// ---- OneOffRender Audio texture helpers ----
// Audio texture is 256x1 with bass (0-63) and treble (192-255)
float getBassValue(){
    // Sample from bass region (0-63 normalized to 0-0.25)
    return texture(iChannel0, vec2(0.125, 0.5)).r;
}

float getTrebleValue(){
    // Sample from treble region (192-255 normalized to 0.75-1.0)
    return texture(iChannel0, vec2(0.875, 0.5)).r;
}

float getMidValue(){
    // Interpolate between bass and treble for mid frequencies
    return mix(getBassValue(), getTrebleValue(), 0.5);
}

// Simulate the original bandAvgBins function using our audio data
float bandAvgBins(float b0, float b1){
    float bass = getBassValue();
    float mid = getMidValue();
    float treble = getTrebleValue();

    // Map frequency ranges to our available data
    if(b1 <= 72.0) {
        // Low frequency range - use bass
        return max(0.0, bass - NOISE_FLOOR) / (1.0 - NOISE_FLOOR);
    } else if(b0 >= 180.0) {
        // High frequency range - use treble
        return max(0.0, treble - NOISE_FLOOR) / (1.0 - NOISE_FLOOR);
    } else {
        // Mid frequency range - use interpolated mid
        return max(0.0, mid - NOISE_FLOOR) / (1.0 - NOISE_FLOOR);
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 R = iResolution.xy;
    vec2 uv = (fragCoord - 0.5*R)/max(R.x,R.y);
    float t = iTime;

    // audio bands
    float bassTight = bandAvgBins( 2.0, 36.0);
    float bassWide  = bandAvgBins( 2.0, 72.0);
    float mid       = bandAvgBins(50.0,160.0);
    float treble    = bandAvgBins(180.0,320.0);

    float loud = clamp((0.7*bassTight + 0.5*mid + 0.3*treble) * ENERGY_GAIN, 0.0, 3.0);
    float beat = max(bassTight - (bassWide + BEAT_THRESH), 0.0) * BEAT_GAIN;

    // flow field warp
    vec2 q = uv;
    float flow = fbm(q*1.2 + vec2(0.0, t*0.25));
    q += 0.35*vec2(fbm(uv*2.0 + flow*2.1 + t*0.1),
                   fbm(uv*2.1 - flow*2.0 - t*0.13));
    q += FLOW_GAIN * loud * vec2(fbm(uv*3.7 + t*0.09), fbm(uv*3.9 - t*0.08));
    q *= rot(0.35*sin(t*0.2));

    // orb field
    vec3 acc = vec3(0.0);
    float energy = 0.0;
    const int N = 12;
    float ga = 2.399963229728653; // golden angle

    for(int i=0;i<N;i++){
        float fi = float(i);
        float a = fi*ga;
        float r = (0.23 + 0.08*sin(0.7*fi + 0.9*t)) * (1.0 + RADIUS_GAIN*loud);
        vec2 center = 0.42*vec2(cos(a*0.9 + 0.21*t), sin(a*1.1 - 0.17*t));
        center += 0.08*vec2(sin(1.7*fi + t*0.6), cos(1.3*fi - t*0.5));
        float d = length(q - center) - r;
        float fall = 0.020/(0.0002 + d*d*18.0);
        float hue = fract(0.12*fi + 0.07*t + 0.25*flow + 0.1*d
                          + HUE_TREBLE*treble + HUE_BEAT*beat);
        vec3 col = palette(hue);
        fall *= 1.0 + 0.25*beat; // soft pop
        acc += col * fall;
        energy += fall;
    }

    // sheen
    float caust = 0.5 + 0.5*sin(10.0*q.x + 13.0*q.y + 2.0*flow - 1.3*t);
    caust = smoothstep(0.2, 0.95, caust);
    float sheenAmp = 0.12 * (1.0 + SHEEN_GAIN*(0.7*treble + 0.3*beat));
    vec3 sheen = palette(0.35 + 0.25*flow) * (sheenAmp * caust);

    // background
    float mist = fbm(uv*1.8 - vec2(t*0.05, t*0.03));
    vec3 bg = mix(vec3(0.04,0.05,0.07), vec3(0.06,0.07,0.10), mist);

    // combine
    vec3 col = bg + acc + sheen;
    col /= (1.0 + 0.35*energy);
    col = col / (1.0 + col); // reinhard

    // vignette
    float vig = 1.0 - smoothstep(0.75, 1.2, length(uv));
    col *= (0.85 + 0.15*vig);

    // final beat brighten
    col *= 1.0 + POP_GAIN * beat;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
