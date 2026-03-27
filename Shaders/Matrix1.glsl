// Matrix Rain Effect - Classic green falling characters
// Uses Amiga font texture for authentic retro look
// Non-audio reactive shader

#version 330 core

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel1;  // Amiga font texture: 08b42b43ae9d3c0605da11d0eac86618ea888e62cdd9518ee8b9097488b31560.png

out vec4 fragColor;

#define CELLS vec2(64.0,30.0)
#define FALLERS 14.0
#define FALLERHEIGHT 12.0

vec2 rand(vec2 uv) {
    return floor(abs(mod(cos(
        uv * 652.6345 + uv.yx * 534.375 +
        iTime * 0.0000005 * dot(uv, vec2(0.364, 0.934))),
     0.001)) * 16000.0);
}

float fallerSpeed(float col, float faller) {
    return mod(cos(col * 363.435  + faller * 234.323), 0.1) * 1.0 + 0.3;
}

void main()
{
    vec2 fragCoord = vec2(gl_FragCoord.x, iResolution.y - gl_FragCoord.y);
    vec2 uv = fragCoord/iResolution.xy;

    vec2 pix = mod(uv, 1.0/CELLS);
    vec2 cell = (uv - pix) * CELLS;
    pix *= CELLS * vec2(0.8, 1.0) + vec2(0.1, 0.0);

    float c = texture(iChannel1, (rand(cell) + pix) / 16.0).x;

    float b = 0.0;
    for (float i = 0.0; i < FALLERS; ++i) {
        float f = 3.0 - cell.y * 0.05 -
            mod((iTime + i * 3534.34) * fallerSpeed(cell.x, i), FALLERHEIGHT);
        if (f > 0.0 && f < 1.0)
            b += f;
    }

    fragColor = vec4(0.0, c * b, 0.0, 1.0);
}