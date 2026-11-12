import SwiftUI

/// Figma: "iPhone 14 Plus - 233" (771:12568) — teaches tap & hold. The Continue button stays inactive
/// until the user holds the card; the chips come out, a little confetti falls, and Continue moves on.
struct OnboardingHoldView: View {
    let onContinue: () -> Void

    @State private var heldFrame: CGRect?
    @State private var cardFrame: CGRect = .zero
    @State private var pressing = false
    @State private var holdProgress: CGFloat = 0
    @State private var chipsOut = false
    @State private var done = false
    @State private var confettiBurst = 0

    // Panel (771:12891) and the research card inside it (771:12688)
    private static let panel = CGRect(x: 6, y: 172, width: 378, height: 392)
    private static let cardInPanel = CGRect(x: 7, y: 55, width: 364, height: 330)
    private static let questions = ["Explain me the terms", "Why is the ratio so high?"]

    var body: some View {
        let card = CGRect(
            x: Self.panel.minX + Self.cardInPanel.minX, y: Self.panel.minY + Self.cardInPanel.minY,
            width: Self.cardInPanel.width, height: Self.cardInPanel.height
        )

        ZStack(alignment: .topLeading) {
            OnboardingBackground()

            Text("Hold & see suggestions")
                .font(FigmaFont.walsheimMedium(31))
                .foregroundStyle(Color.ink)
                .at(23, 81)

            // Line 25: 2pt dashes, 4pt apart
            DashedRule()
                .frame(width: 344, height: 2)
                .at(23, 151)

            // Yellow hint panel
            ZStack(alignment: .topLeading) {
                Color(hex: 0xFAF7D4)

                BlinkingCircle(blinking: !done)
                    .at(16, 13)

                Text("Tap & hold me to view suggested questions")
                    .font(FigmaFont.walsheimMedium(15))
                    .foregroundStyle(Color(hex: 0x797419))
                    .at(56, 17)

                ResearchCard()
                    .opacity(heldFrame != nil ? 0 : 1)
                    .scaleEffect(pressing && heldFrame == nil ? 1.015 : 1)
                    .animation(.easeOut(duration: 0.25), value: pressing)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cardFrame = $0 }
                    .at(Self.cardInPanel.minX, Self.cardInPanel.minY)
            }
            .frame(width: Self.panel.width, height: Self.panel.height, alignment: .topLeading)
            // The whole panel listens for the hold; only the card reacts
            .background(
                LongPressAttach(
                    onPressing: { down in
                        pressing = down
                        if down { Haptics.prepare() }
                    },
                    onHold: { hold(cardFrame) }
                )
            )
            .at(Self.panel.minX, Self.panel.minY)

            HeldWidgetLayer(
                frame: heldFrame,
                questions: Self.questions,
                progress: holdProgress,
                chipsOut: chipsOut,
                onDismiss: release
            ) { ResearchCard() }

            // Above the held layer, so it stays tappable while the card is lifted
            OnboardingButton(title: "Continue", enabled: done, action: onContinue)
                .at(23, 738)

            ConfettiBurst(trigger: confettiBurst, origin: CGPoint(x: card.minX + 40, y: card.maxY + 20))
                .allowsHitTesting(false)
        }
        .frame(width: MutualFundScreen.canvasWidth, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(OnboardingBackground())
    }

    /// Tap outside the lifted card puts it back (Continue stays active once the hold has been done)
    private func release() {
        guard heldFrame != nil else { return }
        Haptics.settle()
        chipsOut = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            holdProgress = 0
        } completion: {
            heldFrame = nil
        }
    }

    private func hold(_ frame: CGRect) {
        guard heldFrame == nil else { return }
        Haptics.lift()
        heldFrame = frame
        holdProgress = 0
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) { holdProgress = 1 }
        DispatchQueue.main.async { chipsOut = true }

        // Chips are out → a little celebration and Continue becomes active; the user moves on with it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            confettiBurst += 1
            Haptics.tap()
            withAnimation { done = true }
        }
    }
}

// MARK: - Pieces

/// Line 25 (771:12581): 2pt dashes with 4pt gaps, 23% black
struct DashedRule: View {
    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 1))
            p.addLine(to: CGPoint(x: 344, y: 1))
        }
        .stroke(Color.black.opacity(0.23), style: StrokeStyle(lineWidth: 2, dash: [2, 4]))
    }
}

/// Frame 2329 (771:12897): yellow ring, blinking slowly until the hold is done
private struct BlinkingCircle: View {
    let blinking: Bool
    @State private var dim = false

    var body: some View {
        Image("HoldCircle")
            .resizable()
            .frame(width: 29, height: 29)
            .opacity(dim ? 0.25 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { dim = true }
            }
            .onChange(of: blinking) { _, on in
                if !on { withAnimation(.easeOut(duration: 0.3)) { dim = false } }
            }
    }
}

/// Research card (771:12688), 364 × 330: MSFT header row + Total worth / XIRR / Expense ratio
struct ResearchCard: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            // Header row (771:12708)
            Image("MetaIcon")
                .resizable()
                .frame(width: 36, height: 39)
                .frame(width: 37, height: 37)
                .clipped()
                .at(15, 17)

            Text("MSFT")
                .font(FigmaFont.walsheimMedium(15))
                .tracking(1.05)
                .foregroundStyle(Color.black.opacity(0.83))
                .at(61, 17)

            Text("NSE")
                .font(FigmaFont.walsheim(14))
                .foregroundStyle(Color.black.opacity(0.56))
                .at(61, 37)

            Image("Sparkline")
                .resizable()
                .frame(width: 37.9174, height: 31)
                .at(208, 14)

            HStack(alignment: .top, spacing: 1) {
                Text("21,202")
                    .font(FigmaFont.walsheimMedium(22))
                    .foregroundStyle(Color(hex: 0x01B405))
                    .frame(width: 67, alignment: .trailing)
                Text(".02")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.black.opacity(0.6))
                    .padding(.top, 4.8)
            }
            .at(261, 14)

            divider(opacity: 0.09).at(0, 73)

            // Total worth
            Text("Total worth")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black.opacity(0.71))
                .at(17, 97)
            HStack(alignment: .top, spacing: 0) {
                Text("Rs1,42,300")
                    .font(FigmaFont.walsheim(19.23))
                    .foregroundStyle(Color.black)
                Text(".02")
                    .font(FigmaFont.walsheimMedium(14.859))
                    .foregroundStyle(Color.black.opacity(0.6))
                    .padding(.top, 4.2)
                    .padding(.leading, 1)
                Text("+42.3%")
                    .font(FigmaFont.walsheimMedium(19.23))
                    .foregroundStyle(Color.gain)
                    .padding(.leading, 7)
            }
            .at(154, 97)

            divider(opacity: 0.1).at(0, 149)

            Text("XIRR")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black.opacity(0.71))
                .at(17, 175)
            valueWithCaption("12.4%", "Know more").at(154, 175)

            divider(opacity: 0.1).at(0, 239)

            Text("Expense ratio")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black.opacity(0.71))
                .at(17, 265)
            valueWithCaption("0.63%", "Applicable when you exit").at(154, 265)

            Image("Vector83")
                .resizable()
                .frame(width: 15.4967, height: 8.07787)
                .rotationEffect(.degrees(7.34))
                .at(10.85, 247.6)
        }
        .frame(width: 364, height: 330)
        .clipped()
        .overlay(Rectangle().stroke(Color.black.opacity(0.04), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 7.5, x: 0, y: 3)
    }

    private func divider(opacity: Double) -> some View {
        Rectangle().fill(Color.black.opacity(opacity)).frame(width: 364, height: 1)
    }

    private func valueWithCaption(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black.opacity(0.71))
                .frame(height: 22)
            Text(caption)
                .font(FigmaFont.walsheim(13))
                .foregroundStyle(Color.black.opacity(0.5))
                .frame(height: 18)
        }
    }
}

// MARK: - Subtle confetti

/// A small, quiet burst: a couple of dozen tiny flakes drift up and out from `origin`, then settle and fade.
struct ConfettiBurst: View {
    let trigger: Int
    let origin: CGPoint

    @State private var startedAt: Date?

    private struct Flake {
        let angle: Double      // radians, mostly upward
        let speed: Double      // pt/s
        let size: CGFloat
        let color: Color
        let spin: Double
        let drift: Double
    }

    private static let palette: [Color] = [
        Color(hex: 0xD4CA12), Color(hex: 0xF28B82), Color(hex: 0x7CB342),
        Color(hex: 0x64B5F6), Color(hex: 0xFFB300), Color(hex: 0xBA68C8),
    ]
    private static let duration: Double = 2.2

    private let flakes: [Flake] = {
        var g = SystemRandomNumberGenerator()
        return (0..<48).map { _ in
            Flake(
                angle: Double.random(in: (-150.0).degrees...(-30.0).degrees, using: &g),
                speed: Double.random(in: 260...460, using: &g),
                size: CGFloat.random(in: 5...9, using: &g),
                color: palette.randomElement(using: &g)!,
                spin: Double.random(in: -6...6, using: &g),
                drift: Double.random(in: -30...30, using: &g)
            )
        }
    }()

    var body: some View {
        TimelineView(.animation(paused: startedAt == nil)) { timeline in
            Canvas { ctx, _ in
                guard let startedAt else { return }
                let t = timeline.date.timeIntervalSince(startedAt)
                guard t >= 0, t < Self.duration else { return }
                let fade = t < 1.5 ? 1 : max(0, 1 - (t - 1.5) / (Self.duration - 1.5))
                for f in flakes {
                    let x = origin.x + cos(f.angle) * f.speed * t * 0.55 + f.drift * t
                    let y = origin.y + sin(f.angle) * f.speed * t * 0.55 + 220 * t * t
                    var rect = CGRect(x: 0, y: 0, width: f.size, height: f.size * 0.6)
                    rect.origin = CGPoint(x: -rect.width / 2, y: -rect.height / 2)
                    var c = ctx
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(f.spin * t))
                    c.opacity = fade
                    c.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(f.color))
                }
            }
        }
        .onChange(of: trigger) { _, _ in startedAt = Date() }
    }
}

private extension Double {
    var degrees: Double { self * .pi / 180 }
}

#Preview {
    OnboardingHoldView(onContinue: {})
}
