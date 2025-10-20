// Created by dila in 2015-08-02
// https://www.shadertoy.com/view/llXXzf

#version 330 core

// Uniforms
uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio (unused in this shader but declared)
uniform sampler2D iChannel1;  // Abstract 1.jpg (3D texture)
uniform sampler2D iChannel2;  // Uffizi Gallery Blurred.png (environment map)

// Output
out vec4 fragColor;

const float pi = 3.14159;

mat3 xrot(float t)
{
    return mat3(1.0, 0.0, 0.0,
                0.0, cos(t), -sin(t),
                0.0, sin(t), cos(t));
}

mat3 yrot(float t)
{
    return mat3(cos(t), 0.0, -sin(t),
                0.0, 1.0, 0.0,
                sin(t), 0.0, cos(t));
}

mat3 zrot(float t)
{
    return mat3(cos(t), -sin(t), 0.0,
                sin(t), cos(t), 0.0,
                0.0, 0.0, 1.0);
}

vec2 map(vec3 p)
{
    p.x += sin(p.z);
    p *= zrot(p.z);
    float d = 1000.0;
    vec3 q = fract(p) * 2.0 - 1.0;
    float idx = 0.0;
    for (int i = 0; i < 3; ++i) {

		q = sign(q) * (1.0 - 1.0 / (1.0 + abs(q) * 0.8));
        
        float md = length(q) - 0.5;
        
        float ss = 0.5 + 0.5 * sin(p.z + md * float(i) * 6.0);

        float cyl = length(p.xy) - 0.5 - ss;
        
        md = max(md, -cyl);
        
        if (md < d) {
            d = md;
            idx = float(i);
        }
    } 
    return vec2(d, idx);
}

vec3 normal(vec3 p)
{
	vec3 o = vec3(0.1, 0.0, 0.0);
    return normalize(vec3(map(p+o.xyy).x - map(p-o.xyy).x,
                          map(p+o.yxy).x - map(p-o.yxy).x,
                          map(p+o.yyx).x - map(p-o.yyx).x));
}

float trace(vec3 o, vec3 r)
{
 	float t = 0.0;
    for (int i = 0; i < 64; ++i) {
     	vec3 p = o + r * t;
        float d = map(p).x;
        t += d * 0.3;
    }
    return t;
}

vec3 _texture(vec3 p)
{
 	vec3 ta = texture(iChannel1, vec2(p.y,p.z)).xyz;
    vec3 tb = texture(iChannel1, vec2(p.x,p.z)).xyz;
    vec3 tc = texture(iChannel1, vec2(p.x,p.y)).xyz;
    return (ta + tb + tc) / 3.0;
}

void main()
{
	vec2 fragCoord = gl_FragCoord.xy;
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    uv = uv * 2.0 - 1.0;
    
    uv.x *= iResolution.x / iResolution.y;
    
    vec3 r = normalize(vec3(uv, 1.0 - dot(uv,uv) * 0.33));
    
    r *= zrot(iTime * 0.25) * yrot(-sin(iTime));
    
    vec3 o = vec3(0.0, 0.0, 0.0);
    o.z += iTime;
    o.x += -sin(o.z);
    
    float t = trace(o, r);
    vec3 w = o + r * t;
    vec3 sn = normal(w);
    vec2 fd = map(w);
    vec3 ref = reflect(r, sn);
    
    vec3 diff = vec3(0.0, 0.0, 0.0);
    if (fd.y == 0.0) {
        diff = vec3(1.0, 0.0, 0.0);
    } else if (fd.y == 1.0) {
        diff = vec3(0.0, 1.0, 0.0);
    } else if (fd.y == 2.0) {
        diff = vec3(0.0, 0.0, 1.0);
    } else {
        diff = vec3(1.0, 1.0, 1.0);
    }
    
    diff += _texture(w);
    // Convert vec3 reflection to vec2 for 2D texture sampling (spherical mapping)
    vec2 ref_uv = vec2(atan(ref.z, ref.x) / (2.0 * pi) + 0.5, asin(ref.y) / pi + 0.5);
    diff += texture(iChannel2, ref_uv).xyz;
    
    diff = mix(diff, vec3(1.0), abs(sn.y));
    diff = mix(vec3(0.8, 0.0, 0.0), diff, abs(sn.y));
    
    float prod = max(dot(sn, -r), 0.0);
    diff *= prod;
    
    float fog = 1.0 / (1.0 + t * t * 0.1 + fd.x * 100.0);
    vec3 fc = diff * fog;
    
	fragColor = vec4(sqrt(fc), 1.0);
}