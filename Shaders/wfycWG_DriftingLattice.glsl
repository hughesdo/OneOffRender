#version 330 core

// Drifting Lattice - Overlapping grids fading in and out
// Created by OneHung
// Audio reactive lattice visibility and glow
// https://www.shadertoy.com/view/wfycWG

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

#define PI 3.14159265359

vec3 erot(vec3 p, vec3 ax, float ro) {
    return mix(dot(ax, p) * ax, p, cos(ro)) + sin(ro) * cross(ax, p);
}

float sdRoundBox(vec3 p, vec3 b, float r) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.) - r;
}

vec3 domRep(vec3 p, float s) {
    return mod(p + s * 0.5, s) - s * 0.5;
}

float lattice1, lattice2, lattice3;
float glow;

float scene(vec3 p, float bass, float mid, float treble) {
    float t = iTime;
    
    // System 1 - bass reactive visibility
    vec3 p1 = erot(p, normalize(vec3(1, 0, 0)), t * 0.1);
    vec3 rep1 = domRep(p1, 2.0);
    lattice1 = sdRoundBox(rep1, vec3(0.15 + bass * 0.05), 0.05);
    
    // System 2 - mid reactive
    vec3 p2 = erot(p, normalize(vec3(1, 1, 0)), 0.6);
    p2 = erot(p2, normalize(vec3(0, 1, 0)), t * 0.08);
    vec3 rep2 = domRep(p2, 2.5);
    lattice2 = sdRoundBox(rep2, vec3(0.12 + mid * 0.04), 0.04);
    
    // System 3 - treble reactive
    vec3 p3 = erot(p, normalize(vec3(1, 0, 1)), 1.1);
    p3 = erot(p3, normalize(vec3(0, 0, 1)), t * 0.05);
    vec3 rep3 = domRep(p3, 3.0);
    lattice3 = sdRoundBox(rep3, vec3(0.1 + treble * 0.03), 0.03);
    
    // Audio-enhanced visibility
    float vis1 = 0.5 + 0.5 * sin(t * 0.4) + bass * 0.3;
    float vis2 = 0.5 + 0.5 * sin(t * 0.3 + 2.1) + mid * 0.25;
    float vis3 = 0.5 + 0.5 * sin(t * 0.25 + 4.2) + treble * 0.3;
    
    lattice1 += (1.0 - vis1) * 2.0;
    lattice2 += (1.0 - vis2) * 2.0;
    lattice3 += (1.0 - vis3) * 2.0;
    
    glow = 0.;
    glow += 0.01 / (0.01 + lattice1 * lattice1) * vis1;
    glow += 0.008 / (0.01 + lattice2 * lattice2) * vis2;
    glow += 0.006 / (0.01 + lattice3 * lattice3) * vis3;
    
    return min(min(lattice1, lattice2), lattice3);
}

void main() {
    vec2 F = gl_FragCoord.xy;
    vec2 R = iResolution.xy;
    vec2 uv = (F - 0.5 * R) / R.y;
    
    // Audio
    float bass = texture(iChannel0, vec2(0.05, 0.25)).x;
    float mid = texture(iChannel0, vec2(0.3, 0.25)).x;
    float treble = texture(iChannel0, vec2(0.7, 0.25)).x;
    bass = smoothstep(0.0, 0.6, bass);
    mid = smoothstep(0.0, 0.5, mid);
    treble = smoothstep(0.1, 0.4, treble);
    
    float t = iTime;
    
    vec3 ro = vec3(sin(t * 0.1) * 2., cos(t * 0.07) * 1.5, t * 0.5);
    vec3 lookAt = ro + vec3(0, 0, 3);
    vec3 fwd = normalize(lookAt - ro);
    vec3 right = normalize(cross(vec3(0, 1, 0), fwd));
    vec3 up = cross(fwd, right);
    vec3 rd = normalize(uv.x * right + uv.y * up + 1.5 * fwd);
    
    float d = 0.;
    vec3 p;
    bool hit = false;
    float glowAccum = 0.;
    
    for (int i = 0; i < 100; i++) {
        p = ro + rd * d;
        float dist = scene(p, bass, mid, treble);
        glowAccum += glow * 0.015;
        if (dist < 0.002) { hit = true; break; }
        d += dist * 0.8;
        if (d > 50.) break;
    }
    
    vec3 col = vec3(0.01, 0.015, 0.03);
    float minD = min(min(lattice1, lattice2), lattice3);
    int hitLattice = (minD == lattice1) ? 0 : (minD == lattice2) ? 1 : 2;
    
    if (hit) {
        vec2 e = vec2(0.002, 0);
        vec3 n = normalize(vec3(
            scene(p + e.xyy, bass, mid, treble) - scene(p - e.xyy, bass, mid, treble),
            scene(p + e.yxy, bass, mid, treble) - scene(p - e.yxy, bass, mid, treble),
            scene(p + e.yyx, bass, mid, treble) - scene(p - e.yyx, bass, mid, treble)
        ));
        
        vec3 baseCol;
        if (hitLattice == 0) baseCol = vec3(0.4 + bass * 0.3, 0.6, 0.9);
        else if (hitLattice == 1) baseCol = vec3(0.9, 0.5 + mid * 0.3, 0.4);
        else baseCol = vec3(0.5, 0.8 + treble * 0.2, 0.5);
        
        float light = pow(length(sin(n * 2.) * 0.5 + 0.5) / sqrt(3.), 1.5);
        float fres = pow(1. - abs(dot(-rd, n)), 2.);
        
        col = baseCol * light * 0.8;
        col += fres * vec3(0.3, 0.35, 0.4) * 0.4;
        col *= exp(-d * 0.04);
    }
    
    vec3 glowCol = vec3(0.4 + bass * 0.2, 0.5, 0.7 + treble * 0.2);
    col += glowCol * glowAccum * (0.5 + bass * 0.3);
    col *= 1. - length(uv) * 0.15;
    
    fragColor = vec4(pow(max(col, 0.), vec3(0.4545)), 1);
}

