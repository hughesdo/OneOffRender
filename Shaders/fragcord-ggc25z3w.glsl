// fragcord-ggc25z3w - Layered Disc Glow
// Converted to OneOffRender format with audio-reactive glow & color

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

// ===== AUDIO REACTIVITY TWEAKS =====
#define AUDIO_GLOW_BOOST    2.5   // How much bass pumps the glow intensity
#define AUDIO_COLOR_SHIFT   0.4   // How much mids shift the color gradient
#define AUDIO_BRIGHTNESS    0.5   // How much overall brightness responds to bass
#define AUDIO_RIDGE_BOOST   1.5   // How much highs amplify ridge detail

// Audio helpers
float getBass()  { return (texture(iChannel0, vec2(0.02, 0.0)).x + texture(iChannel0, vec2(0.05, 0.0)).x) * 0.5; }
float getMid()   { return (texture(iChannel0, vec2(0.15, 0.0)).x + texture(iChannel0, vec2(0.25, 0.0)).x) * 0.5; }
float getHigh()  { return (texture(iChannel0, vec2(0.5, 0.0)).x  + texture(iChannel0, vec2(0.7, 0.0)).x)  * 0.5; }

//Light mode
#define LIGHT 0.0

//Overall scale
#define SCALE 0.05
//Overall brightness
#define BRIGHTNESS 0.1

//Gradient colors
#define COL1 vec3(1.00, 0.05, 0.01)
#define COL2 vec3(0.01, 0.03, 1.00)

//Disc radius
#define RAD 0.7

//Yaw angle (radians)
#define YAW (0.5*iTime)
//Pitch angle (radians)
#define PITCH (0.7+0.3*sin(iTime))
//Perspective ratio
#define PER sin(PITCH)
//Base rotation angle
#define ANGLE 0.2

//Number of layers
#define LAYERS 5.0
//Toggle layer shift (shifting factor)
#define LAYER_SHIFT 1.618
//Toggle layer spacing (spacing factor)
#define LAYER_SPACE 0.3

//Half pi
#define HPI 1.5707963268

//White noise function (1D in, 1D out)
float w1(float p)
{
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}
//White noise function (2D in, 1D out)
float w1(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
//White noise function (2D in, 2D out)
vec2 w2(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);

}
//Bi-cubic value noise (1D in, 1D out)
float v1(float p)
{
    float f = floor(p);
    float s = smoothstep(f, f + 1.0, p);

    return mix(w1(f), w1(f + 1.0), s);
}
//Bi-cubic value noise (2D in, 1D out)
float v1(vec2 p)
{
    vec2 f = floor(p);
    vec2 s = smoothstep(f, f + 1.0, p);

    return mix(mix(w1(f), w1(f + vec2(1, 0)), s.x),
    mix(w1(f + vec2(0, 1)), w1(f + 1.0), s.x), s.y);
}

//2D rotation function
mat2 rotate2d(float a)
{
    return mat2(cos(a + vec4(0, -HPI, HPI, 0)));
}

//Color sample function — audio-enhanced
vec3 color(vec2 p, float bass, float mid, float high)
{
    float rad = length(p);
    float ring = rad - RAD;

    float r = max(rad, sqrt(rad));
    float rays = v1(p / r * 8.0 + iTime * 0.3) * v1(p / r * 13.0 - iTime * 0.3);
    float glw = 1.4 / (0.2 * max(1.0 - rays, 0.0) + 1.5 * max(ring, -ring * 8.0));
    glw *= glw;
    glw *= (1.0 + bass * AUDIO_GLOW_BOOST); // Audio: bass pumps glow

    float ridges = v1(rotate2d(rad * 3.0) * p) * 0.4 +
    v1(rotate2d(rad * 2.5) * p * 2.0 + 9.0) * 0.3 +
    v1(rotate2d(rad * 2.0) * p * 4.0 - 9.0) * 0.2 +
    v1(rotate2d(rad * 1.5) * p * 5.0 + 3.0) * 0.1;

    ridges *= ridges * ridges;
    ridges *= (1.0 + high * AUDIO_RIDGE_BOOST); // Audio: highs sharpen ridges

    // Audio: mids shift gradient position
    float grad = tanh(p.x - 1.0 + mid * AUDIO_COLOR_SHIFT) * 0.5 + 0.5;
    vec3 dark = mix(COL1, COL2, grad) * glw * ridges;
    vec3 light = mix(COL1, COL2, grad) / glw;
    light *= 20.0 * ridges;
    return mix(dark, light, LIGHT);
}

void mainImage(out vec4 O, in vec2 frag_coord)
{
    // Audio sampling
    float bass = getBass();
    float mid  = getMid();
    float high = getHigh();

    vec2 suv = (2.0 * frag_coord - iResolution.xy) / iResolution.y;

    suv *= rotate2d(ANGLE);
    suv.y /= PER;

    float texel = SCALE * iResolution.y;

    vec3 col = vec3(0.0);

    vec2 c = suv / SCALE;
    float spa = 1.0;

    mat2 gold = mat2(0.22252093, -0.97492791, 0.97492791, 0.22252093);
    mat2 orient = rotate2d(YAW);
    mat2 base = orient;
    vec2 disc = suv * orient;
    float w = 0.5;

    float rad = length(suv);
    float glw = 2.0 / (0.2 + abs(rad * rad - 1.0));
    vec3 cola = color(disc, bass, mid, high);

    vec2 par = 2.0 * rotate2d(ANGLE)[1];
    for (float i = 0.5 / LAYERS; i < 1.0; i += 1.0 / LAYERS)
    {
        orient *= gold;
        vec2 p = (c - par * (i - 0.5)) * orient;
        p += LAYER_SHIFT * i;
        spa += LAYER_SPACE;
        p /= spa;

        vec2 cell = round(p / 2.0);
        float dof = tanh(0.2 + 0.1 * abs(orient * cell).y);
        float r = 0.4 * dof;
        vec2 sub = (p - cell * 2.0);
        vec2 off = w2(cell) * 2.0 - 1.0;
        off = cos(off.x * 6.2831 + vec2(0, HPI)) * (w - r);
        sub = orient * sub * vec2(1, PER) + orient * off;
        float len = length(sub);
        float att = clamp((r - len) * 10.0 + 0.5, 0.0, 1.0);
        vec3 colc = color((orient * (cell + off * 4.0) * base * 2.0) * spa * SCALE, bass, mid, high);
        colc *= smoothstep(0.0, 0.1, rad - RAD);

        float f = fract(v1(orient * cell * base * spa * 0.2) * 4.0 - 0.1 * iTime);
        f *= f * min((1.0 - f) * 4e1, 1.0);
        col += f * colc * att *
        smoothstep(1.6, -1.0, dot(sub / r, normalize(orient * cell + 0.1)));
    }
    col += cola;

    // Audio: overall brightness boost
    col *= (1.0 + bass * AUDIO_BRIGHTNESS);

    O = vec4(sqrt(tanh(col)), 1);
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}