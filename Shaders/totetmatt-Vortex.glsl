#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

#define PI 3.141592
mat2 rot(float a){
  float c=cos(a),s=sin(a);
    return mat2(c,-s,s,c);
  }
float stargate(vec2 uv,float offset)
{
  vec2 uuv = uv;
  uuv*=rot(offset*23.);
  float c = sin(atan(uuv.x,uuv.y))*.5+.5;
	float f = texture(iChannel0,vec2(abs(floor(20.*c)/20.))).r*exp(1.+c)*.10;
  float d = abs(length(uv)-(.4+f*1.5))-.04;
   return d;
  }
  vec3 pal(float t){
    return +vec3(.5,.7,.5)+vec3(.5,.7,.5)*cos(2.*PI*(vec3(1.,10.1,1.)*t+vec3(.3,.0,.7)));
    }
    float grid(vec2 uv){
      return abs(fract(uv.x*10.))<.02 || abs(fract(uv.y*10.))<.02  ? 1.: 0.;
      }

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 fragCoordFromUV = (fragCoord / iResolution) * iResolution;
    //vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
    vec2 uv =  (fragCoordFromUV-.5*iResolution.xy)/iResolution.y;

 float tt = texture(iChannel0,vec2(.3,uv.y)).r*.1;

  float d = 1.;
  float lim = 10.;
  vec3 col  = vec3(0.);
  for(float i=0.;i<=lim;++i){
         float it = i/lim;

          float pit = fract(it+iTime*.1);
           float qq = tt*25. > pit? tt*50.0:1.;
          it = mix(50.,.001,pit);

    vec2 coord = (uv-.05*vec2(it*tt*sin(iTime),it*tt *cos(iTime)))*it;
    float g = pit*grid(uv*it*rot(pit*2.)) * smoothstep(.01,.021,(length(coord)-.55));
        d = .1/abs(.01+stargate(coord,i/lim));
        d = (d*3.*g)+d;
    col += mix(vec3(.1),pal((i/lim)+tt)*pit,d*qq)/lim;
    }






    // Output to screen
    fragColor = vec4(col,1.0);
}