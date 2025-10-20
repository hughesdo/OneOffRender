/*
    Original by Chronos: https://www.shadertoy.com/view/33jSWh

    -------------------------------------------------------------
    |              Magical Orb by chronos                       |
    -------------------------------------------------------------


    Using my previous shader as a basis for this version where the
    glowing volumetrics are constrained to a sphere.


    See also:
    previous shader: "The Weave" https://www.shadertoy.com/view/W3SSRm

    Similar aesthetics: Heimdal Rir Over Bivrost
    https://www.shadertoy.com/view/lXKBzV

    "Ghosts" by xor https://www.shadertoy.com/view/tXlXDX

    -------------------------------------------------------------
    self link:       https://www.shadertoy.com/view/33jSWh
    -------------------------------------------------------------

    Converted for OneOffRender by Don Hughes
*/

#version 330 core

// OneOffRender uniforms
uniform float iTime;
uniform vec2 iResolution;
uniform samplerCube iChannel1;  // Cubemap texture (Krakow Cloth Hall)

out vec4 fragColor;

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

vec3 cmap(float x)
{
    float t = mod(iTime, 30.);
    return
    (smoothstep(-1., 0., t)-smoothstep(9., 10., t)) * cmap1(x) + 
    (smoothstep(9., 10., t)-smoothstep(19., 20., t)) * cmap2(x) + 
    (smoothstep(19., 20., t)-smoothstep(29., 30., t)) * cmap3(x) +
    (smoothstep(29., 30., t)-smoothstep(39., 40., t)) * cmap1(x) 
    ;


}

void main()
{
    // Use gl_FragCoord directly (no Y-flip needed)
    vec2 fragCoord = gl_FragCoord.xy;

    vec2 uv = (2. * fragCoord - iResolution.xy)/iResolution.y;

    float focal = 1.;  // Reduced from 2.0 to 1.0 for wider FOV (2x zoom out)
    vec3 ro = vec3(0, 0, 6.+cos(iTime*.25)*.75);


    float time = iTime * .5;

    float c = cos(time), s = sin(time);
    ro.xz *= mat2(c,s,-s,c);

    vec3 rd = normalize(vec3(uv, -focal));
    rd.xz *= mat2(c,s,-s,c);

    vec3 color = vec3(0);

    // Sample cubemap for background (changed from iChannel3 to iChannel1)
    color += pow(texture(iChannel1, rd).rgb, vec3(2.2));

    time = iTime;
    {
        float t  = dot(0. - ro, rd);
        vec3 p   = t * rd + ro;
        float y2 = dot(p, p);
        float x2 = 4. - y2;
        if(y2 <= 4.)
        {
            float a = t-sqrt(x2);
            float b = t+sqrt(x2);

            color *= exp(-(b-a));

            // Removed noise texture reference (iChannel0) - use simple offset instead
            t = a + 0.01;

            for(int i = 0; i < 99 && t < b; i++)
            {
                vec3 p = t * rd + ro;

                float T = (t+time)/5.;
                float c = cos(T), s = sin(T);
                p.xy = mat2(c,-s,s,c) * p.xy;

                for(float f = 0.; f < 9.; f++)
                {
                    float a = exp(f)/exp2(f);
                    p += cos(p.yzx * a + time)/a;
                }
                float d = 1./100. + abs((ro -p-vec3(0,1,0)).y-1.)/10.;
                color += cmap(t) * 1e-3 / d ;
                t += d*.25;
            }

            float R0 = 0.04;
            vec3 N = normalize(a * rd  + ro);
            float cosTheta = dot(-rd, N);
            float fresnel = R0 + (1.0 - R0) * pow(1.0 - cosTheta, 5.0);

            color *= 1.-fresnel;
            // Sample cubemap for reflection (changed from iChannel3 to iChannel1)
            color += fresnel * pow(texture(iChannel1, reflect(rd, N)).rgb, vec3(2.2));
        }

    }


    color = 1.-exp(-color);
    color *= 1.-dot(uv*.55,uv*.55)*.15;
    color = pow(color, vec3(1./2.2));

    // Removed noise texture dithering (iChannel0) - output clean color
    color = clamp(color, 0., 1.);
    fragColor = vec4(color, 1);
}