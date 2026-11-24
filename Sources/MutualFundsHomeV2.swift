import SwiftUI

/// Figma "iPhone 14 Plus - 559" (118:26118, file `sub7vIn6sMBlHb4SIWHyek`, which took the place of 101:17619):
/// the mutual funds explore page, the homepage's second version as it now stands. A back button and a search
/// field stay at the top; under them a row of three tabs ("All", chosen, "For you" and "Portfolio"), "Mutual
/// funds" over a row of fund categories, a tinted card of funds ranked by performance, two plain lists, a list
/// under the cube heading, the categories again, and then "All mutual funds": the kinds of fund as chips over a
/// card of funds. Each list has "FUND" and "3Y RETURNS" over its funds; a tap on the returns brings up the
/// choices of stretch (118:26105), and the one picked is the stretch every list's returns are over. The
/// advisor's pill stays at the foot.
///
/// The frame before it had the month's risers as small charts ("Rising in november") after the lists, and a
/// card for each kind of fund, one under the other, where "All mutual funds" is; this frame took both away.
///
/// It was drawn first as 47:6749, with "Explore Mutual Funds" as a title over the search field and a row of
/// nine kinds of fund where the tabs are; the frame took those away.
///
/// It is what a plain launch opens, and `-mf` opens it too; the first version (`MutualFundsHomeView`, with the
/// fund houses' map) is kept behind `-mfHomeV1`. A tap on a fund in a row pushes that
/// fund's page (`MutualFundDetailView`); `-mfFund` opens with the drawn fund's already up. The frame draws one
/// state only: the tabs do not respond yet. A category card, a kind's chip or the
/// ranked card's expand button pushes that category's page (`MutualFundCategoryView`), which lists the real funds
/// of the kind.
///
/// The search field searches the list of active funds (`MutualFundCatalogue.search`). A tap on it brings the
/// keyboard up and puts search over the page, under the top bar: the kinds of fund to browse while nothing is
/// typed, and then the funds found, best first, as the page's own rows. A tap on a fund opens its page, and on a
/// kind its category's page. While search is up the back button is gone and the field runs the width of the
/// page; the cross at its trailing end cancels the search and goes back to the page.
/// No frame draws search in use, so how it looks is made here from the page's own parts.
///
/// The funds in its lists are real ones too, from the list of active funds (`MutualFundCatalogue`), where the
/// frame has placeholders: each list is the top of its category by what the funds have returned a year over
/// three years. The two small charts are as drawn, with the frame's one-month figures (the list has no
/// one-month return), and each opens its real fund's page.
struct MutualFundsHomeV2View: View {
    /// How a rating is coloured (57:8336, 57:8351, 57:8366)
    enum Tone {
        case lavender, yellow, green

        /// The colour a score out of five is written in: green from 4, lavender from 3, yellow under it, as
        /// the frame's ratings are (4.5, 3.1 and 2.9)
        init(score: Double) {
            self = score >= 4 ? .green : score >= 3 ? .lavender : .yellow
        }

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

    /// The kinds of fund search offers to browse (47:7331, the row the page's first drawing had), each with its orb
    static let kinds: [(title: String, orb: String)] = [
        ("Equity", "MFHome2ChipEquity"), ("Banking", "MFHome2ChipBanking"), ("Small cap", "MFHome2ChipSmallCap"),
        ("Debt", "MFHome2ChipDebt"), ("Real estate", "MFHome2ChipRealEstate"), ("Mid cap", "MFHome2ChipMidCap"),
        ("Liquid", "MFHome2ChipLiquid"), ("Large cap", "MFHome2ChipLargeCap"), ("Technology", "MFHome2ChipTechnology"),
    ]

    /// 118:26439: "All mutual funds", as the frame lists them: the eight small cap funds that have returned most
    static let all: [ListedFund] = Array(FundCategory.smallCap.funds.prefix(8))

    /// 57:8327: the ranked card's three funds: the small cap funds that have returned most a year over three
    /// years, which are the first three of the page its expand button opens
    static let ranked: [ListedFund] = Array(FundCategory.smallCap.funds.prefix(3))

    /// 57:8429: "Upcoming mid caps", the first three mid cap funds by the same measure
    static let midCaps: [ListedFund] = Array(FundCategory.midCap.funds.prefix(3))

    /// 57:8430: "New infrastructure funds", the first three infrastructure funds by the same measure
    static let infrastructure: [ListedFund] = Array(FundCategory.infrastructure.funds.prefix(3))

    /// 57:8659: "Rising small cap funds", the three small cap funds after the ranked card's, so that no fund
    /// is on the page twice. The frame repeats the infrastructure funds here.
    static let rising: [ListedFund] = Array(FundCategory.smallCap.funds.dropFirst(3).prefix(3))

    /// 47:7226: the categories. The frame's third and fourth cards are empty, and are kept so.
    static let categories: [(title: String, art: String, artTop: CGFloat)?] = [
        ("Equity funds", "MFHome2CatEquity", 70), ("Hybrid funds", "MFHome2CatHybrid", 79), nil, nil,
    ]

    private static let barShadow = Color.black.opacity(0.08) // Gap: black 8%, the top bar's shadow, is Shadow/1 at a stronger tint
    private static let tabShadow = Color.black.opacity(0.07) // Gap: black 7%, the chosen tab's shadow, is unbound
    private static let rankedInk = Color(hex: 0xA872B3) // Gap: accent-lavender/500 has no semantic token
    private static let rankedTop = Color(hex: 0xD0F7F4, opacity: 0.44) // Gap: #D0F7F4 44%, the top of the ranked card, is unbound
    private static let rankedFoot = Color(hex: 0xE7FCE4, opacity: 0.44) // Gap: #E7FCE4 44%, the foot of the ranked card, is unbound
    private static let rankedShadow = Color.black.opacity(0.08) // Gap: black 8%, the ranked card's shadow, is Shadow/1 at a stronger tint
    private static let footWash = Color(hex: 0xF3F6F3) // Gap: #F3F6F3, the wash under the pill, is unbound

    /// The fund whose page is pushed over this one; `-mfFund` opens with the drawn fund's already up
    @State private var openedFund: MutualFund? = ProcessInfo.processInfo.arguments.contains("-mfFund") ? .kotak : nil

    /// The category whose page is pushed over this one, under the advisor's pill
    @State private var openedCategory: FundCategory?
    private static let push = Animation.spring(response: 0.45, dampingFraction: 0.92)

    /// Search is up over the page
    @State private var searching = false
    /// The field widens over the back button, and narrows again, on this spring
    private static let searchSpring = Animation.spring(response: 0.35, dampingFraction: 0.85)
    /// What is typed into the search field
    @State private var query = ""

    /// The stretch every list's returns are over (118:26105), and where on the screen the column's words that were
    /// tapped are while its choices are up
    @State private var period = FundPeriod.threeYears
    @State private var pickingAt: CGRect?
    /// The list whose column brought them up: they stay with its words if the page moves under them
    @State private var pickingIn: String?
    /// How far the choices have come out from under the column's words (0 to 1), and how far they've grown from
    /// the words' size to their own: each on its own spring, as a fund's card opens out
    @State private var pillMove: CGFloat = 0
    @State private var pillGrow: CGFloat = 0
    /// The pill sliding to the stretch picked
    private static let pickSpring = Animation.spring(response: 0.32, dampingFraction: 0.8)
    // The springs a fund's card opens out and goes back on (`MutualFundDetailView`)
    private static let openMove = Animation.spring(response: 0.5, dampingFraction: 0.78)
    private static let openGrow = Animation.spring(response: 0.58, dampingFraction: 0.7)
    private static let closeMove = Animation.spring(response: 0.42, dampingFraction: 0.84)
    private static let closeGrow = Animation.spring(response: 0.46, dampingFraction: 0.76)

    /// Brings the choices up from the column's words at `place`; they come out once they're there (`periodLayer`)
    private func openPeriods(in list: String, at place: CGRect) {
        guard pickingAt == nil else { return }
        Haptics.tap()
        pillMove = 0
        pillGrow = 0
        pickingIn = list
        pickingAt = place
    }

    /// Sends the choices back under the column's words, and takes them away once they're there
    private func closePeriods() {
        guard pickingAt != nil, pillGrow > 0 else { return }
        withAnimation(Self.closeGrow) { pillGrow = 0 }
        withAnimation(Self.closeMove, completionCriteria: .removed) {
            pillMove = 0
        } completion: {
            if pillMove == 0 { pickingAt = nil }
        }
    }

    private func pick(_ picked: FundPeriod) {
        Haptics.tap()
        withAnimation(Self.pickSpring) { period = picked }
        // A moment to see the pill land on it, and the choices go back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { closePeriods() }
    }

    /// A list's funds, the better return over the chosen stretch first; a fund that hasn't run that long is last
    private func ordered(_ funds: [ListedFund]) -> [ListedFund] {
        guard period != .threeYears else { return funds }
        return funds.enumerated().sorted {
            let first = $0.element.returned(over: period), second = $1.element.returned(over: period)
            return (first == nil ? 1 : 0, -(first ?? 0), $0.offset) < (second == nil ? 1 : 0, -(second ?? 0), $1.offset)
        }.map(\.element)
    }

    /// 118:26105: the choices of stretch, under the column's words that brought them up (over them where there's
    /// no room under), their trailing end 10 from the screen's as the frame has it. They come out from under those
    /// words: starting behind them at their size, moving out to their place and growing to their own size, and go
    /// back the same way once one's picked. A tap anywhere else puts them away too.
    private var periodLayer: some View {
        GeometryReader { screen in
            if let at = pickingAt {
                let top = screen.frame(in: .global).minY
                let under = at.maxY - top + 6
                // Clear of the advisor's pill at the foot
                let fits = under + 57 < screen.size.height - 120
                let rest = fits ? under : at.minY - top - 6 - 57
                // Behind the words: as wide as they are, its trailing end at theirs, its middle on theirs
                let small = min(1, at.width / 352)
                let grown = min(max(pillGrow, 0), 1)
                let scale = small + (1 - small) * pillGrow
                let behind = at.midY - top - 57 / 2
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { closePeriods() }
                    .accessibilityLabel("Close")
                    .accessibilityAddTraits(.isButton)
                FundPeriodPicker(chosen: period, onPick: pick)
                    .fixedSize()
                    .scaleEffect(scale, anchor: .trailing)
                    .opacity(min(1, grown / 0.3))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 10 + (screen.size.width - at.maxX + screen.frame(in: .global).minX - 10) * (1 - pillMove)) // Gap: 10 from the screen's trailing edge, no spacing token
                    .offset(y: behind + (rest - behind) * pillMove)
                    .onAppear {
                        withAnimation(Self.openMove) { pillMove = 1 }
                        withAnimation(Self.openGrow) { pillGrow = 1 }
                    }
            }
        }
    }

    @FocusState private var searchFocused: Bool

    private func open(_ category: FundCategory?) {
        guard let category, openedCategory == nil else { return }
        Haptics.tap()
        withAnimation(Self.push) { openedCategory = category }
    }

    /// Opens a listed fund's page
    private func open(_ fund: ListedFund?) {
        guard let fund, openedFund == nil else { return }
        Haptics.tap()
        searchFocused = false
        openedFund = .listed(fund)
    }

    private func endSearch() {
        guard searching else { return }
        Haptics.tap()
        searchFocused = false
        withAnimation(Self.searchSpring) { searching = false }
        query = ""
    }

    var body: some View {
        VStack(spacing: 0) {
            // Keeps the page from running up under the status bar as it scrolls
            Color.clear.frame(height: 1)
            ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    tabs
                        .padding(.leading, 17) // Gap: 17 from the screen's edge, no spacing token
                        .padding(.top, 88) // Gap: the tabs start 89 under the status bar, 19 under the top bar; no spacing token
                    // 118:26173
                    categories("Mutual funds", across: 168)
                        .padding(.top, 37) // Gap: 37 under the tabs, no spacing token
                    // The sections are 47 apart
                    Group {
                        rankedCard
                            .padding(.horizontal, SpacingScale.spaceMdLg)
                        list("Upcoming mid caps", Self.midCaps)
                            .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
                        list("New infrastructure funds", Self.infrastructure)
                            .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
                        cubeList
                            .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
                        categories("Rising small cap funds", across: 173)
                        allFunds
                    }
                    .padding(.top, SpacingScale.space6xl)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // Room to scroll the last card clear of the advisor's pill
                .padding(.bottom, SpacingScale.space10xl)
            }
            .opacity(searching ? 0 : 1)
            .allowsHitTesting(!searching)
            .accessibilityHidden(searching)
            if searching {
                search
                    .transition(.opacity)
            }
            }
        }
        // A tap on the field brings search up
        .onChange(of: searchFocused) {
            if searchFocused, !searching {
                withAnimation(Self.searchSpring) { searching = true }
            }
        }
        // The frame has no fill of its own: white
        .background(ColorScale.surfaceWidget.ignoresSafeArea())
        .overlay(alignment: .top) { bar }
        .overlay { periodLayer }
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
        .overlay {
            // iOS push: a category's page comes in from the trailing edge, over this one and under the advisor's
            // pill, which stays where it is. Its funds open their pages as the homepage's do.
            ZStack {
                if let openedCategory {
                    MutualFundCategoryView(category: openedCategory) { fund in
                        guard openedFund == nil else { return }
                        Haptics.tap()
                        openedFund = .listed(fund)
                    } onKind: { kind in
                        // Another kind's page takes this one's place, from its top
                        Haptics.tap()
                        self.openedCategory = kind
                    } onBack: {
                        withAnimation(Self.push) { self.openedCategory = nil }
                    }
                    .id(openedCategory.id)
                    .transition(.move(edge: .trailing))
                }
            }
        }
        // The advisor stays at the foot of the page; a fund's page is pushed over it, and the bar is carried across
        .modifier(FundPush(fund: $openedFund))
        .preferredColorScheme(.light)
    }

    // MARK: The top bar and the tabs

    /// 101:18264: the bar that stays at the top as the page scrolls under it, 7 under the status bar: a round
    /// back button, 50 across, and the search field. It has no ground of its own; its button and field cast its
    /// shadow. The button does nothing yet: the page has nothing behind it to go back to. While search is up the
    /// button is gone and the field runs the width of the page, with a cross at its trailing end that cancels the
    /// search and goes back to the page.
    private var bar: some View {
        HStack(spacing: 7) { // Gap: 7 from the button to the field, no spacing token
            // 101:18265: the category pages' back button at 49.9 × 49. The drawing carries its own soft shadow,
            // 262 × 261 around its 54 × 53.
            if !searching {
                Image("MFCatBack")
                    .resizable()
                    .frame(width: 262 * 49.9 / 54, height: 261 * 49 / 53)
                    .offset(y: 4 * 49 / 53)
                    .frame(width: 49.9, height: 49)
                    .accessibilityLabel("Back")
                    .accessibilityAddTraits(.isButton)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
            // 101:18267: the search field, 57 tall
            Surface(surface: .surfaceWidget, shape: .capsule, border: .borderSubtle, shadow: .none) {
                FundSearchField(prompt: "SEARCH MID CAP", text: $query, focused: $searchFocused, active: searching, onCancel: endSearch)
                    .padding(.leading, 18.3) // Gap: 18.3 inside the field, no spacing token
                    .padding(.trailing, SpacingScale.spaceXs)
                    .frame(height: 57)
                    // A tap anywhere in the field is a tap on what is typed
                    .contentShape(Rectangle())
                    .onTapGesture { searchFocused = true }
            }
            .shadow(color: Self.barShadow, radius: 25, x: 0, y: 4) // Gap: 0 4 50 at 8%, Shadow/1's shape at a stronger tint. ds-lint-ignore: no_raw_shadow
        }
        .padding(.leading, SpacingScale.spaceMdLg)
        .padding(.trailing, SpacingScale.spaceMdLg)
        .padding(.top, 11) // Gap: the field is 10 under the status bar, 3 inside the bar's 63; no spacing token
    }

    /// 109:20463: "All", chosen, in a black pill, then "For you" and "Portfolio", each after the grid
    private var tabs: some View {
        HStack(spacing: 0) {
            tab("All", chosen: true)
            tab("For you", chosen: false)
                .padding(.leading, SpacingScale.spaceMdLg)
            tab("Portfolio", chosen: false)
                .padding(.leading, SpacingScale.spaceSm)
        }
    }

    private func tab(_ title: String, chosen: Bool) -> some View {
        Stack(direction: .horizontal, gap: .spaceMd, alignment: .center) {
            Image("MFExploreGrid")
                .foregroundStyle(chosen ? ColorScale.contentOnColor : ColorScale.contentSecondary)
                .accessibilityHidden(true)
            DsText(title, variant: .h5, color: chosen ? .contentOnColor : .contentSecondary)
                .fixedSize()
        }
        .padding(.horizontal, 11) // Gap: 11 inside the pill, no spacing token
        .padding(.vertical, 6) // Gap: 6 above and below, no spacing token
        .background {
            if chosen {
                Capsule()
                    .fill(ColorScale.surfaceInverse)
                    .shadow(color: Self.tabShadow, radius: 24.25, x: 0, y: 4) // Gap: 0 4 48.5 at 7%, not a Shadow style. ds-lint-ignore: no_raw_shadow
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(chosen ? .isSelected : [])
    }

    // MARK: Search

    /// Search, over the page and under the top bar: the kinds of fund to browse while nothing is typed, then the
    /// funds the list finds for what is typed, best first, as the page's own rows. A drag on it puts the keyboard
    /// away. No frame draws it.
    private var search: some View {
        let typed = query.trimmingCharacters(in: .whitespaces)
        let found = typed.isEmpty ? [] : MutualFundCatalogue.search(typed, limit: 50)
        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if typed.isEmpty {
                    title("Browse by kind")
                        .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
                    browse
                        .padding(.top, SpacingScale.spaceXl)
                } else if found.isEmpty {
                    title("No funds found")
                    // Gap: P4 on the 21 pt line this file gives it (the token's line is 23)
                    GapText("Nothing in the list of active funds matches “\(typed)”. Try a fund house, or a kind such as small cap or liquid.", family: .walsheim, medium: false, size: 15, lineHeight: 21, color: ColorScale.contentTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, SpacingScale.spaceMd)
                } else {
                    // Gap: P5 on the 19 pt line this file gives it (the token's line is 21)
                    GapText(found.count == 50 ? "The first 50 funds found" : found.count == 1 ? "1 fund found" : "\(found.count) funds found", family: .walsheim, medium: false, size: 13, lineHeight: 19, color: ColorScale.contentTertiary)
                        .fixedSize()
                    rows(found)
                        .padding(.top, SpacingScale.spaceXl)
                }
            }
            .padding(.horizontal, typed.isEmpty ? 0 : 17) // Gap: 17 from the screen's edges, no spacing token
            .padding(.top, 93) // Gap: 30 under the top bar, no spacing token
            .frame(maxWidth: .infinity, alignment: .leading)
            // Room to scroll the last fund clear of the advisor's pill
            .padding(.bottom, SpacingScale.space10xl)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(ColorScale.surfaceWidget)
    }

    /// The kinds of fund, as many to a row as fit; a tap opens the kind's page
    private var browse: some View {
        FlowRows(spacing: SpacingScale.spaceMd) {
            ForEach(Self.kinds, id: \.title) { kind in
                FundKindChip(title: kind.title, orb: kind.orb)
                    .onTapGesture {
                        searchFocused = false
                        open(FundCategory.named(kind.title))
                    }
            }
        }
        .padding(.horizontal, SpacingScale.spaceLg)
    }

    // MARK: Lists

    /// A list's title (57:8326). Gap: H4 on the 29 pt line this file gives it (the token's line is 35)
    private func title(_ string: String) -> some View {
        GapText(string, family: .walsheim, medium: true, size: 23, lineHeight: 29, color: ColorScale.contentPrimary)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
    }

    /// 57:8325: "Performing small caps", ranked, in a tinted card with a soft shadow and a white card inside it
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
                    // Its tap target is 44 across
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture { open(.performingSmallCap) }
                    .padding(-4.5) // Gap: the 44 pt tap target reaches 4.5 past the 35 pt button, no spacing token
                    .accessibilityLabel("See all performing small caps")
                    .accessibilityAddTraits(.isButton)
            }
            .padding(.horizontal, 17) // Gap: 17 inside the card, no spacing token
            Surface(surface: .surfaceWidget, radius: .radius15, shadow: .none) {
                VStack(spacing: 37) { // Gap: 37 between the rows, no spacing token
                    ForEach(ordered(Self.ranked)) { row($0) }
                }
                .padding(17) // Gap: 17 inside the white card, no spacing token
            }
            .padding(.horizontal, SpacingScale.spaceMdLg)
        }
        .padding(.vertical, 17) // Gap: 17 above and below, no spacing token
        .background {
            let outline = RoundedRectangle(cornerRadius: RadiusToken.radius23.value, style: .continuous)
            // The tint is see-through, and its shadow must not show through it: the shadow is cast by a white
            // card under the tint, which on the white page looks the same as the tint alone
            outline
                .fill(ColorScale.surfaceWidget)
                .shadow(color: Self.rankedShadow, radius: 50, x: 0, y: 4) // Gap: 0 4 100 at 8%, Shadow/1's shape at a stronger tint, spread not drawn. ds-lint-ignore: no_raw_shadow
                .overlay(outline.fill(LinearGradient(colors: [Self.rankedTop, Self.rankedFoot], startPoint: .top, endPoint: .bottom)))
        }
    }

    /// 57:8429: a title over three funds
    private func list(_ heading: String, _ funds: [ListedFund]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            title(heading)
            listed(heading, funds)
                .padding(.top, 17) // Gap: 17 under the title, no spacing token
        }
    }

    /// The column names, then the funds 15 under them
    private func listed(_ heading: String, _ funds: [ListedFund]) -> some View {
        Stack(gap: .spaceLg) {
            FundColumns(period: period) {
                openPeriods(in: heading, at: $0)
            } onMove: { place in
                if pickingAt != nil, pickingIn == heading { pickingAt = place }
            }
            rows(ordered(funds))
        }
    }

    private func rows(_ funds: [ListedFund]) -> some View {
        Stack(gap: .space3xl) {
            ForEach(funds) { row($0) }
        }
    }

    /// 57:8328: one of the homepage's funds as a row; a tap opens its page
    private func row(_ fund: ListedFund) -> some View {
        MutualFundRow(fund, over: period) { open(fund) }
    }

    /// 57:8659: the cube, a title and a line about it, then three funds
    private var cubeList: some View {
        VStack(alignment: .leading, spacing: 17) { // Gap: 17 under the heading, no spacing token
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
            listed("Rising small cap funds", Self.rising)
        }
    }

    // MARK: All mutual funds

    /// 118:26436: "All mutual funds": the kinds of fund as chips, running off the trailing edge (a tap opens that
    /// kind's page; the last is written as the frame writes it), then "FUND" and the returns' stretch over the
    /// funds in the widget card, as a category's page lists them: returns to two decimals, and the first marked
    /// as the highest
    private var allFunds: some View {
        let funds = ordered(Self.all)
        let leader = funds.first.flatMap { $0.returned(over: period) == nil ? nil : $0.id }
        return VStack(alignment: .leading, spacing: 0) {
            title("All mutual funds")
                .padding(.leading, 17) // Gap: 17 from the screen's edge, no spacing token
            ScrollView(.horizontal, showsIndicators: false) {
                Stack(direction: .horizontal, gap: .spaceMd) {
                    ForEach(Self.kinds, id: \.title) { kind in
                        FundKindChip(title: kind.title == "Technology" ? "Technologi" : kind.title, orb: kind.orb)
                            .onTapGesture { open(FundCategory.named(kind.title)) }
                            .accessibilityLabel(kind.title)
                    }
                }
                .padding(.horizontal, SpacingScale.spaceMdLg)
            }
            .scrollClipDisabled()
            .padding(.top, SpacingScale.spaceMdLg)
            FundColumns(period: period) {
                openPeriods(in: "All mutual funds", at: $0)
            } onMove: { place in
                if pickingAt != nil, pickingIn == "All mutual funds" { pickingAt = place }
            }
            .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
            .padding(.top, SpacingScale.spaceLg)
            // 118:26439: the funds, in the widget card with its designed shadow
            Surface(surface: .surfaceWidget, radius: .radius23) {
                VStack(spacing: 41) { // Gap: 41 between the rows, no spacing token
                    ForEach(funds) { fund in
                        MutualFundRow(fund, over: period, decimals: 2, badge: fund.id == leader ? "Highest \(period.rawValue) return" : nil) {
                            open(fund)
                        }
                    }
                }
                .padding(.horizontal, 17) // Gap: 17 inside the card, no spacing token
                .padding(.top, 24) // Gap: 24 over the first fund, no spacing token
                .padding(.bottom, 28) // Gap: 28 under the last, no spacing token
            }
            .padding(.horizontal, SpacingScale.spaceMdLg)
            .padding(.top, SpacingScale.spaceLg)
        }
    }

    // MARK: Categories

    /// 118:26173, 118:26210: a title over a row of cards, running off the trailing edge: "Mutual funds" at the top
    /// of the page, its cards 168 across, and "Rising small cap funds" further down, its cards 173
    private func categories(_ heading: String, across: CGFloat) -> some View {
        Stack(gap: .space2xl) {
            DsText(heading, variant: .h3)
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
                            .frame(width: across, height: 173, alignment: .topLeading)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { open(category.flatMap { FundCategory.named($0.title) }) }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(category == nil ? [] : .isButton)
                        .accessibilityHidden(category == nil)
                    }
                }
                .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
            }
        }
    }
}

/// A rating out of five as a figure and five dots (57:8336, 101:15361)
struct FundRatingMark: View {
    /// As written: "4.7"
    let rating: String
    /// How many of the five dots are filled
    let filled: Int
    let tone: MutualFundsHomeV2View.Tone

    var body: some View {
        Stack(direction: .horizontal, gap: .spaceXs, alignment: .center) {
            // Gap: Md 17/21 at 4% tracking has no text style
            GapText(rating, family: .walsheim, medium: true, size: 17, lineHeight: 21, trackingPercent: 4, color: tone.ink)
                .fixedSize()
            FundRatingDots(filled: filled, tone: tone)
        }
    }
}

/// Five 15 pt dots, the first of them filled (57:8338, 101:15224)
struct FundRatingDots: View {
    let filled: Int
    let tone: MutualFundsHomeV2View.Tone

    var body: some View {
        HStack(spacing: 3) { // Gap: 3 between the dots, no spacing token
            ForEach(0..<5, id: \.self) { place in
                if place < filled {
                    Circle().fill(tone.dot).frame(width: 15, height: 15)
                } else {
                    Circle().strokeBorder(ColorScale.borderDefault, lineWidth: 1).frame(width: 15, height: 15) // Gap: a 1 pt ring, not the hairline
                }
            }
        }
        .accessibilityHidden(true)
    }
}

extension MutualFundRow {
    /// A fund from the list of active funds: its name in full, its house's logo, the return it is ranked by, and
    /// its score among its category's funds as the figure and dots
    /// The return is written to one decimal, as the explore page has it, or to two, as a category's page does
    /// over the stretch asked for; a fund that hasn't run that long has a dash
    init(_ fund: ListedFund, over period: FundPeriod = .threeYears, decimals: Int = 1, badge: String? = nil, onTap: @escaping () -> Void) {
        let returned = fund.returned(over: period)
        self.init(
            name: fund.name, logo: fund.logo ?? "", house: fund.house,
            returned: returned.map { String(format: "%.\(decimals)f%%", $0) } ?? "–", up: (returned ?? 0) >= 0,
            rating: String(format: "%.1f", fund.score), filled: Int(fund.score.rounded()),
            tone: MutualFundsHomeV2View.Tone(score: fund.score),
            kind: fund.kindLine, badge: badge, widest: decimals > 1 ? "49." + String(repeating: "5", count: decimals) + "%" : "49.5%", onTap: onTap
        )
    }
}

/// Figma 57:8328: a mutual fund as a list row, 71 tall. Its fund house's logo, its name in full with its return
/// at the trailing edge, its rating as a figure and five dots, and what kind of fund it is. It is the row the mutual
/// funds pages list funds with: the homepage's lists, and the category pages'.
struct MutualFundRow: View {
    let name: String
    /// The fund house's logo, an image set's name
    let logo: String
    /// The fund house, whose first letter stands in where the app has no logo for it
    var house = ""
    /// What it has returned, as written: "18.7%"
    let returned: String
    /// Written in green, or in red for a loss
    var up = true
    /// Its rating out of five, as written, and how many of the five dots are filled
    let rating: String
    let filled: Int
    let tone: MutualFundsHomeV2View.Tone
    /// "Direct • Equity • Large cap"
    let kind: String
    /// What the fund is first at, written over its name where its rating would be (79:12044): "Highest 3Y return"
    var badge: String? = nil
    /// The widest return the row keeps room for: "49.5%" to one decimal, "49.55%" to two
    var widest = "49.5%"
    let onTap: () -> Void

    private static let upInk = Color(hex: 0x3FD519) // Gap: utility-green/400 has no semantic token
    private static let downInk = Color(hex: 0xF0453A) // Gap: utility-red/500 has no semantic token

    var body: some View {
        Stack(direction: .horizontal, gap: .spaceLg) {
            FundHouseLogo(name: logo, side: 51, house: house)
            VStack(alignment: .leading, spacing: 0) {
                if let badge {
                    // 79:12044: the mark and what the fund is first at
                    Stack(direction: .horizontal, gap: .spaceXs, alignment: .center) {
                        Image("MFCatTop")
                            .accessibilityHidden(true)
                        // Gap: Reckless Regular 15/21 has no text style
                        GapText(badge, family: .reckless, medium: false, size: 15, lineHeight: 21, color: ColorScale.contentPrimary)
                            .fixedSize()
                    }
                    .padding(.bottom, 1) // Gap: 1 over the name, no spacing token
                }
                HStack(alignment: .top, spacing: SpacingScale.spaceXs) {
                    // The name is given in full, over as many lines as it needs; the return keeps to the first
                    DsText(name, variant: .p3)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    // The return's room is always that of the widest it's set for ("49.5%"), so the name beside it
                    // breaks the same way whatever the return is
                    // Gap: H6 (Md 17/23) in a utility colour with no content token
                    GapText(widest, family: .walsheim, medium: true, size: 17, lineHeight: 23, color: Self.upInk)
                        .fixedSize()
                        .hidden()
                        .overlay(alignment: .trailing) {
                            GapText(returned, family: .walsheim, medium: true, size: 17, lineHeight: 23, color: up ? Self.upInk : Self.downInk)
                                .fixedSize()
                        }
                }
                if badge == nil {
                    FundRatingMark(rating: rating, filled: filled, tone: tone)
                        .padding(.top, 3) // Gap: 3 under the name, no spacing token
                }
                // Gap: P5 on the 19 pt line this file gives it (the token's line is 21)
                GapText(kind, family: .walsheim, medium: false, size: 13, lineHeight: 19, color: ColorScale.contentTertiary)
                    .lineLimit(1)
                    .padding(.top, badge == nil ? SpacingScale.spaceXs : 3) // Gap: 3 under the name where there is no rating, no spacing token
            }
        }
        // 71 with a name of one line, as the frame draws it, and a line taller for each line more; 67 with a badge
        .frame(minHeight: badge == nil ? 71 : 67, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(badge.map { $0 + ", " } ?? "")\(returned), rated \(rating) of 5, \(kind)")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    MutualFundsHomeV2View()
}
