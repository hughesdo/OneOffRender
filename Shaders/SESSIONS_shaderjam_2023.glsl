#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

// SESSIONS shaderjam 2023
// Audio reactive fractal tunnel

#define time iTime
#define B (texture(iChannel0,vec2(.1,.75)))
#define BB (texture(iChannel0,vec2(.1,.75)))

#define F float
#define V vec2
#define W vec3
#define N normalize
#define L length
#define rot(x) mat2(cos(x),-sin(x),sin(x),cos(x))
#define S(x) sin(x+2.*sin(x))
#define col(x) (cos((x+W(0,.3,.4))*6.28)*.5+.5)

void main()
{
    vec2 uv = (gl_FragCoord.xy-.5*iResolution.xy)/iResolution.y;

    F i=0.,d=0.,e=1.;
    W p,pI, rd=N(W(0,0,1));
    rd.zy*=rot(uv.y*2.);
    rd.xz*=rot(-uv.x*2.5+S(time*.1)*4.+.03*S(time+uv.x*2.));
    F c;
    for(;i++<99.&&e>.0001;){
        pI=p=d*rd;
        F sz=.25*BB.x;
        sz = max(sz,.1);
        p.z+=(time*.5)+B.x*.01;
        p.zy=p.yz;
        F s,ss=1.5;
        p.xz*=vec2(s=1.+.5*S(pI.y*2.-time));
        ss*=s;

        c=0.;
        for(F j=0.;j++<4.;){
            p.xz*=rot(time+S(time*.4*1.61+pI.z*1.+j));
            ss*=s=3.;
            p*=s;
            p.y+=.5+j/10.;
            p.y=fract(p.y)-.5;
            p=abs(p)-.5-B.x*.1 + .2*S(pI.z*.1+time*.1);
            if(p.z<p.x)p.xz=p.zx;
            if(p.y>p.x)p.xy=p.yx;
            c+=L(p)*.01;
        }

        p-=clamp(p,-sz,sz);
        d+=e=(L(p.xz)-.0001)/ss;
    }
    fragColor.rgb = 20./i*col(log(d)*.8+c*20.+time*.1);
    fragColor.a=1.;
}

