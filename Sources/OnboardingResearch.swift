import SwiftUI

/// The sheet that opens over the advisory chat to show the research being done (99:1750), 368 × 499. Its parts come
/// in one under another as the agent gets to them: the title, the plan, the web searches, the counts, then the
/// sources it read: 807 links, each with its site's logo, that scroll with the rest of the sheet.
///
/// The welcome's chat opens a larger version of it (141:3689, 368 × 612) with a smaller title and wider boxes: the
/// same parts in the same order, set by a `Style`.
struct ResearchSheet: View {
    struct Style {
        var height: CGFloat
        /// The title's size and line height; it wraps on its own when `titleLines` is nil
        var titleSize: CGFloat
        var titleLineHeight: CGFloat
        var titleLines: [String]?
        var titleInset: CGFloat
        var titleTop: CGFloat
        /// Space under the title, before the plan
        var titleGap: CGFloat
        /// The boxes' inset from the sheet's sides
        var inset: CGFloat
        /// Space above the links box
        var linksGap: CGFloat
        var shadowOpacity: Double
        var shadowRadius: CGFloat
        /// "Research" over the title, with a close on the right (225:12081)
        var hasHeader = false

        var boxWidth: CGFloat { 368 - inset * 2 }

        /// 99:1750, over the advisory chat
        static let advisory = Style(height: 499, titleSize: 45, titleLineHeight: 46,
                                    titleLines: ["Market research", "January’17"], titleInset: 12, titleTop: 12,
                                    titleGap: 30, inset: 23, linksGap: 7, shadowOpacity: 0.23, shadowRadius: 100)
        /// 141:3689, over the welcome's chat
        static let welcome = Style(height: 612, titleSize: 37, titleLineHeight: 43, titleLines: nil,
                                   titleInset: 17, titleTop: 4, titleGap: 36, inset: 19, linksGap: 17,
                                   shadowOpacity: OnboardingDecadeWelcomeView.cardShadow, shadowRadius: OnboardingDecadeWelcomeView.cardShadowRadius,
                                   hasHeader: true)
    }

    var style: Style = .advisory
    /// When the research began; with one, a progress timer (148:6544) runs under the title
    var researchStarted: Date? = nil

    /// How long the research takes
    /// `-researchSeconds N` shortens it, and the analysis, for working on what comes after
    static let researchDuration: TimeInterval = override ?? 17
    /// How long the analysis takes
    static let analysisDuration: TimeInterval = override ?? 27
    private static let override: TimeInterval? = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-researchSeconds"), i + 1 < args.count, let n = Double(args[i + 1]) { return n }
        return nil
    }()
    /// The title, when the research is about something in particular
    var heading: String? = nil
    /// Its parts come in one by one only the first time it opens; after that it's simply there
    var animatesIn = true
    /// The research is still going: the header shimmers
    var researching = false
    /// The close at the header's right
    var onClose: () -> Void = {}

    /// How many of the parts have come in, top down
    @State private var revealed = 0
    /// How many of the source rows have come in; the first screenful arrives one by one, the rest all at once
    @State private var linksShown = 0
    /// The plan and the gathering are each worked on for a couple of seconds, pulsing softly, before they're done
    @State private var planDone = false
    @State private var resourcesDone = false

    private static let line = Color(red: 194 / 255, green: 194 / 255, blue: 194 / 255).opacity(0.33)
    private static let text = Color(red: 33 / 255, green: 33 / 255, blue: 33 / 255)

    /// Labels set at their Figma widths; the wider ones run past the tile's edge and are cut off, as in Figma
    static let counts: [(value: String, label: String, width: CGFloat)] = [
        ("1,512", "Portfolio disclosures", 105),
        ("98", "Scheme Information Document", 123),
        ("118", "Index factsheets (TRI)", 123),
    ]

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 7) {
                if style.hasHeader {
                    header
                        .padding(.leading, style.titleInset - style.inset)
                        .padding(.top, 17)
                        .arriving(revealed > 0)
                }
                VStack(alignment: .leading, spacing: 10) {
                    title
                    if let researchStarted {
                        ResearchTimer(started: researchStarted, duration: Self.researchDuration)
                            .padding(.bottom, 23 - (style.titleGap - 7))
                    }
                }
                .padding(.leading, style.titleInset - style.inset)
                .padding(.top, style.titleTop)
                .padding(.bottom, style.titleGap - 7)
                .arriving(revealed > 0)

                // 99:1788
                box(radius: 13) {
                    HStack(spacing: 9) {
                        Image("ResearchDoc").frame(width: 17, height: 17)
                        Text(planDone ? "Research plan created" : "Creating the plan")
                            .font(FigmaFont.walsheim(14))
                            .foregroundStyle(Self.text.opacity(0.67))
                            .contentTransition(.opacity)
                    }
                    .padding(.horizontal, 12)
                    .frame(width: style.boxWidth, height: 43, alignment: .leading)
                    .pulsing(!planDone)
                }
                .arriving(revealed > 1)

                // 99:1793
                box(radius: 13) {
                    HStack(alignment: .top, spacing: 9) {
                        Image("ResearchGlobe").frame(width: 17, height: 17)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(resourcesDone ? "Gathered 890 resources" : "Gathering resources")
                                .font(FigmaFont.walsheim(14))
                                .foregroundStyle(Self.text.opacity(0.67))
                                .contentTransition(.opacity)
                            Text("Credible sources verified by research agent")
                                .font(FigmaFont.walsheim(13))
                                .foregroundStyle(Self.text.opacity(0.47))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .frame(width: style.boxWidth, height: 63, alignment: .topLeading)
                    .pulsing(!resourcesDone)
                }
                .arriving(revealed > 2)

                // 101:1805, 101:1815, 101:1821: they run off the right edge and scroll sideways
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(Array(Self.counts.enumerated()), id: \.offset) { index, count in
                            Self.countTile(count)
                                .arriving(revealed > 3 + index)
                        }
                    }
                    .padding(.horizontal, style.inset)
                }
                .padding(.horizontal, -style.inset)

                links
                    .padding(.top, style.linksGap - 7)
                    .arriving(revealed > 6)
            }
            .padding(.horizontal, style.inset)
            .padding(.bottom, 23)
        }
        .frame(width: 368, height: style.height)
        .background(Color.white)
        .clipShape(shape)
        .shadow(color: Color.black.opacity(style.shadowOpacity), radius: style.shadowRadius, x: 0, y: 4)
        .onAppear {
            // Back again: all there from its first frame
            guard !animatesIn else { return }
            revealed = 7
            linksShown = ResearchSource.all.count
            planDone = true
            resourcesDone = true
        }
        .task { await reveal() }
    }

    /// "Research" (233:12927), Walsheim Medium 23 on a 29pt line, shimmering softly while it works; the close
    /// sits level with it at the right
    private var header: some View {
        HStack(spacing: 0) {
            Text("Research")
                .font(FigmaFont.walsheimMedium(23))
                .foregroundStyle(Color.black)
                .frame(height: 29)
                .shimmering(researching)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.6))
                    .frame(width: 29, height: 29)
                    .background(Circle().fill(Color.black.opacity(0.06)))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close research")
            .padding(.trailing, 17 - style.inset - 7.5)
        }
        .frame(height: 29)
    }

    /// Set at its line height, tighter than the font's own: line by line when the lines are given, otherwise wrapped
    @ViewBuilder private var title: some View {
        if let lines = style.titleLines {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(FigmaFont.reckless(style.titleSize))
                        .frame(height: style.titleLineHeight)
                }
            }
            .foregroundStyle(Color.black.opacity(0.93))
        } else {
            Text(heading ?? "Market research January’17")
                .font(FigmaFont.reckless(style.titleSize))
                .lineSpacing(style.titleLineHeight - style.titleSize * 1.2)
                .foregroundStyle(Color.black.opacity(0.93))
                .frame(width: 342, alignment: .leading)
        }
    }

    private func reveal() async {
        guard animatesIn else {
            revealed = 7
            linksShown = ResearchSource.all.count
            planDone = true
            resourcesDone = true
            return
        }
        // Each part lands as the one before settles, as though the agent is working through them; the plan and the
        // gathering each take two seconds, pulsing, before they're marked done
        func land(after beat: Double) async -> Bool {
            try? await Task.sleep(for: .seconds(beat))
            guard !Task.isCancelled else { return false }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { revealed += 1 }
            Haptics.revealGrain(intensity: 0.45)
            return true
        }
        guard await land(after: 0.15), await land(after: 0.55) else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: 0.3)) { planDone = true }
        guard await land(after: 0.35) else { return }
        try? await Task.sleep(for: .seconds(2))
        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: 0.3)) { resourcesDone = true }
        for beat in [0.35, 0.12, 0.12, 0.45] {
            guard await land(after: beat) else { return }
        }
        for _ in 0..<10 {
            try? await Task.sleep(for: .seconds(0.07))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) { linksShown += 1 }
        }
        linksShown = ResearchSource.all.count
    }

    private func box<Content: View>(radius: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        Self.box(radius: radius, content: content)
    }

    private static func box<Content: View>(radius: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return content()
            .clipShape(shape)
            .overlay(shape.strokeBorder(Self.line, lineWidth: 1))
    }

    /// One of the counts, 113 × 104; the chat shows them too once the research is done
    static func countTile(_ count: (value: String, label: String, width: CGFloat)) -> some View {
        box(radius: 13) {
            VStack(alignment: .leading, spacing: 0) {
                Image("ResearchDoc").frame(width: 17, height: 17)
                    .padding(.bottom, 6)
                Text(count.value)
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Self.text.opacity(0.67))
                    .frame(height: 21)
                    .padding(.bottom, 3)
                Text(count.label)
                    .font(FigmaFont.walsheim(13))
                    .lineSpacing(15 - 13 * 1.2)
                    .foregroundStyle(Self.text.opacity(0.47))
                    .frame(width: count.width, alignment: .leading)
                    .fixedSize()
            }
            .padding(.leading, 12)
            .padding(.top, 11)
            .frame(width: 113, height: 104, alignment: .topLeading)
        }
    }

    /// The sources it read (99:1751), 44pt rows with a hairline under each
    private var links: some View {
        box(radius: 17) {
            if let researchStarted {
                liveLinks(since: researchStarted)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(ResearchSource.all) { source in
                        row(source)
                            .opacity(source.id < linksShown ? 1 : 0)
                            .offset(y: source.id < linksShown ? 0 : 8)
                    }
                }
                .frame(width: style.boxWidth)
            }
        }
    }

    /// While the research runs, the sources keep rolling up through a window of five and a half rows, newer ones
    /// coming in at the foot, as it reads its way through them
    private func liveLinks(since started: Date) -> some View {
        let rowHeight: CGFloat = 44
        let visible = 7
        return TimelineView(.animation) { context in
            // Rolls once the rows have come in, at a row every 0.6s
            let elapsed = max(0, context.date.timeIntervalSince(started) - 3.2)
            let travel = CGFloat(elapsed) * rowHeight / 0.6
            let first = Int(travel / rowHeight)
            let shift = travel - CGFloat(first) * rowHeight
            ZStack(alignment: .topLeading) {
                ForEach(0..<visible, id: \.self) { k in
                    let index = first + k
                    let source = ResearchSource.all[index % ResearchSource.all.count]
                    row(source)
                        .frame(width: style.boxWidth)
                        .offset(y: CGFloat(k) * rowHeight - shift)
                        .opacity(index < linksShown ? 1 : 0)
                }
            }
            .frame(width: style.boxWidth, height: rowHeight * 5.5, alignment: .topLeading)
            .clipped()
            // Fading out at the foot, where the next ones come in
            .mask(LinearGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.8),
                                         .init(color: .black.opacity(0), location: 1)],
                                 startPoint: .top, endPoint: .bottom))
        }
    }

    private func row(_ source: ResearchSource) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                SourceLogo(domain: source.domain)
                    .padding(.trailing, 9)
                Text(source.title)
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(Self.text.opacity(0.67))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: 201, alignment: .leading)
                Spacer(minLength: 5)
                Text(source.domain)
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(Self.text.opacity(0.47))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: 43)
            Self.line.frame(height: 1)
        }
    }
}

/// The research's progress (148:6544), 334 × 21: a 277pt track that fills as the time left counts down beside it
struct ResearchTimer: View {
    let started: Date
    let duration: TimeInterval

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = min(max(context.date.timeIntervalSince(started), 0), duration)
            let left = Int(ceil(duration - elapsed))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: 0x262626).opacity(0.11))
                    .frame(width: 277, height: 7)
                Capsule()
                    .fill(Color(hex: 0x262626))
                    .frame(width: max(7, 277 * elapsed / duration), height: 7)
                Text(String(format: "%02d:%02d", left / 60, left % 60))
                    .font(FigmaFont.walsheim(13))
                    .tracking(1.43)
                    .monospacedDigit()
                    .foregroundStyle(Color.black)
                    .frame(width: 334, height: 21, alignment: .trailing)
            }
            .frame(width: 334, height: 21, alignment: .leading)
        }
    }
}

private extension View {
    /// Comes in from a little below, fading up
    func arriving(_ arrived: Bool) -> some View {
        opacity(arrived ? 1 : 0)
            .offset(y: arrived ? 0 : 14)
            .scaleEffect(arrived ? 1 : 0.98, anchor: .top)
    }
}

/// A source's site logo, 17 × 17. HDFC's comes with the app; the rest are fetched from the site's favicon, with the
/// site's initial standing in until it arrives.
struct SourceLogo: View {
    let domain: String

    var body: some View {
        Group {
            if domain == "hdfc.co.in" {
                Image("ResearchHDFC").resizable()
            } else {
                AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=64")) { image in
                    image.resizable()
                } placeholder: {
                    Text(domain.prefix(1).uppercased())
                        .font(FigmaFont.walsheimMedium(10))
                        .foregroundStyle(Color.black.opacity(0.5))
                        .frame(width: 17, height: 17)
                        .background(Color.black.opacity(0.06))
                }
            }
        }
        .frame(width: 17, height: 17)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
    }
}

/// One web page the agent read
struct ResearchSource: Identifiable {
    let id: Int
    let title: String
    let domain: String

    /// 807 of them, made up from the kinds of pages a fund research run reads, spread across the sites it reads them on
    static let all: [ResearchSource] = {
        let sites: [(domain: String, pages: [String])] = [
            ("hdfc.co.in", ["%@ direct growth - NAV", "%@ - monthly portfolio", "%@ - scheme factsheet"]),
            ("cbinsights.com", ["Friday, Jan CBInsights.com", "State of fintech: India Q4", "Asset managers to watch"]),
            ("valueresearchonline.com", ["%@ - fund review", "%@ - risk and return", "Best midcap funds this year"]),
            ("morningstar.in", ["%@ - Morningstar rating", "%@ - portfolio holdings", "Fund flows: January"]),
            ("amfiindia.com", ["Monthly AAUM disclosure", "%@ - NAV history", "Industry SIP book, January"]),
            ("sebi.gov.in", ["Mutual fund categorisation circular", "Total expense ratio norms", "Riskometer guidelines"]),
            ("moneycontrol.com", ["%@ - performance", "Midcaps rally as FIIs return", "%@ - peer comparison"]),
            ("economictimes.indiatimes.com", ["Smallcap valuations stretched?", "%@ sees record inflows", "SIP flows hit new high"]),
            ("livemint.com", ["How to read a factsheet", "Midcap funds: what to expect", "%@ manager interview"]),
            ("nseindia.com", ["Nifty Midcap 150 - TRI", "Index rebalancing notice", "Market turnover, January"]),
            ("bseindia.com", ["S&P BSE Midcap - factsheet", "Sectoral indices, January", "Corporate actions"]),
            ("rbi.org.in", ["Monetary policy statement", "Bulletin: liquidity conditions", "Inflation expectations survey"]),
            ("business-standard.com", ["%@ trims banking exposure", "Fund houses bet on capex", "Midcap earnings season"]),
            ("reuters.com", ["India equities: foreign flows", "Rupee steadies ahead of policy", "Asia markets wrap"]),
            ("bloomberg.com", ["India's mutual fund boom", "Midcap premium widens", "Emerging market flows"]),
            ("icicipruamc.com", ["%@ - scheme information document", "Market outlook, January", "Equity valuation index"]),
            ("sbimf.com", ["%@ - key information memorandum", "Monthly fund factsheet", "Debt market update"]),
            ("axismf.com", ["%@ - portfolio disclosure", "Equity market outlook", "Fixed income outlook"]),
            ("kotakmf.com", ["%@ - riskometer", "Market pulse, January", "Kotak midcap strategy note"]),
            ("crisil.com", ["Mutual fund ranking, December", "%@ - CRISIL rank", "Industry AUM outlook"]),
            ("tickertape.in", ["%@ - holdings analysis", "Midcap screener", "Sector allocation trends"]),
            ("groww.in", ["%@ - returns calculator", "%@ - expense ratio", "Top rated midcap funds"]),
            ("niftyindices.com", ["Nifty Midcap 150 methodology", "Index dashboard, January", "Factor index returns"]),
            ("ft.com", ["Indian stocks lure global funds", "Valuations test India's rally", "Asset management outlook"]),
        ]
        let funds = [
            "HDFC Midcap fund", "Kotak Emerging Equity", "Axis Midcap fund", "SBI Magnum Midcap", "Nippon India Growth",
            "Motilal Oswal Midcap", "ICICI Pru Midcap", "PGIM Midcap Opportunities", "Edelweiss Midcap", "DSP Midcap",
        ]
        return (0..<807).map { i in
            let site = sites[(i * 7 + i / sites.count) % sites.count]
            let page = site.pages[(i / sites.count) % site.pages.count]
            let title = page.contains("%@") ? String(format: page, funds[(i / 3) % funds.count]) : page
            return ResearchSource(id: i, title: title, domain: site.domain)
        }
    }()
}

#Preview {
    ResearchSheet()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.3))
}

/// A soft band of light that sweeps across text every couple of seconds, for something still at work
private struct Shimmer: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.overlay {
                TimelineView(.animation) { context in
                    // A 1.1s sweep, then a 0.9s rest
                    let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2)
                    let phase = min(t / 1.1, 1)
                    GeometryReader { geo in
                        let band = geo.size.width * 0.6
                        LinearGradient(colors: [.white.opacity(0), .white.opacity(0.6), .white.opacity(0)],
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: band)
                            .offset(x: -band + (geo.size.width + band) * phase)
                    }
                    .mask(content)
                }
                .allowsHitTesting(false)
            }
        } else {
            content
        }
    }
}

extension View {
    func shimmering(_ active: Bool) -> some View { modifier(Shimmer(active: active)) }
}

/// A soft, slow pulse in opacity, for something still being worked on
private struct Pulse: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        TimelineView(.animation(paused: !active)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            content.opacity(active ? 0.8 + 0.2 * cos(t * .pi / 0.7) : 1)
        }
    }
}

extension View {
    func pulsing(_ active: Bool) -> some View { modifier(Pulse(active: active)) }
}
