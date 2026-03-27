//https://www.shadertoy.com/view/W3lyzs
//Original Created by nayk in 2025-10-09


uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;
// shadertoy emulation
#define  time iTime
#define  resoluti iTimeon iResolution

// Emulate a black texture
#define texture(s, uv) vec4(0.0)

// --------[ Original ShaderToy begins here ]---------- //
#define time iTime
uniform vec2 v2Resolution; // viewport resolution (in pixels)
uniform float fFrameTime; // duration of the last frame, in seconds

//uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
#define B (texture(iChannel0,vec2(.1,.75)))
#define BB (texture(iChannel0,vec2(.1,.75)))
//uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
//uniform sampler1D texFFTIntegrated; // this is continually increasing

#define F float
#define V vec2
#define W vec3
#define N normalize
#define L length
#define rot(x) mat2(cos(x),-sin(x),sin(x),cos(x))
#define S(x) sin(x+2.*sin(x))
#define col(x) (cos((x+W(0,.3,.4))*6.28)*.5+.5)

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
  uv/=dot(uv,uv)*0.1;
	uv -= iTime*10.; uv*=.1;
	F i=0.,d=0.,e=1.;
	W p,pI, rd=N(W(0,0,1));
	rd.zy*=rot(uv.y*3.);

	F c;
    	rd.xz*=rot(-uv.x*3.5+S(time*0.0)*4.+.03*S(time+uv.x*10.));
        
	for(F ii=1.;ii<=99.;ii++){
		if (e<=.0001) break;
		pI=p=d*rd;
        
		F sz=.25*BB.x;
		sz = max(sz,.1);
		
		p.zy=p.yz;
      
		F s,ss=1.5;
        p.xy*=s=1.+.5*S(pI.x*2.-time);
        ss*=s;
p.xz*=rot(time+S(time*.4*1.61+pI.z*1.));
		//p.xz*=rot(S(time*.4));
		 c=0.;
		for(F j=1.;j<=2.;j++){
		p.xz*=rot(time+S(time*.4*4.61+pI.z*1.+j));
			ss*=s=3.;
			p*=s;
			p.y+=.5+j/10.;//+B.x;
			p.y=fract(p.y)-.5;
			p=abs(p)-.5-B.x*.1 + .2*S(pI.z*.1+time*0.1);
			if(p.z<p.x)p.xz=p.zx;
			if(p.y>p.x)p.xy=p.yx;
			c+=L(p)*.01;
		}
		
		p-=clamp(p,-sz,sz);
		d+=e=(L(p.xz)-.0001)/ss;
		i++;
	}
	fragColor.rgb = 20./i*col(log(d)*.8+c*20.+time*mouse.x*1.);
    fragColor.a=1.;
}