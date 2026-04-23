// https://www.shadertoy.com/view/7ffSRs
// Lost in the Infinite OldEclipse
// Converted to OneOffRender format with audio reactivity

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

// ===== AUDIO REACTIVITY TWEAKS =====
#define AUDIO_ROTATION_BOOST 0.3   // How much bass speeds the rotation axis shift
#define AUDIO_GLOW_BOOST     2.5   // How much bass pumps color accumulation
#define AUDIO_COLOR_SHIFT    0.8   // How much mids shift the color phase
#define AUDIO_SPHERE_PULSE   0.06  // How much bass pulses the sphere radius

// Audio helpers
float getBass()  { return (texture(iChannel0, vec2(0.02, 0.0)).x + texture(iChannel0, vec2(0.05, 0.0)).x) * 0.5; }
float getMid()   { return (texture(iChannel0, vec2(0.15, 0.0)).x + texture(iChannel0, vec2(0.25, 0.0)).x) * 0.5; }

void mainImage( out vec4 O, vec2 I ){
    // Audio sampling
    float bass = getBass();
    float mid  = getMid();

    vec3 p, a, r = normalize(vec3(I+I,0) - iResolution.xyy);
    float i, t, v;
    // Raymarching loop
    for (O*=i; i++<80.;t+=v*.2){
    p=t*r;
    // Rotation around axis — bass speeds the rotation
    float rotSpeed = iTime * (0.1 + bass * AUDIO_ROTATION_BOOST * 0.1);
    p = dot(a=normalize(sin(rotSpeed+i*.1+vec3(3,1,0))),p)*2.*a-p;
    // Move forward
    p.z+=14.;
    // Angular repetition in xz plane
    p.xz=length(p.xz)*vec2(cos(p.z=mod(atan(p.z,p.x),.4)-.2), sin(p.z));
    // Radial repetition in xz plane and repetition in y plane
    p.xy=mod(p.xy,1.)-.5;
    // Density — bass pulses the sphere radius
    float sphereR = 0.1 + bass * AUDIO_SPHERE_PULSE;
    v=abs(length(p)-sphereR)+.01;
    // Color accumulation — bass pumps glow, mids shift color
    float glowMul = 1.0 + bass * AUDIO_GLOW_BOOST;
    O += glowMul * exp(sin(i*.3 + iTime + mid * AUDIO_COLOR_SHIFT + vec4(0,1,3,0))) / v;
    }
    // Tone mapping
    O = tanh(O*O/2e4);
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}