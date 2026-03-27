// ported from here  http://pastebin.com/9PRG1PfN
// using MinimalEffortTM methods :)
//
// original 4k intro by Quite & Orange
// http://www.pouet.net/prod.php?which=55758
//
// Wrapped for OneOffRender: #version 330 core, uniforms, void main()

#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform vec4 iMouse;
uniform sampler2D iChannel0;  // self-feedback (unused by p0)
uniform sampler2D iChannel1;  // audio FFT (unused in original — kept for wiring)

#define float2 vec2
#define float3 vec3
#define float4 vec4
#define float3x3 mat3

#define tex2D texture
#define sampler sampler2D

float saturate(float s) { return clamp(s, 0.0, 1.0); }
float2 saturate(float2 s) { return clamp(s, 0.0, 1.0); }
float3 saturate(float3 s) { return clamp(s, 0.0, 1.0); }
float4 saturate(float4 s) { return clamp(s, 0.0, 1.0); }
#define frac fract

float3 mul(float3 v, float3x3 m) { return v * m; }
#define lerp mix

vec2 _j() { return iResolution.xy; }
vec4 _h() { return  vec4(0.0,0.0,iMouse.x/iResolution.x*0.01,iMouse.y/iResolution.y); }
float _t() { return iTime; }

#define s iChannel0
#define j _j()
#define h _h()
#define t _t()

float3 q(sampler s,float2 x) {
    float4 c=tex2D(s,x),d=float4(3.0/pow(c.w,.15));
    return (saturate(c.x/d)*d).xyz;
}

float3x3 r(float3 g) {
        g*=6.283;
        float a=cos(g.x),b=sin(g.x),c=cos(g.y),d=sin(g.y),e=cos(g.z),f=sin(g.z);
        return float3x3(c*e+b*d*f,-a*f,b*c*f-d*e,c*f-b*d*e,a*e,-d*f-b*c*e,a*d,b,a*c);
}

float3x3 w() {
        return r(float3(0,0,smoothstep(-7.,30.,t))+smoothstep(170.,300.,t)*float3(1,2,3)+sin(float3(5,6,7)*(h.z*100.0+t*.002))*.08*(2.0-sin((h.z*2222.0-h.w))));
}

float f1(float3 p) {
        float3 g=(frac(mul(p+sin(p.yzx*.1)/3.0,r(sin(p.z*.07)*float3(0,0,.3)*smoothstep(150.,60.,p.z)))/6.0)-.5)*6.0;
        float d1=2.4*smoothstep(20.,70.,t)-abs(p.x)-1.0,d2=max(abs(g.x),max(abs(g.y),abs(g.z)))-2.3,d3=length(p-float3(0,0,84))-18.0;

        d1=lerp(d1,min(max(d1,-.7-d2),max(d2-.3,abs(d1-.9)-1.3)),saturate(p.z*.03-.5+sin(p.z*.1)*.1));
        d1=max(max(d1,25.0-p.z),p.z-116.0);
        d1=min(min(max(d1,min(11.0-abs(d3),max(-p.z+84.0,abs(length(p.xy)-1.3+sin(p.z*.9)/5.0)-.2))),max(d1+.5,abs(d3-4.0)-.5))-.3*smoothstep(60.,110.,t),max(111.0-p.z,min(7.0-length(p.xy)/2.0-sin(p.z*.3+sin(p.z*2.0)/25.0+t/5.0)*6.0,max(-p.x+(p.z-105.0)*.1,abs(p.y)-1.8))));
        g=mul(p-float3(0,0,44),r(pow(smoothstep(36.,4.,t)*float3(1,2,3),float3(2))*step(-p.z,-15.0)));

        if(t<44.0)
                d1=lerp(d1,max(abs(g.x),max(abs(g.y),abs(g.z)))-4.0-15.0*smoothstep(27.,36.,t),smoothstep(44.,30.,t));

        d1=min(d1,.8*max(p.z-14.0,abs(length(p.xy)-1.5-sin(floor(p.z))/5.0)-1.0));

        return d1;
}

float f2(float3 p) {
        p.z-=138.0;
        float ln=pow(1.0/length(p+3.0*sin(t*float3(5.1,7.6,1)*.023)),2.0)+pow(1.0/length(p+3.0*sin(t*float3(4.5,2.7,2)*.033)),2.0)+pow(1.0/length(p+3.0*sin(t*float3(6.3,3.7,4)*.031)),2.0)+pow(1.0/length(p+3.0*sin(t*float3(7.5,6.3,5)*.023)),2.0),d1=1.0/sqrt(ln)-1.0;

        d1=min(lerp(d1-.7,min(abs(d1+.3)-.3,abs(d1-.7)*2.0-.3),smoothstep(150.,230.,t-p.y/9.0)),abs(d1-5.0)-1.0+4.2*smoothstep(210.,150.,t+p.y/5.0))+2.0*smoothstep(230.,270.,t+p.y);

        return d1;
}

float3 k() {
        return mul(float3(0,.1,-.1-2.0*smoothstep(170.,190.,t)),w())+float3(0,0,smoothstep(-.07,1.0,t*.005)*140.0);
}

float f(float3 p) {
        p+=.01;
        float d1=95.0-length(p-k()),d2=f2(p);

        if(t<280.0)
                d1=min(d1,f1(p))+14.0*smoothstep(140.,230.,t);
        if(t>130.0)
                d1=min(d1,d2);

        d1*=.3;
        p*=.3;
        for(float i=0.0; i<4.0; i++) {
                float3 q=1.0+i*i*.18*(1.0+4.0*(1.0+.3*sin(t*.001))*sin(float3(5.7,6.4,7.3)*i*1.145+.3*sin(h.w*.015)*(3.0+i))),g=(frac(p*q)-.5)/q;
                d1=min(d1+.03,max(d1,max(abs(g.x),max(abs(g.y),abs(g.z)))-.148));
        }

        return d1/.28;
}

float3 nn(float3 p) {
        float2 e=float2(4e-3,0);
        return -normalize(float3(f(p+e.xyy),f(p+e.yxy),f(p+e.yyx)));
}

float u(float3 p,float3 y) {
        float o=.8,g=f(p),d;

        for(float i=0.0;i<1.0;i+=.25) {
                d=i*.15+.025;
                o-=float(g<.01)*(d-f(p-y*d))*2.0*(2.0-i*1.8);
        }

        return o;
}

float4 p0(float2 vp) {
        float2 x=(vp)/j;
        float3
            p=k(),
            a=p,
            y=mul(
                normalize(
                    float3(
                        2.0*sin((vp-.5-j/2.0)/j.y),
                        cos(length((vp-.5-j/2.0)/j.y/2.0)*2.0*sqrt(2.0))
                    )
                ),
                w());
        float g=0.0,df=f(p)+.002;

        for(float i=0.0;i<90.0;i++) {
                if (abs(df)<=.00032)
                    break;
                g+=smoothstep(.5,.07,df)*.01*(1.0-g);
                p+=y*(df+.000001*length(p-a));
                df=f(p);
        }

        float3 n=nn(p);
        float d=length(p-a),o=u(p,n),z=2.0*pow(.5+dot(n,normalize(normalize(sin(p.yzx/5.0+h.w+float3(.14,.47,.33)*t))))/2.0,.5);

        z*=float(1.0+.8/pow(d+.5,.6)*sin(floor(p*1.6+sin(floor(p.yzx*3.0))*3.0)+sin(floor(p.zxy*1.7)))+.7*sin(t*.08+4.0*length(sin(floor(p*3.0+t*.1+sin(floor(p.yzx*133.0))*.24/d*sin(t*.3+floor(p.zxy*.15)))+sin(floor(p.yzx*7.0))))+step(length(frac(p.xy*7.0)-.5)+.6*sin(length(sin(t*float2(.5,.7)+floor(p.xy*7.0)))),.5))*sin(floor(p.z)*3.0+floor(p.x+sin(floor(p.yzx*15.0)))));
        z+=pow(.45+.45*sin(o*38.0+t),19.0);

        return float4(z,g,o,d);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = p0(fragCoord);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
