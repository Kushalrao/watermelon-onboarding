import SwiftUI

/// How the fund page turns into the summary card at the top of the chat.
enum TransitionStyle: String, CaseIterable, Identifiable {
    /// The header card morphs into the summary card while the page fades away beneath it.
    case morph
    /// The whole page shrinks into the summary card; pulling the card down expands it back into the page.
    case collapse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morph: "Morph header"
        case .collapse: "Collapse page"
        }
    }
}

/// Hosts the fund page (700:6963) and the chat state (700:7314) and drives the transition between them.
///
/// `progress` runs 0 → 1 (page → chat). Scrolling 200pt past the XIRR card collapses the page into the
/// summary card at the top; pulling that card down expands it back into the page.
struct FundExperienceView: View {
    @AppStorage("transitionStyle") private var style: TransitionStyle = .collapse

    @State private var progress: CGFloat = 0
    @State private var isCollapsed = false
    @State private var isAnimating = false
    @State private var pastExpandThreshold = false
    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var scrollOffset: CGFloat = 0
    /// Chat bubbles pop in one by one once the widget has landed
    @State private var chatRevealed = false
    /// Floating tab selection; Market and For you slide between each other
    @State private var tab: FundTab = .market

    // Long-pressed widget lifted out with question chips (753:12431)
    @State private var heldWidget: HeldWidget?
    @State private var holdProgress: CGFloat = 0
    /// Flipped one frame after the lift starts so the chips animate out from the widget's corner
    @State private var holdChipsOut = false
    private static let holdTransition = Animation.spring(response: 0.45, dampingFraction: 0.78)

    // "Ask anything" pill ↔ composer card (717:10766)
    @State private var isComposing = false
    @State private var composeProgress: CGFloat = 0
    @State private var composerText = ""
    @State private var composerContext: FundContext?
    @FocusState private var composerFocused: Bool
    @StateObject private var keyboard = KeyboardObserver()
    private static let composeTransition = Animation.spring(response: 0.5, dampingFraction: 0.86)

    private static let collapseTriggerDistance: CGFloat = 200
    private static let expandDragDistance: CGFloat = 260
    private static let expandReleaseDistance: CGFloat = 90
    private static let transition = Animation.spring(response: 0.5, dampingFraction: 0.86)
    /// Slower, so each section can be seen arriving at (or leaving) the widget
    private static let gatherTransition = Animation.spring(response: 1.1, dampingFraction: 0.92)

    // Summary card frame (700:7459)
    static let cardRect = CGRect(x: 13, y: 59, width: 364, height: 150)
    static let cardRadius: CGFloat = 31

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // #FCFCFC on the page, white in the chat state
                Color.screenBackground
                    .overlay(Color.white.opacity(progress))

                switch style {
                case .morph:
                    MorphLayers(isCollapsed: isCollapsed, chatRevealed: chatRevealed) { page(viewport: geo.size) }
                case .collapse:
                    CollapseLayers(
                        isCollapsed: isCollapsed,
                        chatRevealed: chatRevealed,
                        collapsing: isCollapsed && isAnimating,
                        scrollOffset: scrollOffset,
                        viewport: geo.size,
                        scrollPosition: $scrollPosition,
                        tab: tab,
                        onScroll: { offset in scrubCollapse(offset: offset, viewportHeight: geo.size.height) },
                        onContext: { openComposer(with: $0) },
                        heldContext: heldWidget?.context,
                        onHold: holdWidget,
                        expandGesture: expandGesture
                    )
                }

                // Floating tabs under the pill (881:13713); the pill itself is drawn by `ComposerLayer`
                FloatingTabs(tab: $tab)
                    .at(11, FloatingTabs.top(viewportHeight: geo.size.height))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                if style == .morph {
                    MorphingCard(collapsing: isCollapsed && isAnimating)
                        .gesture(expandGesture)
                }

                ComposerLayer(
                    isFocused: $composerFocused,
                    text: $composerText,
                    viewport: geo.size,
                    keyboardHeight: keyboard.height,
                    isComposing: isComposing,
                    context: composerContext,
                    onOpen: { openComposer() },
                    onClose: closeComposer
                )

                // Above everything: while a widget is held, a tap anywhere else puts it back
                HeldWidgetLayer(
                    frame: heldWidget?.frame,
                    questions: heldWidget?.context.questions ?? [],
                    progress: holdProgress,
                    chipsOut: holdChipsOut,
                    onDismiss: releaseWidget
                ) { heldWidget?.context.widget }
            }
            // `progress` is the value SwiftUI animates; every layer reads the in-flight value from the
            // environment, so the staggered choreography below runs during animations, not just drags.
            .modifier(AnimatedProgress(progress: progress))
            .modifier(AnimatedComposeProgress(progress: composeProgress))
        }
        .ignoresSafeArea()
        .onAppear(perform: applyDebugState)
        .onChange(of: composerFocused) { _, focused in
            // Keyboard dismissed some other way (e.g. swipe) — fold the card back into the bar
            if !focused && isComposing { closeComposer() }
        }
    }

    // MARK: Held widget

    private func holdWidget(_ context: FundContext, frame: CGRect) {
        guard heldWidget == nil, !isComposing else { return }
        Haptics.lift()
        heldWidget = HeldWidget(context: context, frame: frame)
        holdProgress = 0
        holdChipsOut = false
        withAnimation(Self.holdTransition) { holdProgress = 1 }
        DispatchQueue.main.async { holdChipsOut = true }
    }

    private func releaseWidget() {
        guard heldWidget != nil else { return }
        Haptics.settle()
        holdChipsOut = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            holdProgress = 0
        } completion: {
            heldWidget = nil
        }
    }

    // MARK: Composer

    private func openComposer(with context: FundContext? = nil) {
        guard !isComposing else { return }
        Haptics.tap()
        composerContext = context
        isComposing = true
        composerFocused = true
        withAnimation(Self.composeTransition) { composeProgress = 1 }
    }

    private func closeComposer() {
        guard isComposing else { return }
        Haptics.settle()
        isComposing = false
        composerFocused = false
        withAnimation(Self.composeTransition) { composeProgress = 0 }
        // Drop the attached context once the card has folded back into the bar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !isComposing { composerContext = nil }
        }
    }

    private func page(viewport: CGSize) -> some View {
        TabPages(tab: tab, width: viewport.width, onContext: { openComposer(with: $0) }, heldContext: heldWidget?.context, onHold: holdWidget) {
            MutualFundScreen(
                scrollPosition: $scrollPosition,
                onScrollOffsetChange: { offset in handleScroll(offset: offset, viewportHeight: viewport.height) },
                onContext: { openComposer(with: $0) },
                heldContext: heldWidget?.context,
                onHold: holdWidget
            )
        }
    }

    /// Scroll offset at which the last section is fully visible above the floating chat + tabs.
    private func xirrInViewOffset(viewportHeight: CGFloat) -> CGFloat {
        MutualFundScreen.contentBottom - FloatingTabs.pillTop(viewportHeight: viewportHeight)
    }

    // MARK: Morph style — collapse once scrolled 200pt past XIRR

    private func handleScroll(offset: CGFloat, viewportHeight: CGFloat) {
        guard !isCollapsed, !isAnimating else { return }
        if offset > xirrInViewOffset(viewportHeight: viewportHeight) + Self.collapseTriggerDistance {
            collapse()
        }
    }

    private func collapse(animation: Animation = FundExperienceView.transition) {
        isCollapsed = true
        isAnimating = true
        Haptics.collapse()
        // Bubbles start arriving as the widget settles into place
        let revealDelay = style == .collapse ? 0.75 : 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay) {
            if isCollapsed { chatRevealed = true }
        }
        withAnimation(animation) {
            progress = 1
        } completion: {
            isAnimating = false
            // Page is hidden now; put it back at the top for when it is expanded again
            scrollPosition.scrollTo(edge: .top)
            scrollOffset = 0
        }
    }

    // MARK: Collapse style — same trigger; the sections then visibly gather into the widget

    private func scrubCollapse(offset: CGFloat, viewportHeight: CGFloat) {
        guard !isCollapsed, !isAnimating else { return }
        // Remember where the page is so the sections can aim at the widget's on-screen spot
        scrollOffset = offset
        if offset > xirrInViewOffset(viewportHeight: viewportHeight) + Self.collapseTriggerDistance {
            collapse(animation: Self.gatherTransition)
        }
    }

    // MARK: Expand (pull the summary card down)

    private var expandGesture: AnyGesture<DragGesture.Value> {
        AnyGesture(DragGesture(minimumDistance: 4, coordinateSpace: .global)
            .onChanged { value in
                guard isCollapsed, !isAnimating else { return }
                if progress == 1 { Haptics.prepare() }
                let pull = max(0, value.translation.height)
                progress = 1 - min(1, Self.rubberBand(pull) / Self.expandDragDistance)

                let past = pull > Self.expandReleaseDistance
                if past != pastExpandThreshold {
                    pastExpandThreshold = past
                    Haptics.thresholdCrossed()
                }
            }
            .onEnded { value in
                guard isCollapsed, !isAnimating else { return }
                pastExpandThreshold = false
                let pull = value.translation.height
                let projected = value.predictedEndTranslation.height
                if pull > Self.expandReleaseDistance || projected > 220 {
                    expand()
                } else {
                    Haptics.settle()
                    withAnimation(Self.transition) { progress = 1 }
                }
            })
    }

    private func expand() {
        isAnimating = true
        Haptics.expand()
        chatRevealed = false
        withAnimation(style == .collapse ? Self.gatherTransition : Self.transition) {
            progress = 0
        } completion: {
            isCollapsed = false
            isAnimating = false
        }
    }

    /// UIScrollView-style rubber banding so the pull eases off the further it goes.
    private static func rubberBand(_ x: CGFloat, limit: CGFloat = 320) -> CGFloat {
        (1 - (1 / ((x * 0.55 / limit) + 1))) * limit
    }

    /// Launch arguments `-progress 0...1` and `-style morph|collapse` — fixed states for simulator screenshots.
    private func applyDebugState() {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-style"), i + 1 < args.count, let s = TransitionStyle(rawValue: args[i + 1]) {
            style = s
        }
        if let i = args.firstIndex(of: "-progress"), i + 1 < args.count, let p = Double(args[i + 1]) {
            progress = CGFloat(min(max(p, 0), 1))
            isCollapsed = progress >= 0.5
            chatRevealed = isCollapsed
        }
        // `-compose`: opens the composer a second after launch
        // `-forYou`: switches to the For you tab a second after launch
        if args.contains("-forYou") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { tab = .forYou }
        }
        if args.contains("-compose") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { openComposer() }
        }
        // `-hold`: lifts the price card out a second after launch
        if args.contains("-hold") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                holdWidget(.navValue, frame: CGRect(x: 11, y: 671, width: 368, height: 445))
            }
        }
        // `-composeContext`: opens the composer with the stats card attached as context
        if args.contains("-composeContext") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { openComposer(with: .fundMetaData) }
        }
        // `-autoScrub`: slowly scrolls through the squeeze zone so the scrub can be screenshotted
        if args.contains("-autoScrub") {
            let start = xirrInViewOffset(viewportHeight: UIScreen.main.bounds.height)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                scrollPosition.scrollTo(y: start)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    scrollPosition.scrollTo(y: start + Self.collapseTriggerDistance + 10)
                }
            }
        }
    }
}

// MARK: - Animated progress plumbing

private struct TransitionProgressKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var transitionProgress: CGFloat {
        get { self[TransitionProgressKey.self] }
        set { self[TransitionProgressKey.self] = newValue }
    }
}

/// Interpolated by SwiftUI during `withAnimation`; publishes the current progress to the subtree.
private struct AnimatedProgress: ViewModifier, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.environment(\.transitionProgress, progress)
    }
}

// MARK: - Style A — header morphs, page fades

private struct MorphLayers<Page: View>: View {
    @Environment(\.transitionProgress) private var progress
    let isCollapsed: Bool
    let chatRevealed: Bool
    @ViewBuilder let page: () -> Page

    var body: some View {
        // Staggered like a sheet: the page is gone by 60%, the chat arrives over the last 55%
        let pageVisibility = 1 - min(1, progress / 0.6)
        let chatVisibility = max(0, (progress - 0.45) / 0.55)

        page()
            .opacity(pageVisibility)
            .scaleEffect(1 - 0.08 * progress, anchor: .top)
            .offset(y: 70 * progress)
            .allowsHitTesting(!isCollapsed)

        ChatContent(revealed: chatRevealed)
            .opacity(chatVisibility)
            .scaleEffect(0.96 + 0.04 * progress, anchor: .top)
            .offset(y: 40 * (1 - progress))
            .allowsHitTesting(isCollapsed)
    }
}

// MARK: - Style B — the page's sections gather into the widget

private struct CollapseLayers: View {
    @Environment(\.transitionProgress) private var p
    let isCollapsed: Bool
    let chatRevealed: Bool
    /// True while the page is moving into the widget (the glow is not shown when pulling it back out)
    let collapsing: Bool
    let scrollOffset: CGFloat
    let viewport: CGSize
    let scrollPosition: Binding<ScrollPosition>
    let tab: FundTab
    let onScroll: (CGFloat) -> Void
    let onContext: (FundContext) -> Void
    let heldContext: FundContext?
    let onHold: (FundContext, CGRect) -> Void
    let expandGesture: AnyGesture<DragGesture.Value>

    var body: some View {
        let card = FundExperienceView.cardRect
        // Frame the page is clipped to: full screen → summary card
        let frame = CGRect(
            x: card.minX * p,
            y: card.minY * p,
            width: viewport.width + (card.width - viewport.width) * p,
            height: viewport.height + (card.height - viewport.height) * p
        )
        let radius = FundExperienceView.cardRadius * p
        let headerVisibility = 1 - min(1, p / 0.4)
        let chatVisibility = max(0, (p - 0.5) / 0.5)
        // White surface covers the gathered sections first, then the summary content fades in on it
        let surfaceVisibility = min(1, max(0, (p - 0.82) / 0.13))
        let summaryVisibility = max(0, (p - 0.9) / 0.1)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        ChatContent(revealed: chatRevealed)
            .opacity(chatVisibility)
            .offset(y: 40 * (1 - p))
            .allowsHitTesting(isCollapsed)

        // Shadow + border drawn as a separate layer, since the mask would clip them
        shape
            .fill(Color.white)
            .overlay(shape.stroke(Color.black.opacity(0.11), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.15), radius: 60, x: 0, y: 1)
            .frame(width: frame.width, height: frame.height)
            .opacity(p)
            .at(frame.minX, frame.minY)

        ZStack(alignment: .top) {
            // Sections gather into the widget one after another (see `GatherModifier`)
            TabPages(tab: tab, width: viewport.width, onContext: onContext, heldContext: heldContext, onHold: onHold) {
                MutualFundScreen(
                    scrollPosition: scrollPosition,
                    gather: GatherState(progress: p, scrollOffset: scrollOffset, leadFromBottom: !isCollapsed),
                    onScrollOffsetChange: onScroll,
                    onContext: onContext,
                    heldContext: heldContext,
                    onHold: onHold
                )
            }
            .allowsHitTesting(!isCollapsed)

            // Nav header rides on top of the page here (in the morph style it is the card itself)
            // No card behind the header in 865:13484 — a light material keeps it readable over scrolled content
            NavHeader()
                .padding(.top, 51)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .opacity(headerVisibility)
                .allowsHitTesting(!isCollapsed)
        }
        .frame(width: viewport.width, height: viewport.height, alignment: .top)
        .overlay(alignment: .topLeading) {
            // The summary surfaces over the gathered sections at the end, tracking the animating frame
            Color.white
                .opacity(surfaceVisibility)
                .frame(width: frame.width, height: frame.height)
                .overlay(alignment: .topLeading) { FundSummaryContent().opacity(summaryVisibility) }
                .allowsHitTesting(false)
                .at(frame.minX, frame.minY)
        }
        .mask(alignment: .topLeading) {
            shape
                .frame(width: frame.width, height: frame.height)
                .at(frame.minX, frame.minY)
        }
        .overlay(alignment: .topLeading) {
            BorderHeatGlow(cornerRadius: radius, progress: collapsing ? p : 0)
                .frame(width: frame.width, height: frame.height)
                .at(frame.minX, frame.minY)
        }
        .overlay(alignment: .topLeading) {
            // Pull handle: the card area, once collapsed
            if isCollapsed {
                Color.clear
                    .frame(width: card.width, height: card.height)
                    .contentShape(Rectangle())
                    .at(card.minX, card.minY)
                    .gesture(expandGesture)
            }
        }
    }
}

// MARK: - The card that morphs between the nav header (717:10994) and the fund summary (700:7459)

private struct MorphingCard: View {
    @Environment(\.transitionProgress) private var progress
    let collapsing: Bool

    private func lerp(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * progress }

    var body: some View {
        let card = FundExperienceView.cardRect
        let height = lerp(63, card.height)
        let radius = lerp(0, FundExperienceView.cardRadius)
        // Each state's content fades over its own half so they never show together
        let headerOpacity = max(0, 1 - progress * 2)
        let summaryOpacity = max(0, progress * 2 - 1)

        ZStack(alignment: .topLeading) {
            Color.white

            NavHeader()
                .opacity(headerOpacity)

            FundSummaryContent()
                .opacity(summaryOpacity)
        }
        .frame(width: card.width, height: height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(Color.black.opacity(0.11 * progress), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(lerp(0.08, 0.15)), radius: lerp(25, 60), x: 0, y: lerp(4, 1))
        .overlay(BorderHeatGlow(cornerRadius: radius, progress: collapsing ? progress : 0))
        .padding(.top, lerp(51, card.minY))
        .contentShape(Rectangle())
    }
}

/// Contents of the summary card (700:7459), 364 × 150
private struct FundSummaryContent: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Text("HSBC Mutual fund")
                .font(FigmaFont.walsheimMedium(23))
                .foregroundStyle(Color.black)
                .at(23, 17)

            // Fund row (700:7464), 334 × 71
            ZStack(alignment: .topLeading) {
                Color.white

                HSBCLogoCrop(slot: CGSize(width: 38.739, height: 33), scaleW: 2.9091, scaleH: 1.9428, leftPct: -0.2963, topPct: -0.4714)
                    .at(13, 17)

                Text("Midcap Growth")
                    .font(FigmaFont.walsheim(15))
                    .foregroundStyle(Color.black.opacity(0.83))
                    .at(59, 17)

                Text("NSE")
                    .font(FigmaFont.walsheim(14))
                    .foregroundStyle(Color.black.opacity(0.56))
                    .at(59, 37)

                Image("Sparkline")
                    .resizable()
                    .frame(width: 37.9174, height: 31)
                    .at(171, 20)

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
                .at(223.94, 20)
            }
            .frame(width: 334, height: 71)
            .shadow(color: Color.black.opacity(0.03), radius: 38, x: 0, y: 3)
            .at(15, 56)

            // Grabber (700:7597)
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: 0x898787))
                .frame(width: 36, height: 3)
                .at(164, 137)
        }
        .frame(width: 364, height: 150, alignment: .topLeading)
    }
}

// MARK: - Chat state contents (700:7314) below the summary card

private struct ChatContent: View {
    /// When true the bubbles pop in one after another (message, then each chip)
    let revealed: Bool

    /// Bubbles arrive one after another, each quicker than the last (see `Stagger`)
    private func arriving<V: View>(_ view: V, order: Int) -> some View {
        let timing = Stagger.arrival(order)
        return view
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 18)
            .scaleEffect(revealed ? 1 : 0.94, anchor: .bottomLeading)
            .animation(
                revealed
                    ? .spring(response: timing.response, dampingFraction: 0.8).delay(timing.delay)
                    : .easeOut(duration: 0.12),
                value: revealed
            )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Assistant message (700:7523), 335 × 196
            arriving(ZStack(alignment: .topLeading) {
                // Bubble (700:7591), 299 × 183
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color(hex: 0xEDECEC))
                        .frame(width: 299, height: 183)

                    Text("Siddarth, For the next few weeks the number will move around a bit, up and down. That’s normal and it doesn’t mean anything yet. The part that matters is the 1st of every month, and that’s already handled.")
                        .font(FigmaFont.walsheim(17))
                        .foregroundStyle(Color.black.opacity(0.71))
                        .frame(width: 265, alignment: .leading)
                        .at(15, 15)

                    Image("BubbleTail")
                        .resizable()
                        .frame(width: 24.3238, height: 14.976)
                        .rotationEffect(.degrees(7.22))
                        .at(1.97, 174.55)

                    Image("Vector83Grey")
                        .resizable()
                        .frame(width: 15.4967, height: 8.07787)
                        .rotationEffect(.degrees(7.34))
                        .at(14.85, 174.63)
                }
                .shadow(color: Color.black.opacity(0.03), radius: 7.5, x: 0, y: 3)
                .at(36, 2)

                Image("ChatAvatar")
                    .resizable()
                    .frame(width: 33, height: 33)
                    .at(0, 163)
            }
            .frame(width: 335, height: 196, alignment: .topLeading), order: 0)
            .at(13, 234)

            arriving(SuggestionChip(title: "Get SBI small cap direct"), order: 1).at(112, 450)
            arriving(SuggestionChip(title: "Get SBI small cap direct"), order: 2).at(112, 526)
        }
        .frame(width: MutualFundScreen.canvasWidth, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

/// Suggestion chip (700:7327 / 700:7330), 263 × 63
private struct SuggestionChip: View {
    let title: String

    var body: some View {
        Button(action: { Haptics.tap() }) {
            ZStack(alignment: .topLeading) {
                Color.white

                HSBCLogoCrop(slot: CGSize(width: 27, height: 23), scaleW: 2.9091, scaleH: 1.9428, leftPct: -0.2963, topPct: -0.4714)
                    .at(15, 20)

                Text(title)
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color.black)
                    .at(49, 20)
            }
            .frame(width: 263, height: 63)
            .clipShape(RoundedRectangle(cornerRadius: 100))
            .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.black.opacity(0.05), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
