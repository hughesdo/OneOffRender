#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// 10 Step Test
// Created by diatribes
// Shadertoy ID: 3Xy3z1
// https://www.shadertoy.com/view/3Xy3z1

void main() {
    vec2 u = gl_FragCoord.xy;
    vec4 o;
    float i, d, s, a, b, n, t=iTime*.65;
    
    vec3 p = vec3(iResolution.xy, iResolution.y), q;
    
    u = (u-p.xy/2.)/p.y;
    
    if(abs(u.y)>.4){ o = vec4(0); fragColor = o; return; }

    
    for(o*=i; i++<10.; ) {
        q = p = vec3(u * d, d);
        
        q.z += t*9.;
        
        p.x -= 50.;
        
        a = 32. + p.y - length(p.y);
        
        b = 42. + p.y - abs(cos(p.x*.03)*38.);
        
        for (n = .1; n < 2.; n += n )
            a += abs(dot(sin(4.*t+q*n*3.), vec3(.13))) / n,
            b += abs(dot(sin(p*n*1.), vec3(.23))) / n;
        d += s = .08 + abs(min(a,b))*.8;
        
        o += 1. / s;
    }
    u.y -= .25;
    
    o = tanh(vec4(a > b?7:4,5, a > b?3:9,1)*o  / 3e2 / pow(dot(u,u),.9));
    
    fragColor = o;
}

