#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Canyon Cruise
// Created by diatribes
// Shadertoy ID: M3GfRt
// https://www.shadertoy.com/view/M3GfRt

#define CAVERN_RADIUS 35.
#define MAX_STEPS 100.
#define MAX_DIST 300.
#define SURFACE_DIST .001
#define inf (MAX_DIST*2.)
#define TIME_MULTIPLIER 12.

vec3 path1(float z) {
    return vec3(
        tan(cos(z * .1) * .75)+(cos(z * .05) * 10.),
        sin(sin(z * .1)) * 6.,
        z
    );
}

vec3 path2(float z) {
    return vec3(
        CAVERN_RADIUS - sin(sin(z * .1)) * 6.,
        2. + sin(sin(z * .2)) * 6.,
        z
    ) ;
}

float scene(vec3 p, out vec3 rgb) {
    float d1 = length(p.xy - path1(p.z).xy);
    float d2 = length(p.xy - path2(p.z).xy);
    float structure = CAVERN_RADIUS - min(d1, d2);
    float ground = p.y-10.;
    float hit = max(ground,structure);
    rgb = vec3(.125,.125,.08);
    return hit;
}

float raymarch(vec3 ro, vec3 rd, out vec3 rgb, bool skipRiver) {
    float dist = 0.0;
    for(float i = 0.; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dist;
        float step = scene(p, rgb);
        dist += step;
        if(dist > MAX_DIST || step < SURFACE_DIST) {
            break;
        }
    }
    return dist;
}

mat3 lookAt(vec3 origin, vec3 target, float roll) {
    vec3 rr = vec3(sin(roll), cos(roll), 0.0);
    vec3 ww = normalize(target - origin);
    vec3 uu = normalize(cross(ww, rr));
    vec3 vv = normalize(cross(uu, ww));
    return mat3(uu, vv, ww);
}

vec3 normal(vec3 p) {
    vec2 e = vec2(.01, 0);
    vec3 rgb;
    vec3 n = scene(p,rgb) - vec3(
        scene(p-e.xyy,rgb),
        scene(p-e.yxy,rgb),
        scene(p-e.yyx,rgb));
    return normalize(n);
}

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    vec3 rgb = vec3(1.);
    vec2 uv = -1.0 + 2.0*(u/iResolution.xy);
	uv.x *= iResolution.x/iResolution.y;
	vec3 ro = vec3(0., 0., iTime*TIME_MULTIPLIER);
	vec3 la = ro + vec3(0., 0., 1.);
    la.xy = ro.xy = path1(ro.z).xy;
	vec3 rd = normalize(vec3(uv,1.)*lookAt(ro,la,0.));
	float d = raymarch(ro, rd, rgb, true);
    vec3 p = ro + rd * d;
    rgb *= 1./pow(d,d*.005);
    vec3 red = vec3(1.0, 0.05, 0.125);
    vec3 blue = vec3(0.0, 0.5, 0.8);
    float diffuse = max(dot(normal(p), normalize(ro-p)), .9);
    if (d >= MAX_DIST) {
       rgb = mix(red.xyz, blue.xyz, uv.y);
    } else {
        rgb *= diffuse;
    }
    o = vec4(pow(rgb, vec3(.45)), 1.0);
    fragColor = o;
}

