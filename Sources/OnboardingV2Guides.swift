import SwiftUI

// The second onboarding's two gestures, on the phone its opening draws (1249:2716, 1251:6920). They are the first
// onboarding's hold and swipe guides (`OnboardingHoldGuideView`, `OnboardingSwipeGuideView`) with the same hold,
// lift, questions, confetti, swipe, composer, ticks and demonstrations; here the widget sits on the phone's screen,
// with nothing said about it and no panel around it. Each fills the page, so what lifts out of the phone, or rises
// over it, has the whole screen.

/// Tap and hold (1249:2716): the holding's card, 292 × 269 on the phone. Held for a second it lifts out and its
/// questions come out under it; a tap anywhere else puts it back.
struct OnboardingV2HoldWidget: View {
    /// Where the widget's top left sits on the screen
    let origin: CGPoint
    /// It's time to go on: lifted out, it's put back in its place first
    var leaving = false
    /// Told once it's back in its place after that (at once, if it was there already)
    var onSettled: () -> Void = {}
    /// Told once the hold has been done
    let onDone: () -> Void

    @State private var heldFrame: CGRect?
    @State private var cardFrame: CGRect = .zero
    @State private var pressing = false
    @State private var holdProgress: CGFloat = 0
    @State private var chipsOut = false
    @State private var done = false
    @State private var confettiBurst = 0
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
    private static let holdTime: TimeInterval = 1
    private static let size = CGSize(width: 292, height: 269)
    private static let questions = ["Explain me the terms", "Why is the ratio so high?"]

    /// 1251:6862: the holding in plain words, as the reading-level card has it, at the phone's 292
    private var widget: some View {
        ComplexityCard(level: .simply, soft: true, width: Self.size.width)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 23, style: .continuous)
        return ZStack(alignment: .topLeading) {
            // The widget's place; empty while it's lifted out
            Color.clear
                .frame(width: Self.size.width, height: Self.size.height)
                .overlay {
                    if heldFrame == nil {
                        widget
                            .overlay(
                                // It goes a shade darker as it's pressed, and the light spreading from the touch is
                                // where that shade is lifted off again
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
                                    .clipShape(shape)
                                    .allowsHitTesting(false)
                            )
                            // Pressed in further the longer it's held; let go early, it springs back out
                            .scaleEffect((pressing ? 0.95 : 1) * hintScale)
                            .animation(pressing ? .linear(duration: Self.holdTime) : .spring(response: 0.4, dampingFraction: 0.6), value: pressing)
                    }
                }
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { cardFrame = $0 }
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
                .accessibilityElement(children: .combine)
                .accessibilityHint("Touch and hold for questions to ask")
                .at(origin.x, origin.y)

            HeldWidgetLayer(
                frame: heldFrame,
                questions: Self.questions,
                progress: holdProgress,
                chipsOut: chipsOut,
                onDismiss: { release() }
            ) { widget }

            ConfettiBurst(trigger: confettiBurst, origin: confettiOrigin)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(!leaving)
        .task(id: hintRun) { await demonstrate() }
        .onChange(of: leaving) { _, leaving in
            if leaving { release(then: onSettled) }
        }
    }

    /// Shows how it's done, over and over, for as long as the widget is left alone
    private func demonstrate() async {
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

    /// A tap outside the lifted widget puts it back, and so does going on; `settled` once it's there
    private func release(then settled: @escaping () -> Void = {}) {
        guard heldFrame != nil else { return settled() }
        Haptics.settle()
        chipsOut = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            holdProgress = 0
        } completion: {
            heldFrame = nil
        }
        // told as soon as it looks back in its place: the spring calls itself done a good while after that
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { settled() }
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
            guard !done else { return }
            confettiBurst += 1
            Haptics.tap()
            done = true
            onDone()
        }
    }
}

/// Swipe (1251:6920): the price chart's card, 292 × 264.725 on the phone (the chart card at 292 of its 364). Swiped
/// right it's attached to the composer, which opens on the phone's own screen, at the phone's scale, over the
/// phone's keyboard (the one under the pill earlier, `OnboardingV2Keyboard`), which comes up with it. Nothing is
/// typed there; its cross, or a tap above it, closes it. The widget comes up to its place from `rise` below it,
/// and on the way isn't drawn below `cutBelow`, the phone's foot.
struct OnboardingV2SwipeWidget: View {
    /// Where the widget's top left sits on the screen
    let origin: CGPoint
    /// The phone's screen on the page, as much of it as shows
    let screen: CGRect
    /// How far below its place it starts from
    var rise: CGFloat = 0
    /// Down the screen, where it's cut off
    var cutBelow: CGFloat? = nil
    /// Told once the swipe has been done
    let onDone: () -> Void

    @State private var done = false
    /// It has come up to its place, or is on its way
    @State private var arrived = false
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

    private static let scale: CGFloat = 292.0 / 364
    private static let swipeThreshold: CGFloat = 70
    /// The composer is laid out on the app's 390 and drawn at the phone screen's 312
    private static let composerScale: CGFloat = 312.0 / 390
    /// The keyboard's place on the phone's screen: where it is under the pill (11, 401 on what's 15 in; the screen is 12 in)
    private static let keyboardAt = CGPoint(x: 14, y: 404)
    /// Where along the swipe (in the widget's own measure) a tick is given: each gap shorter than the last, down
    /// to 6, so they come quicker the further the widget's taken
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
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                let lift = min(1, (dragX + hintX) / Self.swipeThreshold)
                MSFTChartCard()
                    // 1251:7050: rounded 23 on the phone, so 23 at its scale
                    .clipShape(RoundedRectangle(cornerRadius: 23 / Self.scale, style: .continuous))
                    .offset(x: dragX + hintX)
                    .scaleEffect(1 + 0.02 * lift, anchor: .leading)
                    .shadow(color: Color.black.opacity(0.12 * lift), radius: 18, x: 0, y: 8)
                    .frame(width: 364, height: 330, alignment: .topLeading)
                    .scaleEffect(Self.scale, anchor: .topLeading)
                    .frame(width: 292, height: 264.725, alignment: .topLeading)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { dragChanged($0.translation.width) }
                            .onEnded { _ in dragEnded() }
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("Swipe right to ask about it")
                    .offset(y: arrived ? 0 : rise)
                    .at(origin.x, origin.y)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .mask(alignment: .top) { Rectangle().frame(maxHeight: cutBelow ?? .infinity) }

                composer
                    .frame(width: screen.width, height: screen.height, alignment: .topLeading)
                    // the screen's own corners, and the phone's foot
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 49, topTrailingRadius: 49, style: .continuous))
                    .at(screen.minX, screen.minY)
            }
            .modifier(AnimatedComposeProgress(progress: composeProgress))
        }
        .task(id: hintRun) { await demonstrate() }
        // as the page moves (the second onboarding's own spring)
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.84)) { arrived = true } }
    }

    /// The composer on the phone's screen, in the screen's own measure: the app's, with its shade, drawn at the
    /// phone's scale so that its card rests the app's 17 above the phone's keyboard; and that keyboard, which
    /// comes up from the foot as the composer opens
    private var composer: some View {
        // (the composer sits 14 above what it's told to float over, and the keyboard's top is 3 below that)
        let keyboardTop = Self.keyboardAt.y / Self.composerScale
        return ZStack(alignment: .topLeading) {
            ComposerLayer(
                isFocused: $focused,
                text: $text,
                viewport: CGSize(width: 390, height: screen.height / Self.composerScale),
                keyboardHeight: 0,
                isComposing: isComposing,
                context: .msftChart,
                bottomAligned: true,
                floatAbove: keyboardTop - 3,
                onOpen: {},
                onClose: close
            )
            .scaleEffect(Self.composerScale, anchor: .topLeading)
            .frame(width: screen.width, height: screen.height, alignment: .topLeading)

            // It's a picture of typing: the field isn't typed in, and the device's keyboard stays down. The card
            // from under its cross to its foot (368 × 323, 11 across, its foot 17 above the keyboard)
            Color.clear
                .contentShape(Rectangle())
                .frame(width: 368 * Self.composerScale, height: (323 - 60) * Self.composerScale)
                .at(11 * Self.composerScale, (keyboardTop - 17 - 323 + 60) * Self.composerScale)
                .allowsHitTesting(isComposing)

            // The app's keyboard covers the page from the shade's foot down; the phone's is narrower and round
            // at the corners, so the shade goes on behind it, as deep as it is at its foot, to the phone's own
            Color.black.opacity(0.18 * composeProgress)
                .frame(width: screen.width, height: max(0, screen.height - Self.keyboardAt.y))
                .contentShape(Rectangle())
                .onTapGesture(perform: close)
                .allowsHitTesting(isComposing)
                .at(0, Self.keyboardAt.y)

            OnboardingV2Keyboard()
                // (and a tap on it isn't one on the shade behind)
                .contentShape(Rectangle())
                .onTapGesture {}
                .offset(y: (1 - composeProgress) * 240)
                .at(Self.keyboardAt.x, Self.keyboardAt.y)
        }
    }

    /// Shows how it's done, over and over, for as long as the widget is left alone
    private func demonstrate() async {
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
        // Follows the finger up to the threshold, then eases off; the widget's drawn smaller, so the finger's
        // travel is put back into its own measure
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
        if !done {
            done = true
            onDone()
        }
    }

    private func close() {
        guard isComposing else { return }
        Haptics.settle()
        isComposing = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { composeProgress = 0 }
    }
}

/// After the swipe: the reading-level card and its slider, as the first onboarding has them (792:13117,
/// `ComplexityCard`, `ComplexitySlider`), at the phone's 292. The slider is moved from BEGINNER through FAMILIAR
/// to PRO and the card is rewritten for each as it is there, the heat going across it. It comes up to its place
/// from `rise` below it, and on the way isn't drawn below `cutBelow`, the phone's foot. Nothing has to be done
/// with it: the frame has its own Continue.
struct OnboardingV2LevelsWidget: View {
    /// Where the card's top left sits on the screen
    let origin: CGPoint
    /// How far below its place it starts from
    var rise: CGFloat = 0
    /// Down the screen, where it's cut off
    var cutBelow: CGFloat? = nil

    @State private var level = ComplexityLevel.simply
    @State private var position: CGFloat = 0
    /// It has come up to its place, or is on its way
    @State private var arrived = false

    /// The slider's 325 at the card's 292
    private static let sliderScale: CGFloat = 292.0 / 325
    /// The card is laid out at its own 326, which every level's words are set for, and drawn at 292
    private static let cardScale: CGFloat = 292.0 / 326

    var body: some View {
        ZStack(alignment: .topLeading) {
            ComplexityCard(level: level, soft: true, quick: true)
                .frame(width: 326, height: 269, alignment: .topLeading)
                .scaleEffect(Self.cardScale, anchor: .topLeading)
                .frame(width: 292, height: 269, alignment: .topLeading)
            // Under the card at its tallest; it stays there as the card shortens
            ComplexitySlider(position: $position, onLevel: { new in
                guard new != level else { return }
                Haptics.tap()
                level = new
            }, soft: true)
            .scaleEffect(Self.sliderScale, anchor: .topLeading)
            .frame(width: 292, height: 61 * Self.sliderScale, alignment: .topLeading)
            .at(0, 269 * Self.cardScale + 22)
        }
        .frame(width: 292, height: 269 * Self.cardScale + 22 + 61 * Self.sliderScale, alignment: .topLeading)
        .offset(y: arrived ? 0 : rise)
        .at(origin.x, origin.y)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .mask(alignment: .top) { Rectangle().frame(maxHeight: cutBelow ?? .infinity) }
        // as the page moves (the second onboarding's own spring)
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.84)) { arrived = true } }
    }
}
