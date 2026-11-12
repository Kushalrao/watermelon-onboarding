import SwiftUI

/// What shows under the plan chip while the research runs (270:16266 onwards): a line saying what it's doing, and,
/// now and then, a card running quickly through the data it's going over. It reads sites (with their icons), then
/// captures fund reports as a chart per fund, compares returns fund by fund, scans holdings as a scrolling list of
/// bars, and maps sectors as blocks that build and settle, then goes back to reading.
struct ResearchLive: View {
    let started: Date
    /// The card's height as it changes, so the chat can keep it in view
    var onHeight: (CGFloat) -> Void = { _ in }

    enum Phase: Equatable {
        case reading, capturing, comparing, scanning, mapping

        /// What it's doing, and to what
        var status: (verb: String, object: String) {
            switch self {
            case .reading: ("Reading", "")
            case .capturing: ("Capturing", "NAV history")
            case .comparing: ("Comparing", "Returns")
            case .scanning: ("Scanning", "HDFC Mid Cap holdings")
            case .mapping: ("Mapping", "HDFC Mid Cap sectors")
            }
        }

        /// The card's height for it; reading has none
        var cardHeight: CGFloat {
            switch self {
            case .reading: 0
            case .capturing: 207
            case .comparing: 118
            case .scanning: 164
            case .mapping: 281
            }
        }
    }

    /// When each phase begins, in seconds after the research started
    static let timeline: [(at: Double, phase: Phase)] = [
        (0, .reading), (3, .capturing), (7, .comparing), (10, .scanning), (13, .mapping), (16, .reading),
    ]

    @State private var phase = Phase.reading
    /// When the current phase began, for its own motion
    @State private var phaseStarted = Date.now
    /// The visual being swept away, and when it began, while the glass band crosses to the next
    /// (the heat sweep from "Adjust to what feels comfortable")
    @State private var leaving: (phase: Phase, started: Date)?
    /// When the band set off; it takes a second to cross
    @State private var sweepStarted = Date.distantPast
    private static let sweepTime = 1.0

    static let cardWidth: CGFloat = 340
    /// The card's height, eased between visuals
    @State private var cardHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            statusLine
                .padding(.leading, 11)
            if phase != .reading {
                VStack(alignment: .leading, spacing: 8) {
                    card
                    // Where the data comes from (286:16524)
                    MorningstarMark().padding(.leading, 11)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            }
        }
        .task {
            for (at, next) in Self.timeline {
                let wait = at - Date.now.timeIntervalSince(started)
                if wait > 0 { try? await Task.sleep(for: .seconds(wait)) }
                guard !Task.isCancelled else { return }
                if next != phase || at == 0 {
                    if phase != .reading && next != .reading {
                        // One visual to the next: the glass band sweeps across, the card resizing with it
                        var quiet = Transaction()
                        quiet.disablesAnimations = true
                        withTransaction(quiet) {
                            leaving = (phase, phaseStarted)
                            sweepStarted = .now
                            phase = next
                            phaseStarted = .now
                        }
                        withAnimation(.easeInOut(duration: Self.sweepTime)) { cardHeight = next.cardHeight }
                    } else {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                            phase = next
                            phaseStarted = .now
                            cardHeight = next.cardHeight
                        }
                    }
                    onHeight(next.cardHeight)
                }
            }
        }
    }

    @ViewBuilder private func visual(_ phase: Phase, t: Double) -> some View {
        switch phase {
        case .capturing: FundChart(t: t)
        case .comparing: ReturnsTable(t: t)
        case .scanning: HoldingBars(t: t)
        case .mapping: SectorBlocks(t: t)
        case .reading: EmptyView()
        }
    }

    // MARK: The line

    /// "Capturing Fund reports" (274:3222): the verb in black, its object greyed; reading names each site with its
    /// icon, a new one every 0.6s
    private var statusLine: some View {
        TimelineView(.periodic(from: started, by: 0.6)) { context in
            let step = Int(context.date.timeIntervalSince(started) / 0.6)
            HStack(spacing: 6) {
                if phase == .reading {
                    let source = ResearchSource.all[(step * 3 + 5) % ResearchSource.all.count]
                    SourceLogo(domain: source.domain)
                        .scaleEffect(15 / 17)
                        .frame(width: 15, height: 15)
                    Text("Reading")
                        .foregroundStyle(Color.black)
                    Text(source.domain)
                        .foregroundStyle(Color.black.opacity(0.35))
                        .lineLimit(1)
                        .id(source.domain)
                        .transition(.opacity)
                } else {
                    Text(phase.status.verb)
                        .foregroundStyle(Color.black)
                    Text(phase.status.object)
                        .foregroundStyle(Color.black.opacity(0.35))
                }
            }
            .font(FigmaFont.walsheim(15))
            .frame(height: 21)
            .contentTransition(.opacity)
        }
    }

    // MARK: The card

    private var card: some View {
        let shape = RoundedRectangle(cornerRadius: 23, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Color(hex: 0xFEFEFE)
            TimelineView(.animation) { context in
                let raw = min(1, max(0, context.date.timeIntervalSince(sweepStarted) / Self.sweepTime))
                // eased in and out, as the slider's sweep is
                let sweep = CGFloat(raw * raw * (3 - 2 * raw))
                HeatSweep(sweep: sweep, forward: true, width: Self.cardWidth, height: cardHeight,
                          contentHeight: max(phase.cardHeight, leaving?.phase.cardHeight ?? 0)) {
                    if let leaving, sweep < 1 {
                        visual(leaving.phase, t: context.date.timeIntervalSince(leaving.started))
                    }
                } after: {
                    visual(phase, t: context.date.timeIntervalSince(phaseStarted))
                }
            }
        }
        .frame(width: Self.cardWidth, height: cardHeight, alignment: .topLeading)
        .clipShape(shape)
        // 274:3198: a soft shadow on the inside
        .overlay(shape.stroke(Color.black.opacity(0.03), lineWidth: 6).blur(radius: 10).clipShape(shape))
    }
}

// MARK: Data
//
// Real figures, from public NAV and portfolio listings (5paisa, Coin by Zerodha, Sharpely, Dezerv, PolicyBazaar),
// for the direct growth plans, as dated beside each.

/// A fund's NAV over some real dates
private struct NAVSeries {
    let fund: String
    let points: [(date: String, nav: Double)]

    var first: Double { points.first!.nav }
    var last: Double { points.last!.nav }
    var change: Double { (last - first) / first * 100 }

    static let all: [NAVSeries] = [
        // 5paisa daily NAV posts, Sep–Oct 2026
        NAVSeries(fund: "SBI Contra", points: [
            ("3 Sep", 415.18), ("4 Sep", 415.17), ("9 Sep", 409.45), ("10 Sep", 409.21), ("11 Sep", 408.97),
            ("15 Sep", 403.77), ("18 Sep", 408.33), ("24 Sep", 411.70), ("25 Sep", 406.00), ("30 Sep", 397.65),
            ("9 Oct", 392.26), ("14 Oct", 391.08), ("23 Oct", 387.11), ("26 Oct", 389.60), ("28 Oct", 390.08),
        ]),
        // 5paisa and Coin by Zerodha, Oct–Nov 2026
        NAVSeries(fund: "Nippon India Small Cap", points: [("23 Oct", 189.21), ("26 Oct", 190.99), ("3 Nov", 196.56)]),
        // PolicyBazaar and Sharpely, Sep–Oct 2026
        NAVSeries(fund: "Axis Small Cap", points: [("4 Sep", 137.66), ("15 Sep", 134.20), ("1 Oct", 132.52)]),
    ]
}

/// NAV and trailing returns
private struct FundReturns {
    let fund: String, asOf: String
    let nav: Double
    let returns: [Double]

    static let all: [FundReturns] = [
        // Coin by Zerodha / Sharpely / 5paisa, 3 Nov 2026
        FundReturns(fund: "Nippon India Small Cap", asOf: "3 Nov", nav: 196.56, returns: [1.53, 13.07, 17.01]),
        // 5paisa, 28 Oct 2026
        FundReturns(fund: "SBI Contra", asOf: "28 Oct", nav: 390.08, returns: [-9.19, 10.09, 12.95]),
    ]
}

func rupees(_ value: Double) -> String { String(format: "₹%.2f", value) }
func percent(_ value: Double) -> String { String(format: "%.2f%%", value) }

// MARK: Capturing: a fund's NAV, drawn, then running (270:16266)

private struct FundChart: View {
    let t: Double
    /// Each fund's line draws in, then a point keeps running along it, before the next
    private static let perFund = 4.0 / Double(NAVSeries.all.count)

    var body: some View {
        let index = Int(t / Self.perFund) % NAVSeries.all.count
        let series = NAVSeries.all[index]
        let p = series.points
        NAVLineChart(title: series.fund, navs: p.map(\.nav),
                     dates: [p.first!.date, p[p.count / 2].date, p.last!.date],
                     t: t.truncatingRemainder(dividingBy: Self.perFund))
    }
}

/// A fund's NAV as a line (270:16266): its name, the latest NAV and the change, the line drawn in and then a point
/// running along it, the high and low down the right, and dates along the foot. Optionally with another curve
/// dashed over it, scaled the same way, to set one shape against the other.
struct NAVLineChart: View {
    let title: String
    let navs: [Double]
    /// The first, middle and last dates
    let dates: [String]
    /// Beside the change, e.g. which period it covers
    var caption: String? = nil
    /// Another shape, 0…1 from its low to its high, laid over the line on the same scale
    var overlay: [Double]? = nil
    /// Seconds since it was shown
    let t: Double
    var width: CGFloat = 340
    var plotHeight: CGFloat = 100
    /// The point runs along it once, over this long, and rests at the end; otherwise it keeps going round
    var runOnce: Double? = nil

    private var change: Double { (navs.last! - navs.first!) / navs.first! * 100 }

    var body: some View {
        let low = navs.min()!, high = navs.max()!
        let span = max(high - low, 0.01)
        // A little room above and below the line
        let floor = low - span * 0.15, ceiling = high + span * 0.15
        let plotWidth = width - 70
        ZStack(alignment: .topLeading) {
            Text(title)
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Color.black.opacity(0.57))
                .lineLimit(1)
                .frame(width: width - 26, height: 19, alignment: .leading)
                .at(13, 13)
            HStack(spacing: 6) {
                Text(rupees(navs.last!))
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color.black)
                Text((change >= 0 ? "+" : "") + percent(change))
                    .font(FigmaFont.walsheimMedium(13))
                    .foregroundStyle(change >= 0 ? Color(hex: 0x38C314) : Color(hex: 0xE3521B))
                if let caption {
                    Text(caption)
                        .font(FigmaFont.walsheim(13))
                        .foregroundStyle(Color.black.opacity(0.4))
                }
            }
            .frame(height: 21)
            .at(13, 35)
            plot(floor: floor, ceiling: ceiling, low: low, span: span)
                .frame(width: plotWidth, height: plotHeight)
                .at(13, 62)
            ForEach(Array([high, low].enumerated()), id: \.offset) { _, nav in
                Text(rupees(nav))
                    .font(FigmaFont.walsheim(12))
                    .tracking(0.4)
                    .foregroundStyle(Color.black.opacity(0.4))
                    .frame(width: 60, height: 17, alignment: .trailing)
                    .at(width - 60 - 6, 62 + plotHeight * (1 - (nav - floor) / (ceiling - floor)) - 8.5)
            }
            HStack(spacing: 0) {
                ForEach(Array(dates.enumerated()), id: \.offset) { i, date in
                    Text(date)
                    if i < dates.count - 1 { Spacer(minLength: 0) }
                }
            }
            .font(FigmaFont.walsheim(12))
            .tracking(0.4)
            .foregroundStyle(Color.black.opacity(0.6))
            .frame(width: plotWidth, height: 17)
            .at(13, 62 + plotHeight + 14)
            Rectangle().fill(Color.black.opacity(0.12)).frame(width: width, height: 0.7).at(0, 62 + plotHeight + 6)
        }
        .frame(width: width, height: 62 + plotHeight + 14 + 17 + 12, alignment: .topLeading)
    }

    private func plot(floor: Double, ceiling: Double, low: Double, span: Double) -> some View {
        let drawn = min(1, max(0, t / 0.6))
        return GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let y = { (nav: Double) in h * (1 - (nav - floor) / (ceiling - floor)) }
            let points = navs.enumerated().map { i, nav in CGPoint(x: w * Double(i) / Double(navs.count - 1), y: y(nav)) }
            let line = Self.smooth(points)
            let tint = change >= 0 ? Color(hex: 0x3FD519) : Color(hex: 0xE3521B)
            // Once drawn, a point runs along it, over and over
            let along = drawn < 1 ? drawn
                : runOnce.map { min(1, (t - 0.6) / $0) } ?? ((t - 0.6) / 0.9).truncatingRemainder(dividingBy: 1)
            let dot = line.trimmedPath(from: 0, to: max(0.001, along)).currentPoint ?? points[0]
            ZStack(alignment: .topLeading) {
                Path { path in
                    path.addPath(line)
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [tint.opacity(0.25), tint.opacity(0)], startPoint: .top, endPoint: .bottom))
                .mask(alignment: .leading) { Rectangle().frame(width: w * drawn) }
                if let overlay, overlay.count > 1 {
                    let theirs = overlay.enumerated().map { i, u in
                        CGPoint(x: w * Double(i) / Double(overlay.count - 1), y: y(low + u * span))
                    }
                    Self.smooth(theirs)
                        .stroke(Color.black.opacity(0.35), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [4, 4]))
                }
                line
                    .trim(from: 0, to: drawn)
                    .stroke(tint, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
                    .background(Circle().fill(tint.opacity(0.25)).frame(width: 18, height: 18))
                    .position(dot)
            }
        }
    }

    static func smooth(_ points: [CGPoint]) -> Path {
        Path { path in
            path.move(to: points[0])
            for i in 1..<points.count {
                let a = points[i - 1], b = points[i]
                let dx = (b.x - a.x) / 2
                path.addCurve(to: b, control1: CGPoint(x: a.x + dx, y: a.y), control2: CGPoint(x: b.x - dx, y: b.y))
            }
        }
    }
}

// MARK: Comparing: NAV and returns, fund by fund (274:3300)

private struct ReturnsTable: View {
    let t: Double

    var body: some View {
        let index = Int(t / 1.5) % FundReturns.all.count
        let fund = FundReturns.all[index]
        ZStack(alignment: .topLeading) {
            HStack(spacing: 6) {
                Text(fund.fund)
                    .foregroundStyle(Color.black)
                Text(fund.asOf)
                    .foregroundStyle(Color.black.opacity(0.35))
            }
            .font(FigmaFont.walsheim(17))
            .frame(height: 21)
            .at(13, 13)
            Rectangle().fill(Color.black.opacity(0.12)).frame(width: 340, height: 0.7).at(0, 47)
            ForEach(Array(["NAV", "1 year", "3 years", "5 years"].enumerated()), id: \.offset) { i, period in
                let x = 13 + CGFloat(i) * 85
                Text(period)
                    .font(FigmaFont.walsheim(15))
                    .foregroundStyle(Color.black.opacity(0.57))
                    .frame(height: 19)
                    .at(x, 56)
                Group {
                    if i == 0 {
                        Text(rupees(fund.nav))
                            .font(FigmaFont.walsheimMedium(15))
                            .tracking(0.4)
                            .foregroundStyle(Color.black)
                            .frame(height: 21)
                    } else {
                        value(fund.returns[i - 1])
                    }
                }
                .at(x, 78)
            }
        }
        // One fund to the next as a whole, so no figure is ever half one and half the other
        .id(index)
        .transition(.opacity)
        .animation(.easeOut(duration: 0.25), value: index)
    }

    /// With an arrow, green up or orange down
    private func value(_ r: Double) -> some View {
        HStack(spacing: 2) {
            Triangle()
                .fill(r < 0 ? Color(hex: 0xE3521B) : Color(hex: 0x38C314))
                .frame(width: 8.5, height: 4.6)
                .rotationEffect(.degrees(r < 0 ? 180 : 0))
                .frame(width: 15, height: 15)
            Text(percent(r))
                .font(FigmaFont.walsheimMedium(15))
                .tracking(0.75)
                .foregroundStyle(r < 0 ? Color(hex: 0xE3521B) : Color(hex: 0x38C314))
        }
        .frame(height: 21)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: Scanning: a fund's top holdings, rolling (274:3397)

private struct HoldingBars: View {
    let t: Double

    /// HDFC Mid Cap Fund's largest holdings, % of the fund, 30 Sep 2026 (Dezerv)
    private struct Holding { let ticker: String, name: String, domain: String, weight: Double }
    private static let holdings: [Holding] = [
        Holding(ticker: "FEDBNK", name: "Federal Bank", domain: "federalbank.co.in", weight: 4.0),
        Holding(ticker: "AUBANK", name: "AU Small Fin.", domain: "aubank.in", weight: 3.9),
        Holding(ticker: "MFSL", name: "Max Financial", domain: "maxfinancialservices.com", weight: 3.5),
        Holding(ticker: "IPCA", name: "Ipca Labs", domain: "ipca.com", weight: 3.4),
    ]
    private static let row: CGFloat = 41
    /// The longest bar is this share of the fund
    private static let fullScale = 4.5

    var body: some View {
        // Ticks up a row at a time, like a ticker: a quick step every 0.7s, then a hold
        let first = Int(t / 0.7)
        let into = min(1, (t - Double(first) * 0.7) / 0.25)
        let shift = Self.row * CGFloat(into * into * (3 - 2 * into)) - Self.row
        ZStack(alignment: .topLeading) {
            // one row above, leaving as the next comes in at the foot
            // Each row keeps its identity as it moves, so it's the same row stepping up, not a slot redrawn
            ForEach((first - 1)..<(first + 5), id: \.self) { n in
                let holding = Self.holdings[((n % Self.holdings.count) + Self.holdings.count) % Self.holdings.count]
                rowView(holding)
                    .offset(y: CGFloat(n - first) * Self.row - shift)
            }
        }
        .frame(width: 340, height: ResearchLive.Phase.scanning.cardHeight, alignment: .topLeading)
    }

    private func rowView(_ h: Holding) -> some View {
        ZStack(alignment: .topLeading) {
            Text(h.ticker)
                .font(FigmaFont.walsheim(13 * 0.8))
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .frame(width: 52, height: 17, alignment: .leading)
                .at(15, 12)
            SourceLogo(domain: h.domain)
                .scaleEffect(15 / 17)
                .frame(width: 15, height: 15)
                .at(69, 13)
            Text(h.name)
                .font(FigmaFont.walsheim(13 * 0.8))
                .tracking(0.48)
                .foregroundStyle(Color.black.opacity(0.4))
                .lineLimit(1)
                .frame(width: 90, height: 17, alignment: .leading)
                .at(87, 12)
            Rectangle()
                .fill(Color(hex: 0x75F455))
                .frame(width: 145 * CGFloat(h.weight / Self.fullScale), height: 23)
                .at(180, 9)
            Text(String(format: "%.1f%%", h.weight))
                .font(FigmaFont.walsheim(12 * 0.8))
                .tracking(0.67)
                .foregroundStyle(Color.black.opacity(0.55))
                .frame(height: 17)
                .at(184, 12)
            Rectangle().fill(Color.black.opacity(0.08)).frame(width: 340, height: 0.7).at(0, 41)
        }
        .frame(width: 340, height: 41, alignment: .topLeading)
    }
}

// MARK: Mapping: a fund's sectors, as blocks that build, then settle to their share (274:3577)

private struct SectorBlocks: View {
    let t: Double

    /// HDFC Mid Cap Fund, % of the fund by sector, 30 Apr 2026 (aggregator data); the rest is everything else
    private struct Block { let sector: String; let share: Double; let color: UInt32; let a: CGRect; let b: CGRect }
    /// Where each lands as it builds, then its place sized to its share
    private static let blocks: [Block] = [
        Block(sector: "Financial", share: 27.2, color: 0xD4F2FA,
              a: CGRect(x: 9, y: 9, width: 147, height: 71), b: CGRect(x: 9, y: 9, width: 138, height: 162)),
        Block(sector: "Consumer", share: 16.4, color: 0xB0FA9D,
              a: CGRect(x: 9, y: 85, width: 147, height: 106), b: CGRect(x: 9, y: 176, width: 138, height: 96)),
        Block(sector: "Healthcare", share: 14.7, color: 0xFAF7D4,
              a: CGRect(x: 9, y: 196, width: 147, height: 76), b: CGRect(x: 152, y: 125, width: 80, height: 147)),
        Block(sector: "Industrials", share: 9.9, color: 0xD4F2FA,
              a: CGRect(x: 161, y: 9, width: 97, height: 93), b: CGRect(x: 237, y: 125, width: 52, height: 147)),
        Block(sector: "Tech", share: 7.8, color: 0xB0FA9D,
              a: CGRect(x: 263, y: 9, width: 68, height: 93), b: CGRect(x: 294, y: 125, width: 37, height: 147)),
        Block(sector: "Others", share: 24.0, color: 0xFAF7D4,
              a: CGRect(x: 161, y: 107, width: 170, height: 165), b: CGRect(x: 152, y: 9, width: 179, height: 111)),
    ]

    var body: some View {
        // Each lands 0.25s after the last; 0.5s after they're all in, they settle to their shares
        let settle = ease((t - (0.25 * Double(Self.blocks.count) + 0.5)) / 0.8)
        ZStack(alignment: .topLeading) {
            ForEach(Array(Self.blocks.enumerated()), id: \.offset) { i, block in
                let landed = ease((t - 0.25 * Double(i)) / 0.35)
                let rect = mix(block.a, block.b, settle)
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color(hex: block.color))
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(block.sector)
                                .font(FigmaFont.walsheim(13))
                                .foregroundStyle(Color.black.opacity(0.6))
                            Text(String(format: "%.1f%%", block.share))
                                .font(FigmaFont.walsheimMedium(rect.width > 70 ? 17 : 13))
                                .foregroundStyle(Color.black.opacity(0.85))
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 7)
                        .padding(.top, 7)
                        .opacity(rect.width > 34 && rect.height > 40 ? 1 : 0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .frame(width: max(0, rect.width), height: max(0, rect.height))
                    .scaleEffect(0.6 + 0.4 * landed, anchor: .topLeading)
                    .opacity(landed)
                    .at(rect.minX, rect.minY)
            }
        }
        .frame(width: 340, height: 281, alignment: .topLeading)
    }

    private func ease(_ x: Double) -> CGFloat {
        let c = min(max(x, 0), 1)
        return CGFloat(c * c * (3 - 2 * c))
    }

    private func mix(_ a: CGRect, _ b: CGRect, _ k: CGFloat) -> CGRect {
        CGRect(x: a.minX + (b.minX - a.minX) * k, y: a.minY + (b.minY - a.minY) * k,
               width: a.width + (b.width - a.width) * k, height: a.height + (b.height - a.height) * k)
    }
}

/// What shows under "Creating analysis" while it works: one line at a time, in the research's style
struct AnalysisLive: View {
    let started: Date
    let duration: Double

    private static let steps: [(verb: String, object: String)] = [
        ("Ranking", "funds in their category"),
        ("Checking", "star ratings against returns"),
        ("Tracing", "fund rank movements"),
        ("Matching", "labels to holdings"),
        ("Reviewing", "fund manager changes"),
        ("Weighing", "risk and costs"),
        ("Writing", "the analysis"),
    ]

    @State private var index = 0

    var body: some View {
        HStack(spacing: 6) {
            Text(Self.steps[index].verb).foregroundStyle(Color.black)
            Text(Self.steps[index].object).foregroundStyle(Color.black.opacity(0.35))
        }
        .font(FigmaFont.walsheim(15))
        .frame(height: 21)
        .id(index)
        .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 6)), removal: .opacity))
        .task {
            // The steps spread evenly over the analysis, however long it takes
            let each = max(duration, 0.1) / Double(Self.steps.count)
            index = min(Self.steps.count - 1, Int(Date.now.timeIntervalSince(started) / each))
            while index < Self.steps.count - 1 {
                let next = started.addingTimeInterval(each * Double(index + 1)).timeIntervalSinceNow
                if next > 0 { try? await Task.sleep(for: .seconds(next)) }
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.35)) { index += 1 }
            }
        }
    }
}

/// "Data from Morningstar" (286:16524): the wordmark and a grey line, wherever data's being fetched or shown
struct MorningstarMark: View {
    var body: some View {
        HStack(spacing: 3) {
            Image("MorningstarMark")
                .resizable()
                .frame(width: 46, height: 13)
            Text("Data from Morningstar")
                .font(FigmaFont.walsheim(12))
                .foregroundStyle(Color.black.opacity(0.35))
                .fixedSize()
        }
        .frame(height: 15)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Data from Morningstar")
    }
}

#Preview {
    ResearchLive(started: .now)
        .frame(width: 374, height: 400, alignment: .top)
}
