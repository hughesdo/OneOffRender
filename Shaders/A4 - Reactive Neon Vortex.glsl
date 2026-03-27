#version 330 core

// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// Audio Reactive Neon Vortex Tunnel - ShaderToy
// Set iChannel0 to audio input

#define PI 3.14159265359

// Audio helpers
float getAudio(float f) { return texture(iChannel0, vec2(f, 0.0)).x; }
float bass() { return (getAudio(0.02) + getAudio(0.05) + getAudio(0.08)) * 0.6; }
float mid() { return (getAudio(0.15) + getAudio(0.25) + getAudio(0.35)) * 0.5; }
float high() { return (getAudio(0.5) + getAudio(0.65) + getAudio(0.8)) * 0.4; }

// Color palette: Magenta -> Blue -> Cyan -> Green -> Yellow
vec3 neonColor(float t) {
    t = fract(t);
    vec3 magenta = vec3(1.0, 0.0, 0.7);
    vec3 blue = vec3(0.2, 0.3, 1.0);
    vec3 cyan = vec3(0.0, 1.0, 1.0);
    vec3 green = vec3(0.2, 1.0, 0.3);
    vec3 yellow = vec3(1.0, 1.0, 0.0);
    
    if(t < 0.2) return mix(magenta, blue, t * 5.0);
    if(t < 0.4) return mix(blue, cyan, (t - 0.2) * 5.0);
    if(t < 0.6) return mix(cyan, green, (t - 0.4) * 5.0);
    if(t < 0.8) return mix(green, yellow, (t - 0.6) * 5.0);
    return mix(yellow, magenta, (t - 0.8) * 5.0);
}

// Tapered segment shape (thick middle, thin ends)
float segmentShape(float t) {
    return smoothstep(0.0, 0.3, t) * smoothstep(1.0, 0.7, t);
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Audio values
    float b = bass();
    float m = mid();
    float h = high();
    float total = (b + m + h) / 2.0;
    
    // Polar coordinates
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    
    // Time with audio modulation
    float time = iTime * 1.2 + b * 0.5;
    
    vec3 col = vec3(0.0);
    
    // Dark ribbed tunnel walls (background)
    float ribAngle = angle * 12.0 + time * 0.5;
    float ribs = sin(ribAngle) * 0.5 + 0.5;
    ribs *= smoothstep(0.1, 0.5, radius);
    col += vec3(0.02, 0.01, 0.025) * ribs;
    
    // Number of spiral arms
    float numArms = 4.0;
    
    // Multiple layers of segments at different depths
    for(float layer = 0.0; layer < 8.0; layer++) {
        // Depth factor (0 = center/far, 1 = edge/near)
        float depth = layer / 8.0;
        float depthRadius = 0.05 + depth * 0.7;
        
        // Layer timing offset for outward motion
        float layerTime = time - layer * 0.15;
        
        // Spiral parameters
        float spiralTightness = 3.0 + m * 1.0;
        float rotation = layerTime * 1.5; // Clockwise
        
        for(float arm = 0.0; arm < numArms; arm++) {
            // Arm angle offset
            float armOffset = arm * PI * 2.0 / numArms;
            
            // Spiral angle calculation
            float spiralAngle = log(radius + 0.001) * spiralTightness + rotation + armOffset;
            
            // Segmentation - create dashes along the spiral
            float segmentPhase = spiralAngle * 2.0 + layer * 0.8;
            float segmentID = floor(segmentPhase);
            float segmentT = fract(segmentPhase);
            
            // Gap between segments
            float gapSize = 0.25 + h * 0.1;
            float isSegment = step(gapSize, segmentT);
            float segmentLocal = (segmentT - gapSize) / (1.0 - gapSize);
            
            // Distance to spiral arm
            float targetAngle = fract((spiralAngle) / (2.0 * PI)) * 2.0 * PI - PI;
            float angleDiff = abs(mod(angle - targetAngle + PI, 2.0 * PI) - PI);
            
            // Width varies with radius (thicker at edges = nearer)
            float baseWidth = 0.02 + radius * 0.08;
            float width = baseWidth * segmentShape(segmentLocal) * (1.0 + b * 0.3);
            
            // Distance to line
            float d = angleDiff * radius;
            
            // Depth mask - segments appear at certain radius ranges
            float depthMask = smoothstep(depthRadius - 0.15, depthRadius, radius);
            depthMask *= smoothstep(depthRadius + 0.25, depthRadius + 0.1, radius);
            
            // Apply segment mask
            float lineMask = smoothstep(width, width * 0.3, d) * isSegment * depthMask;
            
            // Color based on angle position (rainbow around circle)
            float colorT = (angle + PI) / (2.0 * PI) + arm / numArms + time * 0.1;
            vec3 lineColor = neonColor(colorT);
            
            // Hard bright core
            float core = smoothstep(width * 0.4, 0.0, d) * isSegment * depthMask;
            
            // Soft bloom/glow
            float bloom = (1.0 / (d * 15.0 + 0.5)) * isSegment * depthMask * 0.15;
            bloom *= (1.0 + total * 2.0);
            
            // Combine core + bloom
            col += lineColor * bloom;
            col += (lineColor * 0.5 + 0.5) * core * 1.5; // Bright white-ish core
        }
    }
    
    // Central void (dark center)
    float voidMask = smoothstep(0.12, 0.02, radius);
    col *= 1.0 - voidMask * 0.95;
    
    // Audio reactive overall brightness pulse
    col *= 1.0 + total * 0.4;
    
    // Tone mapping
    col = 1.0 - exp(-col * 1.5);
    
    // Boost saturation
    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(luma), col, 1.3);
    
    // Subtle vignette
    col *= 1.0 - radius * 0.2;
    
    fragColor = vec4(col, 1.0);
}
