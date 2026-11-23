import SwiftUI

/// Figma "iPhone 14 Plus - 511" (10:4545, file `sub7vIn6sMBlHb4SIWHyek`): the mutual funds homepage. The rule under
/// the status bar, "Explore mutual funds", the "All · Watchlist" row, and runs of funds, each under a picture, a
/// title and a line about it, with the advisor's pill at the foot.
///
/// Before the title is the fund houses' map (15:6337, `MutualFundsHouseMap`), which arrives cell by cell when the
/// page opens. Under the runs come three sections drawn in other frames of the same file, in the order they were asked for:
/// "Performing small caps" (15:6246), funds in columns of four that scroll sideways; "All mutual funds" (15:6247),
/// one card of rows; and the tinted cards (15:6248), each a short ranked list. No frame shows them together, so
/// the space between one section and the next is `space4xl`, the scale's gap between major sections.
///
/// It is what a plain launch opens; `-mf` opens it too. The frames draw one state only, so the row does not switch.
/// A tap on a fund pushes that fund's page (`MutualFundDetailView`, with its content from `MutualFund`); `-mfFund`
/// opens with the drawn fund's already up.
struct MutualFundsHomeView: View {
    /// A run of funds under one heading (10:4562)
    struct Collection: Identifiable {
        let id: Int
        /// The picture beside the heading, an image set's name
        let art: String
        let title: String
        let detail: String
        let funds: [Fund]
    }

    /// One fund, as a card (10:4563) or a row (13:5774, 8:3851)
    struct Fund: Identifiable {
        let id: Int
        /// The fund house, as written beside its logo on a card
        var house = ""
        /// The fund house's logo, an image set's name
        let logo: String
        let name: String
        /// What it has returned, as written
        let returned: String
        /// The span the return is over, in its badge
        var period = "3Y"
        /// The line under its name in a list: "Growth • Equity • Small cap"
        var kind = ""
    }

    /// A tinted card with a short ranked list (8:3066)
    struct Ranking: Identifiable {
        let id: Int
        let title: String
        let detail: String
        let tint: Color
        let funds: [Fund]
    }

    /// The frame's two runs, with the copy as it is drawn
    static let collections: [Collection] = (0..<2).map { run in
        Collection(
            id: run,
            art: "TopicCubeGreen",
            title: "Rising small cap funds",
            detail: "Symbol the soaring bird formed from geometric shapes and fluid arcs, expressing",
            funds: (0..<2).map { Fund(id: $0, house: "HDFC", logo: "MFHomeHDFC", name: "HDFC Small Cap Fund", returned: "24.6%") }
        )
    }

    /// 13:5868: "Performing small caps", in the frame's two columns of four
    static let performing: [[Fund]] = [
        [
            Fund(id: 0, logo: "MFHomeHDFC", name: "HDFC Small Cap Fund", returned: "27.6%"),
            Fund(id: 1, logo: "MFHomeQuant", name: "Quant Small Cap Fund", returned: "24.6%"),
            Fund(id: 2, logo: "MFHomeTata", name: "Tata Small Cap Fund", returned: "23.2%"),
            Fund(id: 3, logo: "MFHomeNippon", name: "Nippon India Small Cap", returned: "22.4%"),
        ],
        [
            Fund(id: 4, logo: "MFHomeSBI", name: "SBI Small Cap Fund", returned: "20.9%"),
            Fund(id: 5, logo: "MFHomeBandhan", name: "Bandhan Small Cap Fund", returned: "20.3%"),
            Fund(id: 6, logo: "MFHomeAxis", name: "Axis Small Cap Fund", returned: "19.6%"),
            Fund(id: 7, logo: "MFHomeKotak", name: "Kotak Small Cap Fund", returned: "18.8%"),
        ],
    ]

    /// 8:3850: "All mutual funds", the frame's seven rows
    static let allFunds: [Fund] = [
        Fund(id: 0, logo: "MFHomeQuant", name: "Quant Small Cap Fund", returned: "24.6%", kind: "Growth • Equity • Small cap"),
        Fund(id: 1, logo: "MFHomeHDFC", name: "HDFC Mid Cap Fund", returned: "26.1%", kind: "Growth • Equity • Mid cap"),
        Fund(id: 2, logo: "MFHomePPFAS", name: "Parag Parikh Flexi Cap", returned: "21.4%", kind: "Growth • Equity • Flexi cap"),
        Fund(id: 3, logo: "MFHomeSBI", name: "SBI Contra Fund", returned: "22.9%", kind: "Growth • Equity • Contra"),
        Fund(id: 4, logo: "MFHomeICICI", name: "ICICI Pru Large Cap", returned: "18.7%", kind: "Growth • Equity • Large cap"),
        Fund(id: 5, logo: "MFHomeMotilal", name: "Motilal Oswal Midcap", returned: "27.3%", kind: "Growth • Equity • Mid cap"),
        Fund(id: 6, logo: "MFHomeTata", name: "Tata Small Cap Fund", returned: "23.2%", kind: "Growth • Equity • Small cap"),
    ]

    /// 8:3066, 8:3097: the two tinted cards, with the same fund three times in each, as drawn
    static let rankings: [Ranking] = [
        Ranking(id: 0, title: "Best small caps", detail: "Ranked by performance", tint: aquaTint, funds: rankedFunds),
        Ranking(id: 1, title: "Rising healthcare funds", detail: "Ranked by performance", tint: leafTint, funds: rankedFunds),
    ]
    private static let rankedFunds: [Fund] = (0..<3).map {
        Fund(id: $0, logo: "MFHomeICICI", name: "ICICI Pru Large Cap", returned: "18.7%", kind: "Growth • Equity • Large cap")
    }

    private static let aquaTint = Color(hex: 0xD1EBED) // Gap: #D1EBED, the first card's tint, is unbound
    private static let leafTint = Color(hex: 0xDFEDD1) // Gap: #DFEDD1, the second card's tint, is unbound
    private static let cardEdge = Color.black.opacity(0.09) // Gap: black 9%, the inner card's edge, is unbound
    private static let titleInk = Color(hex: 0x212121) // Gap: #212121, the title's colour, is unbound
    private static let returnInk = Color(hex: 0x00A800) // Gap: utility-green/500 has no semantic token
    private static let ruleInk = Color.black.opacity(0.57) // Gap: black 57%, the rule's colour, is unbound
    private static let footWash = Color(hex: 0xF3F6F3) // Gap: #F3F6F3, the wash under the pill, is unbound

    /// The fund whose page is pushed over this one; `-mfFund` opens with the drawn fund's already up
    @State private var openedFund: MutualFund? = ProcessInfo.processInfo.arguments.contains("-mfFund") ? .hsbc : nil
    private static let push = Animation.spring(response: 0.45, dampingFraction: 0.92)

    /// Opens a fund's page with the return that was tapped: the homepage writes two for one of its funds
    private func open(_ fund: Fund) {
        guard openedFund == nil else { return }
        Haptics.tap()
        let figure = Double(fund.returned.replacingOccurrences(of: "%", with: ""))
        let found = MutualFund.named(fund.name)
        withAnimation(Self.push) { openedFund = figure.map(found.returning) ?? found }
    }

    var body: some View {
        VStack(spacing: 0) {
            rule
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Gap: Reckless Medium 43/49 has no text style (H1 is Regular 45/49)
                    // 15:6337: the fund houses' map, edge to edge, before the title. No frame shows the two together:
                    // the map takes the title's place 22 under the rule, and the title follows a section's space below.
                    MutualFundsHouseMap()
                        .padding(.top, 22) // Gap: 22 under the rule, no spacing token
                    // Broken where the frame breaks it: left to itself iOS keeps "funds" from standing alone
                    GapText("Explore mutual\nfunds", family: .reckless, medium: true, size: 43, lineHeight: 49, color: Self.titleInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Explore mutual funds")
                        .accessibilityAddTraits(.isHeader)
                        .padding(.horizontal, 17) // Gap: the title sits 17 from the screen's edges, no spacing token
                        .padding(.top, SpacingScale.space4xl)
                    tabs
                        .padding(.top, 19) // Gap: 19 under the title, no spacing token
                    VStack(alignment: .leading, spacing: 27) { // Gap: 27 between the runs, no spacing token
                        ForEach(Self.collections) { run($0) }
                    }
                    .padding(.horizontal, SpacingScale.spaceLg)
                    .padding(.top, 40) // Gap: 40 under the row, no spacing token
                    performing
                        .padding(.top, SpacingScale.space4xl)
                    allFunds
                        .padding(.horizontal, SpacingScale.spaceLg)
                        .padding(.top, SpacingScale.space4xl)
                    Stack(gap: .spaceXl) {
                        ForEach(Self.rankings) { ranking($0) }
                    }
                    .padding(.horizontal, SpacingScale.spaceMdLg)
                    .padding(.top, SpacingScale.space4xl)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // Room to scroll the last card clear of the advisor's pill
                .padding(.bottom, SpacingScale.space10xl)
            }
        }
        .background(MutualFundsHomeBackdrop())
        .overlay {
            // 10:4615: the page fades into a pale wash behind the pill, 125 up from the foot of the screen
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

    // MARK: Rule

    /// 10:4552: the line under the status bar; the page scrolls away beneath it
    private var rule: some View {
        Self.ruleInk
            .frame(height: 1)
            .padding(.horizontal, SpacingScale.spaceMd)
            .padding(.top, 4) // Gap: the 1 pt rule ends 5 under the status bar, no spacing token
            .accessibilityHidden(true)
    }

    // MARK: All · Watchlist

    /// 10:4712, 10:4556, 10:4559: "All" in its black pill, then "Watchlist" twice, as drawn; the row runs off the
    /// trailing edge
    private var tabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Stack(direction: .horizontal, gap: .space3xl, alignment: .center) {
                Surface(surface: .surfaceInverse, radius: .radius27, shadow: .token(.shadow2)) {
                    Stack(direction: .horizontal, gap: .spaceMd, alignment: .center) {
                        Image("MFHomeAll")
                        DsText("All", variant: .h3, color: .contentOnColor)
                            .fixedSize()
                    }
                    .padding(.horizontal, 11) // Gap: 11 inside the pill, no spacing token
                    .frame(height: 47)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isSelected)
                ForEach(0..<2, id: \.self) { _ in
                    HStack(spacing: 10) { // Gap: 10 from the bookmark to its word, no spacing token
                        Image("MFHomeBookmark")
                        // Gap: Rg 27/35 has no text style
                        GapText("Watchlist", family: .walsheim, medium: false, size: 27, lineHeight: 35, color: ColorScale.contentTertiary)
                            .fixedSize()
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, 17) // Gap: the row starts 17 from the screen's edge, no spacing token
        }
        // The pill's shadow reaches past the row
        .scrollClipDisabled()
    }

    // MARK: A run of funds

    private func run(_ collection: Collection) -> some View {
        VStack(alignment: .leading, spacing: 28) { // Gap: 28 from the heading to its funds, no spacing token
            HStack(alignment: .top, spacing: 17) { // Gap: 17 from the picture to the words, no spacing token
                // 10:4581: the cube, 59.23 × 57.21 here
                Image(collection.art)
                    .resizable()
                    .frame(width: 59.23, height: 57.21)
                    .padding(.top, 3.67) // Gap: the picture sits 3.67 down, no spacing token
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) { // Gap: 3 under the title, no spacing token
                    DsText(collection.title, variant: .h5)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                    DsText(collection.detail, variant: .p5, color: .contentTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 4) // Gap: the heading sits 4 inside its run, no spacing token
            .padding(.trailing, SpacingScale.spaceLg)
            // The heading is 68 tall in the frame, whatever its lines come to
            .frame(height: 68, alignment: .top)
            Stack(direction: .horizontal, gap: .spaceMdLg) {
                ForEach(collection.funds) { card($0) }
            }
        }
    }

    /// 10:4563: a square card with the fund house, the fund's name over two lines, and what it has returned
    private func card(_ fund: Fund) -> some View {
        // Gap: the card is #FEFEFE in the frame, unbound; `surfaceWidget` is white. It has no shadow there.
        Surface(surface: .surfaceWidget, radius: .radius23, shadow: .none) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 0) {
                        Stack(direction: .horizontal, gap: .spaceSm, alignment: .center) {
                            FundHouseLogo(name: fund.logo, side: 23)
                            DsText(fund.house, variant: .lb1)
                                .fixedSize()
                        }
                        .frame(height: 23)
                        DsText(fund.name, variant: .p3)
                            .frame(width: 125, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 17) // Gap: 17 under the fund house, no spacing token
                        returned(fund.returned)
                            .padding(.top, SpacingScale.spaceXs)
                    }
                    .padding(.leading, SpacingScale.spaceLg)
                    .padding(.top, SpacingScale.spaceLg)
                }
        }
        .modifier(OpensFund { open(fund) })
    }

    // MARK: Sections

    /// A section's title (13:5680, 8:3849): H3, on the 35 pt line the frames give it (the token's line is 39)
    private func heading(_ title: String) -> some View {
        DsText(title, variant: .h3)
            .fixedSize()
            .frame(height: 35)
            .accessibilityAddTraits(.isHeader)
    }

    /// 15:6246: funds in columns of four, 271 wide, running off the trailing edge
    private var performing: some View {
        VStack(alignment: .leading, spacing: 17) { // Gap: 17 under the title, no spacing token
            heading("Performing small caps")
                .padding(.leading, 17) // Gap: the section starts 17 from the screen's edge, no spacing token
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 27) { // Gap: 27 between the columns, no spacing token
                    ForEach(Self.performing.indices, id: \.self) { column in
                        VStack(alignment: .leading, spacing: 14) { // Gap: 14 between the rows, no spacing token
                            ForEach(Self.performing[column]) { compactRow($0) }
                        }
                    }
                }
                .padding(.horizontal, 17) // Gap: the columns start 17 from the screen's edge, no spacing token
            }
        }
    }

    /// 13:5774: the logo, then the name over the badge and the return
    private func compactRow(_ fund: Fund) -> some View {
        Stack(direction: .horizontal, gap: .spaceMdLg) {
            FundHouseLogo(name: fund.logo, side: 41)
                .padding(.top, SpacingScale.space2xs)
            VStack(alignment: .leading, spacing: 3) { // Gap: 3 under the name, no spacing token
                DsText(fund.name, variant: .p3)
                    .fixedSize()
                Stack(direction: .horizontal, gap: .spaceXs, alignment: .center) {
                    period(fund.period)
                    returned(fund.returned)
                }
            }
        }
        .frame(width: 271, height: 49, alignment: .topLeading)
        .modifier(OpensFund { open(fund) })
    }

    /// 15:6247: one card of rows. The frame's card runs 39 past its seventh row, off the foot of the frame; here
    /// it ends with its last row.
    private var allFunds: some View {
        VStack(alignment: .leading, spacing: 17) { // Gap: 17 under the title, no spacing token
            heading("All mutual funds")
                .padding(.leading, 2) // Gap: the title sits 2 inside the card's edge, no spacing token
            // Gap: the card is #FEFEFE in the frame, unbound; `surfaceWidget` is white. It has no shadow there.
            Surface(surface: .surfaceWidget, radius: .radius23, shadow: .none) {
                VStack(spacing: 0) {
                    ForEach(Self.allFunds) { fund in
                        listRow(fund, Self.wideRow, ruled: fund.id != Self.allFunds.last?.id)
                    }
                }
            }
        }
    }

    /// 8:3066: a tinted card with its title, a line under it, and a white card of three rows
    private func ranking(_ ranking: Ranking) -> some View {
        Stack(gap: .spaceSm) {
            // Gap: Reckless Medium 23/31 has no text style
            GapText(ranking.title, family: .reckless, medium: true, size: 23, lineHeight: 31, color: Self.titleInk)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
            // Gap: Rg 15/21 has no text style (P4 is 15/23)
            GapText(ranking.detail, family: .walsheim, medium: false, size: 15, lineHeight: 21, color: ColorScale.contentSecondary)
                .lineLimit(1)
            Surface(surface: .surfaceWidget, radius: .radius23, shadow: .none) {
                VStack(spacing: 0) {
                    // Every row is ruled in the frame, the last one against the card's own edge
                    ForEach(ranking.funds) { listRow($0, Self.narrowRow, ruled: true) }
                }
            }
            .overlay(RoundedRectangle(cornerRadius: RadiusToken.radius23.value, style: .continuous).strokeBorder(Self.cardEdge, lineWidth: 1)) // Gap: a 1 pt edge, not the hairline
        }
        .padding(.horizontal, 17) // Gap: 17 inside the tinted card, no spacing token
        .padding(.top, 17) // Gap: 17 over the title, no spacing token
        .padding(.bottom, 26) // Gap: 26 under the list, no spacing token
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: RadiusToken.radius23.value, style: .continuous).fill(ranking.tint))
    }

    /// Where a list row's parts sit: the frames draw it in a wide card (8:3851) and a narrow one (8:3069)
    private struct RowInsets {
        let leading: CGFloat
        let logoToName: CGFloat
        let trailing: CGFloat
    }

    private static let wideRow = RowInsets(leading: 19, logoToName: SpacingScale.spaceMdLg, trailing: 19) // Gap: 19 from the card's edges, no spacing token
    private static let narrowRow = RowInsets(leading: SpacingScale.spaceMdLg, logoToName: 11, trailing: SpacingScale.spaceLg) // Gap: 11 from the logo to the name, no spacing token

    /// 8:3851: a 79 pt row with the logo, the name over what kind of fund it is, and the badge and return at the
    /// trailing edge
    private func listRow(_ fund: Fund, _ insets: RowInsets, ruled: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            FundHouseLogo(name: fund.logo, side: 41)
                .padding(.top, 19.5) // Gap: the logo sits 19.5 down the row, no spacing token
            VStack(alignment: .leading, spacing: 3) { // Gap: 3 under the name, no spacing token
                DsText(fund.name, variant: .p3)
                    .lineLimit(1)
                // P5 on the 19 pt line the frame gives it (the token's line is 21)
                DsText(fund.kind, variant: .p5, color: .contentTertiary)
                    .lineLimit(1)
                    .frame(height: 19)
            }
            .padding(.leading, insets.logoToName)
            .padding(.top, 18) // Gap: the name sits 18 down the row, no spacing token
            Spacer(minLength: SpacingScale.spaceXs)
            Stack(direction: .horizontal, gap: .spaceXs) {
                period(fund.period)
                returned(fund.returned)
            }
            .fixedSize()
            .padding(.top, 18) // Gap: the return sits 18 down the row, no spacing token
        }
        .padding(.leading, insets.leading)
        .padding(.trailing, insets.trailing)
        .frame(height: 79, alignment: .top)
        .overlay(alignment: .bottom) {
            if ruled {
                ColorScale.borderSubtle.frame(height: 1) // Gap: the rule under a row is 1 pt, not the hairline
            }
        }
        .modifier(OpensFund { open(fund) })
    }

    /// 13:5778: the span a return is over, in its 21 pt badge
    private func period(_ text: String) -> some View {
        // Gap: Lb1 on the 17 pt line this file gives it. On the token's 21 pt line the letters sit about 1.5 pt
        // high of the badge's centre.
        GapText(text, family: .walsheim, medium: false, size: 13, lineHeight: 17, color: ColorScale.contentTertiary)
            .fixedSize()
            .frame(width: 21, height: 21)
            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(ColorScale.borderSubtle, lineWidth: BorderTokens.hairline)) // Gap: 5, the badge's radius, has no token
    }

    /// What a fund has returned: H6 (Md 17/23) in utility-green/500, which has no content token
    private func returned(_ text: String) -> some View {
        GapText(text, family: .walsheim, medium: true, size: 17, lineHeight: 23, color: Self.returnInk)
            .fixedSize()
    }
}

/// A fund on the homepage, wherever it is drawn, opens the fund's page on a tap
private struct OpensFund: ViewModifier {
    let open: () -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture(perform: open)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
    }
}

/// 10:4546–10:4549: #FCFCFC with three pale blobs under a heavily blurred, 9% white veil. The same blobs as
/// `DecadeBackdrop`, in this frame's own colours and places.
private struct MutualFundsHomeBackdrop: View {
    private static let ground = Color(hex: 0xFCFCFC) // Gap: #FCFCFC, the page's ground, is unbound
    private static let lime = Color(hex: 0xF0F6DF) // Gap: #F0F6DF, unbound
    private static let sage = Color(hex: 0xD8E0DB) // Gap: #D8E0DB, unbound
    private static let mist = Color(hex: 0xF0F0F0) // Gap: #F0F0F0, unbound
    private static let veil = Color.white.opacity(0.09) // Gap: white 9%, unbound

    var body: some View {
        ZStack(alignment: .topLeading) {
            Ellipse().fill(Self.lime)
                .frame(width: 165, height: 378)
                .at(97, 118)
                .blur(radius: 72)
            Ellipse().fill(Self.sage)
                .frame(width: 119.38, height: 273.04)
                .rotationEffect(.degrees(-86.94))
                .at(166.38 + (279.03 - 119.38) / 2, 486.38 + (133.8 - 273.04) / 2)
                .blur(radius: 72)
            Ellipse().fill(Self.mist)
                .frame(width: 359.54, height: 446)
                .rotationEffect(.degrees(-3.73))
                .at(171 + (387.81 - 359.54) / 2, -19 + (468.46 - 446) / 2)
                .blur(radius: 72)
        }
        .frame(width: MutualFundScreen.canvasWidth, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Self.ground)
        // Each blob is blurred on its own, as in `DecadeBackdrop`
        .overlay(Self.veil)
        .ignoresSafeArea()
    }
}

#Preview {
    MutualFundsHomeView()
}
