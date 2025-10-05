#version 330 core

// EVOKE 2019 Shader Showdown - OneOffRender Version
// Converted from Shadertoy format to OneOffRender
// Original: https://www.shadertoy.com/view/wtSXDw
// Winning shader made at EVOKE 2019 Shader Showdown

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Global variables from original shader
vec2 s,v,e=vec2(.00035,-.00035);
float t,tt,g,de,cr,f,ff;
vec3 np,cp,pp,po,no,ld,al;
vec4 su=vec4(0);

// Box distance function
float bo(vec3 p,vec3 r){
    vec3 q=abs(p)-r;
    return max(max(q.x,q.y),q.z);
}

// 2D rotation matrix
mat2 r2(float r){
    return mat2(cos(r),sin(r),-sin(r),cos(r));
} 

// Fractal box function
vec2 fb(vec3 p)	
{
    p.xy*=r2(tt);
    cp=p;
    pp=abs(p)-vec3(0,0,3);
    vec2 h,t=vec2(bo(p,vec3(.6,.6,4.3)),3);
    t.x=min(bo(pp,vec3(.2,3.9,.2)),t.x);
    t.x=min(bo(pp,vec3(3.9,.2,.2)),t.x);
    h=vec2(length(cp.xy)-4.,5);
    h.x=max(h.x,-(length(cp.xy)-3.8));
    h.x=max(h.x,bo(pp,vec3(4,4,1)));
    h.x=min(h.x,bo(pp,vec3(1)));
    t=t.x<h.x?t:h;
    h=vec2(bo(pp,vec3(.8,1.2,.8)),6);
    h.x=min(h.x,bo(pp,vec3(1.2,.8,.8)));
    h.x=min(h.x,bo(abs(abs(p)-vec3(0,0,1))-vec3(0,0,.5),vec3(.4,.8,.4)));
    h.x=min(h.x,length(p)-.1);
    t=t.x<h.x?t:h;
    h=vec2(bo(p,vec3(-.05,25,-.05)),6);
    t=t.x<h.x?t:h;
    g+=0.1/(0.1+h.x*h.x*20.);
    t.x*=0.7;
    return t;
}

// Main distance function
vec2 mp( vec3 p )
{ 
    p.xy*=r2(sin(p.z*0.2)*0.2);
    np=p;
    np.z=mod(p.z+tt*10.,60.)-30.;
    for(int i=0;i<5;i++){
        np=abs(np)-vec3(2,2,3.8);
        np.xy*=r2(1.);
        np.xz*=r2(.5);    
        np.xz-=2.;
    }
    vec2 h,t=fb(np);
    h=vec2(1.2*bo(abs(np*.5)-vec3(4,0,0),vec3(.5,.5,10)),6);    
    h.x=min(.8*length(abs(p.xy)-vec2(20,0.5))-(.6+sin(np.z*.2)*.5),h.x);
    t=t.x<h.x?t:h;
    return t;
}

// Raymarching function
vec2 tr( vec3 ro, vec3 rd )
{
    vec2 h,t=vec2(.1);
    for(int i=0;i<128;i++){
        h=mp(ro+rd*t.x);
        if(h.x<.0001||t.x>70.) break;
        t.x+=h.x;t.y=h.y;    
    }
    if(t.x>70.) t.y=0.;  
    return t;
}

// Noise function
float noi(vec3 p){
    vec3 f=floor(p),s=vec3(7,157,113);
    p-=f;vec4 h=vec4(0,s.yz,s.y+s.z)+dot(f,s);
    p=p*p*(3.-2.*p);
    h=mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
    h.xy=mix(h.xz,h.yw,p.y);
    return mix(h.x,h.y,p.z);
}

// Complex noise function
float cno(vec3 p,float k){
    float f=0.; 
    p.z+=tt*k;
    f+=0.5*noi(p);p=2.1*p;
    f+=0.25*noi(p+1.);p=2.2*p;
    f+=0.125*noi(p+2.);p=2.3*p;
    return f;
}

// Cloud map function
float cmp( vec3 p)
{
    float t=.8*bo(p-vec3(0,-68,0),vec3(50,50.+sin(p.z*.2)*3.-sin(p.x*.2)*3.,250));
    p.xy*=r2(sin(p.z*0.2)*0.2);
    p.z=mod(p.z+tt*10.+30.,60.)-30.;
    t=min(t,.8*length(abs(p)-vec3(8.,4.+sin(tt)*6.,2.))-(sin(tt)*7.));
    return t;
}

void main()
{
    // Fix upside-down issue by flipping Y coordinate
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv=(fragCoord.xy/iResolution.xy-0.5)/vec2(iResolution.y/iResolution.x,1);
    tt=mod(iTime,62.83);
    
    vec3 ro=vec3(35.-cos(tt*1.05)*10.,sin(tt*1.05)*10.,-5);
    vec3 cw=normalize(vec3(0)-ro);
    vec3 cu=normalize(cross(cw,vec3(cos(tt*0.2-0.5),1,0)));
    vec3 cv=normalize(cross(cu,cw));
    vec3 rd=mat3(cu,cv,cw)*normalize(vec3(uv,0.5));
    vec3 co,fo;
    vec3 ld=normalize(vec3(.2,.5,.1));
    
    co=fo=vec3(.2,.6,.5)+((length(uv)-.5));
    s=tr(ro,rd);
    t=s.x;    
    
    if(s.y>0.){
        vec3 po=ro+rd*t;
        vec3 no=normalize(e.xyy*mp(po+e.xyy).x+e.yyx*mp(po+e.yyx).x+e.yxy*mp(po+e.yxy).x+e.xxx*mp(po+e.xxx).x);
        co=mix(mix(pow(max(dot(reflect(-ld,no),-rd),0.),exp2(11.*cno(np*.5,0.)))+(s.y==5.?vec3(.1,.2,.6):vec3(s.y<5.?0.:0.5))*(clamp(mp(po+no*.2).x/.2,0.,1.)*clamp(mp(po+no*.4).x/.4,0.,1.)+.1)*(max(0.,dot(no,ld))+smoothstep(0.,1.,mp(po+ld*.4).x/.4)+smoothstep(0.,1.,mp(po+ld*2.).x/2.)),fo,min(pow(1.+dot(no,rd),4.),.5)),fo,1.-exp(-.000005*t*t*t));
    }
    
    cr=cmp(ro-1.)+fract(dot(sin(uv*476.567+uv.yx*785.951),vec2(984.156)));
    for(int i=0;i<120;i++){
        cp=ro+rd*(cr+=1./3.);
        if(su.a>.99||cr>t) break;
        de=clamp(-cmp(cp)+2.*cno(cp,10.),0.,1.);
        su+=vec4(vec3(mix(1.,0.,de)*de),de)*(1.-su.a);
    }
    
    fragColor = vec4(pow(mix(co,mix(su.xyz,fo,1.-exp(-.000005*cr*cr*cr)),su.a*.9)+g*0.3,vec3(0.45)),1);
}
