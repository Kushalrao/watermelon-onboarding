import SwiftUI

/// A set of funds that has a page of its own: a kind of fund from the homepage's row, one of its category cards,
/// or what its ranked card opens out to. The funds are the real ones, from the list of active funds
/// (`MutualFundCatalogue`).
struct FundCategory: Identifiable {
    let id: String
    /// The page's title
    let title: String
    /// What its funds are called in the line under the title: "small cap funds"
    let noun: String
    /// The drawing at the top of its page, an image set's name: the category's own, from the frames of category
    /// cards (47:3036, 47:3772, 47:4268)
    let art: String
    /// Whether a fund belongs in it
    let includes: (ListedFund) -> Bool

    /// What the kind's funds invest in, for the line under the page's title ("Funds investing in smaller
    /// companies, ranked by 3-year annualised returns", 79:12166), and what the page's pill asks about ("What are
    /// small cap?", 111:22481), by the category's id
    private static let about: [String: (invests: String, asks: String)] = [
        "equity": ("company shares", "equity funds"), "debt": ("bonds and other loans", "debt funds"),
        "hybrid": ("a mix of shares and bonds", "hybrid funds"), "small-cap": ("smaller companies", "small cap"),
        "performing-small-cap": ("smaller companies", "small cap"), "mid-cap": ("mid-sized companies", "mid cap"),
        "large-cap": ("the largest companies", "large cap"), "liquid": ("very short-term loans", "liquid funds"),
        "banking": ("banks and financial services", "banking funds"), "technology": ("technology companies", "technology funds"),
        "real-estate": ("housing and real estate", "real estate funds"), "infrastructure": ("infrastructure builders", "infrastructure funds"),
        "pharma": ("pharma and healthcare", "pharma funds"), "fmcg": ("consumer goods companies", "FMCG funds"),
        "energy": ("energy and power", "energy funds"), "automobile": ("automobile and transport", "automobile funds"),
        "commodities": ("commodities and resources", "commodities funds"),
    ]

    var invests: String { Self.about[id]?.invests ?? noun }
    var asks: String { Self.about[id]?.asks ?? noun }

    /// Its funds, the better three-year return first
    var funds: [ListedFund] {
        MutualFundCatalogue.ranked(MutualFundCatalogue.funds.filter(includes))
    }

    /// The list classes funds by asset class, SEBI category and size of company, and has no column for the
    /// sector a fund invests in. A sector's funds are told by their names, among the equity funds the list
    /// classes as sectoral or thematic.
    private static func sector(_ words: String...) -> (ListedFund) -> Bool {
        { fund in
            guard fund.assetClass == "Equity", fund.category.contains("Sectoral") || fund.category.contains("Thematic") else { return false }
            let name = fund.name.lowercased()
            return words.contains { name.contains($0) }
        }
    }

    // Each drawing is the one the frames give the category: 47:2976 "Equity fund", 47:3020 "Debt fund",
    // 47:2956 "Hybrid fund", 47:3055 "Banking", 47:3097 "Technology", 47:3385 "Real estate", 47:4619 "Liquid
    // funds". The homepage's row names its small, mid and large cap icons "Start small", "Balanced" and "Low
    // risk", so those sizes take 47:4645, 47:3899 and 47:3877.
    static let equity = FundCategory(id: "equity", title: "Equity funds", noun: "equity funds", art: "MFCatArtEquity") { $0.assetClass == "Equity" }
    static let debt = FundCategory(id: "debt", title: "Debt funds", noun: "debt funds", art: "MFCatArtDebt") { $0.assetClass == "Debt" }
    static let hybrid = FundCategory(id: "hybrid", title: "Hybrid funds", noun: "hybrid funds", art: "MFCatArtHybrid") { $0.assetClass == "Hybrid" }
    static let smallCap = FundCategory(id: "small-cap", title: "Small cap funds", noun: "small cap funds", art: "MFCatArtStartSmall") { $0.category == "Small Cap Fund" }
    static let midCap = FundCategory(id: "mid-cap", title: "Mid cap funds", noun: "mid cap funds", art: "MFCatArtBalanced") { $0.category == "Mid Cap Fund" }
    static let largeCap = FundCategory(id: "large-cap", title: "Large cap funds", noun: "large cap funds", art: "MFCatArtLowRisk") { $0.category == "Large Cap Fund" }
    static let liquid = FundCategory(id: "liquid", title: "Liquid funds", noun: "liquid funds", art: "MFCatArtLiquid") { $0.category == "Liquid Fund" }
    static let banking = FundCategory(id: "banking", title: "Banking funds", noun: "banking and financial services funds", art: "MFCatArtBanking", includes: sector("banking", "financial"))
    static let technology = FundCategory(id: "technology", title: "Technology funds", noun: "technology funds", art: "MFCatArtTechnology", includes: sector("tech", "digital"))
    static let realEstate = FundCategory(id: "real-estate", title: "Real estate funds", noun: "housing and real estate funds", art: "MFCatArtRealEstate", includes: sector("housing", "realty", "real estate"))
    /// The explore page's "New infrastructure funds" are its first three
    static let infrastructure = FundCategory(id: "infrastructure", title: "Infrastructure funds", noun: "infrastructure funds", art: "MFKindArtInfrastructure", includes: sector("infra"))
    // The kinds the explore page's cards add (111:21296 …), each with its card's drawing
    static let pharma = FundCategory(id: "pharma", title: "Pharma funds", noun: "pharma and healthcare funds", art: "MFKindArtPharma", includes: sector("pharma", "health"))
    static let fmcg = FundCategory(id: "fmcg", title: "FMCG funds", noun: "FMCG and consumption funds", art: "MFKindArtFMCG", includes: sector("fmcg", "consum"))
    static let energy = FundCategory(id: "energy", title: "Energy funds", noun: "energy and power funds", art: "MFKindArtEnergy", includes: sector("energy", "power"))
    static let automobile = FundCategory(id: "automobile", title: "Automobile funds", noun: "automobile and transport funds", art: "MFKindArtAutomobile", includes: sector("auto", "transport"))
    static let commodities = FundCategory(id: "commodities", title: "Commodities funds", noun: "commodities and resources funds", art: "MFKindArtCommodities", includes: sector("commodit", "metal", "resources"))
    /// Figma 13:5191, as titled there: what the homepage's "Performing small caps" card opens out to
    static let performingSmallCap = FundCategory(id: "performing-small-cap", title: "Performing small cap", noun: "small cap funds", art: "MFCatArtStartSmall") { $0.category == "Small Cap Fund" }

    /// The category a kind of fund in the homepage's row, or one of its category cards, opens
    static func named(_ title: String) -> FundCategory? {
        switch title {
        case "Equity", "Equity funds", "Equity fund": equity
        case "Debt", "Debt fund": debt
        case "Hybrid funds", "Hybrid fund": hybrid
        case "Pharma": pharma
        case "FMCG": fmcg
        case "Infrastructure": infrastructure
        case "Energy/ Power": energy
        case "Automobile": automobile
        case "Commodities": commodities
        case "Small cap": smallCap
        case "Mid cap": midCap
        case "Large cap": largeCap
        case "Liquid": liquid
        case "Banking": banking
        case "Technology": technology
        case "Real estate": realEstate
        default: nil
        }
    }
}

/// Figma "Category – Small cap" (79:12035, file `sub7vIn6sMBlHb4SIWHyek`): a category's page. A back button and a
/// search field stay at the top. Under them come the category's drawing, its title, a line about what its funds
/// invest in, a pill that asks what the kind is, a row of the kinds of fund, "FUND" and "3Y RETURNS", and the
/// category's funds in a white card, the better return first. It takes the place of 13:5191.
///
/// Each fund is the mutual funds pages' own row (`MutualFundRow`), with its return to two decimals; the first
/// has "Highest 3Y return" over its name where the others have their rating. The drawing, the title, the line
/// and the pill's question are the category's own; the frame draws small cap.
///
/// A tap on a kind in the row brings that kind's page in this one's place. The pill and "3Y RETURNS" do not
/// respond yet. The row's last kind is written "Technologi", as the frame writes it.
///
/// The page has no pill of its own: it is pushed over a homepage and under that page's advisor pill, which stays
/// where it is. The back button, or a drag in from the leading edge, takes it back. The search field narrows the
/// page's own funds to those whose name or house has every word typed; while something is typed the drawing, the
/// title and the rows above the funds step aside for the funds found.
struct MutualFundCategoryView: View {
    let category: FundCategory
    /// A fund was tapped
    var onOpen: (ListedFund) -> Void
    /// A kind in the row was tapped
    var onKind: (FundCategory) -> Void
    var onBack: () -> Void

    /// The category's funds, ordered once when the page opens
    private let funds: [ListedFund]
    /// How far the page has been dragged back
    @State private var pulled: CGFloat = 0
    /// What is typed into the search field
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    /// The funds listed: all of the category's, or those that match what is typed
    private var shown: [ListedFund] {
        funds.filter { $0.matches(query) }
    }

    private var typing: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// Search is in use: the field has the keyboard, or something is typed
    private var searching: Bool {
        searchFocused || typing
    }

    private func endSearch() {
        Haptics.tap()
        searchFocused = false
        query = ""
    }

    private static let asksEdge = Color.black.opacity(0.05) // Gap: black 5%, the asking pill's edge, is unbound
    private static let asksShadow = Color.black.opacity(0.03) // Gap: black 3%, the asking pill's shadow, is unbound
    private static let searchShadow = Color.black.opacity(0.05) // Gap: black 5%, the search field's shadow, is unbound
    private static let footWash = Color(hex: 0xF3F6F3) // Gap: #F3F6F3, the wash under the pill, is unbound

    init(category: FundCategory, onOpen: @escaping (ListedFund) -> Void = { _ in }, onKind: @escaping (FundCategory) -> Void = { _ in },
         onBack: @escaping () -> Void = {}) {
        self.category = category
        self.onOpen = onOpen
        self.onKind = onKind
        self.onBack = onBack
        funds = category.funds
    }

    var body: some View {
        VStack(spacing: 0) {
            bar
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if typing {
                        // Gap: P5 on the 19 pt line this file gives it (the token's line is 21)
                        GapText(found, family: .walsheim, medium: false, size: 13, lineHeight: 19, color: ColorScale.contentTertiary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: 264)
                            .padding(.top, 23) // Gap: 23 under the bar while something is typed, no spacing token
                    } else {
                        // 79:12316: the category's drawing, 120 tall
                        Image(category.art)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 120)
                            .padding(.top, 19) // Gap: 19 under the bar, no spacing token
                            .accessibilityHidden(true)
                        // 79:12165. Gap: H2 (Reckless Regular 35) on the 43 pt line this file gives it (the token's line is 51)
                        GapText(category.title, family: .reckless, medium: false, size: 35, lineHeight: 43, color: ColorScale.contentPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: 239)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.top, 18) // Gap: 18 under the drawing, no spacing token
                        // 79:12166. Gap: P5 on the 19 pt line this file gives it (the token's line is 21)
                        GapText("Funds investing in \(category.invests), ranked by 3-year annualised returns", family: .walsheim, medium: false, size: 13, lineHeight: 19, color: ColorScale.contentTertiary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(width: 264)
                            .padding(.top, 8) // Gap: 8 under the title, no spacing token
                        asks
                            .padding(.top, 12) // Gap: 12 under the line, no spacing token
                        kinds
                            .padding(.top, SpacingScale.space3xl)
                    }
                    if !shown.isEmpty {
                        // 111:20976
                        FundColumns()
                            .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
                            .padding(.top, SpacingScale.spaceLg)
                        // 79:12036: the funds, in the widget card with its designed shadow
                        Surface(surface: .surfaceWidget, radius: .radius23) {
                            LazyVStack(spacing: 41) { // Gap: 41 between the rows, no spacing token
                                ForEach(shown) { fund in
                                    MutualFundRow(fund, decimals: 2, badge: fund.id == leader ? "Highest 3Y return" : nil) {
                                        searchFocused = false
                                        onOpen(fund)
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
                .frame(maxWidth: .infinity)
                // Room to scroll the last fund clear of the advisor's pill
                .padding(.bottom, SpacingScale.space10xl)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(ColorScale.surfaceBase.ignoresSafeArea())
        .overlay {
            // 13:5202: the page fades into a pale wash behind the pill, 125 up from the foot of the screen
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(colors: [Self.footWash.opacity(0), Self.footWash], startPoint: .top, endPoint: .bottom)
                    .frame(height: 125)
            }
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .leading) { backEdge }
        .offset(x: pulled)
        .preferredColorScheme(.light)
    }

    /// The category's first fund, where it has a three-year return to be first by
    private var leader: Int? {
        funds.first.flatMap { $0.threeYear == nil ? nil : $0.id }
    }

    /// How many of the category's funds match what is typed
    private var found: String {
        let typed = query.trimmingCharacters(in: .whitespaces)
        return shown.isEmpty
            ? "None of the \(funds.count) \(category.noun) match “\(typed)”."
            : "\(shown.count) of \(funds.count) \(category.noun) match “\(typed)”."
    }

    /// 111:22479: the pill that asks what the kind is, with its arrow. It does not respond yet.
    private var asks: some View {
        Surface(surface: .surfaceBase, shape: .capsule, shadow: .none) {
            HStack(spacing: 11) { // Gap: 11 from the question to the arrow, no spacing token
                // Gap: P3 on the 23 pt line this file gives it (the token's line is 25)
                GapText("What are \(category.asks)?", family: .walsheim, medium: false, size: 17, lineHeight: 23, color: ColorScale.contentPrimary)
                    .fixedSize()
                Image("MFCatAsk")
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, SpacingScale.spaceLg)
            .padding(.vertical, SpacingScale.spaceMdLg)
        }
        .overlay(Capsule().strokeBorder(Self.asksEdge, lineWidth: 2)) // Gap: a 2 pt edge, not the hairline
        .shadow(color: Self.asksShadow, radius: 15, x: 0, y: 3) // Gap: 0 3 30 at 3%, not a Shadow style. ds-lint-ignore: no_raw_shadow
        .accessibilityElement(children: .combine)
    }

    /// 111:20981: the kinds of fund, running off the trailing edge; a tap brings that kind's page in this one's
    /// place. The last is written as the frame writes it.
    private var kinds: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Stack(direction: .horizontal, gap: .spaceMd) {
                ForEach(MutualFundsHomeV2View.kinds, id: \.title) { kind in
                    FundKindChip(title: kind.title == "Technology" ? "Technologi" : kind.title, orb: kind.orb)
                        .onTapGesture {
                            if let other = FundCategory.named(kind.title), other.id != category.id { onKind(other) }
                        }
                        .accessibilityLabel(kind.title)
                }
            }
            .padding(.horizontal, 17) // Gap: 17 from the screen's edges, no spacing token
        }
        .scrollClipDisabled()
    }

    // MARK: Bar

    /// 13:5405: the back button and the search field, which stay at the top as the page scrolls under them. While
    /// search is in use the button is gone and the field runs the width of the page, with a cross at its
    /// trailing end that cancels the search and brings the whole page back.
    private var bar: some View {
        HStack(spacing: SpacingScale.spaceXs) {
            if !searching {
                Button {
                    Haptics.tap()
                    onBack()
                } label: {
                    // 13:5406: the drawing carries its own soft shadow, 262 × 261 around its 54 × 53
                    Image("MFCatBack")
                        .resizable()
                        .frame(width: 262, height: 261)
                        .offset(y: 4)
                        .frame(width: 54, height: 53)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
            // 13:5408: the search field, 57 tall
            FundSearchField(prompt: "SEARCH", size: 17, text: $query, focused: $searchFocused, active: searching, onCancel: endSearch)
            .padding(.leading, 17) // Gap: 17 inside the field, no spacing token
            .padding(.trailing, SpacingScale.spaceXs)
            .frame(height: 57)
            // A tap anywhere in the field is a tap on what is typed
            .contentShape(Rectangle())
            .onTapGesture { searchFocused = true }
            .background {
                RoundedRectangle(cornerRadius: RadiusToken.radius27.value, style: .continuous)
                    .fill(ColorScale.surfaceWidget)
                    .shadow(color: Self.searchShadow, radius: 25, x: 0, y: 4) // Gap: 0 4 50 at 5%, half Shadow/1's blur. ds-lint-ignore: no_raw_shadow
            }
        }
        .padding(.leading, searching ? SpacingScale.spaceMdLg : 11) // Gap: 11 from the screen's edge, no spacing token
        .padding(.trailing, SpacingScale.spaceMdLg)
        .frame(height: 63)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: searching)
        // The frame's bar has no ground of its own; here it has the page's, so the funds pass out of sight under it
        .background(ColorScale.surfaceBase)
        .zIndex(1)
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
            // The back button is the way back for assistive technologies
            .accessibilityHidden(true)
            .padding(.top, 63) // Gap: clear of the 63 pt bar, whose back button sits at this edge; no spacing token
    }
}

#Preview {
    MutualFundCategoryView(category: .performingSmallCap)
}
