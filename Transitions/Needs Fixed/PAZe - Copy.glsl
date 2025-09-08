// author: gre + PAEz
// License: MIT
uniform float smoothness; // = 0.3
uniform bool opening; // = true

const vec2 center = vec2(0.5, 0.5);
const float SQRT_2 = 1.414213562373;


//Number of turbulence waves
#define TURB_NUM 10.0
//Turbulence wave amplitude
uniform float TURB_AMP;//= 0.9
//Turbulence wave speed
uniform float TURB_SPEED;//= 1.3
//Turbulence frequency
uniform float TURB_FREQ;//= 4.0
//Turbulence frequency multiplier
uniform float TURB_EXP;//= 1.9

//Apply turbulence to coordinates
vec2 turbulence(vec2 p, float strength)
{
    vec2 orig = p;                   // save the input
    float freq = TURB_FREQ;
    mat2  rot  = mat2(0.6, -0.8,
                      0.8,  0.6);

    for(float i = 0.0; i < TURB_NUM; i++)
    {
        float phase = freq * (p * rot).y
                    + TURB_SPEED * progress
                    + i;
        p += TURB_AMP * rot[0] * sin(phase) / freq;

        rot  *= mat2(0.6, -0.8,
                     0.8,  0.6);
        freq *= TURB_EXP;
    }

    return orig + strength * (p - orig);
}

uniform float peakPoint; // = 0.1


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
  float x = opening ? progress : 1.-progress;
  vec2 p =turbulence(uv,strength);
  float m = smoothstep(-smoothness, 0.0, SQRT_2*distance(center, p) - x*(1.+smoothness));
  return mix(getFromColor(uv), getToColor(uv), opening ? 1.-m : m);
}