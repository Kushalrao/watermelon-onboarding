import SwiftUI

// MARK: - NAV history (HSBC Midcap Fund – Direct Plan – Growth, AMFI 151036)

struct NAVPoint {
    let date: Date
    let nav: Double
}

/// Daily NAVs bundled in `hsbc_midcap_nav.json` (from api.mfapi.in/mf/151036). The scheme code starts on
/// 28 Nov 2022, when HSBC's mid cap fund took over the L&T Midcap scheme, so 5Y and All both begin there.
enum NAVHistory {
    static let points: [NAVPoint] = {
        struct File: Decodable { let dates: [String]; let navs: [Double] }
        guard let url = Bundle.main.url(forResource: "hsbc_midcap_nav", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else { return [] }
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        return zip(file.dates, file.navs).compactMap { d, v in parser.date(from: d).map { NAVPoint(date: $0, nav: v) } }
    }()

    static func points(for period: ChartPeriod) -> [NAVPoint] {
        guard let last = points.last, let start = period.start(from: last.date) else { return points }
        let slice = points.filter { $0.date >= start }
        return slice.count > 1 ? slice : points
    }
}

enum ChartPeriod: String, CaseIterable {
    case month = "1M", sixMonths = "6M", year = "1Y", threeYears = "3Y", fiveYears = "5Y", all = "All"

    func start(from end: Date) -> Date? {
        let cal = Calendar.current
        switch self {
        case .month: return cal.date(byAdding: .month, value: -1, to: end)
        case .sixMonths: return cal.date(byAdding: .month, value: -6, to: end)
        case .year: return cal.date(byAdding: .year, value: -1, to: end)
        case .threeYears: return cal.date(byAdding: .year, value: -3, to: end)
        case .fiveYears: return cal.date(byAdding: .year, value: -5, to: end)
        case .all: return nil
        }
    }

    var caption: String {
        switch self {
        case .month: "Last month"
        case .sixMonths: "Last 6 months"
        case .year: "Last year"
        case .threeYears: "Last 3 years"
        case .fiveYears, .all: "Since " + ChartFormat.day.string(from: NAVHistory.points.first?.date ?? .now)
        }
    }

    /// Format for the four dates under the chart
    var axisFormat: DateFormatter {
        switch self {
        case .month: ChartFormat.dayMonth
        case .sixMonths, .year: ChartFormat.month
        case .threeYears, .fiveYears, .all: ChartFormat.monthYear
        }
    }
}

enum ChartFormat {
    private static func make(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = format
        f.locale = Locale(identifier: "en_IN")
        return f
    }
    static let day = make("d MMM yyyy")
    static let dayMonth = make("d MMM")
    static let month = make("MMM")
    static let monthYear = make("MMM ''yy")

    static let rupees: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_IN")
        f.maximumFractionDigits = 0
        return f
    }()
}

// MARK: - Animatable series

/// A fixed-length list of values (0 = bottom of the chart, 1 = top) SwiftUI can interpolate, so switching
/// periods morphs one line into the next.
struct ChartSeries: VectorArithmetic {
    var values: [Double]

    static let count = 90
    static var zero: ChartSeries { ChartSeries(values: []) }

    private static func combine(_ a: ChartSeries, _ b: ChartSeries, _ op: (Double, Double) -> Double) -> ChartSeries {
        let n = max(a.values.count, b.values.count)
        return ChartSeries(values: (0..<n).map { i in
            op(i < a.values.count ? a.values[i] : 0, i < b.values.count ? b.values[i] : 0)
        })
    }

    static func + (a: ChartSeries, b: ChartSeries) -> ChartSeries { combine(a, b, +) }
    static func - (a: ChartSeries, b: ChartSeries) -> ChartSeries { combine(a, b, -) }
    mutating func scale(by rhs: Double) { values = values.map { $0 * rhs } }
    var magnitudeSquared: Double { values.reduce(0) { $0 + $1 * $1 } }

    /// Resamples the period's NAVs to `count` points (bucket averages when there are more, linear
    /// interpolation when there are fewer) and normalises them to the period's low…high.
    init(points: [NAVPoint], low: Double, high: Double) {
        let navs = points.map(\.nav)
        let n = Self.count
        var out: [Double] = []
        for i in 0..<n {
            let a = Double(i) / Double(n) * Double(navs.count - 1)
            let b = Double(i + 1) / Double(n) * Double(navs.count - 1)
            if navs.count > n {
                let lo = Int(a.rounded(.down)), hi = max(lo, Int(b.rounded(.down)))
                let bucket = navs[lo...min(hi, navs.count - 1)]
                out.append(bucket.reduce(0, +) / Double(bucket.count))
            } else {
                let t = Double(i) / Double(n - 1) * Double(navs.count - 1)
                let lo = Int(t.rounded(.down)), hi = min(lo + 1, navs.count - 1)
                out.append(navs[lo] + (navs[hi] - navs[lo]) * (t - Double(lo)))
            }
        }
        // Keep the real first and last NAVs so the line starts and ends on them
        out[0] = navs.first ?? 0
        out[n - 1] = navs.last ?? 0
        let span = max(high - low, 0.0001)
        values = out.map { ($0 - low) / span }
    }

    init(values: [Double]) { self.values = values }

    /// Height (0…1) of the curve at a horizontal fraction
    func value(at fraction: Double) -> Double {
        guard values.count > 1 else { return values.first ?? 0 }
        let t = min(max(fraction, 0), 1) * Double(values.count - 1)
        let lo = Int(t.rounded(.down)), hi = min(lo + 1, values.count - 1)
        return values[lo] + (values[hi] - values[lo]) * (t - Double(lo))
    }
}

/// The NAV line (or, closed, the area under it), drawn as Catmull-Rom curves through the series
struct NAVCurve: Shape {
    var series: ChartSeries
    var closed = false

    var animatableData: ChartSeries {
        get { series }
        set { series = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let v = series.values
        guard v.count > 1 else { return Path() }
        let pts = v.enumerated().map { i, y in
            CGPoint(x: rect.minX + rect.width * CGFloat(i) / CGFloat(v.count - 1), y: rect.minY + rect.height * (1 - CGFloat(y)))
        }
        var path = Path()
        path.move(to: pts[0])
        for i in 0..<(pts.count - 1) {
            let p0 = pts[max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(i + 2, pts.count - 1)]
            path.addCurve(
                to: p2,
                control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            )
        }
        if closed {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

/// Morphs one period's line into the next as a wave that flows left to right: the wave front travels across
/// at a steady pace and each point, as it is reached, glides to its new height on a soft spring (a slight
/// overshoot, then settling), so the line looks like it is flowing into its new shape.
struct WarpingNAVCurve: Shape {
    var from: ChartSeries
    var to: ChartSeries
    /// 0 = `from`, 1 = `to`
    var progress: CGFloat
    var closed = false

    /// How far behind the right edge trails the left (as a share of the whole transition)
    private static let spread = 0.75
    /// Each point's spring: damping ratio and natural frequency (settles within its share of the time)
    private static let damping = 0.62
    private static let frequency = 9.0

    /// Under-damped spring step response, 0 → 1 over t 0…1
    private static func spring(_ t: Double) -> Double {
        guard t > 0 else { return 0 }
        guard t < 1 else { return 1 }
        let z = damping, w = frequency
        let wd = w * (1 - z * z).squareRoot()
        return 1 - exp(-z * w * t) * (cos(wd * t) + z / (1 - z * z).squareRoot() * sin(wd * t))
    }

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let n = to.values.count
        guard from.values.count == n, progress < 1 else { return NAVCurve(series: to, closed: closed).path(in: rect) }
        let values = (0..<n).map { i -> Double in
            let x = Double(i) / Double(n - 1)
            let local = Double(progress) * (1 + Self.spread) - x * Self.spread
            return from.values[i] + (to.values[i] - from.values[i]) * Self.spring(local)
        }
        return NAVCurve(series: ChartSeries(values: values), closed: closed).path(in: rect)
    }
}

// MARK: - Price card (865:13501) with the real NAV chart

struct PriceCard: View {
    @State private var period: ChartPeriod = .threeYears
    /// Index into the period's NAVs of the tapped point; nil shows the latest NAV
    @State private var selected: Int?
    /// The line being warped away from while switching periods
    @State private var previous: ChartSeries?
    @State private var warp: CGFloat = 1

    // Chart plot area inside the chart group (865:13505): the line runs from the top grid line (y 9)
    // to the bottom one (y 249), 296 wide, leaving the right edge for the price labels
    private static let plot = CGRect(x: 0, y: 9, width: 296, height: 240)
    private static let rise = Color(hex: 0x3FD519)
    private static let riseFill = Color(hex: 0x85FF66)
    private static let fall = Color(hex: 0xF53B3E)
    private static let fallFill = Color(hex: 0xFF7C5C)

    var body: some View {
        let points = NAVHistory.points(for: period)
        let navs = points.map(\.nav)
        let low = navs.min() ?? 0, high = navs.max() ?? 1
        let series = ChartSeries(points: points, low: low, high: high)
        let shown = selected.flatMap { points.indices.contains($0) ? points[$0] : nil } ?? points.last
        let start = points.first?.nav ?? 1
        let change = ((shown?.nav ?? start) / start - 1) * 100
        let rising = (points.last?.nav ?? 0) >= start
        let line = rising ? Self.rise : Self.fall
        let fill = rising ? Self.riseFill : Self.fallFill

        ZStack(alignment: .topLeading) {
            Color.white

            Text("₹")
                .font(.system(size: 35, weight: .medium))
                .foregroundStyle(Color.ink)
                .at(16, 23)

            price(shown?.nav ?? 0)
                .at(39.13, 19)

            HStack(spacing: 6) {
                Text(selected == nil ? period.caption : ChartFormat.day.string(from: shown?.date ?? .now))
                    .foregroundStyle(Color.black.opacity(0.43))
                Text(String(format: "%@%.1f%%", change >= 0 ? "+" : "−", abs(change)))
                    .foregroundStyle(change >= 0 ? Color(hex: 0x139100) : Self.fall)
                    .contentTransition(.numericText(value: change))
            }
            .font(FigmaFont.walsheim(15))
            .at(16, 65)

            // Figma: U+100360 in SF Compact Text Medium = "ellipsis"
            Image(systemName: "ellipsis")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.6))
                .at(331, 25)

            // Chart (865:13505), 336 × 281
            ZStack(alignment: .topLeading) {
                gridLine(opacity: 0.13).at(0, 9)
                gridLine(opacity: 0.13).at(0, 129)
                gridLine(opacity: 0.33).at(0, 249)

                WarpingNAVCurve(from: previous ?? series, to: series, progress: warp, closed: true)
                    .fill(LinearGradient(colors: [fill.opacity(0.6), fill.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                    .frame(width: Self.plot.width, height: Self.plot.height)
                    .at(Self.plot.minX, Self.plot.minY)

                WarpingNAVCurve(from: previous ?? series, to: series, progress: warp)
                    .stroke(line, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .frame(width: Self.plot.width, height: Self.plot.height)
                    .at(Self.plot.minX, Self.plot.minY)

                if let selected, points.indices.contains(selected) {
                    marker(index: selected, count: points.count, series: series, color: line)
                }

                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { i in
                        if i > 0 { Spacer(minLength: 0) }
                        axisLabel(period.axisFormat.string(from: points[min(points.count - 1, (points.count - 1) * i / 3)].date))
                    }
                }
                .frame(width: 254)
                .at(33, 264)

                // Price labels sit just above their grid lines: high, middle, low
                ForEach([(high, 0), ((high + low) / 2, 120), (low, 240)], id: \.1) { value, top in
                    Text("₹" + (ChartFormat.rupees.string(from: NSNumber(value: value)) ?? ""))
                        .font(FigmaFont.walsheim(12))
                        .tracking(0.84)
                        .foregroundStyle(Color.black.opacity(0.4))
                        .contentTransition(.numericText(value: value))
                        .frame(width: 336, height: 17, alignment: .trailing)
                        .at(0, CGFloat(top))
                }
            }
            .frame(width: 336, height: 281, alignment: .topLeading)
            // Tap anywhere on the chart to read the NAV on that day; tap the same day again to clear
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                let fraction = min(max((location.x - Self.plot.minX) / Self.plot.width, 0), 1)
                let index = Int((fraction * CGFloat(points.count - 1)).rounded())
                Haptics.tap()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    selected = selected == index ? nil : index
                }
            }
            .at(14, 101)

            PeriodSelector(selection: Binding(
                get: { period },
                set: { new in
                    // Start the warp from the line as it is now, then sweep to the new period
                    var reset = Transaction()
                    reset.disablesAnimations = true
                    withTransaction(reset) {
                        previous = series
                        warp = 0
                    }
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) {
                        selected = nil
                        period = new
                    }
                    DispatchQueue.main.async {
                        // Linear: the wave front moves at a steady pace; the easing is in each point's spring
                        withAnimation(.linear(duration: 1.9)) { warp = 1 }
                    }
                }
            ))
            .at(26, 399)
        }
        .frame(width: 368, height: 445)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
    }

    /// "501" + ".26", the rupees rolling to the new value
    private func price(_ nav: Double) -> some View {
        let whole = ChartFormat.rupees.string(from: NSNumber(value: floor(nav))) ?? ""
        let paise = String(format: ".%02d", Int(((nav - floor(nav)) * 100).rounded()) % 100)
        return HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(whole)
                .font(FigmaFont.walsheimMedium(35.613))
                .foregroundStyle(Color.ink)
            Text(paise)
                .font(FigmaFont.walsheimMedium(26.323))
                .foregroundStyle(Color.ink.opacity(0.43))
        }
        .contentTransition(.numericText(value: nav))
    }

    /// Dashed guide down from the tapped day, with a dot on the curve
    private func marker(index: Int, count: Int, series: ChartSeries, color: Color) -> some View {
        let fraction = count > 1 ? Double(index) / Double(count - 1) : 0
        let x = Self.plot.minX + Self.plot.width * fraction
        let y = Self.plot.minY + Self.plot.height * (1 - series.value(at: fraction))

        return ZStack(alignment: .topLeading) {
            Path { p in
                p.move(to: CGPoint(x: x, y: Self.plot.minY))
                p.addLine(to: CGPoint(x: x, y: Self.plot.maxY))
            }
            .stroke(Color.black.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(color, lineWidth: 3))
                .frame(width: 12, height: 12)
                .shadow(color: color.opacity(0.4), radius: 6)
                .position(x: x, y: y)
        }
        .frame(width: 336, height: 281, alignment: .topLeading)
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    private func gridLine(opacity: Double) -> some View {
        Rectangle()
            .fill(Color.black.opacity(opacity))
            .frame(width: 338, height: 1)
    }

    private func axisLabel(_ s: String) -> some View {
        Text(s)
            .font(FigmaFont.walsheim(12))
            .tracking(0.84)
            .foregroundStyle(Color.black.opacity(0.6))
            .frame(height: 17)
    }
}

/// 1M 6M 1Y (3Y) 5Y All (865:13522), 316 × 31. With a binding, tapping a period moves the outline to it.
struct PeriodSelector: View {
    var selection: Binding<ChartPeriod> = .constant(.threeYears)

    private let items: [(ChartPeriod, CGFloat)] = [
        (.month, 158 - 148.5), (.sixMonths, 158 - 87), (.year, 158 - 27.5),
        (.threeYears, 188), (.fiveYears, 158 + 89), (.all, 158 + 148.5),
    ]

    var body: some View {
        let selectedX = items.first { $0.0 == selection.wrappedValue }?.1 ?? 188

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.41), lineWidth: 1)
                .frame(width: 40, height: 31)
                .at(selectedX - 20, 0)

            ForEach(items, id: \.0) { period, centerX in
                Button {
                    guard selection.wrappedValue != period else { return }
                    Haptics.tap()
                    selection.wrappedValue = period
                } label: {
                    Text(period.rawValue)
                        .font(FigmaFont.walsheim(15))
                        .tracking(1.05)
                        .foregroundStyle(Color.black.opacity(0.6))
                        .frame(width: 44, height: 31)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: centerX, y: 15.5)
            }
        }
        .frame(width: 316, height: 31)
    }
}
