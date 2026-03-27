#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    float i, s = 14.;
    vec4 q, l;
    
    // Audio reactivity
    float bass = texture(iChannel0, vec2(0.05, 0.0)).x;
    float mid = texture(iChannel0, vec2(0.3, 0.0)).x;
    float high = texture(iChannel0, vec2(0.7, 0.0)).x;
    
    float pulse = 1.0 + bass * 0.5;
    float timeOffset = iTime + mid * 2.0;
    
    fragColor = vec4(0.0);
    for(fragColor *= i; i++ < 11.; s *= .8, fragColor += sin(l * vec4(3,2,1,1) + i * .7) / s, l /= 4.)
        q.xy = sin(timeOffset + s * fragCoord / iResolution.y * pulse + q.yx * 2.),
        l += .1 / max(dot(q = sin(q), q * 4.), .1);

    fragColor = tanh(fragColor * fragColor * (1.0 + high * 0.3));
}