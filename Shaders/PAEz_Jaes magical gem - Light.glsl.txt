// https://www.shadertoy.com/view/wcVfRK
// @Jaenam97, PAEz, Gemini 3 Pro

float getTunnel(vec2 uv, float time, float Z) {
    // 1. DISTORTION
    float len = length(uv);
    float ang = atan(uv.y, uv.x);
    
    // Twist
    float twist = 0.2 * sin(time * 0.102); 
    ang += twist / (len + 0.1); 
    
    // Pulse/Wave
    float wave = 0.23 * sin(len * 18.0 - time * 0.7);
    
    // Reconstruct UVs
    vec2 warpedUV = vec2(cos(ang), sin(ang)) * (len + wave);

    // 2. Square Tunnel Logic
    float s_bg = sin(time * 0.0001); float c_bg = cos(time * 0.0001);
    warpedUV *= mat2(c_bg, -s_bg, s_bg, c_bg);
    
    // Chebyshev distance
    float rad = max(abs(warpedUV.x), abs(warpedUV.y));
    float tunnelZ = 0.6 / (rad + 0.281); 
    
    // 3. Pattern
    float wallAngle = atan(warpedUV.y, warpedUV.x) / 6.28;
    vec2 tunnelGrid = vec2(wallAngle * 8.0, tunnelZ - time * 0.001);
    
    vec2 tGridId = floor(tunnelGrid);
    float checker = mod(tGridId.x + tGridId.y, 2.0);
    
    // Fog
    float tunnelFog = smoothstep(0.0, 4.0, tunnelZ);
    
    // Pulse
    float bgPulse = 0.5 + 0.5 * sin(tunnelZ * 0.4 + time + Z * 2.0 + wave * 10.0); 
    
    return checker * bgPulse * tunnelFog;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // --- SETUP ---
    // Extract Bass info
    float bass = texelFetch(iChannel0, ivec2(5, 0), 0).x;
     float mid = texelFetch(iChannel0, ivec2(127, 0), 0).x;
     float high = texelFetch(iChannel0, ivec2(500, 0), 0).x;
     high=mix(high,mid,0.5);
    
    vec2 uv_orig = fragCoord / iResolution.xy;
    vec2 texsize = iResolution.xy;
    float time = iTime;
    
    vec2 r = texsize;
    vec2 FC = uv_orig * r;
    vec4 o = vec4(0.0);
    
    vec2 bgBaseUV = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    for(int channel = 0; channel < 3; channel++)
    {
        float Z = float(channel - 1); 
        float channelValue = 0.0;
        float skipFlag = 0.0;
        float d = 0.0;
        float density = 0.0;
        
        for(float i = 0.0; i < 80.0; i += 1.0)
        {
            float continueFlag = 1.0 - step(0.5, skipFlag);
            vec3 p = vec3((FC * 2.0 - r) / r.y * d, d - 8.0);

            float skipCondition = step(5.0, abs(p.x));
            skipFlag = max(skipFlag, skipCondition * continueFlag);
            float processFlag = 1.0 - step(0.5, skipFlag);

            if(processFlag > 0.5)
            {
                vec3 pRaw = p; 
                
                // Rotations
                float s_rot = sin(time/5.0); float c_rot = cos(time/5.0);
                mat2 rot1 = mat2(c_rot, -s_rot, s_rot, c_rot);
                p.xz = rot1 * p.xz;
                
                s_rot = sin(time/5.0); c_rot = cos(time/5.0);
                mat2 rot2 = mat2(c_rot, -s_rot, s_rot, c_rot);
                p.xy = rot2 * p.xy;

                // Dots Logic
                vec3 g = floor(p * 6.0);
                vec3 f = fract(p * 6.0) - 0.5;
                float rand1 = fract(sin(dot(g, vec3(127.0, 312.0, 75.0))) * 43758.0);
                float h = step(length(f), rand1 * 0.3 + 0.1);
                float rand2 = fract(sin(dot(g, vec3(44.0, 78.0, 123.0))) * 127.0);
                float a = 500.0+rand2 * high*30.0*mid;

                // --- INNER BOX REPETITION LOGIC ---
                float e = 0.0; float sc = 2.0+bass*2.1;

                if(i<60.0) sc=4.5+(bass+mid+high)/13.0;
                // ----------------------------------

                float absX=abs(p.x), absY=abs(p.y), absZ=abs(p.z);
                
                // Main Object Size
                float size = -8.5 + sc * 2.9;
                
                float c = max(max(max(absX, absY), absZ), dot(vec3(absX, absY, absZ), vec3(0.577)) * 0.9) - size; 
                
                // --- BAND LOGIC ---
                float sphereDist = length(pRaw) - size * 0.8;
                float bandMetric = sphereDist; 
                
                if(c > 0.12) {
                    float bandFreq = 3.0; 
                    float warpFactor = 0.3 * sin(pRaw.z * 2.0 + iTime * 0.6) * sin(pRaw.y * 2.0 - iTime);
                    float warpedDist = bandMetric + warpFactor * 1.3; 
                    float ripples = sin(warpedDist * bandFreq);
                    float sharpBand = smoothstep(0.00, 0.99, ripples*0.5);
                    float fade = 1.0 / (c * 50.0);
                    float startFade = smoothstep(0.01, 0.5, c); 
                    
                    float centerDist = length(pRaw.xy);
                    float centerHole = smoothstep(size * 0.8, size * 0.8 + 2.0, centerDist);
                    
                    channelValue += (0.0001 + sharpBand * fade * 1000.0) * 14.1 * startFade * centerHole;
                }

                float sinC = length(sin(vec3(c))); 
                float s_dist = 0.01 + 0.25 * abs(max(max(c, e - 0.1), abs(sinC) - 0.3) + Z * 0.02 - i / 130.0);
                d += s_dist;

                float sf = smoothstep(0.02, 0.01, s_dist);
                channelValue += 1.6 / s_dist * (0.5 + 0.5 * sin(i * 0.2 + Z * 5.0) + sf * 4.0 * h * sin(a + i * 0.4 + Z * 5.0));
                
                density += sf * 0.10;
            }
            else { d += 1.0 * skipCondition; }
        }
        
        // --- COMPOSITE BACKGROUND ---
        float warpAmount = density * (0.15 + Z * 0.15);
        vec2 refractedUV = bgBaseUV * (1.0 - warpAmount);
        float bgFinal = getTunnel(refractedUV, time, Z*1.5);
        
        // --- VISIBILITY MASK ---
        // We use density to check if we are "inside" the object.
        // density is > 0.0 inside, 0.0 outside.
        // smoothstep makes the transition clean.
        float objectMask = smoothstep(0.3, 1.0, density*7.5);
        
        // Apply the mask to the intensity
        float bgIntensity = 1000.0 * 1.5 * objectMask; 

        channelValue += bgFinal * bgIntensity;

        if(channel == 0) o.r = channelValue*1.5;
        else if(channel == 1) o.g = channelValue*1.5;
        else o.b = channelValue*1.5;
    }

    o = o * o / 1.0e7;
    o = min(o, 10.0); 
    vec4 exp2o = exp(4.0 * o);
    o = (exp2o - 1.0) / (exp2o + 1.0);
    
    fragColor = o;
}