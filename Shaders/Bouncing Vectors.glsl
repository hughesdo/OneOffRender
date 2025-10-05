// Vectors by Xor
// https://x.com/XorDev/status/1972423422711111894
// Made reactive by PAEz

// FFT bands
#define LOW_START   0
#define LOW_END     20
#define LOW_COUNT (LOW_END-LOW_START)
#define MID_START   150
#define MID_END     350
#define MID_COUNT (MID_END-MID_START)
#define HIGH_START  490
#define HIGH_END    502
#define HIGH_COUNT (HIGH_END-HIGH_START)

// Main loop parameters
#define MAX_ITERATIONS 70.0
#define COLOR_MULTIPLIER 9.0
#define FINAL_DIVISOR 60000.0

// Ray and space parameters
#define RAY_SCALE 2.0
#define DEPTH_OFFSET_MIN 10.0  // bass = 0
#define DEPTH_OFFSET_MAX 5.0  // bass = 1
#define STEP_SIZE 0.10

// Time-based animation
#define TIME_DIVISOR 4.0
#define PHASE_OFFSET_Y 2.0
#define PHASE_OFFSET_Z 4.0

// Inner loop parameters
#define INNER_LOOP_START 2.0
#define INNER_LOOP_END 9.0

// Mathematical operations
#define SIN_POWER 1.0
#define CROSS_PRODUCT_WEIGHT 1.0
#define DOT_PRODUCT_WEIGHT 1.0

// Frequency control for particles
#define FREQUENCY_SCALAR_MIN 1.0   // treble = 0
#define FREQUENCY_SCALAR_MAX 1.50  // treble = 1

// Grid-specific spacing control
#define GRID_SPACING_SCALAR_MIN 1.0  // treble = 0
#define GRID_SPACING_SCALAR_MAX 2.0  // treble = 1

#define GLOW_MIN 1.0  // treble = 0
#define GLOW_MAX 0.8  // treble = 1

#define GRID_DENSITY_MIN 1.0  // treble = 0
#define GRID_DENSITY_MAX 3.0  // treble = 1

#define DEPTH_MIN 4.0  // treble = 0
#define DEPTH_MAX 0.0  // treble = 1

#define BRIGHT_MIN 1.0  // treble = 0
#define BRIGHT_MAX 0.8  // treble = 1

// Color channel weights
#define RED_WEIGHT 1.0
#define GREEN_WEIGHT 1.0
#define BLUE_WEIGHT 1.0
#define ALPHA_WEIGHT 1.0

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Band averages via three tight loops (skip unused bins)
    float low = 0.0;
    for (int i = LOW_START; i < LOW_END; ++i) {
        low += texelFetch(iChannel0, ivec2(i, 0), 0).r;
    }
    float mid = 0.0;
    for (int i = MID_START; i < MID_END; ++i) {
        mid += texelFetch(iChannel0, ivec2(i, 0), 0).r;
    }
    float high = 0.0;
    for (int i = HIGH_START; i < HIGH_END; ++i) {
        high += texelFetch(iChannel0, ivec2(i, 0), 0).r;
    }

    // Avoid dividing by zero
    low  = (LOW_COUNT  > 0) ? (low  / float(LOW_COUNT))*1.6  : 0.0;
    mid  = (MID_COUNT  > 0) ? (mid  / float(MID_COUNT))  : 0.0;
    high = (HIGH_COUNT > 0) ? (high / float(HIGH_COUNT))*1.7 : 0.0;


    // Interpolate parameters based on audio
    float DEPTH_OFFSET = mix(DEPTH_OFFSET_MIN, DEPTH_OFFSET_MAX, low);
    float FREQUENCY_SCALAR = mix(FREQUENCY_SCALAR_MIN, FREQUENCY_SCALAR_MAX, high);
    float GRID_SPACING_SCALAR = mix(GRID_SPACING_SCALAR_MIN, GRID_SPACING_SCALAR_MAX, high);
    float GLOW = mix(GLOW_MIN, GLOW_MAX, high);
    float GRID_DENSITY = mix(GRID_DENSITY_MIN, GRID_DENSITY_MAX, high);
    float DEPTH = mix(DEPTH_MIN, DEPTH_MAX, high);
    float BRIGHT = mix(BRIGHT_MIN, BRIGHT_MAX, high);

    vec2 resolution = iResolution.xy;
    vec3 pixelCoord = vec3(fragCoord, 0.0);
    float time = iTime;
    vec4 outputColor = vec4(0.0);
    
    float depth = DEPTH;
    float stepDistance = 0.0;
    
    for(float iteration = 0.0; iteration < MAX_ITERATIONS; iteration++) {
        vec3 position = depth * normalize(pixelCoord.rgb * RAY_SCALE - resolution.xyy);
        vec3 animationVector = normalize(sin(time / TIME_DIVISOR + vec3(0.0, PHASE_OFFSET_Y, PHASE_OFFSET_Z)));
        vec3 tempVector;
        
        position.z += DEPTH_OFFSET;
        tempVector = animationVector = DOT_PRODUCT_WEIGHT * dot(animationVector, position) * animationVector + CROSS_PRODUCT_WEIGHT * cross(animationVector, position);
        
        for(stepDistance = INNER_LOOP_START; stepDistance < INNER_LOOP_END; stepDistance++) {
            animationVector += sin(ceil(animationVector * stepDistance * GRID_SPACING_SCALAR)*GLOW - time).yzx / stepDistance;
        }
        
        depth += stepDistance = STEP_SIZE * length(sin(animationVector * animationVector * FREQUENCY_SCALAR))*GLOW * sqrt(length(tempVector * sin(tempVector.yzx*GRID_DENSITY)));
        outputColor += vec4(COLOR_MULTIPLIER * RED_WEIGHT, iteration * GREEN_WEIGHT, depth * BLUE_WEIGHT, ALPHA_WEIGHT) / stepDistance*BRIGHT;
    }
    
    outputColor = tanh(outputColor / FINAL_DIVISOR);
    fragColor = outputColor;
}
