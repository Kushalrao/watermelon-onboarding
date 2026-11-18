import SwiftUI

/// What the three guides share (973:17046): the advisor in her corner saying her piece, the card under her, 364 ×
/// 494 and 181 under the status bar, with its heading, and Continue under it. Each guide lays its own content over
/// this, at `inGuideCard(_:_:top:)` in the card's measure.
private struct OnboardingGuideChrome: View {
    let heading: String
    /// What she says about this guide's widget
    let said: String
    var confirmEnabled = true
    /// Set a second after she's finished saying her piece: the card, what's on it and Continue come up then
    @Binding var cardUp: Bool
    let onConfirm: () -> Void

    @Environment(\.onboardingTop) private var top
    /// Her message has come in
    @State private var saidShown = false

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

            AdvisorAvatar()
                .at(Self.side + 15, 61 - 44 + top)
            // Over the foot of her picture, arriving as the chat's bubbles do
            if saidShown {
                AdvisorBubble(text: said, typed: true) {
                    // Only her first line brings the card; what she says after that finds it there
                    guard !cardUp else { return }
                    Task {
                        try? await Task.sleep(for: .seconds(1))
                        Haptics.tap()
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.84)) { cardUp = true }
                    }
                }
                    .at(Self.side + 35, 104 - 44 + top)
                    .transition(.scale(scale: 0.9, anchor: .bottomLeading).combined(with: .opacity).combined(with: .offset(y: 12)))
                    // A new line is a new bubble: the last one goes and this one comes up and types
                    .id(said)
            }

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
            .guideCardArrival(cardUp)

            OnboardingConfirmButton(enabled: confirmEnabled, action: onConfirm)
                .frame(maxWidth: .infinity)
                .padding(.top, Self.confirmTop(top: top))
                .opacity(cardUp ? 1 : 0)
                .allowsHitTesting(cardUp)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            guard !saidShown else { return }
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            Haptics.thresholdCrossed()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) { saidShown = true }
        }
    }
}

private extension View {
    /// The card and what's on it come up from below together
    func guideCardArrival(_ up: Bool) -> some View {
        offset(y: up ? 0 : 60).opacity(up ? 1 : 0).allowsHitTesting(up)
    }

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

    @State private var cardUp = false
    /// What she's saying: how it's done, then well done, then her answer to a question tapped
    @State private var said = OnboardingHoldGuideView.asks
    private static let asks = "Curious about something you see? Tap and hold a widget and I’ll suggest what to ask."
    private static let congrats = "Congrats, you’ve learnt it! These are questions I’d suggest for this widget."
    private static let later = "I’ll definitely answer this later. For now, let’s continue to the next one."
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
    /// The demonstration, shown when the widget's been left alone for three seconds: a ripple from its middle, the
    /// widget pressing in and waiting there, then springing back out. Counted up at each touch, which starts the wait again
    @State private var hintRun = 0
    @State private var hintScale: CGFloat = 1
    @State private var rippleScale: CGFloat = 0.2
    @State private var rippleOpacity: Double = 0
    @State private var hintDim: Double = 0
    @State private var beats: Task<Void, Never>?
    /// The wait after each tick while the widget's held, each shorter than the last; together they fill the hold
    private static let beatWaits: [TimeInterval] = [0.2, 0.17, 0.145, 0.12, 0.1, 0.085, 0.07, 0.06, 0.05]

    /// How long the widget has to be held
    private static let holdTime: TimeInterval = 1

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
            OnboardingGuideChrome(heading: "Tap & hold the widget\nto get a suggestion", said: said, confirmEnabled: done, cardUp: $cardUp, onConfirm: onContinue)

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
                                    .overlay(
                                        // White light spreading from the touch, soft at its edge. The widget's white,
                                        // so it goes a shade darker as it's pressed, and the light is where that shade
                                        // is lifted off again; nothing's laid over the widget's words
                                        Color.black.opacity(0.07 * hintDim)
                                            .mask {
                                                ZStack {
                                                    Color.black
                                                    Circle()
                                                        .fill(RadialGradient(
                                                            stops: [
                                                                .init(color: Color.black, location: 0),
                                                                .init(color: Color.black.opacity(0.8), location: 0.6),
                                                                .init(color: Color.black.opacity(0), location: 1),
                                                            ],
                                                            center: .center, startRadius: 0, endRadius: 70
                                                        ))
                                                        .frame(width: 140, height: 140)
                                                        .scaleEffect(rippleScale)
                                                        .opacity(rippleOpacity)
                                                        .blendMode(.destinationOut)
                                                }
                                                .compositingGroup()
                                            }
                                        .allowsHitTesting(false)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 23 / Self.scale, style: .continuous))
                                    // Pressed in further the longer it's held; let go early, it springs back out
                                    .scaleEffect((pressing ? 0.95 : 1) * hintScale)
                                    .animation(pressing ? .linear(duration: Self.holdTime) : .spring(response: 0.4, dampingFraction: 0.6), value: pressing)
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
                .onLongPressGesture(minimumDuration: Self.holdTime, maximumDistance: 12) {
                    hold(cardFrame)
                } onPressingChanged: { down in
                    pressing = down
                    if down {
                        Haptics.prepare()
                        // Ticks, with a shorter wait before each, until the hold lands
                        beats = Task {
                            for (i, wait) in Self.beatWaits.enumerated() {
                                Haptics.beat(strength: Double(i) / Double(Self.beatWaits.count - 1))
                                try? await Task.sleep(for: .seconds(wait))
                                if Task.isCancelled { return }
                            }
                        }
                    } else {
                        // Let go, or landed: the ticks stop
                        beats?.cancel()
                    }
                    // A touch ends the demonstration and starts its wait again
                    hintRun += 1
                    rippleOpacity = 0
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        hintScale = 1
                        hintDim = 0
                    }
                }
                .inGuideCard(17.5, 102, top: top)
            }
            .guideCardArrival(cardUp)

            HeldWidgetLayer(
                frame: heldFrame,
                questions: Self.questions,
                progress: holdProgress,
                chipsOut: chipsOut,
                onDismiss: release,
                onQuestion: { _ in
                    guard said != Self.later else { return }
                    Haptics.tap()
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) { said = Self.later }
                }
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
        .task(id: hintRun) { await demonstrate() }
        // The wait before the demonstration starts once the card is there
        .onChange(of: cardUp) { hintRun += 1 }
    }

    /// Shows how it's done, over and over, for as long as the widget is left alone
    private func demonstrate() async {
        guard cardUp else { return }
        do {
            try await Task.sleep(for: .seconds(3))
            while !done, !pressing, heldFrame == nil {
                // The touch: a ripple out from the middle
                rippleScale = 0.2
                rippleOpacity = 1
                try await Task.sleep(for: .seconds(0.03))
                withAnimation(.easeOut(duration: 0.25)) { hintDim = 1 }
                withAnimation(.easeOut(duration: 1)) { rippleScale = 4 }
                withAnimation(.easeIn(duration: 1)) { rippleOpacity = 0 }
                try await Task.sleep(for: .seconds(0.12))
                // pressing in, and held there
                withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) { hintScale = 0.93 }
                try await Task.sleep(for: .seconds(1.3))
                // then let go: back out past its size and settling
                withAnimation(.spring(response: 0.55, dampingFraction: 0.42)) { hintScale = 1 }
                withAnimation(.easeOut(duration: 0.3)) { hintDim = 0 }
                try await Task.sleep(for: .seconds(3))
            }
        } catch {}
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
        beats?.cancel()
        Haptics.landed()
        heldFrame = frame
        confettiOrigin = CGPoint(x: frame.minX + 40, y: frame.maxY + 20)
        holdProgress = 0
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) { holdProgress = 1 }
        DispatchQueue.main.async { chipsOut = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            confettiBurst += 1
            Haptics.tap()
            withAnimation { done = true }
            // and she says so, in a new bubble
            if said == Self.asks {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) { said = Self.congrats }
            }
        }
    }
}

// MARK: - Swipe (832:13341)

/// The swipe guide, as before (777:12973) in the new card: the blue panel is the earlier one at 328 wide. Swiping
/// the widget right attaches it to the composer, which rises above Confirm; Confirm wakes once that's been done.
struct OnboardingSwipeGuideView: View {
    let onContinue: () -> Void

    @Environment(\.onboardingTop) private var top

    @State private var cardUp = false
    @State private var done = false
    @State private var isComposing = false
    @State private var composeProgress: CGFloat = 0
    @State private var text = ""
    @FocusState private var focused: Bool
    @State private var dragX: CGFloat = 0
    @State private var pastThreshold = false
    @State private var dragging = false
    /// How many of the ticks' marks the finger is past
    @State private var beatsPassed = 0
    /// The demonstration, shown when the widget's been left alone for three seconds: it slides right as if
    /// swiped, waits, and springs back. Counted up at each touch, which starts the wait again
    @State private var hintRun = 0
    @State private var hintX: CGFloat = 0

    private static let scale: CGFloat = 328 / 378
    private static let swipeThreshold: CGFloat = 70
    /// Where along the swipe (in the panel's measure) a tick is given: each gap shorter than the last, down to 6,
    /// so they come quicker the further the widget's taken
    private static let beatMarks: [CGFloat] = {
        var marks: [CGFloat] = []
        var x: CGFloat = 8
        var gap: CGFloat = 26
        while x < 320 {
            marks.append(x)
            x += gap
            gap = max(6, gap * 0.82)
        }
        return marks
    }()

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                OnboardingGuideChrome(heading: "Swipe the widget\nto ask your advisor", said: "Have a question of your own? Swipe a widget to the right and ask me about it.", confirmEnabled: done, cardUp: $cardUp, onConfirm: onContinue)

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

                        let lift = min(1, (dragX + hintX) / Self.swipeThreshold)
                        MSFTChartCard()
                            .offset(x: dragX + hintX)
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
                .guideCardArrival(cardUp)

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
        .task(id: hintRun) { await demonstrate() }
        // The wait before the demonstration starts once the card is there
        .onChange(of: cardUp) { hintRun += 1 }
    }

    /// Shows how it's done, over and over, for as long as the widget is left alone
    private func demonstrate() async {
        guard cardUp else { return }
        do {
            try await Task.sleep(for: .seconds(3))
            while !done, !dragging, !isComposing {
                // Out to the right, as a finger would take it
                withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { hintX = 56 }
                try await Task.sleep(for: .seconds(1.1))
                // and let go: back past its place and settling
                withAnimation(.spring(response: 0.55, dampingFraction: 0.42)) { hintX = 0 }
                try await Task.sleep(for: .seconds(3))
            }
        } catch {}
    }

    private func dragChanged(_ dx: CGFloat) {
        if !dragging {
            dragging = true
            Haptics.prepare()
            beatsPassed = 0
            // A touch ends the demonstration
            hintRun += 1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { hintX = 0 }
        }
        // Follows the finger up to the threshold, then eases off; the panel's drawn smaller, so the finger's
        // travel is put back into the panel's own measure
        let x = max(0, dx) / Self.scale
        let over = x - Self.swipeThreshold
        dragX = x <= Self.swipeThreshold ? x : Self.swipeThreshold + (1 - 1 / (over * 0.55 / 90 + 1)) * 90
        // A tick at each mark the finger passes going out; coming back gives none, and re-arms them
        let passed = Self.beatMarks.prefix { $0 <= x }.count
        if passed > beatsPassed {
            Haptics.beat(strength: Double(passed) / Double(Self.beatMarks.count))
        }
        beatsPassed = passed
        let past = x > Self.swipeThreshold
        if past != pastThreshold {
            pastThreshold = past
            Haptics.thresholdCrossed()
        }
    }

    private func dragEnded() {
        let send = pastThreshold
        pastThreshold = false
        dragging = false
        // and its wait starts again from here
        hintRun += 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { dragX = 0 }
        if send { swiped() }
    }

    private func swiped() {
        guard !isComposing else { return }
        Haptics.landed()
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
    @State private var cardUp = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            OnboardingGuideChrome(heading: "What feels comfortable\nto read?", said: "It matters that you understand what I say. Pick the way of reading that feels right.", cardUp: $cardUp, onConfirm: onContinue)

            ComplexityCard(level: level, soft: true)
                .inGuideCard(19, 94, top: top)
                .guideCardArrival(cardUp)

            ComplexitySlider(position: $position, soft: true) { newLevel in
                guard newLevel != level else { return }
                Haptics.tap()
                level = newLevel
            }
            .inGuideCard(20, 406, top: top)
            .guideCardArrival(cardUp)
        }
        .ignoresSafeArea()
    }
}
