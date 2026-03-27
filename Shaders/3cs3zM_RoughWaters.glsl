#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Rough Waters
// Created by diatribes
// Shadertoy ID: 3cs3zM
// https://www.shadertoy.com/view/3cs3zM

/* 
 texturize() modified from the below by @Elsio
 https://www.shadertoy.com/view/M3yBWK
 https://www.shadertoy.com/view/WcXGRM
*/
float texturize(vec3 p, float t) {

    float d = 0., a = .4;
    vec3 f;
    while(a < 64.)

        // Multiplies input position by current frequency a.
        // Scale factor of 8 determines base detail level.
        f = p * a * 8.,

        // Creates vertical movement over time.
        // Factor of 1.4 controls animation speed.
        f.y -= t * 1.4,

        // Uses sine waves for base noise pattern.
        // Dot product with normalized input adds complexity.
        // Division by a keeps frequency and amplitude related,
        // to preserve effect at scale
        d -= abs(dot(sin(f), p/p)) / a,

        // Doubles frequency for next iteration.
        // Creates smooth transition between detail levels.
        a += a;

    return d;
}


vec3 plasma(vec2 uv) {
    float t = iTime*.1;
    uv *= 10.;
    float r = distance(uv, vec2(sin(t), sin(t)));
    float g = distance(uv, vec2(0, 3.));
    float b = distance(uv, vec2(r, sin(t)*25.));
    float value = abs(sin(r+t) + sin(g+t) + sin(b+t) + sin(uv.x+t) + cos(uv.y+t));
    return vec3(r,g,b)/value*.1;
}

float scene(vec3 p, out vec3 rgb) {
    float e = texturize(p, iTime*.5)*.05;
    
    float lightningFreq = abs(tanh(cos(iTime*2.)*13.)) +
                          sin(iTime*3.)+cos(iTime*2.)+sin(iTime*.5)
                          *.04;
    vec3 lightning = clamp(vec3(1./lightningFreq),vec3(.2),vec3(5.));

    float w1 = sin(iTime+p.x*.3+p.z*1.1)*.22;
    float w2 = tanh(cos(iTime+p.x*.75+p.z*.3)*.20)*1.1;
    float w3 = tanh(cos(iTime+p.x*.6+p.z*1.7)*.26)*1.;
    float river = 1.5+p.y+w1+w2+w3;
    
    float w4 = sin(iTime+p.x*.3+p.z*.15)*.20;
    float w5 = tanh(cos(iTime+p.x*.75+p.z*1.3)*.23)*1.1;
    float w6 = cos(iTime+p.x*.6+p.z*2.3)*.21;
    float sky = 9.-p.y+w1+w2+w3+w4+w5+w6+e;
    
    float hit = sky;
    hit = min(hit,river);
    
    if (river == hit) {
        rgb = plasma(sin(p.xz))*vec3(.01,.04,.07);
    } else if (sky == hit) {
        rgb = vec3(1.);
        rgb *= sin(p.z)*.5+.75;
        rgb *= sin(2.+vec3(cos(p.z*1.8)*.6));
        rgb *= vec3(.5,.01,0.2);
    } else {
        //
    }
    rgb *= lightning;
    return hit;
}

float raymarch(vec3 ro, vec3 rd, out vec3 rgb) {
  float dist = 0.0;
  for(float i = 0.; i < 200.; i++) {
    vec3 p = ro + rd * dist;
    float step = scene(p, rgb);
    dist += step;
    if(dist > 100. || step < .001) {
        break;
    }
  }
  return dist;
}

mat3 lookAt(vec3 origin, vec3 target, float roll) {
  vec3 rr = vec3(sin(roll), cos(roll), 0.0);
  vec3 ww = normalize(target - origin);
  vec3 uu = normalize(cross(ww, rr));
  vec3 vv = normalize(cross(uu, ww));
  return mat3(uu, vv, ww);
}

vec3 normal(vec3 p) {
  vec2 e = vec2(.01, 0);
  vec3 rgb;

  vec3 n = scene(p,rgb) - vec3(
    scene(p-e.xyy,rgb),
    scene(p-e.yxy,rgb),
    scene(p-e.yyx,rgb));

  return normalize(n);
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec3 rgb = vec3(1.);
	
    vec2 uv = -1.0 + 2.0*(u.xy/iResolution.xy);
	uv.x *= iResolution.x/iResolution.y;

	vec3 ro = vec3(0., 0., iTime*1.5);
	vec3 la = ro + vec3(0., 0., 1.);

	vec3 rd = normalize(vec3(uv,1.)*lookAt(ro,la,0.));
	float d = raymarch(ro, rd, rgb);
    vec3 p = ro + rd * d;

    float diffuse = max(dot(normal(p), normalize(ro-p)), .1);
    rgb *= diffuse;
    if (d >= 100.) {
        vec3 red = vec3(1.0, 0.05, 0.125);
        vec3 blue = vec3(0.0, 0.5, 0.8);
        rgb = mix(red.xyz, blue.xyz, uv.y);
    }
    rgb *= 1./pow(d,d*.03);
    fragColor = vec4(pow(rgb, vec3(.45)), 1.0);
}

