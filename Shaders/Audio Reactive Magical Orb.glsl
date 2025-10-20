#version 330 core

/*
    Audio Reactive Magical Orb - OneOffRender Version
    Based on original by Chronos: https://www.shadertoy.com/view/33jSWh
    Modified: Audio affects ONLY colors and orb size, NOT internal animation
    Converted for OneOffRender with cubemap support
*/

// OneOffRender uniforms
uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;      // Audio texture
uniform samplerCube iChannel1;    // Cubemap texture (cobblestone_street_night)

out vec4 fragColor;

// ============ AUDIO REACTIVE TWEAKING VARIABLES ============
const float ORB_BASE_RADIUS = 2.0;        // Base radius of the orb sphere
const float ORB_PULSE_AMOUNT = 1.5;       // How much orb grows/shrinks on beats
const float GLOW_INTENSITY = 1e-3;        // Volumetric glow intensity
const float GLOW_AUDIO_MULT = 4.0;        // How much audio boosts glow
const float HUE_SHIFT_MULT = 10.0;        // Continuous hue shifting with audio
const float BASS_COLOR_JUMP = 20.0;       // Big color jumps on bass hits
const float BASS_FREQ = 0.1;              // Bass frequency sample point
const float MID_FREQ = 0.3;               // Mid frequency sample point
const float HIGH_FREQ = 0.7;              // High frequency sample point
// ===========================================================

// ============ ENVIRONMENT LIGHTING VARIABLES ============
const float CUBEMAP_DARKNESS = 0.1;       // 0.0 = black, 1.0 = full brightness (very dark base)
const float SPOTLIGHT_STRENGTH = 6.0;     // Main spotlight beam intensity
const float SPOTLIGHT_TIGHTNESS = 25.0;   // How focused the spotlight is (higher = tighter)
const float SPOTLIGHT_SHARPNESS = 5.0;    // Directional falloff sharpness
const float AMBIENT_GLOW_STRENGTH = 0.8;  // Subtle ambient colored glow affecting entire scene
const float RADIAL_FALLOFF_STRENGTH = 15.0; // Screen-space radial falloff
const float DIFFUSE_SHARPNESS = 4.0;      // Physically-based directional sharpness
const float ORB_ENV_AUDIO_BOOST = 5.0;    // Extra light intensity on audio peaks (bass-driven)
const float BASS_BRIGHTNESS_MULT = 3.0;   // Extra brightness boost on bass hits
// =======================================================

const float PI = 3.14159265;

vec3 cmap1(float x) { return pow(.5+.5*cos(PI * x + vec3(1,2,3)), vec3(2.5)); }

vec3 cmap2(float x)
{
    vec3 col = vec3(.35, 1,1)*(cos(3.141592*x*vec3(1)+.75*vec3(2,1,3))*.5+.5);
    col *= col * col;
    return col;
}

vec3 cmap3(float x)
{
    vec3 yellow = vec3(1.,.9,0);
    vec3 purple = vec3(.75,0,1);
    vec3 col = mix(purple, yellow, cos(x/1.25)*.5+.5);
    col*=col*col;
    return col;
}

vec3 cmap(float x, float hueShift, float bassJump)
{
    float t = mod(iTime, 30.);
    // Apply continuous hue shift and bass-driven color jumps
    float colorOffset = hueShift + bassJump;
    return
    (smoothstep(-1., 0., t)-smoothstep(9., 10., t)) * cmap1(x + colorOffset) + 
    (smoothstep(9., 10., t)-smoothstep(19., 20., t)) * cmap2(x + colorOffset) + 
    (smoothstep(19., 20., t)-smoothstep(29., 30., t)) * cmap3(x + colorOffset) +
    (smoothstep(29., 30., t)-smoothstep(39., 40., t)) * cmap1(x + colorOffset);
}

void main()
{
    // OneOffRender coordinate system (no Y-flip needed for this shader)
    vec2 fragCoord = gl_FragCoord.xy;

    // Sample audio frequencies from iChannel0 (audio texture) - OneOffRender convention
    float bass = texture(iChannel0, vec2(BASS_FREQ, 0.0)).x;
    float mid = texture(iChannel0, vec2(MID_FREQ, 0.0)).x;
    float high = texture(iChannel0, vec2(HIGH_FREQ, 0.0)).x;
    float audioLevel = (bass + mid + high) / 3.0;

    vec2 uv = (2. * fragCoord - iResolution.xy)/iResolution.y;

    float focal = 1.;
    vec3 ro = vec3(0, 0, 6.+cos(iTime*.25)*.75);

    float time = iTime * .5;
    float c = cos(time), s = sin(time);
    ro.xz *= mat2(c,s,-s,c);

    vec3 rd = normalize(vec3(uv, -focal));
    rd.xz *= mat2(c,s,-s,c);

    vec3 color = vec3(0);

    // Calculate audio-reactive orb colors (for environment lighting)
    float hueShift = mid * HUE_SHIFT_MULT + high * 5.0;
    float bassJump = bass * BASS_COLOR_JUMP;
    vec3 orbColor = cmap(iTime, hueShift, bassJump);

    // Background cubemap - darkened and lit by orb
    vec3 cubemapColor = pow(texture(iChannel1, rd).rgb, vec3(2.2));
    cubemapColor *= CUBEMAP_DARKNESS;  // Darken to create night atmosphere

    // Calculate orb lighting on environment - Hybrid spotlight + ambient glow
    vec3 orbPos = vec3(0, 0, 0);  // Orb at origin
    float orbRadius = ORB_BASE_RADIUS + bass * ORB_PULSE_AMOUNT;

    // === COMPONENT 1: SPOTLIGHT (Dominant - Tight Focused Beam) ===
    vec3 orbScreenDir = normalize(orbPos - ro);
    float angularDist = length(rd - orbScreenDir);

    // Very tight spotlight falloff
    float spotlightFalloff = 1.0 / (1.0 + angularDist * angularDist * SPOTLIGHT_TIGHTNESS);
    spotlightFalloff = pow(spotlightFalloff, 3.0);  // Sharp edges

    // Directional component (only surfaces facing orb)
    vec3 envSurfacePos = ro + rd * 50.0;
    vec3 toOrb = orbPos - envSurfacePos;
    vec3 lightDir = normalize(toOrb);
    float spotlightDirectional = pow(max(0.0, dot(lightDir, -rd)), SPOTLIGHT_SHARPNESS);

    // Combine spotlight components
    float spotlightMask = spotlightFalloff * spotlightDirectional;

    // === COMPONENT 2: RADIAL GLOW (Screen-space, softer) ===
    float radialFalloff = pow(1.0 / (1.0 + angularDist * angularDist * RADIAL_FALLOFF_STRENGTH), 2.0);
    float radialDirectional = pow(max(0.0, dot(lightDir, -rd)), DIFFUSE_SHARPNESS);
    float radialMask = radialFalloff * radialDirectional;

    // === COMPONENT 3: AMBIENT GLOW (Affects entire scene subtly) ===
    // Distance-based falloff for ambient
    float distToOrb = length(toOrb);
    float ambientFalloff = 1.0 / (1.0 + distToOrb * distToOrb * 0.005);  // Very soft falloff

    // === AUDIO REACTIVITY ===
    // Base intensity with audio boost
    float baseIntensity = 1.0 + audioLevel * ORB_ENV_AUDIO_BOOST;
    // Extra bass-driven brightness
    float bassBrightness = 1.0 + bass * BASS_BRIGHTNESS_MULT;

    // === COMBINE ALL COMPONENTS ===
    // Spotlight (dominant)
    vec3 spotlightLight = orbColor * spotlightMask * SPOTLIGHT_STRENGTH * baseIntensity * bassBrightness;

    // Radial glow (medium)
    vec3 radialLight = orbColor * radialMask * 2.0 * baseIntensity;

    // Ambient glow (subtle, affects everything)
    vec3 ambientLight = orbColor * ambientFalloff * AMBIENT_GLOW_STRENGTH * baseIntensity;

    // Add all lighting components to darkened cubemap
    cubemapColor += spotlightLight + radialLight + ambientLight;

    color += cubemapColor;

    time = iTime;
    {
        // Audio-reactive orb radius (already calculated above for lighting)
        float orbRadiusSq = orbRadius * orbRadius;
        
        float t  = dot(0. - ro, rd);
        vec3 p   = t * rd + ro;
        float y2 = dot(p, p);
        float x2 = orbRadiusSq - y2;
        
        if(y2 <= orbRadiusSq)
        {
            float a = t-sqrt(x2);
            float b = t+sqrt(x2);

            color *= exp(-(b-a));

            t = a + 0.01;

            // Audio affects ONLY glow intensity and colors
            float glowMult = GLOW_INTENSITY * (1.0 + audioLevel * GLOW_AUDIO_MULT);

            // Color modulation uses same hueShift and bassJump calculated earlier

            for(int i = 0; i < 99 && t < b; i++)
            {
                vec3 p = t * rd + ro;

                // ORIGINAL ANIMATION - NOT audio reactive
                float T = (t+time)/5.;
                float c = cos(T), s = sin(T);
                p.xy = mat2(c,-s,s,c) * p.xy;

                for(float f = 0.; f < 9.; f++)
                {
                    float a = exp(f)/exp2(f);
                    p += cos(p.yzx * a + time)/a;
                }
                
                // ORIGINAL DENSITY - NOT audio reactive
                float d = 1./100. + abs((ro -p-vec3(0,1,0)).y-1.)/10.;
                
                // ONLY colors and glow are audio reactive
                color += cmap(t, hueShift, bassJump) * glowMult / d;
                t += d*.25;
            }

            // Fresnel and reflections - darkened to match environment
            float R0 = 0.04;
            vec3 N = normalize(a * rd  + ro);
            float cosTheta = dot(-rd, N);
            float fresnel = R0 + (1.0 - R0) * pow(1.0 - cosTheta, 5.0);

            color *= 1.-fresnel;
            vec3 reflectionColor = pow(texture(iChannel1, reflect(rd, N)).rgb, vec3(2.2));
            reflectionColor *= CUBEMAP_DARKNESS;  // Match environment darkness
            color += fresnel * reflectionColor;
        }
    }

    color = 1.-exp(-color);
    color *= 1.-dot(uv*.55,uv*.55)*.15;
    color = pow(color, vec3(1./2.2));

    color = clamp(color, 0., 1.);
    fragColor = vec4(color, 1);
}