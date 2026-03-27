#version 330 core

// Original author: Forthro
// Modified by: ArthurTent for ShaderAmp project
// URL: https://www.shadertoy.com/view/dtyfzD
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Converted to OneOffRender format

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;  // Audio texture

out vec4 fragColor;

// https://www.shadertoy.com/view/dtyfzD
// Modified by ArthurTent
// Created by Forthro
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/
uniform sampler2D iChannel1;

float sphereSound( in vec3 checkedPoint )
{
    vec2 samplerSmall = vec2( 0.5 + abs(sin( atan( checkedPoint.y / ( checkedPoint.x )))) / 12.0, 0.25 );
    vec2 samplerBig = vec2( cos( atan( checkedPoint.x / ( checkedPoint.z ))) / 12.0, 0.25 );

    return ( texture( iChannel0, samplerSmall ).r * texture( iChannel0, samplerBig ).r ) * 2.5;
}

float sphereDistance( in vec3 checkedPoint )
{
    const float radius = 3.0;
    const float amplification = 5.0;

    return distance( checkedPoint, vec3( 0.0, 0.0, 0.0 ) ) - radius - sphereSound( checkedPoint ) * amplification;
}

vec3 sphereNormal( in vec3 checkedPoint )
{
    const float shift = 1.1;
    return normalize(
        vec3
        (
            sphereDistance(checkedPoint + vec3( shift, 0, 0 )) - sphereDistance(checkedPoint - vec3( shift, 0, 0 )),
            sphereDistance(checkedPoint + vec3( 0, shift, 0 )) - sphereDistance(checkedPoint - vec3( 0, shift, 0 )),
            sphereDistance(checkedPoint + vec3( 0, 0, shift )) - sphereDistance(checkedPoint - vec3( 0, 0, shift ))
        )
    );
}

struct FragData{
    vec2 screenCoord;
    vec2 normalCoord;
    float normalDistance;
};

vec3 background( in FragData fragData )
{
    float sound = texture( iChannel0, vec2( cos( fragData.normalDistance ), 0.25 )).r
                + texture( iChannel0, vec2( sin( fragData.normalDistance ), 0.25 )).r;
    float fragAngle = cos( atan( fragData.normalCoord.x, fragData.normalCoord.y ) * 8.0 );

    float shiftedTime = iTime * 3.0 - ( fragData.normalDistance * 7.0 ) + fragAngle * sin( pow(( 1.3 - fragData.normalDistance ), ( 1.3 - fragData.normalDistance )) * 100.0 + iTime * 3.0 + sound * sound * 2.0);

    float waveModulator = 0.35 + sin(( fragData.normalDistance-shiftedTime /  5.0 ) * 20.0 ) / 2.0 * sound * 2.0;

    float red = ( 0.95 + sin( shiftedTime + sound * 4.0 ) / 7.0 ) * waveModulator;
    float green = 0.1 * waveModulator;
    float blue = ( 0.55 + cos( shiftedTime + sound * 4.0 ) / 3.0 ) * waveModulator;

    return vec3( red, green, blue );
}

void main( )
{
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

    const float focalLength = 10.0;
    const float camSurfaceRadius = 5.0;

    FragData fragData;
    //fragData.screenCoord = fragCoord;
    fragData.screenCoord = (fragCoord / iResolution);
    //fragData.normalCoord = -1.0 + 1.5 *(fragCoord / iResolution);
    fragData.normalCoord = -0.7 + 1.5 *(fragCoord / iResolution);
    fragData.normalDistance = distance(fragData.normalCoord, vec2( 0.0, 0.0 ));

    float camRotation = iTime / 5.0;
    float rotationRadius = 55.0 + 10.0 * cos( camRotation / 1.3 );
    vec3 camPosition = vec3( rotationRadius * sin( camRotation ) + 3.0  * cos( camRotation * 3.0 ), 4.0 * sin( camRotation / 1.3 ), -rotationRadius * cos( camRotation ) + 3.0  * sin( camRotation * 2.3 ) );
    float camYaw = camRotation;

    vec3 camLocalSurfaceCoord =
        vec3(
            cos( camYaw ) * fragData.normalCoord.x * camSurfaceRadius,
            fragData.normalCoord.y * camSurfaceRadius,
            sin( camYaw ) * fragData.normalCoord.x * camSurfaceRadius
        );
    vec3 rayDirection = normalize( vec3( camLocalSurfaceCoord.x - sin( camYaw ) * focalLength, camLocalSurfaceCoord.y, camLocalSurfaceCoord.z + cos( camYaw ) * focalLength ) );
    vec3 camSurfaceCoord = camPosition + camLocalSurfaceCoord;

    float sphereRaysShift = camPosition.y / ( distance( camPosition, vec3(0.0,0.0,0.0) ) / focalLength ) / camSurfaceRadius;
    float sphereRaysStrength = pow( sphereSound( vec3( fragData.normalCoord  + vec2( 0.0, sphereRaysShift ), 0.0 )), 2.5 );
    vec3 color = ( background( fragData ) / 25.0 + vec3( 0.12, 0.12, 0.24 ) * sphereRaysStrength ) * fragData.normalDistance;

    vec3 checkedSpherePoint = camSurfaceCoord;
    float cumulativeDensity = 1.0;

    while( distance( checkedSpherePoint, camPosition ) < 75.0 ){
    // Get fragment coordinates with Y-flip for OneOffRender
    vec2 fragCoord = gl_FragCoord.xy;
    fragCoord.y = iResolution.y - fragCoord.y;

        float currentDistance = sphereDistance( checkedSpherePoint );
        checkedSpherePoint += max( 0.5, currentDistance + 0.01 ) * rayDirection;

        float density = pow( max( 0.0, 3.5 - currentDistance ), 2.5 );

        float sound = sphereSound( checkedSpherePoint );
        float soundEffect = sound * sound / 50.0;
        color += ( vec3( soundEffect, 0.025 - soundEffect / 2.0, 0.07 - soundEffect / 2.0 ) * density + vec3( 0.15, 0.05, 0.05 ) * max( 0.0, dot( sphereNormal( checkedSpherePoint ), -rayDirection ) - 0.5 ) * density )
               / cumulativeDensity;
        cumulativeDensity += density;
    }

    fragColor = vec4( color, 1.0 );
}

