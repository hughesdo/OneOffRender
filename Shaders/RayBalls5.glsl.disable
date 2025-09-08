#version 330

// RayBalls5.glsl - RayBalls4 with Audio-Reactive Waveform Sky
// Combines the raymarching scene from RayBalls4.glsl with the audio-reactive 
// waveform visualization from Waveform.glsl as the background sky
// 
// Attribution:
// Original ray tracing concept inspired by:
// https://glslsandbox.com/e#27338.10
// Voronoi Variation by Brandon Fogerty (bfogerty at gmail dot com, xdpixel.com)
// Waveform visualization from: https://www.shadertoy.com/view/Wcc3z2
// Author: @XorDev on X (formerly Twitter)
//
// Enhanced for DISCO project with video morphing, dynamic camera tracking, and audio-reactive sky

// Standard uniforms that your processor provides
uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // video texture
uniform sampler2D iChannel1;  // audio texture for waveform

// Simple user controls (non-audio-reactive)
uniform float ballSpeed;        // Speed of video ball animation
uniform float ballSize;         // Size multiplier for video ball
uniform float videoReflectivity; // Controls video ball reflectivity (0.0-1.0)

// Input/output for fragment shader
in vec2 v_text;
out vec4 fragColor;

// Original ray tracing structures (simplified)
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
    bool isVideoBall;
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

// DARK SKY:
//const float exposure = 0.001;  // restored original low baseline  0.002
//const float gamma = 2.2;   // 2.0 - 2.6
//const float intensity = 100.0;  // optional: you can leave at 100 if you like
//const vec3 ambient = vec3(0.6, 0.8, 1.0) * intensity / gamma;

// XOrDev's Waveform is in the sky with a world view, it needs light!
//const float exposure = 0.01;   // Try 0.01 to 0.05 for starters
//const float gamma = 2.2;       // sRGB standard, keep
//const float intensity = 1.0;   // You can keep 1.0 to 10.0 for light balance
//const vec3 ambient = vec3(0.6, 0.8, 1.0) * intensity / gamma;

// Not bad just dark still
//const float exposure = 0.02;
//const float gamma = 2.2;
//const float intensity = 5.0;
//const vec3 ambient = vec3(0.6, 0.8, 1.0) * intensity / gamma;

// The scene is now bright the sky not so much
const float exposure = 0.02;
const float gamma = 2.2;
const float intensity = 20.0;
const vec3 ambient = vec3(0.6, 0.8, 1.0) * intensity / gamma;


Light light;
Intersect miss = Intersect(0.0, vec3(0.0), Material(vec3(0.0), 0.0, 0.0, false));

// Audio-reactive waveform sky function (adapted from Waveform.glsl)
vec3 renderAudioSky(vec2 fragCoord) {
    // shift the whole animation up by 20% of the screen
    float yOffset = iResolution.y * 0.20;
    fragCoord.y -= yOffset;

    vec4 O = vec4(0.0);
    vec2 I = fragCoord;
    float i, d, z, rr;

    for (O *= i; i++ < 90.0;
         O += (cos(z * 0.5 + iTime + vec4(0,2,4,3)) + 1.3) / d / z )
    {
        vec3 R = vec3(iResolution.x, iResolution.y, iResolution.y);
        vec3 p = z * normalize(vec3(I + I, 0.0) - R);
        rr = max(-++p, 0.0).y;
        // sample audio texture: x coordinate from geometry, y from depth
        float a = texture(iChannel1, vec2((p.x + 6.5) / 15.0,
                      (-p.z - 3.0) * 50.0 / R.y)).r;
        p.y += rr + rr - 4.0 * a;
        z += d = 0.1 * (0.1 * rr + abs(p.y) / (1.0 + rr + rr + rr*rr)
                       + max(d = p.z + 3.0, -d * 0.1));
    }
    O = tanh(O / 900.0);

    // ENHANCED: Increase waveform brightness for better visibility
	//return O.rgb;
    return O.rgb * 20.0; // Boost brightness significantly  The sky was black without Waveform before.
}




// NEW: Enhanced timing with video morphing and camera transition phases
bool isIntroPhase(float time) {
    float animTime = time * ballSpeed;
    float introDuration = 15.0 / 30.0; // 0.5 seconds of normal fullscreen video
    return animTime < introDuration;
}

bool isVideoMorphPhase(float time) {
    float animTime = time * ballSpeed;
    float introDuration = 15.0 / 30.0; // 0.5 seconds normal video
    float morphDuration = 15.0 / 30.0; // 0.5 seconds morphing
    return animTime >= introDuration && animTime < (introDuration + morphDuration);
}

bool isCameraTransitionPhase(float time) {
    float animTime = time * ballSpeed;
    float introDuration = 15.0 / 30.0; // 0.5 seconds normal video
    float morphDuration = 15.0 / 30.0; // 0.5 seconds morphing
    float totalVideoDuration = introDuration + morphDuration; // 1.0 seconds total
    float transitionDuration = 90.0 / 30.0; // 3 seconds camera pullback
    return animTime >= totalVideoDuration && animTime < (totalVideoDuration + transitionDuration);
}

float getVideoMorphFactor(float time) {
    float animTime = time * ballSpeed;
    float introDuration = 15.0 / 30.0; // 0.5 seconds normal video
    float morphDuration = 15.0 / 30.0; // 0.5 seconds morphing
    
    if (animTime < introDuration) {
        return 0.0; // Pure flat video
    } else if (animTime < (introDuration + morphDuration)) {
        float t = (animTime - introDuration) / morphDuration;
        return smoothstep(0.0, 1.0, t); // Smooth morph from flat to ball
    } else {
        return 1.0; // Pure video ball
    }
}

float getCameraTransitionFactor(float time) {
    float animTime = time * ballSpeed;
    float totalVideoDuration = 30.0 / 30.0; // 1.0 seconds total video (intro + morph)
    float transitionDuration = 90.0 / 30.0; // 3 seconds camera pullback

    if (animTime < totalVideoDuration) {
        return 0.0; // Before camera transition
    } else if (animTime < (totalVideoDuration + transitionDuration)) {
        float t = (animTime - totalVideoDuration) / transitionDuration;
        return smoothstep(0.0, 1.0, t); // Smooth camera pullback
    } else {
        return 1.0; // Camera transition complete
    }
}

// NEW: Get orbital angle and related calculations for dynamic camera
float getOrbitalAngle(float time) {
    if (isIntroPhase(time) || isVideoMorphPhase(time)) {
        return 0.0; // No orbital motion during video phases
    }
    
    float animTime = (time * ballSpeed) - (30.0 / 30.0); // Subtract total video duration
    return animTime * 0.5; // Same as in getVideoBallPosition
}

// NEW: Calculate dynamic camera adjustments based on video ball position
struct CameraAdjustment {
    float heightOffset;
    float tiltAngle;
};

CameraAdjustment getDynamicCameraAdjustment(float time) {
    CameraAdjustment adj;
    adj.heightOffset = 0.0;
    adj.tiltAngle = 0.0;
    
    // Only apply during normal orbital phase
    if (isIntroPhase(time) || isVideoMorphPhase(time) || isCameraTransitionPhase(time)) {
        return adj;
    }
    
    float angle = getOrbitalAngle(time);
    
    // Normalize angle to 0-2π range for consistent calculations
    float normalizedAngle = mod(angle, 6.28318530718); // 2π
    
    // Calculate distance factor: 0.0 at closest (angle=0), 1.0 at farthest (angle=π)
    float distanceFactor = (cos(normalizedAngle) + 1.0) * 0.5;
    
    // Define adjustment parameters
    float maxHeightAdjustment = 3.5; // Maximum camera height adjustment
    float maxTiltAngle = 0.62; // Maximum tilt angle in radians (~8.6 degrees)
    float transitionWidth = 1.2; // How wide the transition zone is (in radians)
    
    // Create smooth transitions around critical points
    // Closest point: angle ≈ 0 or 2π
    float closestFactor = 0.0;
    float distToClosest = min(normalizedAngle, 6.28318530718 - normalizedAngle);
    if (distToClosest < transitionWidth) {
        closestFactor = smoothstep(transitionWidth, 0.0, distToClosest);
    }
    
    // Farthest point: angle ≈ π
    float farthestFactor = 0.0;
    float distToFarthest = abs(normalizedAngle - 3.14159265359); // π
    if (distToFarthest < transitionWidth) {
        farthestFactor = smoothstep(transitionWidth, 0.0, distToFarthest);
    }
    
    // Apply adjustments
    // When closest: camera moves down (negative height), tilts up (positive angle)
    adj.heightOffset = -maxHeightAdjustment * closestFactor + maxHeightAdjustment * 0.5 * farthestFactor;
    
    // When closest: tilt up to see ball better
    // When farthest: tilt down to avoid obstruction
    adj.tiltAngle = maxTiltAngle * closestFactor - maxTiltAngle * 0.7 * farthestFactor;
    
    return adj;
}

// ENHANCED: Continuous orbit animation starting after video phases
vec3 getVideoBallPosition(float time) {
    if (isIntroPhase(time)) {
        // During intro: position ball far away so it doesn't interfere
        return vec3(0.0, 0.0, -1000.0);
    } else if (isVideoMorphPhase(time)) {
        // During morph: transition from screen center to orbital start position
        float morphFactor = getVideoMorphFactor(time);

        // Start position: screen center for morphing
        vec3 startPos = vec3(0.0, 0.0, 0.0);

        // End position: where orbital motion will begin
        float videoBallRadius = 3.0 * ballSize;
        float orbitRadius = 9.0 + (videoBallRadius - 3.0); //dh 8
        float orbitY = 6.0 + (videoBallRadius - 3.0) * 0.5;
        vec3 endPos = vec3(orbitRadius, orbitY, 0.0); // Start of orbital motion

        // Smooth transition from center to orbital start position
        return mix(startPos, endPos, morphFactor);
    }

    // After video phases: normal orbital motion starting immediately
    float animTime = (time * ballSpeed) - (30.0 / 30.0); // Subtract total video duration (1 second)

    // Dynamic orbit radius that scales with ball size to prevent collisions
    float videoBallRadius = 3.0 * ballSize;
    float orbitRadius = 9.0 + (videoBallRadius - 3.0);  //dh 8

    // Continuous orbit - radius and height scale with ball size
    float angle = animTime * 0.5; // Orbit speed
    float x = cos(angle) * orbitRadius;
    float z = sin(angle) * orbitRadius;

    // Y position scales with ball size to maintain clearance above other spheres
    float y = 6.0 + (videoBallRadius - 3.0) * 0.5;

    return vec3(x, y, z);
}

float getVideoBallSize(float time) {
    if (isIntroPhase(time)) {
        // During intro: tiny size so it's not visible
        return 0.1;
    } else if (isVideoMorphPhase(time)) {
        // During morph: transition from fullscreen size to video ball size
        float morphFactor = getVideoMorphFactor(time);

        // Start size: large enough to fill screen when at center
        float startSize = 8.0 * ballSize;

        // End size: normal video ball size
        float endSize = 3.0 * ballSize;

        // Smooth transition from fullscreen to ball size
        return mix(startSize, endSize, morphFactor);
    }

    // After video phases: normal size for orbital motion
    return 3.0 * ballSize;
}

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
        d *= 0.5;
    }

    plane.material.color *= d;
    return Intersect(len, plane.normal, plane.material);
}

// ENHANCED: Calculate camera position with dynamic adjustments
vec3 getCameraPosition(float time) {
    // Original camera parameters (the target position)
    float maxVideoBallRadius = 3.0 * ballSize;
    float maxOrbitRadius = 8.0 + (maxVideoBallRadius - 3.0);
    float maxExtent = maxOrbitRadius + maxVideoBallRadius;
    float originalRadius = max(18.0, maxExtent * 1.3);
    float baseHeight = 3.7; // Original camera height

    // Camera angle that continues smoothly throughout
    float camAngle = time * 0.2;

    if (isIntroPhase(time) || isVideoMorphPhase(time)) {
        // During intro and morph: calculate what the camera position would be
        // (not used during 2D rendering, but keeps continuity)
        return vec3(
            originalRadius * sin(camAngle),
            baseHeight,
            originalRadius * cos(camAngle)
        );
    } else if (isCameraTransitionPhase(time)) {
        // During transition: smooth pullback from video ball to original position
        float transitionFactor = getCameraTransitionFactor(time);

        // Get current video ball position for close-up camera
        vec3 videoBallPos = getVideoBallPosition(time);

        // Close-up camera position: close enough to nearly fill screen with video ball
        float videoBallRadius = getVideoBallSize(time);
        float closeUpDistance = videoBallRadius * 2.5; // Close enough to nearly fill screen

        // Position camera slightly offset from ball for better viewing angle
        vec3 closeUpOffset = normalize(vec3(1.0, 0.3, 1.0)); // Slight angle
        vec3 closeUpCamPos = videoBallPos + closeUpOffset * closeUpDistance;

        // Target camera position (where we're transitioning TO)
        // This should match the camera angle at the END of transition
        vec3 targetCamPos = vec3(
            originalRadius * sin(camAngle),
            baseHeight,
            originalRadius * cos(camAngle)
        );

        // Smooth transition from close-up to target camera position
        return mix(closeUpCamPos, targetCamPos, transitionFactor);
    } else {
        // ENHANCED: Normal camera behavior with dynamic adjustments
        CameraAdjustment adj = getDynamicCameraAdjustment(time);

        // Apply height adjustment
        float adjustedHeight = baseHeight + adj.heightOffset;

        // Base camera position
        vec3 baseCamPos = vec3(
            originalRadius * sin(camAngle),
            adjustedHeight,
            originalRadius * cos(camAngle)
        );

        return baseCamPos;
    }
}

// ENHANCED: Calculate camera target with dynamic tilt adjustments
vec3 getCameraTarget(float time) {
    vec3 baseTarget = vec3(0.0, 2.5, 0.0); // Default scene center

    if (isCameraTransitionPhase(time)) {
        // During transition: smoothly transition from looking at ball to scene center
        float transitionFactor = getCameraTransitionFactor(time);
        vec3 ballTarget = getVideoBallPosition(time);
        return mix(ballTarget, baseTarget, transitionFactor);
    } else if (!isIntroPhase(time) && !isVideoMorphPhase(time)) {
        // ENHANCED: Apply dynamic tilt adjustments during orbital phase
        CameraAdjustment adj = getDynamicCameraAdjustment(time);

        // Adjust target height based on tilt angle
        // Positive tilt angle = look up (higher target Y)
        // Negative tilt angle = look down (lower target Y)
        float adjustedTargetY = baseTarget.y + adj.tiltAngle * 8.0; // Scale factor for tilt sensitivity

        return vec3(baseTarget.x, adjustedTargetY, baseTarget.z);
    }

    return baseTarget;
}

// Get current camera position for camera-locked texture calculations
vec3 getCurrentCameraPos() {
    return getCameraPosition(iTime);
}

Intersect trace(Ray ray) {
    // Original spheres exactly as in the original
    Sphere sphere0 = Sphere(2.0, vec3(-3.0 - sin(iTime), 3.0 + sin(iTime), 0), Material(vec3(1.0, 0.0, 0.0), 0.05, 0.01, false));
    Sphere sphere1 = Sphere(3.0, vec3(3.0 + cos(iTime), 3.0, 0), Material(vec3(0.0, 0.0, 1.0), 0.05, 0.01, false));
    Sphere sphere2 = Sphere(1.0, vec3(0.5, 1.0, 6.0), Material(vec3(1.0, 1.0, 1.0), 0.001, 0.1, false));

    // Video ball with higher orbit - non-reflective material for clear video visibility
    vec3 videoBallPos = getVideoBallPosition(iTime);
    float videoBallRadius = getVideoBallSize(iTime);
    // Video ball material with user-controllable reflectivity
    // IMPORTANT: Initialize with white color, will be replaced with video texture
    Sphere videoBall = Sphere(videoBallRadius, videoBallPos, Material(vec3(1.0, 1.0, 1.0), 1.0, videoReflectivity, true));

    Intersect closest = intersect(ray, Plane(vec3(0, 1, 0), Material(vec3(1.0, 1.0, 1.0), 0.4, 0.9, false)));

    // Check each sphere individually like the original
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

    // Check video ball and apply camera-locked texture
    Intersect hitVideo = intersect(ray, videoBall);
    if ((hitVideo.material.diffuse > 0.0 || hitVideo.material.specular > 0.0) &&
        (closest.material.diffuse <= 0.0 && closest.material.specular <= 0.0 || hitVideo.len < closest.len)) {
        closest = hitVideo;

        // CAMERA-LOCKED VIDEO TEXTURE (Billboard Style)
        vec3 hitPoint = ray.origin + hitVideo.len * ray.direction;
        vec3 cameraPos = getCurrentCameraPos();
        vec3 toCamera = normalize(cameraPos - videoBallPos);

        // Create camera-facing coordinate system
        vec3 up = vec3(0.0, 1.0, 0.0);
        vec3 right = normalize(cross(up, toCamera));
        vec3 forward = toCamera;
        up = cross(forward, right); // Recompute up to ensure orthogonality

        // Get surface point relative to ball center
        vec3 localPoint = hitPoint - videoBallPos;

        // Project onto camera-facing plane
        float u = 0.5 + dot(localPoint, right) / (videoBallRadius * 2.0);
        float v = 0.5 - dot(localPoint, up) / (videoBallRadius * 2.0);  // Flip V to fix upside-down video

        // Clamp UV coordinates to valid range
        u = clamp(u, 0.0, 1.0);
        v = clamp(v, 0.0, 1.0);

        // Sample video texture with camera-locked coordinates
        vec3 videoColor = texture(iChannel0, vec2(u, v)).rgb;

        // Ensure video is visible - add fallback for debugging
        if (length(videoColor) < 0.01) {
            // Fallback: bright magenta to indicate texture sampling issue
            videoColor = vec3(1.0, 0.0, 1.0);
        }

        closest.material.color = videoColor;
    }

    return closest;
}

vec3 radiance(Ray ray) {
    vec3 color = vec3(0.);
    vec3 fresnel = vec3(1.0);
    vec3 mask = vec3(1.0);
    Intersect hit;
    vec3 reflection;
    vec3 spotLight;
    bool hitFloorOnFirstTrace = false;

    // FIXED: Check for primary miss first - only apply waveform to true sky pixels
    hit = trace(ray);
    if (hit.material.diffuse <= 0.0 && hit.material.specular <= 0.0) {
        // PRIMARY MISS: This pixel sees only sky - render waveform background
        vec2 fragCoord = vec2(v_text.x * iResolution.x, v_text.y * iResolution.y);

        // COORDINATE REMAPPING: Transform sky region coordinates to full waveform space
        // Assume sky occupies roughly the top 60% of the screen (Y > 0.4 * height)
        float skyStartY = iResolution.y * 0.4; // Sky starts at 40% from bottom
        float skyHeight = iResolution.y * 0.6;  // Sky occupies top 60%

        // Remap Y coordinate: translate and scale so sky region maps to full waveform height
        vec2 remappedCoord = fragCoord;
        if (fragCoord.y > skyStartY) {
            // This pixel is in sky region - remap Y to full waveform range
            float skyY = fragCoord.y - skyStartY;  // Translate: 0 = start of sky
            remappedCoord.y = (skyY / skyHeight) * iResolution.y;  // Scale: stretch to full height
        } else {
            // This shouldn't happen since we're only calling this on misses, but safety fallback
            remappedCoord.y = 0.0;
        }

        vec3 sky = renderAudioSky(remappedCoord);

        // Sharp spotlight - only add spotlight if looking directly at sun
        spotLight = vec3(1e6) * pow(abs(dot(ray.direction, light.direction)), 250.0);

        // Return waveform sky with spotlight
        return sky + spotLight;
    }

    // OBJECT HIT: Process normal raymarching with reflections (no waveform bleeding)
    for (int i = 0; i <= iterations; ++i) {
        hit = trace(ray);
        if (hit.material.diffuse > 0.0 || hit.material.specular > 0.0) {
            // Check if we hit the floor on the very first trace
            if (i == 0 && abs(hit.normal.y - 1.0) < 0.1) {
                hitFloorOnFirstTrace = true;
            }

            vec3 r0 = hit.material.color.rgb + hit.material.specular;
            float hv = clamp(dot(hit.normal, -ray.direction), 0.0, 1.0);
            fresnel = r0 + (1.0 - r0) * pow(1.0 - hv, 5.0);

            // ENHANCED LIGHTING FOR VIDEO BALL (no shadow check)
            if (hit.material.isVideoBall) {
                // Video ball gets enhanced lighting without shadow calculation
                float lightDot = max(0.5, dot(hit.normal, light.direction));
                //color += lightDot * light.color * hit.material.color.rgb * hit.material.diffuse * (1.0 - fresnel) * mask;
                // Add extra ambient for video visibility
                color += hit.material.color.rgb * ambient * 3.0 * mask;  //dh 0.3 too reflective
            } else {
                // ORIGINAL SHADOW CALCULATION FOR NON-VIDEO OBJECTS
                if (trace(Ray(ray.origin + hit.len * ray.direction + epsilon * light.direction, light.direction)).material.diffuse == 0.0) {
                    color += clamp(dot(hit.normal, light.direction), 0.0, 1.0) * light.color
                           * hit.material.color.rgb * hit.material.diffuse
                           * (1.0 - fresnel) * mask;
                }
            }

            mask *= fresnel;
            reflection = reflect(ray.direction, hit.normal);
            ray = Ray(ray.origin + hit.len * ray.direction + epsilon * reflection, reflection);
        } else {
            // Sharp black horizon - only add spotlight if looking directly at sun
            spotLight = vec3(1e6) * pow(abs(dot(ray.direction, light.direction)), 250.0);
            
			// Subtle fill so horizon can still lift slightly without going mid-gray
            //vec3 backgroundAmbient = ambient * 0.03;
            //color += mask * (backgroundAmbient + spotLight);
			
			// I think the above was a mistake introduced at some point -DH
			color *= mask * (ambient + spotLight);
            
			break;
        }
    }

    // FIXED: Only add floor reflection if the PRIMARY ray hit the floor
    if (hitFloorOnFirstTrace) {
        // Get reflected sky coordinates (flip Y) using proper gl_FragCoord
        vec2 fragCoord = vec2(v_text.x * iResolution.x, v_text.y * iResolution.y);
        vec2 reflectedCoord = vec2(fragCoord.x, iResolution.y - fragCoord.y);

        // COORDINATE REMAPPING FOR REFLECTION: Same sky region mapping as above
        float skyStartY = iResolution.y * 0.4;
        float skyHeight = iResolution.y * 0.6;

        // Remap reflected coordinates to sky region
        vec2 remappedReflectedCoord = reflectedCoord;
        if (reflectedCoord.y > skyStartY) {
            float skyY = reflectedCoord.y - skyStartY;
            remappedReflectedCoord.y = (skyY / skyHeight) * iResolution.y;
        } else {
            remappedReflectedCoord.y = 0.0;
        }

        vec3 skyReflect = renderAudioSky(remappedReflectedCoord);

        // Subtle blend of reflected waveform onto floor (preserve checkerboard pattern)
        color += skyReflect * 0.05; // Subtle reflection only
    }

    return color;
}

void main() {
    light.color = vec3(1.0) * intensity;
    // 1:30 PM sun position - high but slightly angled from southwest
    light.direction = normalize(vec3(-2.5, 8.0, 3.0));

    // Phase 1: Normal fullscreen video (0.0-0.5s)
    if (isIntroPhase(iTime)) {
        vec2 videoUV = vec2(v_text.x, 1.0 - v_text.y); // Flip Y to fix upside-down
        vec3 videoColor = texture(iChannel0, videoUV).rgb;
        fragColor = vec4(videoColor, 1.0);
        return;
    }

    // Phase 2: Video morphing from flat to ball (0.5-1.0s)
    if (isVideoMorphPhase(iTime)) {
        // Get morph factor (0.0 = flat video, 1.0 = video ball)
        float morphFactor = getVideoMorphFactor(iTime);

        // Set up 3D scene for morphing
        vec2 uv = (v_text * iResolution.xy) / iResolution.xy - vec2(0.5);
        uv.x *= iResolution.x / iResolution.y;

        // Camera positioned to follow the morphing video ball
        vec3 videoBallPos = getVideoBallPosition(iTime);
        float videoBallRadius = getVideoBallSize(iTime);

        // Camera distance adjusts with ball size to maintain good framing
        float cameraDistance = videoBallRadius * 2.5; // Keep ball well-framed
        vec3 camPos = videoBallPos + vec3(0.0, 0.0, cameraDistance);
        vec3 target = videoBallPos; // Always look at the morphing ball

        vec3 forward = normalize(target - camPos);
        vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
        vec3 up = cross(forward, right);
        vec3 rayDir = normalize(uv.x * right + uv.y * up + forward);

        Ray ray = Ray(camPos, rayDir);

        // Check intersection with morphing video ball (reuse existing variables)
        Sphere videoBall = Sphere(videoBallRadius, videoBallPos, Material(vec3(1.0), 1.0, 0.0, true));

        Intersect hit = intersect(ray, videoBall);

        if (hit.material.diffuse > 0.0 || hit.material.specular > 0.0) {
            // Hit the morphing video ball - blend UV coordinates
            vec3 hitPoint = ray.origin + hit.len * ray.direction;
            vec3 localPoint = hitPoint - videoBallPos;

            // Flat UV (like fullscreen video)
            vec2 flatUV = vec2(v_text.x, 1.0 - v_text.y);

            // Sphere UV (billboard style)
            vec3 toCamera = normalize(camPos - videoBallPos);
            vec3 sphereUp = vec3(0.0, 1.0, 0.0);
            vec3 sphereRight = normalize(cross(sphereUp, toCamera));
            sphereUp = cross(toCamera, sphereRight);

            float u = 0.5 + dot(localPoint, sphereRight) / (videoBallRadius * 2.0);
            float v = 0.5 - dot(localPoint, sphereUp) / (videoBallRadius * 2.0);
            vec2 sphereUV = vec2(clamp(u, 0.0, 1.0), clamp(v, 0.0, 1.0));

            // Morph between flat and sphere UV
            vec2 finalUV = mix(flatUV, sphereUV, morphFactor);

            vec3 videoColor = texture(iChannel0, finalUV).rgb;
            fragColor = vec4(videoColor, 1.0);
            return;
        } else {
            // No hit - black background during morph (no waveform yet)
            fragColor = vec4(0.0, 0.0, 0.0, 1.0);
            return;
        }
    }

    // Phase 3 & 4: 3D scene with enhanced dynamic camera system and audio-reactive sky
    // WAVEFORM INTEGRATION: Audio-reactive waveforms appear ONLY in these phases
    // - Waveforms appear only in far background (when rays miss all objects)
    // - Video balls continue using video texture (iChannel0) exclusively
    // - Waveforms use audio texture (iChannel1) for FFT reactivity
    vec2 uv = (v_text * iResolution.xy) / iResolution.xy - vec2(0.5);
    uv.x *= iResolution.x / iResolution.y;

    // ENHANCED: Use dynamic camera system with height and tilt adjustments
    vec3 camPos = getCameraPosition(iTime);
    vec3 target = getCameraTarget(iTime);

    // Calculate camera orientation with dynamic adjustments
    vec3 forward = normalize(target - camPos);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = cross(forward, right);
    vec3 rayDir = normalize(uv.x * right + uv.y * up + forward);

    Ray ray = Ray(camPos, rayDir);
    fragColor = vec4(pow(radiance(ray) * exposure, vec3(1.0 / gamma)), 1.0);
}
