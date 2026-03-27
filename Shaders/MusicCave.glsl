#version 330 core

//CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/
//To the extent possible under law, Blackle Mori has waived all copyright and related or neighboring rights to this work.
// Converted for OneOffRender system

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

vec3 erot(vec3 p, vec3 ax, float ro) {
  return mix(dot(ax,p)*ax,p,cos(ro))+sin(ro)*cross(ax,p);
}

float edges;
float comp(vec3 p) {
  vec3 s = sin(p)*sin(p);
  edges = max(max(edges,s.x),max(s.z,s.y));
  p = asin(sin(p));
  return dot(p,normalize(vec3(1)));
}

float stage;
float cave;
float pillars;
float scene(vec3 p) {
  edges = 0.;
  float d1 = comp(erot(p,normalize(vec3(3,2,1)),0.5)+1.);
  float d2 = comp(erot(p,normalize(vec3(2,1,3)),0.6)+2.);
  float d3 = comp(erot(p,normalize(vec3(1,3,2)),0.7)+3.+iTime*mod(stage,2.));
  cave = (d1+d2+d3)/3. - length(p.zy*vec2(1,.2))/3. + 2.;
  pillars = length(asin(sin(p.xy/3.+2.))*3.)-.2 - pow(texture(iChannel0,vec2(abs(p.z)/400.,0)).r,4.)/2. - p.z*p.z/100.;
  return min(cave,pillars);
}

vec3 norm(vec3 p) {
  mat3 k = mat3(p,p,p)-mat3(0.01);
  return normalize(scene(p) - vec3( scene(k[0]),scene(k[1]),scene(k[2]) ));
}

//hello world
void main()
{
  vec2 fragCoord = gl_FragCoord.xy;
  fragCoord.y = iResolution.y - fragCoord.y;
  vec2 uv = (fragCoord-iResolution.xy*.5)/iResolution.y;

  float t = iTime/60.*125.;
  stage = floor(t/4.);
  t += mod(stage,100.)*34.23;
  vec3 cam = normalize(vec3(1.2+sin(stage),uv));
  vec3 init= vec3(-4,0,0);
  cam = erot(cam,vec3(1,0,0),t/6.*sign(cos(stage*32.3)));
  if(cos(stage*7.)<0.)cam=cam.zxy;
  init.x += mod(t,100.)*3.*sign(cos(stage*10.3));
  vec3 p =init;
  bool hit = false;
  float dist;
  float glow = 0.;
  for (int i = 0; i < 150 && !hit ; i ++) {
    dist = scene(p);
    hit = dist*dist < 1e-6;
    glow += smoothstep(.99,1.,edges)/(1.+abs(cave)*200.)*pow(abs(sin(p.x/40.+iTime)),20.)/2.;
    glow += pow(texture(iChannel0,vec2(abs(p.z)/20.,0)).r,4.)/(1.+abs(pillars)*100.)/2.;
    p+=cam*dist;
  }
  bool pl = pillars==dist;
  float ms = step(0.999,edges);
  float fog = smoothstep(80.,0.,distance(p,init));
#define AO(p,n,t) smoothstep(-t,t,scene(p+n*t))
  vec3 n = norm(p);
  vec3 r = reflect(cam,n);
  float ao = AO(p,n,1.)*AO(p,n,.5)*AO(p,n,.1);
  float sss = AO(p,vec3(0.7),1.);
  float spec = length(sin(r.xy*3.)*.4+.6)/sqrt(2.);
  vec3 matcol = pl ? vec3 (0.9,0.1,0.05) : vec3(0.8);
  vec3 col = mix(spec,sss,.5)*matcol;
  if(!pl)col *= 1.-ms;
  col += pow(spec,10.);
  fragColor.xyz = sqrt((hit ? col*fog*ao : vec3(0.03)) + glow*glow + glow*vec3(0.5,0.7,1));
  fragColor *= 1.-dot(uv,uv)*.7;
}