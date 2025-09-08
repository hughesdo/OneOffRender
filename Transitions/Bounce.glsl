#version 330

uniform float progress;
uniform sampler2D from;
uniform sampler2D to;

uniform vec4 shadow_colour; // = vec4(0.,0.,0.,.6)
uniform float shadow_height; // = 0.075
uniform float bounces; // = 3.0

const float PI = 3.14159265358;

vec4 transition(vec2 uv) {
  float time = progress;
  float stime = sin(time * PI / 2.);
  float phase = time * PI * bounces;
  float y = (abs(cos(phase))) * (1.0 - stime);
  float d = uv.y - y;

  return mix(
    mix(
      texture(to, uv),
      shadow_colour,
      step(d, shadow_height) * (1.0 - mix(
        ((d / shadow_height) * shadow_colour.a) + (1.0 - shadow_colour.a),
        1.0,
        smoothstep(0.95, 1., progress)
      ))
    ),
    texture(from, vec2(uv.x, uv.y + (1.0 - y))),
    step(d, 0.0)
  );
}

void main() {
  vec2 uv = gl_FragCoord.xy / vec2(1280.0, 720.0);  // Consider using 'resolution' uniform later
  gl_FragColor = transition(uv);
}
