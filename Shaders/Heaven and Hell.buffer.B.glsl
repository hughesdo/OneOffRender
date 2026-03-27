#version 330 core

// Buffer B: Sky/Ground/Bloom Extraction
// OneOffRender channel mapping:
//   iChannel0 = Buffer A output (beat detection)
//   iChannel1 = audio texture

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Buffer A
uniform sampler2D iChannel1;  // Audio texture

out vec4 fragColor;

#define AUDIO_BASS_SENSITIVITY 1.5
#define AUDIO_MID_SENSITIVITY 0.8
#define AUDIO_HIGH_SENSITIVITY 0.2

#define SKY_INTENSITY 0.5
#define SKY_ANIMATION_SPEED 4.0
#define SKY_PLAYFUL_PAUSE 0.9
#define SKY_AUDIO_WARP 0.388

#define BLOOM_BEAT_GLOW 0.4
#define BLOOM_SKY_EXTRACTION 0.2

#define SPHERE_ROTATION_SPEED 0.12
#define CAMERA_ORBIT_SPEED 0.05

#define GROUND_WAVE_AMPLITUDE 0.29
#define GROUND_WAVE_FREQUENCY 1.5
#define GROUND_WAVE_SPEED 0.77
#define GROUND_WAVE_CHAOS 0.005
#define GROUND_WAVE_AUDIO_REACT 0.000
#define GROUND_CREST_GLOW 0.9
#define GROUND_REFLECT_DISTORTION 0.2
#define GROUND_REFLECTIVITY 0.8
#define GROUND_ROUGHNESS 0.15
#define GROUND_DARKNESS 0.3

#define HORIZON_BLUR_WIDTH 0.015
#define HORIZON_GLOW_INTENSITY 0.0
#define HORIZON_GLOW_COLOR vec3(0.2, 0.2, 1.0)
#define HORIZON_FOG_DENSITY 2.35

#define PI 3.14159265359
#define PHI 1.618033988749894
#define E 2.71828182846
#define SQ2 1.41421356237

float getAudio(float band) {
    // Audio is on iChannel1 in OneOffRender buffer convention
    return texture(iChannel1, vec2(band, 0.0)).x;
}

vec3 analyzeAudio() {
    float bass = 0.0, mid = 0.0, high = 0.0;
    for(int i = 0; i < 8; i++) {
        float f = float(i) / 8.0;
        float s = getAudio(f * 0.5);
        if(f < 0.25) bass += s;
        else if(f < 0.6) mid += s;
        else high += s;
    }
    return vec3(bass / 2.0 * AUDIO_BASS_SENSITIVITY,
                mid / 3.0 * AUDIO_MID_SENSITIVITY,
                high / 3.0 * AUDIO_HIGH_SENSITIVITY);
}

mat3 rotate_y(float a) {
    float sa = sin(a), ca = cos(a);
    return mat3(ca, 0., sa, 0., 1., 0., -sa, 0., ca);
}

mat3 rotate_x(float a) {
    float sa = sin(a), ca = cos(a);
    return mat3(1., 0., 0., 0., ca, sa, 0., -sa, ca);
}

mat3 rotate_z(float a) {
    float sa = sin(a), ca = cos(a);
    return mat3(ca, sa, 0., -sa, ca, 0., 0., 0., 1.);
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float hash4(vec4 p) {
    p = fract(p * vec4(0.1031, 0.1030, 0.0973, 0.1099));
    p += dot(p, p.yzwx + 33.33);
    return fract((p.x + p.y) * (p.z + p.w));
}

float noise4D(vec4 p) {
    vec4 i = floor(p);
    vec4 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash4(i);
    float b = hash4(i + vec4(1,0,0,0));
    float c = hash4(i + vec4(0,1,0,0));
    float d = hash4(i + vec4(1,1,0,0));
    float e = hash4(i + vec4(0,0,1,0));
    float f_ = hash4(i + vec4(1,0,1,0));
    float g = hash4(i + vec4(0,1,1,0));
    float h = hash4(i + vec4(1,1,1,0));
    float i1 = hash4(i + vec4(0,0,0,1));
    float i2 = hash4(i + vec4(1,0,0,1));
    float i3 = hash4(i + vec4(0,1,0,1));
    float i4 = hash4(i + vec4(1,1,0,1));
    float i5 = hash4(i + vec4(0,0,1,1));
    float i6 = hash4(i + vec4(1,0,1,1));
    float i7 = hash4(i + vec4(0,1,1,1));
    float i8 = hash4(i + vec4(1,1,1,1));
    float x0 = mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
    float x1 = mix(mix(e, f_, f.x), mix(g, h, f.x), f.y);
    float x2 = mix(mix(i1, i2, f.x), mix(i3, i4, f.x), f.y);
    float x3 = mix(mix(i5, i6, f.x), mix(i7, i8, f.x), f.y);
    return mix(mix(x0, x1, f.z), mix(x2, x3, f.z), f.w);
}

float timeEvolution(float t, float audioMid) {
    float speed = SKY_ANIMATION_SPEED + audioMid * 10.2 * SKY_AUDIO_WARP;
    return  speed
+ sin(t * PHI) * SKY_PLAYFUL_PAUSE * 1.75
         + sin(t * PHI) * SKY_PLAYFUL_PAUSE
         + sin(t * E) * SKY_PLAYFUL_PAUSE * 0.7
         + sin(t * PI) * SKY_PLAYFUL_PAUSE * 0.45;
}

vec4 domainWarp(vec4 p, float t, float audioMid) {
    vec4 q = p;
    for(int i = 0; i < 3; i++) {
        float fi = float(i);
        float angle = t * (0.1 + fi * 0.05 + audioMid * 0.1 * SKY_AUDIO_WARP) + fi * PHI;
        vec2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle)) * q.xy;
        q.xy = rot;
        q += 0.3 * noise4D(q * (1.5 + fi * 0.5) + vec4(t * 0.1)) - 0.15;
    }
    return q;
}

vec3 extractSkyBright(vec2 screenUV, float time, vec3 audio) {
    vec2 uv = screenUV * 2.0;
    float te = timeEvolution(time, audio.y);
    vec4 pos = vec4(uv * 2.0, length(uv) * SQ2, te * 0.5);
    pos = domainWarp(pos, te*1.5, audio.y);

    float field = 0.50;
    float amplitude = 1.0;
    float frequency = 1.2;
    for(int i = 1; i < 6; i++) {
        vec4 samplePos = pos * frequency + vec4(time * (0.1 + float(i) * 0.50));
        field += noise4D(samplePos) * amplitude;
        frequency *= PHI;
        amplitude *= 0.6;
    }

    float eps = 0.05;
    float nX = noise4D(domainWarp(pos + vec4(eps,0,0,0), te, audio.y));
    float nY = noise4D(domainWarp(pos + vec4(0,eps,0,0), te, audio.y));
    vec3 normal = normalize(vec3((field - nX) / eps, (field - nY) / eps, 1.0));
    float curvature = length(normal.xy);
    float glow = pow(curvature, 4.0) * (2.0 + audio.x * 0.5);

    vec3 baseColor = 0.6 + 0.5 * cos(vec3(0,1.0,2.0) * PI * 3.5 + field * 4.0 + te);
    baseColor=pow(baseColor,vec3(1.5))*0.75;
    vec3 viewDir = normalize(vec3(uv, 1.0));
    float opalescence = dot(viewDir, normal) * 1.5 + 0.5;
    vec3 irid = 0.5 + 0.5 * cos(vec3(0.0, 0.5, 1.0) * PI * 1.5 + opalescence * 4.0 + time * 0.2);
    vec3 bright = irid * glow * 0.6 + baseColor * pow(glow, 2.0) * 0.4;
    bright=pow(bright,vec3(1.5))*1.0;
    float lum = dot(bright, vec3(0.299, 0.587, 0.114));
    return (lum > 0.3) ? bright * (lum - 0.3) * BLOOM_SKY_EXTRACTION : vec3(0.0);
}

void getWave(vec2 xz, float time, float audioBass, out float height, out vec2 gradient) {
    height = 0.0;
    gradient = vec2(0.0);

    float speed = time * (GROUND_WAVE_SPEED + audioBass * GROUND_WAVE_AUDIO_REACT);
    float amp = GROUND_WAVE_AMPLITUDE;
    float freq = GROUND_WAVE_FREQUENCY;

    float goldenAngle = 2.39996323;

    for(int i = 0; i < 4; i++) {
        float fi = float(i);
        float angle = fi * goldenAngle;
        vec2 dir = vec2(cos(angle), sin(angle));
        vec2 perp = vec2(-dir.y, dir.x);

        float phase = dot(xz, dir) * freq + speed * (1.0 + fi * 0.2);
        float wave = sin(phase);
        height += amp * wave;

        float dwave = cos(phase);
        gradient += dir * (amp * freq * dwave);

        if(GROUND_WAVE_CHAOS > 0.001) {
            float phase2 = dot(xz, perp) * freq * 1.618 + speed * 1.3;
            float wave2 = sin(phase2);
            height += amp * GROUND_WAVE_CHAOS * wave2 * 0.5;
            gradient += perp * (amp * freq * 1.618 * cos(phase2) * GROUND_WAVE_CHAOS * 0.5);
        }

        amp *= 0.5;
        freq *= PHI;
    }

    if(GROUND_ROUGHNESS > 0.0) {
        vec2 noiseUV = xz * 8.0 + time * 0.1;
        height += (noise(noiseUV) - 0.5) * GROUND_ROUGHNESS * 0.02;
    }
}

vec3 sampleGround(vec3 ro, vec3 rd, float time, vec3 audio, vec2 screenUV) {
    float baseGroundY = -1.4;
    float gt = (baseGroundY - ro.y) / rd.y;

    if(gt > 0.2) {
        vec3 hitPos = ro + rd * gt;

        float waveH;
        vec2 waveGrad;
        getWave(hitPos.xz, time, audio.x, waveH, waveGrad);

        vec3 normal = normalize(vec3(-waveGrad.x, 1.0, -waveGrad.y));
        vec3 refDir = reflect(rd, normal);

        vec2 reflUV = screenUV * vec2(1.0, -1.0);
        reflUV += refDir.xz * GROUND_REFLECT_DISTORTION * (1.0 + length(waveGrad));

        vec3 skyBloom = extractSkyBright(reflUV, time, audio);
        float falloff = exp(-length(hitPos.xz) * 0.2);

        float crest = smoothstep(0.4, 1.0, (waveH + GROUND_WAVE_AMPLITUDE) / (GROUND_WAVE_AMPLITUDE * 2.0 + 0.001));
        vec3 crestColor = vec3(0.6, 0.80, 1.1) * crest * GROUND_CREST_GLOW * 3.0;

        float soft = smoothstep(10.0, 2.0, length(hitPos.xz));

        return (skyBloom * GROUND_REFLECTIVITY + crestColor) * falloff * soft * GROUND_DARKNESS;
    }
    return vec3(0.0);
}

vec3 extractBright(vec3 ro, vec3 rd, float time, vec3 audio, vec2 screenUV) {
    vec3 skyBright = extractSkyBright(screenUV, time, audio);

    float horizonEdge = -0.17;
    float groundBlend = smoothstep(horizonEdge + HORIZON_BLUR_WIDTH, horizonEdge, rd.y);

    vec3 bright = skyBright;

    if(groundBlend > 0.38) {
        vec3 groundBright = sampleGround(ro, rd, time, audio, screenUV);

        bright = mix(skyBright, groundBright, groundBlend);

        float horizonGlow = 1.0 - abs(rd.y - horizonEdge) / HORIZON_BLUR_WIDTH;
        horizonGlow = max(0.0, horizonGlow) * HORIZON_GLOW_INTENSITY;
        horizonGlow *= smoothstep(0.0, 1.0, groundBlend * (1.0 - groundBlend) * 4.0);

        float fog = exp(-abs(rd.y - horizonEdge) * 10.0) * HORIZON_FOG_DENSITY;
        vec3 fogColor = HORIZON_GLOW_COLOR * (0.5 + audio.x * 0.5);

        bright += fogColor * fog;
        bright += HORIZON_GLOW_COLOR * horizonGlow * (0.3 + audio.x * 0.7);
    }

    return bright;
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;

    vec2 uv = fragCoord / iResolution.xy;
    vec2 centered = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float time = iTime;
    vec3 audio = analyzeAudio();

    float camDist = 3.5;
    float camAngle = time * CAMERA_ORBIT_SPEED;
    float camHeight = 0.2 + sin(time * 0.07) * 0.15;
    vec3 ro = vec3(sin(camAngle) * camDist, camHeight, cos(camAngle) * camDist);
    vec3 lookAt = vec3(0.0, -0.05, 0.0);
    vec3 forward = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0, 1, 0), forward));
    vec3 up = cross(forward, right);
    vec3 rd = normalize(forward + centered.x * right + centered.y * up);

    vec3 bright = extractBright(ro, rd, time, audio, centered);
    fragColor = vec4(bright, 1.0);
}
