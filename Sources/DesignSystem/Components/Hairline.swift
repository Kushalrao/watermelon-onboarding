import SwiftUI

/// A separator: the one stroke weight in the system (`BorderTokens.hairline`), in a border colour token.
/// Runs the full length of its container on the given axis.
struct Hairline: View {
    enum Axis { case horizontal, vertical }

    let color: BorderColor
    var axis: Axis = .horizontal

    init(_ color: BorderColor = .borderSubtle, axis: Axis = .horizontal) {
        self.color = color
        self.axis = axis
    }

    var body: some View {
        switch axis {
        case .horizontal: color.color.frame(height: BorderTokens.hairline)
        case .vertical: color.color.frame(width: BorderTokens.hairline)
        }
    }
}
