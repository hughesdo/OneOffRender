#version 330 core

// Original author: kalin
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/MslBDN
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture
uniform sampler2D iChannel1;  // Video texture (SpaceTravel)

out vec4 fragColor;

#define s(x) smoothstep(0.15, 0.3, x * 1.1 - 0.1)

vec3 chromaKey(vec3 x, vec3 y){
    vec2 c = s(vec2(x.g - x.r * x.y, x.g));

    return mix(x, y, c.x * c.y);
}
vec3 getTexture(vec2 p){
    vec4 texSample = texture(iChannel1, p);
    return texSample.xyz * texSample.w;
}

void main() {
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    float bass = pow(texture(iChannel0, vec2(0.0, 0.14)).x, 4.);
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 nuv = uv * 2.0 - 1.0;

    nuv.x /= iResolution.y / iResolution.x;
    nuv.x /= 0.9;
    nuv.y /= 0.9;

    float bpm = 1.0 / 60.0 * 84.3;
    float t = iTime;
    float pi = 3.1415926535;
    float drum = pow(abs(sin(t * bpm * pi)), 32.0);

    fragColor.x = drum*10.;
    fragColor.y = pow(abs(sin(t * bpm * pi * 4.0)), 32.0) * uv.y;

    // uv = 0..1
    // resx = 800~
    float pixel = uv.x * iResolution.x;
    float muvx = length(nuv);
    float mx = muvx / 512.0 * iResolution.x * (0.15 + 0.5 * pow(muvx, 4.0));
    float mu = texture(iChannel0, vec2(mx / iResolution.x, 0.25)).x;
    //float outer = step(0.0, muvx);
    float outer = step(0.0, muvx);
    float inner = step(0.15, 1.0 - muvx);

    vec3 col0 = vec3(0.0, 0.0, 2.8) * mu * 0.2;
    col0 += pow(mu, 11.0) * 0.2;
    col0 += pow(drum * mu * muvx, 1.2) * 0.2;

    //vec3 col1 = vec3(sin(iTime)/1.5 + 0.4 + 0.4 * mu, 0.3 + 0.2 * mu, 0.2 + 0.3 * mu) * pow(mu, 2.0) * 3.0;
    vec3 col1 = vec3(sin(iTime)/1.5 + 10.8 * mu, 0.3 + 0.2 * mu, 0.2 + 0.3 * mu) * pow(mu, 2.0) * 3.0;
    vec3 col2 = vec3(10.0*bass, bass*2.5, bass*5.);


    vec3 col_greenscreen = getTexture(uv);
    col0 = chromaKey(col_greenscreen, col0);
    col1 = chromaKey(col_greenscreen, col1);
    col2 = chromaKey(col_greenscreen, col2);


    fragColor.xyz = col2 * max(0.0, (1.0 - inner));
    fragColor *= pow(max(fragColor - .2, 0.0), vec4(1.4)) * .5;

    //fragColor.xyz += abs(sin(nuv.y * 10.0 * bpm * (1.0 - inner) + t * 5.0)) * (1.0 - inner) * 0.1;
    fragColor.xyz += abs(sin(nuv.y * 10.0 * bpm * (1.0 - inner) + t * 5.0*mu)) * (1.0 - inner) * 0.1;
    fragColor.xyz += fract(sin(nuv.y * 30.0 * bpm * (1.0 - inner) + t * 2.0)) * (1.0 - inner) * 0.2 * mx * 0.5;


    fragColor.xyz += col1 * inner * outer * 0.1;
    fragColor.xyz += col0 * inner * outer;
    fragColor.xyz += col1 * inner * outer * sin(t * bpm + nuv.y * 15.0 * mu);

    fragColor *= pow(max(fragColor - .2, 0.0), vec4(bass*outer)) * 1.5;
    vec3 resultColorWithBorder = mix(vec3(0.),vec3(fragColor.x, fragColor.y, fragColor.z),pow(max(0.,1.5-length(uv*uv*uv*vec2(2.0,2.0))),.3));
    fragColor = vec4(resultColorWithBorder, 1.0);
}
