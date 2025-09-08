#version 330 core

/*
Gyroid Art
Original: https://www.shadertoy.com/view/X32czG
Inspired by shadertoyjiang
Real-time ray marched gyroid surface
Converted for OneOffRender system
*/

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture (required but not used)
out vec4 fragColor;

// 2D rotation matrix
mat2 rot(float t) {
    return mat2(cos(t), sin(t), -sin(t), cos(t));
}

// Smooth minimum function for blending
float smin(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

// Smooth maximum function
float smax(float d1, float d2, float k) {
    return smin(d1, d2, -k);
}

// Gyroid distance function
float gyroid(vec3 p) {
    float r = 4.25;  // Radius
    float d1 = length(p) - r;

    vec3 q = p;
    float d2 = dot(cos(q.yzx * 4.0), sin(q * 4.0)) / 4.0;

    float k = 32.0;  // Frequency
    float d6 = dot(cos(p * k), sin(p.yzx * k)) / k;

    float d5 = length(max(abs(vec2(d2, d1)), 0.0)) - 0.03;

    float dist = 0.5 * smin(d5, length(smax(0.0, smax(d1, smax(abs(d2), abs(d6) - 0.01, 0.03), 0.03), 0.01)) - 0.001, 0.01);

    return dist;
}

// Scene mapping function
float map(vec3 p) {
    float t = iTime * 1.0;  // Speed multiplier

    // Apply rotations (using time instead of mouse)
    p.xz *= rot(t * 0.05);
    p.yz *= rot(t * 0.02);
    p.xy *= rot(t * 0.03);

    return gyroid(p);
}

// Soft shadow calculation
float calcSoftShadow(vec3 ro, vec3 rd) {
    float res = 1.0;
    float t = 0.001;
    float ph = 1e10;
    float w = 0.2;

    for (int i = 0; i < 24; i++) {
        float h = map(ro + rd * t);

        float y = h * h / (2.0 * ph);
        float d = sqrt(h * h - y * y);
        res = min(res, d / (w * max(0.0, t - y)));
        ph = h;

        t += h;

        if (res < 0.0001 || t > 5.0) break;
    }

    res = clamp(res, 0.0, 1.0);
    return res * res * (3.0 - 2.0 * res);
}

// Normal calculation using central differences
vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Screen coordinates to UV with Y-flip for correct orientation
    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;

    // Camera setup
    float zoom = 9.0;
    vec3 ro = vec3(0.0, 0.0, -zoom);  // Ray origin
    vec3 rd = normalize(vec3(uv, 1.5));  // Ray direction
    vec3 lightDir = normalize(vec3(-1.0, 2.0, -3.0));

    float t = 0.0;
    vec3 color = vec3(0.0);
    bool hit = false;

    // Ray marching loop
    for (int i = 0; i < 128; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);

        if (d < 0.01) {  // Hit surface
            vec3 normal = getNormal(p);

            // Lighting calculations
            float diff = max(dot(normal, lightDir), 0.0);
            float spec = pow(max(dot(reflect(-lightDir, normal), -rd), 0.0), 32.0);

            // Base color with iridescent effect
            vec3 baseColor = 0.5 + 0.5 * cos(iTime * 0.5 + p * 2.0 + vec3(0.0, 2.0, 4.0));

            color = baseColor * (diff + 0.1) + spec * 0.5;

            // Apply soft shadows
            vec3 shadowRay = normalize(lightDir * 100.0 - p);
            float shadow = calcSoftShadow(p - rd * 0.001, shadowRay);
            color *= (shadow + 0.2);

            // Distance fog
            color *= smoothstep(600.0, 0.0, length(p));

            hit = true;
            break;
        }

        t += d * 0.95;  // Step along ray

        if (t > 100.0) break;  // Max distance
    }

    if (!hit) {
        // Background gradient
        color = mix(vec3(0.05, 0.1, 0.2), vec3(0.0), length(uv));
    }

    // Gamma correction
    color = pow(color, vec3(0.8));

    fragColor = vec4(color, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}