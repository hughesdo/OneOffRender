#version 330 core

// Molten Heart - Audio-reactive raymarching shader with layered effects
// Features dual-layer raymarching with bass and treble reactivity

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// Custom tanh implementation for WebGL
vec4 tanh_approx(vec4 x) {
    vec4 x2 = x * x;
    vec4 x3 = x2 * x;
    vec4 x5 = x3 * x2;
    return x - x3/3.0 + 2.0*x5/15.0;
}

void mainImage(out vec4 O, vec2 I)
{
    float t = iTime;
    float z = 0.0;
    float d = 0.0;
    float s = 0.0;
    float i = 0.0;
    
    // Audio sampling & smoothing
    float bass = 0.0;
    float treble = 0.0;
    
    bass = texture(iChannel0, vec2(0.5, 0.1)).r;
    treble = texture(iChannel0, vec2(0.5, 0.9)).r;
    
    bass = bass * 0.15 + texture(iChannel0, vec2(0.49, 0.05)).r * 0.85;
    treble = treble * 0.15 + texture(iChannel0, vec2(0.49, 0.9)).r * 0.85;
    
    bass = smoothstep(0.0, 1.0, bass * 1.2);
    treble = smoothstep(0.0, 1.0, treble * 0.75);
    
    // Background (Molten Heart) setup
    float baseRadius_bg = 3.0 + bass * 0.74;
    float ringWidth_bg = 0.1 + bass * 0.025;
    
    vec4 colorShift_bg = vec4(
        3.0,
        8.5 + treble * 0.03,
        1.0 + treble * 0.05,
        0.0
    );
    
    vec4 O_bg = vec4(0.0);
    
    // Background raymarching
    i = 0.0;
    for(int iter = 0; iter < 50; iter++)
    {
        vec3 p = z * normalize(vec3(I + I, 0.0) - vec3(iResolution.xy, iResolution.y));
        p.z += 5.0;
        
        vec3 a = normalize(cos(vec3(5.0, 0.0, 1.0) + t * 0.1 - d * 4.0));
        a = a * dot(a, p) - cross(a, p);
        
        d = 1.0;
        for(int d_iter = 0; d_iter < 8; d_iter++)
        {
            a -= sin(a * d + t).zxy / d + bass * 0.015;
            a += sin(a * d + t).zxy / d + 0.1 + bass * 0.045;
            d += 1.0;
        }
        
        float ringDist = ringWidth_bg * abs(length(p) - 3.8);
        s = length(a) - baseRadius_bg - sin(texture(iChannel0, vec2(1.0, s) * 0.1).r / 0.1);
        float sphereDist = 0.01 * abs(cos(s));
        
        d = ringDist + sphereDist;
        z += d;
        
        O_bg += (cos(s + colorShift_bg) + 1.0) / d;
        i += 1.0;
    }
    
    // Apply tonemapping to background using custom tanh
    O_bg = tanh_approx(O_bg / 5000.0);
    
    // Foreground (Speak) setup
    float baseRadius_fg = 3.0 + bass * 0.6;
    float sphereThickness_fg = 0.1 + bass * 0.02;
    
    vec4 colorShift_fg = vec4(
        6.0,
        1.0 + treble * 0.04,
        2.0 + treble * 0.06,
        0.0
    );
    
    vec4 O_fg = vec4(0.0);
    z = 0.0;
    
    // Foreground raymarching
    i = 0.0;
    for(int iter = 0; iter < 60; iter++)
    {
        vec3 p = z * normalize(vec3(I + I, 0.0) - vec3(iResolution.xy, iResolution.y));
        vec3 a = normalize(cos(vec3(0.0, 2.0, 4.0) + t + 0.1 * i));
        p.z += 7.0;
        a = a * dot(a, p) - cross(a, p);
        
        d = 0.6;
        for(int d_iter = 0; d_iter < 4; d_iter++) {
            a -= cos(a * d + t - 0.1 * i).zxy / d + bass * 0.1;
            d *= 2.0;
            if(d >= 9.0) break;
        }
        
        s = length(a) - baseRadius_fg - sin(texture(iChannel0, vec2(1.0, s) * 0.1).r / 0.1);
        d = sphereThickness_fg * abs(s);
        z += d;
        
        O_fg += (cos(i * 0.1 + t + colorShift_fg) + 1.0) / d;
        i += 1.0;
    }
    
    // Apply tonemapping to foreground using custom tanh
    O_fg = tanh_approx(O_fg / 3000.0);
    
    // Layer blending & final output
    float alpha = min(length(O_fg), 1.0);
    O = O_bg * (1.0 - alpha) + O_fg;
    O *= 1.0 + bass * 0.2;
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
