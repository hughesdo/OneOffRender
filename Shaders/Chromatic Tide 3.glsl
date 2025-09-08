#version 330 core

// Chromatic Tide — radial tides and gentle interference (Audio Reactive)
// Influences acknowledged: ideas from Inigo Quilez (distance/polar play), P_Malin (color intent), BigWings (animated pattern layering). Original implementation.

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

const float PI2 = 6.28318530718;
mat2 r2(float a){ 
    float s=sin(a), c=cos(a); 
    return mat2(c,-s,s,c); 
}
vec3 pal2(float t, vec3 A, vec3 B, vec3 C, vec3 D){
    return A + B*cos(PI2*(C*t + D));
}
void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec2 uv = (fragCoord - 0.5*iResolution.xy)/iResolution.y;
    
    // audio reactive element - subtle frequency modulation
    float audio = texture(iChannel0, vec2(0.1, 0.25)).x;
    float audioSmooth = texture(iChannel0, vec2(0.05, 0.25)).x;
    
    // Center point (no mouse interaction in OneOffRender)
    vec2 center = vec2(0.0);
    vec2 q = uv - center;
    
    // gentle scene rotation with subtle audio influence on rotation rate
    q = r2(0.07*sin(iTime*0.13 + audioSmooth*0.3)) * q;
    
    float r = length(q);
    float ang = atan(q.y, q.x);
    
    // domain warp: subtle swirl and breathing with audio-reactive interference
    float swirl = 0.15 * sin(ang*3.0 + iTime*0.9) * exp(-r*1.6);
    // audio creates subtle spatial distortion in the wave pattern
    float audioWarp = 0.02 * audio * sin(r*15.0 + ang*2.0 + iTime*2.0);
    float wr = r + swirl + audioWarp + 0.05*sin(6.0*r - iTime*0.8) + 0.03*sin(4.0*ang + iTime*0.6);
    
    // two interleaved patterns with audio-modulated ring frequency
    float ringFreq = 30.0 + audio * 8.0; // subtle frequency shift based on audio
    float rings = 0.5 + 0.5*sin(ringFreq*wr - iTime*1.1);
    float fans  = 0.5 + 0.5*sin(4.0*ang + r*5.0 + iTime*0.35);
    // audio affects the blend between ring and fan patterns
    float blendAmount = 0.42 + audio * 0.15;
    float tide  = mix(rings, fans, blendAmount);
    
    // color palette: azure-magenta-amber orbit, balanced
    vec3 A = vec3(0.48,0.46,0.47);
    vec3 B = vec3(0.42,0.50,0.57);
    vec3 C = vec3(1.00,0.52,0.26);
    // subtle turbulence on D color component
    float turbulence = 0.09 * sin(r*12.0 + ang*4.0 + iTime*1.7) * sin(r*8.0 - ang*2.0 + iTime*2.3);
    vec3 D = vec3(0.00,0.22,0.61) + vec3(turbulence*0.5, turbulence, turbulence*1.2);
    vec3 col = pal2(tide + 0.1*sin(ang + iTime*0.2), A,B,C,D);
    
    // soft caustic-like brightening along ring crests with audio enhancement
    float ridgeFreq = 20.0 + audioSmooth * 5.0;
    float ridge = pow(0.5 + 0.5*sin(ridgeFreq*wr - iTime*0.9), 6.0);
    // audio boosts the ridge intensity slightly
    col += ridge * vec3(0.25,0.35,0.45) * (1.0 + audio * 0.4);
    
    // radial fade for meditative center focus
    float fade = exp(-r*0.85);
    col *= fade*1.25 + 0.15;
    
    // vignette
    float vig = 1.0 - 0.25*pow(length(uv), 1.25);
    col *= vig;
    
    // soft clamp
    col = clamp(tanh(col), 0.0, 1.0);
    fragColor = vec4(col,1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}