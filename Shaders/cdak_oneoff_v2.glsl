// cdak_oneoff_v2 — Image pass (Sobel edges + MusicCave streak composite)
// iChannel0 = Buffer A output: vec4(lighting, glow+streaks, AO, distance)
//
// V2: push harder — more intense Sobel edge lines, warm streak tint on bright
// glow regions, stronger tone contrast. MusicCave streaks are folded into the
// glow channel by Buffer A, so the Sobel kernel naturally fires harder on loud
// transients — edge lines flare up with the music.

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;  // Buffer A

// ============================================================
// TWEAKABLE
// ============================================================
// V2 edge colors: pushed more saturated than V1
#define EDGE_COLOR_H  vec3(0.30, 0.02, 1.4)   // more blue/violet horizontal
#define EDGE_COLOR_V  vec3(0.02, 0.80, 1.4)   // more cyan vertical

#define GAMMA_CURVE   vec3(1.8, 1.2, 1.1)
#define EXPOSURE      2.0                      // slightly brighter than V1

// Streak tint in image pass (warm orange overlay on bright glow pixels)
#define STREAK_TINT   vec3(1.6, 1.1, 0.65)
#define STREAK_SCALE  14.0

// ============================================================
// Depth-normalised sample from Buffer A
// ============================================================
vec3 sampleBuf(vec2 uv) {
    vec4 c = texture(iChannel0, uv);
    vec3 d = vec3(3.0) / pow(max(c.w, 0.001), 0.15);
    return clamp(c.x / d, 0.0, 1.0) * d;
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    float t = max(iTime, 0.001);
    vec2 uv = fragCoord / iResolution.xy;

    vec4 raw = texture(iChannel0, uv);
    float lighting = raw.x;
    float glow     = raw.y;   // includes MusicCave streak energy from Buffer A
    float occ      = raw.z;
    float dist     = raw.w;

    // Adaptive kernel — wider blur on bright glow (streaks make this expand on beats)
    vec2 kw = (4e-4 / iResolution.xy) * iResolution.x
            / pow(dist + 0.03, 0.5)
            * (pow(glow, 2.0) + 0.1);

    // 3×3 Sobel
    vec3 e = vec3(1.0, -1.0, 0.0);
    vec3 s11 = sampleBuf(uv + kw * e.yy);
    vec3 s12 = sampleBuf(uv + kw * e.zy);
    vec3 s13 = sampleBuf(uv + kw * e.xy);
    vec3 s21 = sampleBuf(uv + kw * e.yz);
    vec3 s23 = sampleBuf(uv + kw * e.xz);
    vec3 s31 = sampleBuf(uv + kw * e.yx);
    vec3 s32 = sampleBuf(uv + kw * e.zx);
    vec3 s33 = sampleBuf(uv + kw * e.xx);

    vec3 gx = s13 + 2.0 * s23 + s33 - (s11 + 2.0 * s21 + s31);
    vec3 gy = s11 + 2.0 * s12 + s13 - (s31 + 2.0 * s32 + s33);

    // Edge magnitude — V2 uses slightly higher scale for more visible lines
    vec3 edgeCol = clamp(
        pow(sqrt(gx * gx * EDGE_COLOR_H + gy * gy * EDGE_COLOR_V), vec3(0.5))
        * 0.55 / pow(dist, 0.3),
        0.0, 1.0
    );

    // Combine: Sobel edges + volumetric glow term
    // glow is already carrying streak energy, so this naturally
    // brightens on loud transients without extra audio access
    vec3 col = (edgeCol + glow * glow * 14.0 / pow(dist + 0.5, 0.6))
             * pow(occ, 1.1) * 1.04;

    // Distance fog
    col = mix(col, vec3(0.0), clamp(dist / 110.0 - 0.1, 0.0, 1.0));

    // Tone curve
    vec3 toneExp = EXPOSURE * GAMMA_CURVE - 1.0
                 + 9.0 / t
                 + 0.1 / (pow(vec3(lighting * 0.4), vec3(3.0, 4.0, 3.0)) + 0.05);
    col = pow(
        max(col + clamp(1.0 - col, 0.0, 1.0) * glow, 0.001),
        toneExp
    ) * 2.0;

    // Warm streak overlay — applied after tone so it punches through.
    // glow² gives the nonlinear "flare on loud beats" character from MusicCave.
    col += glow * glow * STREAK_SCALE * STREAK_TINT;

    fragColor = vec4(col, 1.0);
}
