#version 330 core

// semifinal2-tapped - OneOffRender Version
// Converted from demoscene format to OneOffRender

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

const float PI = 3.14159;

// Audio-reactive functions
float getFFT(float freq) {
    return texture(iChannel0, vec2(freq, 0.0)).r;
}

float getFFTSmoothed(float freq) {
    float sum = 0.0;
    float samples = 5.0;
    for(float i = 0.0; i < samples; i++) {
        float offset = (i - samples * 0.5) * 0.02;
        sum += texture(iChannel0, vec2(clamp(freq + offset, 0.0, 1.0), 0.0)).r;
    }
    return sum / samples;
}

// Procedural Perlin noise replacement
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float smoothNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = noise(i);
    float b = noise(i + vec2(1.0, 0.0));
    float c = noise(i + vec2(0.0, 1.0));
    float d = noise(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Procedural grass texture replacement
vec3 grassTexture(vec2 uv) {
    float n1 = smoothNoise(uv * 8.0);
    float n2 = smoothNoise(uv * 16.0) * 0.5;
    float n3 = smoothNoise(uv * 32.0) * 0.25;
    float grass = n1 + n2 + n3;
    return vec3(0.2, 0.6, 0.1) * grass;
}

void main()
{
  vec2 uv = vec2((gl_FragCoord.x - iResolution.x*.5) / iResolution.y, (gl_FragCoord.y - iResolution.y*.5) / iResolution.y);

  uv *= 2.0;
  float factor = 0.0;
  float f2 = 0.0;
  float radius = 0.54;
  
  // Audio-reactive radius
  radius += getFFT(0.1) * 0.3;
  
  const int count = 20;
  for(int i = 0; i != count; ++i)
  {
    float offset = sin(2.0 * PI * float(i) / float(count) + iTime * 0.4);
    
    // Audio-reactive movement
    offset += getFFTSmoothed(float(i) * 0.05) * 0.5;
    
    float base = length(uv-vec2(offset, sin(iTime + 2.0 * PI * float(i) / float(count)))) + radius;
  
    factor += smoothstep(0.0, 1.0, 1.0 - base);
    factor += 0.2 * smoothstep(0.0, 1.0, 1.0 - base - sin(iTime) * 0.05);
    f2 += smoothstep(0.0, 1.0, 1.0 - base);
    
    // Replace texPerlin with procedural noise
    factor += 0.1 * factor * smoothNoise(uv * 4.0);
  }

  // Audio-reactive coloring
  vec3 color = vec3(factor * 0.4, factor, factor);
  color += getFFT(0.2) * vec3(1.0, 0.5, 0.8) * factor;
  
  color += vec3(0.0, uv.y*0.4*factor, 0.0) + f2 * length(grassTexture(uv));
  
  // Add some audio-reactive enhancement
  color += getFFTSmoothed(0.05) * vec3(0.3, 0.6, 1.0) * factor;
  
  fragColor = vec4(color, 1.0);
}
