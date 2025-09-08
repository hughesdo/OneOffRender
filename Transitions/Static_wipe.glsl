// Author: Ben Lucas
// License: MIT
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform bool u_transitionUpToDown; // = true
uniform float u_max_static_span; // = 0.5

out vec4 outColor;

#define PI 3.14159265359

float rnd(vec2 st) {
    return fract(sin(dot(st.xy, vec2(10.0, 70.0))) * 12345.5453123);
}

vec4 transition(vec2 uv) {
    float span = u_max_static_span * pow(sin(PI * progress), 0.5);
    float transitionEdge = u_transitionUpToDown ? 1.0 - uv.y : uv.y;
    float mixRatio = 1.0 - step(progress, transitionEdge);
    vec4 transitionMix = mix(
        texture(from, uv),
        texture(to, uv),
        mixRatio
    );
    float noiseEnvelope = smoothstep(progress - span, progress, transitionEdge) * (1.0 - smoothstep(progress, progress + span, transitionEdge));
    vec4 noise = vec4(vec3(rnd(uv * (1.0 + progress))), 1.0);
    return mix(transitionMix, noise, noiseEnvelope);
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}