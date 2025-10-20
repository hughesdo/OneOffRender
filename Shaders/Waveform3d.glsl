/*
    "Waveform3d" by @XorDev

    I wish Soundcloud worked on ShaderToy again

    Converted for OneOffRender - GLSL 330 core
*/

#version 330 core

out vec4 fragColor;

// Uniforms
uniform vec2 iResolution;      // Resolution
uniform float iTime;           // Time
uniform sampler2D iChannel0;   // Buffer A output (feedback buffer)
uniform sampler2D iChannel1;   // Audio FFT texture

void mainImage(out vec4 O, vec2 I)
{
    // Y-flip to match Shadertoy coordinate system
    I.y = iResolution.y - I.y;

    //Raymarch iterator, step distance, depth and reflection
    float i, d, z, r;
    //Clear fragcolor and raymarch 90 steps
    for(O*= i; i++<9e1;
    //Pick color and attenuate
    O += (cos(z*.5+iTime+vec4(0,2,4,3))+1.3)/d/z)
    {
        //Raymarch sample point
        vec3 R = iResolution.xyy,
         p = z * normalize(vec3(I+I,0) - R);
        //Shift camera and get reflection coordinates
        r = max(-++p, 0.).y;
        //Mirror and music - Buffer A contains scrolling waveform history
        // Sample from buffer using x position and z-depth for the scrolling y coordinate
        float x = (p.x+6.5)/15.;
        float y = (-p.z-3.)*5e1/R.y;
        p.y += r+r-4.*texture(iChannel0, vec2(x, y)).r;
        //Step forward (reflections are softer)
        z += d = .1*(.1*r+abs(p.y)/(1.+r+r+r*r) + max(d=p.z+3.,-d*.1));
    }
    //Tanh tonemapping
    O = tanh(O/9e2);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}