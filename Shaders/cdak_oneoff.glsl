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
uniform sampler2D iChannel0;  // Buffer A output

//sampler s;
//float2 j;
//float4 h:register(c1);

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
//float3 pow(float3 v, float e) { return pow(v, float3(e)); }
//float3 pow(float3 v, int e) { return pow(v, float3(e)); }
//float3 pow(float v, float3 e) { return pow(float3(v), e); }
//float smoothstep(int a, int b, float t) { return smoothstep(float(a), float(b), t); }
#define frac fract

float3 mul(float3 v, float3x3 m) { return v * m; }
#define lerp mix

float automation_intensity()
{
    return 0.02 - sin(iTime*0.1) * 0.01;
}

vec2 _j() { return iResolution.xy; }
vec4 _h() { return  vec4(automation_intensity()/*0.02*/,0.0,iMouse.x/iResolution.x*0.01,iMouse.y/iResolution.y); }
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
        g=mul(p-float3(0,0,44),r(pow(smoothstep(36.,4.,t)*float3(1,2,3),float3(2.))*step(-p.z,-15.0)));

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

float4 p1(float2 vp/*:vpos*/)/*:color0*/ {
        float2 x=(vp/*+.5*/)/j;
        float3 c=float3(tex2D(s,x).x),b=tex2D(s,x).yzw;
        float2 w=4e-4/j*j.x/pow(b.z+.03,.5)*(pow(b.y,2.0)+.1);
        float3 e=float3(1,-1,0),_11=q(s,x+w*e.yy),_12=q(s,x+w*e.zy),_13=q(s,x+w*e.xy),_21=q(s,x+w*e.yz),_23=q(s,x+w*e.xz),_31=q(s,x+w*e.yx),_32=q(s,x+w*e.zx),_33=q(s,x+w*e.xx),v=_13+2.0*_23+_33-(_11+2.0*_21+_31),z=_11+2.0*_12+_13-(_31+2.0*_32+_33);

        c=lerp((saturate(sqrt(sqrt(v*v*float3(.5,.01,1)+z*z*float3(.02,1,1)))*.4/pow(b.z,.3))*sqrt(h.x*50.0+1.0)+b.x*b.x*12.0/pow(b.z+.5,.6))*pow(b.y,1.1)*1.04,float3(h.x*70.0+h.x*smoothstep(50.,10.,t)*2.0),saturate(b.z/110.0-.1+h.x*3.0));
        c=pow(c+saturate(1.0-c)*b.x,1.8*float3(1.8,1.2,1.1)-1.0+9.0/t+.1/(pow(float3(h.x*20.0),float3(3,4,3))+.05))*2.0;

        return c.xyzz;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = p1(fragCoord);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
