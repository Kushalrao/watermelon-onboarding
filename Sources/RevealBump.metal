#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// A soft swell travelling down the card with the reveal front, as if something rolls along under it: around
/// `bumpY` the card is magnified a little, vertically towards the line and outwards from the middle, so its sides
/// bow out where the swell is. `centreX` is the card's middle; `strength` 0 = flat.
[[ stitchable ]] float2 revealBump(float2 position, float bumpY, float centreX, float halfHeight, float strength) {
    float d = position.y - bumpY;
    float f = exp(-(d * d) / (halfHeight * halfHeight));
    // Sampling from nearer the line and nearer the middle reads as the surface rising towards you
    float y = position.y - d * f * strength * 0.28;
    float x = centreX + (position.x - centreX) * (1.0 - f * strength * 0.035);
    return float2(x, y);
}
