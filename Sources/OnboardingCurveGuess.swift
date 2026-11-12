import SwiftUI

/// "While it happens" (312:16623): draw any curve, and it finds the fund whose NAV moved most like it, over the last
/// year or the last five, out of 51 real ones. When it has it, the glass band sweeps across and shows the fund's
/// line, with what was drawn dashed over it.
struct CurveGuess: View {
    static let width: CGFloat = 368
    private static let box = CGSize(width: 342, height: 234)

    @State private var stroke: [CGPoint] = []
    @State private var match: CurveMatch?
    @State private var matchedAt = Date.distantPast
    /// When the band set off back to an empty box, for the next one
    @State private var returnedAt: Date?

    /// The point runs along the fund's line once, this slowly; 3s after it's done, back to drawing
    private static let run = 2.2
    private static var holdsFor: Double { 0.5 + 0.6 + run + 3 }

    var body: some View {
        ZStack(alignment: .top) {
            Text("While it happens")
                .font(FigmaFont.walsheim(23))
                .foregroundStyle(Color(hex: 0x212121))
                .frame(height: 31)
            Text("Draw any curve and we will tell which fund is it")
                .font(FigmaFont.walsheim(17))
                .lineSpacing(25 - 17 * 1.2)
                .foregroundStyle(Color(hex: 0x212121).opacity(0.75))
                .multilineTextAlignment(.center)
                .frame(width: 270)
                .padding(.top, 36)
            TimelineView(.animation) { context in
                let shown = context.date.timeIntervalSince(matchedAt)
                if let returnedAt, let match {
                    // and back again, the fund giving way to an empty box
                    let raw = min(1, max(0, context.date.timeIntervalSince(returnedAt) / 1.0))
                    HeatSweep(sweep: CGFloat(raw * raw * (3 - 2 * raw)), forward: true,
                              width: Self.box.width, height: Self.box.height, contentHeight: Self.box.height) {
                        result(match, t: max(0, shown - 0.5))
                    } after: {
                        canvas
                    }
                } else {
                    let raw = match == nil ? 0 : min(1, max(0, shown / 1.0))
                    // The same glass band as "Adjust to what feels comfortable", across the box
                    HeatSweep(sweep: CGFloat(raw * raw * (3 - 2 * raw)), forward: true,
                              width: Self.box.width, height: Self.box.height, contentHeight: Self.box.height) {
                        canvas
                    } after: {
                        if let match { result(match, t: max(0, shown - 0.5)) }
                    }
                }
            }
            .task(id: matchedAt) {
                guard match != nil else { return }
                try? await Task.sleep(for: .seconds(Self.holdsFor))
                guard !Task.isCancelled, match != nil else { return }
                stroke = []
                returnedAt = .now
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { return }
                match = nil
                returnedAt = nil
            }
            .frame(width: Self.box.width, height: Self.box.height)
            .padding(.top, 103)
            if match != nil && returnedAt == nil {
                Button {
                    Haptics.tap()
                    withAnimation(.easeOut(duration: 0.25)) {
                        match = nil
                        stroke = []
                        returnedAt = nil
                    }
                } label: {
                    Text("Draw another")
                        .font(FigmaFont.walsheim(15))
                        .foregroundStyle(Color.black.opacity(0.6))
                        .frame(height: 21)
                }
                .buttonStyle(.plain)
                .padding(.top, 103 + Self.box.height + 10)
                .transition(.opacity)
            }
        }
        .frame(width: Self.width, alignment: .top)
    }

    // MARK: Drawing

    private var canvas: some View {
        ZStack {
            Color.white
            Rectangle()
                .strokeBorder(Color.black.opacity(0.26), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
            if stroke.isEmpty {
                Text("Draw here")
                    .font(FigmaFont.walsheim(15))
                    .foregroundStyle(Color.black.opacity(0.25))
            }
            Path { path in
                guard let first = stroke.first else { return }
                path.move(to: first)
                for point in stroke.dropFirst() { path.addLine(to: point) }
            }
            .stroke(Color(hex: 0x212121), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
        .frame(width: Self.box.width, height: Self.box.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard match == nil else { return }
                    if value.translation == .zero { stroke = [] }
                    let p = CGPoint(x: min(max(value.location.x, 3), Self.box.width - 3),
                                    y: min(max(value.location.y, 3), Self.box.height - 3))
                    stroke.append(p)
                }
                .onEnded { _ in finish() }
        )
        .accessibilityElement()
        .accessibilityLabel("Drawing area")
        .accessibilityIdentifier("CurveCanvas")
    }

    /// Lifted: if it's a curve across a fair part of the box, find its fund
    private func finish() {
        guard match == nil else { return }
        let xs = stroke.map(\.x)
        guard let lo = xs.min(), let hi = xs.max(), hi - lo > Self.box.width * 0.35,
              let found = CurveMatch.closest(to: stroke) else {
            withAnimation(.easeOut(duration: 0.2)) { stroke = [] }
            return
        }
        Haptics.thresholdCrossed()
        match = found
        matchedAt = .now
    }

    // MARK: The fund

    private func result(_ m: CurveMatch, t: Double) -> some View {
        ZStack(alignment: .topLeading) {
            Color(hex: 0xFEFEFE)
            HStack(spacing: 6) {
                Text("This is the fund")
                    .foregroundStyle(Color.black)
                Text("\(m.score)% match")
                    .foregroundStyle(Color.black.opacity(0.35))
            }
            .font(FigmaFont.walsheim(13))
            .frame(height: 17)
            .at(13, 6)
            NAVLineChart(title: m.fund.name, navs: m.navs, dates: m.dates, caption: m.period,
                         overlay: m.drawn, t: t, width: Self.box.width, plotHeight: 112, runOnce: Self.run)
                .offset(y: 14)
        }
        .frame(width: Self.box.width, height: Self.box.height, alignment: .topLeading)
        .clipShape(Rectangle())
        .overlay(Rectangle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
    }
}

// MARK: The funds, and the match

/// One fund's real NAV over the last year and the last five (AMFI NAV history via api.mfapi.in), bundled as
/// fund_curves.json
struct FundCurve: Decodable {
    struct Window: Decodable {
        let from: String
        let navs: [Double]
        var full: Bool?
    }
    let name: String
    let scheme: String
    let asOf: String
    let nav: Double
    let oneYear: Window
    let fiveYear: Window?

    static let all: [FundCurve] = {
        struct File: Decodable { let funds: [FundCurve] }
        guard let url = Bundle.main.url(forResource: "fund_curves", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }
        return file.funds
    }()
}

struct CurveMatch {
    let fund: FundCurve
    let period: String
    let navs: [Double]
    let dates: [String]
    /// What was drawn, 0…1 from its low to its high, at the same points as the fund's line
    let drawn: [Double]
    let score: Int

    private static let samples = 48

    /// The fund and period whose shape is nearest the stroke's, both scaled to their own range
    static func closest(to stroke: [CGPoint]) -> CurveMatch? {
        guard let drawn = shape(of: stroke) else { return nil }
        var best: (fund: FundCurve, window: FundCurve.Window, period: String, distance: Double)?
        for fund in FundCurve.all {
            var windows = [(fund.oneYear, "1 year")]
            if let five = fund.fiveYear, five.full ?? false { windows.append((five, "5 years")) }
            for (window, period) in windows {
                let theirs = normalised(resampled(window.navs, to: samples))
                let distance = zip(drawn, theirs).map { ($0 - $1) * ($0 - $1) }.reduce(0, +) / Double(samples)
                if best == nil || distance < best!.distance { best = (fund, window, period, distance) }
            }
        }
        guard let best else { return nil }
        let navs = resampled(best.window.navs, to: samples)
        let score = Int((max(0, 1 - best.distance.squareRoot() / 0.5) * 100).rounded())
        return CurveMatch(fund: best.fund, period: best.period, navs: navs,
                          dates: dates(from: best.window.from, to: best.fund.asOf), drawn: drawn, score: max(score, 1))
    }

    /// The stroke as heights across its width, left to right, in 48 even steps, scaled 0…1 (up is up)
    private static func shape(of stroke: [CGPoint]) -> [Double]? {
        guard let lo = stroke.map(\.x).min(), let hi = stroke.map(\.x).max(), hi > lo else { return nil }
        var sums = [Double](repeating: 0, count: samples), counts = [Int](repeating: 0, count: samples)
        for p in stroke {
            let bin = min(samples - 1, Int(Double(p.x - lo) / Double(hi - lo) * Double(samples - 1) + 0.5))
            sums[bin] += -Double(p.y)
            counts[bin] += 1
        }
        // Fill the steps the stroke skipped, from their neighbours
        var values = [Double?](repeating: nil, count: samples)
        for i in 0..<samples where counts[i] > 0 { values[i] = sums[i] / Double(counts[i]) }
        let known = values.indices.filter { values[$0] != nil }
        guard let first = known.first, let last = known.last else { return nil }
        var filled = [Double](repeating: 0, count: samples)
        for i in 0..<samples {
            if i <= first { filled[i] = values[first]!; continue }
            if i >= last { filled[i] = values[last]!; continue }
            if let v = values[i] { filled[i] = v; continue }
            let a = known.last { $0 < i }!, b = known.first { $0 > i }!
            filled[i] = values[a]! + (values[b]! - values[a]!) * Double(i - a) / Double(b - a)
        }
        return normalised(filled)
    }

    private static func resampled(_ series: [Double], to n: Int) -> [Double] {
        (0..<n).map { i in
            let x = Double(i) * Double(series.count - 1) / Double(n - 1)
            let a = Int(x), b = min(a + 1, series.count - 1)
            return series[a] + (series[b] - series[a]) * (x - Double(a))
        }
    }

    private static func normalised(_ v: [Double]) -> [Double] {
        guard let lo = v.min(), let hi = v.max(), hi - lo > 1e-9 else { return v.map { _ in 0.5 } }
        return v.map { ($0 - lo) / (hi - lo) }
    }

    /// Its first, middle and last months, as "Nov 2025"
    private static func dates(from: String, to: String) -> [String] {
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"
        let out = DateFormatter()
        out.dateFormat = "MMM yyyy"
        guard let a = iso.date(from: from), let b = iso.date(from: to) else { return [from, "", to] }
        let mid = a.addingTimeInterval(b.timeIntervalSince(a) / 2)
        return [a, mid, b].map(out.string(from:))
    }
}

#Preview {
    CurveGuess()
        .padding(.top, 40)
}
