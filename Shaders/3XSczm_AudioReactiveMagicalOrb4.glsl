#version 330 core

// Audio Reactive Magical Orb 4 with Edge Rainbow Waves
// Created by OneHung
// Original orb by Chronos
// https://www.shadertoy.com/view/3XSczm

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;
uniform samplerCube iChannel1;

out vec4 fragColor;

const float ORB_RADIUS = 2.0;
const float GLOW_INTENSITY = 1e-3;
const float GLOW_AUDIO_MULT = 4.0;
const float HUE_SHIFT_MULT = 10.0;
const float BASS_COLOR_JUMP = 20.0;
const float BASS_FREQ = 0.1;
const float MID_FREQ = 0.3;
const float HIGH_FREQ = 0.7;
const float CUBEMAP_DARKNESS = 1.0;
const float SPOTLIGHT_STRENGTH = 6.0;
const float SPOTLIGHT_TIGHTNESS = 25.0;
const float SPOTLIGHT_SHARPNESS = 5.0;
const float AMBIENT_GLOW_STRENGTH = 0.3;
const float RADIAL_FALLOFF_STRENGTH = 15.0;
const float DIFFUSE_SHARPNESS = 4.0;
const float ORB_ENV_AUDIO_BOOST = 5.0;
const float BASS_BRIGHTNESS_MULT = 3.0;
const float BASS_THRESHOLD = 0.3;
const float WAVE_SPEED = 5.0;
const float WAVE_DURATION = 2.0;
const float WAVE_WIDTH = 0.12;
const float WAVE_FEATHER = 0.04;
const float EDGE_DETECT_SCALE = 0.003;
const float EDGE_THRESHOLD = 0.15;
const float EDGE_CONTRAST = 3.0;
const float RAINBOW_INTENSITY = 3.5;
const float RAINBOW_MAX_ADD = 0.6;
const float PERSISTENT_EDGE_GLOW = 0.2;
const float PERSISTENT_RADIUS = 0.6;
const float WAVE_COOLDOWN = 0.8;
const float INTERNAL_SPEED_MULT = 2.0;
const float PI = 3.14159265;

vec3 cmap1(float x) { return pow(.5+.5*cos(PI * x + vec3(1,2,3)), vec3(2.5)); }
vec3 cmap2(float x) {
    vec3 col = vec3(.35, 1,1)*(cos(3.141592*x*vec3(1)+.75*vec3(2,1,3))*.5+.5);
    return col * col * col;
}
vec3 cmap3(float x) {
    vec3 col = mix(vec3(.75,0,1), vec3(1.,.9,0), cos(x/1.25)*.5+.5);
    return col*col*col;
}
vec3 cmap(float x, float hueShift, float bassJump) {
    float t = mod(iTime, 30.);
    float colorOffset = hueShift + bassJump;
    return (smoothstep(-1., 0., t)-smoothstep(9., 10., t)) * cmap1(x + colorOffset) + 
           (smoothstep(9., 10., t)-smoothstep(19., 20., t)) * cmap2(x + colorOffset) + 
           (smoothstep(19., 20., t)-smoothstep(29., 30., t)) * cmap3(x + colorOffset) +
           (smoothstep(29., 30., t)-smoothstep(39., 40., t)) * cmap1(x + colorOffset);
}

float detectEdges(vec3 rd) {
    vec3 offset = vec3(EDGE_DETECT_SCALE);
    vec3 c = texture(iChannel1, rd).rgb;
    vec3 sobelX = vec3(0.0);
    sobelX += texture(iChannel1, rd + vec3(-offset.x, -offset.y, 0)).rgb * -1.0;
    sobelX += texture(iChannel1, rd + vec3(-offset.x, 0, 0)).rgb * -2.0;
    sobelX += texture(iChannel1, rd + vec3(-offset.x, offset.y, 0)).rgb * -1.0;
    sobelX += texture(iChannel1, rd + vec3(offset.x, -offset.y, 0)).rgb * 1.0;
    sobelX += texture(iChannel1, rd + vec3(offset.x, 0, 0)).rgb * 2.0;
    sobelX += texture(iChannel1, rd + vec3(offset.x, offset.y, 0)).rgb * 1.0;
    vec3 sobelY = vec3(0.0);
    sobelY += texture(iChannel1, rd + vec3(-offset.x, -offset.y, 0)).rgb * -1.0;
    sobelY += texture(iChannel1, rd + vec3(0, -offset.y, 0)).rgb * -2.0;
    sobelY += texture(iChannel1, rd + vec3(offset.x, -offset.y, 0)).rgb * -1.0;
    sobelY += texture(iChannel1, rd + vec3(-offset.x, offset.y, 0)).rgb * 1.0;
    sobelY += texture(iChannel1, rd + vec3(0, offset.y, 0)).rgb * 2.0;
    sobelY += texture(iChannel1, rd + vec3(offset.x, offset.y, 0)).rgb * 1.0;
    vec3 sobelZ = vec3(0.0);
    sobelZ += texture(iChannel1, rd + vec3(0, -offset.y, -offset.z)).rgb * -1.0;
    sobelZ += texture(iChannel1, rd + vec3(0, 0, -offset.z)).rgb * -2.0;
    sobelZ += texture(iChannel1, rd + vec3(0, offset.y, -offset.z)).rgb * -1.0;
    sobelZ += texture(iChannel1, rd + vec3(0, -offset.y, offset.z)).rgb * 1.0;
    sobelZ += texture(iChannel1, rd + vec3(0, 0, offset.z)).rgb * 2.0;
    sobelZ += texture(iChannel1, rd + vec3(0, offset.y, offset.z)).rgb * 1.0;
    vec3 edges = sqrt(sobelX * sobelX + sobelY * sobelY + sobelZ * sobelZ);
    float edgeStrength = pow(dot(edges, vec3(0.299, 0.587, 0.114)) * EDGE_CONTRAST, 2.0);
    return smoothstep(EDGE_THRESHOLD, EDGE_THRESHOLD + 0.1, edgeStrength);
}

vec3 orbRainbow(float t, vec3 orbColor) {
    vec3 rainbow = 0.5 + 0.5 * cos(2.0 * PI * (t * 3.0 + vec3(0.0, 0.33, 0.67)));
    rainbow = mix(rainbow, orbColor, 0.5);
    rainbow *= orbColor + vec3(0.3);
    return rainbow * rainbow * 1.5;
}

void main() {
    float bass = texture(iChannel0, vec2(BASS_FREQ, 0.25)).x;
    float mid = texture(iChannel0, vec2(MID_FREQ, 0.25)).x;
    float high = texture(iChannel0, vec2(HIGH_FREQ, 0.25)).x;
    float audioLevel = (bass + mid + high) / 3.0;

    float waveSlot = mod(iTime, WAVE_COOLDOWN + WAVE_DURATION);
    bool canTriggerWave = waveSlot < WAVE_DURATION;
    float waveTime = canTriggerWave && bass > BASS_THRESHOLD ? waveSlot : -999.0;

    vec2 uv = (2. * gl_FragCoord.xy - iResolution.xy)/iResolution.y;
    float focal = 1.;
    vec3 ro = vec3(0, 0, 6.+cos(iTime*.25)*.75);
    float time = iTime * .5;
    float c = cos(time), s = sin(time);
    ro.xz *= mat2(c,s,-s,c);
    vec3 rd = normalize(vec3(uv, -focal));
    rd.xz *= mat2(c,s,-s,c);

    vec3 color = vec3(0);
    float hueShift = mid * HUE_SHIFT_MULT + high * 5.0;
    float bassJump = bass * BASS_COLOR_JUMP;
    vec3 orbColor = cmap(iTime, hueShift, bassJump);
    vec2 orbUV = vec2(0.0);

    vec3 cubemapDir = vec3(rd.x, -rd.y, rd.z);  // Flip Y to correct orientation
    vec3 cubemapColor = pow(texture(iChannel1, cubemapDir).rgb, vec3(2.2)) * CUBEMAP_DARKNESS;
    float edgeMask = detectEdges(rd);
    vec3 orbPos = vec3(0, 0, 0);
    vec3 orbScreenDir = normalize(orbPos - ro);
    float angularDist = length(rd - orbScreenDir);
    float spotlightFalloff = pow(1.0 / (1.0 + angularDist * angularDist * SPOTLIGHT_TIGHTNESS), 3.0);
    vec3 envSurfacePos = ro + rd * 50.0;
    vec3 toOrb = orbPos - envSurfacePos;
    vec3 lightDir = normalize(toOrb);
    float spotlightDirectional = pow(max(0.0, dot(lightDir, -rd)), SPOTLIGHT_SHARPNESS);
    float spotlightMask = spotlightFalloff * spotlightDirectional;
    float radialFalloff = pow(1.0 / (1.0 + angularDist * angularDist * RADIAL_FALLOFF_STRENGTH), 2.0);
    float radialMask = radialFalloff * pow(max(0.0, dot(lightDir, -rd)), DIFFUSE_SHARPNESS);
    float ambientFalloff = 1.0 / (1.0 + length(toOrb) * length(toOrb) * 0.005);
    float baseIntensity = 1.0 + audioLevel * ORB_ENV_AUDIO_BOOST;
    float bassBrightness = 1.0 + bass * BASS_BRIGHTNESS_MULT;

    cubemapColor += orbColor * spotlightMask * SPOTLIGHT_STRENGTH * baseIntensity * bassBrightness;
    cubemapColor += orbColor * radialMask * 2.0 * baseIntensity;
    cubemapColor += orbColor * ambientFalloff * AMBIENT_GLOW_STRENGTH * baseIntensity;

    if (edgeMask > 0.01) {
        if (waveTime >= 0.0 && waveTime < WAVE_DURATION) {
            float waveRadius = waveTime * WAVE_SPEED;
            float distFromOrb = length(uv - orbUV);
            float waveDist = abs(distFromOrb - waveRadius);
            float waveRingMask = 1.0 - smoothstep(WAVE_WIDTH * 0.5, WAVE_WIDTH * 0.5 + WAVE_FEATHER, waveDist);
            waveRingMask *= 1.0 - (waveTime / WAVE_DURATION);
            float finalWaveMask = waveRingMask * edgeMask;
            float rainbowT = fract((distFromOrb - (waveRadius - WAVE_WIDTH * 0.5)) / WAVE_WIDTH);
            vec3 rainbowColor = orbRainbow(rainbowT, orbColor);
            vec3 edgeGlow = min(rainbowColor * finalWaveMask * RAINBOW_INTENSITY * (1.0 + bass * 2.0), vec3(RAINBOW_MAX_ADD));
            cubemapColor += edgeGlow;
        }
        if (PERSISTENT_EDGE_GLOW > 0.0) {
            float persistDist = length(uv - orbUV);
            float persistMask = 1.0 - smoothstep(0.0, PERSISTENT_RADIUS, persistDist);
            cubemapColor += orbColor * edgeMask * persistMask * PERSISTENT_EDGE_GLOW * (1.0 + audioLevel);
        }
    }
    color += cubemapColor;

    time = iTime;
    float orbRadiusSq = ORB_RADIUS * ORB_RADIUS;
    float t = dot(0. - ro, rd);
    vec3 p = t * rd + ro;
    float y2 = dot(p, p);
    float x2 = orbRadiusSq - y2;

    if(y2 <= orbRadiusSq) {
        float a = t-sqrt(x2);
        float b = t+sqrt(x2);
        color *= exp(-(b-a));
        t = a + 0.01;
        float glowMult = GLOW_INTENSITY * (1.0 + audioLevel * GLOW_AUDIO_MULT);

        // Audio affects internal animation speed and complexity
        float internalTime = time * (1.0 + bass * INTERNAL_SPEED_MULT);

        for(int i = 0; i < 99 && t < b; i++) {
            vec3 p = t * rd + ro;
            float T = (t+internalTime)/5.;
            float c = cos(T), s = sin(T);
            p.xy = mat2(c,-s,s,c) * p.xy;

            // Audio affects internal complexity
            float complexityMult = 1.0 + mid * 0.5;
            for(float f = 0.; f < 9.; f++) {
                float a = exp(f)/exp2(f);
                p += cos(p.yzx * a * complexityMult + internalTime)/a;
            }
            float d = 1./100. + abs((ro -p-vec3(0,1,0)).y-1.)/10.;
            color += cmap(t, hueShift, bassJump) * glowMult / d;
            t += d*.25;
        }
        float R0 = 0.04;
        vec3 N = normalize(a * rd + ro);
        float cosTheta = dot(-rd, N);
        float fresnel = R0 + (1.0 - R0) * pow(1.0 - cosTheta, 5.0);
        color *= 1.-fresnel;
        vec3 reflectDir = vec3(reflect(rd, N).x, -reflect(rd, N).y, reflect(rd, N).z);
        color += fresnel * pow(texture(iChannel1, reflectDir).rgb, vec3(2.2)) * CUBEMAP_DARKNESS;
    }

    color = 1.-exp(-color);
    color *= 1.-dot(uv*.55,uv*.55)*.15;
    color = pow(color, vec3(1./2.2));
    fragColor = vec4(clamp(color, 0., 1.), 1);
}

