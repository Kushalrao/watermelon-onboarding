import SwiftUI

/// The outline a `Surface` takes.
enum SurfaceShape: Equatable {
    case rectangle
    /// Rounded by a radius token
    case rounded(RadiusToken)
    /// Fully rounded ends (pills). A shape, not a radius: it has no value to tokenise.
    case capsule

    var shape: AnyShape {
        switch self {
        case .rectangle: AnyShape(Rectangle())
        case .rounded(let radius): AnyShape(RoundedRectangle(cornerRadius: radius.value, style: .continuous))
        case .capsule: AnyShape(Capsule())
        }
    }
}

/// A container with the Figma "Container styles": surface fill, corner radius, hairline border and drop shadow,
/// each a token. Use it for pages, cards, panels and pills instead of `.background`, `.clipShape`, `.shadow`.
///
///     Surface(surface: .surfaceWidget, radius: .radius23, border: .borderSubtle) { … }
///     Surface(surface: .surfaceRaised, shape: .capsule, shadow: .shadow3) { … }
struct Surface<Content: View>: View {
    /// Each surface's designed elevation (the Figma Surfaces section; same table as the RN port)
    static func designedShadow(for surface: SurfaceFill) -> ShadowToken? {
        switch surface {
        case .surfaceWidget, .surfaceRaised: .shadow1
        case .surfaceFocus: .shadow2
        default: nil
        }
    }

    /// How the shadow is chosen
    enum Elevation: Equatable {
        /// The shadow designed for `surface`, if it has one
        case designed
        case none
        case token(ShadowToken)
    }

    /// Fill token. Surfaces with a designed shadow get it automatically.
    let surface: SurfaceFill?
    let shape: SurfaceShape
    /// Draws the hairline border (`BorderTokens.hairline`) in this stroke token.
    let border: BorderColor?
    let elevation: Elevation
    @ViewBuilder let content: () -> Content

    init(surface: SurfaceFill? = nil, shape: SurfaceShape = .rectangle, border: BorderColor? = nil,
         shadow: Elevation = .designed, @ViewBuilder content: @escaping () -> Content) {
        self.surface = surface
        self.shape = shape
        self.border = border
        self.elevation = shadow
        self.content = content
    }

    /// Rounded by a radius token: the usual card.
    init(surface: SurfaceFill? = nil, radius: RadiusToken, border: BorderColor? = nil,
         shadow: Elevation = .designed, @ViewBuilder content: @escaping () -> Content) {
        self.init(surface: surface, shape: .rounded(radius), border: border, shadow: shadow, content: content)
    }

    var resolvedShadow: ShadowToken? {
        switch elevation {
        case .designed: surface.flatMap(Self.designedShadow)
        case .none: nil
        case .token(let token): token
        }
    }

    /// The hairline, drawn inside the outline
    @ViewBuilder private func stroke(_ color: Color) -> some View {
        switch shape {
        case .rectangle: Rectangle().strokeBorder(color, lineWidth: BorderTokens.hairline)
        case .rounded(let radius):
            RoundedRectangle(cornerRadius: radius.value, style: .continuous).strokeBorder(color, lineWidth: BorderTokens.hairline)
        case .capsule: Capsule().strokeBorder(color, lineWidth: BorderTokens.hairline)
        }
    }

    var body: some View {
        let outline = shape.shape
        content()
            .clipShape(outline)
            .background {
                if let surface {
                    outline.fill(surface.color).dsShadow(resolvedShadow)
                }
            }
            .overlay {
                if let border { stroke(border.color) }
            }
    }
}
