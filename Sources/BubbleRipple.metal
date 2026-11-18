#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// A small ripple that crosses a chat bubble from left to right with the white that washes over it: what's under
// the front bobs by about a point, and is still again once it's passed. `progress` runs 0 → 1.
[[ stitchable ]] float2 bubbleRipple(float2 position, float2 size, float progress) {
    float front = mix(-0.2, 1.2, progress) * size.x;
    float d = (position.x - front) / 70.0;
    // Nothing at either end, so the bubble starts and finishes undisturbed
    float env = exp(-d * d) * sin(progress * 3.14159265);
    return position + float2(sin(d * 2.0) * 0.4, cos(d * 2.2) * 1.1) * env;
}
