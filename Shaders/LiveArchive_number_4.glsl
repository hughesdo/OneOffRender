#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// LiveArchive number 4
// Code by Flopine
// Algorave Nogozon 2019

#define PI 3.141592
#define time iTime

float hash1d (vec2 x)
{return fract(sin(dot(x,vec2(1.45,8.151)))*45.489);}

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float moda (inout vec2 p, float rep)
{
    float per = 2.*PI/rep;
    float a = atan(p.y,p.x);
    float l = length(p);
    float id = floor(a/per);
    a = mod(a, per) - per*.5;
    p = vec2(cos(a),sin(a))*l;
    if (abs(id) >= rep/2.)id = abs(id);
    return id;
}

void mo (inout vec2 p, vec2 d)
{
    p = abs(p)-d;
    if (p.y>p.x) p.xy = p.yx;
}

vec2 rep2d (inout vec2 p, float rep)
{
    vec2 id = floor((p)/rep);
    p = mod(p,rep)-rep*0.5;
    return id;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float stmin (float a, float b, float k, float n)
{
    float st = k/n;
    float u = b-k;
    return min(min(a,b),0.5*(u+a+abs(mod(u-a+st, 2.*st)-st)));
}

vec3 palette (float t, vec3 a, vec3 b, vec3 c, vec3 d)
{return a+b*cos(2.*PI*(c*t+d));}

float sphe (vec3 p, float r)
{return length(p)-r;}

float od (vec3 p, float r)
{return dot(p, normalize(sign(p)))-r;}

float box (vec3 p , vec3 c)
{
    vec3 q = abs(p)-c;
    return min(0., max(q.x,max(q.y,q.z)))+length(max(q,0.));
}

float cyl (vec3 p, float r, float h)
{return max(length(p.xy)-r, abs(p.z)-h);}

float g3 = 0.;
float g1 = 0.;

float prim1 (vec3 p)
{
    float d = smin(od(p,.2), box(p, vec3(.5)), 0.5); 
    p.xz*= rot(time);
    p.xz *= rot(p.y);   
    float id = moda(p.xz, 3.);
    p.x -= 1.;
    d = min(d, cyl(p.xzy, 0.1, 4.));
    return d;
}

float fractal (vec3 p, float count)
{
    p.y += 1.;
    float d = prim1(p);
    for (float i=count; i>0.; i--)
    {
        float ratio = i/count;
        p.xz = abs(p.xz) - 1.;
        p.xz *= rot(PI/4.);
        p.yz *= rot(time+ratio);
        p.xz -= 1.8;
        d = stmin(d, prim1(p),2., 5.);
    }
    g3 += 0.1/(0.1+d*d);
    return d;
}

float water (vec3 p)
{
    p.y += sin(length(p.xz)-time*(5.))*0.5;
    return abs(p.y)-0.5;
}

float cylinders (vec3 p)
{
    vec2 ids = rep2d(p.xz, 15.); 
    float s = max(-od(p-vec3(0.,10.,0.), .8),sphe(p-vec3(0.,10.,0.), 1.));
    p.xz *= rot(time);
    p.xz *= rot(p.y*0.5);
    float id = moda(p.xz, 5.);
    p.x -= 2.;
    float d = min(s,cyl(p.xzy, 0.2, 1e10));
    g1 += 0.1/(0.1+d*d);
    return d;
}

float SDF (vec3 p)
{   
    p.y +=2.;
    return smin(fractal(p,3.),smin(water(p), cylinders(p), 0.8), 1.);
}

vec3 camera(vec3 ro, vec2 uv, vec3 ta) 
{
    vec3 fwd = normalize(ta - ro);
    vec3 left = normalize(cross(vec3(0, 1, 0), fwd));
    vec3 up = normalize(cross(fwd, left));
    return normalize(fwd + uv.x*left + up * uv.y);
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = 2.*(fragCoord/iResolution.xy)-1.;
    uv.x *= iResolution.x / iResolution.y;
    
    float dither = hash1d(uv);
    uv.x += .3;
    uv.y += .4;
    
    vec3 ro = vec3(-10.*sin(time)*0.8,3.,-15.* cos(time)); vec3 p = ro;
    vec3 tar = vec3(0.,-2.,0.);
    vec3 rd = camera(ro, uv, tar);
    vec3 col = vec3(0.);
    
    float shad = 0.;
    bool hit = false;

    for (float i=0.; i<64.; i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            shad = i/64.;
            hit = true;
            break;
        }
        p += d*rd*0.8;
    }

    if (hit)
    {
        col = vec3(shad);
        col += g1 * vec3(0.3,0.,0.3)*0.5;
        col += g3*palette(p.z, vec3(0.5),vec3(0.5), vec3(0.2), vec3(0.2,0.1,.5))*0.2;
    }
    
    float t = length(ro-p);
    col = mix(col, palette(uv.y, vec3(0.5), vec3(0.5), vec3(0.5), vec3(0.3,0.6,0.5)), 1.-exp(-0.001*t*t));

    fragColor = vec4(pow(col, vec3(2.1)), 1.);
}

