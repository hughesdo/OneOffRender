#version 330 core

// fragmentcompofix_skycolorspinner_300es - OneOffRender Version
// Converted from GLSL Sandbox format to OneOffRender
// Complex sky spinner scene with procedural effects

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

#define pi acos(-1.0)
#define twoPi acos(-1.0) * 2.0
#define COLOR_N vec3(0.15, 0.34, 0.6)

// Audio-reactive functions
float getFFT(float freq) {
    return texture(iChannel0, vec2(freq, 0.0)).r;
}

float getFFTSmoothed(float freq) {
    float sum = 0.0;
    float samples = 5.0;
    for(float i = 0.0; i < samples; i++) {
        float offset = (i - samples * 0.5) * 0.02;
        sum += texture(iChannel0, vec2(clamp(freq + offset, 0.0, 1.0), 0.0)).r;
    }
    return sum / samples;
}

vec2 mainPoint;
float voronoiStrength = 0.022;
float spinnerAt = 0.0;

mat2 rotate(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

vec2 random2d2d(vec2 p){
    return fract(sin(vec2(dot(p.xy,vec2(12.532,95.235)), dot(p.xy,vec2(42.532,65.235))))*24627.1245);
}

float random1d2d(vec2 p){
    return fract(sin(dot(p.xy, vec2(12.532, 95.235))) * 24627.1245);
}

float random(vec3 v) { 
	return fract(sin(dot(v, vec3(12.9898, 78.233, 19.8321))) * 43758.5453);
}

float valueNoise(vec3 v) {
	vec3 i = floor(v);
	vec3 f = smoothstep(0.0, 1.0, fract(v));
	return  mix(
		mix(
			mix(random(i), random(i + vec3(1.0, 0.0, 0.0)), f.x),
			mix(random(i + vec3(0.0, 1.0, 0.0)), random(i + vec3(1.0, 1.0, 0.0)), f.x),
			f.y
		),
		mix(
			mix(random(i + vec3(0.0, 0.0, 1.0)), random(i + vec3(1.0, 0.0, 1.0)), f.x),
			mix(random(i + vec3(0.0, 1.0, 1.0)), random(i + vec3(1.0, 1.0, 1.0)), f.x),
			f.y
		),
		f.z
	);
}

float fbm(vec3 v) {
	float n = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		n += a * valueNoise(v);
		v *= 2.0;
		a *= 0.5;
	}
	return n;
}

float sdPlane(vec3 p, vec4 n) 
{
    return dot(p, n.xyz) + n.w;
}

float dPlaneBottom(vec3 p) 
{
    // Audio-reactive plane distortion
    return sdPlane(p, vec4(0.0, 1.0, 0.0, 1.0)) * 0.8 + sin(p.z*4.0 + iTime*2.0 + getFFT(0.1)*5.0)*0.05;
}

float sdCappedCylinder(vec3 p, float h, float r){
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCone(vec3 p, vec2 c, float h){
    vec2 q = h * vec2(c.x/c.y, -1.0);
    
    vec2 w = vec2(length(p.xz), p.y);
    vec2 a = w - q * clamp(dot(w,q)/dot(q,q), 0.0, 1.0);
    vec2 b = w - q * vec2(clamp(w.x/q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a), dot(b, b));
    float s = max(k*(w.x*q.y - q.x*w.y), k*(w.y-q.y));
    return sqrt(d) * sign(s);
}

float sdSpinner(vec3 p){
    float c = 0.0;
    vec3 p1 = p;
    p1.xy *= rotate(pi);
    c += sdCone(p1 - vec3(0.0, 0.5722, 0.0), vec2(1.122, 0.82), 0.472);

    vec3 p2 = p;
    float cyl = sdCappedCylinder(p2, 0.12, 0.622);
    c = min(c, cyl);

    vec3 p3 = p;
    float axis = sdCappedCylinder(p3 - vec3(0.0, -0.1, 0.0), 0.62, 0.032);
    c = min(c, axis);

    return c;
}

float dSpinner(vec3 p){
    p.y += 0.36;
    // Audio-reactive spinner rotation
    p.xz *= rotate(iTime + getFFTSmoothed(0.05) * 3.0);
    p.xy *= rotate(0.2 + getFFT(0.2) * 0.5);
    return sdSpinner(p);
}

float smoothMin(float a, float b, float k){
    float h = clamp(0.5 + 0.5 * (b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float distanceFunction(vec3 p)
{
    vec3 p1 = p;
    float d = 0.0;
    d += dSpinner(p1);
    spinnerAt += 0.4/(0.4+abs(d));

    vec3 p2 = p;
    d = smoothMin(d, dPlaneBottom(p2), 0.01);

    return d;
}

vec3 getNormal(vec3 p){
    vec2 err = vec2(0.01, 0.0);
    return normalize(vec3(
        distanceFunction(p + err.xyy) - distanceFunction(p - err.xyy),
        distanceFunction(p + err.yxy) - distanceFunction(p - err.yxy),
        distanceFunction(p + err.yyx) - distanceFunction(p - err.yyx)
    ));
}

float starOrb(vec2 uv, vec2 p, float flare){
    float c = 0.0;
    uv -= p;
    float d = length(uv);
    c += 0.2/d;

    float ray = max(0.0, 1.0 - abs(uv.x*uv.y*200.0));
    c += ray*flare;
    uv *= rotate(pi/4.0);
    ray = max(0.0, 1.0 - abs(uv.x*uv.y*500.0));
    c += ray*0.2*flare;

    c *= smoothstep(0.4, 0.2, d);

    return c;
}

vec3 latticeStarField(vec2 uv, float s, vec2 subPos){
    vec3 color = vec3(0.0);

    uv *= s;
    uv += subPos;

    vec2 fPos = fract(uv) - 0.5;
    vec2 iPos = floor(uv);

    for(float y = -1.0; y <= 1.0; y+=1.0){
        for(float x = -1.0; x <= 1.0; x+=1.0){
            vec2 offset = vec2(x, y);
            float n = random1d2d(iPos+offset);
            float s = fract(n*4052.22);
            float star = starOrb(fPos-offset, vec2(n, fract(n*34.24)), smoothstep(0.1, 0.02, s)); 
            color += pow(star * s, 2.0);
        }
    }
    
    return color;
}

vec3 skyTexture(vec2 uv, float size, vec3 baseColor, float scrollSpeed, float timeSeed){
    vec2 uv2 = uv * size;
    vec3 col = vec3(0.0);

    // Audio-reactive sky texture
    float audioMod = getFFTSmoothed(0.1) * 0.5;
    
    vec3 noiseCol = pow(vec3(fbm(vec3(uv2 + vec2(0.0, iTime*(scrollSpeed + 0.1) + timeSeed + audioMod), 122.2))), vec3(2.0));
    noiseCol += pow(vec3(fbm(vec3(uv2 + vec2(0.0, iTime*(scrollSpeed + 0.2) + timeSeed + audioMod), 422.2))), vec3(3.2));
    noiseCol += pow(vec3(fbm(vec3(uv2 + vec2(0.0, iTime*(scrollSpeed + 0.3) + timeSeed + audioMod), 522.2))), vec3(4.0));

    col += mix(baseColor, vec3(1.0), pow(noiseCol, vec3(3.0)));
    
    // Add audio-reactive color enhancement
    col += getFFT(0.2) * vec3(0.3, 0.6, 1.0);

    return col;
}

vec3 voronoi(vec2 uv, float s)
{   
    vec2 uv2 = uv * s;

    vec2 iPos= floor(uv2);
    vec2 fPos = fract(uv2);

    vec3 returnParam = vec3(0.0);
    float dist = 999.0;
    vec2 point = vec2(8.0);
    vec2 offset = vec2(8.0);
    vec2 diff = vec2(8.0);
    for(int y = -1; y <= 1; y++){
        for(int x = -1 ; x <= 1; x++){
            vec2 o = vec2(float(x), float(y));
            vec2 p = random2d2d(iPos + o);

            // Audio-reactive voronoi movement
            p = 0.5 + 0.5 * sin(iTime*0.2 + twoPi * p + getFFTSmoothed(0.15) * 2.0);

            vec2 di = o + p - fPos;
            float d = dot(di, di);

            point = mix(point, p, (1.0 - step(dist, d)));
            offset = mix(offset, o, (1.0 - step(dist, d)));
            diff = mix(diff, di, (1.0 - step(dist, d)));
            dist = mix(dist, d, (1.0 - step(dist, d)));
        }
    }
    
    // Edge calculation
    dist = 999.0;
    for(int y = -2; y <= 2; y++){
        for(int x = -2 ; x <= 2; x++){
            vec2 o = offset + vec2(float(x), float(y));
            vec2 p = random2d2d(iPos + o);

            p = 0.5 + 0.5 * sin(iTime*0.2 + twoPi * p + getFFTSmoothed(0.15) * 2.0);

            vec2 di = o + p - fPos;

            dist = mix(dist, min(dist, dot(0.5*(diff+di), normalize(di-diff))), (1.0 - step(dot(diff-di, diff-di), 0.0001)));
        }
    }

    mainPoint = point;
    returnParam = vec3(dist, diff);

    return returnParam;
}

float easeInOutExpo(float t)
{
    if (t == 0.0 || t == 1.0) {
        return t;
    }
    if ((t *= 2.0) < 1.0) {
        return 0.5 * pow(2.0, 10.0 * (t - 1.0));
    } else {
        return 0.5 * (-pow(2.0, -10.0 * (t - 1.0)) + 2.0);
    }
}

float linearStep(float start, float end, float t)
{
    return clamp((t - start) / (end - start), 0.0, 1.0);
}

vec3 background(vec3 rayDir){
    float k = rayDir.y * 0.5 + 0.5;
    vec3 color = vec3(0.0);
    for(float i = 0.0; i <= 1.0; i+=1.0/5.0){
        float depth = fract(iTime*0.2 + i);
        float scale = mix(3.0, 0.1, depth);
        float fade = depth*smoothstep(10.0, 0.001, depth);
        
        // Audio-reactive star field
        float audioFlicker = sin(i*200.0+iTime*4.0 + getFFT(0.3)*10.0) * 0.1 + 0.1;
        color.r += latticeStarField(rayDir.xy*rotate(i*234.25), scale, vec2(i*222.87)).r*(fade*audioFlicker);

        depth = fract(iTime*0.2 + i + 0.01);
        scale = mix(3.0, 0.1, depth);
        fade = depth*smoothstep(10.0, 0.001, depth);
        color.g += latticeStarField(rayDir.xy*rotate(i*234.25), scale, vec2(i*222.87)).g*(fade*audioFlicker);

        depth = fract(iTime*0.2 + i - 0.01);
        scale = mix(3.0, 0.1, depth);
        fade = depth*smoothstep(10.0, 0.001, depth);
        color.b += latticeStarField(rayDir.xy*rotate(i*234.25), scale, vec2(i*222.87)).b*(fade*audioFlicker);
    }
    return mix(vec3(1.0), color, k);
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);
    vec3 camPos = vec3(0.0, 0.5, -2.5);
    vec3 objectPos = vec3(0.0, 0.0, 0.0);
    vec3 forward = normalize(objectPos - camPos);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(forward, up));
    up = normalize(cross(right, forward));
    
    // Audio-reactive FOV
    float fov = 1.0 + getFFTSmoothed(0.05) * 0.5;
    vec3 rayDir = normalize(uv.x * right + uv.y * up + fov * forward);

    float d = 0.0;
    float df = 0.0;
    vec3 p = vec3(0.0);
    bool isHit = false;
    for(int i = 0; i < 100; i++){ // Reduced iterations for performance
        p = camPos + rayDir * d;
        df = distanceFunction(p);
        if(df <= 0.001){
            isHit = true;
            break;
        }
        if(df > 100.0){
            break;
        }
        d += df;
    }

    if(isHit){
        if(dPlaneBottom(p) <= 0.001){
            vec2 mappingUv = p.xz;
            float voro = voronoiStrength/voronoi(mappingUv + vec2(iTime*0.01, 0.0), 2.0).x;
            vec3 skyColor = skyTexture(mappingUv + voro*0.5, 2.0, mix(COLOR_N, vec3(1.0), smoothstep(0.0, 102.0, d)), 1.0, 2.0);
            color += skyColor;
            color += voro*0.1;
        }

        if(dSpinner(p) <= 0.001){
            vec3 skyColor = skyTexture(rayDir.xy, 9.0, mix(COLOR_N, vec3(1.0), smoothstep(0.0, 32.0, d)), 0.2, 2.0);
            color = skyColor;
        }

    }else{
        vec3 skyColor = skyTexture(rayDir.yx, 20.0, COLOR_N, 0.1, 2.0);
        color +=  skyColor;
    }

    color += pow(background(rayDir), vec3(12.0))*smoothstep(0.0, 32.0, d);
    color += pow(spinnerAt * 0.05 + getFFT(0.1) * 0.1, 8.0); // Audio-reactive spinner glow
    color = pow(color, vec3(0.4545));

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x, iResolution.y);
    uv.y = -uv.y; // Fix upside-down orientation
    vec3 color = vec3(0.0);

    color += renderingFunc(uv);

    // Add some audio-reactive color enhancement
    color += getFFTSmoothed(0.05) * vec3(0.1, 0.2, 0.4);

    fragColor = vec4(color, 1.0);
}
