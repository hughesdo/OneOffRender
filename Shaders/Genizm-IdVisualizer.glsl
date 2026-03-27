#version 330 core
// Original author: gurudevbk
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/7ldyzN
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format
uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture
out vec4 fragColor;

#define freq(f) texture(iChannel0, vec2(f, 0.25)).x * 0.8

float avgFreq(float start, float end, float step) {
    float div = 0.0;
    float total = 0.0;
    for (float pos = start; pos < end; pos += step) {
        div += 1.0;
        total += freq(pos);
    }
    return total / div;
}

void main()
{
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;
    
    float bassFreq = pow(avgFreq(0.0, 0.1, 0.01), 0.85);
    float medFreq = pow(avgFreq(0.1, 0.6, 0.01), 0.85);
    float topFreq = pow(avgFreq(0.6, 1.0, 0.01), 0.85);
    
    float aspect = (iResolution.y/iResolution.x);
    float value;
    
    vec2 uv = fragCoord / iResolution;
    uv -= vec2(0.5, 0.5*aspect);
    
    // FIXED: Changed from "uv *= -0.01*iTime;" to proper zoom/rotation animation
    uv *= (1.0 + 0.01*sin(iTime*0.5));  // Gentle zoom animation
    
    float rot = radians(45.0); // radians(45.0*sin(medFreq*iTime));
    mat2 m = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
    uv = m * uv;
    
    uv += vec2(0.5, 0.5*aspect);
    uv.y += 0.5*(1.0-aspect);
    
    vec2 pos = 10.0*uv;
    vec2 rep = fract(pos);
    float dist = 2.0*min(min(rep.x, 1.0-rep.x), min(rep.y, 1.0-rep.y));
    float squareDist = length((floor(pos)+vec2(0.5)) - vec2(5.0));
    
    float edge = sin(medFreq+iTime-squareDist*0.5)*0.5+0.5;
    edge = (bassFreq+medFreq+sin(iTime)-squareDist*iTime*0.5)*0.3;
    edge += .2*medFreq;
    edge = 2.0*fract(edge*0.5);
    
    value = fract(dist*2.0);
    value = mix(value, 1.0-value, step(1.0, edge));
    
    edge = pow(abs(1.0-edge), 2.0);
    value = smoothstep(edge-0.05, edge, 0.95*value);
    value += squareDist*.1;
    
    fragColor = vec4(value);
    fragColor = mix(vec4(1.0,1.0,1.0,1.0),
                    vec4(0.5*value*topFreq,
                         0.5*medFreq,
                         .5*value*bassFreq,1.0),
                         value);
}
