#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Fractal Texturemap Experiment
// Created by diatribes
// Shadertoy ID: 4XVfWm
// https://www.shadertoy.com/view/4XVfWm

#define rot(a)   mat2 (cos(a+vec4(0,11,33,0)))                   
#define T iTime

float fractal(vec3 p, out vec3 rgb, int iterations){
  float m = 1.;
  for (int i = 0; i < iterations; i++) {
    float n = abs(p.x*p.y*p.z);
    p = abs(p)/clamp(n,.3,1.)-1.45;
    m = abs(min(p.x,min(p.y,p.z)));
  }
  m = exp(-3. * m)*2.5;
  rgb=vec3(p.xy,2.5) * m;
  return length(rgb*.1);
}

vec3 cor;
float M(vec3 p){
    float d = dot(cos(p), sin(p.yzx)) + 1.3;
    
    vec3 q = p * 9.;
    float k = dot(cos(q), sin(q.yzx)) + .1;
    
    vec3 cor1 = vec3(217,193,136)/255.; 
    vec3 cor2 = vec3(67,47,31)/255.; 
    vec3 cor3 = vec3(148,108,65)/255.; 
    
    cor = mix(cor1, cor2, k * 1.1 + .75) ;
    cor = mix(cor, cor3, abs(k * .45) + .3);
    
    return  d;
}

void main(){
    vec2 u = gl_FragCoord.xy;
    vec4 O;
    float T  = iTime * 4., 
          a  = T * .04, 
          PI = 3.14;
    
    vec3 p = vec3(0,0,5), 
         d = normalize(vec3((u-iResolution.xy*.5)/iResolution.y, -1.));
    
    d.yz *= rot(a);
    d.xz *= rot(a*.5);

    vec3 rgb;
    float g = 0.0;
    for(float i=0., s, e; ++i < 99.;)
    {
        s = M(p);
        e = fractal(p, rgb, 3);

        if(s < .001 || e < .001) break;

        p += d*min(s,e)*.5;
        g += .02;
    }

    O = vec4(cor * rgb * (1.-g), 1.);
    fragColor = O;
}

