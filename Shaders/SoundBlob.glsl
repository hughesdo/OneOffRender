#version 330 core

// Shadertoy uniforms
uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0; // Audio texture input

// Input from vertex shader
in vec2 fragCoord;

// Output
out vec4 fragColor;

// Constants
#define PI 3.14159
#define TWO_PI 6.2831
#define NUMFREQ 12
#define RM_EPSILON 0.002
#define RM_MIN_STEP_SIZE 0.001
#define RM_MIN_DISTANCE 0.01

// Rotation functions
vec3 rotateX(vec3 p, float a) { 
    float c = cos(a), s = sin(a); 
    return vec3(p.x, c*p.y - s*p.z, s*p.y + c*p.z); 
}

vec3 rotateY(vec3 p, float a) { 
    float c = cos(a), s = sin(a); 
    return vec3(c*p.x + s*p.z, p.y, c*p.z - s*p.x); 
}

vec3 rotateZ(vec3 p, float a) { 
    float c = cos(a), s = sin(a); 
    return vec3(c*p.x - s*p.y, s*p.x + c*p.y, p.z); 
}

// Signed distance primitives (from IQ)
float sdSphere(vec3 p, float r) { 
    return length(p) - r; 
}

float sdTorus(vec3 p, float r, float r2) { 
    return length(vec2(length(p.xz) - r, p.y)) - r2; 
}

float sdBox(vec3 p, vec3 b) { 
    vec3 d = abs(p) - b; 
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0)); 
}

float sdHexPrism(vec3 p, vec2 h) { 
    vec3 q = abs(p); 
    return max(q.z - h.y, max((q.x * 0.866025 + q.y * 0.5), q.y) - h.x); 
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0); 
    return mix(b, a, h) - k * h * (1.0 - h); 
}

// Scene distance function
vec2 map(in vec3 p) 
{
    float freqs[NUMFREQ];
    float t, d, minD = 100000000.0, minID = 0.0;
    float a = 2.5 * TWO_PI, b, c;
    float total = 0.0;
    
    for(int i = 0; i < NUMFREQ; i++) {
        t = float(i) / float(NUMFREQ);
        freqs[i] = texture(iChannel0, vec2(t, 0.25)).x;
        b = sin(PI * t + iTime * 1.3);
        c = t * a;
        d = sdSphere(
            p + vec3(
                cos(c * 0.9 + iTime * 2.0) * b, 
                sin(c + iTime * 1.7) * b, 
                2.0 * t - 1.0
            ) * 0.1, 
            0.01 + freqs[i] * pow(1.11, float(i)) * 0.05
        );        
        total += d;
        minD = smin(minD, d, 0.07);
    }    
    return vec2(1.0, minD);
}

// Calculate scene normal vector at point p
vec3 calcNormal(in vec3 pos, in float epsilon)
{
    vec3 eps = vec3(epsilon, 0.0, 0.0);
    vec3 nor = vec3(
        map(pos + eps.xyy).y - map(pos - eps.xyy).y,
        map(pos + eps.yxy).y - map(pos - eps.yxy).y,
        map(pos + eps.yyx).y - map(pos - eps.yyx).y
    );
    return normalize(nor);
}

// Raymarch function
vec3 rayMarch(in vec3 from, in vec3 direction)
{
    float travel_distance = 0.0;
    for (float i = 0.0; i < 64.0; i += 1.0) 
    {    
        vec3 position = from + direction * travel_distance;
        vec2 result = map(position);  
        
        float object_id = result.x;
        float distance_to_scene = result.y;
        
        if (distance_to_scene < RM_EPSILON)
        {
            return vec3(travel_distance, i / 64.0, object_id);
        }
        travel_distance += max(distance_to_scene, RM_MIN_STEP_SIZE);
    }
    return vec3(0.0, 1.0, 0.0);
}

void main()
{
    // Convert fragCoord to match Shadertoy's pixel coordinates
    vec2 actualFragCoord = fragCoord * iResolution;
    vec2 uv = (actualFragCoord.xy / iResolution.xx) - 
              vec2(0.5, 0.5 * iResolution.y / iResolution.x);
    
    float time = iTime * 1.5;
    float dist = 0.8;
    
    vec3 camera_position = vec3(sin(time) * dist, 0.0, -cos(time) * dist);
    vec3 ray_direction = normalize(vec3(uv, 1.0));
    ray_direction = rotateY(ray_direction, -time);
    
    vec3 result = rayMarch(camera_position, ray_direction); 
    
    float amp = texture(iChannel0, vec2(0.5, 0.75)).x;
    float len_uv = length(uv);
    vec4 color = vec4(vec3(0.3, 0.9, 1.0) * amp * 0.1 / max(len_uv, 0.001), 1.0);
    
    if (result.x != 0.0) {
        vec3 position = camera_position + (ray_direction * result.x);
        vec3 normal = calcNormal(position, 0.001);
        vec3 light = normalize(vec3(-1.0, 1.0, -0.5));
        vec3 reflection = reflect(ray_direction, normal);
        float diffuse = dot(normal, light);
        float specular = pow(clamp(dot(reflection, light), 0.0, 1.0), 20.0);
        float iterations = (1.0 - result.y);
        
        color = vec4(
            vec3(specular * diffuse) * vec3(1.0, 1.0, 1.0) +
            vec3(diffuse * 0.4 + 0.6) * vec3(0.9, 0.5 - (result.y) * 0.5, (1.0 / result.x) * 0.1),
            1.0
        );
    }   
    fragColor = color;
}