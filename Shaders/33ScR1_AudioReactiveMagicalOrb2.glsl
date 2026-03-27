#version 330 core

// Audio Reactive Magical Orb 2
// Created by OneHung
// Based on original by Chronos
// https://www.shadertoy.com/view/33ScR1

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
const float INTERNAL_SPEED_MULT = 2.0;
const float BASS_FREQ = 0.1;
const float MID_FREQ = 0.3;
const float HIGH_FREQ = 0.7;
const float PI = 3.14159265;

vec3 cmap1(float x) { return pow(.5+.5*cos(PI * x + vec3(1,2,3)), vec3(2.5)); }

vec3 cmap2(float x) {
    vec3 col = vec3(.35, 1,1)*(cos(3.141592*x*vec3(1)+.75*vec3(2,1,3))*.5+.5);
    col *= col * col;
    return col;
}

vec3 cmap3(float x) {
    vec3 yellow = vec3(1.,.9,0);
    vec3 purple = vec3(.75,0,1);
    vec3 col = mix(purple, yellow, cos(x/1.25)*.5+.5);
    col*=col*col;
    return col;
}

vec3 cmap(float x, float hueShift, float bassJump) {
    float t = mod(iTime, 30.);
    float colorOffset = hueShift + bassJump;
    return
    (smoothstep(-1., 0., t)-smoothstep(9., 10., t)) * cmap1(x + colorOffset) + 
    (smoothstep(9., 10., t)-smoothstep(19., 20., t)) * cmap2(x + colorOffset) + 
    (smoothstep(19., 20., t)-smoothstep(29., 30., t)) * cmap3(x + colorOffset) +
    (smoothstep(29., 30., t)-smoothstep(39., 40., t)) * cmap1(x + colorOffset);
}

void main() {
    float bass = texture(iChannel0, vec2(BASS_FREQ, 0.25)).x;
    float mid = texture(iChannel0, vec2(MID_FREQ, 0.25)).x;
    float high = texture(iChannel0, vec2(HIGH_FREQ, 0.25)).x;
    float audioLevel = (bass + mid + high) / 3.0;
    
    vec2 uv = (2. * gl_FragCoord.xy - iResolution.xy)/iResolution.y;
    float focal = 1.;
    vec3 ro = vec3(0, 0, 6.+cos(iTime*.25)*.75);
    
    float time = iTime * .5;
    float c = cos(time), s = sin(time);
    ro.xz *= mat2(c,s,-s,c);
    
    vec3 rd = normalize(vec3(uv, -focal));
    rd.xz *= mat2(c,s,-s,c);

    vec3 color = vec3(0);
    vec3 cubemapDir = vec3(rd.x, -rd.y, rd.z);  // Flip Y to correct orientation
    color += pow(texture(iChannel1, cubemapDir).rgb, vec3(2.2));
    
    time = iTime;
    {
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
            float hueShift = mid * HUE_SHIFT_MULT + high * 5.0;
            float bassJump = bass * BASS_COLOR_JUMP;

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
            color += fresnel * pow(texture(iChannel1, reflectDir).rgb, vec3(2.2));
        }
    }
    
    color = 1.-exp(-color);
    color *= 1.-dot(uv*.55,uv*.55)*.15;
    color = pow(color, vec3(1./2.2));
    color = clamp(color, 0., 1.);
    
    fragColor = vec4(color, 1);
}

