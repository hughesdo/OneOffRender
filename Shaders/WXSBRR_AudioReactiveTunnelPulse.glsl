#version 330 core

// Audio Reactive Tunnel Pulse
// Created by OneHung
// https://www.shadertoy.com/view/WXSBRR

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

#define PI 3.14159265

float bass()    { return texture(iChannel0, vec2(0.02, 0.25)).x; }
float mid()     { return texture(iChannel0, vec2(0.15, 0.25)).x; }
float treble()  { return texture(iChannel0, vec2(0.5, 0.25)).x; }

vec3 palette(float t) {
    vec3 a = vec3(0.45);
    vec3 b = vec3(0.45);
    vec3 c = vec3(1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    vec2 uv0 = uv;
    vec3 finalColor = vec3(0.0);
    
    float t = iTime * 0.5;
    float b = bass() * 3.0;
    float m = mid() * 2.0;
    float h = treble() * 2.0;
    
    vec3 base = vec3(0.0, 0.84, 0.0);
    
    for (float i = 0.0; i < 3.0; i++) {
        uv = fract(uv * 1.5) - 0.5;
        float d = length(uv) * exp(-length(uv0));
        float a = atan(uv.y, uv.x);
        
        float rings = sin(d * 8.0 - t * 2.0 + b * 3.0) * 0.5 + 0.5;
        rings *= sin(d * 4.0 + t + m * 2.0) * 0.5 + 0.5;
        float segments = sin(a * 8.0 + t + m * 4.0) * 0.5 + 0.5;
        float pattern = rings * segments;
        pattern = pow(pattern, 0.9 - b * 0.2);
        
        vec3 col = palette(d * 2.0 + i * 0.4 + t * 0.2 + b * 0.5);
        pattern /= (d * d + 0.5);
        pattern += h * 0.4 * exp(-d * 4.0);
        
        finalColor += col * pattern;
    }
    
    float centerGlow = 1.0 / (length(uv0) * 2.0 + 1.0);
    centerGlow = pow(centerGlow, 3.0) * (1.0 + b * 1.5);
    finalColor += vec3(centerGlow) * palette(t);
    
    float vignette = 1.0 - length(uv0) * 0.3;
    finalColor *= vignette;
    
    finalColor = pow(finalColor, vec3(1.1));
    finalColor = mix(base, finalColor, 0.85);
    
    fragColor = vec4(finalColor, 1.0);
}

