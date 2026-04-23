// https://www.shadertoy.com/view/wfKyz1
// Fiber Bundle by FabriceNeyret2
// Converted to OneOffRender format with subtle audio reactivity

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

void mainImage( out vec4 O, vec2 I ){
    // Multi-bin averages — smoother than single bins
    float bass = (texture(iChannel0, vec2(0.03, 0.0)).r
               + texture(iChannel0, vec2(0.06, 0.0)).r
               + texture(iChannel0, vec2(0.09, 0.0)).r) / 3.0;
    float mid  = (texture(iChannel0, vec2(0.18, 0.0)).r
               + texture(iChannel0, vec2(0.25, 0.0)).r
               + texture(iChannel0, vec2(0.32, 0.0)).r) / 3.0;
    float high = (texture(iChannel0, vec2(0.55, 0.0)).r
               + texture(iChannel0, vec2(0.65, 0.0)).r) / 2.0;

    // Bass drives a π phase flip in the cos palette — same schema,
    // but smoothstep snaps it toward the complementary color state on beats
    float beatPhase = smoothstep(0.25, 0.60, bass) * 3.14159;

    float i, t, v, s;
    for (O*=i; i++<50.; t+=v*.1){
        vec3 p = t*normalize(vec3(I+I,0)-iResolution.xyy);
        p.z += 38.;
        p.xz = mod(p.xz*mat2(cos(p.y*.02+iTime*.2-vec4(0,11,33,0))) -11.,22.)-11.;
        p.y = ceil(p.y);
        v = 5.*max(.03, length(p.xz)-5.);
        for (s=0.; s++<2.; v+=abs(dot(sin(p*s+iTime)/s, vec3(1))));

        // Same cos schema + beat phase flip + high hue drift
        O += (1.+cos(i*.2 + vec4(5,1,3,0) + high*0.4 + beatPhase)) / v;

        // Mid-frequency glow: warm orange halo tightest near cylinder surfaces
        float prox = 0.025 / (v*v + 0.008);
        O.rgb += vec3(1.0, 0.5, 0.08) * prox * mid * 1.5;
    }
    // Tone mapping — bass lifts overall brightness
    O = tanh(O / (5e1 - bass * 10.0));
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}
