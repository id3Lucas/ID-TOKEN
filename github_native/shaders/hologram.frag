#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uTilt;   // Tilt vector (-1.0 to 1.0)
uniform float uOpacity; // Global opacity based on speed

uniform sampler2D uTexHex;
uniform sampler2D uTexText;
uniform sampler2D uTexWave;

out vec4 fragColor;

// Helper to simulate "oil on water" rainbow colors
vec3 iridescence(vec2 uv, float rotation) {
    float t = uTime * 0.5;
    vec3 col = 0.5 + 0.5 * cos(t + uv.xyx * 3.0 + vec3(0, 2, 4) + rotation);
    return col;
}

// Sample a texture with Chromatic Aberration (RGB Split)
// layerAlpha: Base transparency of this layer
// parallaxMult: How much this layer moves with tilt
// aberrationMult: How much the colors split
vec4 sampleLayer(sampler2D tex, vec2 uv, float parallaxMult, float aberrationMult, float layerAlpha) {
    // 1. Calculate UV offset due to Tilt (Parallax)
    // -uTilt because things further away move opposite to camera
    vec2 parallaxOffset = uTilt * parallaxMult * 0.1; // 0.1 max shift
    vec2 centerUV = uv + parallaxOffset;

    // 2. Chromatic Aberration Offsets
    // Split perpendicular to tilt? Or just along X?
    // Let's split along the tilt vector for realism.
    vec2 splitVector = uTilt * aberrationMult * 0.02; 

    // Sample channels
    // Input is White (1,1,1,A). We care about Alpha.
    float r = texture(tex, centerUV - splitVector).a;
    float g = texture(tex, centerUV).a;
    float b = texture(tex, centerUV + splitVector).a;

    // Combine into RGB
    vec3 rgb = vec3(r, g, b);
    
    // Calculate final alpha (union of channels)
    float a = max(r, max(g, b));

    return vec4(rgb * layerAlpha, a * layerAlpha);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    
    // --- LAYER COMBINATION ---
    
    // Layer 1: Waves (Background)
    // Low Parallax (0.3), No Split, Low Alpha
    vec4 colWave = sampleLayer(uTexWave, uv, 0.2, 0.0, 0.08);

    // Layer 2: Hex (Middle)
    // Medium Parallax (0.5), Slight Split, Medium Alpha
    vec4 colHex = sampleLayer(uTexHex, uv, 0.4, 0.5, 0.55);
    
    // Add Iridescence to Hex
    vec3 iris = iridescence(uv, 0.0);
    colHex.rgb *= mix(vec3(1.0), iris, 0.5); // 50% Rainbow

    // Layer 3: Text (Foreground)
    // High Parallax (1.0), High Split, Reduced Alpha from 1.0 -> 0.5
    vec4 colText = sampleLayer(uTexText, uv, 0.8, 2.0, 0.5);
    
    // Add bright Iridescence to Text
    colText.rgb += iridescence(uv, 1.0) * colText.a * 0.3;


    // --- COMPOSITING (Screen Blend) ---
    // Start with Black
    vec3 finalColor = vec3(0.0);
    
    // Add Layers (Additive/Screen look)
    finalColor += colWave.rgb * uOpacity;
    finalColor += colHex.rgb * uOpacity;
    finalColor += colText.rgb * uOpacity;

    // Final Output
    // Pre-multiplied alpha not strictly needed if we output rect
    fragColor = vec4(finalColor, 1.0);
}
