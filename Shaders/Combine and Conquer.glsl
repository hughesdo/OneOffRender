
//  Created by PAEz in 2025-10-12
//  https://www.shadertoy.com/view/33lcDf

#version 330 core

// Uniforms
uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio FFT texture

// Output
out vec4 fragColor;

//  Pastel analogous and aligned-phase palettes for beautiful mixing
vec3 palette1(float t) {
    vec3 a = vec3(0.48, 0.53, 0.57);       // light, bluish-grey pastel
    vec3 b = vec3(0.15, 0.13, 0.18);       // soft, low saturation
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.34, 0.47, 0.60);       // blue-aqua
    return a + b * cos(6.28318 * (c * t + d));
}
vec3 palette2(float t) {
    vec3 a = vec3(1.53, 0.57, 0.62);       // slightly brighter, soft purple pastel
    vec3 b = vec3(0.12, 0.11, 0.13);       // soft, low saturation
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.41, 0.53, 0.72);       // purple-aqua, phase aligned
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;

    float bass = texture(iChannel0, vec2(0.1, 0.25)).x * 0.11;
    float mid  = texture(iChannel0, vec2(0.5, 0.25)).x * 0.5;
    float treb = texture(iChannel0, vec2(0.9, 0.25)).x * 1.5;
    float avgAudio = (bass + mid + treb) * 3.00;

    // Normalized coordinates
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    float r = length(uv);

    // Subtle counter-rotation
    float innerSpin = iTime * 7.0 * 1.00115;    // gentle center spin
    float outerSpin = -iTime * 1.0 * 1.00025;   // gentle outer counter-spin
    float mixRad = 87.5 * smoothstep(-0.001, 0.026, r * 3.0);
    float spin = -7.2 * mix(innerSpin, outerSpin, mixRad);
    float cs = cos(spin), sn = sin(spin);
    uv = mat2(cs, -sn, sn, cs) * uv * 0.7;
    r = length(uv) * 1.0;

    float baseAngle = atan(uv.y, uv.x);
    float segs = 5.0;
    float segAngle = 6.283185 * segs;
    float kAngle = mod(baseAngle, segAngle);
    kAngle = abs(kAngle - segAngle * 0.5);

    // Subtle fold
    float fold = 0.52 * sin(iTime * 0.2 + r * 1.5 + -0.8 * sin(kAngle));  // very gentle!
    float a = baseAngle + fold;
    kAngle = mod(a, segAngle);
    kAngle = abs(kAngle - segAngle * 0.5);

    vec2 kUv = vec2(cos(kAngle), sin(kAngle)) * r;
    float kMag = length(kUv);
    float kTheta = atan(kUv.y, kUv.x);

    float kTurb = sin(kMag * 12.0 + sin(kAngle * 2.0) * segs * -0.45 + iTime * 1.0 + bass * 5.0 + mid * 0.2) * 0.08
                + cos(sin(kAngle * 5.0) * segs * 1.2 + iTime * 1.7 + treb * 7.0) * 0.06
                + sin(iTime + kMag * 22.0 + bass * 7.5) * 0.03;

    float kSpiral = sin(sin(kAngle * segs * -0.67) + mid * 2.7 + bass * 2.4 + iTime * 0.54) * 0.10;
    float kWave = sin((kMag + kSpiral) * 6.1 - iTime * 0.8 + treb * -0.4) * 0.56;
    float masterPattern = kTurb + kWave + kSpiral;

    float d = length(mod((kUv + masterPattern * 0.4) * 10.7, 2.0) - 1.0)
              - (0.42 + bass * 0.19 + 0.11 * masterPattern);

    float sdf = smoothstep(1.018, -0.2, abs(d - 0.08 + -0.977 * masterPattern));

    float pal1_t = mod(iTime * 0.07 + kTheta * 5.14 + masterPattern * 0.24, 1.0);
    float pal2_t = mod(iTime * 0.09 + kMag + masterPattern * 0.17, 1.0);
    vec3 col1 = palette1(pal1_t);
    vec3 col2 = palette2(pal2_t);

    // CLAMP blend factor for smooth interpolation! Very important.
    float blend = clamp(sdf + 0.16 * masterPattern, 0.0, 1.0);
    vec3 color = mix(col1, col2, blend);

    color *= 1.0 - kMag * 0.41 + avgAudio * 0.37 + masterPattern * 0.19;

    float hShift = iTime * 0.15 + bass * 0.28 + mid * 0.16 + treb * 0.17
                   + sin(kTheta * 7.2 + masterPattern * 8.0) * 0.17;
    float aH = hShift * 6.283185;
    float S = sin(aH), C = cos(aH);
    mat3 rot = mat3(
      0.299 + 0.701 * C + 0.168 * S, 0.587 - 0.587 * C + 0.330 * S, 0.114 - 0.114 * C - 0.497 * S,
      0.299 - 0.299 * C - 0.328 * S, 0.587 + 0.413 * C + 0.035 * S, 0.114 - 0.114 * C + 0.292 * S,
      0.299 - 0.3 * C + 1.25 * S,    0.587 - 0.588 * C - 1.05 * S,  0.114 + 0.886 * C - 0.203 * S
    );
    color = rot * color;

    color = pow(color, vec3(1.0 - avgAudio * 0.18 + masterPattern * 0.07));
    color *= vec3(1.03 + bass * 0.33 + masterPattern * 0.09,
                  1.04 + mid * 0.35 + masterPattern * 0.07,
                  1.02 + treb * 0.31 + masterPattern * 0.10);

    color = clamp(color * 1.11, 0.0, 1.0);
    fragColor = vec4(color, 1.0);
}
