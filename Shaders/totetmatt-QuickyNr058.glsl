#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

/* Blame @byt3_m3chanic for the abuse of LogPolar
 and djH0ffman for the overuse of good sounds :D

 Thanks folks !

*/

#define PI 3.141592
#define fGlobalTime iTime
vec2 logpol(vec2 uv){
    return vec2(log((length(uv))),atan(uv.y,uv.x));
 }
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 fragCoordFromUV = (fragCoord / iResolution) * iResolution;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0*fragCoordFromUV-iResolution.xy)/iResolution.y;
    //vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;


    vec3 col;


  uv*=rot(fGlobalTime*.5);

  uv = -logpol(uv)*3.0;

  uv+=fGlobalTime*.5;
  uv = asin(sin(uv));


  uv = logpol(uv)*3.5*.5*texture(iChannel0,fract(vec2(.1))).r; // A 2 c'est MIEUX :D

  uv.x -=sqrt(texture(iChannel0,fract(vec2(.1))).r*10.)*2.+fGlobalTime*1.0;
  uv.y +=pow(fGlobalTime,1.2);
  vec2 id = floor(uv);
  uv = fract(uv)*2.-1.;
  float d = length(uv)-.35-sin(id.x*3.+id.y*4.)*.2;
  d/=3.5;
  d = smoothstep(fwidth(d),0.,d);
  d = d+abs(uv.x)-.1;
    d = smoothstep(fwidth(d),-0.01,d);

  col  = mod(length(floor(uv)),2.) == 0. ? 1.-vec3(d) :  vec3(d);
    fragColor = vec4(col,1.0);
}