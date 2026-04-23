// https://www.shadertoy.com/view/NfsGDN
// Fusion Reactor OldEclipse
// Converted to OneOffRender format with audio reactivity

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

// ===== AUDIO REACTIVITY TWEAKS =====
#define AUDIO_ROTATION_BOOST 0.4   // How much bass speeds up layer rotation
#define AUDIO_GLOW_BOOST     3.0   // How much bass pumps glow accumulation
#define AUDIO_COLOR_SHIFT    0.5   // How much mids shift the color phase
#define AUDIO_CARVE_DEPTH    0.15  // How much highs affect carving depth

// Audio helpers
float getBass()  { return (texture(iChannel0, vec2(0.02, 0.0)).x + texture(iChannel0, vec2(0.05, 0.0)).x) * 0.5; }
float getMid()   { return (texture(iChannel0, vec2(0.15, 0.0)).x + texture(iChannel0, vec2(0.25, 0.0)).x) * 0.5; }
float getHigh()  { return (texture(iChannel0, vec2(0.5, 0.0)).x  + texture(iChannel0, vec2(0.7, 0.0)).x)  * 0.5; }

void mainImage( out vec4 O, vec2 I ){
    // Audio sampling
    float bass = getBass();
    float mid  = getMid();
    float high = getHigh();

    vec3 p, q, r = normalize(vec3(I+I,0) - iResolution.xyy);
    float i, j, t, v, s;
    // Raymarching loop, bound maximum step size
    for (O*=i; i++<50.;t+=min(v*.15,1.)){
    p=t*r;

    // Move camera back
    p.z+=2.5;

    // Rotate different amount each y layer — bass speeds rotation
    float rotSpeed = (sin(round(p.y*3.)*2.)+.2) * (1.0 + bass * AUDIO_ROTATION_BOOST);
    p.xz*=mat2(cos(rotSpeed*iTime+vec4(0,11,33,0)));

    // Start with density based on solid hyperboloid
    q=p*p;
    s=q.x+q.z-q.y;
    v = max(s-1.,.01);

    // Add two hyperboloid surfaces
    v = min(v,abs(s-2.)+.001);
    v = min(v,abs(s-7.)+.001);

    // Repeatedly carve cube shells out of structure — highs affect carving
    float carveSize = 0.2 + high * AUDIO_CARVE_DEPTH;
    s=1.;
    for(j=0.;j++<6.;){
        p*=1.5;
        s*=1.5;
        q=abs(mod(p-1.,2.)-1.);
        v=max(v,(carveSize-abs(.6-max(max(q.x,q.y),q.z)))/s);
    }

    // Color accumulation — bass pumps glow, mids shift color phase
    float glowMul = 1.0 + bass * AUDIO_GLOW_BOOST;
    O += glowMul * exp(cos(t + mid * AUDIO_COLOR_SHIFT + vec4(0,.5,1.5,0))) / sqrt(v);
    }
    // Tone mapping
    O=tanh(O*O/4e4);
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}