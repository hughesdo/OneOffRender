// https://www.shadertoy.com/view/7cBSDR
// Hard-Wired by OldEclipse
// Converted to OneOffRender format with subtle audio reactivity

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0; // Audio FFT (512x2: row 0 = FFT, row 1 = waveform)

out vec4 fragColor;

void mainImage( out vec4 O, vec2 I ){
    // Subtle audio: bass lifts glow, highs nudge color phase
    float bass = texture(iChannel0, vec2(0.04, 0.0)).r;
    float high = texture(iChannel0, vec2(0.60, 0.0)).r;

    vec3 a, p, q, r = normalize(vec3(I+I,0) - iResolution.xyy);
    float i, t, v, l;
    for (O*=i;i++<50.;t+=v*min(l,1.)*.8){
        p = t*r;
        p.z+=.1;
        p = dot(a=normalize(sin(iTime*.05+vec3(3,2,0))),p)*2.*a-p;
        q=p/=l=dot(p,p);
        p=round(p*24.)/24.;
        p.xy = abs(mod(p.xy-2., 4.) -2.)-1.+.6*vec2(cos(p.z/3.),cos(p.z/2.));
        v = abs(length(p.xy)-.2)+.01;
        // Color accumulation — highs add a subtle hue shift
        O+=1./v/(abs(sin(q.z*.5-iTime+vec4(0,.2,.4,0) + high*0.3))+.1)*exp(-t);
    }
    // Tone mapping — bass gently lifts luminance
    O = tanh(O / (2e3 - bass * 300.0));
}

void main() {
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    mainImage(fragColor, fragCoord);
}
