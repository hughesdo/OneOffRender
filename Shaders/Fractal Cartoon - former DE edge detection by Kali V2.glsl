// "Fractal Cartoon" - former "DE edge detection" by Kali
// V2 — smoother audio reactivity
//
// V1 was too jerky because:
//   1. Single FFT bin = maximally spiky, reflects one transient
//   2. tGlobal = iTime * (0.5 + bass*0.35) — the offset grows with iTime,
//      so a bass spike at t=30s shifts the path parameter by ~10 units.
//
// V2 fixes:
//   1. Multi-bin averaging across each band (8 samples) — feels the whole mix
//   2. pow() compression on all band values — quiet passages stay calm
//   3. Additive time offset: tGlobal = iTime*0.5 + energy*0.25
//      The path offset is always ≤0.25 units regardless of elapsed time
//   4. All coefficients scaled down to keep motion subtle

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform sampler2D iChannel0;

out vec4 fragColor;

float gBass, gMid, gHigh, gTreble;
float tGlobal;
#define t tGlobal

#define CLUBBER_R gBass
#define CLUBBER_G gMid
#define CLUBBER_B gHigh
#define CLUBBER_A gTreble

const float iTransition = 1.0;

#define MUSICRAYS    (1.2 * CLUBBER_A)
#define MUSICWAVES   CLUBBER_R
#define MUSICMOD1    (CLUBBER_G / 4.4)
#define MUSICMOD2    (CLUBBER_B / 6.6)
#define MUSICSUNSIZE (length(vec2(CLUBBER_R, CLUBBER_G)))
#define MUSICSUNSPIN (length(vec2(CLUBBER_B, CLUBBER_A)))

//#define SHOWONLYEDGES
#define WAVES

#define RAY_STEPS 150
#define BRIGHTNESS 1.2
#define GAMMA 1.4
#define SATURATION .65
#define detail .001

const vec3 origin = vec3(-1., .7, 0.);
float det = 0.0;

// Average 8 evenly-spaced bins across [lo, hi] — broader = smoother
float bandAvg(float lo, float hi) {
    float s = 0.0, d = (hi - lo) / 7.0;
    s += texture(iChannel0, vec2(lo + 0.0*d, 0.0)).r;
    s += texture(iChannel0, vec2(lo + 1.0*d, 0.0)).r;
    s += texture(iChannel0, vec2(lo + 2.0*d, 0.0)).r;
    s += texture(iChannel0, vec2(lo + 3.0*d, 0.0)).r;
    s += texture(iChannel0, vec2(lo + 4.0*d, 0.0)).r;
    s += texture(iChannel0, vec2(lo + 5.0*d, 0.0)).r;
    s += texture(iChannel0, vec2(lo + 6.0*d, 0.0)).r;
    s += texture(iChannel0, vec2(lo + 7.0*d, 0.0)).r;
    return s / 8.0;
}

mat2 rot(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

vec4 formula(vec4 p) {
    p.xz = abs(p.xz + 1.) - abs(p.xz - 1.2 + MUSICMOD1) - p.xz;
    p.y -= .25;
    p.xy *= rot(radians(35.));
    p = p * 2. / clamp(dot(p.xyz, p.xyz), .2, min(1.05, 0.95 + MUSICMOD2));
    return p;
}

float de(vec3 pos) {
#ifdef WAVES
    pos.y += sin(pos.z - t * 6. + MUSICWAVES) * .15;
#endif
    vec3 tpos = pos;
    tpos.z = abs(3. - mod(tpos.z, 6.));
    vec4 p = vec4(tpos, 1.);
    for (int i = 0; i < 4; i++) { p = formula(p); }
    float fr = (length(max(vec2(0.), p.yz - 1.5)) - 1.) / p.w;
    float ro = max(abs(pos.x + 1.) - .3, pos.y - .35);
          ro = max(ro, -max(abs(pos.x + 1.) - .1, pos.y - .5));
    // Reduced offset scale vs V1 (0.8 instead of 2.0) — less geometry jerk
    pos.z = abs(.25 - mod(pos.z - 0.8 * length(vec2(gBass, gMid)), .5));
          ro = max(ro, -max(abs(pos.z) - .2, pos.y - .3));
          ro = max(ro, -max(abs(pos.z) - .01, -pos.y + .32));
    return min(fr, ro);
}

vec3 path(float ti) {
    ti *= 1.5;
    return vec3(sin(ti), (1. - sin(ti * 2.)) * .5, -ti * 5.) * .33;
}

float edge = 0.;
vec3 normal(vec3 p) {
    vec3 e = vec3(0.0, det * 5., 0.0);
    float d1 = de(p - e.yxx), d2 = de(p + e.yxx);
    float d3 = de(p - e.xyx), d4 = de(p + e.xyx);
    float d5 = de(p - e.xxy), d6 = de(p + e.xxy);
    float d = de(p);
    edge = abs(d - 0.5*(d2+d1)) + abs(d - 0.5*(d4+d3)) + abs(d - 0.5*(d6+d5));
    edge = min(1., pow(edge, .55) * 15.);
    return normalize(vec3(d1-d2, d3-d4, d5-d6));
}

vec3 raymarch(in vec3 from, in vec3 dir) {
    edge = 0.;
    vec3 p, norm;
    float d = 100., totdist = 0.;
    for (int i = 0; i < RAY_STEPS; i++) {
        if (d > det && totdist < 25.0) {
            p = from + totdist * dir;
            d = de(p);
            det = detail * exp(.13 * totdist);
            totdist += d;
        } else { break; }
    }
    vec3 col = vec3(0.);
    p -= (det - d) * dir;
    norm = normal(p);

#ifdef SHOWONLYEDGES
    col = 1. - vec3(edge);
#else
    col = mix(vec3(edge), (1. - abs(norm)) * max(0., 1. - edge * .8), iTransition);
#endif

    totdist = clamp(totdist, 0., 26.);
    dir.y -= .02;
    float sunsize = 7. - MUSICSUNSIZE;
    float an = atan(dir.x, dir.y) + iTime * 1.5 + MUSICSUNSPIN;
    float s  = pow(clamp(1.0 - length(dir.xy)*sunsize - abs(.2-mod(an,.4)), 0., 1.), .1);
    float sb = pow(clamp(1.0 - length(dir.xy)*(sunsize-.2) - abs(.2-mod(an,.4)), 0., 1.), .1);
    float sg = pow(clamp(1.0 - length(dir.xy)*(sunsize - 4.5 - MUSICRAYS) - .5*abs(.2-mod(an,.4)), 0., 1.), 3.);
    float y  = mix(.45, 1.2, pow(smoothstep(0., 1., .75-dir.y), 2.)) * (1. - sb*.5);

    vec3 backg = vec3(0.5, 0., 1.) * iTransition * ((1.-s)*(1.-sg)*y + (1.-sb)*sg*vec3(1.,.8,.15)*3.);
         backg += min(vec3(1.,.9,.1)*s, vec3(iTransition));
         backg = max(backg, sg*vec3(1.,.9,.5));

    col = mix(vec3(1.,.9,.3)*iTransition, col, exp(-.004*totdist*totdist));
    if (totdist > 25.) col = backg;
    col = pow(col, vec3(GAMMA)) * BRIGHTNESS;
    col = mix(vec3(length(col)), col, SATURATION);
#ifdef SHOWONLYEDGES
    col = 1. - vec3(length(col));
#else
    col *= mix(vec3(length(col)), vec3(1.,.9,.85), iTransition);
#endif
    return col;
}

vec3 move(inout vec3 dir) {
    vec3 go    = path(t);
    vec3 adv   = path(t + .7);
    vec3 advec = normalize(adv - go);
    float an = adv.x - go.x;
    an *= min(1., abs(adv.z - go.z)) * sign(adv.z - go.z) * .7;
    dir.xy *= mat2(cos(an), sin(an), -sin(an), cos(an));
    an = advec.y * 1.7;
    dir.yz *= mat2(cos(an), sin(an), -sin(an), cos(an));
    an = atan(advec.x, advec.z);
    dir.xz *= mat2(cos(an), sin(an), -sin(an), cos(an));
    return go;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    // Multi-bin band averages — each covers a broad range, not one spike
    // pow() compression (< 1 exponent) keeps quiet passages calm, loud passages alive
    gBass   = pow(bandAvg(0.02, 0.12), 0.7);  // sub-bass/kick
    gMid    = pow(bandAvg(0.12, 0.35), 0.7);  // low-mid body
    gHigh   = pow(bandAvg(0.35, 0.60), 0.7);  // upper-mid presence
    gTreble = pow(bandAvg(0.60, 0.85), 0.7);  // treble air

    // Full-spectrum energy for camera — widest possible window, most stable
    float fullEnergy = pow(bandAvg(0.02, 0.70), 0.6);

    // ADDITIVE offset instead of multiplicative — offset is always ≤0.25 units,
    // so a transient at t=60s can't teleport the camera the way V1 did.
    tGlobal = iTime * 0.5 + fullEnergy * 0.25;

    vec2 uv = fragCoord.xy / iResolution.xy * 2. - 1.;
    uv.y *= iResolution.y / iResolution.x;
    float fov = .9 - max(0., .7 - iTime * .3);
    vec3 dir  = normalize(vec3(uv * fov, 1.));
    vec3 from = origin + move(dir);
    vec3 color = raymarch(from, dir);
    fragColor = vec4(color, 1.);
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}
