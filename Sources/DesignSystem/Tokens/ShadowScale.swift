import SwiftUI

// Hand-authored Tier 2: elevation, with the RN port's names (shadow1 … shadow3). The Figma parameters come from
// the generated ShadowPrimitives (the Shadow/1–3 effect styles); the SwiftUI mapping comes from DSPlatform.
//
// GAP: SwiftUI's `.shadow` has no `spread`. Colour, opacity, offset and blur are applied as designed; spread
// (12 / 7 / 7) is dropped, so each shadow reaches a little less far than in Figma. Not approximated (ADR 005).

/// What SwiftUI's `.shadow(color:radius:x:y:)` takes for one level, plus the Figma parameters it came from.
struct ShadowSpec {
    /// The Figma drop shadow, kept for traceability (and for `spread`, which SwiftUI can't draw)
    let figma: ShadowParams
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    init(_ p: ShadowParams) {
        figma = p
        color = Color(hex: p.color, opacity: p.opacity)
        radius = DSPlatform.shadowRadius(blur: p.blur)
        x = p.offsetX
        y = p.offsetY
    }
}

enum ShadowScale {
    /// Shadow/1: resting surface lift.
    static let shadow1 = ShadowSpec(ShadowPrimitives.shadow1)
    /// Shadow/2: raised surface.
    static let shadow2 = ShadowSpec(ShadowPrimitives.shadow2)
    /// Shadow/3: strongest lift (floating / dark card).
    static let shadow3 = ShadowSpec(ShadowPrimitives.shadow3)
}

/// A `ShadowScale` level, as `Surface(shadow:)` takes it.
enum ShadowToken: CaseIterable {
    case shadow1, shadow2, shadow3

    var spec: ShadowSpec {
        switch self {
        case .shadow1: ShadowScale.shadow1
        case .shadow2: ShadowScale.shadow2
        case .shadow3: ShadowScale.shadow3
        }
    }
}

extension View {
    /// The drop shadow for a `ShadowScale` level. Prefer `Surface(shadow:)`; this is for shapes `Surface` can't be.
    func dsShadow(_ token: ShadowToken?) -> some View {
        let spec = token?.spec
        return shadow(color: spec?.color ?? .clear, radius: spec?.radius ?? 0, x: spec?.x ?? 0, y: spec?.y ?? 0)
    }
}
