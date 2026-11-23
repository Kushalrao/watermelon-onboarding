import SwiftUI

/// A mutual fund's NAV over a period, as its page draws it (`MutualFundDetailView`): the curve over its wash, the
/// prices at the trailing edge with today's NAV beside the end of the curve, and the periods under it.
///
/// It is drawn three ways. On the sheet's page (Figma 101:15003) it stands on the page's ground. In the card
/// (101:15916) it has the fund's return over it, a line across at each marked price, and its chosen period
/// filled. In the pop-up the card opens out into it is the card's chart, taller.
///
/// It can be read with a finger: a drag across it puts a line through the curve where the finger is, with a dot
/// on the curve and, in a pill over the line, the fund's NAV on that day and the day. The pill rides along with
/// the line and goes when the finger lifts. A drag up or down is left to the page. In the pop-up a touch held on
/// it reads it too; on the page a hold lifts the whole widget out instead.
///
/// A tap on a period moves the ring to it, and the curve and its prices change over to it
/// (`MutualFund.chart(for:)`).
struct FundGrowthChart: View {
    enum Style {
        case sheet, card, popUp
    }

    let fund: MutualFund
    var style: Style
    /// The period shown, which the page keeps so that the card and its pop-up show the same one
    @Binding var period: MutualFund.Period
    /// The chart has begun to be read, or is no longer
    var onReading: (Bool) -> Void = { _ in }

    private static let axisInk = Color.black.opacity(0.4) // Gap: black 40%, the chart's prices, is unbound
    private static let periodInk = Color.black.opacity(0.6) // Gap: black 60%, the periods not chosen, is unbound
    private static let chartLine = Color(hex: 0x3FD519) // Gap: utility-green/400, the curve, has no semantic token
    private static let chartFill = Color(hex: 0x85FF66) // Gap: #85FF66, under the curve, is unbound
    private static let gridInk = Color.black.opacity(0.13) // Gap: black 13%, the chart's line at a marked price, is unbound
    private static let baseInk = Color.black.opacity(0.33) // Gap: black 33%, the chart's base line, is unbound

    /// The point of the curve under the finger, while the chart is being read
    @State private var read: Int?
    /// Each period's curve, made once when the chart appears
    @State private var charts: [MutualFund.Period: MutualFund.Chart] = [:]
    @Namespace private var ring

    /// How a chart is laid out in its 364 pt of width
    private struct Geometry {
        let size: CGSize
        /// Where the curve is drawn: down to where its wash ends and its lowest marked price is written
        let plot: CGRect
        /// Where the marked prices end
        let trailing: CGFloat
        /// Where the row of periods starts
        let periods: CGPoint
        /// How far down the chart can be read from
        let reach: CGFloat
    }

    /// The sheet's chart is 364 × 277, with its curve 290 across from 14 in, between 34.73 and 221.5 down. The
    /// card's is the top 310 of the card, with its curve 296 across from 20 in, between 47 and 254 down, under
    /// the return. The pop-up's is the card's with 68 more for the curve.
    private var geometry: Geometry {
        switch style {
        case .sheet:
            Geometry(size: CGSize(width: 364, height: 277), plot: CGRect(x: 14, y: 34.73, width: 290, height: 186.77),
                     trailing: 350, periods: CGPoint(x: 11, y: 235), reach: 229)
        case .card:
            Geometry(size: CGSize(width: 364, height: 310), plot: CGRect(x: 20, y: 47, width: 296, height: 207),
                     trailing: 356, periods: CGPoint(x: 6, y: 267), reach: 262)
        case .popUp:
            Geometry(size: CGSize(width: 364, height: 378), plot: CGRect(x: 20, y: 47, width: 296, height: 275),
                     trailing: 356, periods: CGPoint(x: 6, y: 335), reach: 330)
        }
    }

    private var plot: CGRect { geometry.plot }

    /// The curve's last day
    private static let today = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 21)) ?? .now
    private static let change = Animation.spring(response: 0.5, dampingFraction: 0.86)

    /// A period's curve in rupees, and the prices its chart runs between
    private struct Reading {
        /// The fund's NAV at each point of the curve: today's, taken back along the curve
        let prices: [Double]
        /// The price at the foot of the plot, a round one at or just under the lowest
        let base: Double
        /// The price at the top of the plot, the highest
        let high: Double
        /// The round prices written beside the curve are this far apart, and written to this many decimals
        let step: Double
        let decimals: Int

        init(_ chart: MutualFund.Chart, nav: Double) {
            let last = chart.series.last ?? 1
            prices = chart.series.map { nav * $0 / last }
            let low = prices.min() ?? 0
            high = max(prices.max() ?? 1, low + 0.01)
            let scale = MutualFund.scale(low: low, high: high)
            base = scale.base
            step = scale.step
            decimals = scale.decimals
        }

        /// How far up the plot a price is, 0 at its foot and 1 at its top
        func rise(_ price: Double) -> Double {
            (price - base) / (high - base)
        }
    }

    /// The chosen period's curve
    private var shown: MutualFund.Chart {
        charts[period] ?? fund.chart(for: period)
    }

    private func point(_ index: Int, in reading: Reading) -> CGPoint {
        CGPoint(
            x: plot.minX + plot.width * CGFloat(index) / CGFloat(reading.prices.count - 1),
            y: plot.maxY - plot.height * CGFloat(reading.rise(reading.prices[index]))
        )
    }

    private func day(_ index: Int) -> String {
        let chart = shown
        let back = chart.years * 365.25 * 86_400 * Double(chart.series.count - 1 - index) / Double(chart.series.count - 1)
        return Self.today.addingTimeInterval(-back).formatted(.dateTime.day().month(.abbreviated).year())
    }

    /// A price as the chart writes it, after the rupee sign the frame gives it (101:15009). GT Walsheim has no
    /// rupee sign, so the sign itself is drawn in the system's font.
    private static func rupees(_ price: Double, decimals: Int) -> String {
        "₹" + String(format: "%.\(decimals)f", price)
    }

    /// The point of the curve nearest a place across the chart
    private func nearest(_ x: CGFloat) -> Int {
        let along = (x - plot.minX) / plot.width
        return min(max(Int((along * CGFloat(shown.series.count - 1)).rounded()), 0), shown.series.count - 1)
    }

    private func touch(at place: CGPoint) {
        let index = nearest(place.x)
        guard index != read else { return }
        if read == nil {
            Haptics.tap()
            onReading(true)
        }
        // The first touch brings the pill in; after that it keeps up with the finger
        withAnimation(read == nil ? .spring(response: 0.3, dampingFraction: 0.86) : nil) { read = index }
    }

    private func touchOver() {
        guard read != nil else { return }
        onReading(false)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) { read = nil }
    }

    private func choose(_ chosen: MutualFund.Period) {
        guard chosen != period else { return }
        Haptics.tap()
        if read != nil { onReading(false) }
        withAnimation(Self.change) {
            read = nil
            period = chosen
        }
    }

    var body: some View {
        let geometry = geometry
        let reading = Reading(shown, nav: fund.nav)
        let rise = reading.prices.map(reading.rise)
        let now = reading.prices.last ?? fund.nav
        let end = plot.maxY - plot.height * CGFloat(reading.rise(now))
        // The round prices, each at its own height: those above the chart are left out, as the frame's ₹43 is cut
        // off, and so is one that today's NAV would be written over
        let marks = stride(from: reading.base, through: reading.high + reading.step, by: reading.step)
            .map { (price: $0, y: plot.maxY - plot.height * CGFloat(reading.rise($0))) }
            .filter { $0.y >= 12 && abs($0.y - end) >= 15 }
        return ZStack(alignment: .topLeading) {
            if style != .sheet {
                // 101:15918, 101:15919: a line at each marked price the curve reaches, and the base line
                ForEach(marks.filter { $0.y >= plot.minY && $0.y < plot.maxY - 1 }, id: \.price) { mark in
                    Self.gridInk
                        .frame(width: 338, height: 1) // Gap: a 1 pt line, not the hairline
                        .at(plot.minX, mark.y - 0.5)
                }
                .id(period)
                .transition(.opacity)
                Self.baseInk
                    .frame(width: 338, height: 1) // Gap: a 1 pt line, not the hairline
                    .at(plot.minX, plot.maxY - 0.5)
                // 101:16715: the return, which gives way to the price's pill while the chart is being read
                FundGain(fund: fund)
                    .at(17, 19)
                    .opacity(read == nil ? 1 : 0)
            }
            // 101:15005, 101:15006: the wash under the curve and the curve. Both are drawn from the period's own
            // prices, and move from one period's shape to the next's.
            GrowthCurve(heights: AnimatableSeries(rise), closed: true)
                .fill(LinearGradient(
                    stops: [.init(color: Self.chartFill.opacity(0.6), location: 0), .init(color: Self.chartFill.opacity(0.04), location: 1)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: plot.width, height: plot.height)
                .at(plot.minX, plot.minY)
            GrowthCurve(heights: AnimatableSeries(rise), closed: false)
                .stroke(Self.chartLine, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)) // Gap: the curve is 2.5 pt, not the hairline
                .frame(width: plot.width, height: plot.height)
                .at(plot.minX, plot.minY)
            // 101:15008 …: the prices at the trailing edge, and today's NAV beside the end of the curve (101:15009)
            ZStack(alignment: .topLeading) {
                ForEach(marks, id: \.price) { mark in
                    price(Self.rupees(mark.price, decimals: reading.decimals), at: mark.y)
                }
                // Today's NAV beside the end of the curve: to the paisa where that keeps clear of the curve, as the
                // frame's ₹40.48 does, and to the rupee where it would not. A figure of the chart's is about 7 across.
                price(Self.rupees(now, decimals: CGFloat(Self.rupees(now, decimals: 2).count) * 7 <= geometry.trailing - plot.maxX - 4 ? 2 : 0), at: end)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            // One period's prices give way to the next's
            .id(period)
            .transition(.opacity)
            // The chart is read from the curve's own ground, not from the periods under it
            ground(geometry)
            periods
                .at(geometry.periods.x, geometry.periods.y)
            if let read {
                pointer(at: point(read, in: reading))
                price(of: read, in: reading)
                    .frame(width: 364)
                    .offset(x: 0.5 + min(max(point(read, in: reading).x, 82), 364 - 82) - 182)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        .onAppear {
            if charts.isEmpty {
                charts = Dictionary(uniqueKeysWithValues: MutualFund.Period.allCases.map { ($0, fund.chart(for: $0)) })
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("NAV over \(period.spoken), now \(String(format: "%.2f", now)) rupees")
    }

    /// The ground the chart is read from. On the page a drag across it reads it, and it keeps that drag from
    /// sending the widget to the advisor (`SwipeShield`); a hold there is the widget's. In the pop-up a hold
    /// reads it too.
    @ViewBuilder private func ground(_ geometry: Geometry) -> some View {
        let ground = Color.clear
            .frame(width: geometry.size.width, height: geometry.reach)
            .contentShape(Rectangle())
            .gesture(ChartDrag(onMove: touch(at:), onEnd: touchOver))
        if style == .popUp {
            ground.gesture(ChartHold(onMove: touch(at:), onEnd: touchOver))
        } else {
            ground.background(SwipeShield())
        }
    }

    /// A price at the chart's trailing edge, centred on its own height. Gap: Rg 12/17 at 7% tracking has no text style
    private func price(_ string: String, at y: CGFloat) -> some View {
        GapText(string, family: .walsheim, medium: false, size: 12, lineHeight: 17, trackingPercent: 7, color: Self.axisInk)
            .fixedSize()
            // The prices end short of the chart's trailing edge: 14 on the sheet, 8 in the card
            .frame(width: geometry.trailing, alignment: .trailing)
            .at(0, y - 8.5)
            .accessibilityHidden(true)
    }

    /// The line through the curve where the finger is, from under the pill to the foot of the plot, and the dot
    /// on the curve
    private func pointer(at place: CGPoint) -> some View {
        ZStack(alignment: .topLeading) {
            Hairline(.borderStrong, axis: .vertical)
                .frame(height: plot.maxY - 56)
                .offset(x: place.x, y: 56)
            Circle()
                .fill(Self.chartLine)
                .frame(width: 9, height: 9)
                .padding(2) // Gap: a 2 pt white ring round the dot, no spacing token
                .background(Circle().fill(ColorScale.surfaceWidget))
                .offset(x: place.x - 6.5, y: place.y - 6.5)
        }
        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    /// The pill over the line while the chart is being read: the fund's NAV at the finger, to the paisa, and the
    /// day. It is the first version's pill (37:4271); the later frames draw the chart at rest, with none.
    private func price(of index: Int, in reading: Reading) -> some View {
        Surface(surface: .surfaceWidget, radius: .radius35) {
            VStack(spacing: 1) { // Gap: 1 between the figure and its line, no spacing token
                // Gap: Md 27/29 at 4% tracking; N2 is the same at 9%
                GapText(Self.rupees(reading.prices[index], decimals: 2), family: .walsheim, medium: true, size: 27, lineHeight: 29, trackingPercent: 4, color: ColorScale.contentPrimary)
                    .fixedSize()
                // Gap: Rg 13/17, Lb1 on the line this file gives it
                GapText(day(index), family: .walsheim, medium: false, size: 13, lineHeight: 17, color: ColorScale.contentTertiary)
                    .fixedSize()
            }
            // The words change at once: fading from one price to the next blurred them under a moving finger
            .animation(nil, value: read)
            .padding(.horizontal, 19) // Gap: 19 inside the pill, no spacing token
            .padding(.top, SpacingScale.spaceSm)
            .padding(.bottom, SpacingScale.spaceXs)
        }
    }

    /// 101:15011, 101:15926: the periods, each where the frames put it, with the ring round the chosen one
    private var periods: some View {
        let middles: [CGFloat] = [9.5, 71, 130.5, 188, 247, 306.5]
        return ZStack(alignment: .topLeading) {
            ForEach(Array(MutualFund.Period.allCases.enumerated()), id: \.element) { place, each in
                Button {
                    choose(each)
                } label: {
                    // Gap: Rg 15/21 at 7% tracking has no text style
                    GapText(each.rawValue, family: .walsheim, medium: false, size: 15, lineHeight: 21, trackingPercent: 7,
                            color: each != period ? Self.periodInk : style == .sheet ? ColorScale.contentPrimary : ColorScale.contentOnColor)
                        .fixedSize()
                        .frame(width: 40, height: 31)
                        .background {
                            if each == period {
                                // A ring on the sheet (101:15015); in the card it is filled (101:15930)
                                Surface(surface: style == .sheet ? nil : .surfaceInverse, shape: .capsule, border: .borderStrong, shadow: .none) { Color.clear }
                                    .matchedGeometryEffect(id: "ring", in: ring)
                            }
                        }
                        // A period is 31 tall in the frame; its tap target is 60 by 44
                        .frame(width: 60, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(each.spoken)
                .accessibilityAddTraits(each == period ? .isSelected : [])
                .at(middles[place] - 30, -6.5)
            }
        }
        .frame(width: 316, height: 31, alignment: .topLeading)
    }
}

/// 101:15353, 101:16715: what a fund has returned a year, with an arrow before it and what it is over after it. A
/// loss is written in red after the arrow turned down.
struct FundGain: View {
    let fund: MutualFund

    private static let gainInk = Color(hex: 0x3FD519) // Gap: utility-green/400 has no semantic token
    private static let lossInk = Color(hex: 0xF0453A) // Gap: utility-red/500 has no semantic token

    var body: some View {
        let up = fund.returned >= 0
        HStack(spacing: 5.5) { // Gap: 5.5 between the arrow, the figure and the period, no spacing token
            Image("MFDetailUp")
                .foregroundStyle(up ? Self.gainInk : Self.lossInk)
                .scaleEffect(x: 1, y: up ? 1 : -1)
            // Gap: Md 21.6/28 has no text style
            GapText(MutualFundsHouseMap.percent(abs(fund.returned)), family: .walsheim, medium: true, size: 21.6, lineHeight: 28, color: up ? Self.gainInk : Self.lossInk)
                .fixedSize()
            GapText(fund.span, family: .walsheim, medium: true, size: 21.6, lineHeight: 28, color: ColorScale.contentDisabled)
                .fixedSize()
        }
        .frame(height: 28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(up ? "Up" : "Down") \(MutualFundsHouseMap.percent(abs(fund.returned))) \(fund.span == "3Y" ? "a year over 3 years" : fund.span == "1Y" ? "over 1 year" : "a year since it began")")
    }
}

/// The fund's growth as a line across its frame, each point as far up as its height says; closed, it takes in
/// the ground under the line, for the wash
private struct GrowthCurve: Shape {
    var heights: AnimatableSeries
    let closed: Bool

    var animatableData: AnimatableSeries {
        get { heights }
        set { heights = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let count = heights.values.count
        guard count > 1 else { return path }
        for (index, height) in heights.values.enumerated() {
            let place = CGPoint(x: rect.minX + rect.width * CGFloat(index) / CGFloat(count - 1), y: rect.maxY - rect.height * CGFloat(height))
            if index == 0 { path.move(to: place) } else { path.addLine(to: place) }
        }
        if closed {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

/// A drag across the chart reads it. It begins only when the finger sets off sideways, so a drag up or down is
/// left to the page.
private struct ChartDrag: UIGestureRecognizerRepresentable {
    let onMove: (CGPoint) -> Void
    let onEnd: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Sideways { Sideways() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began, .changed: onMove(context.converter.localLocation)
        case .ended, .cancelled, .failed: onEnd()
        default: break
        }
    }

    final class Sideways: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
            let speed = pan.velocity(in: pan.view)
            return abs(speed.x) > abs(speed.y)
        }
    }
}

/// A touch held on the chart reads it where it is held, and then wherever it moves
private struct ChartHold: UIGestureRecognizerRepresentable {
    let onMove: (CGPoint) -> Void
    let onEnd: () -> Void

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let hold = UILongPressGestureRecognizer()
        hold.minimumPressDuration = 0.15
        return hold
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began, .changed: onMove(context.converter.localLocation)
        case .ended, .cancelled, .failed: onEnd()
        default: break
        }
    }
}
