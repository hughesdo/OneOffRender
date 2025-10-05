#version 330 core

// semifinal2-blueberry - OneOffRender Version
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

float _d; int _mID; // minimal spheretracer setup

// if we find a closer distance, store distance and material ID
float minMat(float d, int id) {
  if (d < _d) {
    _d = d;
    _mID = id;
  }
  return _d;
}

// distances - audio reactive ball
float the_ball(vec3 p)
{
  return length(p) - (1.0 + getFFT(0.1) * 50.0);
}

float the_floor(vec3 p)
{
  return p.y + 1.0;
}

// combined scene
float scene(vec3 p) {
  float d = 999999.0;
  d = minMat(the_ball(p), 0); // second parameter is material ID
  d = minMat(the_floor(p), 1);
  return d;
}

vec3 calcBallNormal( vec3 v ) {
  vec3 n;
  float e = 0.0001;
  n.x = the_ball( v + vec3(e,0,0) ) - the_ball( v - vec3(e,0,0) );
  n.y = the_ball( v + vec3(0,e,0) ) - the_ball( v - vec3(0,e,0) );
  n.z = the_ball( v + vec3(0,0,e) ) - the_ball( v - vec3(0,0,e) );
  return normalize(n);
}

vec3 calcBallLighting( vec3 p, vec3 camPos )
{
  vec3 norm = calcBallNormal(p);
  vec3 lightDir = normalize(vec3(-1,1,-1));

  float diff = dot(lightDir,norm);
  diff = clamp( diff,0.0,1.0);

  vec3 V = normalize( camPos - p );
  vec3 L = lightDir;
  vec3 H = normalize( V + L );
  float specular = dot(H,norm);
  specular = clamp( specular, 0.0, 1.0 );

  // Audio-reactive coloring
  vec3 baseColor = vec3(1,0,0) + getFFT(0.2) * vec3(0, 1, 0.5);
  return baseColor * diff + pow( specular, 16.0 );
}

bool wheel(vec2 v, float n, float t) {
  return fract(atan(v.x,v.y)/6.28*n+t) > 0.5;
}

void main(void) {
  vec2 uv = gl_FragCoord.xy / iResolution.y;
  float aspect = iResolution.x / iResolution.y;

  uv -= vec2(0.8,0.5);

  float time = iTime;

  // Audio-reactive pattern colors
  vec3 color = wheel(uv, 6.0, time) ? vec3(1.0,0.8,0) + getFFT(0.1) * vec3(0.5, 0.2, 1.0) : vec3(0.8,0.5,0);

  vec2 s = fract(uv*4.0)-0.5;

  int ii = int(uv.x*4.0-s.x)+int(uv.y*4.0-s.y)+3;
  float r = 0.2 + max(0.0,cos((fract(time)*6.0) - float(ii)))*0.3;
  r += getFFTSmoothed(0.05) * 0.2; // Audio-reactive radius
  
  if (length(s) < r) {
    if (length(s) < r*0.2) {
    color = vec3(sin(time*40.0)) + getFFT(0.3) * vec3(1.0, 0.5, 0.8);
  } else {
    color = wheel(s, 6.0, -time) ? vec3(0.0,0.8,1) + getFFT(0.15) * vec3(1.0, 0.2, 0.5) : vec3(0,0.5,1);
}
  }

  vec2 ss = fract(uv*8.0-vec2(time*3.0,time*0.67))-0.5;
  int ii2 = int(uv.x*4.0-s.x)-int(uv.y*4.0-s.y)+3;
  float r2 = 0.2 + cos((fract(time)*6.0) - float(ii2))*0.2;
  r2 += getFFT(0.25) * 0.3; // Audio-reactive
  
  float ff = max(abs(ss.x),abs(ss.y));
  if (ff < r2 && ff > r2*0.5) {
    float ll = r2*r2*r2*9.0+0.4;
    ll += getFFTSmoothed(0.2) * 2.0; // Audio-reactive brightness
    color = vec3(ll,1,ll);
  }
  
  // Enable the 3D scene instead of early return
  // Switch between 2D pattern and 3D scene based on time
  float sceneSwitch = mod(time, 10.0);
  
  if (sceneSwitch > 5.0) {
    // Show 3D scene
    float fCamTime = iTime / 3.0;
    vec3 camPos = vec3(sin(fCamTime)*6.0,2.0,cos(fCamTime)*6.0);
    vec3 camDir = normalize(vec3(sin(fCamTime + PI),-0.4,cos(fCamTime + PI)));
    vec3 camUp = vec3(0,1,0);

    float camFovTan = tan(60.0 * PI/360.0);  
    vec2 sc = (uv*2.0 - vec2(1.0)) * vec2(aspect,1.0);
    vec3 rayDir = normalize(mat3(cross(camDir,camUp), camUp, -camDir) * normalize(vec3(sc, -1.0/camFovTan)));

    // march ray
    float numSteps = 100.0;
    float maxDist = 1000.0;
    float t = 0.0;
    float i = 0.0;
    for (; i < 1.0; i+= 1.0/numSteps) {
      _d = 100000.0;
      scene(camPos + rayDir * t);
      if ((abs(_d) / t < camFovTan/iResolution.y) || (t > maxDist)) break;
      t += _d;
    }

    if ((t > maxDist) || (i >= 1.0)) {
      // ray missed, paint background
      color = mix(vec3(0,0,0),vec3(0,0.5,1),uv.y);
    } else {
      // ray hit, select material
      vec3 p = camPos + rayDir * t;
      if (_mID == 0) {
        color = calcBallLighting( p, camPos );
      } else if (_mID == 1) {
        color = vec3(1,1,1) * ((mod(p.x,2.0) < 1.0) == (mod(p.z,2.0) < 1.0) ? 1.0 : 0.1); 
      }
    }
  }

  // gamma adjust
  color = pow(color, vec3(1.0/2.2));
  
  fragColor = vec4(color,1.0);
}
