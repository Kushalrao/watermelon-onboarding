import SwiftUI

/// The only way to render text in the design system. Picks a `TypographyScale` variant and a content colour
/// token, so family, weight, size, line height, tracking and colour always come from Figma-bound tokens.
///
/// Reach for it anywhere you would write `Text`; never set `.font`, `.tracking` or `.lineSpacing` by hand.
///
///     DsText("Fixed Deposits", variant: .h1)
///     DsText("7.85%", variant: .n2, color: .statusSuccessText)
struct DsText: View {
    private let text: Text
    /// Which text style to render. Names match the Figma text styles (D1, H3, P2, Lb1, N4 …).
    let variant: TypographyVariant
    /// Text colour token. Defaults to `contentPrimary`.
    let color: TextColor

    init(_ string: String, variant: TypographyVariant, color: TextColor = .contentPrimary) {
        self.text = Text(verbatim: string)
        self.variant = variant
        self.color = color
    }

    var body: some View {
        text
            .modifier(DsTextStyle(spec: variant.spec))
            .foregroundStyle(color.color)
    }
}
