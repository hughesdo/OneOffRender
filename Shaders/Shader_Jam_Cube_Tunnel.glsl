#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

// Shader Jam - Cube Tunnel
// Original Bonzomatic Shader
// https://gist.github.com/gam0022/b09b6e4c89262d55a88632456f0ef535

float fft(float d) { return texture(iChannel0, vec2(fract(d), 0.25)).r * 0.4; }
#define time iTime
float beat, bpm, beatTau, beatPhase;

#define VOL 0.
#define SOL 1.
#define PI acos(-1.)
#define TAU (2. * PI)
#define saturate(x) clamp(x, 0., 1.)

vec3 pal(float x) { return 0.5 + 0.5 * cos(TAU * (x + vec3(0, 0.333, 0.666))); }

void U(inout vec4 m, float d, float a, float b, float c) { m = (d < m.x) ? vec4(d, a, b, c) : m; }

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(0., max(q.x, max(q.y, q.z)));
}

void rot(inout vec2 p, float x) { p = mat2(cos(x), sin(x), -sin(x), cos(x)) * p; }

float phase(float x) { return floor(x) + 0.5 + 0.5 * cos(PI * exp(-5. * fract(x))); }

vec3 target;

vec4 map(vec3 p) {
    vec4 m = vec4(1, VOL, 0, 0);
    vec3 pos = p;

    float a = 15.;
    p = mod(p, a) - 0.5 * a;

    vec3 of = vec3(1.5);
    vec3 ro = vec3(0.34 - 0.02 * sin(TAU * phase(beat) / 4.), 0.3, 0.3);
    p -= of;

    for (int i = 0; i < 5; i++) {
        p = abs(p + of) - of;
        rot(p.xz, ro.x * TAU);
        rot(p.yx, ro.y * TAU);
        rot(p.zy, ro.z * TAU);
    }

    float hue = 0.9 + pos.z;
    if (mod(beat, 16.) < 8.) hue = 0.9;
    float emi = saturate(cos(TAU * (beat / 2. + pos.z / 32.)));

    U(m, sdBox(p, vec3(1)), SOL, 0., 1.);
    U(m, sdBox(p, vec3(0.1, 1.1, 1.1)), VOL, hue, emi);
    U(m, sdBox(p, vec3(1.1, 1.1, 0.1)), VOL, hue + 0.5, emi);

    vec3 p2 = pos - target;

    of = vec3(0.3);
    ro = vec3(0.34 - 0.2 * sin(TAU * phase(beat) / 4.), 0.3, 0.3);

    for (int i = 0; i < 2; i++) {
        p2 = abs(p2 + of) - of;
        rot(p2.xz, ro.x * TAU);
        rot(p2.yx, ro.y * TAU);
        rot(p2.zy, ro.z * TAU);
    }

    float s = 0.4 + clamp(fft(0.1) * 10., 0., 2.);
    hue = beat / 8.;
    emi = fft(0.1) * 10.;
    U(m, sdBox(p2, s * vec3(1)), SOL, beat / 8., 1.);
    U(m, sdBox(p2, s * vec3(0.1, 1.1, 1.1)), VOL, hue + 0.5, emi);
    U(m, sdBox(p2, s * vec3(1.1, 1.1, 0.1)), VOL, hue + 0.0, emi);

    return m;
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;
    
    vec2 uv = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
    uv -= 0.5;
    uv /= vec2(iResolution.y / iResolution.x, 1);

    bpm = 130.;
    beat = bpm * time / 60.;
    beatTau = beat * TAU;

    vec3 col = vec3(0);

    vec3 ro, ray;
    target = ro + vec3(0., 0., beat * 2.);

    if (mod(beat, 16.) < 4.) {
        ro = target + vec3(0, 0, -10);
        ray = vec3(uv, 0.3);
    } else {
        float a = 6.;
        ro = target + vec3(a * cos(beatTau / 32.), 2. * sin(beatTau / 16.), a * sin(beatTau / 32.));
        vec3 up = vec3(0, 1, 0);
        vec3 fwd = normalize(target - ro);
        vec3 right = normalize(cross(up, fwd));
        up = normalize(cross(fwd, right));
        ray = normalize(uv.x * right + uv.y * up + fwd * 0.3);
    }

    float t, d;
    for (int i = 0; i < 300; i++) {
        vec3 p = ro + ray * t;
        vec4 m = map(p);
        d = m.x;

        if (m.y == VOL) {
            col += clamp(0.01 * m.w * pal(m.z) / abs(d), 0.0, 0.3);
            t += 0.25 * abs(d) + 0.01;
        } else {
            if (d < 0.01) {
                col += 0.01 * float(i);
                break;
            }

            t += d;
        }
    }

    col = mix(vec3(0), col, exp(-0.1 * t));
    col = saturate(col);
    vec2 uv2 = abs(uv);
    float hue = beat / 8.;
    col += pal(hue) * clamp((fft(uv2.y * 0.2) - uv2.x), 0., 1.);
    col += pal(hue + 0.5) * clamp((fft(uv2.y * 0.3) - uv2.x), 0., 1.);

    fragColor = vec4(col, 1);
}

