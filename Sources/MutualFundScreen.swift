import SwiftUI

/// Figma: "iPhone 14 Plus - 251" (node 865:13474), 390 × 2156.
/// The scrolling fund page. The fixed header and the floating chat + tabs live in `FundExperienceView`.
struct MutualFundScreen: View {
    static let canvasWidth: CGFloat = 390
    /// Figma frame is 2156; the extra room lets the page scroll far enough past the last card to trigger the collapse
    static let canvasHeight: CGFloat = 2302
    /// Bottom edge of the last section (the placeholder cards, 865:13616) in content coordinates.
    static let contentBottom: CGFloat = 1596 + 206

    var scrollPosition: Binding<ScrollPosition>
    /// When set, the page's sections gather into the summary widget as `progress` rises (Collapse style).
    var gather: GatherState? = nil
    var onScrollOffsetChange: (CGFloat) -> Void
    var onScrollPhaseChange: (ScrollPhase) -> Void = { _ in }
    /// A widget was swiped right: attach it as context on the input.
    var onContext: (FundContext) -> Void = { _ in }
    /// The widget currently lifted out by a long press (drawn by `HeldWidgetLayer`, hidden here)
    var heldContext: FundContext? = nil
    /// A widget was long-pressed; the rect is its frame on screen.
    var onHold: (FundContext, CGRect) -> Void = { _, _ in }

    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                BackgroundBlobs()
                    .opacity(1 - (gather?.progress ?? 0))

                Text("HSBC midcap direct growth")
                    .font(FigmaFont.reckless(43))
                    .foregroundStyle(Color.ink)
                    .frame(width: 356, alignment: .leading)
                    .gathered(gather, index: 0, y: 131, height: 98)
                    .at(15, 131)

                FundFeatureList()
                    .widgetHold(isHeld: heldContext == .fundMetaData) { onHold(.fundMetaData, $0) }
                    .contextSwipe { onContext(.fundMetaData) }
                    .gathered(gather, index: 1, y: 256, height: 214)
                    .at(13, 256)

                FundScoreCard()
                    .widgetHold(isHeld: heldContext == .fundScore) { onHold(.fundScore, $0) }
                    .contextSwipe { onContext(.fundScore) }
                    .gathered(gather, index: 2, y: 507, height: 127)
                    .at(11, 507)

                PriceCard()
                    .widgetHold(isHeld: heldContext == .navValue) { onHold(.navValue, $0) }
                    .contextSwipe { onContext(.navValue) }
                    .gathered(gather, index: 3, y: 671, height: 445)
                    .at(11, 671)

                InvestmentsCard()
                    .widgetHold(isHeld: heldContext == .investments) { onHold(.investments, $0) }
                    .contextSwipe { onContext(.investments) }
                    .gathered(gather, index: 4, y: 1176, height: 393)
                    .at(11, 1176)

                // Figma (907:16990) leaves these at y 1421 under the moved investments card; kept 27pt below it
                PlaceholderCards()
                    .gathered(gather, index: 5, y: 1596, height: 206)
                    .at(11, 1596)
            }
            .frame(width: Self.canvasWidth, height: Self.canvasHeight, alignment: .topLeading)
            .clipped()
            .frame(maxWidth: .infinity)
        }
        .scrollPosition(scrollPosition)
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, new in
            onScrollOffsetChange(new)
        }
        .onScrollPhaseChange { _, new in onScrollPhaseChange(new) }
        .defaultScrollAnchor(Self.debugScrollAnchor)
    }

    /// Launch argument `-scrollAnchor center|bottom` — lets simulator screenshots capture the lower sections.
    private static var debugScrollAnchor: UnitPoint? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-scrollAnchor"), i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "center": return .center
        case "bottom": return .bottom
        default: return nil
        }
    }
}

// MARK: - Widgets as chat context

/// A page widget attached to the composer as context (the chip in 717:10770).
enum FundContext: Equatable {
    case fundMetaData, fundScore, navValue, investments, summary, fundPerformance, msftChart
    /// A fixed deposit card, by issuer
    case deposit(String)
    /// A card on a bank's page: the issuer, which card, and which version of the page it is on
    case bank(String, BankSection, v2: Bool)

    /// The cards on a bank's page (`offers` is one of the second version's tenure groups)
    enum BankSection: Equatable {
        case identity, thingsToKnow, comparison, available, offers(Int)

        var title: String {
            switch self {
            case .identity: "About the bank"
            case .thingsToKnow: "Things to know"
            case .comparison: "Interest comparison"
            case .available: "Available FD’s"
            case .offers(let index): ["FD’s over 1 year", "FD’s up to 1 year", "FD’s up to 3 months"][index]
            }
        }

        var questions: [String] {
            switch self {
            case .identity: ["Is this bank safe?", "What is an SFB licence?"]
            case .thingsToKnow: ["Any penalty to withdraw early?", "How does the insurance work?"]
            case .comparison: ["Why is its rate higher?", "Which bank is safest?"]
            case .available, .offers: ["Which tenure suits me?", "How is interest paid out?"]
            }
        }
    }

    /// The fixed deposit it is, for a deposit card or a card on its bank's page
    var deposit: FixedDepositsView.Deposit? {
        switch self {
        case .deposit(let name), .bank(let name, _, _): FixedDepositsView.deposits.first { $0.name == name }
        default: nil
        }
    }

    /// The chip's icon in the composer
    var icon: String { deposit?.logo ?? "MetaIcon" }

    var title: String {
        switch self {
        case .fundMetaData: "HSBC fund meta data"
        case .fundScore: "HSBC fund score"
        case .navValue: "HSBC price chart"
        case .investments: "For investments"
        case .summary: "Fund summary for you"
        case .fundPerformance: "Fund performance"
        case .msftChart: "MSFT price chart"
        case .deposit(let name): "\(name) FD"
        case .bank(_, let section, _): section.title
        }
    }

    var subtitle: String {
        switch self {
        case .fundMetaData: "Direct, Growth, Midcap"
        case .fundScore: "Score 8.1 · Rank 4"
        case .navValue: "Last 3 months · 3Y"
        case .investments: "Minimum SIP, Fund size, Nav"
        case .summary: "Risk, goals, performance"
        case .fundPerformance: "Steady growth over years"
        case .msftChart: "NSE · 3Y"
        case .deposit: deposit.map { "Up to \($0.rate) PA · \($0.ratingShort)" } ?? ""
        case .bank(let name, _, _): name
        }
    }

    /// Suggested questions shown when the widget is held (753:12431 defines these for the stats card)
    var questions: [String] {
        if case .bank(_, let section, _) = self { return section.questions }
        if let deposit { return ["Is \(deposit.name) safe?", "What if I break it early?"] }
        return ["Explain me the terms", "Why is the ratio so high?"]
    }

    /// The widget's own view, for drawing a lifted copy above the page
    @ViewBuilder var widget: some View {
        switch self {
        case .fundMetaData: FundFeatureList().background(Color.white)
        case .fundScore: FundScoreCard(fillsOnAppear: false)
        case .navValue: PriceCard()
        case .investments: InvestmentsCard()
        case .summary: FundSummaryCard()
        case .fundPerformance: FundPerformanceCard()
        case .msftChart: MSFTChartCard()
        case .deposit: if let deposit { DepositCard(deposit: deposit) }
        case .bank(_, let section, let v2):
            if let deposit {
                if v2 {
                    FixedDepositBankV2View(deposit: deposit).section(section)
                } else {
                    FixedDepositBankView(deposit: deposit).section(section)
                }
            }
        }
    }
}

/// Long-press a widget to lift it out of the page. Reports the widget's on-screen frame so the lifted
/// copy can be drawn exactly where it was; the original is hidden while held.
private struct WidgetHoldModifier: ViewModifier {
    let isHeld: Bool
    let onHold: (CGRect) -> Void
    @State private var frame: CGRect = .zero
    @State private var pressing = false

    func body(content: Content) -> some View {
        content
            .opacity(isHeld ? 0 : 1)
            // Slight lift while the finger is down, before the hold fires
            .scaleEffect(pressing && !isHeld ? 1.015 : 1, anchor: .center)
            .animation(.easeOut(duration: 0.25), value: pressing)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
            .background(
                LongPressAttach(
                    onPressing: { down in
                        pressing = down
                        if down { Haptics.prepare() }
                    },
                    onHold: { onHold(frame) }
                )
            )
    }
}

/// Installs a long-press recognizer on the enclosing `UIScrollView`, gated to this widget's bounds.
/// (A SwiftUI `onLongPressGesture` inside the scroll view does not fire reliably.)
struct LongPressAttach: UIViewRepresentable {
    let onPressing: (Bool) -> Void
    let onHold: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> AnchorView {
        let view = AnchorView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ view: AnchorView, context: Context) {
        context.coordinator.onPressing = onPressing
        context.coordinator.onHold = onHold
    }

    final class AnchorView: UIView {
        weak var coordinator: Coordinator?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.attach(to: self)
        }
        override func layoutSubviews() {
            super.layoutSubviews()
            coordinator?.attach(to: self)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onPressing: (Bool) -> Void = { _ in }
        var onHold: () -> Void = {}
        private weak var anchor: UIView?
        private var press: UILongPressGestureRecognizer?

        func attach(to anchor: UIView) {
            guard press == nil, anchor.window != nil else { return }
            var v: UIView? = anchor.superview
            while let view = v, !(view is UIScrollView) { v = view.superview }
            // No scroll view (e.g. an onboarding screen): listen on the window instead
            guard let host = v ?? anchor.window else { return }
            self.anchor = anchor
            let press = UILongPressGestureRecognizer(target: self, action: #selector(handle(_:)))
            press.minimumPressDuration = 0.45
            press.allowableMovement = 12
            press.delegate = self
            host.addGestureRecognizer(press)
            self.press = press
        }

        @objc private func handle(_ press: UILongPressGestureRecognizer) {
            switch press.state {
            case .began:
                onPressing(true)
                onHold()
            case .ended, .cancelled, .failed:
                onPressing(false)
            default: break
            }
        }

        func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
            guard let anchor else { return false }
            return anchor.bounds.contains(gesture.location(in: anchor))
        }

        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

extension View {
    func widgetHold(isHeld: Bool, onHold: @escaping (CGRect) -> Void) -> some View {
        modifier(WidgetHoldModifier(isHeld: isHeld, onHold: onHold))
    }
}

/// Swipe a widget to the right to send it to the input as context. The widget follows the finger,
/// ticks at the threshold, then springs back as the composer opens.
private struct ContextSwipeModifier: ViewModifier {
    let onSend: () -> Void
    @State private var dragX: CGFloat = 0
    @State private var pastThreshold = false

    private static let threshold: CGFloat = 70

    func body(content: Content) -> some View {
        let lift = min(1, dragX / Self.threshold)
        content
            .offset(x: dragX)
            // Lifts slightly while being dragged so it reads as the widget being picked up
            .scaleEffect(1 + 0.02 * lift, anchor: .leading)
            .shadow(color: Color.black.opacity(0.12 * lift), radius: 18, x: 0, y: 8)
            .background(
                RightSwipeAttach(
                    onChanged: { dx in
                        if dragX == 0 { Haptics.prepare() }
                        // Follows the finger 1:1 up to the threshold, then eases off
                        let x = max(0, dx)
                        dragX = x <= Self.threshold ? x : Self.threshold + Self.rubberBand(x - Self.threshold)
                        let past = x > Self.threshold
                        if past != pastThreshold {
                            pastThreshold = past
                            Haptics.thresholdCrossed()
                        }
                    },
                    onEnded: { _ in
                        let send = pastThreshold
                        pastThreshold = false
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { dragX = 0 }
                        if send { onSend() }
                    }
                )
            )
    }

    private static func rubberBand(_ x: CGFloat, limit: CGFloat = 90) -> CGFloat {
        (1 - (1 / ((x * 0.55 / limit) + 1))) * limit
    }
}

/// Installs a pan recognizer on the enclosing `UIScrollView` that only begins for a rightward, mostly
/// horizontal drag inside this widget's bounds; the scroll view's own pan waits for it to fail, so
/// vertical drags scroll the page as usual. (A SwiftUI `DragGesture` would claim the touch first and
/// block scrolling; `UIGestureRecognizerRepresentable` has the same problem.)
struct RightSwipeAttach: UIViewRepresentable {
    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> AnchorView {
        let view = AnchorView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ view: AnchorView, context: Context) {
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
    }

    final class AnchorView: UIView {
        weak var coordinator: Coordinator?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.attach(to: self)
        }
        override func layoutSubviews() {
            super.layoutSubviews()
            coordinator?.attach(to: self)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onChanged: (CGFloat) -> Void = { _ in }
        var onEnded: (CGFloat) -> Void = { _ in }
        private weak var anchor: UIView?
        private var pan: UIPanGestureRecognizer?

        func attach(to anchor: UIView) {
            guard pan == nil, anchor.window != nil else { return }
            var v: UIView? = anchor.superview
            while let view = v, !(view is UIScrollView) { v = view.superview }
            let scrollView = v as? UIScrollView
            // No scroll view (e.g. an onboarding screen): listen on the window instead
            guard let host = scrollView ?? anchor.window else { return }
            self.anchor = anchor
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handle(_:)))
            pan.delegate = self
            host.addGestureRecognizer(pan)
            scrollView?.panGestureRecognizer.require(toFail: pan)
            self.pan = pan
        }

        @objc private func handle(_ pan: UIPanGestureRecognizer) {
            let dx = pan.translation(in: pan.view).x
            switch pan.state {
            case .changed: onChanged(dx)
            case .ended, .cancelled, .failed: onEnded(dx)
            default: break
            }
        }

        func gestureRecognizerShouldBegin(_ gesture: UIGestureRecognizer) -> Bool {
            guard let pan = gesture as? UIPanGestureRecognizer, let anchor else { return false }
            guard anchor.bounds.contains(pan.location(in: anchor)) else { return false }
            let t = pan.translation(in: pan.view)
            return t.x > 0 && t.x > abs(t.y) * 1.5
        }

        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            false
        }
    }
}

extension View {
    @ViewBuilder
    func contextSwipe(onSend: @escaping () -> Void) -> some View {
        if ProcessInfo.processInfo.arguments.contains("-noContextSwipe") {
            self
        } else {
            modifier(ContextSwipeModifier(onSend: onSend))
        }
    }
}

// MARK: - Gathering sections into the summary widget (Collapse style)

struct GatherState {
    /// 0 = page laid out, 1 = every section squeezed into the widget
    var progress: CGFloat
    /// Current scroll offset, so the widget's screen position can be expressed in content coordinates
    var scrollOffset: CGFloat
    /// Gathering while scrolled to the bottom: the sections on screen (XIRR, Nav value) lead.
    /// Laying out from the widget at the top: the title leads.
    var leadFromBottom: Bool
}

/// Moves a page section from its place on the page onto the summary widget and squeezes it to the widget's
/// height. Sections are staggered by index so they gather (and, in reverse, lay out) one after another.
private struct GatherModifier: ViewModifier {
    let state: GatherState?
    let index: Int
    let y: CGFloat
    let height: CGFloat

    private static let sectionCount = 6
    private static let stagger: CGFloat = 0.11

    func body(content: Content) -> some View {
        let overall = state?.progress ?? 0
        let order = (state?.leadFromBottom ?? false) ? Self.sectionCount - 1 - index : index
        let span = 1 - Self.stagger * CGFloat(Self.sectionCount - 1)
        let p = min(1, max(0, (overall - Self.stagger * CGFloat(order)) / span))
        let card = FundExperienceView.cardRect
        let targetY = card.minY + (state?.scrollOffset ?? 0)

        content
            .scaleEffect(x: 1, y: 1 + (min(1, card.height / height) - 1) * p, anchor: .top)
            .offset(y: (targetY - y) * p)
    }
}

extension View {
    func gathered(_ state: GatherState?, index: Int, y: CGFloat, height: CGFloat) -> some View {
        modifier(GatherModifier(state: state, index: index, y: y, height: height))
    }
}

// MARK: - Background (Ellipse 3/4/5/6 under a 145px backdrop blur, 64% white)

struct BackgroundBlobs: View {
    /// White wash over the blurred blobs (64% on the fund pages, 87% on the v2 home)
    var wash: Double = 0.64

    var body: some View {
        ZStack(alignment: .topLeading) {
            Ellipse()
                .fill(Color(hex: 0xF6F5DF))
                .frame(width: 165, height: 378)
                .at(97, 118)

            Ellipse()
                .fill(Color(hex: 0xBBC5B0))
                .frame(width: 119.377, height: 273.036)
                .rotationEffect(.degrees(-86.94))
                .frame(width: 279.025, height: 133.796)
                .at(7, 678.206)

            ForEach([CGPoint(x: 171, y: 4.411), CGPoint(x: 75, y: 960.411)], id: \.y) { origin in
                Ellipse()
                    .fill(Color(hex: 0xF0F0F0))
                    .frame(width: 359.537, height: 446)
                    .rotationEffect(.degrees(-3.73))
                    .frame(width: 387.814, height: 468.464)
                    .at(origin.x, origin.y)
            }
        }
        .blur(radius: 145)
        .overlay(Color.white.opacity(wash))
    }
}

// MARK: - Nav header (865:13484) — the white card itself is drawn by `MorphingCard`

struct NavHeader: View {
    @AppStorage("transitionStyle") private var transitionStyle: TransitionStyle = .collapse
    @Environment(\.goBack) private var goBack
    private let midY: CGFloat = 31.5

    var body: some View {
        ZStack(alignment: .topLeading) {
            Button {
                Haptics.tap()
                goBack()
            } label: {
                Image("BackIcon")
                    .resizable()
                    .frame(width: 10, height: 17)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .position(x: 20 + 5, y: midY)

            // Logo + "HSBC" (865:13485)
            ZStack(alignment: .topLeading) {
                HSBCLogoCrop(slot: CGSize(width: 43, height: 23), scaleW: 1.8267, scaleH: 1.9428, leftPct: 0, topPct: -0.4714)

                Text("HSBC")
                    .font(FigmaFont.walsheimMedium(17))
                    .tracking(0.85)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.black.opacity(0.5))
                    .frame(height: 23)
                    .position(x: 47.5 + 24, y: 11.5)
            }
            .frame(width: 95, height: 23)
            .position(x: 49 + 47.5, y: midY)

            Image("BookmarkIcon")
                .resizable()
                .frame(width: 17, height: 20)
                .position(x: 283 + 8.5, y: midY)

            // Figma: U+100360 in SF Compact Rounded Semibold = "ellipsis" (337, 18, 22 × 27)
            // Prototype control: the menu switches the page ↔ chat transition style.
            Menu {
                Picker("Transition", selection: $transitionStyle) {
                    ForEach(TransitionStyle.allCases) { Text($0.title).tag($0) }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20.25, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.black)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .onChange(of: transitionStyle) { Haptics.tap() }
            .position(x: 327 + 11, y: midY)
        }
        .frame(width: 376, height: 63)
    }
}

// MARK: - Direct fund / Growth fund / Midcap (865:13531)

struct FundFeatureList: View {
    // Figma: U+101EF4 / U+10321F / U+102839 in SF Compact Rounded
    private let rows: [(icon: String, title: String, detail: String, y: CGFloat, detailY: CGFloat)] = [
        ("point.bottomleft.forward.to.point.topright.scurvepath", "Direct fund", "Lower expense ratio, zero commissions", 0, 28),
        ("graph.2d", "Growth fund", "Fund reinvest the fund’s earnings back into it instead of paying them out", 72, 100),
        ("distribute.horizontal", "Midcap", "Funds that invest in mid-sized companies", 165, 193),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(rows, id: \.title) { row in
                Image(systemName: row.icon)
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundStyle(Color.black)
                    .frame(width: 24, height: 23, alignment: .leading)
                    .at(5, row.y + 3)

                Text(row.title)
                    .font(FigmaFont.walsheim(19))
                    .foregroundStyle(Color.black)
                    .frame(height: 25)
                    .at(38, row.y)

                Text(row.detail)
                    .font(FigmaFont.walsheim(15))
                    .foregroundStyle(Color.black.opacity(0.43))
                    .lineSpacing(3)
                    .frame(width: 326, alignment: .leading)
                    .at(38, row.detailY)
            }
        }
        .frame(width: 364, height: 214, alignment: .topLeading)
        // Holdable/swipeable anywhere in the block, not only on the text
        .contentShape(Rectangle())
    }
}

// MARK: - Score / Rank card (907:17135)

struct FundScoreCard: View {
    /// The page copy plays its reveal when it first appears; the lifted copy (held widget) shows the end state
    var fillsOnAppear = true
    /// Bars lit so far; the score counts up alongside them
    @State private var filled = 0
    /// Card grown from the score row alone to include the rank row
    @State private var showsRank = false
    /// Rank counted so far (rolls 0 → 4 as the rank row arrives)
    @State private var rankCount = 0
    /// This fund's box widened into the outlined HSBC box
    @State private var rankExpanded = false

    private static let score = 8.1
    private static let rank = 4
    /// Height with just the score row: the meter (23…42) plus the same 23pt below it
    private static let collapsedHeight: CGFloat = 65
    private static let fullHeight: CGFloat = 127

    var body: some View {
        let shownScore = Self.score * Double(filled) / Double(ScoreMeter.scoreBars)

        ZStack(alignment: .topLeading) {
            Color.white

            ScoreMeter(filled: filled)
                .at(23, 23)

            figure(String(format: "%.1f", shownScore), value: shownScore, label: "Score", top: 14, captionTop: 24)

            ForEach(1...5, id: \.self) { rank in
                rankBox(rank)
            }

            figure("\(rankCount)", value: Double(rankCount), label: "Rank", top: 75, captionTop: 84)
        }
        .frame(width: 368, height: showsRank ? Self.fullHeight : Self.collapsedHeight, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
        .frame(height: Self.fullHeight, alignment: .top)
        .onAppear(perform: reveal)
    }

    /// Rank boxes (907:17260…17316): plain 24 × 28 gray boxes on a 31pt pitch; this fund's box then widens to
    /// 121 × 40, turns white with a black outline and shows the HSBC logo, pushing the boxes after it along.
    private func rankBox(_ rank: Int) -> some View {
        let isFund = rank == Self.rank
        let e: CGFloat = isFund && rankExpanded ? 1 : 0
        let x: CGFloat = rank > Self.rank && rankExpanded ? 244 : 23 + CGFloat(rank - 1) * 31

        return ZStack {
            RoundedRectangle(cornerRadius: 7 + 8 * e)
                .fill(Color(hex: 0xEBEBE8).mix(with: .white, by: e))
                .overlay(RoundedRectangle(cornerRadius: 7 + 8 * e).stroke(Color.black.opacity(e), lineWidth: 1))

            Text("\(rank)")
                .font(FigmaFont.walsheimMedium(15))
                .foregroundStyle(Color.black.opacity(0.33))
                .opacity(1 - e)

            if isFund {
                // This fund's place in the ranking (907:17263)
                ZStack(alignment: .topLeading) {
                    HSBCLogoCrop(slot: CGSize(width: 28.677, height: 15.167), scaleW: 1.8267, scaleH: 1.9428, leftPct: 0, topPct: -0.4714)

                    Text("HSBC")
                        .font(FigmaFont.walsheimMedium(11.274))
                        .tracking(0.5637)
                        .foregroundStyle(Color.black.opacity(0.5))
                        .frame(height: 15.253)
                        .at(31.83, 0)
                }
                .frame(width: 63, height: 15.253, alignment: .topLeading)
                .scaleEffect(0.6 + 0.4 * e)
                .opacity(e)
            }
        }
        .frame(width: 24 + 97 * e, height: 28 + 12 * e)
        .clipShape(RoundedRectangle(cornerRadius: 7 + 8 * e))
        .at(x, 79 - 6 * e)
    }

    /// Big number with its caption at x 313; the number is right-aligned to x 310 so it grows leftwards
    private func figure(_ text: String, value: Double, label: String, top: CGFloat, captionTop: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Text(text)
                .font(FigmaFont.walsheimMedium(25.095))
                .foregroundStyle(Color.black)
                // iOS rolling-digit transition as the number counts up
                .contentTransition(.numericText(value: value))
                .frame(width: 60, height: 37, alignment: .trailing)
                .at(310 - 60, top)

            Text(label)
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Color.black.opacity(0.43))
                .frame(height: 23)
                .at(313, captionTop)
        }
    }

    /// 1. The meter lights one bar at a time while the score counts up (a soft tick per bar).
    /// 2. The card grows to show the rank row of plain boxes; the rank rolls up to 4.
    /// 3. This fund's box widens into its outlined HSBC style.
    private func reveal() {
        guard fillsOnAppear else {
            filled = ScoreMeter.scoreBars
            showsRank = true
            rankCount = Self.rank
            rankExpanded = true
            return
        }
        let start = 0.4
        for i in 0..<ScoreMeter.scoreBars {
            DispatchQueue.main.asyncAfter(deadline: .now() + start + Double(i) * 0.04) {
                Haptics.meterTick(intensity: 0.45 - 0.3 * Double(i) / Double(ScoreMeter.scoreBars))
                withAnimation(.easeOut(duration: 0.25)) { filled = i + 1 }
            }
        }
        let meterDone = start + Double(ScoreMeter.scoreBars) * 0.04

        DispatchQueue.main.asyncAfter(deadline: .now() + meterDone + 0.15) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { showsRank = true }
        }
        for r in 1...Self.rank {
            DispatchQueue.main.asyncAfter(deadline: .now() + meterDone + 0.35 + Double(r - 1) * 0.09) {
                Haptics.meterTick(intensity: 0.3)
                withAnimation(.easeOut(duration: 0.25)) { rankCount = r }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + meterDone + 0.35 + Double(Self.rank) * 0.09 + 0.1) {
            Haptics.thresholdCrossed()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) { rankExpanded = true }
        }
    }
}

/// The score meter (907:17231): 25 bars, 5 × 19 on a 10pt pitch, coloured along a yellow → lilac → green
/// gradient up to the score and light gray after it.
private struct ScoreMeter: View {
    /// Number of bars lit, counted from the left
    let filled: Int

    private static let barCount = 25
    private static let width: CGFloat = 245
    /// Gradient stops from the Union fill; everything past 0.79 is the unfilled gray
    private static let stops: [(CGFloat, UInt32)] = [
        (0, 0xFEC853), (0.278846, 0xDCBCAB), (0.504808, 0xB2B8D0), (0.791458, 0x87F77D),
    ]
    private static let empty = Color(hex: 0xEDEDED)
    /// Bars whose centre falls inside the coloured part of the gradient (8.1 → 20 of 25)
    static let scoreBars = (0..<barCount).filter { (2.5 + CGFloat($0) * 10) / width <= stops.last!.0 }.count

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<Self.barCount, id: \.self) { i in
                Capsule()
                    .fill(i < filled ? Self.color(at: (2.5 + CGFloat(i) * 10) / Self.width) : Self.empty)
                    .frame(width: 5, height: 19)
            }
        }
        .frame(width: Self.width, height: 19)
    }

    /// Colour of the Union gradient at `t` (0…1 across the meter)
    private static func color(at t: CGFloat) -> Color {
        let upper = stops.firstIndex { $0.0 >= t } ?? stops.count - 1
        guard upper > 0 else { return Color(hex: stops[0].1) }
        let (t0, c0) = stops[upper - 1], (t1, c1) = stops[upper]
        let f = Double((t - t0) / (t1 - t0))
        func channel(_ c: UInt32, _ shift: UInt32) -> Double { Double((c >> shift) & 0xFF) / 255 }
        return Color(
            red: channel(c0, 16) + (channel(c1, 16) - channel(c0, 16)) * f,
            green: channel(c0, 8) + (channel(c1, 8) - channel(c0, 8)) * f,
            blue: channel(c0, 0) + (channel(c1, 0) - channel(c0, 0)) * f
        )
    }
}

// Price card and period selector live in FundChart.swift

// MARK: - For investments (865:13491)

struct InvestmentsCard: View {
    private let rows: [(label: String, value: String, y: CGFloat)] = [
        ("Minimum SIP", "19.84%", 81),
        ("Fund size", "- 9.09%", 138),
        ("Nav 28 Oct", "- 9.09%", 195),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            Text("For investments")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black.opacity(0.93))
                .frame(height: 25)
                .at(17, 15)

            Rectangle()
                .fill(Color.black.opacity(0.07))
                .frame(width: 368, height: 2)
                .at(0, 54)

            ForEach(rows, id: \.label) { row in
                Text(row.label)
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color.black.opacity(0.56))
                    .frame(height: 25)
                    .at(17, row.y)

                Text(row.value)
                    .font(FigmaFont.walsheimMedium(19))
                    .foregroundStyle(Color.black)
                    .frame(width: 336, height: 25, alignment: .trailing)
                    .at(17, row.y - 1)
            }

            Text("Ashima, For the next few weeks the number will move around a bit, up and down. That’s normal and it doesn’t mean anything yet. The part that matters is the 1st of every month, and that’s already handled.")
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Color.black.opacity(0.71))
                .lineSpacing(3)
                .frame(width: 334, alignment: .leading)
                .at(17, 261)
        }
        .frame(width: 368, height: 393)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
    }
}

// MARK: - Placeholder cards (865:13616 / 865:13617)

private struct PlaceholderCards: View {
    var body: some View {
        HStack(spacing: 11) {
            card
            card
        }
        .frame(width: 367, height: 206, alignment: .leading)
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 23, style: .continuous)
            .fill(Color.white)
            .frame(width: 178, height: 206)
            .shadow(color: Color.black.opacity(0.02), radius: 50, x: 0, y: 4)
    }
}

/// "image 18" — the HSBC logo PNG as Figma crops it: the image is scaled by (scaleW, scaleH) relative to the slot
/// and offset by (leftPct, topPct) of the slot, then clipped to the slot.
struct HSBCLogoCrop: View {
    let slot: CGSize
    let scaleW: CGFloat
    let scaleH: CGFloat
    let leftPct: CGFloat
    let topPct: CGFloat

    var body: some View {
        Image("HSBCLogo")
            .resizable()
            .frame(width: slot.width * scaleW, height: slot.height * scaleH)
            .offset(x: slot.width * leftPct, y: slot.height * topPct)
            .frame(width: slot.width, height: slot.height, alignment: .topLeading)
            .clipped()
    }
}

// MARK: - Floating tabs (881:13651) — under the "Ask your advisor" pill, which `ComposerLayer` draws

struct FloatingTabs: View {
    @Environment(\.composeProgress) private var composeProgress
    @Binding var tab: FundTab
    @Namespace private var selection

    /// Top of the "Ask your advisor" pill. Figma has it 176pt above the bottom; pulled 20pt lower so the
    /// pill + tabs sit closer to the home indicator.
    static func pillTop(viewportHeight: CGFloat) -> CGFloat { viewportHeight - 156 }
    /// Top of the tab bar: 64pt below the pill
    static func top(viewportHeight: CGFloat) -> CGFloat { pillTop(viewportHeight: viewportHeight) + 64 }

    // Label x positions inside the bar (Market is drawn centred in its 123pt highlight)
    private let tabs: [(title: String, x: CGFloat)] = [("Market", 7), ("For you", 155), ("Research", 271)]

    var body: some View {
        let hidden = min(1, composeProgress / 0.4)

        ZStack(alignment: .topLeading) {
            Color.white

            ForEach(tabs, id: \.title) { tab in
                let selected = self.tab.rawValue == tab.title
                Button {
                    guard !selected, let next = FundTab(rawValue: tab.title) else { return }
                    Haptics.tap()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { self.tab = next }
                } label: {
                    ZStack {
                        if selected {
                            Capsule()
                                .fill(Color(hex: 0x302721))
                                .matchedGeometryEffect(id: "highlight", in: selection)
                        }
                        Text(tab.title)
                            .font(FigmaFont.walsheim(17))
                            .foregroundStyle(selected ? Color.white : Color.black)
                    }
                    .frame(width: 123, height: 47)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // Unselected labels keep their Figma x (their text starts there); the 123pt slot is centred on it
                .at(tab.title == "Market" ? 7 : tab.x + textWidth(tab.title) / 2 - 61.5, 7)
            }
        }
        .frame(width: 368, height: 61)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.09), radius: 50, x: 0, y: 4)
        .opacity(1 - hidden)
        .offset(y: 30 * hidden)
        .allowsHitTesting(hidden < 0.5)
    }

    /// Figma text widths (881:13652 / 881:13655)
    private func textWidth(_ title: String) -> CGFloat {
        switch title {
        case "For you": 58
        case "Research": 70
        default: 53
        }
    }
}

#Preview {
    FundExperienceView()
}
