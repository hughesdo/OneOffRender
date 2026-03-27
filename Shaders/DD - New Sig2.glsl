#version 330 core

// DD - New Sig2
// Created by OneHung
// Generative background (NewSig), @OneHung SDF text, Stargate Kawoosh raymarcher

uniform float iTime;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform sampler2D iChannel0;

out vec4 fragColor;

// --- GLOBAL CONFIG & UTILS ---
#define NEWVALUE values[int(floor(float(v)*rand(seed+float(i))))] * (sin(iTime*rand(seed+float(i)))*rand(seed+float(i)))
#define NEWVALUE2 values[int(floor(float(v)*rand(seed+float(i+5))))] * (sin(iTime*rand(seed+float(i)))*rand(seed+float(i+5)))

int PALETTE = 9;
float gdist = 0.;
const float pi = 3.14159274;
const float tau = 6.28318548;

float rand(float n){return fract(cos(n*89.42)*343.42);}
mat2 rotate2D(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

// --- NEWSIG GENERATIVE BACKGROUND FUNCS ---
float isolines(vec3 p) {
    float s, i, n, T = iTime;
    p += cos(p.z+T+p.yzx*.5)*.6;
    s = 4.-length(p.xy);
    p.xy *= mat2(cos(.3*T+vec4(0,33,11,0)));
    for (n = .01; n < 1.; n += n )
        s -= abs(dot(sin( p.z + T + 4.*p/n ), vec3(1.2))) * n;
    return s;
}

vec3 fire(vec4 o, vec2 u) {
    float d=1.,a,i,s,t = .1*(sin(iTime*.4) + iTime  );
    vec3  p = vec3(iResolution, 1.0);
    u = (u+u-p.xy)/p.y;
    u *= mat2(cos(sin(iTime*.05)*2.+vec4(0,33,11,0)));
    u += cos(t*vec2(.4,.8)) * vec2(.3,.1);
    for(o*=0.; i++<64.; o += 1./s ) {
        p = vec3(u*d,d+t*1e1);
        d += s = .01 + abs(isolines(p))*.15;
    }
    return (vec4(1,.5,0.2,0)*o/1e3).rgb;
}

vec2 shake() {
    return vec2(sin(iTime*1e2), cos(iTime*2e2)) * max(0.,1.2-iTime)/20.;
}

float nz(vec2 nv){
    float o = 0.;
    for (float i = .2; i < 2.; i *= 1.4142) {
        o += abs(dot(sin(nv * i * 64.), vec2(.05))) / i;
    }
    return mix(o, distance(vec2(0), nv), 0.5 + (sin(iTime)/2.));
}

float rMix(float a, float b, float s){
    s = rand(s);
    return s>0.9?sin(a):s>0.8?sqrt(abs(a)):s>0.7?a+b:s>0.6?a-b:s>0.5?b-a:s>0.4?nz(vec2(a,b)):s>0.3?b/(a==0.?0.01:a):s>0.2?a/(b==0.?0.01:b):s>0.1?a*b:cos(a);
}

vec3 gpc(float t) { return 0.5 + 0.5*cos(vec3(0,2,4) + t*2.0); }

vec3 hsl2rgb( in vec3 c ){
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}
vec3 contrast(vec3 color, float value) { return 0.5 + value * (color - 0.5); }
vec3 gammaCorrection (vec3 colour, float gamma) { return pow(colour, vec3(1. / gamma)); }

vec3 addColor(float num, float seed, float alt){
    if(isinf(num)){num = alt * seed;}
    if(PALETTE == 7){
        return contrast(gpc(num),1.7);
    } else if(PALETTE > 2 || (PALETTE == 1 && rand(seed+19.)>0.3)){
        float sat = 1.;
        if(num<0.){sat = 1.-(1./(abs(num)+1.));}
        float light = 1.0-(1./(abs(num)+1.));
        vec3 col = hsl2rgb(vec3(fract(abs(num)), sat, light));
        if(PALETTE == 1){col *= 2.;}
        return col;
    } else {
        vec3 col = vec3(fract(abs(num)), 1./num, 1.-fract(abs(num)));
        if(rand(seed*2.)>0.5){col = col.gbr;}
        if(rand(seed*3.)>0.5){col = col.gbr;}
        if(PALETTE == 1){col += (1.+cos(rand(num)+vec3(4,2,1))) / 2.;}
        return col;
    }
}

vec3 sanitize(vec3 dc){
    dc.r = min(1., dc.r); dc.g = min(1., dc.g); dc.b = min(1., dc.b);
    if(!(dc.r>=0.) && !(dc.r<0.)) return vec3(1,0,0);
    if(!(dc.g>=0.) && !(dc.g<0.)) return vec3(1,0,0);
    if(!(dc.b>=0.) && !(dc.b<0.)) return vec3(1,0,0);
    return dc;
}

vec3 mainAgg(vec2 uv, float seed, float pixely){
    uv.x-=0.5*iResolution.x/iResolution.y;
    uv.y-=0.5;
    uv = pixely>0.?(floor(uv/pixely))*pixely:uv;
    uv += shake();
    float zoom = 4. + (3.*(sin(iTime/1.5)+1.));
    vec2 guv = (uv*zoom);
    float x = guv.x; float y = guv.y;
    float o = nz(guv);
    PALETTE = int(floor(float(8)*rand(seed+66.)));
    const int v = 24;
    vec3 col = vec3(0);
    float cn = 1.;
    float values[v];
    values[0] = 1.0; values[1] = 10.0; values[2] = x; values[3] = y;
    values[4] = x*x; values[5] = y*y; values[6] = x*x*x; values[7] = y*y*y;
    values[8] = x*x*x*x; values[9] = y*y*y*y; values[10] = x*y*x; values[11] = y*y*x;
    values[12] = sin(y); values[13] = cos(y); values[14] = sin(x); values[15] = cos(x);
    values[16] = sin(x)*sin(x); values[17] = cos(x)*cos(x);
    values[18] = 2.; values[19] = distance(vec2(x,y), vec2(0));
    values[20] = 3.14159; values[21] = atan(x, y)*4.; values[22] = o;
    values[23] = distance(vec2(x,y), vec2(0))*sin(atan(x, y));

    float total = 0.; float sub = 0.;
    int maxi = 30; int mini = 5;
    int iterations = min(maxi,mini + int(floor(rand(seed*6.6)*float(maxi-mini))));
    for(int i = 0; i<iterations; i++){
        if(rand(seed+float(i+3))>rand(seed)){
            sub = sub==0. ? rMix(NEWVALUE, NEWVALUE2, seed+float(i+4)) : rMix(sub, rMix(NEWVALUE, NEWVALUE2, seed+float(i+4)), seed+float(i));
        } else {
            sub = sub==0. ? NEWVALUE : rMix(sub, NEWVALUE, seed+float(i));
        }
        if(abs(sub)<1.){seed+=100.;PALETTE = int(floor(float(8)*rand(seed+66.)));}
        if(rand(seed+float(i))>rand(seed)/2.){
            total = total==0. ? sub : rMix(total, sub,seed+float(i*2));
            sub = 0.;
            col += addColor(total, seed+float(i), values[21]);
            cn+=1.;
        }
    }
    total = sub==0. ? total : rMix(total, sub, seed);
    col += addColor(total, seed, values[21]);
    col /=cn;
    if(PALETTE<3){col/=(3.* (0.5 + rand(seed+13.)));}
    if(PALETTE == 4){col = pow(col, 1./col)*1.5;}
    if(PALETTE == 2 || PALETTE == 5){col = hsl2rgb(col);}
    if(PALETTE == 6){
        col = hsl2rgb(hsl2rgb(col));
        if(rand(seed+17.)>0.5) col = col.gbr;
        if(rand(seed+19.)>0.5) col = col.gbr;
    }
    return sanitize(col);
}

// --- '@OneHung' TEXT SDF ---
float dLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}
float df_at(vec2 p) {
    float d = 1e6;
    d = min(d, dLine(p, vec2(-0.4, 0.0), vec2(-0.4, 0.5)));
    d = min(d, dLine(p, vec2(-0.4, 0.5), vec2(0.4, 0.5)));
    d = min(d, dLine(p, vec2(0.4, 0.5), vec2(0.4, -0.5)));
    d = min(d, dLine(p, vec2(0.4, -0.5), vec2(-0.4, -0.5)));
    d = min(d, dLine(p, vec2(-0.4, -0.5), vec2(-0.4, -0.2)));
    // inner 'a'
    d = min(d, dLine(p, vec2(-0.2, 0.2),  vec2(0.2, 0.2)));
    d = min(d, dLine(p, vec2(0.2, 0.2),   vec2(0.2, -0.3)));
    d = min(d, dLine(p, vec2(-0.2, 0.0),  vec2(0.2, 0.0)));
    d = min(d, dLine(p, vec2(-0.2, 0.0),  vec2(-0.2, -0.2)));
    d = min(d, dLine(p, vec2(-0.2, -0.2), vec2(0.2, -0.2)));
    d = min(d, dLine(p, vec2(-0.2, 0.0),  vec2(-0.2, 0.2)));
    return d;
}
float df_O(vec2 p) {
    float d = 1e6;
    d = min(d, dLine(p, vec2(-0.3, -0.4), vec2(-0.3, 0.4)));
    d = min(d, dLine(p, vec2(-0.3, 0.4), vec2(0.3, 0.4)));
    d = min(d, dLine(p, vec2(0.3, 0.4), vec2(0.3, -0.4)));
    d = min(d, dLine(p, vec2(0.3, -0.4), vec2(-0.3, -0.4)));
    return d;
}
float df_n(vec2 p) {
    float d = 1e6;
    d = min(d, dLine(p, vec2(-0.3, -0.4), vec2(-0.3, 0.4)));
    d = min(d, dLine(p, vec2(-0.3, 0.4), vec2(0.3, 0.4)));
    d = min(d, dLine(p, vec2(0.3, 0.4), vec2(0.3, -0.4)));
    return d;
}
float df_e(vec2 p) {
    float d = 1e6;
    d = min(d, dLine(p, vec2(0.3, 0.0), vec2(-0.3, 0.0)));
    d = min(d, dLine(p, vec2(-0.3, 0.0), vec2(-0.3, 0.4)));
    d = min(d, dLine(p, vec2(-0.3, 0.4), vec2(0.3, 0.4)));
    d = min(d, dLine(p, vec2(0.3, 0.4), vec2(0.3, 0.0)));
    d = min(d, dLine(p, vec2(-0.3, 0.0), vec2(-0.3, -0.4)));
    d = min(d, dLine(p, vec2(-0.3, -0.4), vec2(0.3, -0.4)));
    return d;
}
float df_H(vec2 p) {
    float d = 1e6;
    d = min(d, dLine(p, vec2(-0.3, -0.4), vec2(-0.3, 0.4)));
    d = min(d, dLine(p, vec2(0.3, -0.4), vec2(0.3, 0.4)));
    d = min(d, dLine(p, vec2(-0.3, 0.0), vec2(0.3, 0.0)));
    return d;
}
float df_u(vec2 p) {
    float d = 1e6;
    d = min(d, dLine(p, vec2(-0.3, 0.4), vec2(-0.3, -0.4)));
    d = min(d, dLine(p, vec2(-0.3, -0.4), vec2(0.3, -0.4)));
    d = min(d, dLine(p, vec2(0.3, -0.4), vec2(0.3, 0.4)));
    return d;
}
float df_g(vec2 p) {
    float d = 1e6;
    d = min(d, dLine(p, vec2(-0.3, 0.0), vec2(0.3, 0.0)));
    d = min(d, dLine(p, vec2(-0.3, 0.0), vec2(-0.3, 0.4)));
    d = min(d, dLine(p, vec2(-0.3, 0.4), vec2(0.3, 0.4)));
    d = min(d, dLine(p, vec2(0.3, 0.4), vec2(0.3, -0.4)));
    d = min(d, dLine(p, vec2(0.3, -0.4), vec2(-0.3, -0.4)));
    d = min(d, dLine(p, vec2(-0.3, -0.4), vec2(-0.3, -0.2)));
    return d;
}
float getOneHungText(vec2 p) {
    float d = 1e6;
    // Shifted blocky characters with extra breathing room
    d = min(d, df_at(p - vec2(-4.2, 0.0)));
    d = min(d, df_O(p - vec2(-3.0, 0.0)));
    d = min(d, df_n(p - vec2(-1.8, 0.0)));
    d = min(d, df_e(p - vec2(-0.6, 0.0)));
    d = min(d, df_H(p - vec2(0.6, 0.0)));
    d = min(d, df_u(p - vec2(1.8, 0.0)));
    d = min(d, df_n(p - vec2(3.0, 0.0)));
    d = min(d, df_g(p - vec2(4.2, 0.0)));
    return d;
}

// --- STARGATE KAWOOSH RAYMARCHER ---
float global_t = 0.0;
float sg_prd = 0.0;
const int maxstps = 64;
const float maxdst = 10.0;
const float mindst = 0.005;

const mat3 m3 = mat3( 0.33338, 0.56034, -0.71817,
                     -0.87887, 0.32651, -0.15323,
                      0.15162, 0.69596,  0.61139) * 1.93;

float gyroidFBM4D(vec4 p) {
    float d = 0.0;  float z = 2.0; float trk = 1.0; float dspAmp = 0.125;
    for (int i = 0; i < 7; i++) {
        p += sin(p.zwyx * 0.75 * trk) * dspAmp;
        d -= abs(dot(cos(p), sin(p.wxyz)) * z);
        z *= 0.57; trk *= 1.5; p.xyz *= m3; p.w -= iTime * 0.4;
    }
    return d;
}

vec3 twistSpace(vec3 p, float k) {
    float c = cos(k * p.x); float s = sin(k * p.x);
    mat2  m = mat2(c, -s, s, c);
    return vec3(m * p.yz, p.x).zyx;
}

float vertCylSDF(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.yz), p.x)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float vertCapsSDF(vec3 p, float h, float r) {
    p.x -= clamp(p.x, 0.0, h);
    return length(p) - r;
}

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * (1.0 / 4.0);
}

float smoothestStep(float edge0, float edge1, float x) {
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    float x2 = x * x;
    return x2 * x2 * (x * (x * (x * -20.0 + 70.0) - 84.0) + 35.0);
}

// Raymarch map. Camera is ro=(-5,0,0), rd converges along +X.
// Stargate Water is a disc on the YZ plane (x=0).
float mapSG(vec3 p) {
    // Water Pool radius: 0 before Kawoosh, expands to 2.25 over 1 second
    float water_rad = smoothstep(11.5, 12.5, global_t) * 2.25;
    if (water_rad < 0.01) return maxdst;

    vec3 q = twistSpace(p, -1.5);
    q = p.x < 0.0 ? q : p;
    float disp = gyroidFBM4D(vec4(q + vec3(iTime * 0.4, 0.0, 0.0), 0.0));

    // Flat cylinder on YZ plane
    float cylinder = vertCylSDF(p, 0.0, water_rad) + disp * 0.025;

    // Kawoosh blorb outward
    float capsule_rad = p.x > 0.0 ? 0.7 : 0.9 + p.x * 0.4;
    capsule_rad *= smoothstep(11.5, 12.5, global_t) * 1.5;

    // Animate kawoosh splashing forward heavily on X axis
    float splash_x = sin(clamp((global_t - 11.5) / 4.5, 0.0, 1.0) * pi) * -6.0;
    float capsule = vertCapsSDF(q - vec3(splash_x, 0.0, 0.0), 2.0, capsule_rad);

    float blorb = (capsule + disp * 0.15) * 0.8;
    float portal = smin(blorb, cylinder, 0.7);

    return mix(cylinder, portal, sg_prd);
}

float rayMarch(vec3 ro, vec3 rd, out float ns) {
    float dO = 0.0; ns = 0.0;
    for(int i = 0; i < maxstps; i++) {
        vec3 p = ro + rd * dO;
        float dS = mapSG(p);
        dO += dS; ns++;
        if(dO > maxdst || abs(dS) < mindst) break;
    }
    ns = smoothestStep(0.1, 1.0, ns * 0.015);
    return dO;
}

vec3 getNormal(vec3 p) {
    vec3 pe = vec3(0.001, 0.0, 0.0);
    // Backward difference
    vec3 n = mapSG(p) - vec3(mapSG(p - pe.xyy), mapSG(p - pe.yxy), mapSG(p - pe.yyx));
    return normalize(n);
}

// --- MAIN INTEGRATION ---
void mainImage0(out vec4 fragColor, vec2 fragCoord) {
    vec2 p = fragCoord;
    vec2 res = iResolution.xy;
    vec2 uv = (p - 0.5 * res) / iResolution.y;

    // TIMELINE CONFIG: 25 second grand loop
    global_t = mod(iTime, 25.0);
    sg_prd = 0.0;
    if (global_t > 11.5 && global_t < 16.0) {
        // Kawoosh protrusion amount controls 3D blending
        sg_prd = sin((global_t - 11.5) / 4.5 * pi);
        sg_prd = smoothestStep(0.01, 1.0, sg_prd);
    }

    // Audio Visualizer
    float audioBoost = 0.02; // Default if iChannel0 has no sound
    float audio_uv = fract(abs(atan(uv.x, uv.y)) / pi);
    audioBoost = mix(0.005, 0.08, texture(iChannel0, vec2(audio_uv, 0.25)).x);

    float r = length(uv);
    float outer_radius = 0.45;

    if (r > outer_radius + audioBoost) {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0); // True black outside
        return;
    }

    // Outer Audio Frequency Monitor Ring
    if (r > outer_radius) {
        float angle = atan(uv.x, uv.y);
        float bars = step(0.1, fract(angle * 30.0 / pi)); // Creates 60 distinct segments
        float intensity = max(0.0, 1.0 - (r - outer_radius) / max(0.001, audioBoost));
        fragColor = vec4(vec3(0.1, 0.8, 1.0) * intensity * bars, 1.0);
        return;
    }

    // --- STARGATE KAWOOSH & WATER RAYMARCHER ALONG X-AXIS ---
    vec3 sg_col = vec3(0.0);
    float sg_alpha = 0.0;
    vec2 text_uv = uv; // The Text will wave with the water surface

    if (global_t > 11.5) {
        vec3 ro = vec3(-5.0, 0.0, 0.0);
        vec3 rd = normalize(vec3(1.0, uv.x, uv.y));

        float numsteps;
        float d = rayMarch(ro, rd, numsteps);
        if (d < maxdst) {
            vec3 p3 = ro + rd * d;
            vec3 n = getNormal(p3);

            vec3 lp0 = vec3(-2.0, 3.0, 5.0);
            vec3 lp1 = vec3(cos(iTime) * 1.5 + 1.0, 0.0, 0.0);
            float diff0 = dot(n, normalize(lp0 - p3)) * 0.5 + 0.5;
            float diff1 = dot(n, normalize(lp1 - p3)) * 0.5 + 0.5;
            float latt = pow(length(lp1 - p3) * 0.2, 2.0) / (pow(numsteps, 2.0) + 0.1);
            float frsn = pow(1.0 + dot(rd, n), 2.0);

            sg_col = mix(vec3(0.0, 0.2, 0.5) / mix(latt, 4.0, 1.0 - sg_prd), vec3(0.2, 0.5, 0.7), frsn);
            sg_col = mix(sg_col, vec3(1.0), numsteps);
            sg_col = pow(sg_col, vec3(0.4545));

            sg_alpha = smoothstep(11.5, 11.6, global_t);
            float wave_intensity = mix(0.06, 0.015, smoothstep(16.0, 18.0, global_t));
            text_uv += n.yz * wave_intensity * sg_alpha;
        }
    }

    // --- RENDER NEWSIG BACKGROUND ---
    vec2 h = (p / res * 2. - 1.) * sqrt(res / res.yx);
    vec3 g = vec3(1, h.yx) / (dot(h, h) + 1.) + vec3(-.5, 0, .5);
    h = g.xy / dot(g, g);
    h = vec2(atan(h.x, h.y), log(length(h))) / tau;
    h += vec2(max(iMouse.x, 10.)/400., max(iMouse.y, 10.)/400.)+iTime/40.;
    h *= mat2(8, 5, -5, 8);
    vec2 cellID = mod(floor(h), vec2(8,5));

    float pma = .11, pmb = .07, pmc = .23;
    bool hotCell = cellID==vec2(mod(floor(rand(floor(iTime*pma))*8.),8.), mod(floor(rand(floor(iTime*pma))*5.),5.))
                || cellID==vec2(mod(floor(rand(floor(iTime*pmb))*8.),8.), mod(floor(rand(floor(iTime*pmb))*5.),5.))
                || cellID==vec2(mod(floor(rand(floor(iTime*pmc))*8.),8.), mod(floor(rand(floor(iTime*pmc))*5.),5.));

    vec2 cellUV = fract(h);
    float seed = cellID.x + cellID.y * 10.0;

    // Spiraling Animation via text_uv (which might be wavy!)
    float t_scale = mix(2.0, 0.1, clamp(global_t / 7.0, 0.0, 1.0));
    float t_rot = mix(-10.0, 0.0, clamp(global_t / 7.0, 0.0, 1.0));

    // Add audio scale pulse when fully shrunk
    if (global_t > 7.0) { t_scale -= audioBoost * 0.15; }

    vec2 luv = rotate2D(t_rot) * text_uv / t_scale;
    float dist = getOneHungText(luv);

    // Remap to pixel space
    dist *= t_scale;

    // Dynamic thickness: thick at the start, thin when shrunk to avoid bunching!
    float thickness = mix(0.15, 0.025, clamp(global_t / 7.0, 0.0, 1.0));
    dist -= thickness;

    // Background color rendering
    vec3 col = mainAgg(cellUV, seed, (hotCell?0.05:0.08));
    vec4 c = vec4(col, 1.0);
    vec3 cf = fire(vec4(0), p);

    if(hotCell && dist < 0.0) c.rgb = cf;
    if(dist < 0.0){
        c.rgb -= pow(max(abs(cellUV.x - .5), abs(cellUV.y - .5)) * 2.15, 16.0)/3.0;
    }

    if(dist >= 0.0 && !hotCell) {
        c.rgb = clamp(c.rgb, vec3(0), vec3(1));
        c.b = 1.0 + audioBoost * 10.0; // Audio Reactive Glow!
        c.rgb += tanh(dist * 12.0);
    } else if (dist >= 0.0 && hotCell){
        if(c.r>0.5||c.g>0.5||c.b<0.3) c.rgb = (c.rgb+vec3(4.))/3.;
        else c.rgb = (c.rgb+vec3(2.))/2.;
        c.rgb = cf.bgr+0.5;
    }

    // Stargate overrides the ambient environment ONLY outside the letters
    if (dist >= 0.0) {
        c.rgb = mix(c.rgb, sg_col, sg_alpha);
    }

    // Create a thick black outline around the text
    float outline_thickness = 0.012;
    float outline_mask = smoothstep(0.0, outline_thickness, dist);
    if (dist > 0.0 && dist < outline_thickness) {
        c.rgb *= smoothstep(0.0, outline_thickness, dist) * 0.5;
    }

    float thr = clamp(1.-abs(dist*100.), 0.0, 1.0);
    c = mix(c, vec4(0,0.0,0.5,1), thr);
    gdist = dist;

    if(dist>0.){
        c = mix(c, vec4(cf.bgr, 1.0), max(0.,min(1.,tanh(dist*2.))) * (1.0 - sg_alpha));
    }

    // Text Shake Effect before kawoosh
    if (global_t > 8.0 && global_t < 11.5 && dist < 0.0) {
        c.rgb += vec3(sin(global_t * 50.0)) * 0.2;
    }

    // Slight blue wash to the text if Stargate is active (looks magical)
    if (dist < 0.0 && sg_alpha > 0.0) {
        c.rgb = mix(c.rgb, vec3(0.1, 0.4, 1.0), 0.3 * sg_alpha);
    }

    // Final Fade out reset
    if (global_t > 24.0) {
        c.rgb *= smoothstep(25.0, 24.0, global_t);
    }

    fragColor = c;
}

void mainImage(out vec4 o, vec2 u) {
    float s = 1.0, k;
    vec2 j = vec2(.5);
    o = vec4(0);
    vec4 c;
    mainImage0(c, u);

    o = c;
    o.a = 1.0;
    o = gdist > 0. ? tanh(o * 1.9) : tanh(o * 1.4);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
