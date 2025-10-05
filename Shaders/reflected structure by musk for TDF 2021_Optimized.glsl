#version 330 core

// Reflected Structure by musk for TDF 2021 - Optimized Version
// Reduced complexity for better performance and animation

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

vec3 col_1, col_2;

mat2 rotate(float a){
	float c=cos(a), s=sin(a);
	return mat2(
		+c, +s,
		-s, +c
	);
}

float ss_noise(float seed){
	vec2 s = gl_FragCoord.xy;
	return fract(
		(sin(dot(s,s)*0.2531+dot(s.xy,s.yx)*0.31343+dot(s,vec2(31.541+fract(seed*50.1191),54.932-fract(seed*30.1191)))-fract(seed*1.7191)))*765.4567
	);
}

vec3 sphere_noise(float seed){
	vec3 n;
	for (int i=0; i<2; i++){ // Reduced from 3 to 2 iterations
		n = (vec3(ss_noise(seed+.93), ss_noise(seed+.31), ss_noise(seed+.56))-vec3(.5))*2.0;
		if (length(n) < 1.0) {
			return n;
		}
	}
	return normalize(n); // Ensure we always return a valid vector
}

float df(vec3 p)//distance function - simplified
{
	float t = iTime;
	p.x+=t*0.07;	
	p.z+=t*.03;

	p.y=abs(p.y);
	p.y-=5.0;
	
	float d = 0.5-p.y;
	
	// Reduced complexity - fewer iterations
	for (int i=0; i<6; i++) // Reduced from 10 to 6
	{
		float fi = float(i);
		
		p+=vec3(1.25-fi,0.0,1.75+fi);
		vec3 pm;
		
		float rep = 10.0+sin(fi*2.0+1.0)*4.0;
		
		pm.xz = mod(p.xz+vec2(rep*.5),vec2(rep))-vec2(rep*.5);
		
		float width = 1.0+sin(fi)*.8;
		float height = 2.0+cos(fi)*1.1;

		vec3 df_vec = abs(vec3(pm.x,p.y+1.0/width,pm.z))-vec3(width,height,width);
		float box = max(max(df_vec.x,df_vec.y),df_vec.z);
	
		d = min(d,box);
	}

	return max(d, 0.001); // Ensure minimum distance to prevent infinite loops
}

vec3 nf(vec3 p, float d){
	vec2 e = vec2(0,d);
	return normalize(vec3(
		df(vec3(p+e.yxx))-df(vec3(p-e.yxx)),
		df(vec3(p+e.xyx))-df(vec3(p-e.xyx)),
		df(vec3(p+e.xxy))-df(vec3(p-e.xxy))
	));
}

float pat(vec3 p){
	float q = 2.0*(abs(fract(df(p+vec3(3.))*13.0)-.5));
	float dq2 = df(p-vec3(1))*.1;
	float q2 = smoothstep(.2,.3, (abs(fract(dq2*32.0)-0.5)*2.0));
	float q3 = smoothstep(.2,.3, (abs(fract(dq2*16.0)-0.5)*2.0));
	return smoothstep(.7,.8,q)*q2*q3;
}

float wave(float x){
	return max(.0, (1./(3.+sin(x)+sin(x*2.)))-.3);
}

// Audio-reactive enhancement
float getAudioLevel() {
	float bass = texture(iChannel0, vec2(0.1, 0.0)).r;
	float mid = texture(iChannel0, vec2(0.5, 0.0)).r;
	float treble = texture(iChannel0, vec2(0.8, 0.0)).r;
	return (bass + mid + treble) / 3.0;
}

vec3 ef(vec3 p){
	float pt = pat(p);
	float audioLevel = getAudioLevel();
	float audioWave1 = wave((p.x+p.z)*.6+iTime) * (1.0 + audioLevel * 2.0);
	float audioWave2 = wave((p.x-p.z)*.125+iTime) * (1.0 + audioLevel * 1.5);
	
	return max(vec3(.0), pt*col_1*20.0*audioWave1)
		+max(vec3(.0), pt*col_2*20.0*audioWave2);
}

vec3 encode_color(vec3 color){
	return (vec3(1.431)*color)/(vec3(1)+color);
}

void main( void ) {
	
	// Audio-reactive color modulation
	float audioLevel = getAudioLevel();
	float bassLevel = texture(iChannel0, vec2(0.1, 0.0)).r;
	float trebleLevel = texture(iChannel0, vec2(0.8, 0.0)).r;
	
	col_1 = mix( vec3(.9,.1,.1), vec3(.2,.5,.9), smoothstep(-.5,.5,sin(iTime*.167 + bassLevel * 3.0)) );
	col_2 = mix( vec3(.7,.3,.1), vec3(.9,.9,.9), smoothstep(-.5,.5,sin(iTime*.134 + trebleLevel * 2.0)) );

	vec2 uv = gl_FragCoord.xy / iResolution.xy;
	vec2 nuv = (uv-0.5)*2.0;

	vec3 color = vec3(0.0);
	float it_count = 0.0;
	float dist = ss_noise(iTime)*.1;
	vec3 pos = vec3(0,0,4);
	vec2 smpn = vec2(ss_noise(iTime+1.),ss_noise(iTime+2.));
	vec3 dir = normalize(vec3((gl_FragCoord.xy+smpn-iResolution.xy*.5)/iResolution.yy, -0.4));
	dir.z += pow(length(dir),2.0)*0.4;
	dir = normalize(dir);
	dir.xy *= rotate(.1);
	dir.xz *= rotate(+iTime*.025 + audioLevel * 0.1);
	pos.xz *= rotate(-iTime*.025 - audioLevel * 0.05);
	
	// Reduced raymarching iterations for performance
	for (int it=0; it<50; it+=1){ // Reduced from 100 to 50
		float d = df(pos+dist*dir);
		dist += d;
		if (d<1e-3 || dist > 50.0) break; // Added max distance check
		it_count = float(it);
	}
	vec3 pos_2 = pos+dist*dir;
	
	vec3 norm = nf(pos_2, 2.0*dist/iResolution.y);
	
	vec3 em_2 = ef(pos_2);
	float pat_2 = pat(pos_2);
	float refl_2 = mix(pow(clamp(1.0+dot(norm, dir),.0,1.),4.0),1.0,0.2);
	
	// Simplified specular - reduced iterations
	vec3 dir_2 = normalize(reflect(dir, norm + max(.0,.005-pat_2)*sphere_noise(iTime+93.1)));
	float dist_2 = ss_noise(iTime+.43)*.1+.1;
	for (int it=0; it<20; it++){ // Reduced from 50 to 20
		float d = df(pos_2+dist_2*dir_2);
		dist_2 += d;
		if (d<1e-3 || dist_2 > 20.0) break; // Added max distance check
	}
	vec3 pos_3 = pos_2+dist_2*dir_2;
	vec3 em_3 = ef(pos_3);
	
	vec3 specular = em_3;
	
	// Simplified diffuse - much fewer samples
	float diffuse_count = .0;
	vec3 diffuse_color = vec3(.0);
	for (int dic=0; dic<4; dic++){ // Reduced from 10 to 4
		vec3 d_dir=normalize(norm + .75*sphere_noise(1.0+dot(pos_2,diffuse_color)-iTime+diffuse_count));
		float d_dist = (1.0/max(0.1, dot(norm, d_dir)))*.005; // Prevent division by zero
		for (int dit=0; dit<5; dit++){ // Reduced from 10 to 5
			float d = df(pos_2+d_dir*d_dist);
			d_dist += d;
			if (d<1e-3 || d_dist > 5.0) break; // Added max distance check
		}
		diffuse_count += 1.0;
		diffuse_color += ef(pos_2+d_dir*d_dist);
	}
	diffuse_color *= mix(1.0, .5,pat_2)/max(1.0, diffuse_count);
	
	color = mix(diffuse_color +mix(em_2, em_2*vec3(.8,.6,.4), pat_2), specular, refl_2);
	color *= (1.0-1.4*length(uv-vec2(0.5)))*2.0;
	
	// Enhanced with audio reactivity
	color *= (1.0 + audioLevel * 0.5);

	// Simplified without complex outline calculations
	color = max(vec3(0), color);
	color += vec3((ss_noise(iTime+9.34)-0.5)*0.005);
	
	// Add time indicator for debugging
	if (uv.x < 0.05 && uv.y < 0.05) {
		float timeIndicator = sin(iTime) * 0.5 + 0.5;
		color = mix(color, vec3(1.0, timeIndicator, 0.0), 0.8);
	}
	
	fragColor = vec4( encode_color(color), 1.0 );
}
