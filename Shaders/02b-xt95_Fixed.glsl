#version 330 core

// 02b-xt95 - OneOffRender Version
// Converted from demoscene format to OneOffRender

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// Audio-reactive functions
float getFFT(float freq) {
    return texture(iChannel0, vec2(freq, 0.0)).r;
}

float getFFTSmoothed(float freq) {
    // Simulate smoothed FFT by averaging nearby frequencies
    float sum = 0.0;
    float samples = 5.0;
    for(float i = 0.0; i < samples; i++) {
        float offset = (i - samples * 0.5) * 0.02;
        sum += texture(iChannel0, vec2(clamp(freq + offset, 0.0, 1.0), 0.0)).r;
    }
    return sum / samples;
}

// Procedural noise texture replacement
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

float fractal(vec3 p)
{
  float scale=1.;
  for(int i=0; i<7; i++)
  {
    p = -1. + 2.*fract(p*.5+.5);
    float k = max( 1.5/dot(p,p), 0.1);
    p *= k;
    scale *= k;
  }
  return 0.25*length(p)/scale;
}

float bt = getFFT(0.01)*100.;

vec3 sky( vec3 dir)
{
  vec3 col =  mix( vec3(1.,.7,.5), vec3(.5,.7,1.), clamp(max(dir.y,0.)*3.,0.,1.) );
  col += smoothNoise(dir.xz/dir.y*.002+iTime*.001) * vec3(0.1) * max(dir.y,0.)*4.;
  col += smoothNoise(dir.xz/dir.y*.004+bt*.001) * vec3(0.1) * max(dir.y,0.)*2.;
  return col;
}

float height( vec2 p)
{
  p*=0.025;
  float h = (smoothNoise(p*.05+iTime*.01) + smoothNoise(p*.05-iTime*.015));
  h += (smoothNoise(p*.1+iTime*.01) + smoothNoise(p*.1-iTime*.01))*.5;
  h += (smoothNoise(p*.2+iTime*.002) + smoothNoise(p*.2-iTime*.002))*.5;
  return h;
}

float map( vec3 p)
{
  return p.y+1. + height(p.xz)*.1 + getFFT(length(p.xz)*0.007)*8.;
}

vec3 normal( vec3 p)
{
  vec2 eps=vec2(0.01,0.);
  return normalize( vec3( map(p)-map(p+eps.xyy), map(p)-map(p+eps.yxy), map(p)-map(p+eps.yyx)) );
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / iResolution.x, gl_FragCoord.y / iResolution.y);
  uv -= 0.5;
  uv /= vec2(iResolution.y / iResolution.x, 1);
  uv.y = -uv.y; // Fix upside-down orientation
  vec3 org = vec3(0.,0.,-8.);
  vec3 dir = normalize(vec3(uv, 1.-length(uv)*(bt*.1)));
  vec4 p = vec4(org,0.);

 vec3 col = vec3(0.);

  for(int i = 0; i< 64; i++)
  {
    float d = map(p.xyz);
    p += vec4(dir*d, 1./64.);
    if(d<0.01)
      break;
  }
  vec3 n = normal(p.xyz);
  vec3 refdir = reflect( dir, n );

  col += sky(refdir);
  if(dir.y<0.)
  col = mix( vec3(.0,.7,1.), col*vec3(1.,.7,1.), abs(dot(n, refdir))*.5+.5 );
  col = mix(col, sky(dir), 1.-exp(-length(p.xyz-org)*.1) );

  col = pow(col*1.2, vec3(3.2));
  fragColor = vec4(col,1.);
}
