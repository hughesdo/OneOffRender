// https://www.shadertoy.com/view/scXSDj
// Futureshock Seek & Destroy Diatribes
// Converted to OneOffRender format with audio reactivity

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

// ===== AUDIO REACTIVITY TWEAKS =====
#define AUDIO_SPEED_BOOST    0.3   // How much bass speeds the camera fly-through
#define AUDIO_GLOW_BOOST     2.0   // How much bass pumps volumetric glow
#define AUDIO_LIGHT_FLASH    1.5   // How much mids flash the light accumulation
#define AUDIO_SHAKE_AMP      0.04  // How much bass adds camera shake

// Audio helpers
float getBass()  { return (texture(iChannel0, vec2(0.02, 0.0)).x + texture(iChannel0, vec2(0.05, 0.0)).x) * 0.5; }
float getMid()   { return (texture(iChannel0, vec2(0.15, 0.0)).x + texture(iChannel0, vec2(0.25, 0.0)).x) * 0.5; }

#define T (sin(iTime*.4)/2.+iTime)
#define P(z) (vec3(cos((z)*.02)*1e2, cos((z)*.015)*1e2, (z)))
#define R(a) mat2(cos(a + vec4(0,33,11,0)))
#define N normalize

float box (vec3 p, float i){
    p = i*.41 - abs(fract(p/i)*i - i/2.);
    return min(p.x, min(p.y, p.z));
}

float boxen(vec3 p) {
    float d = -9e9, i = 1e2;
    p *= 5e1;
    for(; i > .1; i *= .3)
        p += cos(p.yzx*4.)/4.,
        d = max(d, box(p, i));
    return d/5e1;
}

float map(vec3 p) {
    vec3 q = abs(p-P(p.z));
    return max(1e1-length(min(.5-q.x, .25-q.y)), max(boxen(p), 1e2*boxen(p.yxz/1e2)));
}

void mainImage(out vec4 o, vec2 u) {
    float s, i;

    // Audio sampling
    float bass = getBass();
    float mid  = getMid();

    vec3 r= vec3(iResolution, 1.0);
    u = (u+u - r.xy) / r.y;
    if(abs(u.x) > 1.4) { o *= i; return; }

    // Audio: bass-triggered shake (replaces the original sin(T)>.8 trigger)
    if(sin(T)>.8 || bass > 0.4) u += sin(T*3e3) * (0.06 + bass * AUDIO_SHAKE_AMP);

    float f = tanh(sin(T)*6.)*.5;
    u *= R(f);

    // Audio: bass subtly speeds the fly-through
    float tAdj = T * (1.0 + bass * AUDIO_SPEED_BOOST);
    vec3  p = P(tAdj*6e1),
          Z = N(P(tAdj*6e1 + 2e1) - p),
          X = N(vec3(Z.z, 0, -Z)),
          D = N(vec3(u, 1) * mat3(-X, cross(X, Z), Z));
    vec2 v = 2e2*(.1*sin(T/1.5))+u + (u.yx*.8+.2-vec2(-1.,.1));

    float glowMul = 1.0 + bass * AUDIO_GLOW_BOOST;
    for(o *= i; i++ < 64.; )
        p += D * s,
        s = map(p) * .8,
        o += glowMul * s/i
          + .2*(vec4(clamp(v.x/2.,v.y,4.),1,2,0))*s,
          +  vec4(4,2,1,0)/ length(v);

    // Audio: mids flash the lights
    vec4 lights = abs(vec4(v.y,2,v.x,0) / dot(cos(T*3.+p/4e1),vec3(1)));
    o += lights * (1.0 + mid * AUDIO_LIGHT_FLASH);

    o = tanh(o / 1e2);
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}