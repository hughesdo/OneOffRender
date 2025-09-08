#version 330 core

/*
    Volumetric Glow 2 - Enhanced Volumetric Raymarching
    Converted for OneOffRender system

    "Volumetric: Glow" by @XorDev

    A lighting demo built for my tutorial on volumetric raymarching
    Enhanced with subtle audio reactivity
*/

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

// === TWEAKING VARIABLES ===
//Audio reactivity intensity for brightness pulsing
#define AUDIO_INTENSITY 3.9

//Output brightness
#define BRIGHTNESS 0.005
//Raymarching steps
#define STEPS 50.0
//Camera y Field Of View ratio
#define FOV 0.30
//Fog density
#define DENSITY 2.00
//Wave frequency in density field
#define WAVE_FREQ 11.0
//Minimum radius for density computation
#define MIN_RAD 23.0
//Threshold for cosine grid
#define COS_THRESHOLD 0.6
//Rotation speed for axis
#define ROT_SPEED 0.1
//Phase offsets for axis rotation (X, Y, Z)
#define AXIS_PHASE_X 0.0
#define AXIS_PHASE_Y 2.0
#define AXIS_PHASE_Z 4.0
//Camera distance
#define CAM_DIST 18.0
//Denominator base for color computation
#define COLOR_DENOM_BASE 2.0
//Color phase offsets (R, G, B)
#define COLOR_PHASE_R 86.0
#define COLOR_PHASE_G 1.0
#define COLOR_PHASE_B 2.0
//Color offset added to cosine
#define COLOR_OFFSET 1.5
//Time speed multiplier for waves
#define WAVE_TIME_SPEED 1.1
//Time speed multiplier for colors
#define COLOR_TIME_SPEED 1.0
//Coordinate centering scale
#define CENTER_SCALE 2.0
//Initial color value (R, G, B)
#define INIT_COLOR_R 1.0
#define INIT_COLOR_G 1.0
#define INIT_COLOR_B 62.0
//Loop start value
#define LOOP_START 0.0
//Camera position offsets (X, Y, Z)
#define CAM_POS_X 0.0
#define CAM_POS_Y 0.0
#define CAM_POS_Z -CAM_DIST

vec3 contrast(vec3 color, float contrast) {
    return 0.5 + contrast * (color - 0.5);
}

//Density field
float volume(vec3 p)
{
    //Spherical distance
    float l = length(p);
    //Projected sine waves
    vec3 v = cos(abs(p) * WAVE_FREQ / max(MIN_RAD,l) + iTime * WAVE_TIME_SPEED);
    //Combine cosine grid with sphere
    return length(vec4(max(v, v.yzx) - COS_THRESHOLD, l-MIN_RAD)) / DENSITY;
}

//3D rotation function
//Rotates 90 degrees from an arbitrary axis
//https://x.com/XorDev/status/1947676805546361160
vec3 rotate(vec3 p, vec3 a)
{
    return a*dot(p,a) + cross(p,a);
}

void main()
{
    // Screen coordinates to UV with Y-flip for correct orientation
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);

    //Center coordinates
    vec2 center = CENTER_SCALE*fragCoord - iResolution.xy;
   
    //Rotation axis
    vec3 axis = normalize(cos(vec3(ROT_SPEED*iTime + vec3(AXIS_PHASE_X,AXIS_PHASE_Y,AXIS_PHASE_Z))));
    //Rotate ray direction
    vec3 dir = rotate(normalize(vec3(center, FOV * iResolution.y)),axis);
   
    //Camera position
    vec3 cam = rotate(vec3(CAM_POS_X, CAM_POS_Y, CAM_POS_Z), axis);
    //Raymarch sample point
    vec3 pos = cam;
   
    //Output color
    vec3 col = vec3(INIT_COLOR_R, INIT_COLOR_G, INIT_COLOR_B);
   
    //Glow raymarch loop
    for(float i = LOOP_START; i<STEPS; i++)
    {
        //Glow density
        float vol = volume(pos);
        //Step forward
        pos += dir * vol;
       
        //Add sine wave coloring
        col += (cos(pos.z/(COLOR_DENOM_BASE+vol)+iTime*COLOR_TIME_SPEED+vec3(COLOR_PHASE_R,COLOR_PHASE_G,COLOR_PHASE_B))+COLOR_OFFSET) / vol;
    }
    
    //Audio reactive brightness - subtle pulsing glow
    float audioBass = texture(iChannel0, vec2(0.1, 0.0)).x;
    float audioMid = texture(iChannel0, vec2(0.5, 0.0)).x;
    float audioReactive = 1.0 + (audioBass + audioMid * 0.5) * AUDIO_INTENSITY;
    
    //Tanh tonemapping with audio reactive brightness
    //https://mini.gmshaders.com/p/tonemaps
    col = tanh(BRIGHTNESS * audioReactive * col);
   
    //Output the resulting color
    fragColor = vec4(fwidth(col*15.00), 1.0);
}