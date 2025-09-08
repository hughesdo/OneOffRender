// License: MIT
// Author: chenkai
// Ported from https://codertw.com/%E7%A8%8B%E5%BC%8F%E8%AA%9E%E8%A8%80/671116/
#version 330

uniform sampler2D from; // First video texture
uniform sampler2D to; // Second video texture
uniform float progress; // Transition progress (0.0 to 1.0)
uniform vec2 resolution; // Resolution
uniform float ratio; // = 1.0

out vec4 outColor;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 motionBlurFrom(vec2 _st, vec2 speed) {
    vec2 texCoord = _st.xy / vec2(1.0).xy;
    vec3 color = vec3(0.0);
    float total = 0.0;
    float offset = rand(_st);
    for (float t = 0.0; t <= 20.0; t++) {
        float percent = (t + offset) / 20.0;
        float weight = 4.0 * (percent - percent * percent);
        vec2 newuv = texCoord + speed * percent;
        newuv = fract(newuv);
        color += texture(from, newuv).rgb * weight;
        total += weight;
    }
    return vec4(color / total, 1.0);
}

vec4 motionBlurTo(vec2 _st, vec2 speed) {
    vec2 texCoord = _st.xy / vec2(1.0).xy;
    vec3 color = vec3(0.0);
    float total = 0.0;
    float offset = rand(_st);
    for (float t = 0.0; t <= 20.0; t++) {
        float percent = (t + offset) / 20.0;
        float weight = 4.0 * (percent - percent * percent);
        vec2 newuv = texCoord + speed * percent;
        newuv = fract(newuv);
        color += texture(to, newuv).rgb * weight;
        total += weight;
    }
    return vec4(color / total, 1.0);
}

float A(float aA1, float aA2) {
    return 1.0 - 3.0 * aA2 + 3.0 * aA1;
}

float B(float aA1, float aA2) {
    return 3.0 * aA2 - 6.0 * aA1;
}

float C(float aA1) {
    return 3.0 * aA1;
}

float GetSlope(float aT, float aA1, float aA2) {
    return 3.0 * A(aA1, aA2) * aT * aT + 2.0 * B(aA1, aA2) * aT + C(aA1);
}

float CalcBezier(float aT, float aA1, float aA2) {
    return ((A(aA1, aA2) * aT + B(aA1, aA2)) * aT + C(aA1)) * aT;
}

float GetTForX(float aX, float mX1, float mX2) {
    float aGuessT = aX;
    for (int i = 0; i < 4; ++i) {
        float currentSlope = GetSlope(aGuessT, mX1, mX2);
        if (currentSlope == 0.0) return aGuessT;
        float currentX = CalcBezier(aGuessT, mX1, mX2) - aX;
        aGuessT -= currentX / currentSlope;
    }
    return aGuessT;
}

float KeySpline(float aX, float mX1, float mY1, float mX2, float mY2) {
    if (mX1 == mY1 && mX2 == mY2) return aX;
    return CalcBezier(GetTForX(aX, mX1, mX2), mY1, mY2);
}

float normpdf(float x) {
    return exp(-20.0 * pow(x - 0.5, 2.0));
}

vec2 rotateUv(vec2 uv, float angle, vec2 anchor, float zDirection) {
    uv = uv - anchor;
    float s = sin(angle);
    float c = cos(angle);
    mat2 m = mat2(c, -s, s, c);
    uv = m * uv;
    uv += anchor;
    return uv;
}

vec4 transition(vec2 uv) {
    float animationTime = progress;
    float easingTime = KeySpline(animationTime, 0.68, 0.01, 0.17, 0.98);
    float blur = normpdf(easingTime);
    float r = 0.0;
    float rotation = 180.0 / 180.0 * 3.14159;
    if (easingTime <= 0.5) {
        r = rotation * easingTime;
    } else {
        r = -rotation + rotation * easingTime;
    }

    vec2 mystCurrent = uv;
    mystCurrent.y *= 1.0 / ratio;
    mystCurrent = rotateUv(mystCurrent, r, vec2(1.0, 0.0), -1.0);
    mystCurrent.y *= ratio;

    float timeInterval = 0.0167 * 2.0;
    if (easingTime <= 0.5) {
        r = rotation * (easingTime + timeInterval);
    } else {
        r = -rotation + rotation * (easingTime + timeInterval);
    }

    vec2 mystNext = uv;
    mystNext.y *= 1.0 / ratio;
    mystNext = rotateUv(mystNext, r, vec2(1.0, 0.0), -1.0);
    mystNext.y *= ratio;

    vec2 speed = (mystNext - mystCurrent) / timeInterval * blur * 0.5;
    if (easingTime <= 0.5) {
        return motionBlurFrom(mystCurrent, speed);
    } else {
        return motionBlurTo(mystCurrent, speed);
    }
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    outColor = transition(uv);
}