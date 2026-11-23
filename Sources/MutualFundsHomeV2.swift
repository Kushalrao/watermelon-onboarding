import SwiftUI

/// Figma "iPhone 14 Plus - 541" (47:6749, file `sub7vIn6sMBlHb4SIWHyek`): the mutual funds homepage, second
/// version. "Explore Mutual Funds", a search field, a row of kinds of fund, a tinted card of funds ranked by
/// performance, two plain lists, a row of fund categories, the month's risers as small charts, a list under the
/// cube heading, and the categories again; the advisor's pill stays at the foot.
///
/// It is what a plain launch opens, and `-mf` opens it too; the first version (`MutualFundsHomeView`, with the
/// fund houses' map) is kept behind `-mfHomeV1`. A tap on a fund, in a row or on a small chart, pushes that
/// fund's page (`MutualFundDetailView`); `-mfFund` opens with the drawn fund's already up. The frame draws one
/// state only: the search field, the kinds of fund, the categories and the expand button do not respond yet.
struct MutualFundsHomeV2View: View {
    /// How a rating is coloured (57:8336, 57:8351, 57:8366)
    enum Tone {
        case lavender, yellow, green

        /// The figure
        var ink: Color {
            switch self {
            case .lavender: Color(hex: 0x74527B) // Gap: accent-lavender/700 has no semantic token
            case .yellow: Color(hex: 0x684600) // Gap: accent-yellow/800 has no semantic token
            case .green: Color(hex: 0x043300) // Gap: utility-green/900 has no semantic token
            }
        }

        /// The filled dots
        var dot: Color {
            switch self {
            case .lavender: Color(hex: 0xA872B3) // Gap: accent-lavender/500 has no semantic token
            case .yellow: Color(hex: 0xB47E00) // Gap: accent-yellow/500 has no semantic token
            case .green: Color(hex: 0x3FD519) // Gap: utility-green/400 has no semantic token
            }
        }
    }

    /// A fund in a list (57:8328)
    struct Fund: Identifiable {
        let id: Int
        let name: String
        /// The fund house's logo, an image set's name
        let logo: String
        /// What it has returned, as written
        let returned: String
        /// Its rating out of five, as written, and how many of the five dots the frame fills for it
        let rating: String
        let filled: Int
        let tone: Tone
        /// "Direct • Equity • Large cap"
        let kind: String
    }

    /// A riser of the month, with its small chart as drawn (57:8554)
    struct Riser: Identifiable {
        let id: Int
        /// The name over two lines, broken where the frame breaks it
        let name: String
        let fund: String
        let logo: String
        let returned: String
        /// The drawn area and line, image sets' names, and where each sits in the chart's 202 × 153.72 panel
        let area: String
        let areaTop: CGFloat
        let line: String
        let lineAt: CGPoint
        /// The prices at the trailing edge that can be seen, with how far down each is
        let prices: [(String, CGFloat)]
    }

    /// 47:7331: the kinds of fund, in the frame's order
    static let kinds: [(title: String, orb: String)] = [
        ("Equity", "MFHome2ChipEquity"), ("Banking", "MFHome2ChipBanking"), ("Small cap", "MFHome2ChipSmallCap"),
        ("Debt", "MFHome2ChipDebt"), ("Real estate", "MFHome2ChipRealEstate"), ("Mid cap", "MFHome2ChipMidCap"),
        ("Liquid", "MFHome2ChipLiquid"), ("Large cap", "MFHome2ChipLargeCap"), ("Technology", "MFHome2ChipTechnology"),
    ]

    /// 57:8327: the ranked card's three funds, as drawn: the first name is written under two houses' logos
    static let ranked: [Fund] = [
        Fund(id: 0, name: "Nippon Pru Large Cap", logo: "MFHomeNippon", returned: "18.7%", rating: "3.1", filled: 3, tone: .lavender, kind: "Direct • Equity • Large cap"),
        Fund(id: 1, name: "Nippon Pru Large Cap", logo: "MFHomeAdityaBirla", returned: "18.7%", rating: "2.9", filled: 2, tone: .yellow, kind: "Direct • Equity • Large cap"),
        Fund(id: 2, name: "Axis Pru Large Cap", logo: "MFHomeAxis", returned: "18.7%", rating: "4.5", filled: 5, tone: .green, kind: "Direct • Equity • Large cap"),
    ]

    /// 57:8429: "Upcoming mid caps"
    static let midCaps: [Fund] = [
        Fund(id: 0, name: "Motilal Oswal Midcap", logo: "MFHomeMotilal", returned: "27.3%", rating: "3.1", filled: 3, tone: .lavender, kind: "Direct • Equity • Mid cap"),
        Fund(id: 1, name: "Edelweiss Mid Cap", logo: "MFHomeEdelweiss", returned: "25.4%", rating: "3.1", filled: 3, tone: .lavender, kind: "Direct • Equity • Mid cap"),
        Fund(id: 2, name: "Invesco India Mid Cap", logo: "MFHomeInvesco", returned: "24.2%", rating: "3.1", filled: 3, tone: .lavender, kind: "Direct • Equity • Mid cap"),
    ]

    /// 57:8430, and again under the cube heading (57:8659): "New infrastructure funds"
    static let infrastructure: [Fund] = [
        Fund(id: 0, name: "ICICI Pru Infrastructure", logo: "MFHomeICICI", returned: "31.2%", rating: "4.5", filled: 5, tone: .green, kind: "Direct • Equity • Sectoral"),
        Fund(id: 1, name: "Bandhan Infrastructure", logo: "MFHomeBandhan", returned: "29.6%", rating: "4.5", filled: 5, tone: .green, kind: "Direct • Equity • Sectoral"),
        Fund(id: 2, name: "Quant Infrastructure", logo: "MFHomeQuant", returned: "27.8%", rating: "4.5", filled: 5, tone: .green, kind: "Direct • Equity • Sectoral"),
    ]

    /// 47:7226: the categories. The frame's third and fourth cards are empty, and are kept so.
    static let categories: [(title: String, art: String, artTop: CGFloat)?] = [
        ("Equity funds", "MFHome2CatEquity", 70), ("Hybrid funds", "MFHome2CatHybrid", 79), nil, nil,
    ]

    /// 47:7141: "Rising in november"
    static let risers: [Riser] = [
        Riser(id: 0, name: "Axis Midcap Fund", fund: "Axis Midcap Fund", logo: "MFHomeAxis", returned: "6.7%",
              area: "MFHome2ChartAxisArea", areaTop: 18.08, line: "MFHome2ChartAxisLine", lineAt: CGPoint(x: 7.19, y: 17.63),
              prices: [("¢107", 13.08), ("¢102", 65.5), ("¢96", 133)]),
        Riser(id: 1, name: "SBI Contra\nFund", fund: "SBI Contra Fund", logo: "MFHomeSBI", returned: "7.8%",
              area: "MFHome2ChartSBIArea", areaTop: 5.04, line: "MFHome2ChartSBILine", lineAt: CGPoint(x: 7.41, y: 4.72),
              prices: [("¢108", 0.05), ("¢102", 65.5), ("¢96", 133)]),
    ]

    private static let titleInk = Color(hex: 0x212121) // Gap: #212121, the title's colour, is unbound
    private static let searchInk = Color.black.opacity(0.5) // Gap: black 50%, the search field's word, is unbound
    private static let returnInk = Color(hex: 0x3FD519) // Gap: utility-green/400 has no semantic token
    private static let rankedInk = Color(hex: 0xA872B3) // Gap: accent-lavender/500 has no semantic token
    private static let rankedTop = Color(hex: 0xD0F7F4, opacity: 0.24) // Gap: #D0F7F4 24%, the top of the ranked card, is unbound
    private static let rankedFoot = Color(hex: 0xE7FCE4, opacity: 0.24) // Gap: #E7FCE4 24%, the foot of the ranked card, is unbound
    private static let footWash = Color(hex: 0xF3F6F3) // Gap: #F3F6F3, the wash under the pill, is unbound
    private static let axisInk = Color.black.opacity(0.4) // Gap: black 40%, a small chart's prices, is unbound
    private static let gridInk = Color.black.opacity(0.13) // Gap: black 13%, a small chart's middle line, is unbound
    private static let baseInk = Color.black.opacity(0.33) // Gap: black 33%, a small chart's base line, is unbound

    /// The fund whose page is pushed over this one; `-mfFund` opens with the drawn fund's already up
    @State private var openedFund: MutualFund? = ProcessInfo.processInfo.arguments.contains("-mfFund") ? .hsbc : nil
    private static let push = Animation.spring(response: 0.45, dampingFraction: 0.92)

    /// Opens a fund's page with the return the homepage writes for it
    private func open(_ name: String, logo: String, returned: String? = nil) {
        guard openedFund == nil else { return }
        Haptics.tap()
        let found = MutualFund.named(name, logo: logo)
        let figure = returned.flatMap { Double($0.replacingOccurrences(of: "%", with: "")) }
        withAnimation(Self.push) { openedFund = figure.map(found.returning) ?? found }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Keeps the page from running up under the status bar as it scrolls
            Color.clear.frame(height: 1)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Gap: Reckless Medium 43/49 has no text style (H1 is Regular 45/49). Broken where the frame breaks it.
                    GapText("Explore Mutual\nFunds", family: .reckless, medium: true, size: 43, lineHeight: 49, color: Self.titleInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Explore Mutual Funds")
                        .accessibilityAddTraits(.isHeader)
                        .padding(.horizontal, 17) // Gap: the title sits 17 from the screen's edges, no spacing token
                        .padding(.top, 36) // Gap: the title starts 37 under the status bar, no spacing token
                    search
                        .padding(.horizontal, SpacingScale.spaceLg)
                        .padding(.top, 17) // Gap: 17 under the title, no spacing token
                    kinds
                        .padding(.top, 11) // Gap: 11 under the search field, no spacing token
                    rankedCard
                        .padding(.horizontal, SpacingScale.spaceMdLg)
                        .padding(.top, 36) // Gap: 36 under the row, no spacing token
                    list("Upcoming mid caps", Self.midCaps)
                        .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
                        .padding(.top, 36) // Gap: 36 under the card, no spacing token
                    list("New infrastructure funds", Self.infrastructure)
                        .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
                        .padding(.top, 70) // Gap: 70 between the lists, no spacing token
                    categories
                        .padding(.top, 69) // Gap: 69 under the list, no spacing token
                    risers
                        .padding(.top, 69) // Gap: 69 under the categories, no spacing token
                    cubeList
                        .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
                        .padding(.top, 81) // Gap: 81 under the charts, no spacing token
                    categories
                        .padding(.top, 100) // Gap: 100 under the list, no spacing token
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // Room to scroll the last card clear of the advisor's pill
                .padding(.bottom, SpacingScale.space10xl)
            }
        }
        // The frame has no fill of its own: white
        .background(ColorScale.surfaceWidget.ignoresSafeArea())
        .overlay {
            // 47:6970: the page fades into a pale wash behind the pill, 125 up from the foot of the screen
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(colors: [Self.footWash.opacity(0), Self.footWash], startPoint: .top, endPoint: .bottom)
                    .frame(height: 125)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
        .accessibilityHidden(openedFund != nil)
        // The advisor stays at the foot of the page, as on the fund page
        .advisorBar()
        .overlay {
            // iOS push: the fund's page comes in from the trailing edge, over this one and its advisor
            ZStack {
                if let openedFund {
                    MutualFundDetailView(fund: openedFund) { withAnimation(Self.push) { self.openedFund = nil } }
                        .transition(.move(edge: .trailing))
                }
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: Search and kinds

    /// 47:7550: the search field, 57 tall
    private var search: some View {
        Surface(surface: .surfaceWidget, radius: .radius27, border: .borderStrong, shadow: .none) {
            Stack(direction: .horizontal, gap: .spaceMdLg, alignment: .center) {
                Image("MFHome2Search")
                    .accessibilityHidden(true)
                // Gap: Md 17/23 at 5% tracking, in capitals, has no text style
                GapText("SEARCH", family: .walsheim, medium: true, size: 17, lineHeight: 23, trackingPercent: 5, color: Self.searchInk)
                    .fixedSize()
                Spacer(minLength: 0)
            }
            .padding(.leading, 18) // Gap: 18 inside the field, no spacing token
            .frame(height: 57)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Search")
    }

    /// 47:7331: the kinds of fund, running off the trailing edge
    private var kinds: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Stack(direction: .horizontal, gap: .spaceMd) {
                ForEach(Self.kinds, id: \.title) { kind in
                    // 47:7332. Gap: #FEFEFE with a 1 pt edge in the frame; here the white widget surface with the hairline
                    Surface(surface: .surfaceWidget, radius: .radius27, border: .borderSubtle, shadow: .token(.shadow1)) {
                        Stack(direction: .horizontal, gap: .spaceMd, alignment: .center) {
                            // The orb is drawn with its own soft shadow, 44.18 across around its 27
                            Image(kind.orb)
                                .resizable()
                                .frame(width: 44.18, height: 44.18)
                                .frame(width: 27, height: 27)
                                .accessibilityHidden(true)
                            // Gap: P4 on the 21 pt line this file gives it (the token's line is 23)
                            GapText(kind.title, family: .walsheim, medium: false, size: 15, lineHeight: 21, color: ColorScale.contentPrimary)
                                .fixedSize()
                        }
                        .padding(.horizontal, SpacingScale.spaceLg)
                        .padding(.vertical, 12) // Gap: 12 above and below, edge included, no spacing token
                    }
                }
            }
            .padding(.horizontal, SpacingScale.spaceLg)
        }
        .scrollClipDisabled()
    }

    // MARK: Lists

    /// A list's title (57:8326). Gap: H4 on the 29 pt line this file gives it (the token's line is 35)
    private func title(_ string: String) -> some View {
        GapText(string, family: .walsheim, medium: true, size: 23, lineHeight: 29, color: ColorScale.contentPrimary)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
    }

    /// 57:8325: "Performing small caps", ranked, in a tinted card with a white one inside it
    private var rankedCard: some View {
        VStack(alignment: .leading, spacing: 22) { // Gap: 22 under the title, no spacing token
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 1) { // Gap: 1 between the two lines, no spacing token
                    // Gap: Rg 15/21 in accent-lavender/500 has no text style or content token
                    GapText("Ranked by performance", family: .walsheim, medium: false, size: 15, lineHeight: 21, color: Self.rankedInk)
                        .fixedSize()
                    title("Performing small caps")
                }
                Spacer(minLength: 0)
                // 57:8377: the expand button, 35 across
                Image("MFHome2Expand")
                    .frame(width: 35, height: 35)
                    .background(Circle().fill(ColorScale.surfaceWidget))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 17) // Gap: 17 inside the card, no spacing token
            Surface(surface: .surfaceWidget, radius: .radius15, shadow: .none) {
                VStack(spacing: 37) { // Gap: 37 between the rows, no spacing token
                    ForEach(Self.ranked) { row($0) }
                }
                .padding(17) // Gap: 17 inside the white card, no spacing token
            }
            .padding(.horizontal, SpacingScale.spaceMdLg)
        }
        .padding(.vertical, 17) // Gap: 17 above and below, no spacing token
        .background(LinearGradient(colors: [Self.rankedTop, Self.rankedFoot], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: RadiusToken.radius23.value, style: .continuous))
    }

    /// 57:8429: a title over three funds
    private func list(_ heading: String, _ funds: [Fund]) -> some View {
        Stack(gap: .space2xl) {
            title(heading)
            rows(funds)
        }
    }

    private func rows(_ funds: [Fund]) -> some View {
        Stack(gap: .space3xl) {
            ForEach(funds) { row($0) }
        }
    }

    /// 57:8328: a fund's logo, its name and return, its rating in a figure and five dots, and what kind it is
    private func row(_ fund: Fund) -> some View {
        Stack(direction: .horizontal, gap: .spaceLg) {
            FundHouseLogo(name: fund.logo, side: 51)
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: SpacingScale.spaceXs) {
                    DsText(fund.name, variant: .p3)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    // Gap: H6 (Md 17/23) in utility-green/400, which has no content token
                    GapText(fund.returned, family: .walsheim, medium: true, size: 17, lineHeight: 23, color: Self.returnInk)
                        .fixedSize()
                }
                Stack(direction: .horizontal, gap: .spaceXs, alignment: .center) {
                    // Gap: Md 17/21 at 4% tracking has no text style
                    GapText(fund.rating, family: .walsheim, medium: true, size: 17, lineHeight: 21, trackingPercent: 4, color: fund.tone.ink)
                        .fixedSize()
                    HStack(spacing: 3) { // Gap: 3 between the dots, no spacing token
                        ForEach(0..<5, id: \.self) { place in
                            if place < fund.filled {
                                Circle().fill(fund.tone.dot).frame(width: 15, height: 15)
                            } else {
                                Circle().strokeBorder(ColorScale.borderDefault, lineWidth: 1).frame(width: 15, height: 15) // Gap: a 1 pt ring, not the hairline
                            }
                        }
                    }
                }
                .padding(.top, 3) // Gap: 3 under the name, no spacing token
                // Gap: P5 on the 19 pt line this file gives it (the token's line is 21)
                GapText(fund.kind, family: .walsheim, medium: false, size: 13, lineHeight: 19, color: ColorScale.contentTertiary)
                    .lineLimit(1)
                    .padding(.top, SpacingScale.spaceXs)
            }
        }
        .frame(height: 71, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture { open(fund.name, logo: fund.logo, returned: fund.returned) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(fund.name), \(fund.returned), rated \(fund.rating) of 5, \(fund.kind)")
        .accessibilityAddTraits(.isButton)
    }

    /// 57:8659: the cube, a title and a line about it, then three funds
    private var cubeList: some View {
        VStack(alignment: .leading, spacing: 33) { // Gap: 33 under the heading, no spacing token
            HStack(alignment: .top, spacing: 17) { // Gap: 17 from the picture to the words, no spacing token
                // 47:7266: the cube, 59.23 × 57.21 here
                Image("TopicCubeGreen")
                    .resizable()
                    .frame(width: 59.23, height: 57.21)
                    .padding(.top, 3.67) // Gap: the picture sits 3.67 down, no spacing token
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) { // Gap: 3 under the title, no spacing token
                    DsText("Rising small cap funds", variant: .h5)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                    // Gap: P5 on the 19 pt line this file gives it (the token's line is 21)
                    GapText("Symbol the soaring bird formed from geometric shapes and fluid arcs, expressing", family: .walsheim, medium: false, size: 13, lineHeight: 19, color: ColorScale.contentTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.trailing, SpacingScale.spaceLg)
            .frame(height: 68, alignment: .top)
            rows(Self.infrastructure)
        }
    }

    // MARK: Categories

    /// 57:8505: "Rising small cap funds" over a row of square cards, running off the trailing edge
    private var categories: some View {
        Stack(gap: .space2xl) {
            DsText("Rising small cap funds", variant: .h3)
                .fixedSize()
                // H3 on the 35 pt line the frame gives it (the token's line is 39)
                .frame(height: 35)
                .accessibilityAddTraits(.isHeader)
                .padding(.leading, 17) // Gap: 17 from the screen's edge, no spacing token
            ScrollView(.horizontal, showsIndicators: false) {
                Stack(direction: .horizontal, gap: .spaceMdLg) {
                    ForEach(Array(Self.categories.enumerated()), id: \.offset) { _, category in
                        // 47:7227. Gap: #FEFEFE with a 1 pt edge in the frame; here the white widget surface with the hairline
                        Surface(surface: .surfaceWidget, radius: .radius23, border: .borderSubtle, shadow: .none) {
                            ZStack(alignment: .topLeading) {
                                if let category {
                                    // Gap: P3 in the unbound #212121; here in the primary content colour
                                    DsText(category.title, variant: .p3)
                                        .fixedSize()
                                        .at(17, 17)
                                    Image(category.art)
                                        .at(17, category.artTop)
                                        .accessibilityHidden(true)
                                }
                            }
                            .frame(width: 173, height: 173, alignment: .topLeading)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityHidden(category == nil)
                    }
                }
                .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
            }
        }
    }

    // MARK: Risers

    /// 57:8904: "Rising in november", each riser's name over its month as a small chart
    private var risers: some View {
        VStack(alignment: .leading, spacing: 27) { // Gap: 27 under the title, no spacing token
            title("Rising in november")
                .padding(.leading, 17) // Gap: 17 from the screen's edge, no spacing token
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) { // Gap: 10 between the risers, no spacing token
                    ForEach(Self.risers) { riser($0) }
                }
                .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
            }
            // The cards' shadows reach past the row
            .scrollClipDisabled()
        }
    }

    /// 57:8554: the fund over its card, 206.5 across
    private func riser(_ riser: Riser) -> some View {
        Stack(gap: .spaceMdLg) {
            // 57:8576: the logo, the name over two lines, and a chevron
            ZStack(alignment: .topLeading) {
                FundHouseLogo(name: riser.logo, side: 41)
                    .at(0, 1)
                DsText(riser.name, variant: .p3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 125, alignment: .leading)
                    .at(50, 0)
                Image("MFHome2Chevron")
                    .at(186.02, 5.47)
                    .accessibilityHidden(true)
            }
            .frame(width: 193.8, height: 46, alignment: .topLeading)
            // 57:8555. Gap: #FEFEFE in the frame; here the white widget surface
            Surface(surface: .surfaceWidget, radius: .radius23) {
                ZStack(alignment: .topLeading) {
                    chart(riser)
                        .at(4, 21.14)
                    // Gap: GT Walsheim Bold 20.5/25.2 has no text style, and the app has no Bold face: Medium here
                    GapText(riser.returned, family: .walsheim, medium: true, size: 20.517, lineHeight: 25.207, color: ColorScale.contentPrimary)
                        .fixedSize()
                        .at(13, 11)
                    // Gap: Rg 8.8/12.3 has no text style
                    GapText("1M returns", family: .walsheim, medium: false, size: 8.793, lineHeight: 12.31, color: ColorScale.contentTertiary)
                        .fixedSize()
                        .at(13, 36.21)
                }
                .frame(width: 202, height: 173, alignment: .topLeading)
            }
            .padding(.leading, 1) // Gap: the card sits 1 in from the name, no spacing token
        }
        .frame(width: 206.5, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { open(riser.fund, logo: riser.logo) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(riser.fund), \(riser.returned) in a month")
        .accessibilityAddTraits(.isButton)
    }

    /// 57:8556: the month as drawn, on its 202 × 153.72 panel: two lines across, the area and its line, and the
    /// prices at the trailing edge
    private func chart(_ riser: Riser) -> some View {
        ZStack(alignment: .topLeading) {
            ColorScale.surfaceBase
            Self.gridInk
                .frame(width: 187.57, height: 0.55)
                .at(7.77, 69.95)
            Self.baseInk
                .frame(width: 187.57, height: 0.55)
                .at(7.77, 137.45)
            Image(riser.area)
                .at(7.8, riser.areaTop)
            Image(riser.line)
                .at(riser.lineAt.x, riser.lineAt.y)
            ForEach(riser.prices, id: \.0) { price, top in
                // Gap: Rg 6.7/9.4 at 7% tracking has no text style
                GapText(price, family: .walsheim, medium: false, size: 6.659, lineHeight: 9.434, trackingPercent: 7, color: Self.axisInk)
                    .fixedSize()
                    .frame(width: 194.7, alignment: .trailing)
                    .at(0, top)
            }
        }
        .frame(width: 202, height: 153.72, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 8.324, style: .continuous)) // Gap: 8.324, the panel's radius, has no token
    }
}

#Preview {
    MutualFundsHomeV2View()
}
