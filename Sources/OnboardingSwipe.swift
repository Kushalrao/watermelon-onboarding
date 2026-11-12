import SwiftUI

/// Teaches swipe-right-to-ask. Panel 777:12973 (378 × 392 at 6, 172) on the same shell as the hold screen.
/// Swiping the card attaches it to the composer, which rises bottom-aligned without the keyboard.
struct OnboardingSwipeView: View {
    let onContinue: () -> Void

    @State private var done = false
    @State private var isComposing = false
    @State private var composeProgress: CGFloat = 0
    @State private var text = ""
    @FocusState private var focused: Bool

    private static let panel = CGRect(x: 6, y: 172, width: 378, height: 392)
    private static let swipeThreshold: CGFloat = 70

    @State private var dragX: CGFloat = 0
    @State private var pastThreshold = false

    private func dragChanged(_ dx: CGFloat) {
        if dragX == 0 { Haptics.prepare() }
        // Follows the finger 1:1 up to the threshold, then eases off
        let x = max(0, dx)
        let over = x - Self.swipeThreshold
        dragX = x <= Self.swipeThreshold ? x : Self.swipeThreshold + (1 - 1 / (over * 0.55 / 90 + 1)) * 90
        let past = x > Self.swipeThreshold
        if past != pastThreshold {
            pastThreshold = past
            Haptics.thresholdCrossed()
        }
    }

    private func dragEnded() {
        let send = pastThreshold
        pastThreshold = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { dragX = 0 }
        if send { swiped() }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                OnboardingBackground()

                ZStack(alignment: .topLeading) {
                    Text("Swipe to ask")
                        .font(FigmaFont.walsheimMedium(31))
                        .foregroundStyle(Color.ink)
                        .at(23, 81)

                    DashedRule()
                        .frame(width: 344, height: 2)
                        .at(23, 151)

                    // Blue hint panel (777:12973)
                    ZStack(alignment: .topLeading) {
                        Color(hex: 0xD4F2FA)

                        MarchingChevrons()
                            .frame(width: 101, height: 26)
                            .at(11, 15)

                        Text("Swipe to ask a specific question")
                            .font(FigmaFont.walsheimMedium(15))
                            .foregroundStyle(Color(hex: 0x3A545B))
                            .at(119, 17)

                        let lift = min(1, dragX / Self.swipeThreshold)
                        MSFTChartCard()
                            .offset(x: dragX)
                            .scaleEffect(1 + 0.02 * lift, anchor: .leading)
                            .shadow(color: Color.black.opacity(0.12 * lift), radius: 18, x: 0, y: 8)
                            .at(7, 55)
                    }
                    .frame(width: Self.panel.width, height: Self.panel.height, alignment: .topLeading)
                    // The whole panel listens for the swipe; only the card moves
                    .background(
                        RightSwipeAttach(onChanged: dragChanged, onEnded: { _ in dragEnded() })
                    )
                    .at(Self.panel.minX, Self.panel.minY)

                    OnboardingButton(title: "Continue", enabled: done, action: onContinue)
                        .at(23, 738)
                }
                .frame(width: MutualFundScreen.canvasWidth, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .top)

                ComposerLayer(
                    isFocused: $focused,
                    text: $text,
                    viewport: geo.size,
                    keyboardHeight: 0,
                    isComposing: isComposing,
                    context: .msftChart,
                    bottomAligned: true,
                    floatAbove: 738,   // top of the Continue button
                    onOpen: {},
                    onClose: close
                )
            }
            .modifier(AnimatedComposeProgress(progress: composeProgress))
        }
        .ignoresSafeArea()
        .onAppear {
            // `-swipeDemo`: opens the composer as if the card had been swiped
            if ProcessInfo.processInfo.arguments.contains("-swipeDemo") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { swiped() }
            }
        }
    }

    private func swiped() {
        guard !isComposing else { return }
        Haptics.tap()
        isComposing = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { composeProgress = 1 }
        withAnimation { done = true }
    }

    private func close() {
        guard isComposing else { return }
        Haptics.settle()
        isComposing = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { composeProgress = 0 }
    }
}

/// Frame 2330: six chevrons that keep marching right, new ones entering from the left
private struct MarchingChevrons: View {
    private static let spacing: CGFloat = 16   // chevrons sit 16pt apart in the Figma SVG
    private static let speed: CGFloat = 22     // pt per second

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let shift = CGFloat(t).truncatingRemainder(dividingBy: Self.spacing / Self.speed) * Self.speed
            Canvas { ctx, size in
                for i in -1...6 {
                    let x = 6.7 + CGFloat(i) * Self.spacing + shift
                    ctx.translateBy(x: x, y: 0)
                    ctx.fill(Self.chevron, with: .color(Color(hex: 0x3A545B)))
                    ctx.translateBy(x: -x, y: 0)
                }
            }
            // Soft fade at both ends so chevrons appear and disappear smoothly
            .mask(
                LinearGradient(
                    stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.15),
                            .init(color: .black, location: 0.85), .init(color: .clear, location: 1)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
        }
    }

    /// One chevron from the SVG, origin at its left edge (x 6.7 … 13.86, y 6.8 … 19.2)
    private static let chevron: Path = {
        var p = Path()
        p.move(to: CGPoint(x: 7.16, y: 12.998))
        p.addLine(to: CGPoint(x: 2.36, y: 8.325))
        p.addQuadCurve(to: CGPoint(x: 2.36, y: 7.065), control: CGPoint(x: 1.75, y: 7.69))
        p.addQuadCurve(to: CGPoint(x: 3.5, y: 7.065), control: CGPoint(x: 2.93, y: 6.5))
        p.addLine(to: CGPoint(x: 8.86, y: 12.31))
        p.addQuadCurve(to: CGPoint(x: 8.86, y: 13.686), control: CGPoint(x: 9.55, y: 12.998))
        p.addLine(to: CGPoint(x: 3.5, y: 18.93))
        p.addQuadCurve(to: CGPoint(x: 2.36, y: 18.93), control: CGPoint(x: 2.93, y: 19.5))
        p.addQuadCurve(to: CGPoint(x: 2.36, y: 17.67), control: CGPoint(x: 1.75, y: 18.31))
        p.closeSubpath()
        return p.offsetBy(dx: -2, dy: 0)
    }()
}

/// MSFT card with the price chart (777:12974), 364 × 330
struct MSFTChartCard: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            // Header row (777:12994)
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

            Rectangle().fill(Color.black.opacity(0.09)).frame(width: 364, height: 1).at(0, 73)

            // Chart area (783:13046), 364 × 251 at y 79 — the chart image starts 71pt above and is clipped
            ZStack(alignment: .topLeading) {
                Color.white

                Image("MSFTChart")
                    .resizable()
                    .frame(width: 296, height: 242)
                    .at(14, -71)

                HStack(spacing: 0) {
                    axis("12"); Spacer(minLength: 0); axis("13"); Spacer(minLength: 0)
                    axis("15"); Spacer(minLength: 0); axis("19")
                }
                .frame(width: 254)
                .at(47, 186)

                price("¢900").at(319, 42)
                price("¢100").at(321, 162)

                PeriodSelector().at(13, 211)
            }
            .frame(width: 364, height: 251, alignment: .topLeading)
            .clipped()
            .at(0, 79)
        }
        .frame(width: 364, height: 330)
        .clipped()
        .overlay(Rectangle().stroke(Color.black.opacity(0.04), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 7.5, x: 0, y: 3)
    }

    private func axis(_ s: String) -> some View {
        Text(s)
            .font(FigmaFont.walsheim(12))
            .tracking(0.84)
            .foregroundStyle(Color.black.opacity(0.6))
    }

    private func price(_ s: String) -> some View {
        Text(s)
            .font(FigmaFont.walsheim(12))
            .tracking(0.84)
            .foregroundStyle(Color.black.opacity(0.4))
    }
}

#Preview {
    OnboardingSwipeView(onContinue: {})
}
