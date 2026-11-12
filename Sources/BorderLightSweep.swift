import SwiftUI

/// A heat-map gradient (bottom → top) on the rounded-rect border, visible only while the page is
/// collapsing into the widget. `progress` is the transition progress; the light fades in as the
/// movement starts and is gone by the time the widget has landed.
struct BorderHeatGlow: View {
    let cornerRadius: CGFloat
    let progress: CGFloat

    private var heat: LinearGradient {
        // Simple warm heat, bottom → top, kept subtle
        LinearGradient(
            colors: [
                Color(hex: 0xFF3D00).opacity(0.55),
                Color(hex: 0xFF8A00).opacity(0.4),
                Color(hex: 0xFFD54F).opacity(0.0),
            ],
            startPoint: .bottom, endPoint: .top
        )
    }

    var body: some View {
        // Fades in over the first 10% of the move, holds, fades out over the last 15%
        let fadeIn = min(1, progress / 0.1)
        let fadeOut = 1 - min(1, max(0, (progress - 0.85) / 0.15))
        let opacity = fadeIn * fadeOut
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            // Faint softness so the line doesn't look hard, no glow
            shape.strokeBorder(heat, lineWidth: 3).blur(radius: 3).opacity(0.5)
            shape.strokeBorder(heat, lineWidth: 1.2)
        }
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}
