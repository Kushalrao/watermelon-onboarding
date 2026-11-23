import SwiftUI

/// Figma "iPhone 14 Plus - 534" (37:3821, file `sub7vIn6sMBlHb4SIWHyek`): a mutual fund's page. The fund's growth
/// over three years on the sunken ground, then a white sheet with the "Market · For you · View research" row, the
/// fund's name and house, and its cards: Basics, Fund holdings as a list and again as a map, Sectors exposure,
/// Market cap exposure and Fund managers. "Start SIP" rides at the foot between the advisor and a "more" button.
///
/// The page is drawn for one fund, `MutualFund.hsbc`, and shows any other the same way (`MutualFund.all`). It opens
/// from a fund on the mutual funds homepage, or straight away with `-mfFund`; a drag from the leading edge takes
/// it back.
///
/// The chart can be read with a finger: a drag across it, or a touch held on it, puts a line through the curve
/// where the finger is, with a dot on the curve and, in the pill at the top, the fund's NAV on that day, in
/// rupees, and the day. The pill rides along with the line and goes back to the return when the finger lifts. A drag up or
/// down still scrolls the page.
///
/// The periods under the chart choose how far back it goes: a tap moves the ring to that period, and the curve,
/// its prices and the return in the pill change over to it (`MutualFund.chart(for:)`).
///
/// The frame draws one state only otherwise: the row of three and the foot's buttons do not respond yet.
struct MutualFundDetailView: View {
    /// The fund the page is for
    var fund: MutualFund = .hsbc
    /// Takes the page away (a drag in from the leading edge)
    var onBack: () -> Void = {}

    /// A holding's place in the map (41:1811): its cell in the 321 × 285 frame, and how the cell is set. The
    /// frame sizes the cells for its own fund; any fund's holdings take them in order, the largest first.
    struct Slot {
        let cell: CGRect
        let tier: Tier

        /// How a map cell is set, by its size in the frame
        enum Tier {
            /// 24 pt logo, 10 pt name, 11 pt share (41:1812)
            case first
            /// 18 pt logo, 8 pt name, 9 pt share (41:1836)
            case second
            /// 14 pt logo and an 8 pt share, no name (41:1884)
            case third
        }
    }

    static let slots: [Slot] = [
        Slot(cell: CGRect(x: 0.5, y: 0.5, width: 90.5, height: 111), tier: .first),
        Slot(cell: CGRect(x: 0.5, y: 112.5, width: 90.5, height: 89), tier: .first),
        Slot(cell: CGRect(x: 0.5, y: 202.5, width: 90.5, height: 82), tier: .first),
        Slot(cell: CGRect(x: 92, y: 0.5, width: 82.5, height: 82), tier: .first),
        Slot(cell: CGRect(x: 175.5, y: 0.5, width: 75, height: 82), tier: .second),
        Slot(cell: CGRect(x: 251.5, y: 0.5, width: 69, height: 82), tier: .second),
        Slot(cell: CGRect(x: 92, y: 83.5, width: 73, height: 72), tier: .second),
        Slot(cell: CGRect(x: 92, y: 156.5, width: 73, height: 66), tier: .second),
        Slot(cell: CGRect(x: 92, y: 223.5, width: 73, height: 61), tier: .second),
        Slot(cell: CGRect(x: 166, y: 83.5, width: 80, height: 51), tier: .second),
        Slot(cell: CGRect(x: 247, y: 83.5, width: 73.5, height: 51), tier: .second),
        Slot(cell: CGRect(x: 166, y: 135.5, width: 64.5, height: 53), tier: .second),
        Slot(cell: CGRect(x: 166, y: 189.5, width: 64.5, height: 49), tier: .third),
        Slot(cell: CGRect(x: 166, y: 239.5, width: 64.5, height: 45), tier: .third),
        Slot(cell: CGRect(x: 231.5, y: 135.5, width: 46, height: 58), tier: .third),
        Slot(cell: CGRect(x: 278.5, y: 135.5, width: 42, height: 58), tier: .third),
        Slot(cell: CGRect(x: 231.5, y: 194.5, width: 46, height: 48.5), tier: .third),
        Slot(cell: CGRect(x: 278.5, y: 194.5, width: 42, height: 48.5), tier: .third),
        Slot(cell: CGRect(x: 231.5, y: 244, width: 46, height: 40.5), tier: .third),
        Slot(cell: CGRect(x: 278.5, y: 244, width: 42, height: 40.5), tier: .third),
    ]

    /// 41:1949: the three sizes of company, in the bar's order, each with its colour
    private static let sizes: [(name: String, ink: Color)] = [("Large cap", largeInk), ("Mid cap", accentInk), ("Small cap", smallInk)]

    private static let titleInk = Color(hex: 0x212121) // Gap: #212121, the titles' colour, is unbound
    private static let upInk = Color(hex: 0x00A800) // Gap: utility-green/500 has no semantic token
    private static let largeInk = Color(hex: 0x3FD519) // Gap: utility-green/400 has no semantic token
    private static let accentInk = Color(hex: 0xA872B3) // Gap: accent-lavender/500 has no semantic token
    private static let smallInk = Color(hex: 0xFEBD12) // Gap: accent-yellow/300 has no semantic token
    private static let pillFill = Color(hex: 0xF9F9F9) // Gap: #F9F9F9, the foot's pills, is unbound
    private static let footTop = Color(hex: 0xF8F8F5, opacity: 0.4) // Gap: #F8F8F5 40%, the top of the foot's wash, is unbound
    private static let footWash = Color(hex: 0xF3F6F3) // Gap: #F3F6F3, the foot's wash, is unbound
    private static let factRule = Color(hex: 0xD2CECC) // Gap: #D2CECC, the rules in Basics, is unbound
    private static let valueInk = Color.black.opacity(0.56) // Gap: black 56%, a fact's value, is unbound
    private static let axisInk = Color.black.opacity(0.4) // Gap: black 40%, the chart's prices, is unbound
    private static let periodInk = Color.black.opacity(0.6) // Gap: black 60%, the periods not chosen, is unbound
    private static let houseInk = Color.black.opacity(0.5) // Gap: black 50%, the fund house's name, is unbound
    private static let chartLine = Color(hex: 0x3FD519) // Gap: utility-green/400, the curve, has no semantic token
    private static let chartFill = Color(hex: 0x85FF66) // Gap: #85FF66, under the curve, is unbound
    private static let mapGround = Color(hex: 0x8C8886, opacity: 0.2) // Gap: ivory/500 at 20%, the map's seams, has no semantic token

    /// How far the page has been dragged back
    @State private var pulled: CGFloat = 0
    /// The point of the curve under the finger, while the chart is being read
    @State private var read: Int?
    /// The period the chart shows; the frame draws the third
    @State private var period = MutualFund.Period.three
    /// Each period's curve, made once when the page opens
    @State private var charts: [MutualFund.Period: MutualFund.Chart] = [:]
    @Namespace private var ring

    var body: some View {
        GeometryReader { geo in
            // A card is the screen less 13 either side; its box is 21 and 22 inside that, 321 in the frame
            let box = geo.size.width - 2 * SpacingScale.spaceMdLg - 43
            VStack(spacing: 0) {
                // Keeps the page from running up under the status bar as it scrolls
                Color.clear.frame(height: 1)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        chart
                            .padding(.top, 27) // Gap: the chart starts 28 under the status bar, no spacing token
                        sheet(box: box)
                            .padding(.top, 20) // Gap: 20 under the chart, no spacing token
                    }
                    // Room to scroll the sheet's end clear of the foot
                    .padding(.bottom, SpacingScale.space10xl)
                }
            }
        }
        .background(ColorScale.surfaceSunken1.ignoresSafeArea())
        .onAppear {
            if charts.isEmpty {
                charts = Dictionary(uniqueKeysWithValues: MutualFund.Period.allCases.map { ($0, fund.chart(for: $0)) })
            }
        }
        .overlay { foot }
        .overlay(alignment: .leading) { backEdge }
        .offset(x: pulled)
        .preferredColorScheme(.light)
    }

    /// A drag in from the leading edge takes the page back, as a pushed page goes
    private var backEdge: some View {
        Color.clear
            .frame(width: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { pulled = max(0, $0.translation.width) }
                    .onEnded { value in
                        if value.translation.width > 110 || value.predictedEndTranslation.width > 260 {
                            Haptics.tap()
                            onBack()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { pulled = 0 }
                        }
                    }
            )
            .accessibilityLabel("Back")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onBack() }
    }

    // MARK: Growth

    /// Where the curve is drawn in the 364 × 277 chart (37:3824): 296 × 188.73, from 14 across and 33.27 down
    private static let plot = CGRect(x: 14, y: 33.27, width: 296, height: 188.73)
    /// The curve's last day
    private static let today = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 21)) ?? .now
    private static let change = Animation.spring(response: 0.5, dampingFraction: 0.86)

    /// The chosen period's curve
    private var shown: MutualFund.Chart {
        charts[period] ?? fund.chart(for: period)
    }

    /// How far up the plot each point of a curve is, 0 at its lowest and 1 at its highest
    private func heights(_ chart: MutualFund.Chart) -> [Double] {
        let low = chart.series.min() ?? 0
        let high = max(chart.series.max() ?? 1, low + 0.01)
        return chart.series.map { ($0 - low) / (high - low) }
    }

    private func point(_ index: Int) -> CGPoint {
        let chart = shown
        return CGPoint(
            x: Self.plot.minX + Self.plot.width * CGFloat(index) / CGFloat(chart.series.count - 1),
            y: Self.plot.maxY - Self.plot.height * CGFloat(heights(chart)[index])
        )
    }

    private func height(of price: Double) -> CGFloat {
        let low = shown.series.min() ?? 0
        let high = max(shown.series.max() ?? 1, low + 0.01)
        return Self.plot.maxY - Self.plot.height * CGFloat((price - low) / (high - low))
    }

    private func day(_ index: Int) -> String {
        let chart = shown
        let back = chart.years * 365.25 * 86_400 * Double(chart.series.count - 1 - index) / Double(chart.series.count - 1)
        return Self.today.addingTimeInterval(-back).formatted(.dateTime.day().month(.abbreviated).year())
    }

    /// The fund's NAV at a point of the curve, in rupees as Basics writes them ("Rs247.02"): today's NAV, taken
    /// back along the curve. The app's font has no rupee sign, so it is written "Rs".
    private func nav(_ index: Int) -> String {
        let series = shown.series
        return "Rs" + String(format: "%.2f", fund.nav * series[index] / (series.last ?? 1))
    }

    /// The point of the curve nearest a place across the chart
    private func nearest(_ x: CGFloat) -> Int {
        let along = (x - Self.plot.minX) / Self.plot.width
        return min(max(Int((along * CGFloat(shown.series.count - 1)).rounded()), 0), shown.series.count - 1)
    }

    private func reading(at place: CGPoint) {
        let index = nearest(place.x)
        guard index != read else { return }
        if read == nil { Haptics.tap() }
        // The first touch brings the pill over; after that it keeps up with the finger
        withAnimation(read == nil ? .spring(response: 0.3, dampingFraction: 0.86) : nil) { read = index }
    }

    private func readingOver() {
        guard read != nil else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) { read = nil }
    }

    private func choose(_ chosen: MutualFund.Period) {
        guard chosen != period else { return }
        Haptics.tap()
        withAnimation(Self.change) {
            read = nil
            period = chosen
        }
    }

    /// 37:3822: the fund's growth, 364 × 277, with the return in a pill over it and the periods under it
    private var chart: some View {
        let chart = shown
        let rise = heights(chart)
        return ZStack(alignment: .topLeading) {
            // 37:3824, 37:3825: the area under the curve and the curve. Both are drawn from the period's own
            // growth, and move from one period's shape to the next's.
            GrowthCurve(heights: AnimatableSeries(rise), closed: true)
                .fill(LinearGradient(
                    stops: [.init(color: Self.chartFill.opacity(0.6), location: 0), .init(color: Self.chartFill.opacity(0.04), location: 1)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: Self.plot.width, height: Self.plot.height)
                .at(Self.plot.minX, Self.plot.minY)
            GrowthCurve(heights: AnimatableSeries(rise), closed: false)
                .stroke(Self.chartLine, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)) // Gap: the curve is 2.5 pt, not the hairline
                .frame(width: Self.plot.width, height: Self.plot.height)
                .at(Self.plot.minX, Self.plot.minY)
            // The prices at the trailing edge; the frame's fourth, ¢160, is cut off above the chart
            ZStack(alignment: .topLeading) {
                ForEach(Array(chart.ticks.enumerated()), id: \.offset) { place, tick in
                    // Gap: Rg 12/17 at 7% tracking has no text style
                    GapText("¢" + String(format: "%.\(chart.decimals)f", tick), family: .walsheim, medium: false, size: 12, lineHeight: 17, trackingPercent: 7, color: Self.axisInk)
                        .fixedSize()
                        .frame(width: 350, alignment: .trailing)
                        // The highest hangs from the top of the plot, as the frame's ¢147 does; the others sit on their price
                        .at(0, place == chart.ticks.count - 1 ? Self.plot.minY : height(of: tick) - 8.5)
                }
            }
            .frame(width: 364, height: 277, alignment: .topLeading)
            // One period's prices give way to the next's
            .id(period)
            .transition(.opacity)
            // The chart is read from the curve's own ground, not from the periods under it
            Color.clear
                .frame(width: 364, height: 229)
                .contentShape(Rectangle())
                .gesture(ChartDrag(onMove: reading, onEnd: readingOver))
                .gesture(ChartHold(onMove: reading, onEnd: readingOver))
            periods
                .at(0, 235)
            if let read {
                pointer(read)
            }
            returned
                .frame(width: 364)
                .offset(x: 0.5 + pillShift)
                .allowsHitTesting(false)
        }
        .frame(width: 364, height: 277, alignment: .topLeading)
        .accessibilityElement(children: .contain)
    }

    /// How far the pill has moved off the chart's middle to stand over the finger, kept inside the chart
    private var pillShift: CGFloat {
        guard let read else { return 0 }
        // A NAV makes the pill about 160 across
        return min(max(point(read).x, 82), 364 - 82) - 182
    }

    /// The line through the curve where the finger is, from under the pill to the foot of the plot, and the dot
    /// on the curve
    private func pointer(_ index: Int) -> some View {
        let place = point(index)
        return ZStack(alignment: .topLeading) {
            Hairline(.borderStrong, axis: .vertical)
                .frame(height: Self.plot.maxY - 56)
                .offset(x: place.x, y: 56)
            Circle()
                .fill(Self.chartLine)
                .frame(width: 9, height: 9)
                .padding(2) // Gap: a 2 pt white ring round the dot, no spacing token
                .background(Circle().fill(ColorScale.surfaceWidget))
                .offset(x: place.x - 6.5, y: place.y - 6.5)
        }
        .frame(width: 364, height: 277, alignment: .topLeading)
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    /// 37:4271: the return over the chosen period, with the frame's own wording under it. While the chart is
    /// being read it carries the fund's NAV at the finger, in rupees, and the day.
    private var returned: some View {
        let chart = shown
        return Surface(surface: .surfaceWidget, radius: .radius35) {
            VStack(spacing: 1) { // Gap: 1 between the figure and its line, no spacing token
                // Gap: Md 27/29 at 4% tracking; N2 is the same at 9%
                GapText(read.map(nav) ?? MutualFundsHouseMap.percent(chart.returned), family: .walsheim, medium: true, size: 27, lineHeight: 29, trackingPercent: 4, color: ColorScale.contentPrimary)
                    .fixedSize()
                    .contentTransition(.numericText(value: chart.returned))
                // Gap: Rg 13/17, Lb1 on the line this file gives it
                GapText(read.map(day) ?? chart.caption, family: .walsheim, medium: false, size: 13, lineHeight: 17, color: ColorScale.contentTertiary)
                    .fixedSize()
            }
            // The words change at once: fading from one price to the next blurred them under a moving finger
            .animation(nil, value: read)
            .padding(.horizontal, 19) // Gap: 19 inside the pill, no spacing token
            .padding(.top, SpacingScale.spaceSm)
            .padding(.bottom, SpacingScale.spaceXs)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(MutualFundsHouseMap.percent(chart.returned)) \(chart.years >= 1 ? "a year " : "")over \(chart.period.spoken)")
    }

    /// 37:3830: the periods, each where the frame puts it, with the ring round the chosen one
    private var periods: some View {
        let middles: [CGFloat] = [9.5, 71, 130.5, 188, 247, 306.5]
        return ZStack(alignment: .topLeading) {
            ForEach(Array(MutualFund.Period.allCases.enumerated()), id: \.element) { place, each in
                Button {
                    choose(each)
                } label: {
                    // Gap: Rg 15/21 at 7% tracking has no text style
                    GapText(each.rawValue, family: .walsheim, medium: false, size: 15, lineHeight: 21, trackingPercent: 7, color: each == period ? ColorScale.contentPrimary : Self.periodInk)
                        .fixedSize()
                        .frame(width: 40, height: 31)
                        .background {
                            if each == period {
                                Surface(shape: .capsule, border: .borderStrong) { Color.clear }
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

    // MARK: The sheet

    /// 37:3839: the white sheet, rounded at the top, that carries the rest of the page
    private func sheet(box: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            views
                .padding(.top, 17) // Gap: 17 inside the sheet's top, no spacing token
            name
                .padding(.leading, SpacingScale.spaceMdLg)
                .padding(.top, 31) // Gap: 31 under the row, no spacing token
            Group {
                basics
                    .padding(.top, 42) // Gap: 42 under the fund house, no spacing token
                // In the frame this card starts 157 under Basics, with nothing between; here it follows at the
                // 35 the other cards keep
                holdingsList
                    .padding(.top, SpacingScale.space4xl)
                holdingsMap(box: box)
                    .padding(.top, SpacingScale.space4xl)
                sectors(box: box)
                    .padding(.top, SpacingScale.space4xl)
                marketCap(box: box)
                    .padding(.top, SpacingScale.space4xl)
                managers
                    .padding(.top, SpacingScale.space4xl)
            }
            .padding(.horizontal, SpacingScale.spaceMdLg)
        }
        .padding(.bottom, 106) // Gap: 106 under the last card, no spacing token
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            // Gap: the frame throws the sheet's shadow upward (y −4); Shadow/2 is the same shadow thrown down
            UnevenRoundedRectangle(topLeadingRadius: RadiusToken.radius27.value, topTrailingRadius: RadiusToken.radius27.value, style: .continuous)
                .fill(ColorScale.surfaceWidget)
                .dsShadow(.shadow2)
        }
    }

    /// 37:3845: "Market", chosen, then "For you" and "View research"; the row runs off the trailing edge
    private var views: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Stack(direction: .horizontal, gap: .spaceMd) {
                view("Market", orb: "MFDetailOrbMarket", chosen: true)
                view("For you", orb: "MFDetailOrbForYou", chosen: false)
                view("View research", orb: "MFDetailOrbResearch", chosen: false)
            }
            .padding(.horizontal, SpacingScale.spaceLg)
        }
        .scrollClipDisabled()
    }

    /// 37:3846, 37:3857: an orb and a word in a pill. Gap: the pills not chosen are #FEFEFE with a 1 pt edge in the
    /// frame; here they are the white widget surface with the hairline.
    private func view(_ title: String, orb: String, chosen: Bool) -> some View {
        Surface(surface: chosen ? .surfaceInverse : .surfaceWidget, radius: .radius27, border: chosen ? nil : .borderSubtle, shadow: .token(.shadow1)) {
            Stack(direction: .horizontal, gap: .spaceMd, alignment: .center) {
                // The orb is exported with its own soft shadow, 44.25 across around its 27
                Image(orb)
                    .resizable()
                    .frame(width: 44.25, height: 44.25)
                    .frame(width: 27, height: 27)
                    .accessibilityHidden(true)
                copy(title, color: chosen ? ColorScale.contentOnColor : ColorScale.contentPrimary)
                    .fixedSize()
                    .frame(height: 21)
            }
            .padding(.horizontal, SpacingScale.spaceLg)
            .padding(.vertical, 11) // Gap: 11 above and below, no spacing token
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    /// 37:3840: the fund's name, then its house
    private var name: some View {
        VStack(alignment: .leading, spacing: 14) { // Gap: 14 under the name, no spacing token
            // Gap: Reckless Medium 45/49 has no text style (H1 is Regular 45/49). The drawn fund's name is broken
            // where the frame breaks it.
            GapText(fund.title, family: .reckless, medium: true, size: 45, lineHeight: 49, color: Self.titleInk)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(fund.name)
                .accessibilityAddTraits(.isHeader)
            Stack(direction: .horizontal, gap: .spaceXs, alignment: .center) {
                switch fund.mark {
                case .wide(let image):
                    // 37:3844: the hexagons, cut from the house's 16:9 mark as the frame cuts them
                    Image(image)
                        .resizable()
                        .frame(width: 78.55, height: 44.68)
                        .offset(y: -10.84 + (44.68 - 23) / 2)
                        .frame(width: 43, height: 23, alignment: .leading)
                        .clipped()
                        .accessibilityHidden(true)
                case .tile(let image):
                    // No frame draws another house here: its logo on the tile the homepage uses, at the mark's height
                    FundHouseLogo(name: image, side: 23)
                }
                // Gap: Md 17/23 at 5% tracking, in capitals, has no text style
                GapText(fund.house.uppercased(), family: .walsheim, medium: true, size: 17, lineHeight: 23, trackingPercent: 5, color: Self.houseInk)
                    .fixedSize()
            }
        }
        .padding(.trailing, SpacingScale.spaceMdLg)
    }

    // MARK: Cards

    /// A card's title (41:1775). Gap: Md 23/31 has no text style (H4 is 23/35)
    private func title(_ string: String) -> some View {
        GapText(string, family: .walsheim, medium: true, size: 23, lineHeight: 31, color: Self.titleInk)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
    }

    /// A card with its title and, under it, a box with a 1 pt edge (41:1774, 41:1777)
    private func card<Content: View>(_ heading: String, expands: Bool = false, @ViewBuilder content: @escaping () -> Content) -> some View {
        Surface(surface: .surfaceWidget, radius: .radius23) {
            VStack(alignment: .leading, spacing: SpacingScale.spaceLg) {
                HStack(spacing: 0) {
                    title(heading)
                    Spacer(minLength: 0)
                    if expands {
                        // 41:1776: the arrows, turned as the frame turns them
                        Image("MFDetailExpand")
                            .scaleEffect(x: -1, y: 1)
                            .accessibilityHidden(true)
                    }
                }
                content()
                    .overlay(Rectangle().strokeBorder(ColorScale.borderSubtle, lineWidth: 1)) // Gap: a 1 pt edge, not the hairline
            }
            .padding(.leading, SpacingScale.spaceXl)
            .padding(.trailing, 22) // Gap: 22 at the trailing edge, no spacing token
            .padding(.top, SpacingScale.spaceXl)
            .padding(.bottom, 27) // Gap: 27 under the box, no spacing token
        }
    }

    /// Body copy. Gap: P4 on the 21 pt line this file gives it (the token's line is 23), so that a row's words sit
    /// on one baseline with its figures
    private func copy(_ string: String, color: Color = ColorScale.contentPrimary) -> some View {
        GapText(string, family: .walsheim, medium: false, size: 15, lineHeight: 21, color: color)
    }

    /// The small line under a name. Gap: P5 on the 19 pt line this file gives it (the token's line is 21)
    private func small(_ string: String) -> some View {
        GapText(string, family: .walsheim, medium: false, size: 13, lineHeight: 19, color: ColorScale.contentTertiary)
    }

    /// The 1 pt rule under a row in a box
    private var rowRule: some View {
        ColorScale.borderSubtle.frame(height: 1) // Gap: the rule under a row is 1 pt, not the hairline
    }

    /// A round 27 pt badge on the page's ground (41:1788)
    private func badge<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(width: 27, height: 27)
            .background(Circle().fill(ColorScale.surfaceBase))
            .overlay(Circle().strokeBorder(ColorScale.borderSubtle, lineWidth: 0.371)) // Gap: the badge's 0.371 stroke is not the hairline
            .accessibilityHidden(true)
    }

    /// What a holding or a size of company makes up, in green. Gap: Rg 15/21, P4 on this file's line, in a utility
    /// colour with no content token
    private func share(_ string: String) -> some View {
        GapText(string, family: .walsheim, medium: false, size: 15, lineHeight: 21, color: Self.upInk)
            .fixedSize()
    }

    /// A 57 pt row in a box: a badge, a name, and a share at the trailing edge (41:1778)
    private func row<Badge: View>(_ name: String, share value: String, @ViewBuilder badge: () -> Badge) -> some View {
        HStack(spacing: 12) { // Gap: 12 from the badge to the name, no spacing token
            badge()
            copy(name)
                .lineLimit(1)
                .frame(height: 21)
            Spacer(minLength: SpacingScale.spaceXs)
            share(value)
        }
        .padding(.horizontal, SpacingScale.spaceLg)
        .frame(height: 57)
        .overlay(alignment: .bottom) { rowRule }
        .accessibilityElement(children: .combine)
    }

    /// 37:3895: Basics, a fact to a row with hairlines between
    private var basics: some View {
        Surface(surface: .surfaceWidget, radius: .radius23) {
            VStack(alignment: .leading, spacing: 0) {
                // Gap: H5 (Md 19/27) in the unbound #212121
                GapText("Basics", family: .walsheim, medium: true, size: 19, lineHeight: 27, color: Self.titleInk)
                    .fixedSize()
                    .accessibilityAddTraits(.isHeader)
                    .padding(.leading, 19) // Gap: 19 inside the card, no spacing token
                    .padding(.top, 17) // Gap: 17 over the title, no spacing token
                    .padding(.bottom, 6) // Gap: 6 under the title, no spacing token
                ForEach(Array(fund.facts.enumerated()), id: \.offset) { index, fact in
                    HStack(spacing: 0) {
                        copy(fact.label)
                            .fixedSize()
                            .frame(height: 21)
                        Spacer(minLength: SpacingScale.spaceXs)
                        // Gap: Rg 15/21 in the unbound black 56%
                        GapText(fact.value, family: .walsheim, medium: false, size: 15, lineHeight: 21, color: Self.valueInk)
                            .fixedSize()
                    }
                    .padding(.horizontal, 19) // Gap: 19 inside the card, no spacing token
                    .padding(.vertical, SpacingScale.spaceLg)
                    .overlay(alignment: .bottom) {
                        if index < fund.facts.count - 1 {
                            Self.factRule
                                .frame(height: BorderTokens.hairline)
                                .padding(.horizontal, SpacingScale.spaceLg)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.bottom, 4) // Gap: 4 under the last row, no spacing token
        }
    }

    /// 41:1774: the five largest holdings, a row each
    private var holdingsList: some View {
        card("Fund holdings", expands: true) {
            VStack(spacing: 0) {
                ForEach(fund.holdings.prefix(5)) { holding in
                    row(holding.name, share: Self.share(holding.share)) {
                        badge {
                            Image(holding.logo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 21.706, height: 21.706)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
    }

    /// A holding's share as the frame writes it: "6.42%"
    private static func share(_ value: Double) -> String {
        String(format: "%.2f%%", value)
    }

    /// 41:1808: twenty holdings as a map, each cell where the frame puts it; a wider box widens the cells with it
    private func holdingsMap(box: CGFloat) -> some View {
        let widen = box / 321
        return card("Fund holdings") {
            ZStack(alignment: .topLeading) {
                Self.mapGround
                ForEach(Array(zip(fund.holdings, Self.slots)), id: \.0.id) { holding, slot in
                    mapCell(holding, slot.tier)
                        .frame(width: slot.cell.width * widen, height: slot.cell.height)
                        .background(ColorScale.surfaceWidget)
                        .clipped()
                        .at(slot.cell.minX * widen, slot.cell.minY)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(holding.name), \(Self.share(holding.share))")
                }
            }
            .frame(width: box, height: 285, alignment: .topLeading)
        }
    }

    /// A map cell's logo, name where its tier has one, and share. The logo's tile is the fund houses' own
    /// (`FundHouseLogo`), which the frame draws here a tenth of a point rounder. Gap: the text is GT Walsheim Rg
    /// at 8 to 11 pt on the font's own line, none of it a text style.
    @ViewBuilder private func mapCell(_ holding: MutualFund.Holding, _ tier: Slot.Tier) -> some View {
        switch tier {
        case .first:
            VStack(spacing: 3) { // Gap: 3 between the lines, no spacing token
                FundHouseLogo(name: holding.logo, side: 24, bordered: false)
                GapText(holding.short, family: .walsheim, medium: false, size: 10, lineHeight: 12, color: ColorScale.contentPrimary)
                    .fixedSize()
                GapText(Self.share(holding.share), family: .walsheim, medium: false, size: 11, lineHeight: 13, color: Self.upInk)
                    .fixedSize()
            }
        case .second:
            Stack(gap: .space2xs, alignment: .center) {
                FundHouseLogo(name: holding.logo, side: 18, bordered: false)
                GapText(holding.short, family: .walsheim, medium: false, size: 8, lineHeight: 10, color: ColorScale.contentPrimary)
                    .fixedSize()
                GapText(Self.share(holding.share), family: .walsheim, medium: false, size: 9, lineHeight: 11, color: Self.upInk)
                    .fixedSize()
            }
        case .third:
            Stack(gap: .space2xs, alignment: .center) {
                FundHouseLogo(name: holding.logo, side: 14, bordered: false)
                GapText(Self.share(holding.share), family: .walsheim, medium: false, size: 8, lineHeight: 10, color: Self.upInk)
                    .fixedSize()
            }
        }
    }

    /// 41:1924: each sector's share, its name, and a bar as long as the share
    private func sectors(box: CGFloat) -> some View {
        // The longest bar runs from 144 to 17 short of the box's trailing edge: 160 in the frame
        let longest = box - 144 - 17
        let most = fund.sectors.map(\.share).max() ?? 1
        return card("Sectors exposure") {
            VStack(spacing: 0) {
                ForEach(fund.sectors, id: \.name) { sector in
                    ZStack(alignment: .leading) {
                        // Gap: Md 15/21 has no text style
                        GapText(MutualFundsHouseMap.percent(sector.share), family: .walsheim, medium: true, size: 15, lineHeight: 21, color: ColorScale.contentPrimary)
                            .fixedSize()
                            .padding(.leading, 16) // Gap: 16 inside the box, no spacing token
                        copy(sector.name)
                            .fixedSize()
                            .frame(height: 21)
                            .padding(.leading, 69) // Gap: the names start 69 inside the box, no spacing token
                        Capsule()
                            .fill(Self.accentInk)
                            .frame(width: longest * sector.share / most, height: 11)
                            .padding(.leading, 144) // Gap: the bars start 144 inside the box, no spacing token
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 57)
                    .overlay(alignment: .bottom) { rowRule }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(sector.name), \(MutualFundsHouseMap.percent(sector.share))")
                }
            }
        }
    }

    /// 41:1947: the three sizes of company as one bar, then a row each with its share of the fund
    private func marketCap(box: CGFloat) -> some View {
        card("Market cap exposure") {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(Self.sizes.enumerated()), id: \.offset) { place, size in
                        size.ink.frame(width: box * fund.caps[place] / 100)
                    }
                }
                .frame(width: box, height: 43, alignment: .leading)
                .accessibilityHidden(true)
                ForEach(Array(Self.sizes.enumerated()), id: \.offset) { place, size in
                    row(size.name, share: MutualFundsHouseMap.percent(fund.caps[place])) {
                        badge { size.ink.frame(width: 13, height: 13) }
                    }
                }
            }
        }
    }

    /// 41:1968: the managers' portraits side by side, running off the card's trailing edge
    private var managers: some View {
        Surface(surface: .surfaceWidget, radius: .radius23) {
            VStack(alignment: .leading, spacing: 19) { // Gap: 19 under the title, no spacing token
                title("Fund managers")
                    .padding(.leading, SpacingScale.spaceXl)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 19) { // Gap: 19 between the portraits, no spacing token
                        ForEach(Array(fund.managers.enumerated()), id: \.offset) { _, manager in
                            Stack(gap: .spaceMd) {
                                Image(manager.portrait)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 188, height: 203)
                                    .frame(width: 176, height: 186)
                                    // The frame has #33302F behind the portrait, which covers it; drawn here it
                                    // showed as a dark fringe round the corners, so it is left out
                                    .clipShape(RoundedRectangle(cornerRadius: RadiusToken.radius27.value, style: .continuous))
                                    .accessibilityHidden(true)
                                Stack {
                                    copy(manager.name)
                                        .fixedSize()
                                        .frame(height: 21)
                                    small(manager.since)
                                        .fixedSize()
                                        .frame(height: 19)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(.horizontal, SpacingScale.spaceXl)
                }
            }
            .padding(.top, SpacingScale.spaceXl)
            .padding(.bottom, SpacingScale.space3xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: The foot

    /// 37:4147: the wash at the foot of the screen, 125 tall, with the advisor, "Start SIP" and "more" on it.
    /// Gap: the frame blurs what is behind the wash by 12; here it is the system's thinnest material.
    private var foot: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack(alignment: .top) {
                Rectangle().fill(.ultraThinMaterial)
                LinearGradient(colors: [Self.footTop, Self.footWash], startPoint: .top, endPoint: .bottom)
                HStack(alignment: .center, spacing: SpacingScale.spaceMdLg) {
                    // 37:4150: the advisor, in a pill of her own
                    Image("MFDetailAvatar")
                        .frame(width: 52, height: 53)
                        .background {
                            Capsule().fill(Self.pillFill)
                                .shadow(color: Color.black.opacity(0.03), radius: 7.5, x: 0, y: 3) // Gap: 0 3 15 at 3%, not a Shadow style. ds-lint-ignore: no_raw_shadow
                        }
                        .accessibilityLabel("Ask your advisor")
                    startSIP
                    // 37:4219: three dots; the drawing carries its own shadow, 129 across around its 53
                    Image("MFDetailMore")
                        .frame(width: 129, height: 129)
                        .offset(y: 3)
                        .frame(width: 53, height: 53)
                        .accessibilityLabel("More")
                }
                .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
                .padding(.top, 18) // Gap: 18 inside the wash, no spacing token
            }
            .frame(height: 125)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    /// 37:4213: "Start SIP" over "Balances your risk", after a green plus
    private var startSIP: some View {
        HStack(spacing: 9.5) { // Gap: 9.5 from the plus to the words, no spacing token
            Image(systemName: "plus")
                .font(.system(size: 17, weight: .semibold)) // ds-lint-ignore: no_hand_set_type (an SF Symbol's size and weight)
                .foregroundStyle(ColorScale.contentOnColor)
                .frame(width: 33, height: 33)
                .background(Circle().fill(Self.largeInk))
                .accessibilityHidden(true)
            Stack {
                DsText("Start SIP", variant: .h6)
                    .fixedSize()
                small("Balances your risk")
                    .fixedSize()
                    .frame(height: 19)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 9.5) // Gap: 9.5 inside the pill, no spacing token
        .frame(maxWidth: .infinity)
        .frame(height: 59)
        .background(Capsule().fill(Self.pillFill).dsShadow(.shadow3))
        .accessibilityElement(children: .combine)
    }
}

/// A curve's heights as something SwiftUI can move from one set to another, point by point
struct AnimatableSeries: VectorArithmetic {
    var values: [Double]

    init(_ values: [Double]) { self.values = values }

    static var zero: AnimatableSeries { AnimatableSeries([]) }

    /// Two curves point by point; one with fewer points (or none, as `zero` has) counts as flat there
    private static func each(_ a: AnimatableSeries, _ b: AnimatableSeries, _ combine: (Double, Double) -> Double) -> AnimatableSeries {
        let count = max(a.values.count, b.values.count)
        return AnimatableSeries((0..<count).map { combine($0 < a.values.count ? a.values[$0] : 0, $0 < b.values.count ? b.values[$0] : 0) })
    }

    static func + (a: AnimatableSeries, b: AnimatableSeries) -> AnimatableSeries { each(a, b, +) }
    static func - (a: AnimatableSeries, b: AnimatableSeries) -> AnimatableSeries { each(a, b, -) }
    mutating func scale(by factor: Double) { values = values.map { $0 * factor } }
    var magnitudeSquared: Double { values.reduce(0) { $0 + $1 * $1 } }
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

#Preview {
    MutualFundDetailView()
}
