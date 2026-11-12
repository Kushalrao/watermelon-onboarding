import SwiftUI

/// Auto-layout container: the Figma frame with gap and padding, expressed in spacing tokens.
///
/// Use it instead of `VStack(spacing: 9)` / `.padding(21)` so every gap traces to a Figma Spacing variable.
///
///     Stack(gap: .spaceMd, padding: .spaceXl) { … }
///     Stack(direction: .horizontal, gap: .spaceXs, alignment: .center) { … }
struct Stack<Content: View>: View {
    enum Direction { case vertical, horizontal }

    /// Layout direction. Defaults to a vertical column.
    var direction: Direction = .vertical
    /// Gap between children. Defaults to none: children touch unless a token says otherwise.
    var gap: SpacingToken = .spaceNone
    /// Padding on all sides.
    var padding: SpacingToken = .spaceNone
    /// Horizontal padding (overrides `padding` on that axis).
    var paddingHorizontal: SpacingToken? = nil
    /// Vertical padding (overrides `padding` on that axis).
    var paddingVertical: SpacingToken? = nil
    /// Where children sit across the stack: its horizontal part for a column, its vertical part for a row.
    var alignment: Alignment = .topLeading
    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            switch direction {
            case .vertical: VStack(alignment: alignment.horizontal, spacing: gap.value, content: content)
            case .horizontal: HStack(alignment: alignment.vertical, spacing: gap.value, content: content)
            }
        }
        .padding(.horizontal, (paddingHorizontal ?? padding).value)
        .padding(.vertical, (paddingVertical ?? padding).value)
    }
}
