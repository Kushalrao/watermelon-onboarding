import SwiftUI

/// What the three guides share (973:17046): the advisor in her corner saying her piece, the card under her, 364 ×
/// 494 and 181 under the status bar, with its heading, and Continue under it. Each guide lays its own content over
/// this, at `inGuideCard(_:_:top:)` in the card's measure.
private struct OnboardingGuideChrome: View {
    let heading: String
    var confirmEnabled = true
    let onConfirm: () -> Void

    @Environment(\.onboardingTop) private var top

    /// The same line on all three frames
    static let said = "Great, now you understanding what i say is important. Select what feels right to you"
    private static var side: CGFloat { (UIScreen.main.bounds.width - 390) / 2 }

    /// Where the card's corner is, for content laid over it
    static func cardOrigin(top: CGFloat) -> CGPoint {
        CGPoint(x: side + 13, y: 225 - 44 + top)
    }
    static func confirmTop(top: CGFloat) -> CGFloat { 738 - 44 + top }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        ZStack(alignment: .topLeading) {
            AdvisorDawnBackground()

            AdvisorBubble(text: Self.said)
                .at(Self.side + 35, 104 - 44 + top)
            AdvisorAvatar()
                .at(Self.side + 15, 61 - 44 + top)

            ZStack(alignment: .topLeading) {
                Color.white
                    .clipShape(shape)
                    .shadow(color: Color.black.opacity(0.07), radius: 48.5, x: 0, y: 4) // Shadow/2: 0 4 97 +7 at 7%; the spread is not drawn

                DsText(heading, variant: .h4)
                    .frame(width: 280, alignment: .leading)
                    .at(19, 23)
            }
            .frame(width: 364, height: 494, alignment: .topLeading)
            .at(Self.cardOrigin(top: top).x, Self.cardOrigin(top: top).y)

            OnboardingConfirmButton(enabled: confirmEnabled, action: onConfirm)
                .frame(maxWidth: .infinity)
                .padding(.top, Self.confirmTop(top: top))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private extension View {
    /// Placed in the guides' card, in the card's own measure
    func inGuideCard(_ x: CGFloat, _ y: CGFloat, top: CGFloat) -> some View {
        let origin = OnboardingGuideChrome.cardOrigin(top: top)
        return at(origin.x + x, origin.y + y)
    }
}

/// Continue (973:17053): 344 × 49, the label centred
struct OnboardingConfirmButton: View {
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Continue")
                .font(FigmaFont.walsheimMedium(17))
                .foregroundStyle(Color.white)
                .offset(x: 0.5)
                .frame(width: 344, height: 49)
                .background(Capsule().fill(Color(hex: 0x1F1513)))
                .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
        }
        .buttonStyle(PressScaleStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
        .animation(.easeInOut(duration: 0.3), value: enabled)
    }
}

// MARK: - Tap & hold (832:12968)

/// The hold guide, as before (771:12568) in the new card (973:17264): the panel is the earlier one at 329 wide. Holding
/// it lifts the widget and brings its questions out; Confirm wakes once that's been done.
struct OnboardingHoldGuideView: View {
    let onContinue: () -> Void

    @Environment(\.onboardingTop) private var top

    @State private var heldFrame: CGRect?
    @State private var cardFrame: CGRect = .zero
    @State private var pressing = false
    @State private var holdProgress: CGFloat = 0
    @State private var chipsOut = false
    @State private var done = false
    @State private var confettiBurst = 0
    /// Where the confetti starts: the lifted widget's lower left, fixed when it's lifted. The widget's frame is
    /// only read when the hold lands, never while the screen's being drawn
    @State private var confettiOrigin: CGPoint = .zero

    /// The earlier panel is 378 × 392 with a 364 × 330 widget; the frame has it at 329 × 341.185
    private static let scale: CGFloat = 329 / 378
    private static let questions = ["Explain me the terms", "Why is the ratio so high?"]

    private var widget: some View {
        ResearchCard()
            .scaleEffect(Self.scale)
            .frame(width: 364 * Self.scale, height: 330 * Self.scale)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            OnboardingGuideChrome(heading: "Tap & hold the widget\nto get a suggestion", confirmEnabled: done, onConfirm: onContinue)

            Group {
                ZStack(alignment: .topLeading) {
                    // 973:17483: the page's own colour, rounded 23 (in the panel's own measure) with a hairline
                    RoundedRectangle(cornerRadius: 23 / Self.scale, style: .continuous)
                        .fill(ColorScale.surfaceBase)
                        .overlay(RoundedRectangle(cornerRadius: 23 / Self.scale, style: .continuous).strokeBorder(Color.black.opacity(0.05), lineWidth: 1 / Self.scale))

                    BlinkingCircle(blinking: !done)
                        .at(16, 13)

                    Text("Tap & hold me to view suggested questions")
                        .font(FigmaFont.walsheimMedium(15))
                        .foregroundStyle(Color(hex: 0x797419))
                        .at(56, 17)

                    // The widget's place; empty while it's lifted out
                    Color.clear
                        .frame(width: 364, height: 330)
                        .overlay {
                            if heldFrame == nil {
                                ResearchCard()
                                    // 973:17484: the widget's rounded 23 now
                                    .clipShape(RoundedRectangle(cornerRadius: 23 / Self.scale, style: .continuous))
                                    .scaleEffect(pressing ? 1.015 : 1)
                                    .animation(.easeOut(duration: 0.25), value: pressing)
                            }
                        }
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cardFrame = $0 }
                        .at(7, 55)
                }
                .frame(width: 378, height: 392, alignment: .topLeading)
                .scaleEffect(Self.scale, anchor: .topLeading)
                .frame(width: 329, height: 341.185, alignment: .topLeading)
                // The whole panel listens for the hold; only the widget reacts
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0.45, maximumDistance: 12) {
                    hold(cardFrame)
                } onPressingChanged: { down in
                    pressing = down
                    if down { Haptics.prepare() }
                }
                .inGuideCard(17.5, 102, top: top)
            }

            HeldWidgetLayer(
                frame: heldFrame,
                questions: Self.questions,
                progress: holdProgress,
                chipsOut: chipsOut,
                onDismiss: release
            ) { widget }

            // Above the held layer, so it can be tapped while the widget's lifted
            if heldFrame != nil {
                OnboardingConfirmButton(enabled: done, action: onContinue)
                    .frame(maxWidth: .infinity)
                    .padding(.top, OnboardingGuideChrome.confirmTop(top: top))
            }

            ConfettiBurst(trigger: confettiBurst, origin: confettiOrigin)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    /// A tap outside the lifted widget puts it back (Confirm stays awake once the hold's been done)
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
        confettiOrigin = CGPoint(x: frame.minX + 40, y: frame.maxY + 20)
        holdProgress = 0
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) { holdProgress = 1 }
        DispatchQueue.main.async { chipsOut = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            confettiBurst += 1
            Haptics.tap()
            withAnimation { done = true }
        }
    }
}

// MARK: - Swipe (832:13341)

/// The swipe guide, as before (777:12973) in the new card: the blue panel is the earlier one at 328 wide. Swiping
/// the widget right attaches it to the composer, which rises above Confirm; Confirm wakes once that's been done.
struct OnboardingSwipeGuideView: View {
    let onContinue: () -> Void

    @Environment(\.onboardingTop) private var top

    @State private var done = false
    @State private var isComposing = false
    @State private var composeProgress: CGFloat = 0
    @State private var text = ""
    @FocusState private var focused: Bool
    @State private var dragX: CGFloat = 0
    @State private var pastThreshold = false

    private static let scale: CGFloat = 328 / 378
    private static let swipeThreshold: CGFloat = 70

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                OnboardingGuideChrome(heading: "Swipe the widget\nto ask your advisor", confirmEnabled: done, onConfirm: onContinue)

                Group {
                    ZStack(alignment: .topLeading) {
                        // 973:17694: the page's own colour, rounded 23 (in the panel's own measure) with a hairline
                        RoundedRectangle(cornerRadius: 23 / Self.scale, style: .continuous)
                            .fill(ColorScale.surfaceBase)
                            .overlay(RoundedRectangle(cornerRadius: 23 / Self.scale, style: .continuous).strokeBorder(Color.black.opacity(0.05), lineWidth: 1 / Self.scale))

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
                    .frame(width: 378, height: 392, alignment: .topLeading)
                    .scaleEffect(Self.scale, anchor: .topLeading)
                    .frame(width: 328, height: 340.148, alignment: .topLeading)
                    // The whole panel listens for the swipe; only the widget moves
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { dragChanged($0.translation.width) }
                            .onEnded { _ in dragEnded() }
                    )
                    .inGuideCard(18, 102, top: top)
                }

                ComposerLayer(
                    isFocused: $focused,
                    text: $text,
                    viewport: geo.size,
                    keyboardHeight: 0,
                    isComposing: isComposing,
                    context: .msftChart,
                    bottomAligned: true,
                    floatAbove: OnboardingGuideChrome.confirmTop(top: top),
                    onOpen: {},
                    onClose: close
                )

                // Above the composer's scrim, so the journey can move on with it open
                if isComposing {
                    OnboardingConfirmButton(enabled: done, action: onContinue)
                        .frame(maxWidth: .infinity)
                        .padding(.top, OnboardingGuideChrome.confirmTop(top: top))
                }
            }
            .modifier(AnimatedComposeProgress(progress: composeProgress))
        }
        .ignoresSafeArea()
    }

    private func dragChanged(_ dx: CGFloat) {
        if dragX == 0 { Haptics.prepare() }
        // Follows the finger up to the threshold, then eases off; the panel's drawn smaller, so the finger's
        // travel is put back into the panel's own measure
        let x = max(0, dx) / Self.scale
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

// MARK: - What feels comfortable to read (832:13535)

/// The reading-level guide, as before (792:13117) in the new card: the slider from SIMPLY through ANY to TERMS
/// rewrites the widget from plain language to shorthand.
struct OnboardingComplexityGuideView: View {
    let onContinue: () -> Void

    @Environment(\.onboardingTop) private var top

    @State private var position: CGFloat = 0
    @State private var level: ComplexityLevel = .simply

    var body: some View {
        ZStack(alignment: .topLeading) {
            OnboardingGuideChrome(heading: "What feels comfortable\nto read?", onConfirm: onContinue)

            ComplexityCard(level: level, soft: true)
                .inGuideCard(19, 94, top: top)

            ComplexitySlider(position: $position, soft: true) { newLevel in
                guard newLevel != level else { return }
                Haptics.tap()
                level = newLevel
            }
            .inGuideCard(20, 406, top: top)
        }
        .ignoresSafeArea()
    }
}
