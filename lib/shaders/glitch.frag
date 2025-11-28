#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uResolution;
uniform float uIntensity; // 0.0 to 1.0
uniform sampler2D uTexture;

out vec4 fragColor;

// Simple pseudo-random noise
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Glitch displacement
    float glitchAmount = uIntensity * 0.05;
    float n = noise(vec2(uv.y * 10.0, uTime * 10.0));
    
    // Random horizontal displacement based on noise and intensity
    float displacement = (n - 0.5) * glitchAmount;
    
    // Only apply displacement in bands
    if (random(vec2(floor(uv.y * 20.0), uTime)) > 0.8) {
        uv.x += displacement;
    }
    
    // Chromatic Aberration
    float aberration = uIntensity * 0.02;
    
    vec4 r = texture(uTexture, uv + vec2(aberration, 0.0));
    vec4 g = texture(uTexture, uv);
    vec4 b = texture(uTexture, uv - vec2(aberration, 0.0));
    
    // Scanlines
    float scanline = sin(uv.y * 800.0 + uTime * 10.0) * 0.1 * uIntensity;
    
    vec4 color = vec4(r.r, g.g, b.b, g.a);
    color.rgb -= scanline;
    
    // Noise grain
    float grain = random(uv + uTime) * 0.1 * uIntensity;
    color.rgb += grain;
    
    fragColor = color;
}
