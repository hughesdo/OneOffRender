#version 330 core

// Attribution:
// Original ray tracing concept inspired by:
// https://glslsandbox.com/e#27338.10
// Voronoi Variation by Brandon Fogerty (bfogerty at gmail dot com, xdpixel.com)
// Waveform visualization from: https://www.shadertoy.com/view/Wcc3z2
// Author: @XorDev on X (formerly Twitter)
//
// Author (2025-06-15):  @OneHung on X, really screwed things up and tossed a bone to ShaderToy.
//
//
// MODIFID 2025-09-07  RayBalls99.9.glsl - Shadertoy Version with Audio-Reactive Fractal Ball
// Combines raymarching scene with audio-reactive waveform sky and fractal ball
// Both sky and ball react to iChannel0 (audio)
// FIXED: Scene light now stays overhead and invisible
// Converted for OneOffRender system

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

// ============= TWEAKING VARIABLES =============
// Ball animation controls
const float BALL_SPEED = 1.3;          // Speed of ball orbital motion
const float BALL_SIZE = 1.6;           // Size multiplier for orbiting ball
const float ORBIT_RADIUS_BASE = 10.0;   // Base orbit radius
const float ORBIT_HEIGHT = 6.0;        // Height of orbital path

// Camera movement controls
const float CAMERA_ORBIT_SPEED = 0.2;  // Camera rotation speed
const float CAMERA_RADIUS = 18.0;      // Camera distance from center
const float CAMERA_BASE_HEIGHT = 3.9;  // Base camera height
const float MAX_HEIGHT_ADJUST = 3.5;   // Maximum camera height adjustment
const float MAX_TILT_ANGLE = 0.62;     // Maximum tilt angle (radians)
const float CAMERA_PAN_AMOUNT = 0.3;   // Amount of left/right pan at closest approach
const float CAMERA_PAN_SMOOTH = 1.5;   // Smoothness of pan transition

// Lighting controls
const float LIGHT_HEIGHT = 6.0;       // Height of the overhead light (higher = more overhead)
const float LIGHT_ANGLE_X = 0.0;       // Slight X angle offset for light direction (-1 to 1)
const float LIGHT_ANGLE_Z = 0.0;       // Slight Z angle offset for light direction (-1 to 1)
const float AMBIENT_STRENGTH = 2.8;    // Ambient lighting multiplier (0.0 to 2.0)
const float DIFFUSE_STRENGTH = 2.2;    // Direct lighting multiplier (0.0 to 3.0)
const float SCENE_CONTRAST = 1.6;      // Overall scene contrast (0.5 to 2.0)
const float CHECKERBOARD_CONTRAST = 3.2; // Checkerboard contrast (0.0=gray, 1.0=black/white)

// Visual controls
const float EXPOSURE = 0.01;
const float GAMMA = 2.2;
const float INTENSITY = 12.0;
const float SKY_BRIGHTNESS = 10.0;     // Waveform sky brightness multiplier
const float FLOOR_REFLECTION = 0.03;   // Floor reflection intensity
const float BALL_REFLECTIVITY = 0.001;   // Fractal ball reflectivity

// Fractal shader controls (for the ball content)
const float FRACTAL_TIME_SPEED = 3.35; // Speed of fractal animation
const float FRACTAL_ITERATIONS = 110.0;// Raymarching iterations for fractal
const float AUDIO_COLOR_INFLUENCE = 2.3; // How much audio affects fractal colors

// ============= RAY TRACING STRUCTURES =============
struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Light {
    vec3 color;
    vec3 direction;
};

struct Material {
    vec3 color;
    float diffuse;
    float specular;
    bool isFractalBall;
};

struct Intersect {
    float len;
    vec3 normal;
    Material material;
};

struct Sphere {
    float radius;
    vec3 position;
    Material material;
};

struct Plane {
    vec3 normal;
    Material material;
};

const float epsilon = 0.001;
const int iterations = 6;

vec3 ambient = vec3(0.6, 0.8, 1.0) * INTENSITY * AMBIENT_STRENGTH / GAMMA;
Light light;
Intersect miss = Intersect(0.0, vec3(0.0), Material(vec3(0.0), 0.0, 0.0, false));

// ============= AUDIO-REACTIVE FRACTAL GALAXY SKY =============
// CBS - Parallax scrolling fractal galaxy
// Inspired by JoshP's Simplicity shader: https://www.shadertoy.com/view/lslGWr
// http://www.fractalforums.com/new-theories-and-research/very-simple-formula-for-fractal-patterns/

float field(in vec3 p, float s) {
    float strength = 7. + .03 * log(1.e-6 + fract(sin(iTime) * 4373.11));
    float accum = s/4.;
    float prev = 0.;
    float tw = 0.;
    for (int i = 0; i < 26; ++i) {
        float mag = dot(p, p);
        p = abs(p) / mag + vec3(-.5, -.4, -1.5);
        float w = exp(-float(i) / 7.);
        accum += w * exp(-strength * pow(abs(mag - prev), 2.2));
        tw += w;
        prev = mag;
    }
    return max(0., 5. * accum / tw - .7);
}

// Less iterations for second layer
float field2(in vec3 p, float s) {
    float strength = 7. + .03 * log(1.e-6 + fract(sin(iTime) * 4373.11));
    float accum = s/4.;
    float prev = 0.;
    float tw = 0.;
    for (int i = 0; i < 18; ++i) {
        float mag = dot(p, p);
        p = abs(p) / mag + vec3(-.5, -.4, -1.5);
        float w = exp(-float(i) / 7.);
        accum += w * exp(-strength * pow(abs(mag - prev), 2.2));
        tw += w;
        prev = mag;
    }
    return max(0., 5. * accum / tw - .7);
}

vec3 nrand3( vec2 co )
{
    vec3 a = fract( cos( co.x*8.3e-3 + co.y )*vec3(1.3e5, 4.7e5, 2.9e5) );
    vec3 b = fract( sin( co.x*0.3e-3 + co.y )*vec3(8.1e5, 1.0e5, 0.1e5) );
    vec3 c = mix(a, b, 0.5);
    return c;
}

vec3 renderAudioSky(vec2 fragCoord) {
    vec2 uv = 2. * fragCoord.xy / iResolution.xy - 1.;
    vec2 uvs = uv * iResolution.xy / max(iResolution.x, iResolution.y);
    vec3 p = vec3(uvs / 4., 0) + vec3(1., -1.3, 0.);
    p += .2 * vec3(sin(iTime / 16.), sin(iTime / 12.),  sin(iTime / 128.));

    float freqs[4];
    //Sound - adapted for OneOffRender audio texture format
    freqs[0] = texture( iChannel0, vec2( 0.01, 0.0 ) ).x;
    freqs[1] = texture( iChannel0, vec2( 0.07, 0.0 ) ).x;
    freqs[2] = texture( iChannel0, vec2( 0.15, 0.0 ) ).x;
    freqs[3] = texture( iChannel0, vec2( 0.30, 0.0 ) ).x;

    float t = field(p,freqs[2]);
    float v = (1. - exp((abs(uv.x) - 1.) * 6.)) * (1. - exp((abs(uv.y) - 1.) * 6.));

    //Second Layer
    vec3 p2 = vec3(uvs / (4.+sin(iTime*0.11)*0.2+0.2+sin(iTime*0.15)*0.3+0.4), 1.5) + vec3(2., -1.3, -1.);
    p2 += 0.25 * vec3(sin(iTime / 16.), sin(iTime / 12.),  sin(iTime / 128.));
    float t2 = field2(p2,freqs[3]);
    vec4 c2 = mix(.4, 1., v) * vec4(1.3 * t2 * t2 * t2 ,1.8  * t2 * t2 , t2* freqs[0], t2);

    //Let's add some stars
    //Thanks to http://glsl.heroku.com/e#6904.0
    vec2 seed = p.xy * 2.0;
    seed = floor(seed * iResolution.x);
    vec3 rnd = nrand3( seed );
    vec4 starcolor = vec4(pow(rnd.y,40.0));

    //Second Layer
    vec2 seed2 = p2.xy * 2.0;
    seed2 = floor(seed2 * iResolution.x);
    vec3 rnd2 = nrand3( seed2 );
    starcolor += vec4(pow(rnd2.y,40.0));

    vec4 result = mix(freqs[3]-.3, 1., v) * vec4(1.5*freqs[2] * t * t* t , 1.2*freqs[1] * t * t, freqs[3]*t, 1.0)+c2+starcolor;
    return result.rgb * SKY_BRIGHTNESS;
}

// ============= AUDIO-REACTIVE FRACTAL (for ball content) =============
vec3 renderFractalContent(vec2 uv) {
    // Audio sampling for color reactivity
    float bassFreq = texture(iChannel0, vec2(0.01, 0.0)).x;
    float midFreq = texture(iChannel0, vec2(0.1, 0.0)).x;
    float highFreq = texture(iChannel0, vec2(0.3, 0.0)).x;
    
    // Smooth audio for transitions
    bassFreq = smoothstep(0.0, 1.0, bassFreq) * 0.3 * AUDIO_COLOR_INFLUENCE;
    midFreq = smoothstep(0.0, 1.0, midFreq) * 0.2 * AUDIO_COLOR_INFLUENCE;
    highFreq = smoothstep(0.0, 1.0, highFreq) * 0.15 * AUDIO_COLOR_INFLUENCE;
    
    float i, r, s, d, n;
    float t = iTime * FRACTAL_TIME_SPEED;
    vec3 p, q;
    
    vec3 o = vec3(0.0);
    s = 1.0;
    d = 0.0;
    
    // Main raymarching loop
    for(i = 0.0; i < FRACTAL_ITERATIONS; i += 1.0) {
        s = 0.01;
        p = vec3(uv * d, d + t * 8.0);
        r = 20.0 - length(p.xy) * 2.0;
        
        for(n = 0.1; n < 1.0; n *= 1.5) {
            q = p * n;
            float angle = q.z * 0.1;
            mat2 rot = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
            q.xy = rot * q.xy;
            q = abs(q) - n * 0.5;
            vec2 q_offset = q.xy + vec2(0.001, 0.0);
            float pattern = cos(atan(q_offset.y, q_offset.x) * 6.0) * cos(length(q.xy) * 8.0);
            r += pattern * 0.2 / n;
        }
        
        if(r < 0.01) break;
        d += max(r * 0.8, 0.01);
        if(d > 50.0) break;
    }
    
    // Rainbow coloring system with audio reactivity
    vec3 color = vec3(0.0);
    if(i < FRACTAL_ITERATIONS - 1.0) {
        float depth = d * 0.01;
        float detail = r;
        float iteration = i * 0.01;
        
        float angle = atan(uv.y, uv.x + 0.001);
        float radius = length(uv);
        
        // Rainbow hue with audio
        float hue = mod(detail * 0.3 + angle * 0.2 + radius * 1.5 + t * 0.3 + bassFreq, 1.0);
        
        // HSV to RGB conversion
        vec3 hsv = vec3(hue, 0.9 + midFreq * 0.1, 0.95 + highFreq * 0.05);
        vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
        vec3 rainbow = hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
        
        // Secondary rainbow layer
        float hue2 = mod(iteration * 2.0 + angle * 0.1 + t * 0.2 + midFreq, 1.0);
        vec3 hsv2 = vec3(hue2, 0.8, 0.85 + bassFreq * 0.1);
        vec3 p2 = abs(fract(hsv2.xxx + K.xyz) * 6.0 - K.www);
        vec3 rainbow2 = hsv2.z * mix(K.xxx, clamp(p2 - K.xxx, 0.0, 1.0), hsv2.y);
        
        // Spiral rainbow pattern
        float spiral = sin(angle * 6.0 + radius * 8.0 - t * 2.0);
        float spiralHue = mod(spiral * 0.1 + radius * 1.0 + t * 0.25 + highFreq, 1.0);
        vec3 hsv3 = vec3(spiralHue, 1.0, 0.8 + midFreq * 0.2);
        vec3 p3 = abs(fract(hsv3.xxx + K.xyz) * 6.0 - K.www);
        vec3 spiralRainbow = hsv3.z * mix(K.xxx, clamp(p3 - K.xxx, 0.0, 1.0), hsv3.y);
        
        // Combine layers
        color = rainbow * 0.5 + rainbow2 * 0.3 + spiralRainbow * 0.2;
        
        // Metallic effect
        float metallic = 0.8 + 0.2 * sin(detail * 4.0 + t) + bassFreq * 0.1;
        color *= metallic;
        
        // Highlights
        float highlight = pow(1.0 - iteration, 2.0);
        color += highlight * vec3(1.0) * (0.3 + highFreq * 0.1);
        
        // Rainbow glow
        float glow = exp(-radius * 1.5) * 0.6;
        float glowHue = mod(t * 0.3 + radius * 2.0 + bassFreq * 0.5, 1.0);
        vec3 glowHsv = vec3(glowHue, 1.0, 1.0);
        vec3 pGlow = abs(fract(glowHsv.xxx + K.xyz) * 6.0 - K.www);
        vec3 glowRainbow = glowHsv.z * mix(K.xxx, clamp(pGlow - K.xxx, 0.0, 1.0), glowHsv.y);
        color += glow * glowRainbow;
    } else {
        // Background gradient
        float radius = length(uv);
        float bgHue = mod(radius * 2.0 + t * 0.1 + midFreq * 0.2, 1.0);
        vec3 bgHsv = vec3(bgHue, 0.8 + bassFreq * 0.1, 0.3 * exp(-radius * 2.0));
        vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        vec3 p = abs(fract(bgHsv.xxx + K.xyz) * 6.0 - K.www);
        color = bgHsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), bgHsv.y);
    }
    
    color = pow(color, vec3(0.8));
    color *= (1.0 + bassFreq * 0.1);
    return color;
}

// ============= BALL AND CAMERA POSITIONING =============
float getOrbitalAngle(float time) {
    return time * BALL_SPEED * 0.5;
}

vec3 getFractalBallPosition(float time) {
    float angle = getOrbitalAngle(time);
    float ballRadius = 3.0 * BALL_SIZE;
    float orbitRadius = ORBIT_RADIUS_BASE + (ballRadius - 3.0);
    
    float x = cos(angle) * orbitRadius;
    float z = sin(angle) * orbitRadius;
    float y = ORBIT_HEIGHT + (ballRadius - 3.0) * 0.5;
    
    return vec3(x, y, z);
}

struct CameraAdjustment {
    float heightOffset;
    float tiltAngle;
    float panAngle;
};

CameraAdjustment getDynamicCameraAdjustment(float time) {
    CameraAdjustment adj;
    adj.heightOffset = 0.0;
    adj.tiltAngle = 0.0;
    adj.panAngle = 0.0;
    
    float angle = getOrbitalAngle(time);
    float normalizedAngle = mod(angle, 6.28318530718);
    
    // Distance factor for height/tilt
    float distanceFactor = (cos(normalizedAngle) + 1.0) * 0.5;
    
    // Closest point transitions
    float transitionWidth = 1.2;
    float closestFactor = 0.0;
    float distToClosest = min(normalizedAngle, 6.28318530718 - normalizedAngle);
    if (distToClosest < transitionWidth) {
        closestFactor = smoothstep(transitionWidth, 0.0, distToClosest);
    }
    
    // Farthest point transitions
    float farthestFactor = 0.0;
    float distToFarthest = abs(normalizedAngle - 3.14159265359);
    if (distToFarthest < transitionWidth) {
        farthestFactor = smoothstep(transitionWidth, 0.0, distToFarthest);
    }
    
    // Height and tilt adjustments
    adj.heightOffset = -MAX_HEIGHT_ADJUST * closestFactor + MAX_HEIGHT_ADJUST * 0.5 * farthestFactor;
    adj.tiltAngle = MAX_TILT_ANGLE * closestFactor - MAX_TILT_ANGLE * 0.7 * farthestFactor;
    
    // NEW: Pan adjustment during closest approach
    // Pan left when ball approaches from right, pan right when it passes to left
    float panTransitionWidth = CAMERA_PAN_SMOOTH;
    if (distToClosest < panTransitionWidth) {
        // Determine which side the ball is on
        float ballX = cos(normalizedAngle);
        // Smooth pan based on ball position
        adj.panAngle = CAMERA_PAN_AMOUNT * ballX * closestFactor;
    }
    
    return adj;
}

vec3 getCameraPosition(float time) {
    float camAngle = time * CAMERA_ORBIT_SPEED;
    CameraAdjustment adj = getDynamicCameraAdjustment(time);
    
    float adjustedHeight = CAMERA_BASE_HEIGHT + adj.heightOffset;
    
    // Apply pan adjustment to camera angle
    float adjustedCamAngle = camAngle + adj.panAngle;
    
    return vec3(
        CAMERA_RADIUS * sin(adjustedCamAngle),
        adjustedHeight,
        CAMERA_RADIUS * cos(adjustedCamAngle)
    );
}

vec3 getCameraTarget(float time) {
    vec3 baseTarget = vec3(0.0, 2.5, 0.0);
    CameraAdjustment adj = getDynamicCameraAdjustment(time);
    
    // Adjust target with tilt
    float adjustedTargetY = baseTarget.y + adj.tiltAngle * 8.0;
    
    // Also apply slight pan to target for smoother motion
    float adjustedTargetX = baseTarget.x + adj.panAngle * 2.0;
    
    return vec3(adjustedTargetX, adjustedTargetY, baseTarget.z);
}

// ============= RAY TRACING FUNCTIONS =============
Intersect intersect(Ray ray, Sphere sphere) {
    vec3 oc = sphere.position - ray.origin;
    float l = dot(ray.direction, oc);
    float det = pow(l, 2.0) - dot(oc, oc) + pow(sphere.radius, 2.0);
    if (det < 0.0) return miss;

    float len = l - sqrt(det);
    if (len < 0.0) len = l + sqrt(det);
    if (len < 0.0) return miss;

    vec3 norm = (ray.origin + len * ray.direction - sphere.position) / sphere.radius;
    return Intersect(len, norm, sphere.material);
}

Intersect intersect(Ray ray, Plane plane) {
    float len = -dot(ray.origin, plane.normal) / dot(ray.direction, plane.normal);
    if (len < 0.0) return miss;

    vec3 hitp = ray.origin + ray.direction * len;
    float m = mod(hitp.x, 2.0);
    float n = mod(hitp.z, 2.0);
    float d = 1.0;
    if ((m > 1.0 && n > 1.0) || (m < 1.0 && n < 1.0)) {
        // Dark tiles - interpolate between gray and black based on CHECKERBOARD_CONTRAST
        d = mix(0.5, 0.0, CHECKERBOARD_CONTRAST);
    }
    // Light tiles stay at 1.0 (white)

    plane.material.color *= d;
    return Intersect(len, plane.normal, plane.material);
}

Intersect trace(Ray ray) {
    // Original animated spheres
    Sphere sphere0 = Sphere(2.0, vec3(-3.0 - sin(iTime), 3.0 + sin(iTime), 0), 
                            Material(vec3(1.0, 0.0, 0.0), 0.05, 0.01, false));
    Sphere sphere1 = Sphere(3.0, vec3(3.0 + cos(iTime), 3.0, 0), 
                            Material(vec3(0.0, 0.0, 1.0), 0.05, 0.01, false));
    Sphere sphere2 = Sphere(1.0, vec3(0.5, 1.0, 6.0), 
                            Material(vec3(1.0, 1.0, 1.0), 0.001, 0.1, false));

    // Fractal ball with orbital motion
    vec3 fractalBallPos = getFractalBallPosition(iTime);
    float fractalBallRadius = 3.0 * BALL_SIZE;
    Sphere fractalBall = Sphere(fractalBallRadius, fractalBallPos, 
                                Material(vec3(1.0, 1.0, 1.0), 1.0, BALL_REFLECTIVITY, true));

    // Check floor plane
    Intersect closest = intersect(ray, Plane(vec3(0, 1, 0), 
                                            Material(vec3(1.0, 1.0, 1.0), 0.4, 0.9, false)));

    // Check spheres
    Intersect hit0 = intersect(ray, sphere0);
    if ((hit0.material.diffuse > 0.0 || hit0.material.specular > 0.0) &&
        (closest.material.diffuse <= 0.0 && closest.material.specular <= 0.0 || hit0.len < closest.len)) {
        closest = hit0;
    }

    Intersect hit1 = intersect(ray, sphere1);
    if ((hit1.material.diffuse > 0.0 || hit1.material.specular > 0.0) &&
        (closest.material.diffuse <= 0.0 && closest.material.specular <= 0.0 || hit1.len < closest.len)) {
        closest = hit1;
    }

    Intersect hit2 = intersect(ray, sphere2);
    if ((hit2.material.diffuse > 0.0 || hit2.material.specular > 0.0) &&
        (closest.material.diffuse <= 0.0 && closest.material.specular <= 0.0 || hit2.len < closest.len)) {
        closest = hit2;
    }

    // Check fractal ball
    Intersect hitFractal = intersect(ray, fractalBall);
    if ((hitFractal.material.diffuse > 0.0 || hitFractal.material.specular > 0.0) &&
        (closest.material.diffuse <= 0.0 && closest.material.specular <= 0.0 || hitFractal.len < closest.len)) {
        closest = hitFractal;

        // Apply fractal texture to ball surface
        vec3 hitPoint = ray.origin + hitFractal.len * ray.direction;
        vec3 cameraPos = getCameraPosition(iTime);
        vec3 toCamera = normalize(cameraPos - fractalBallPos);

        // Camera-facing coordinate system
        vec3 up = vec3(0.0, 1.0, 0.0);
        vec3 right = normalize(cross(up, toCamera));
        vec3 forward = toCamera;
        up = cross(forward, right);

        vec3 localPoint = hitPoint - fractalBallPos;
        float u = dot(localPoint, right) / fractalBallRadius;
        float v = -dot(localPoint, up) / fractalBallRadius;

        // Get fractal content for this UV
        vec3 fractalColor = renderFractalContent(vec2(u, v));
        closest.material.color = fractalColor;
    }

    return closest;
}

vec3 radiance(Ray ray) {
    vec3 color = vec3(0.);
    vec3 fresnel = vec3(1.0);
    vec3 mask = vec3(1.0);
    Intersect hit;
    vec3 reflection;
    bool hitFloorOnFirstTrace = false;

    // Check for primary miss - render waveform sky
    hit = trace(ray);
    if (hit.material.diffuse <= 0.0 && hit.material.specular <= 0.0) {
        // FIXED: Use ray direction for camera-relative sky coordinates
        // This makes the sky move with camera pans and tilts

        // Convert 3D ray direction to 2D sky coordinates
        // Project ray direction onto a virtual sky dome
        vec3 skyDir = normalize(ray.direction);

        // Convert to spherical coordinates, then to screen-like coordinates
        float skyX = atan(skyDir.x, skyDir.z) / (2.0 * 3.14159) + 0.5; // Azimuth: 0-1
        float skyY = (skyDir.y + 1.0) * 0.5; // Elevation: 0-1 (0=down, 1=up)

        // Scale to resolution for the waveform algorithm
        vec2 skyCoord = vec2(skyX * iResolution.x, skyY * iResolution.y);

        // Only render sky if looking upward (skyY > threshold)
        if (skyY > 0.15) { // Only show sky when looking somewhat upward
            vec3 sky = renderAudioSky(skyCoord);

            // Add brightness boost for better visibility
            sky *= 1.5;

            // Fade sky based on how much we're looking up
            float skyFade = smoothstep(0.15, 0.4, skyY);
            sky *= skyFade;

            return sky;
        } else {
            // Looking down - return dark sky
            return vec3(0.0, 0.0, 0.0);
        }
    }

    // Process raymarching with reflections
    for (int i = 0; i <= iterations; ++i) {
        hit = trace(ray);
        if (hit.material.diffuse > 0.0 || hit.material.specular > 0.0) {
            if (i == 0 && abs(hit.normal.y - 1.0) < 0.1) {
                hitFloorOnFirstTrace = true;
            }

            vec3 r0 = hit.material.color.rgb + hit.material.specular;
            float hv = clamp(dot(hit.normal, -ray.direction), 0.0, 1.0);
            fresnel = r0 + (1.0 - r0) * pow(1.0 - hv, 5.0);

            // Enhanced lighting for fractal ball
            if (hit.material.isFractalBall) {
                float lightDot = max(0.5, dot(hit.normal, light.direction));
                color += hit.material.color.rgb * ambient * 3.0 * mask;
            } else {
                // Shadow calculation for non-fractal objects
                if (trace(Ray(ray.origin + hit.len * ray.direction + epsilon * light.direction, 
                             light.direction)).material.diffuse == 0.0) {
                    color += clamp(dot(hit.normal, light.direction), 0.0, 1.0) * light.color
                           * hit.material.color.rgb * hit.material.diffuse
                           * (1.0 - fresnel) * mask;
                }
            }

            mask *= fresnel;
            reflection = reflect(ray.direction, hit.normal);
            ray = Ray(ray.origin + hit.len * ray.direction + epsilon * reflection, reflection);
        } else {
            // REMOVED: spotLight effect that was making the light visible
            color += ambient * mask;
            break;
        }
    }

    // Add floor reflection
    if (hitFloorOnFirstTrace) {
        // FIXED: Use ray-based reflection coordinates that move with camera
        // Create reflected ray direction for floor reflection
        vec3 reflectedRayDir = reflect(ray.direction, vec3(0.0, 1.0, 0.0)); // Reflect off floor (Y-up)
        vec3 skyDir = normalize(reflectedRayDir);

        // Convert reflected ray to sky coordinates
        float skyX = atan(skyDir.x, skyDir.z) / (2.0 * 3.14159) + 0.5;
        float skyY = (skyDir.y + 1.0) * 0.5;

        vec2 reflectedSkyCoord = vec2(skyX * iResolution.x, skyY * iResolution.y);

        // Only add reflection if the reflected ray would hit sky
        if (skyY > 0.15) {
            vec3 skyReflect = renderAudioSky(reflectedSkyCoord);

            // Boost reflection brightness slightly
            skyReflect *= 1.2;

            // Fade reflection based on reflected ray elevation
            float reflectionFade = smoothstep(0.15, 0.4, skyY);
            skyReflect *= reflectionFade;

            color += skyReflect * FLOOR_REFLECTION;
        }
    }

    return color;
}

// ============= MAIN FUNCTION =============
void main() {
    // Screen coordinates to UV with Y-flip for correct orientation
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    // Set up lighting - ADJUSTABLE: Light height and angle
    light.color = vec3(1.0) * INTENSITY * DIFFUSE_STRENGTH;
    // Create adjustable light direction from high above
    vec3 lightPos = vec3(LIGHT_ANGLE_X, LIGHT_HEIGHT, LIGHT_ANGLE_Z);
    light.direction = normalize(-lightPos); // Points toward origin from light position

    // Set up camera ray
    vec2 uv = (fragCoord.xy / iResolution.xy - vec2(0.5)) * 2.0;
    uv.x *= iResolution.x / iResolution.y;

    vec3 camPos = getCameraPosition(iTime);
    vec3 target = getCameraTarget(iTime);

    vec3 forward = normalize(target - camPos);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);
    vec3 rayDir = normalize(uv.x * right + uv.y * up + forward);

    Ray ray = Ray(camPos, rayDir);
    vec3 finalColor = pow(radiance(ray) * EXPOSURE, vec3(1.0 / GAMMA));
    
    // Apply scene contrast
    finalColor = mix(vec3(0.5), finalColor, SCENE_CONTRAST);
    
    fragColor = vec4(finalColor, 1.0);
}