import SwiftUI

/// Where a chat page grows out of: an icon's on-screen frame and its colour
struct ChatSource: Equatable {
    var frame: CGRect
    var fill: Color
    /// A brand-new conversation: no history, the agent opens it
    var fresh = false
}

private struct OpenMoodDialKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenChatKey: EnvironmentKey {
    static let defaultValue: (ChatSource) -> Void = { _ in }
}

extension EnvironmentValues {
    /// Opens the chat page, expanding it out of the tapped icon
    var openChat: (ChatSource) -> Void {
        get { self[OpenChatKey.self] }
        set { self[OpenChatKey.self] = newValue }
    }

    /// Raises the market-mood dial (the + button)
    var openMoodDial: () -> Void {
        get { self[OpenMoodDialKey.self] }
        set { self[OpenMoodDialKey.self] = newValue }
    }
}

/// iOS zoom transition: at 0 the page is shrunk into the source icon (clipped to its shape, under a
/// cover of the icon's colour); at 1 it fills the screen. The page is scaled to the icon's width and centred on
/// it, so it reads as the icon itself opening up into the page.
///
/// Where it is (`move`) and how big it is (`grow`) run on separate springs, so the size trails the travel a
/// touch and overshoots before settling, like the system's own zoom.
struct ZoomFromSource: ViewModifier, Animatable {
    var move: CGFloat
    var grow: CGFloat
    let source: ChatSource
    /// Full screen size, safe areas included
    let screen: CGSize

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(move, grow) }
        set { move = newValue.first; grow = newValue.second }
    }

    /// Display corner radius, so the page lands flush with the screen's own corners
    private static let screenCorner: CGFloat = 55

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let bounds = geo.frame(in: .global)
            // Everything in the page's own coordinates (it's laid out inside the safe area)
            let full = CGRect(x: -bounds.minX, y: -bounds.minY, width: screen.width, height: screen.height)
            let from = source.frame.offsetBy(dx: -bounds.minX, dy: -bounds.minY)
            let size = CGSize(width: lerp(from.width, full.width, grow), height: lerp(from.height, full.height, grow))
            let mid = CGPoint(x: lerp(from.midX, full.midX, move), y: lerp(from.midY, full.midY, move))
            let rect = CGRect(x: mid.x - size.width / 2, y: mid.y - size.height / 2, width: size.width, height: size.height)
            let scale = lerp(from.width / full.width, 1, grow)
            let corner = lerp(from.height / 2, Self.screenCorner, grow)
            let centre = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            // Scaling about the page's centre moves the screen's centre here; shift it onto the growing frame's centre
            let screenMid = CGPoint(x: centre.x + scale * (full.midX - centre.x), y: centre.y + scale * (full.midY - centre.y))

            content
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(scale)
                .offset(x: rect.midX - screenMid.x, y: rect.midY - screenMid.y)
                // The icon's colour covers the page at first and fades as it opens
                .overlay {
                    RectShape(rect: rect, corner: corner)
                        .fill(source.fill)
                        .opacity(Double(1 - min(1, max(0, grow) / 0.3)))
                        .allowsHitTesting(false)
                }
                .mask { RectShape(rect: rect, corner: corner) }
        }
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }
}

/// A rounded rect at an arbitrary spot, even outside the view's own bounds
private struct RectShape: Shape {
    var rect: CGRect
    var corner: CGFloat

    func path(in _: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: max(0, min(corner, rect.height / 2, rect.width / 2)), style: .continuous)
    }
}
