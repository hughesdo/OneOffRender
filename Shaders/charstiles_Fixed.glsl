#version 330 core

// charstiles - OneOffRender Version
// Converted from demoscene format to OneOffRender

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// Audio-reactive functions
float getFFT(float freq) {
    return texture(iChannel0, vec2(freq, 0.0)).r;
}

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

vec4 mat(vec3 p){
    return vec4(1);
}

float sphere(vec3 p , float l){
    return length(p)-l;
}

float scene(vec3 p){
    float c = 1.0;
    return sphere(mod(p,c) - (c/2.0),.1);
}

vec4 trace(vec3 ro, vec3 rd){
    float d = 0.0;
    vec3 p = ro;

    for (int i = 0; i < 32; i++){
        d = scene(p);
        p += d * rd;
        
        if (d < 0.01){
            return mat(p);
        }
    }
    return vec4(0);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / iResolution.x, gl_FragCoord.y / iResolution.y);
  uv -= 0.5;
  uv /= vec2(iResolution.y / iResolution.x, 1);
  float FOV = 1.0;

  vec3 ro = vec3(sin(iTime),0,iTime);
  vec3 lookat = vec3(0,0,iTime + 100.0);

  vec3 forward = normalize(lookat - ro);
  vec3 right = normalize(vec3(forward.z,0,-forward.x));
  vec3 up = normalize(cross(forward,right));
   
  vec3 rd = normalize(forward + FOV * uv.x * right + FOV * uv.y * up);
  
  vec2 m;
  m.x = atan(uv.x / uv.y) / 3.14;
  m.y = 1.0 / length(uv) * .2;
  float d = m.y;

  float f = getFFT(d) * 100.0;
  m.x += sin( iTime ) * 0.1;
  m.y += iTime * 0.25;

  vec4 t = plas( m * 3.14, iTime ) / d;
  t = clamp( t, 0.0, 1.0 );
  fragColor = (f + t) * trace(ro,rd);
}
