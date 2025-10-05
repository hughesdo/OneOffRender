#version 330 core

// 01d-kabuto - OneOffRender Version
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

// Procedural normal texture replacement
float normalTex(vec2 uv) {
    float n = 0.0;
    n += 0.5 * sin(uv.x * 17.0 + uv.y * 13.0);
    n += 0.25 * sin(uv.x * 31.0 - uv.y * 23.0);
    return 0.5 + 0.5 * n;
}

// Procedural mono texture replacement
vec3 monoTex(vec2 uv) {
    float n = 0.0;
    n += 0.5 * sin(uv.x * 19.0 + uv.y * 11.0);
    n += 0.25 * sin(uv.x * 29.0 - uv.y * 17.0);
    float mono = 0.5 + 0.5 * n;
    return vec3(mono);
}

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

vec4 f_plane(vec3 pos) {
  float c = step(abs(pos.x),1.)*.25+.25;
  c += step(abs(pos.x),sin(sin(pos.z*3.)+sin(pos.z*4.2434))*.1+.2);

   float u = sin(pos.z*.03+iTime*.4)+sin(pos.z*.0114)+sin(pos.z*.021341);
   u = sin(u*10.);
   pos.y += u*u;

  float a = normalTex(vec2(pos.z*.01,iTime*1))*.5-.15;  
  pos.xy *= mat2(cos(a),sin(a),-sin(a),cos(a));

  return vec4(vec3(c), max(abs(pos.y),abs(pos.x)-1.));
}

vec4 f_obj1(vec3 pos) {
  float z = floor(pos.z);
  pos.z = fract(pos.z+.5)-.5;
  float t = iTime+sin(sin(z)*131.+iTime)*3.;
  pos -= vec3(sin(t),cos(t),0)*2.;
  return vec4(abs(vec3(cos(z),cos(z+2.),cos(z-2.))),length(pos)-getFFTSmoothed(pos.z*.002)*10.);
}

vec4 f_obj2(vec3 pos) {
  pos.z += .5;
  float z = floor(pos.z);
  pos.z = fract(pos.z*.5+.5)*2.-.5;
  pos.y -= sin(pos.x)*getFFT(pos.z)+pow(abs(sin(pos.x+z+iTime*10.)+sin(pos.x+z*1.131)),5.)*.1+3.;
  float t = iTime+sin(sin(z)*131.+iTime)*3.;
  pos -= vec3(sin(t),cos(t),0)*2.;
  return vec4(abs(vec3(cos(z),cos(z+2.),cos(z-2.))),length(pos.yz)-.01);
}

vec4 m(vec4 c) {
  return vec4(c.xyz,1)/(c.w+.001);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / iResolution.x, gl_FragCoord.y / iResolution.y);
  uv -= 0.5;
  uv /= vec2(iResolution.y / iResolution.x, 1);

  vec3 pos = vec3(0,1,(iTime)*5.);
  vec3 dir = normalize(vec3(uv,1));

  vec4 v_plane, v_obj1, v_obj2;

  vec4 sum1 = vec4(0);

  for (int i = 0; i < 100; i++) {
    v_plane = f_plane(pos);
    v_obj1 = f_obj1(pos);
    v_obj2 = f_obj2(pos);
    float f = .5;
    f = min(f,v_plane.w);
    f = min(f,v_obj1.w);
    f = min(f,v_obj2.w);
    sum1 += v_obj1/(v_obj1.w+.1);

    pos += dir*f;
  }

   vec4 sum = m(v_plane);
   sum += m(v_obj1);
   sum += m(v_obj2);
   sum += vec4(monoTex(gl_FragCoord.xy/iResolution.xy)*getFFT(0.0)*2.,1.)*10.;

  fragColor = vec4(sum.xyz/sum.w+sum1.xyz*.01,1.);
}
