#version 330

uniform float progress;
uniform sampler2D from;
uniform sampler2D to;

// author: Gunnar Roth
// based on work from natewave
// license: MIT
vec4 transition(vec2 p) {
  vec2 block = floor(p.xy / vec2(16));
  vec2 uv_noise = block / vec2(64);
  uv_noise += floor(vec2(progress) * vec2(1200.0, 3500.0)) / vec2(64);
  vec2 dist = progress > 0.0 ? (fract(uv_noise) - 0.5) * 0.3 *(1.0 -progress) : vec2(0.0);
  vec2 red = p + dist * 0.2;
  vec2 green = p + dist * .3;
  vec2 blue = p + dist * .5;

  return vec4(mix(texture(from, red), texture(to, red), progress).r,mix(texture(from, green), texture(to, green), progress).g,mix(texture(from, blue), texture(to, blue), progress).b,1.0);
}


void main() {
    vec2 uv = gl_FragCoord.xy / vec2(1280.0, 720.0);
    vec4 fromColor = texture(from, uv);
    vec4 toColor = texture(to, uv);
    gl_FragColor = mix(fromColor, toColor, progress);
}
