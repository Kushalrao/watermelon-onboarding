#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Lens-like warp around a vertical band at `bandX`: pixels near the band are pulled sideways towards it
/// and rippled vertically, fading out with distance. `strength` 0 = no warp.
[[ stitchable ]] float2 bandWarp(float2 position, float bandX, float halfWidth, float strength) {
    float d = position.x - bandX;
    float f = exp(-(d * d) / (halfWidth * halfWidth));
    float dx = d * f * strength * 0.9;
    float dy = sin(position.y * 0.07 + bandX * 0.05) * f * strength * 14.0;
    return float2(position.x + dx, position.y + dy);
}

/// Same warp for a horizontal band travelling vertically at `bandY`.
[[ stitchable ]] float2 bandWarpY(float2 position, float bandY, float halfWidth, float strength) {
    float d = position.y - bandY;
    float f = exp(-(d * d) / (halfWidth * halfWidth));
    float dy = d * f * strength * 0.9;
    float dx = sin(position.x * 0.07 + bandY * 0.05) * f * strength * 14.0;
    return float2(position.x + dx, position.y + dy);
}
