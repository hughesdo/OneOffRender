/*================================
=           Gemmarium            =
=         Author: Jaenam         =
================================*/
// Date:    2025-11-28
// License: Creative Commons (CC BY-NC-SA 4.0)

//Twigl (golfed) version --> https://x.com/Jaenam97/status/1994387530024718563?s=20

#version 330 core

uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

// Gemmarium-inspired 2D gem with mirrored floor. This is a stable,
// GLSL 330-core friendly version that captures the faceted gem feel
// without the extremely golfed original code that caused driver/
// compilation issues on some setups.
void mainImage(out vec4 O, vec2 fragCoord)
{
	vec2 resolution = iResolution;
	float time = iTime * 0.3;

	// Normalized coordinates, center at 0
	vec2 uv = (fragCoord * 2.0 - resolution.xy) / resolution.y;

	const float PI = 3.14159265359;
	float r = length(uv);
	float a = atan(uv.y, uv.x);

	// Faceted radial segments (like gem cuts)
	float segments = 12.0;
	float segAngle = 2.0 * PI / segments;
	float id = floor(a / segAngle + 0.5);
	float localAngle = a - id * segAngle;
	localAngle = abs(localAngle);

	// How close we are to a facet center (0 at edge, 1 at center)
	float facetMask = 1.0 - smoothstep(0.0, segAngle * 0.5, localAngle);

	// Animated radius for the main gem ring
	float baseRadius = 0.55;
	float animate = 0.08 * sin(time * 2.0 + id * 0.8)
	              + 0.04 * sin(time * 5.0 + id * 1.7);
	float radius = baseRadius + animate;

	float edge = smoothstep(radius, radius - 0.015, r);
	float inner = smoothstep(radius * 0.5, radius * 0.5 - 0.01, r);
	float gemMask = edge * facetMask + inner * 0.5;

	// Mirrored floor: reflect across a horizontal line and add a dimmer copy
	float floorY = -0.15;
	float reflectMask = 0.0;
	if (uv.y < floorY)
	{
		vec2 uvFloor = uv;
		uvFloor.y = floorY - (uv.y - floorY);

		float r2 = length(uvFloor);
		float a2 = atan(uvFloor.y, uvFloor.x);
		float id2 = floor(a2 / segAngle + 0.5);
		float local2 = abs(a2 - id2 * segAngle);
		float facet2 = 1.0 - smoothstep(0.0, segAngle * 0.5, local2);

		float radius2 = baseRadius + animate * 0.8;
		float edge2 = smoothstep(radius2, radius2 - 0.015, r2);
		float inner2 = smoothstep(radius2 * 0.5, radius2 * 0.5 - 0.01, r2);
		float gemMask2 = edge2 * facet2 + inner2 * 0.5;

		reflectMask = gemMask2 * 0.4;
	}

	// Base background (very dark, slight vignette)
	float vignette = smoothstep(1.2, 0.2, r);
	vec3 col = vec3(0.01, 0.01, 0.03) * vignette;

	// Gem colors: simple dispersion across facets
	vec3 facetColor = 0.4 + 0.6 * cos(vec3(0.0, 2.0, 4.0) + id * 0.8 + time * 2.0);
	col += facetColor * gemMask;
	col += facetColor * reflectMask * 0.6;

	// Radial glow around the gem
	float glow = smoothstep(0.8, 0.2, r);
	col += vec3(0.15, 0.2, 0.35) * glow * (0.3 + 0.7 * sin(time * 3.0));

	// Slight gamma adjustment
	col = pow(max(col, 0.0), vec3(0.85));

	O = vec4(col, 1.0);
}

void main()
{
    vec2 fragCoord = gl_FragCoord.xy;
    mainImage(fragColor, fragCoord);
}
