// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
 
    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
 
    // Smooth Interpolation
 
    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);
 
    // Mix 4 coorners porcentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}
 
// Extended wave functions for turbulence and visual modulation
// waveform types:
// 0 = sine
// 1 = square
// 2 = sawtooth
// 3 = triangle
// 4 = pulse
// 5 = noise-based
// 6 = exponential decay sine
//   = soft square - removed right now due to no tanh
// 7 = rounded sawtooth
// 8 = stepped stair
 
float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}
 
float noiseWave(float phase) {
    float intPart = floor(phase);
    float fracPart = phase - intPart;
    return mix(hash(intPart), hash(intPart + 1.0), fracPart) * 2.0 - 1.0;
}
 
float waveFunction(float phase, int type) {
    if (type == 0) return sin(phase);                                 // sine wave
    if (type == 1) return sign(sin(phase));                           // square wave
    if (type == 2) return 2.0 * fract(phase / (2.0 * 3.14159)) - 1.0; // sawtooth wave
    if (type == 3) return abs(mod(phase / 3.14159, 2.0) - 1.0) * 2.0 - 1.0; // triangle wave
    if (type == 4) return step(0.5, fract(phase / (2.0 * 3.14159))) * 2.0 - 1.0; // pulse wave (50%)
    if (type == 5) return noiseWave(phase);                           // pseudo-random noise wave
    if (type == 6) return sin(phase) * exp(-abs(phase) * 0.1);        // exponentially decaying sine
    //if (type == 7) return tanh(10.0 * sin(phase));                    // soft square remove
    if (type == 7) return tan(fract(phase / (2.0 * 3.14159)) * 3.14159 - 1.5708); // rounded sawtooth
    if (type == 8) return floor(fract(phase / (2.0 * 3.14159)) * 5.0) / 2.0 - 1.0; // stepped stair
    return sin(phase); // default
}
 
vec2 turbulence(vec2 p, float strength, int waveType)
{
    vec2 orig = p;
    float freq = TURB_FREQ;
    mat2 rot = mat2(0.6, -0.8,
                    0.8,  0.6);
 
    for(float i = 0.0; i < 100.0; i++)
    {
        if (TURB_AMT == i) break;
        float phase = freq * (p * rot).y
                    + TURB_SPEED * progress
                    + i;
        p += TURB_AMP * rot[0] * waveFunction(phase, waveType) / freq;
 
        rot *= mat2(0.6, -0.8,
                    0.8,  0.6);
        freq *= TURB_EXP;
    }
 
    return orig + strength * (p - orig);
}
 
// linear ramp-up then ramp-down
float computeStrength(float progress, float peak){
    // make sure peak is in (0,1)
    peak = clamp(peak, 0.0001, 0.9999);
 
    // before peak: ramp 0→1, after peak: ramp 1→0
    float up   = progress / peak;
    float down = (1.0 - progress) / (1.0 - peak);
 
    // take the smaller of the two ramps, and clamp to [0,1]
    return clamp(min(up, down), 0.0, 1.0);
}
 
 
vec4 transition (vec2 uv) {
  float strength = computeStrength(progress,peakPoint);
 // vec4 from=getFromColor();
 vec2 a = turbulence(uv,strength,TURB_WAV);
  vec4 from = getFromColor(uv);
  vec4 to = getToColor(uv);
  float n = noise(a * scale);
  
  float p = mix(-smoothness, 1.0 + smoothness, progress);
  float lower = p - smoothness;
  float higher = p + smoothness;
  
  float q = smoothstep(lower, higher, n);
  
  return mix(
    from,
    to,
    1.0 - q
  );
}