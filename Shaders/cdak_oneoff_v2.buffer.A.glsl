// cdak_oneoff_v2 — Buffer A (Raymarching pass + MusicCave streaks)
// Outputs: vec4(lighting, glow+streaks, AO, distance)
// iChannel0 = self-feedback (unused)
// iChannel1 = audio FFT texture
//
// V2 additions over V1 buffer:
//   - MusicCave-style audio streak accumulator in march loop.
//     FFT energy sampled by tunnel depth, concentrated near surfaces.
//     Streak energy is folded into the glow channel so the image-pass
//     Sobel sees brighter edges wherever music is loud.

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;  // self-feedback (unused)
uniform sampler2D iChannel1;  // audio FFT

// ============================================================
// TWEAKABLE VARIABLES
// ============================================================
#define MARCH_STEPS      90
#define TIME_SCALE       1.0
#define SCENE_DURATION   300.0

#define AUDIO_GLOW       1.5
#define AUDIO_GEOMETRY   0.08

// MusicCave streak controls
#define STREAK_FALLOFF   55.0
#define STREAK_EXPONENT  2.5
#define STREAK_MIX       0.4   // how much streak folds into glow channel

// ============================================================
// AUDIO HELPERS — audio is on iChannel1 in buffer pass
// ============================================================
float bass()      { return texture(iChannel1, vec2(0.05, 0.25)).x; }
float mids()      { return texture(iChannel1, vec2(0.25, 0.25)).x; }
float highs()     { return texture(iChannel1, vec2(0.60, 0.25)).x; }
float broadband() { return texture(iChannel1, vec2(0.15, 0.25)).x; }

vec4 getH() {
    float b = bass();
    float m = mids();
    float hi = highs();
    return vec4(
        b * 0.02,
        m,
        hi * 0.01,
        iTime * 0.5 + b * 2.0
    );
}

// ============================================================
// ROTATION MATRIX
// ============================================================
mat3 r(vec3 g) {
    g *= 6.283;
    float a = cos(g.x), b = sin(g.x),
          c = cos(g.y), d = sin(g.y),
          e = cos(g.z), f = sin(g.z);
    return mat3(
        c*e + b*d*f,  -a*f,  b*c*f - d*e,
        c*f - b*d*e,   a*e, -d*f - b*c*e,
        a*d,           b,    a*c
    );
}

// ============================================================
// CAMERA ROTATION — no audio wobble
// ============================================================
mat3 w(float t, vec4 h) {
    return r(
        vec3(0.0, 0.0, smoothstep(-7.0, 30.0, t))
        + smoothstep(170.0, 300.0, t) * vec3(1.0, 2.0, 3.0)
    );
}

// ============================================================
// SDF: TUNNEL
// ============================================================
float f1(vec3 p, float t) {
    vec3 g = (fract(
        r(sin(p.z * 0.07) * vec3(0.0, 0.0, 0.3) * smoothstep(150.0, 60.0, p.z))
        * (p + sin(p.yzx * 0.1) / 3.0)
        / 6.0
    ) - 0.5) * 6.0;

    float d1 = 2.4 * smoothstep(20.0, 70.0, t) - abs(p.x) - 1.0;
    float d2 = max(abs(g.x), max(abs(g.y), abs(g.z))) - 2.3;
    float d3 = length(p - vec3(0.0, 0.0, 84.0)) - 18.0;

    d1 = mix(d1,
        min(max(d1, -0.7 - d2), max(d2 - 0.3, abs(d1 - 0.9) - 1.3)),
        clamp(p.z * 0.03 - 0.5 + sin(p.z * 0.1) * 0.1, 0.0, 1.0));
    d1 = max(max(d1, 25.0 - p.z), p.z - 116.0);
    d1 = min(
        min(
            max(d1, min(11.0 - abs(d3),
                max(-p.z + 84.0, abs(length(p.xy) - 1.3 + sin(p.z * 0.9) / 5.0) - 0.2))),
            max(d1 + 0.5, abs(d3 - 4.0) - 0.5)
        ) - 0.3 * smoothstep(60.0, 110.0, t),
        max(111.0 - p.z,
            min(7.0 - length(p.xy) / 2.0
                - sin(p.z * 0.3 + sin(p.z * 2.0) / 25.0 + t / 5.0) * 6.0,
                max(-p.x + (p.z - 105.0) * 0.1, abs(p.y) - 1.8)))
    );

    vec3 gq = r(pow(smoothstep(36.0, 4.0, t) * vec3(1.0, 2.0, 3.0), vec3(2.0))
               * step(-p.z, -15.0))
               * (p - vec3(0.0, 0.0, 44.0));

    if (t < 44.0)
        d1 = mix(d1,
            max(abs(gq.x), max(abs(gq.y), abs(gq.z))) - 4.0 - 15.0 * smoothstep(27.0, 36.0, t),
            smoothstep(44.0, 30.0, t));

    d1 = min(d1, 0.8 * max(p.z - 14.0,
        abs(length(p.xy) - 1.5 - sin(floor(p.z)) / 5.0) - 1.0));

    return d1;
}

// ============================================================
// SDF: METABALLS
// ============================================================
float f2(vec3 p, float t) {
    p.z -= 138.0;
    float ln = pow(1.0 / length(p + 3.0 * sin(t * vec3(5.1, 7.6, 1.0) * 0.023)), 2.0)
             + pow(1.0 / length(p + 3.0 * sin(t * vec3(4.5, 2.7, 2.0) * 0.033)), 2.0)
             + pow(1.0 / length(p + 3.0 * sin(t * vec3(6.3, 3.7, 4.0) * 0.031)), 2.0)
             + pow(1.0 / length(p + 3.0 * sin(t * vec3(7.5, 6.3, 5.0) * 0.023)), 2.0);
    float d1 = 1.0 / sqrt(ln) - 1.0;
    d1 = min(
        mix(d1 - 0.7,
            min(abs(d1 + 0.3) - 0.3, abs(d1 - 0.7) * 2.0 - 0.3),
            smoothstep(150.0, 230.0, t - p.y / 9.0)),
        abs(d1 - 5.0) - 1.0 + 4.2 * smoothstep(210.0, 150.0, t + p.y / 5.0)
    ) + 2.0 * smoothstep(230.0, 270.0, t + p.y);
    return d1;
}

// ============================================================
// CAMERA POSITION
// ============================================================
vec3 k(float t, mat3 wm) {
    return wm * vec3(0.0, 0.1, -0.1 - 2.0 * smoothstep(170.0, 190.0, t))
           + vec3(0.0, 0.0, smoothstep(-0.07, 1.0, t * 0.005) * 140.0);
}

// ============================================================
// COMBINED SDF
// ============================================================
float f(vec3 p, float t, vec3 cam, vec4 h) {
    p += 0.01;
    float d1 = 95.0 - length(p - cam);
    float d2 = f2(p, t);
    if (t < 280.0) d1 = min(d1, f1(p, t)) + 14.0 * smoothstep(140.0, 230.0, t);
    if (t > 130.0) d1 = min(d1, d2);
    d1 *= 0.3;
    vec3 pp = p * 0.3;
    for (float i = 0.0; i < 4.0; i++) {
        vec3 q = 1.0 + i * i * 0.18
            * (1.0 + 4.0 * (1.0 + 0.3 * sin(t * 0.001))
            * sin(vec3(5.7, 6.4, 7.3) * i * 1.145
                  + 0.3 * sin(h.w * 0.015) * (3.0 + i)));
        vec3 g = (fract(pp * q) - 0.5) / q;
        d1 = min(d1 + 0.03, max(d1, max(abs(g.x), max(abs(g.y), abs(g.z))) - 0.148));
    }
    return d1 / 0.28;
}

// ============================================================
// NORMAL ESTIMATION
// ============================================================
vec3 nn(vec3 p, float t, vec3 cam, vec4 h) {
    vec2 e = vec2(4e-3, 0.0);
    return -normalize(vec3(
        f(p + e.xyy, t, cam, h),
        f(p + e.yxy, t, cam, h),
        f(p + e.yyx, t, cam, h)
    ));
}

// ============================================================
// AMBIENT OCCLUSION
// ============================================================
float ao(vec3 p, vec3 n, float t, vec3 cam, vec4 h) {
    float o = 0.8;
    float g = f(p, t, cam, h);
    for (float i = 0.0; i < 1.0; i += 0.25) {
        float d = i * 0.15 + 0.025;
        o -= step(g, 0.01) * (d - f(p - n * d, t, cam, h)) * 2.0 * (2.0 - i * 1.8);
    }
    return o;
}

// ============================================================
// MAIN — outputs vec4(lighting, glow+streaks, AO, distance)
// ============================================================
void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    float t = mod(iTime * TIME_SCALE, SCENE_DURATION);
    vec4 h = getH();

    mat3 wm = w(t, h);
    vec3 cam = k(t, wm);

    vec2 sc = (fragCoord - 0.5 - iResolution.xy / 2.0) / iResolution.y;
    float lsc = length(sc / 2.0);
    vec3 rd = wm * normalize(vec3(2.0 * sin(sc), cos(lsc * 2.0 * sqrt(2.0))));

    vec3 p = cam;
    vec3 a = cam;
    float g      = 0.0;   // volumetric glow
    float streak = 0.0;   // MusicCave audio streak
    float df = f(p, t, cam, h) + 0.002;

    for (int i = 0; i < MARCH_STEPS; i++) {
        if (abs(df) <= 0.00032) break;

        // Broadband-boosted glow accumulation
        g += smoothstep(0.5, 0.07, df) * 0.01 * (1.0 + broadband() * AUDIO_GEOMETRY * 12.0) * (1.0 - g);

        // MusicCave streak: FFT sampled by tunnel depth, concentrated at surfaces
        float audioFreq = pow(texture(iChannel1, vec2(fract(abs(p.z) * 0.007), 0.25)).r,
                              STREAK_EXPONENT);
        streak += audioFreq / (1.0 + abs(df) * STREAK_FALLOFF) * 0.018;

        p += rd * (df + 0.000001 * length(p - a));
        df = f(p, t, cam, h);
    }

    vec3 n = nn(p, t, cam, h);
    float d = length(p - a);
    float occ = ao(p, n, t, cam, h);

    vec3 lightDir = normalize(sin(p.yzx / 5.0 + h.w + vec3(0.14, 0.47, 0.33) * t));
    float z = 2.0 * pow(0.5 + dot(n, normalize(lightDir)) / 2.0, 0.5);

    z *= 1.0 + 0.8 / pow(d + 0.5, 0.6)
        * sin(floor(p * 1.6 + sin(floor(p.yzx * 3.0)) * 3.0)
              + sin(floor(p.zxy * 1.7))).x
        + 0.7 * sin(t * 0.08
            + 4.0 * length(sin(
                floor(p * 3.0 + t * 0.1
                    + sin(floor(p.yzx * 133.0)) * 0.24 / d
                    * sin(t * 0.3 + floor(p.zxy * 0.15)))
                + sin(floor(p.yzx * 7.0))))
            + step(
                length(fract(p.xy * 7.0) - 0.5)
                + 0.6 * sin(length(sin(t * vec2(0.5, 0.7) + floor(p.xy * 7.0)))),
                0.5)
        ) * sin(floor(p.z) * 3.0 + floor(p.x + sin(floor(p.yzx * 15.0))).x);

    z += pow(0.45 + 0.45 * sin(occ * 38.0 + t), 19.0) * (1.0 + bass() * AUDIO_GLOW);

    // Fold streak into glow channel so image-pass Sobel responds to it.
    // streak*streak gives punchy nonlinear response on loud transients.
    float glowOut = g + streak * streak * STREAK_MIX;

    // Pack: lighting, glow+streaks, AO, distance
    fragColor = vec4(z, glowOut, occ, d);
}
