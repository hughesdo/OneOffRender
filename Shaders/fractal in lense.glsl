#https://www.shadertoy.com/view/wflfWB
#Original Created by nayk in 2025-09-16


#define R(p,a,r)mix(a*dot(p,a),p,cos(r))+sin(r)*cross(p,a)
#define H(h)(cos((h)*6.3+vec3(0,23,21))*.5+.5)
#define RADIUS       0.28
#define IOR          1.8
#define STRENGTH     1.6
#define EDGE_SOFTNESS 0.2
#define CURVATURE    6.0
#define ABERRATION   0.1
#define SQUIRCLE_P   16.0
#define PARALLAX     22.0
#define Q(p) p *= 2.*r(round(atan(p.x, p.y) * 4.) / 4.)
#define r(a) mat2(cos(a + asin(vec4(0,1,-1,0))))
float smin (float a, float b)
{
	float m = min(a, b);
	float dif = abs(a - b);
	
	return m + dif * (exp(m) / (exp(a) + exp(b)));
}

vec2 AspectRatio(vec2 uv)
{

	float aspect = iResolution.x / iResolution.y;
	uv.x = (uv.x - 1.5) * aspect + 0.5;
	
	return uv;
}

vec2 InverseAspect(vec2 uvAdj)
{
	float aspect = iResolution.x / iResolution.y;
	uvAdj.x = (uvAdj.x - 0.5) / aspect + 0.5;
	
	return uvAdj;
}

float SquircleMetric(vec2 dNorm, float pExp)
{
	vec2 a = abs(dNorm);
   
	float s = pow(a.x, pExp) + pow(a.y, pExp);
	float r = pow(s, 1.0 / pExp);
	
	return r;
}

vec2 SquircleGrad(vec2 dNorm, float pExp)
{
Q(dNorm);
	vec2 s = sign(dNorm);
	vec2 a = abs(dNorm);
	vec2 g = s * pow(a + 1e-8, vec2(pExp - 0.5));
	
	float len = max(length(g), 1e-6);
	g /= len;
	
	return g;
}

vec2 RefractedUV(vec2 uv, vec2 center, float radius, float ior, float strength, float curveExp)
{
	
	vec2 uvAdj = AspectRatio(uv);
	vec2 cAdj = AspectRatio(center);
	vec2 delta = uvAdj - cAdj;
	Q(delta);
	vec2 dNorm = delta / radius;
	float r = SquircleMetric(dNorm, SQUIRCLE_P);
	if (r >= 1.0)
		return uv;
	
	float slopeScale = pow(r, curveExp);
	vec2 tangential = SquircleGrad(dNorm, SQUIRCLE_P) * slopeScale;
	
	float nLen2 = dot(tangential, tangential);
	float z = sqrt(max(0.0, 1.0 - nLen2));
	vec3 normal = normalize(vec3(tangential, z));
	
	vec3 incident = vec3(0.0, 0.0, -3.0);
	vec3 refr = refract(incident, normal, 1.0 / ior);
	
	float rim = smoothstep(0.0, 1.0, r);
	float t = PARALLAX / max(1e-5, -refr.z);
	vec2 proj = refr.xy * t;
	vec2 uvAdjOut = uvAdj + proj * strength * rim * (1.0 - r);
	vec2 uvOut = InverseAspect(uvAdjOut);
	
	return uvOut;
}


const float PI = 3.14159265;

const float anim_speed = 1.075;

vec2 cmul(vec2 a, vec2 b)
{
    return vec2(a.x * b.x - a.y*b.y, a.x * b.y + a.y * b.x);
}
vec2 conj(vec2 z) { return z * vec2(1,-1); }
vec2 cdiv(vec2 a, vec2 b)
{
    return cmul(a, conj(b)) / dot(b,b);
}

vec2 spiralthing(vec2 uv)
{
    vec3 numer = vec3(uv.y, 1., uv.x);
    float denom = dot(uv, uv) + 1.;
    vec3 offset = vec3(0., -.5, .5);
    vec2 R = vec2(1,0);
    vec2 z = cdiv(R - uv, R+uv);
    z = conj(z);
    z = vec2(atan(z.y, z.x), log(length(z))) / (2. * PI);

    z += iTime * anim_speed;
    vec2 mn = vec2( 100., -6. );

    float angle = atan(mn.y, mn.x);//atan(-5./8.);
    float scale = length(mn);

    float c = cos(angle), s = sin(angle);
    z *= scale * mat2(c,s,-s,c);

    vec2 id = floor(z);
    vec2 f  = fract(z);

    // I have no idea why this works, but just randomly tried stuff xD
    vec2 canonicalCell = mod(id, abs(mn));

   
    return f;
}
void mainImage(out vec4 O, vec2 C)
{
    O=vec4(0);
    vec3 p,r=iResolution,
    d2=normalize(vec3((C*2.-r.xy)/r.y,1.255));  
    
    
    vec2 uv = C/ iResolution.xy;

	vec2 uv2 = C / iResolution.xy;
    Q(uv2);
    uv2.y-=0.5;
	vec2 lensCenter = iMouse.z > 0.0 ? (iMouse.xy / iResolution.xy) : vec2(0.5, 0.5);
	  vec2 R = vec2(1,0);
            vec2 z = cdiv(R - uv2*2.5, R+uv2*5.5);
            z = conj(z);
            z = vec2(atan(z.y, z.x), log(length(z))) / (2. * PI);

            z += iTime * anim_speed;
          
           
	vec3 baseCol = texture(iChannel0, uv).rgb;
	
	vec2 uvAdj = AspectRatio(uv);
	vec2 cAdj = AspectRatio(lensCenter);
	float rNorm = SquircleMetric((uvAdj - cAdj) / RADIUS, SQUIRCLE_P);
	float d = rNorm - 1.0;
	float mask = 1.0 - smoothstep(0.0, EDGE_SOFTNESS, d);
	
	vec2 uvR = RefractedUV(uv, lensCenter, RADIUS, IOR + ABERRATION, STRENGTH, CURVATURE);
	vec2 uvG = RefractedUV(uv, lensCenter, RADIUS, IOR, STRENGTH, CURVATURE);
	vec2 uvB = RefractedUV(uv, lensCenter, RADIUS, IOR - ABERRATION, STRENGTH, CURVATURE);
	vec3 lensCol = vec3(uvR.x, uvG.y, uvB.x);
	
	float edgeShade = mix(1.0, 0.985, smoothstep(0.6, 1.0, rNorm));
	lensCol *= edgeShade;
	
	vec3 color = mix(baseCol, lensCol, mask);
    
    for(float i=0.,a,s,e,g=0.;
        ++i<70.;
        O.xyz+=mix(vec3(0.1,0.5,3.),H(g*.1),.8)*30./e/8e3
    )
    {
        p=g*d2*color;
        
        p.x+=iTime*0.03;
       p.xz*=mat2(cos(iTime*0.1),sin(iTime*0.1),-sin(iTime*0.1),cos(iTime*0.1));
          p.yz*=mat2(cos(iTime*0.1),sin(iTime*0.1),-sin(iTime*0.1),cos(iTime*0.1));
        a=30.;
        p=mod(p-a,a*2.)-a;
        s=2.;
        for(int i=0;i++<8;){
            p=.5-abs(p);
            p.x<p.z?p=p.zyx:p;
            p.z<p.y?p=p.xzy:p;
            s*=e=1.3+sin(iTime*.1)*.1;
            p=abs(p)*e-
                vec3(
                    10.*3.,
                    120,
                    8.*5.
                 );
         }
         g+=e=length(p.yxzz)/s;
    }
}