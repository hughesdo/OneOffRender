// cdak_oneoff_v4.glsl
// V4: Image pass - lines react cleanly to audio intensity globally
#version 330 core

out vec4 fragColor;

uniform vec2 iResolution;
uniform float iTime;
uniform vec4 iMouse;
uniform sampler2D iChannel0;  // Buffer A output
uniform sampler2D iChannel1;  // audio FFT

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

float bass() {
    float b = 0.0;
    for(int i = 1; i <= 5; i++) { b += texture(iChannel1, vec2(float(i)*0.02, 0.25)).x; }
    return b * 0.2;
}
float mids() {
    float m = 0.0;
    for(int i = 1; i <= 5; i++) { m += texture(iChannel1, vec2(0.15 + float(i)*0.03, 0.25)).x; }
    return m * 0.2;
}
float highs() {
    float h = 0.0;
    for(int i = 1; i <= 5; i++) { h += texture(iChannel1, vec2(0.50 + float(i)*0.04, 0.25)).x; }
    return h * 0.2;
}

float automation_intensity()
{
    return 0.02 - sin(iTime*0.1) * 0.01;
}

vec2 _j() { return iResolution.xy; }
vec4 _h() { return  vec4(automation_intensity(),0.0,iMouse.x/iResolution.x*0.01,iMouse.y/iResolution.y); }
float _t() { return iTime; }

#define s iChannel0
#define j _j()
#define h _h()
#define t _t()

float3 q(sampler s,float2 x) {
    float4 c=tex2D(s,x),d=float4(3.0/pow(c.w,.15));
    return (saturate(c.x/d)*d).xyz;
}

float4 p1(float2 vp) {
        float2 x=vp/j;
        float3 c=float3(tex2D(s,x).x),b=tex2D(s,x).yzw;
        
        float audioBass = bass();
        float audioMids = mids();

        // Slightly thicken the lines on bass hits (halved from 0.8 to 0.4)
        float2 w=4e-4/j*j.x/pow(b.z+.03,.5)*(pow(b.y,2.0)+.1) * (1.0 + audioBass * 0.4);

        float3 e=float3(1,-1,0),_11=q(s,x+w*e.yy),_12=q(s,x+w*e.zy),_13=q(s,x+w*e.xy),_21=q(s,x+w*e.yz),_23=q(s,x+w*e.xz),_31=q(s,x+w*e.yx),_32=q(s,x+w*e.zx),_33=q(s,x+w*e.xx),v=_13+2.0*_23+_33-(_11+2.0*_21+_31),z=_11+2.0*_12+_13-(_31+2.0*_32+_33);

        // V3 base colors: v*v*float3(.5,.01,1) + z*z*float3(.02,1,1)
        float3 edge_col_h = float3(.5, .01, 1.0);
        float3 edge_col_v = float3(.02, 1.0, 1.0);
        
        float3 edgeSum = v*v*edge_col_h + z*z*edge_col_v;
        
        // This is the edge intensity term. Multiply by bass and mids so it pulses with the song. (Halved from 2.5/1.5 to 1.25/0.75)
        float edgeStrength = 0.4 * (1.0 + audioBass * 1.25 + audioMids * 0.75); 
        
        // Calculate the color interpolation exactly like V3, but with the modified edgeStrength
        c = lerp((saturate(sqrt(sqrt(edgeSum)) * edgeStrength / pow(b.z, .3)) * sqrt(h.x*50.0+1.0) + b.x*b.x*12.0/pow(b.z+.5,.6)) * pow(b.y,1.1)*1.04, float3(h.x*70.0+h.x*smoothstep(50.,10.,t)*2.0), saturate(b.z/110.0-.1+h.x*3.0));

        c = pow(c+saturate(1.0-c)*b.x,1.8*float3(1.8,1.2,1.1)-1.0+9.0/t+.1/(pow(float3(h.x*20.0),float3(3,4,3))+.05))*2.0;

        return c.xyzz;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = p1(fragCoord);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
