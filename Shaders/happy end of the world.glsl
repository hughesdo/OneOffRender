// happy end of the world
// Converted to OneOffRender format with subtle audio reactivity

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

void mainImage( out vec4 O, vec2 I ){
    // Subtle audio: bass lifts glow warmth, highs brighten star density
    float bass = texture(iChannel0, vec2(0.04, 0.0)).r;
    float high = texture(iChannel0, vec2(0.65, 0.0)).r;

    float i, t, v;
    for (O*=i; i++<80.;t+=v*.3){
        vec3 p=t*normalize(vec3(I+I,1)-iResolution.xyy);
        p.xy*=mat2(cos(i+vec4(0,11,33,0)));
        p.z-=iTime;
        p=mod(p,4.)-2.;
        v = (length(p.yz)+length(p.xz))/2.;
        // Color — bass warms the palette, highs push brightness
        O+=exp(sin(t+vec4(0,2,4,0) + bass*0.5))/v/v;
    }
    // Tone mapping — high energy slightly lifts the overall glow
    O = tanh(O*O / (2e4 - high * 3000.0));
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}
