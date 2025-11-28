#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uResolution;
uniform vec2 uCenter; // Normalized center (0.0 - 1.0)
uniform float uRadius; // Normalized radius
uniform float uThickness;
uniform vec4 uColor;
uniform sampler2D uTexture; // Input texture (optional, if used as overlay)

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // Correct aspect ratio for circle
    vec2 pos = uv;
    pos.x *= uResolution.x / uResolution.y;
    vec2 center = uCenter;
    center.x *= uResolution.x / uResolution.y;
    
    float dist = distance(pos, center);
    
    // Ring calculation
    // Smoothstep for anti-aliased edges
    float ring = smoothstep(uRadius - uThickness, uRadius, dist) - 
                 smoothstep(uRadius, uRadius + uThickness, dist);
                 
    // Inner fade (echo trail)
    float trail = smoothstep(uRadius - uThickness * 4.0, uRadius, dist) * 0.5;
    
    // Combine
    float alpha = max(ring, trail);
    
    // Output color
    fragColor = uColor * alpha;
}
