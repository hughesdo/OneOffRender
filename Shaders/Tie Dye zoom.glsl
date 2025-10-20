#version 330 core

// Tie Dye Zoom - Psychedelic kaleidoscopic pattern with zoom animation
// Non-audio-reactive, time-based animation

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

#define TILE_SCALE 0.85
#define SPEED -0.01
#define LAYERS 9.0
#define WAVE_FREQ -19.0
#define GLOW_POWER 2.0
#define GLOW_INTENSITY 0.015
#define PA vec3(0.5,0.5,0.5)
#define PB vec3(0.5,0.5,0.5)
#define PC vec3(1.0,1.0,1.0)
#define PD vec3(0.263,0.416,0.557)
#define PI 3.14159
#define TAU 6.28318

// --- ZOOM CONTROLS ---
#define ZOOM_SPEED 0.3   // How fast to zoom in and out
#define ZOOM_AMOUNT 1.0  // How much to zoom in and out

vec3 palette(float t){ return PA + PB * cos(TAU * (PC * t + PD)); }

// Rotation matrix helper
mat2 rotate2d(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

// Tile function with rotation
vec2 tile(vec2 uv, float angle){
    uv = rotate2d(angle) * uv;
    float a=atan(uv.y,uv.x),r=length(uv),segments=3.0;
    a=mod(a,TAU/segments);
    a=abs(a-PI/segments);
    return vec2(cos(a),sin(a))*r*TILE_SCALE;
}

// Shape function with rotation
float shape(vec2 p, float angle){
    p = rotate2d(angle) * p;
    float a=atan(p.y,p.x),r=length(p),petal=cos(a*6.0)*0.05+0.06;
    return r-petal;
}

void main() {
    // Screen coordinates with Y-flip for correct orientation
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);

    vec2 uv = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    vec2 uv0 = uv;
    vec3 c = vec3(0.0);

    float zoom = 1.0 + sin(iTime * ZOOM_SPEED) * ZOOM_AMOUNT;

    uv *= zoom;

    // Control rotation speeds
    float tileAngle = iTime * 0.05;
    float shapeAngle = 1440.0;

    for(float i=1.0;i<LAYERS;i+=1.0){
        uv = tile(uv, tileAngle+i/LAYERS);
        float d = shape(uv, shapeAngle*i/LAYERS) * exp(-length(uv0));
        vec3 col = palette(length(uv0)+i*0.1+iTime*SPEED);
        d = sin(d*WAVE_FREQ+iTime)/8.0;
        d = abs(d);
        d = pow(GLOW_INTENSITY/d,GLOW_POWER);
        c += col*d*i*0.17;
    }
    fragColor = vec4(c,1.0);
}


