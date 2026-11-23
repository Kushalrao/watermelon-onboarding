import SwiftUI

/// A mutual fund's page, in the two ways the file `sub7vIn6sMBlHb4SIWHyek` draws it (`Layout`).
///
/// "iPhone 14 Plus - 551" (101:15915) is the newer, and what opens. The fund house's logo, the fund's name and
/// its Decade rating stand in the middle at the top, over a row of three small tabs ("Market · For you ·
/// Research"). Then a card carries the fund's return, its NAV over three years, the periods and its facts in two
/// columns, and under it come Fund holdings, Sectors exposure, Fund charges and Fund managers.
///
/// "iPhone 14 Plus - 550" (101:15002) is kept behind `-mfFundV2`. The fund's NAV over a month is on the sunken
/// ground, then a white sheet opens with the fund's return as a tab, then its house, its name, its Decade rating
/// and the "Market · For you · View research" row, and carries Fund basics and the same four cards. Under them
/// the rating is written again, large, over a card the frame leaves empty.
///
/// Both have a round back button at the top, and "Ask advisor" and "Start SIP" side by side at the foot. They
/// take the place of the first version of the page (37:3821), which had the return in a pill over the chart, the
/// holdings again as a map, and a card for the split by company size.
///
/// The page is drawn for one fund, `MutualFund.kotak`, and shows any other the same way. It opens from a fund on
/// a mutual funds homepage or a category's page, or straight away with `-mfFund`; the back button, or a drag
/// from the leading edge, takes it back.
///
/// The chart (`FundGrowthChart`) can be read with a finger, by a drag across it, and its periods choose how far
/// back it goes. The return written with the arrow keeps to the fund's return a year over three years, as the
/// older frame has it beside a chart of one month.
///
/// The cards are widgets, as the app's other pages' are:
/// - A tap on the chart, on Fund holdings or on Sectors exposure opens the card out, from where it is, into a
///   pop-up over the page: the chart taller with the period's figures, every holding (101:17152), or the sectors
///   with the companies in them. A tap outside the pop-up, or a drag down on its title, closes it back into the
///   card. Only the holdings' pop-up is drawn in Figma; the other two are made in its manner.
/// - A hold on any card lifts it out of the page with questions about it, and a swipe to the right sends it to
///   the advisor's composer, which comes out of "Ask advisor" (`advisorComposer`, `askable`). A tap on "Ask
///   advisor" opens the composer too.
///
/// Once the fund's name has scrolled away, the bar at the top carries it (105:19390): the back button grows, and
/// a pill beside it has the house's logo and name over the fund's name. On the card's page the three tabs stay
/// under that bar from where they reach it (105:18624), and a tap chooses one.
///
/// The frames draw one state only otherwise: the row of three, "Scheme document" and "Start SIP" do not respond
/// yet.
struct MutualFundDetailView: View {
    /// Which of the two drawn pages this is
    enum Layout {
        /// 101:15002: the chart on the page's ground, and the rest on a white sheet
        case sheet
        /// 101:15915: the fund's logo, name and rating at the top, and the chart in a card with the fund's facts
        case card

        /// The newer is what opens; `-mfFundV2` opens the one before it
        static let chosen: Layout = ProcessInfo.processInfo.arguments.contains("-mfFundV2") ? .sheet : .card
    }

    /// The fund the page is for
    var fund: MutualFund = .kotak
    var layout = Layout.chosen
    /// Draws the foot's pills itself. A homepage that pushes the page carries them across from its own bar
    /// (`FundPush`), and the page then draws only the wash behind them.
    var ownsFoot = true
    /// How far the page has been dragged back, as a share of its width, while it is being dragged
    var onPull: (CGFloat) -> Void = { _ in }
    /// Takes the page away (the back button, or a drag in from the leading edge)
    var onBack: () -> Void = {}

    private static let titleInk = Color(hex: 0x212121) // Gap: #212121, the titles' colour, is unbound
    private static let upInk = Color(hex: 0x00A800) // Gap: utility-green/500 has no semantic token
    private static let chargeInk = Color(hex: 0xB47E00) // Gap: accent-yellow/500 has no semantic token
    private static let footTop = Color(hex: 0xF8F8F5, opacity: 0.4) // Gap: #F8F8F5 40%, the top of the foot's wash, is unbound
    private static let footWash = Color(hex: 0xF3F6F3) // Gap: #F3F6F3, the foot's wash, is unbound
    private static let factRule = Color(hex: 0xD2CECC) // Gap: #D2CECC, the rules in Fund basics, is unbound
    private static let valueInk = Color.black.opacity(0.56) // Gap: black 56%, a fact's value, is unbound
    private static let houseInk = Color.black.opacity(0.5) // Gap: black 50%, the fund house's name, is unbound
    private static let backShadow = Color.black.opacity(0.08) // Gap: black 8%, the back button's shadow, is Shadow/1 at a stronger tint
    private static let holdingInk = Color(hex: 0x74527B) // Gap: accent-lavender/700 has no semantic token
    private static let tabShadow = Color.black.opacity(0.07) // Gap: black 7%, the chosen tab's shadow, is unbound

    /// How far the page has been dragged back
    @State private var pulled: CGFloat = 0
    @State private var width: CGFloat = 390
    /// The chart is being read
    @State private var reading = false
    /// The period the chart shows: the frame of the sheet draws the first, and the frame of the card the fourth
    @State private var period = Layout.chosen == .sheet ? MutualFund.Period.month : .three
    /// The card that is opened out into its pop-up, or on its way there or back
    @State private var popUp: FundContext.FundSection?
    /// How far the pop-up has travelled from the card's place, 0, to its own, 1, and how far it has changed size
    @State private var popMove: CGFloat = 0
    @State private var popGrow: CGFloat = 0
    /// Where the cards that open out are on the page, kept without redrawing the page as it scrolls
    @State private var places = Places()
    /// The fund's name has scrolled away, and the bar at the top carries it
    @State private var stuck = false
    /// The foot's pills are out of the way: a pop-up or the advisor's composer is up
    @State private var covered = false
    /// Which of the card page's three tabs is chosen: "Market", "For you" or "Research"
    @State private var picked = 0
    /// The tabs have scrolled up to the bar, and stay under it
    @State private var tabsStuck = false
    @Namespace private var chosenTab

    /// The cards' places on the page
    private final class Places {
        var frames: [FundContext.FundSection: CGRect] = [:]
    }

    /// The period each fund's page is showing, by the fund's name, for a copy of its chart drawn off the page (a
    /// held widget's) to show the same one
    private static var shownPeriods: [String: MutualFund.Period] = [:]

    private static let space = "fundPage"
    // The pop-up's springs are the foot's, which are the chat's: it travels a little ahead of its size, which goes
    // just past and settles; closing is tighter
    private static let openMove = Animation.spring(response: 0.5, dampingFraction: 0.78)
    private static let openGrow = Animation.spring(response: 0.58, dampingFraction: 0.7)
    private static let closeMove = Animation.spring(response: 0.42, dampingFraction: 0.84)
    private static let closeGrow = Animation.spring(response: 0.46, dampingFraction: 0.76)

    var body: some View {
        VStack(spacing: 0) {
            // Keeps the page from running up under the status bar as it scrolls
            Color.clear.frame(height: 1)
            ScrollView(showsIndicators: false) {
                Group {
                    switch layout {
                    case .sheet:
                        VStack(spacing: 0) {
                            opening(.growth, growthChart(.sheet, period: $period))
                                .padding(.top, 12) // Gap: the chart starts 13 under the status bar, no spacing token
                            sheet
                                .padding(.top, SpacingScale.spaceXs)
                        }
                    case .card:
                        page
                    }
                }
                // Room to scroll the page's end clear of the foot
                .padding(.bottom, SpacingScale.space10xl)
            }
            // The name is under the bar once the page has scrolled this far: 440 on the sheet, 150 on the card's page
            .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y > (layout == .sheet ? 440 : 150) } action: { _, past in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { stuck = past }
            }
        }
        .background { ground.ignoresSafeArea() }
        .onAppear {
            // A page opened as the sheet where the card is what opens, or the other way, starts on its own period
            if layout != Layout.chosen, Self.shownPeriods[fund.id] == nil {
                period = layout == .sheet ? .month : .three
            }
            Self.shownPeriods[fund.id] = period
        }
        .onChange(of: period) { Self.shownPeriods[fund.id] = period }
        // The cards are not held or swiped through a pop-up
        .onChange(of: popUp) { WidgetGestures.suspended = popUp != nil }
        .onDisappear {
            Self.shownPeriods[fund.id] = nil
            WidgetGestures.suspended = false
        }
        .overlay(alignment: .top) { header }
        .overlay(alignment: .top) {
            if layout == .card {
                // 105:18624: the tabs, 11 under the bar, once the page has scrolled them up to there
                tabs(stuck: true)
                    .padding(.horizontal, 11) // Gap: 11 inside the tabs' ground, no spacing token
                    .padding(.vertical, SpacingScale.spaceXs)
                    // Gap: the frame has the tabs straight on the page; a ground of the system's thinnest
                    // material keeps their words clear of what scrolls under them
                    .background(Capsule().fill(.ultraThinMaterial))
                    .padding(.top, 69) // Gap: the tabs are 74 under the status bar, 5 of it their ground; no spacing token
                    .opacity(tabsStuck ? 1 : 0)
                    .allowsHitTesting(tabsStuck)
                    .accessibilityHidden(!tabsStuck)
            }
        }
        .overlay { foot }
        .overlay(alignment: .topLeading) { back }
        .overlay(alignment: .leading) { backEdge }
        .overlay {
            if let popUp { popUpLayer(popUp) }
        }
        .coordinateSpace(.named(Self.space))
        // The foot's pills go while a pop-up is over the page; the composer adds itself to this (`advisorComposer`)
        .preference(key: FundFootCoveredKey.self, value: popUp != nil)
        // The advisor's composer comes out of "Ask advisor", 104 above the foot of the screen, and a held card is
        // lifted over everything
        .advisorComposer(pillRise: 104)
        .onPreferenceChange(FundFootCoveredKey.self) { covered = $0 }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .offset(x: pulled)
        .preferredColorScheme(.light)
    }

    /// 105:19390: the bar once the fund's name has scrolled away. Beside the back button, which is 45 across here,
    /// a white pill carries the house's logo, the house's name and, under it, the fund's name without the house
    /// at its start ("Asset allocation fund"). The bar has no ground of its own: the page scrolls under the button
    /// and the pill, which cast the bar's shadow.
    private var header: some View {
        Surface(surface: .surfaceWidget, radius: .radius27, border: .borderSubtle, shadow: .none) {
            HStack(spacing: 12) { // Gap: 12 from the logo to the words, no spacing token
                // 105:19745: the house's logo on its tile, 39 across
                FundHouseLogo(name: fund.logo ?? "", side: 39, house: fund.house)
                VStack(alignment: .leading, spacing: 0) {
                    // Gap: Rg 13/17, Lb1 on the line this file gives it, in the unbound black 50%
                    GapText(fund.house, family: .walsheim, medium: false, size: 13, lineHeight: 17, color: Self.houseInk)
                        .lineLimit(1)
                    // Gap: P3 on the 23 pt line this file gives it (the token's line is 25)
                    GapText(fund.shortName, family: .walsheim, medium: false, size: 17, lineHeight: 23, color: ColorScale.contentPrimary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12) // Gap: 12 inside the pill, no spacing token
            .frame(height: 57)
        }
        .shadow(color: Self.backShadow, radius: 25, x: 0, y: 4) // Gap: 0 4 50 at 8%, Shadow/1's shape at a stronger tint. ds-lint-ignore: no_raw_shadow
        .padding(.leading, 70) // Gap: the pill starts 70 in, 12 after the back button; no spacing token
        .padding(.trailing, SpacingScale.spaceMdLg)
        .padding(.top, 3) // Gap: the pill is 3 inside the bar's 63, no spacing token
        // It comes out from beside the back button
        .scaleEffect(stuck ? 1 : 0.94, anchor: .leading)
        .opacity(stuck ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(fund.name)
        .accessibilityHidden(!stuck)
    }

    /// The page's ground. The sheet's is the sunken surface. The card's is the base surface for the first 300 pt
    /// of the screen and the sunken one from 375 down, where the frame has its first card; it stays where it is as
    /// the page scrolls. Gap: the frame's ground is read off its picture, not a fill the file gives.
    @ViewBuilder private var ground: some View {
        switch layout {
        case .sheet:
            ColorScale.surfaceSunken1
        case .card:
            VStack(spacing: 0) {
                LinearGradient(
                    stops: [.init(color: ColorScale.surfaceBase, location: 0), .init(color: ColorScale.surfaceBase, location: 0.8), .init(color: ColorScale.surfaceSunken1, location: 1)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 375)
                ColorScale.surfaceSunken1
            }
        }
    }

    /// The round back button, which stays at the top as the page scrolls under it: 40 across, 15 in and 12 under
    /// the status bar, on the sheet (101:15509), and 37 across, 13 under the status bar, on the card (101:15943),
    /// where it is the category pages' button at seven tenths of its size. Once the fund's name has scrolled away
    /// it is 45 across, 13 in and 9 under the status bar, beside the bar's pill (105:19740). On the sheet it goes
    /// while the chart is being read, when the price's pill can stand where it is.
    private var back: some View {
        let side: CGFloat = stuck ? 45 : layout == .sheet ? 40 : 37.7
        return Button {
            Haptics.tap()
            onBack()
        } label: {
            Group {
                switch layout {
                case .sheet:
                    Image("MFDetailBack")
                        .resizable()
                        .frame(width: side, height: side)
                        .shadow(color: Self.backShadow, radius: 25, x: 0, y: 4) // Gap: 0 4 50 at 8%, Shadow/1's shape at a stronger tint. ds-lint-ignore: no_raw_shadow
                case .card:
                    // The drawing carries its own soft shadow, 262 × 261 around its 54 × 53, and is drawn to the
                    // button's size
                    Image("MFCatBack")
                        .resizable()
                        .frame(width: 262 * side / 54, height: 261 * side / 54)
                        .offset(y: 4 * side / 54)
                        .frame(width: side, height: side)
                }
            }
            // Its tap target is 44 at least
            .frame(width: max(side, 44), height: max(side, 44))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.leading, stuck || layout == .sheet ? SpacingScale.spaceMdLg : 12) // Gap: the card's button is 15.15 in, 12 to its tap target; no spacing token
        .padding(.top, stuck || layout == .card ? SpacingScale.spaceMd : 10) // Gap: the sheet's 44 pt tap target starts 10 under the status bar, no spacing token
        .opacity(!reading || layout == .card ? 1 : 0)
        .accessibilityLabel("Back")
    }

    /// A drag in from the leading edge takes the page back, as a pushed page goes
    private var backEdge: some View {
        Color.clear
            .frame(width: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged {
                        pulled = max(0, $0.translation.width)
                        onPull(min(pulled / max(width, 1), 1))
                    }
                    .onEnded { value in
                        if value.translation.width > 110 || value.predictedEndTranslation.width > 260 {
                            Haptics.tap()
                            onBack()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                pulled = 0
                                onPull(0)
                            }
                        }
                    }
            )
            .accessibilityHidden(true)
    }

    // MARK: Growth

    private func growthChart(_ style: FundGrowthChart.Style, period: Binding<MutualFund.Period>) -> some View {
        FundGrowthChart(fund: fund, style: style, period: period) { reading = $0 }
    }

    /// One of the page's cards on its own, as it rests on the page: for a copy of it lifted over the page
    /// (`FundContext.widget`). The chart is on the period the page is showing.
    @ViewBuilder func section(_ section: FundContext.FundSection) -> some View {
        let period = Binding.constant(Self.shownPeriods[fund.id] ?? (layout == .sheet ? MutualFund.Period.month : .three))
        switch section {
        case .growth:
            switch layout {
            case .card: Surface(surface: .surfaceWidget, radius: .radius23) { growthBody(period: period) }
            case .sheet: growthChart(.sheet, period: period).background(ColorScale.surfaceSunken1)
            }
        case .basics: basics
        case .holdings: holdings
        case .sectors: sectors
        case .charges: charges
        case .managers: managers
        }
    }

    /// A card of the page as a widget: a hold lifts it out with questions, and a swipe to the right sends it to
    /// the advisor
    private func asking<Card: View>(_ section: FundContext.FundSection, _ card: Card) -> some View {
        card.askable(.fundCard(fund.name, section))
    }

    /// A card that opens out into a pop-up when it is tapped, and is a widget besides. It is left empty while its
    /// pop-up is up, which has grown out of it.
    private func opening<Card: View>(_ section: FundContext.FundSection, _ card: Card) -> some View {
        asking(
            section,
            OpeningCard(open: { open(section) }) {
                card
                    .opacity(popUp == section ? 0 : 1)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { places.frames[section] = $0 }
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Opens \(section.title.lowercased())")
        )
    }

    // MARK: The card's page

    /// 101:15915: the fund's logo, name and rating, the row of three, the card with the chart and the facts, and
    /// the cards under it
    private var page: some View {
        VStack(spacing: 0) {
            // 101:16616: the fund house's logo on its tile, 57 across
            FundHouseLogo(name: fund.logo ?? "", side: 57, house: fund.house)
                .padding(.top, 52) // Gap: the logo starts 53 under the status bar, no spacing token
                .accessibilityLabel(fund.house)
            // 101:15940. Gap: Reckless Medium 35/43 has no text style (H2 is Regular 35/51)
            GapText(fund.title, family: .reckless, medium: true, size: 35, lineHeight: 43, color: ColorScale.contentPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16) // Gap: the name is 29 from the edges, 16 inside the cards' 13; no spacing token
                .padding(.top, 8) // Gap: 8 under the logo, no spacing token
                .accessibilityLabel(fund.name)
                .accessibilityAddTraits(.isHeader)
            rated
                .padding(.top, SpacingScale.spaceMdLg)
            tabs(stuck: false)
                // The tabs stay under the bar from where they reach it, 74 under the status bar: this row goes,
                // and the one over the page takes its place
                .onGeometryChange(for: Bool.self) { $0.frame(in: .named(Self.space)).minY <= 74 } action: { tabsStuck = $0 }
                .opacity(tabsStuck ? 0 : 1)
                .accessibilityHidden(tabsStuck)
                .padding(.top, 43) // Gap: 43 under the rating, no spacing token
            opening(.growth, growth)
                .padding(.top, 17) // Gap: 17 under the row, no spacing token
            VStack(spacing: 23) { // Gap: 23 between the cards, no spacing token
                opening(.holdings, holdings)
                opening(.sectors, sectors)
                asking(.charges, charges)
                asking(.managers, managers)
            }
            .padding(.top, 28) // Gap: 28 under the chart's card, no spacing token
            // 111:22487: the rating again, large, and under it a card the frame leaves empty. The frame gives the
            // two alone, not where they go: here they follow the last card.
            verdict
                .padding(.top, SpacingScale.space7xl)
            Surface(surface: .surfaceWidget, radius: .radius23, border: .borderSubtle) {
                Color.clear.frame(height: 321)
            }
            .padding(.top, 27) // Gap: 27 under the rating's line, no spacing token
            .accessibilityHidden(true)
        }
        .padding(.horizontal, SpacingScale.spaceMdLg)
    }

    /// 101:16783, 105:18624: the three tabs. The chosen one is in a small black pill and the others are plain
    /// words, each after its orb; a tap chooses a tab, and the pill moves to it. What is under the tabs is the
    /// same for all three: the frames draw "Market" only. The row is drawn twice, in the page and over it once
    /// it has stuck under the bar, and each has its own pill.
    private func tabs(stuck: Bool) -> some View {
        let names = [("Market", "MFDetailOrbMarket"), ("For you", "MFDetailOrbForYou"), ("Research", "MFDetailOrbResearch")]
        return HStack(spacing: 23) { // Gap: 23 between the three, no spacing token
            ForEach(Array(names.enumerated()), id: \.offset) { place, name in
                tabItem(name.0, orb: name.1, chosen: place == picked, pill: stuck ? "stuck" : "page")
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard place != picked else { return }
                        Haptics.tap()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { picked = place }
                    }
            }
        }
    }

    private func tabItem(_ title: String, orb: String, chosen: Bool, pill: String) -> some View {
        HStack(spacing: chosen ? SpacingScale.spaceXs : 6) { // Gap: 6 from an orb to its word where it is not chosen, no spacing token
            // The orb is exported with its own soft shadow, 44.25 across around its 27; it is 15 here
            Image(orb)
                .resizable()
                .frame(width: 24.58, height: 24.58)
                .frame(width: 15, height: 15)
                // The drawing's shadow is left out: at this size it showed as a pale square on the page's ground
                .clipShape(Circle())
                .accessibilityHidden(true)
            // Gap: Md and Rg 15/19.63 have no text style
            GapText(title, family: .walsheim, medium: chosen, size: 15, lineHeight: 19.63, color: chosen ? ColorScale.contentOnColor : ColorScale.contentTertiary)
                .fixedSize()
        }
        .padding(.horizontal, chosen ? SpacingScale.spaceSm : 0)
        .padding(.vertical, SpacingScale.spaceXs)
        .background {
            if chosen {
                Capsule()
                    .fill(ColorScale.surfaceInverse)
                    .shadow(color: Self.tabShadow, radius: 13.6, x: 0, y: 2.243) // Gap: 0 2.24 27.2 at 7%, not a Shadow style. ds-lint-ignore: no_raw_shadow
                    .matchedGeometryEffect(id: pill, in: chosenTab)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(chosen ? [.isSelected, .isButton] : .isButton)
    }

    /// 101:15916: the card with the return, the chart, the periods and, under them, the fund's facts in two
    /// columns: the first three on the leading side, the rest on the trailing one
    private var growth: some View {
        Surface(surface: .surfaceWidget, radius: .radius23) {
            growthBody(period: $period)
        }
    }

    /// What is in that card: the chart, then the facts
    private func growthBody(period: Binding<MutualFund.Period>) -> some View {
        VStack(spacing: 17) { // Gap: the facts start 17 under the chart's 310, no spacing token
            growthChart(.card, period: period)
            columns(fund.facts, leading: 3)
        }
        .padding(.bottom, 17) // Gap: 17 under the facts, no spacing token
        .frame(maxWidth: .infinity)
    }

    /// Facts in two columns, the first few on the leading side and the rest on the trailing one (101:16586 …)
    private func columns(_ all: [(label: String, value: String)], leading: Int) -> some View {
        HStack(alignment: .top, spacing: 22) { // Gap: 22 between the columns, no spacing token
            facts(Array(all.prefix(leading)))
                // The leading column is 161 of the card's 364 in the frame
                .frame(width: 161)
            facts(Array(all.dropFirst(leading)))
                .frame(maxWidth: .infinity)
        }
        .padding(.leading, SpacingScale.spaceLg)
        .padding(.trailing, 20) // Gap: 20 at the trailing edge, no spacing token
    }

    /// A column of facts (101:16586 …), 34 from one to the next
    private func facts(_ facts: [(label: String, value: String)]) -> some View {
        Stack(gap: .spaceMdLg) {
            ForEach(Array(facts.enumerated()), id: \.offset) { _, fact in
                HStack(spacing: 0) {
                    copy(fact.label)
                        .fixedSize()
                        .frame(height: 21)
                    Spacer(minLength: SpacingScale.spaceXs)
                    // Gap: Rg 15/21 in the unbound black 56%
                    GapText(fact.value, family: .walsheim, medium: false, size: 15, lineHeight: 21, color: Self.valueInk)
                        .lineLimit(1)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: The sheet

    /// 101:15020: the white sheet, rounded at the top, that carries the rest of the page
    private var sheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            tab
            rowRule
            VStack(alignment: .leading, spacing: 0) {
                house
                    .padding(.top, 20) // Gap: 20 under the tab's rule, no spacing token
                name
                    .padding(.top, SpacingScale.spaceMd)
                rated
                    .padding(.top, 17) // Gap: 17 under the name, no spacing token
            }
            .padding(.leading, 17) // Gap: 17 inside the sheet, no spacing token
            .padding(.trailing, 41) // Gap: the name is 332 across in the frame's 390, 41 short of the edge; no spacing token
            views
                .padding(.top, 38) // Gap: 38 under the rating, no spacing token
            VStack(spacing: 23) { // Gap: 23 between the cards, no spacing token
                asking(.basics, basics)
                opening(.holdings, holdings)
                opening(.sectors, sectors)
                asking(.charges, charges)
                asking(.managers, managers)
            }
            .padding(.horizontal, SpacingScale.spaceMdLg)
            .padding(.top, 30) // Gap: 30 under the row, no spacing token
            verdict
                .padding(.top, 119) // Gap: 119 under the last card, no spacing token
            // 101:15220: the card under the rating, which the frame leaves empty
            Surface(surface: .surfaceBase, radius: .radius23, border: .borderSubtle, shadow: .token(.shadow1)) {
                Color.clear.frame(height: 321)
            }
            .padding(.horizontal, SpacingScale.spaceMdLg)
            .padding(.top, 27) // Gap: 27 under the rating's line, no spacing token
            .accessibilityHidden(true)
        }
        .padding(.bottom, 43) // Gap: 43 under the last card, no spacing token
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            // Gap: the frame throws the sheet's shadow upward (0 −4 48.5 at 7%); Shadow/2 is near it, thrown down
            UnevenRoundedRectangle(topLeadingRadius: RadiusToken.radius27.value, topTrailingRadius: RadiusToken.radius27.value, style: .continuous)
                .fill(ColorScale.surfaceWidget)
                .dsShadow(.shadow2)
        }
    }

    /// 101:15353: the return, in the middle of the 50 pt at the top of the sheet
    private var tab: some View {
        FundGain(fund: fund)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
    }

    /// 101:15333: the fund house's logo on its tile, and its name in capitals
    private var house: some View {
        Stack(direction: .horizontal, gap: .spaceSm, alignment: .center) {
            FundHouseLogo(name: fund.logo ?? "", side: 23, house: fund.house)
            // Gap: Md 17/23 at 5% tracking, in capitals, has no text style
            GapText(fund.house.uppercased(), family: .walsheim, medium: true, size: 17, lineHeight: 23, trackingPercent: 5, color: Self.houseInk)
                .lineLimit(1)
        }
    }

    /// 101:15021: the fund's name. Gap: GT Walsheim Md 35/43 has no text style
    private var name: some View {
        GapText(fund.title, family: .walsheim, medium: true, size: 35, lineHeight: 43, color: ColorScale.contentPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(fund.name)
            .accessibilityAddTraits(.isHeader)
    }

    /// How many of five dots a rating fills
    private var filled: Int {
        min(max(Int(fund.rating.rounded()), 0), 5)
    }

    private var tone: MutualFundsHomeV2View.Tone {
        MutualFundsHomeV2View.Tone(score: fund.rating)
    }

    /// 101:15359: "Decade Rating", then the rating as the lists write it
    private var rated: some View {
        Stack(direction: .horizontal, gap: .spaceMd, alignment: .center) {
            // Gap: Reckless Regular 17/21 has no text style
            GapText("Decade Rating", family: .reckless, medium: false, size: 17, lineHeight: 21, color: ColorScale.contentPrimary)
                .fixedSize()
            FundRatingMark(rating: String(format: "%.1f", fund.rating), filled: filled, tone: tone)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Decade rating \(String(format: "%.1f", fund.rating)) of 5")
    }

    /// 101:15463: "Market", chosen, then "For you" and "View research"; the row runs off the trailing edge
    private var views: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Stack(direction: .horizontal, gap: .spaceMd, alignment: .center) {
                view("Market", orb: "MFDetailOrbMarket", chosen: true)
                view("For you", orb: "MFDetailOrbForYou", chosen: false)
                view("View research", orb: "MFDetailOrbResearch", chosen: false)
            }
            .padding(.horizontal, SpacingScale.spaceMdLg)
        }
        .scrollClipDisabled()
    }

    /// 101:15464, 101:15475: an orb and a word in a pill. The chosen one is black, inside a 2 pt edge on the sheet
    /// and with none in the holdings' pop-up (101:17212). Gap: the
    /// pills not chosen are #FEFEFE with a 1 pt edge in the frame; here they are the white widget surface with
    /// the hairline.
    private func view(_ title: String, orb: String, chosen: Bool, edged: Bool = true) -> some View {
        let edged = chosen && edged
        // Radius/27 on a pill 49 or 53 tall is a capsule, and is drawn as one: a continuous corner wider than half
        // the pill's height bulges at its ends
        return Surface(surface: chosen ? .surfaceInverse : .surfaceWidget, shape: .capsule, border: chosen ? nil : .borderSubtle, shadow: .token(edged ? .shadow2 : .shadow1)) {
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
            .padding(.horizontal, edged ? 17 : SpacingScale.spaceLg) // Gap: 15 inside the chosen pill's 2 pt edge, no spacing token
            .padding(.vertical, edged ? 13 : 11) // Gap: 11 above and below, inside the chosen pill's edge; no spacing token
            // The orb's drawing is square, and its shadow's corner would show past the pill's round end
            .clipShape(Capsule())
        }
        .overlay {
            if edged {
                Capsule()
                    .strokeBorder(ColorScale.borderStrong, lineWidth: 2) // Gap: the chosen pill's 2 pt edge, not the hairline
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    // MARK: Cards

    /// A card's title (101:15382). Gap: H5 (Md 19/27) in the unbound #212121
    private func heading(_ string: String) -> some View {
        GapText(string, family: .walsheim, medium: true, size: 19, lineHeight: 27, color: Self.titleInk)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
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

    /// The 1 pt rule under the sheet's tab and under a row in a box (101:15358, 101:15114)
    private var rowRule: some View {
        ColorScale.borderSubtle.frame(height: 1) // Gap: these rules are 1 pt, not the hairline
    }

    /// A share of the fund as the frame writes it: "6.42%"
    private static func share(_ value: Double) -> String {
        String(format: "%.2f%%", value)
    }

    /// A card with its title, the arrows beside it, and under them a box of rows with a 1 pt edge (101:15085)
    private func boxed<Rows: View>(_ title: String, @ViewBuilder rows: @escaping () -> Rows) -> some View {
        Surface(surface: .surfaceWidget, radius: .radius23) {
            boxedBody(title, rows: rows)
        }
    }

    /// What is in such a card: the title, the arrows and the box of rows
    private func boxedBody<Rows: View>(_ title: String, @ViewBuilder rows: @escaping () -> Rows) -> some View {
        VStack(alignment: .leading, spacing: 17) { // Gap: 17 under the title, no spacing token
            HStack(alignment: .top, spacing: 0) {
                heading(title)
                Spacer(minLength: 0)
                // 101:15087: the arrows, turned as the frame turns them
                Image("MFDetailExpand")
                    .scaleEffect(x: -1, y: 1)
                    .padding(.top, 6) // Gap: the arrows sit 6 under the title's top, no spacing token
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 4) // Gap: the title is 4 further in than the box, no spacing token
            VStack(spacing: 0, content: rows)
                .clipShape(RoundedRectangle(cornerRadius: RadiusToken.radius15.value, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: RadiusToken.radius15.value, style: .continuous).strokeBorder(ColorScale.borderSubtle, lineWidth: 1)) // Gap: a 1 pt edge, not the hairline
        }
        .padding(.horizontal, SpacingScale.spaceLg)
        .padding(.vertical, 17) // Gap: 17 above and below, no spacing token
    }

    /// A 57 pt row in a box: a 27 pt badge, a name, and a share at the trailing edge (101:15089)
    private func row<Badge: View>(_ name: String, share value: Double, ink: Color, ruled: Bool, @ViewBuilder badge: () -> Badge) -> some View {
        HStack(spacing: 11) { // Gap: 11 from the badge to the name, no spacing token
            badge()
                .frame(width: 27, height: 27)
                .accessibilityHidden(true)
            copy(name)
                .lineLimit(1)
                .frame(height: 21)
            Spacer(minLength: SpacingScale.spaceXs)
            // Gap: Rg 15/21, P4 on this file's line; a holding's is in a utility colour with no content token
            GapText(Self.share(value), family: .walsheim, medium: false, size: 15, lineHeight: 21, color: ink)
                .fixedSize()
        }
        .padding(.horizontal, SpacingScale.spaceLg)
        .frame(height: 57)
        .overlay(alignment: .bottom) {
            if ruled { rowRule }
        }
        .accessibilityElement(children: .combine)
    }

    /// 101:15371: Fund basics, a fact to a row with hairlines between, and "Scheme document" beside the title
    private var basics: some View {
        Surface(surface: .surfaceWidget, radius: .radius23) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    heading("Fund basics")
                    Spacer(minLength: SpacingScale.spaceXs)
                    copy("Scheme document", color: ColorScale.contentQuaternary)
                        .fixedSize()
                        .frame(height: 21)
                }
                .padding(.horizontal, 19) // Gap: 19 inside the card, no spacing token
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

    /// 101:15085: the five largest holdings, a row each, with each one's share in green
    private var holdings: some View {
        boxed("Fund holdings") { largestHoldings }
    }

    @ViewBuilder private var largestHoldings: some View {
        let largest = Array(fund.holdings.prefix(5))
        ForEach(Array(largest.enumerated()), id: \.element.id) { place, holding in
            row(holding.name, share: holding.share, ink: Self.upInk, ruled: place < largest.count - 1) {
                // 101:15099: the company's logo on a round badge, on the page's ground
                Image(holding.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21.706, height: 21.706)
                    .clipShape(Circle())
                    .frame(width: 27, height: 27)
                    .background(Circle().fill(ColorScale.surfaceBase))
                    .overlay(Circle().strokeBorder(ColorScale.borderSubtle, lineWidth: 0.371)) // Gap: the badge's 0.371 stroke is not the hairline
            }
        }
    }

    // MARK: Pop-ups

    private func open(_ section: FundContext.FundSection) {
        guard popUp == nil else { return }
        Haptics.tap()
        popMove = 0
        popGrow = 0
        // The pop-up starts in the card's place and sets off once it is there (`popUpLayer`)
        popUp = section
    }

    private func closePopUp() {
        guard popUp != nil, popGrow > 0 else { return }
        Haptics.tap()
        withAnimation(Self.closeMove) { popMove = 0 }
        withAnimation(Self.closeGrow, completionCriteria: .removed) {
            popGrow = 0
        } completion: {
            popUp = nil
        }
    }

    /// How tall a pop-up is, where it is not as tall as the screen lets it be: the sectors' is its title and
    /// five sectors, and the chart's its title, the chart and two rows of figures
    private func height(of section: FundContext.FundSection) -> CGFloat? {
        switch section {
        case .sectors: 504
        case .growth: 535
        default: nil
        }
    }

    /// 101:17152: a card opened out over the page. It is the card itself, grown from where it is on the page to
    /// 13 from either side: as tall as the screen lets it be, 17 under the status bar and 30 over the foot of the
    /// screen, or as tall as what it holds, in the middle of that. The card's own contents give way to the
    /// pop-up's as it grows, and the page behind is covered. The frame draws the holdings' open; how a pop-up
    /// gets there is not drawn.
    private func popUpLayer(_ section: FundContext.FundSection) -> some View {
        GeometryReader { geo in
            let from = places.frames[section] ?? .zero
            let full = CGRect(x: 13, y: 17, width: geo.size.width - 26, height: geo.size.height - 47)
            let tall = min(height(of: section) ?? full.height, full.height)
            let to = CGRect(x: full.minX, y: full.midY - tall / 2, width: full.width, height: tall)
            let grown = min(max(popGrow, 0), 1)
            let shape = RoundedRectangle(cornerRadius: RadiusToken.radius23.value + (RadiusToken.radius27.value - RadiusToken.radius23.value) * grown, style: .continuous)
            ZStack(alignment: .topLeading) {
                // The page is covered by its own ground. Gap: the frame has the plain ground behind the pop-up;
                // here a little of the page shows through the system's thinnest material
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    ColorScale.surfaceSunken1.opacity(0.8)
                }
                .opacity(grown)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: closePopUp)
                .accessibilityLabel("Close")
                .accessibilityAddTraits(.isButton)
                ZStack(alignment: .topLeading) {
                    compact(section)
                        .frame(width: from.width)
                        // The card's contents are gone by a third of the way, as the pop-up's start to come in
                        .opacity(1 - min(grown / 0.3, 1))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    expanded(section)
                        .frame(width: to.width, height: to.height, alignment: .top)
                        .opacity(min(max((popGrow - 0.25) / 0.45, 0), 1))
                }
                .frame(width: from.width + (to.width - from.width) * popGrow,
                       height: max(from.height + (to.height - from.height) * popGrow, 1), alignment: .topLeading)
                .clipShape(shape)
                .background(shape.fill(ColorScale.surfaceWidget).dsShadow(.shadow2))
                .offset(x: from.minX + (to.minX - from.minX) * popMove, y: from.minY + (to.minY - from.minY) * popMove)
            }
        }
        .onAppear {
            withAnimation(Self.openMove) { popMove = 1 }
            withAnimation(Self.openGrow) { popGrow = 1 }
        }
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, closePopUp)
    }

    /// What the card holds on the page, which the pop-up starts as
    @ViewBuilder private func compact(_ section: FundContext.FundSection) -> some View {
        switch section {
        case .holdings: boxedBody("Fund holdings") { largestHoldings }
        case .sectors: boxedBody("Sectors exposure") { largestSectors }
        case .growth:
            switch layout {
            case .card: growthBody(period: $period)
            case .sheet: growthChart(.sheet, period: $period)
            }
        default: EmptyView()
        }
    }

    /// What the pop-up holds once it is open
    @ViewBuilder private func expanded(_ section: FundContext.FundSection) -> some View {
        switch section {
        case .holdings: allHoldings
        case .sectors: allSectors
        case .growth: allGrowth
        default: EmptyView()
        }
    }

    /// A pop-up's title, with what stands under it, over what the pop-up holds. A drag down on the title closes
    /// the pop-up, and a tap inside it is not a tap on the page behind it.
    private func popUpBody<Under: View, Content: View>(_ title: String, @ViewBuilder under: () -> Under, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 23) { // Gap: 23 under the title, no spacing token
                // Gap: Md 23/31 has no text style (H4 is 23/35)
                GapText(title, family: .walsheim, medium: true, size: 23, lineHeight: 31, color: Self.titleInk)
                    .fixedSize()
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)
                under()
            }
            .padding(.horizontal, 17) // Gap: 17 inside the pop-up, no spacing token
            .padding(.top, 21) // Gap: 21 over the title, no spacing token
            .padding(.bottom, 10) // Gap: what is under is cut off 10 under the title's part, no spacing token
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onEnded { value in
                        if value.translation.height > 50 { closePopUp() }
                    }
            )
            content()
        }
        .contentShape(Rectangle())
        .onTapGesture {}
    }

    /// 101:17152: "All", chosen, then "Sector" and "Fund", and every holding, the largest first, which scroll
    /// under them
    private var allHoldings: some View {
        popUpBody("Fund holdings") {
            // 101:17211
            Stack(direction: .horizontal, gap: .spaceMd, alignment: .center) {
                view("All", orb: "MFDetailOrbMarket", chosen: true, edged: false)
                view("Sector", orb: "MFDetailOrbForYou", chosen: false)
                view("Fund", orb: "MFDetailOrbResearch", chosen: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } content: {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(fund.holdings) { holding in
                        popUpRow(holding.name, under: "Equity • \(holding.sector)", share: holding.share) {
                            Image(holding.logo)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32.961, height: 32.961)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.top, 17) // Gap: the first holding is 27 under the row, 17 inside the list; no spacing token
                .padding(.horizontal, 17) // Gap: 17 inside the pop-up, no spacing token
            }
        }
    }

    /// The sectors' pop-up, in the manner of the holdings': each sector with its drawing, the largest of the
    /// fund's holdings that are in it, and its share. No frame draws it.
    private var allSectors: some View {
        popUpBody("Sectors exposure") {
            EmptyView()
        } content: {
            VStack(spacing: 0) {
                ForEach(fund.sectors, id: \.name) { sector in
                    popUpRow(sector.name, under: fund.companies(in: sector.name), share: sector.share) {
                        if let art = MutualFund.sectorArt[sector.name] {
                            Image(art)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                        }
                    }
                }
            }
            .padding(.top, 17) // Gap: the first sector is 27 under the title, as the holdings are under their row; no spacing token
            .padding(.horizontal, 17) // Gap: 17 inside the pop-up, no spacing token
        }
    }

    /// The chart's pop-up, in the manner of the holdings': the chart, taller, and under it what the NAV has done
    /// over the period it shows. No frame draws it.
    private var allGrowth: some View {
        popUpBody("Fund performance") {
            EmptyView()
        } content: {
            VStack(spacing: 17) { // Gap: 17 under the chart, as in the card; no spacing token
                growthChart(.popUp, period: $period)
                columns(spread, leading: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// What the NAV has done over the period the chart shows: where it is, its highest and lowest, and how far
    /// it has moved from the period's start, written as the fund's facts are
    private var spread: [(label: String, value: String)] {
        let series = fund.chart(for: period).series
        let last = series.last ?? 1
        let prices = series.map { fund.nav * $0 / last }
        func rupees(_ price: Double) -> String { "Rs" + String(format: "%.2f", price) }
        return [("Nav", rupees(fund.nav)),
                ("\(period.rawValue) high", rupees(prices.max() ?? fund.nav)),
                ("\(period.rawValue) low", rupees(prices.min() ?? fund.nav)),
                ("\(period.rawValue) change", String(format: "%+.1f%%", (last / (series.first ?? 1) - 1) * 100))]
    }

    /// 101:17155: a row of a pop-up, 85 from one to the next: a 41 pt badge, a name over a line about it, and a
    /// share of the fund in lavender, then a rule
    private func popUpRow<Badge: View>(_ name: String, under: String, share value: Double, @ViewBuilder badge: () -> Badge) -> some View {
        VStack(spacing: 20) { // Gap: 20 from a row to its rule, no spacing token
            HStack(alignment: .top, spacing: SpacingScale.spaceLg) {
                badge()
                    .frame(width: 41, height: 41)
                    .background(Circle().fill(ColorScale.surfaceBase))
                    .overlay(Circle().strokeBorder(ColorScale.borderSubtle, lineWidth: 0.563)) // Gap: the badge's 0.563 stroke is not the hairline
                    .padding(.top, 1) // Gap: the badge sits 1 under the name's top, no spacing token
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) { // Gap: 1 under the name, no spacing token
                    // Gap: P3 on the 23 pt line this file gives it (the token's line is 25). A long name is given in full
                    GapText(name, family: .walsheim, medium: false, size: 17, lineHeight: 23, color: ColorScale.contentPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    small(under)
                        .lineLimit(1)
                }
                Spacer(minLength: SpacingScale.spaceXs)
                // Gap: P3 on this file's line, in an accent colour with no content token
                GapText(Self.share(value), family: .walsheim, medium: false, size: 17, lineHeight: 23, color: Self.holdingInk)
                    .fixedSize()
            }
            rowRule
        }
        .padding(.bottom, 21) // Gap: 21 from a rule to the next row, no spacing token
        .accessibilityElement(children: .combine)
    }

    /// 101:15119: the five largest sectors, a row each, with each one's drawing
    private var sectors: some View {
        boxed("Sectors exposure") { largestSectors }
    }

    @ViewBuilder private var largestSectors: some View {
        let largest = Array(fund.sectors.prefix(5))
        ForEach(Array(largest.enumerated()), id: \.element.name) { place, sector in
            row(sector.name, share: sector.share, ink: ColorScale.contentPrimary, ruled: place < largest.count - 1) {
                if let art = MutualFund.sectorArt[sector.name] {
                    Image(art)
                }
            }
        }
    }

    /// 101:15195: Fund charges, numbered, each with its name in yellow over what it comes to
    private var charges: some View {
        Surface(surface: .surfaceWidget, radius: .radius23) {
            VStack(alignment: .leading, spacing: 21) { // Gap: 21 between the charges, no spacing token
                heading("Fund charges")
                ForEach(Array(fund.charges.enumerated()), id: \.offset) { place, charge in
                    HStack(alignment: .top, spacing: 0) {
                        // Gap: Md 21/29 has no text style
                        GapText("\(place + 1)", family: .walsheim, medium: true, size: 21, lineHeight: 29, color: ColorScale.contentPrimary)
                            .fixedSize()
                            // The names start 47 after the numbers do
                            .frame(width: 47, alignment: .leading)
                        Stack(gap: .spaceXs) {
                            copy(charge.label, color: Self.chargeInk)
                                .fixedSize()
                                .frame(height: 21)
                            // Gap: P2 on the 27 pt line this file gives it
                            GapText(charge.value, family: .walsheim, medium: false, size: 19, lineHeight: 27, color: ColorScale.contentPrimary)
                                .fixedSize()
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(charge.label == "Exist load" ? "Exit load" : charge.label), \(charge.value)")
                }
            }
            .padding(.horizontal, 19) // Gap: 19 inside the card, no spacing token
            .padding(.vertical, 17) // Gap: 17 above and below, no spacing token
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 101:15209: the managers' portraits side by side, running off the card's trailing edge
    private var managers: some View {
        Surface(surface: .surfaceWidget, radius: .radius23) {
            VStack(alignment: .leading, spacing: SpacingScale.spaceMdLg) {
                heading("Fund managers")
                    .padding(.leading, 19) // Gap: 19 inside the card, no spacing token
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
                    .padding(.horizontal, 19) // Gap: 19 inside the card, no spacing token
                }
                // The row scrolls sideways, so a swipe along it is not one that sends the card to the advisor
                .background(SwipeShield())
            }
            .padding(.top, 17) // Gap: 17 over the title, no spacing token
            .padding(.bottom, SpacingScale.space3xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 101:15222, 101:15221: the rating again, large, over its dots, and "Decade fund rating" under them. The
    /// frame writes 4.9 here and 4.7 under the name; the page writes the fund's one rating in both places.
    private var verdict: some View {
        VStack(spacing: 11) { // Gap: 11 under the dots, no spacing token
            VStack(spacing: 16) { // Gap: 9 in the frame; the figure sits 7 lower on its 49 pt line here, so 16. No spacing token
                // Gap: Reckless SemiBold 53/49 has no text style, and the design system has no SemiBold face: Medium here
                GapText(String(format: "%.1f", fund.rating), family: .reckless, medium: true, size: 53, lineHeight: 49, color: tone.dot)
                    .fixedSize()
                FundRatingDots(filled: filled, tone: tone)
            }
            // Gap: Md 23/31 has no text style (H4 is 23/35)
            GapText("Decade fund rating", family: .walsheim, medium: true, size: 23, lineHeight: 31, color: Self.titleInk)
                .fixedSize()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Decade fund rating, \(String(format: "%.1f", fund.rating)) of 5")
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: The foot

    /// 101:15391: the wash at the foot of the screen, 125 tall, with "Ask advisor" and "Start SIP" on it
    /// (`MutualFundFoot`). Gap: the frame blurs what is behind the wash by 12; here it is the system's thinnest
    /// material.
    private var foot: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                LinearGradient(colors: [Self.footTop, Self.footWash], startPoint: .top, endPoint: .bottom)
            }
            .frame(height: 125)
        }
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
        .overlay {
            if ownsFoot {
                MutualFundFoot(move: 1, grow: 1)
                    .opacity(covered ? 0 : 1)
                    .animation(.easeOut(duration: 0.2), value: covered)
            }
        }
        // "Ask advisor" is 17 in and 17 over the home indicator, whichever page draws it
        .overlay(alignment: .bottomLeading) {
            AdvisorPillTap()
                .padding(.leading, 17) // Gap: 17 from the leading edge, no spacing token
                .padding(.bottom, 17) // Gap: 17 over the home indicator, no spacing token
        }
    }
}

/// A card that a tap opens out. What is in the card keeps its own taps (the chart's periods). A finger lifted
/// after a hold is not a tap: the card is then held, lifted out of the page, and the tap is let go.
private struct OpeningCard<Card: View>: View {
    let open: () -> Void
    @ViewBuilder let card: () -> Card
    @Environment(\.askAbout) private var ask

    var body: some View {
        card()
            .contentShape(Rectangle())
            .onTapGesture {
                if ask.held == nil { open() }
            }
    }
}

/// The fund page's "Ask advisor" pill as something to tap: it opens the advisor's composer (`advisorComposer`).
/// The pill itself is drawn by `MutualFundFoot`, which a homepage may be carrying over the page.
private struct AdvisorPillTap: View {
    @Environment(\.askAbout) private var ask

    var body: some View {
        Color.clear
            .frame(width: 169, height: 53)
            .contentShape(Capsule())
            .onTapGesture { ask.open() }
            .accessibilityLabel("Ask advisor")
            .accessibilityAddTraits(.isButton)
    }
}

/// The bar at the foot of the mutual funds pages, as one thing that changes between them. On a homepage it is
/// the advisor's pill ("Ask your advisor", as `advisorBar()` draws it at rest) and the mic. On a fund's page
/// (101:15392) the advisor's pill has drawn in to "Ask advisor", and the mic has opened out, into the room she
/// left, as "Start SIP". The bar can be anywhere between the two: it is what `FundPush` moves as a fund's page
/// comes in, goes back, or is dragged.
///
/// Where its parts are and how big they are go separately, as the chat's page does when it grows out of its icon:
/// `move` is how far they have travelled and `grow` how far they have changed size, each from 0 on a homepage to
/// 1 on a fund's page. Each has its own spring, so a part arrives a little ahead of its size, which goes just
/// past and settles.
struct MutualFundFoot: View, Animatable {
    /// How far the parts have travelled: 0 on a homepage, 1 on a fund's page
    var move: CGFloat
    /// How far they have changed size, and changed over from one page's contents to the other's
    var grow: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(move, grow) }
        set {
            move = newValue.first
            grow = newValue.second
        }
    }

    private static let pillFill = Color(hex: 0xF9F9F9) // Gap: #F9F9F9, the foot's pills, is unbound
    private static let pillEdge = Color.black.opacity(0.31) // Gap: black 31%, the pills' edge, is unbound
    private static let promptInk = Color.black.opacity(0.67) // Gap: black 67%, the advisor's prompt, is unbound

    /// A place between a homepage's and a fund page's
    private func place(_ from: CGFloat, _ to: CGFloat) -> CGFloat { from + (to - from) * move }

    /// A size between a homepage's and a fund page's
    private func size(_ from: CGFloat, _ to: CGFloat) -> CGFloat { from + (to - from) * grow }

    /// 0 until `grow` reaches `from`, 1 once it reaches `to`
    private func rise(_ from: CGFloat, _ to: CGFloat) -> CGFloat { min(max((grow - from) / (to - from), 0), 1) }

    /// A pill of the foot (101:15393): its fill, its edge, and its own soft shadow
    private var pill: some View {
        Capsule()
            .fill(Self.pillFill)
            .overlay(Capsule().stroke(Self.pillEdge, lineWidth: BorderTokens.hairline))
            .shadow(color: Color.black.opacity(0.03), radius: 15 - 7.5 * rise(0, 1), x: 0, y: 3) // Gap: the pill's own soft shadow, 0 3 15 at 3%, not a Shadow style. ds-lint-ignore: no_raw_shadow
    }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width
            let foot = geo.size.height
            // Both pills are 100 up from the foot on a homepage and 4 higher on a fund's page
            let top = place(foot - 100, foot - 104)
            // The advisor's pill: 294 across on a homepage, 169 on a fund's page
            let advisor = CGRect(x: 17, y: top, width: size(294, 169), height: 53)
            // The mic's 53 pt round, 9 clear of the 294 pill, opens out into "Start SIP": from 9 clear of the
            // advisor's 169 to 17 short of the trailing edge, which is 178 across in the frame
            let start = CGRect(x: place(320, 195), y: top, width: size(53, wide - 212), height: 53)
            let face = size(32.9508, 42.8361)
            ZStack(alignment: .topLeading) {
                pill
                    .opacity(rise(0.15, 0.55))
                    .frame(width: start.width, height: start.height)
                    .at(start.minX, start.minY)
                startSIP
                    .opacity(rise(0.5, 1))
                    .frame(width: start.width, height: start.height)
                    .clipShape(Capsule())
                    .at(start.minX, start.minY)
                // The mic gives way in the middle of the pill it opens into; its drawing carries its shadow, 129
                // across around its 53
                Image("MicButton")
                    .resizable()
                    .frame(width: 129, height: 129)
                    .opacity(1 - rise(0.15, 0.55))
                    .at(start.midX - 26.5 - 38, start.minY - 35)
                pill
                    .frame(width: advisor.width, height: advisor.height)
                    .at(advisor.minX, advisor.minY)
                // A homepage's plus and prompt stay where they are and are lost as the pill draws in over them;
                // "Ask advisor" comes in beside her face once it has
                ZStack(alignment: .topLeading) {
                    Group {
                        Image("PlusIcon")
                            .resizable()
                            .frame(width: 13.0239, height: 13.0156)
                            .at(13.99, 20.82)
                        // Set as `advisorBar()` sets it, so that the one takes over from the other without a jump
                        Text("Ask your advisor") // ds-lint-ignore: no_raw_text
                            .font(FigmaFont.walsheim(17)) // ds-lint-ignore: no_hand_set_type
                            .foregroundStyle(Self.promptInk)
                            .fixedSize()
                            .frame(height: 23)
                            .at(78, 15)
                    }
                    .opacity(1 - rise(0, 0.35))
                    // 101:15574
                    DsText("Ask advisor", variant: .h6)
                        .fixedSize()
                        .frame(height: 23)
                        .at(56, 15)
                        .opacity(rise(0.5, 1))
                }
                .frame(width: advisor.width, height: advisor.height, alignment: .topLeading)
                .clipShape(Capsule())
                .at(advisor.minX, advisor.minY)
                // Her face moves from beside the plus to the leading end of her pill, and grows from 30 to 39
                Group {
                    Image("PillAvatar")
                        .resizable()
                        .opacity(1 - rise(0.3, 0.8))
                    Image("MFDetailAvatar")
                        .resizable()
                        .opacity(rise(0.3, 0.8))
                }
                .frame(width: face, height: face)
                .at(advisor.minX + place(39.525, 5.082), advisor.minY + place(10.525, 5.082))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(grow > 0.5 ? "Ask advisor, Start SIP" : "Ask your advisor")
    }

    /// 101:15458: a plus and "Start SIP", in the middle of the pill; they come in once it has opened
    private var startSIP: some View {
        Stack(direction: .horizontal, gap: .spaceXs, alignment: .center) {
            Image(systemName: "plus")
                .font(.system(size: 22)) // ds-lint-ignore: no_hand_set_type (an SF Symbol's size)
                .foregroundStyle(ColorScale.contentPrimary)
                .frame(width: 19, height: 26)
            DsText("Start SIP", variant: .h6)
                .fixedSize()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A fund's page says so when it has covered the whole of itself, so that a foot bar carried over it gives way
struct FundFootCoveredKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

/// Pushes a fund's page over a mutual funds homepage, with the foot's bar carried across as one thing
/// (`MutualFundFoot`): the homepage's advisor pill becomes the fund page's bar as the page comes in, and goes back
/// with it; while the page is dragged back from its leading edge, the bar follows the finger.
///
/// At rest on the homepage the bar is `advisorBar()`'s own, which is the one that opens the composer. The carried
/// bar takes its place, looking the same, only while a fund's page is up or on its way.
struct FundPush: ViewModifier {
    /// The fund whose page is up; setting it pushes the page, clearing it takes the page back
    @Binding var fund: MutualFund?

    /// The fund whose page is drawn, which follows `fund` with the push's spring
    @State private var shown: MutualFund?
    /// Where the bar is between the homepage's, 0, and the fund page's, 1: how far it has travelled, and how far
    /// it has changed size
    @State private var move: CGFloat = 0
    @State private var grow: CGFloat = 0
    /// The carried bar is up, and the homepage's own is hidden under it
    @State private var carries = false
    @State private var hidesOwn = false
    /// The fund's page has something up over the whole of it (its pop-up of holdings), and the bar is out of the way
    @State private var covered = false

    private static let push = Animation.spring(response: 0.45, dampingFraction: 0.92)
    // The bar's springs are the chat's, from where it grows out of its icon (`RootView`). Opening: it travels a
    // little ahead of its size, which goes just past and settles. Closing: tighter, with only a small give.
    private static let openMove = Animation.spring(response: 0.5, dampingFraction: 0.78)
    private static let openGrow = Animation.spring(response: 0.58, dampingFraction: 0.7)
    private static let closeMove = Animation.spring(response: 0.42, dampingFraction: 0.84)
    private static let closeGrow = Animation.spring(response: 0.46, dampingFraction: 0.76)

    func body(content: Content) -> some View {
        content
            .accessibilityHidden(shown != nil)
            .preference(key: AdvisorBarHiddenKey.self, value: hidesOwn)
            // The advisor stays at the foot of the homepage, as on the other pages
            .advisorBar()
            .overlay {
                // iOS push: the fund's page comes in from the trailing edge, over the homepage
                ZStack {
                    if let shown {
                        MutualFundDetailView(fund: shown, ownsFoot: false, onPull: pulled) { fund = nil }
                            .transition(.move(edge: .trailing))
                    }
                }
            }
            .overlay {
                if carries {
                    MutualFundFoot(move: move, grow: grow)
                        .opacity(covered ? 0 : 1)
                        .animation(.easeOut(duration: 0.2), value: covered)
                }
            }
            .onPreferenceChange(FundFootCoveredKey.self) { covered = $0 }
            .onAppear {
                // Opened with a fund's page already up (`-mfFund`)
                guard fund != nil, shown == nil else { return }
                carries = true
                hidesOwn = true
                move = 1
                grow = 1
                shown = fund
            }
            .onChange(of: fund?.id) {
                if let fund {
                    carries = true
                    hidesOwn = true
                    withAnimation(Self.push) { shown = fund }
                    withAnimation(Self.openMove) { move = 1 }
                    withAnimation(Self.openGrow) { grow = 1 }
                } else {
                    withAnimation(Self.push) { shown = nil }
                    withAnimation(Self.closeMove) { move = 0 }
                    // Waits for the spring to come fully to rest: the homepage's own bar stands still
                    withAnimation(Self.closeGrow, completionCriteria: .removed) {
                        grow = 0
                    } completion: {
                        guard fund == nil else { return }
                        // The homepage's own bar comes back under the carried one, which then goes
                        hidesOwn = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            if fund == nil { carries = false }
                        }
                    }
                }
            }
    }

    /// The page is being dragged back: the bar goes with the finger. When the finger lets go without taking the
    /// page back, the page's own spring brings both home.
    private func pulled(_ share: CGFloat) {
        move = 1 - share
        grow = 1 - share
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

#Preview {
    MutualFundDetailView()
}
