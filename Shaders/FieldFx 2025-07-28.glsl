# https://www.shadertoy.com/view/t33Xzl
# Created by mrange in 2025-07-29
#  FieldFx 2025-07-28

// CC0: FieldFx 2025-07-28
//  My first contribution to FieldFx shader jam
//  Went for comfort since it was my first time and coded glow tracers

// Stream recording:
//  https://scenesat.com/videoarchive/FYBKI5?bs5#show-FYBKI5

// Twitch: https://www.twitch.tv/fieldfx
// Alkama was DJ:ing and had a great set

#define BPM 114.



float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

float hash(vec2 co) {
  return fract(sin(dot(co.xy ,vec2(12.9898,58.233))) * 13758.5453);
}

float hash(vec3 r)  {
  return fract(sin(dot(r.xy,vec2(1.38984*sin(r.z),1.13233*cos(r.z))))*653758.5453);
}

float segmenty(vec2 p) {
  float 
      d0 = length(p)
    , d1 = abs(p.x)
  ;
  return p.y > 0. ? d0 : d1;
}

vec3 bars(vec3 col) {
    col = mix(col,vec3(0), isnan(col));
    const float ZZ = 0.025;
    vec2 
        r = iResolution.xy
      , C = gl_FragCoord.xy
      , p = (C + C - r) / r.y
      , q
      ;
    float 
        t   = iTime
      , aa  = sqrt(2.) / r.y
      ;
    p.y += 0.5;
    q = (1. + p) * 0.5;
    // Draw frequency bars
    if (abs(p.x) < 1.5 - ZZ * 3.) {
        float 
            x = q.x
          , n = round(x / ZZ) * ZZ
          ;
        vec2 c = q;
        c.x -= n;
        x = n;
        
        x = clamp(x * 0.5 + 0.125, 0., 1.);
        float f = texture(iChannel0, vec2(x,.25)).x;
        //x += 1./16.;
        
        c.y -= 0.5;
        c.y = abs(c.y) - f * 0.3;
        
        col = mix(
            col
        ,   vec3(0)
        , smoothstep(aa, -aa, segmenty(c) - ZZ * 0.4-aa*2.)
        );
        col = mix(
            col
        , vec3(0.1+4.*abs(p.y)) * (1.25 + sign(p.y))
        , smoothstep(aa, -aa, segmenty(c) - ZZ * 0.4)
        );
    }
    
    // Horizontal line at y=0
    if (abs(p.y) < 2. * aa) {
        col = vec3(2);
    }
    
    // Bottom half tint
    if (p.y < 0.) {
        col += -0.01 * vec3(1, 3, 21) * p.y;
    }
    
    // Final color processing
    col = sqrt(tanh(col));
    
    return col;
}

vec4 eff0(vec2 C, float V) {
  float i,d,z,T=iTime*BPM/60.,F=sqrt(fract(T)),B=floor(T)+F;
  vec4 o,p,X,Y;
  for(vec2 r=iResolution.xy;++i<77.;z+=.7*d) {
    p = vec4(z*normalize(vec3(C-.5*r,r.y)),.25);
    p.z += .7*B;
    mat2 R = mat2(cos(.3*B+0.5*p.z+vec4(0,11,33,0)));
    p.xy *= R;
    Y = p;
    p.xy -= .5;
    
    p -= round(p);
    p.xw *= R;
    p.wy *= R;
    p.zw *= R;
    X = p;
    X *= X;
    X *= X;
    d = pow(dot(X,X),.125) - .3;
    X = sin(66.*Y+B*3.141592654+Y.z);
    d += X.x*X.y*X.z*X.w*4e-2;
    d = abs(d)+1e-3;
    // d = length(p)-1.;
    p = 1.+sin(3.*Y.x+.4*Y.z+vec4(4,1,0,5));
    if (V==0.) o += p.w/d*p;
    o += pow(1.-F,2.)*z*z*z*vec4(3,1,2,0)*2.;
  }
  return o/2e4;
}

vec4 eff1(vec2 C, float V) {
  float i,d,z,k,L,T=iTime*BPM/60.,F=sqrt(fract(T)),B=floor(T)+F;
  vec4 o,p,X,Y;
  mat2 R = mat2(cos(0.3*B+vec4(0,11,33,0)));
  for(vec2 r=iResolution.xy;++i<77.;z+=.7*d) {
    p = vec4(z*normalize(vec3(C-.5*r,r.y)),.0);
    p.z -= 5.;
    L = length(p)-4.;
    k = 6./dot(p,p);
    p *= k;
    Y = p;
    p.xw *= R;
    p.wy *= R;
    p.zw *= R;
    p += .3*B+.3*length(p);
    p -= round(p);
    X = p;
    X *= X;
    X *= X;
    d = pow(dot(X,X),.125)-.3;
    d /= k;
    d = abs(d) + 1e-3;
    d = max(d,L);
    p += 1.+sin(Y.x+iTime+log2(k)+vec4(5,3,1,4));
    //d = length(p)-1.;
    if (V==0.) o += p.w/d*p;
    o += pow(1.-F,2.)*k*k*vec4(2,1,3,0)*80.;
  }
  
  return o/2e4;
}

void mainImage(out vec4 O, vec2 C) {
  float h = hash(floor(iTime*BPM/(60.*8.)));
  O -= O;
  if (h > 0.75) {
    O += eff0(C,0.);
  } else if (h > 0.5) {
    O += eff1(C,0.);
  } else if (h > .25) {
    O += eff0(C,1.);
  } else {
    O += eff1(C,1.);
  }
  O.xyz = bars(O.xyz*O.xyz);
}