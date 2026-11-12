import SwiftUI

/// Figma "iPhone 14 Plus - 457" (644:18888): the fixed deposits page. A back / title / search bar, the
/// "All · Your deposits" switch, what fixed deposits give you, the deposits to browse, and questions to ask the
/// advisor. A tap on a deposit pushes its bank's page. It is the default; `-fdListV1` opens the earlier list
/// (`FixedDepositsView`).
struct FixedDepositsHomeView: View {
    var onBack: () -> Void = {}

    /// The bank whose page is pushed over this one
    @State private var openedBank: FixedDepositsView.Deposit?
    private static let push = Animation.spring(response: 0.45, dampingFraction: 0.92)

    // Search: pull the page down past the threshold and let go, or tap the glass. It finds a bank, which opens
    // its page, or an intent ("Short term"), which narrows the deposits to browse.
    @State private var searching = false
    @State private var pull: CGFloat = 0
    @State private var pastThreshold = false
    @State private var intent: Intent?

    /// What someone might be after, in place of a bank's name
    enum Intent: String, CaseIterable {
        case shortTerm = "Short term", longTerm = "Long term", highest = "Highest returns"
        case instant = "Instant withdrawal", safest = "AAA rated", banks = "Small finance banks", nbfc = "NBFC’s"

        var detail: String {
            switch self {
            case .shortTerm: "Best 1 year rates"
            case .longTerm: "Best 5 year rates"
            case .highest: "Top rates on any tenure"
            case .instant: "Withdraw anytime"
            case .safest: "Highest safety rating"
            case .banks: "Insured up to ₹5L"
            case .nbfc: "Finance companies"
            }
        }

        var icon: String {
            switch self {
            case .shortTerm: "hourglass"
            case .longTerm: "calendar"
            case .highest: "chart.line.uptrend.xyaxis"
            case .instant: "bolt"
            case .safest: "shield"
            case .banks: "building.columns"
            case .nbfc: "briefcase"
            }
        }

        var keywords: String {
            switch self {
            case .shortTerm: "short term 1 year 12 months quick"
            case .longTerm: "long term 5 years retirement"
            case .highest: "best high top returns interest rate"
            case .instant: "liquid withdraw anytime premature break"
            case .safest: "safe safest secure crisil aaa rating"
            case .banks: "sfb bank insured dicgc"
            case .nbfc: "nbfc company housing finance"
            }
        }

        /// The deposits that answer it, best first, each with the rate that matters for it
        var deposits: [(FixedDepositsView.Deposit, Double)] {
            let all = FixedDepositsView.deposits
            func ranked(_ rate: (FixedDepositsView.Deposit) -> Double?) -> [(FixedDepositsView.Deposit, Double)] {
                all.compactMap { deposit in rate(deposit).map { (deposit, $0) } }.sorted { $0.1 > $1.1 }
            }
            switch self {
            case .shortTerm: return Array(ranked { $0.rate(for: .oneYear) }.prefix(5))
            case .longTerm: return Array(ranked { $0.rate(for: .fiveYears) }.prefix(5))
            case .highest: return Array(ranked { $0.best }.prefix(5))
            case .instant, .banks: return ranked { $0.kind == .smallFinance ? $0.best : nil }
            case .nbfc: return ranked { $0.kind != .smallFinance ? $0.best : nil }
            case .safest: return ranked { $0.ratingShort.hasSuffix("AAA") ? $0.best : nil }
            }
        }
    }

    /// Intents first, then every bank
    private static let searchItems: [QuickSearchOverlay.Item] =
        Intent.allCases.map { QuickSearchOverlay.Item(icon: $0.icon, title: $0.rawValue, detail: $0.detail, keywords: $0.keywords) }
        + FixedDepositsView.deposits.map {
            QuickSearchOverlay.Item(image: $0.logo, title: $0.name, detail: $0.kind.rawValue, keywords: $0.ratingShort)
        }

    private func openSearch() {
        guard !searching, openedBank == nil else { return }
        Haptics.lift()
        searching = true
    }

    private func pick(_ item: QuickSearchOverlay.Item) {
        if let chosen = Intent(rawValue: item.title) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { intent = chosen }
        } else if let deposit = FixedDepositsView.deposits.first(where: { $0.name == item.title }) {
            openBank(deposit)
        }
    }

    /// The four deposits drawn in the frame
    static let browse: [FixedDepositsView.Deposit] = ["Bajaj Finance", "Suryoday SF Bank", "Jana SF Bank", "AU SF Bank"]
        .compactMap { name in FixedDepositsView.deposits.first { $0.name == name } }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                switcher
                    .padding(.horizontal, SpacingScale.spaceLg)
                    .padding(.top, SpacingScale.spaceLg)
                advisoryCard
                    .padding(.horizontal, 11) // Gap: the card sits 11 from the screen edge, no spacing token
                    .padding(.top, SpacingScale.space3xl)
                DsText("Fixed deposits", variant: .h3)
                    .padding(.leading, SpacingScale.spaceXl)
                    .padding(.top, 56) // Gap: 56 above the title, no spacing token
                benefits
                    .padding(.horizontal, 11) // Gap: the card sits 11 from the screen edge, no spacing token
                    .padding(.top, SpacingScale.spaceLg)
                browseTitle
                    .padding(.leading, SpacingScale.spaceXl)
                    .padding(.trailing, SpacingScale.spaceMd)
                    .padding(.top, 56) // Gap: 56 above the section title, no spacing token
                cards(slot: 0, intent?.deposits.map { ($0.0, FixedDepositsView.percent($0.1)) })
                    .padding(.top, 33) // Gap: 33 under the section title, no spacing token
                DsText("Ask your advisor", variant: .h3)
                    .padding(.leading, SpacingScale.spaceXl)
                    .padding(.top, SpacingScale.space5xl)
                questions
                    .padding(.horizontal, SpacingScale.spaceSm)
                    .padding(.top, SpacingScale.space3xl)
                if intent == nil {
                    cards(slot: 1, nil)
                        .padding(.top, 56) // Gap: 56 above the second run of cards, no spacing token
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Room to scroll the last card clear of the advisor pill
            .padding(.bottom, SpacingScale.space10xl)
            // While pulling for search, the content eases back a touch
            .scaleEffect(1 - 0.06 * min(1, pull / QuickSearchOverlay.threshold), anchor: .top)
        }
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, offset in
            pull = max(0, -offset)
            let past = pull > QuickSearchOverlay.threshold
            if past != pastThreshold {
                pastThreshold = past
                if past { Haptics.thresholdCrossed() }
            }
        }
        .onScrollPhaseChange { old, new in
            // Letting go past the threshold opens search
            if old == .interacting, new != .interacting, pastThreshold { openSearch() }
        }
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .background(ColorScale.surfaceBase.ignoresSafeArea())
        .allowsHitTesting(!searching)
        .overlay {
            if searching {
                QuickSearchOverlay(placeholder: "Search banks, short term, safest", items: Self.searchItems, onPick: pick) { searching = false }
                    .ignoresSafeArea(.container)
            }
        }
        // The advisor pill steps aside for search
        .preference(key: AdvisorBarHiddenKey.self, value: searching)
        .accessibilityHidden(openedBank != nil)
        // The advisor stays at the foot of the page, as on the fund page
        .advisorBar()
        .overlay {
            // iOS push: the bank's page comes in from the trailing edge, over this one
            ZStack {
                if let openedBank {
                    let close = { withAnimation(Self.push) { self.openedBank = nil } }
                    Group {
                        if ProcessInfo.processInfo.arguments.contains("-fdBankV1") {
                            FixedDepositBankView(deposit: openedBank, onBack: close)
                        } else {
                            FixedDepositBankV2View(deposit: openedBank, onBack: close)
                        }
                    }
                    .advisorBar()
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private func openBank(_ deposit: FixedDepositsView.Deposit) {
        Haptics.tap()
        withAnimation(Self.push) { openedBank = deposit }
    }

    // MARK: Bar

    private var header: some View {
        ZStack {
            // Gap: Rg 19/25 in black has no text style or content token
            GapText("Fixed deposits", family: .walsheim, medium: false, size: 19, lineHeight: 25, color: Color.black) // Gap: unbound black
            HStack(spacing: 0) {
                Button {
                    Haptics.tap()
                    onBack()
                } label: {
                    Surface(surface: .surfaceWidget, shape: .capsule, shadow: .token(.shadow2)) {
                        Image("FDHomeBack").frame(width: 39, height: 39)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                Spacer(minLength: 0)
                Button(action: openSearch) {
                    Surface(surface: .surfaceWidget, shape: .capsule, shadow: .token(.shadow2)) {
                        Image("FDHomeSearch").frame(width: 39, height: 39)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search")
            }
            // The buttons are 39 across, 15 and 17 from the screen's edges; the back button's tap target is 44
            .padding(.leading, 12.5) // Gap: 15 to the button, no spacing token
            .padding(.trailing, 14.5) // Gap: 17 to the button, no spacing token
        }
        .frame(height: 63)
        .padding(.top, SpacingScale.spaceSm)
        .background(ColorScale.surfaceBase)
    }

    // MARK: All · Your deposits

    private var switcher: some View {
        Surface(surface: .surfaceSunken2, radius: .radius27, shadow: .none) {
            HStack(spacing: 0) {
                Surface(surface: .surfaceWidget, shape: .capsule, shadow: .none) {
                    DsText("All", variant: .p4, color: .contentPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 47)
                }
                // Gap: Rg 17/23 in black 67% has no content token
                GapText("Your deposits", family: .walsheim, medium: false, size: 17, lineHeight: 23, color: Color.black.opacity(0.67)) // Gap: unbound black 67%
                    .frame(maxWidth: .infinity)
            }
            .padding(3) // Gap: the chosen side sits 3 inside the track, no spacing token
        }
    }

    // MARK: Advisor

    /// Figma 679:22715: the advisor's note on a white panel under an amber header, over a tilted fund card
    /// that runs off the bottom edge
    private var advisoryCard: some View {
        let shape = RoundedRectangle(cornerRadius: RadiusToken.radius27.value, style: .continuous)
        return ZStack(alignment: .top) {
            // Gap: Reckless Condensed SemiBold 25/45 at 0.25 tracking in blue/900 has no text style or content token
            Text(verbatim: "DEPOSIT ADVICE") // ds-lint-ignore: no_raw_text
                .font(.custom("RecklessCondensedS-TRIAL-SemiBold", fixedSize: 25)) // ds-lint-ignore: no_hand_set_type
                .tracking(0.25) // ds-lint-ignore: no_hand_set_type
                .foregroundStyle(ColorPrimitives.blue900) // ds-lint-ignore: no_tier1
                .frame(height: 45)
                .padding(.top, 3) // Gap: 3 from the card's top, no spacing token

            // The white panel, 213 tall from 51 down
            ZStack(alignment: .top) {
                HStack(alignment: .top, spacing: 15) { // Gap: 15 between the face and the note, no spacing token
                    Image("FDAdvisorFace")
                        .resizable()
                        .frame(width: 53, height: 53)
                        .clipShape(Circle())
                        .padding(.top, 2.5) // Gap: the face sits 2.5 below the note's top
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) { // Gap: 2 between the lines, no spacing token
                        HStack(spacing: 0) {
                            // Gap: Rg 17/19 in black has no text style
                            GapText("From your ", family: .walsheim, medium: false, size: 17, lineHeight: 19, color: Color.black) // Gap: unbound black
                            Spacer(minLength: 0)
                            // Gap: SF Pro Regular 15/17 in #E0E0E2 has no text style or content token
                            Text(verbatim: "9:14 AM") // ds-lint-ignore: no_raw_text
                                .font(.system(size: 15)) // ds-lint-ignore: no_hand_set_type
                                .foregroundStyle(Color(hex: 0xE0E0E2)) // Gap: unbound #E0E0E2
                                .frame(height: 17)
                        }
                        // Gap: Rg 15/21 in #8C8C8C has no text style or content token
                        GapText("Have you heard of Calathea? It’s a patterned tropical houseplant…", family: .walsheim, medium: false, size: 15, lineHeight: 21, color: Color(hex: 0x8C8C8C)) // Gap: unbound #8C8C8C
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.leading, SpacingScale.spaceLg)
                .padding(.trailing, 28) // Gap: 28 from the panel's side, no spacing token
                .padding(.top, 13) // Gap: 13 from the panel's top, no spacing token

                fundCard
                    .rotationEffect(.degrees(4.7))
                    .padding(.top, 116) // Gap: the tilted card's box starts 104 down the panel and is 12 taller than the card
            }
            .frame(maxWidth: .infinity)
            .frame(height: 213, alignment: .top)
            .background(ColorScale.surfaceWidget)
            .clipShape(shape)
            .padding(.top, 51) // Gap: the panel starts 51 down, no spacing token
        }
        .frame(maxWidth: .infinity)
        .frame(height: 264, alignment: .top)
        .background(Color(hex: 0xFEC568)) // Gap: unbound #FEC568
        .clipShape(shape)
        .shadow(color: Color.black.opacity(0.07), radius: 28.5, x: 0, y: 2) // Gap: 0 2 57 spread 5 at 7%, not a Shadow style; the spread is not drawn. ds-lint-ignore: no_raw_shadow
        .accessibilityElement(children: .combine)
    }

    /// The 300 × 191.6 fund card inside the advisory view
    private var fundCard: some View {
        let ink = Color.black // Gap: unbound black, used at 93%, 43% and 7%
        return ZStack(alignment: .topLeading) {
            // Gap: Rg 13.859/20.38 in black 93% has no text style or content token
            GapText("Fund performance", family: .walsheim, medium: false, size: 13.859, lineHeight: 20.38, color: ink.opacity(0.93))
                .offset(x: 13.86, y: 12.23)
            GapText("Doing great", family: .walsheim, medium: false, size: 13.859, lineHeight: 20.38, color: ink.opacity(0.93))
                .frame(width: 270.47, alignment: .trailing)
                .offset(y: 12.23)
            Rectangle().fill(ink.opacity(0.07))
                .frame(width: 300, height: 1.63)
                .offset(y: 44.84 - 1.63)
            // Four bars standing on one line, 93.75 down
            ForEach(Array([13.043, 15.489, 20.38, 29.348].enumerated()), id: \.offset) { index, height in
                Capsule().fill(Color(hex: 0x3FD519)) // Gap: unbound #3FD519
                    .frame(width: 5.707, height: height)
                    .offset(x: 17.12 + 9.783 * Double(index), y: 93.746 - height)
            }
            // Gap: Md 13.859/20.38 in black has no text style
            GapText("Steady growth over years", family: .walsheim, medium: true, size: 13.859, lineHeight: 20.38, color: ink)
                .offset(x: 92.12, y: 58.69)
            // Gap: Rg 12.228/18.75 in black 43% has no text style or content token
            GapText("NAV re-invested", family: .walsheim, medium: false, size: 12.228, lineHeight: 18.75, color: ink.opacity(0.43))
                .offset(x: 92.12, y: 81.52)
        }
        .frame(width: 300, height: 191.576, alignment: .topLeading)
        .background(Color(hex: 0xFBF6F0)) // Gap: unbound #FBF6F0
        .clipShape(RoundedRectangle(cornerRadius: 18.75, style: .continuous)) // Gap: 18.75 radius, no radius token
    }

    // MARK: Create your plan

    /// Not shown for now: the advisory view card takes its place.
    /// Figma 665:20272: the reader over "Create your fixed deposit plan" and "Lets start"
    private var planCard: some View {
        Surface(surface: .surfaceWidget, radius: .radius27, border: .borderSubtle, shadow: .token(.shadow2)) {
            VStack(alignment: .leading, spacing: 0) {
                // The picture, 380 × 474 on the 368 card, showing its 200 from 161 down
                Color.clear
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .top) {
                        GeometryReader { geo in
                            let scale = geo.size.width / 368
                            Image("FDPlanHero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 380 * scale, height: 474 * scale)
                                .offset(x: -6 * scale, y: -161 * scale)
                        }
                    }
                    .clipped()
                    .accessibilityHidden(true)
                // Gap: Reckless Medium 35/39 in #212121 has no text style or content token
                GapText("Create your fixed deposit plan", family: .reckless, medium: true, size: 35, lineHeight: 39, color: Color(hex: 0x212121)) // Gap: unbound #212121
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 340, alignment: .leading)
                    .padding(.top, 20) // Gap: 20 under the picture, no spacing token
                    .padding(.leading, SpacingScale.spaceXl)
                Button { Haptics.tap() } label: {
                    // Gap: Md 17/23 in #212121 has no content token
                    GapText("Lets start", family: .walsheim, medium: true, size: 17, lineHeight: 23, color: Color(hex: 0x212121)) // Gap: unbound #212121
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(Capsule().fill(ColorScale.surfaceWidget))
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.25), lineWidth: 1)) // Gap: 1pt black 25%, unbound
                        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3) // Gap: 0 3 30 at 3%, not a Shadow style. ds-lint-ignore: no_raw_shadow
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 17) // Gap: 17 beside the button, no spacing token
                .padding(.top, 37) // Gap: 37 above the button, no spacing token
                .padding(.bottom, 22) // Gap: 22 under the button, no spacing token
            }
        }
    }

    // MARK: What a fixed deposit gives you

    private var benefits: some View {
        Surface(surface: .surfaceWidget, radius: .radius23, shadow: .token(.shadow2)) {
            VStack(spacing: 0) {
                benefit(icon: "FDHomeReturns", title: "High returns")
                Hairline(.borderSubtle)
                benefit(icon: "FDHomePayouts", title: "Monthly payouts")
                Hairline(.borderSubtle)
                benefit(icon: "FDHomeWithdraw", title: "Instant withdrawals")
            }
        }
    }

    private func benefit(icon: String, title: String) -> some View {
        HStack(spacing: SpacingScale.spaceMdLg) {
            Image(icon).frame(width: 29, height: 29)
            VStack(alignment: .leading, spacing: 3) { // Gap: 3 between the lines, no spacing token
                DsText(title, variant: .p3)
                // Gap: Rg 13 at 120% has no text style
                GapText("Up to 8.30% a year", family: .walsheim, medium: false, size: 13, lineHeight: 15.6, color: ColorScale.contentTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 23) // Gap: 23 beside the icon, no spacing token
        .frame(height: 76)
    }

    // MARK: Deposits

    /// The four deposits; the frame draws them twice, either side of the advisor's questions
    private func cards(slot: Int, _ found: [(FixedDepositsView.Deposit, String)]?) -> some View {
        // The four drawn, at the rate drawn; or what an intent found, each at the rate that matters for it
        let shown = found ?? Self.browse.map { ($0, "8.5%") }
        return VStack(spacing: 23) { // Gap: 23 between cards, no spacing token
            ForEach(shown, id: \.0.id) { deposit, rate in
                FDHomeCard(deposit: deposit, rate: rate)
                    .contentShape(Rectangle())
                    .onTapGesture { openBank(deposit) }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .askable(.fdCard(deposit.name, slot))
            }
        }
        .padding(.horizontal, SpacingScale.spaceSm)
    }

    /// "Browse all fixed deposits"; or the intent searched for, with a cross to go back to all of them
    @ViewBuilder private var browseTitle: some View {
        if let intent {
            HStack(spacing: SpacingScale.spaceMd) {
                DsText(intent.rawValue, variant: .h4)
                Spacer(minLength: 0)
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { self.intent = nil }
                } label: {
                    Surface(surface: .surfaceSunken2, shape: .capsule, shadow: .none) {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 11, height: 11)
                            .foregroundStyle(ColorScale.contentSecondary)
                            .frame(width: 29, height: 29)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
            .frame(height: 29)
        } else {
            DsText("Browse all fixed deposits", variant: .h4)
        }
    }

    // MARK: Ask your advisor

    /// Each tile's wash, left to right. Gap: the fills are unbound gradients, read off the frame
    private static let washes: [[Gradient.Stop]] = [
        [.init(color: Color(hex: 0xFFD24F), location: 0), .init(color: Color(hex: 0xFCCB9F), location: 1)], // Gap: unbound gradient
        [.init(color: Color(hex: 0xD6C3BD), location: 0), .init(color: Color(hex: 0xC2C3D5), location: 0.5), .init(color: Color(hex: 0xC1C6D8), location: 1)], // Gap: unbound gradient
        [.init(color: Color(hex: 0xD9D6C1), location: 0), .init(color: Color(hex: 0xC5DBD3), location: 0.35), .init(color: Color(hex: 0xC4D1B9), location: 1)], // Gap: unbound gradient
        [.init(color: Color(hex: 0xE8DAAE), location: 0), .init(color: Color(hex: 0xDCD4C7), location: 0.7), .init(color: Color(hex: 0xDACBCD), location: 1)], // Gap: unbound gradient
    ]

    private var questions: some View {
        VStack(spacing: SpacingScale.spaceMdLg) {
            ForEach(0..<2, id: \.self) { row in
                HStack(spacing: 11) { // Gap: 11 between tiles, no spacing token
                    question(Self.washes[row * 2])
                    question(Self.washes[row * 2 + 1])
                }
            }
        }
    }

    private func question(_ wash: [Gradient.Stop]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gap: Rg 15/19 in black 61% has no text style or content token
            GapText("Mutual funds market", family: .walsheim, medium: false, size: 15, lineHeight: 19, color: Color.black.opacity(0.61)) // Gap: unbound black 61%
                .fixedSize()
            Spacer(minLength: 0)
            // Gap: Rg 17/21 in black has no text style or content token
            GapText("How mutual funds performed in the last 6 months?", family: .walsheim, medium: false, size: 17, lineHeight: 21, color: Color.black) // Gap: unbound black
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, SpacingScale.spaceLg)
        .padding(.top, SpacingScale.spaceMdLg)
        .padding(.bottom, 19) // Gap: 19 under the question, no spacing token
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 192)
        .background(LinearGradient(stops: wash, startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: RadiusToken.radius27.value, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 28.5, x: 0, y: 2) // Gap: 0 2 57 +5 at 7%, not a Shadow style. ds-lint-ignore: no_raw_shadow
    }
}

/// One deposit on the fixed deposits page: who, a badge and the rate, then how safe it is
struct FDHomeCard: View {
    let deposit: FixedDepositsView.Deposit
    /// 8.5% as the frame draws every card; a search by intent passes the rate it ranked on
    var rate = "8.5%"

    private var isBank: Bool { deposit.kind == .smallFinance }

    /// The agency and grade of a rated issuer (the frame's cards are all CRISIL AAA)
    private var rated: (agency: String, grade: String) {
        if case .agency(let agency, let grade) = deposit.rating { return (agency, grade) }
        return ("CRISIL", "AAA")
    }

    private var note: String {
        guard !isBank, rated.grade != "AAA" else { return "AAA means the highest degree of safety for timely repayment of interest and principal." }
        return "\(rated.grade) means \(rated.grade.hasPrefix("AA") ? "a high" : "an adequate") degree of safety for timely repayment of interest and principal."
    }

    var body: some View {
        Surface(surface: .surfaceWidget, radius: .radius23, shadow: .none) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    Surface(surface: .surfaceSunken1, radius: .radius15, shadow: .none) {
                        Image(deposit.logo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 37, height: 37)
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous)) // Gap: 5 is not a radius token
                            .frame(width: 51, height: 51)
                    }
                    .padding(.top, 19) // Gap: 19 above the logo, no spacing token
                    VStack(alignment: .leading, spacing: 3) { // Gap: 3 between the name and its badge, no spacing token
                        // Gap: Md 19/25 in black 83% has no content token
                        GapText(deposit.name, family: .walsheim, medium: true, size: 19, lineHeight: 25, color: Color.black.opacity(0.83)) // Gap: unbound black 83%
                            .fixedSize()
                        badge
                    }
                    .padding(.leading, SpacingScale.spaceMdLg)
                    .padding(.top, 20) // Gap: 20 above the name, no spacing token
                    Spacer(minLength: 0)
                    // Gap: Md 21/31 in #01B405 has no text style or content token
                    GapText(rate, family: .walsheim, medium: true, size: 21, lineHeight: 31, color: Color(hex: 0x01B405)) // Gap: unbound #01B405
                        .fixedSize()
                        .padding(.top, 22) // Gap: 22 above the rate, no spacing token
                }
                .padding(.leading, 19) // Gap: 19 beside the logo, no spacing token
                .padding(.trailing, SpacingScale.spaceXl)
                .frame(height: 95, alignment: .top)

                Hairline(.borderSubtle)

                ZStack(alignment: .topLeading) {
                    // Gap: Rg 17/22 in black 51% has no text style or content token
                    GapText(isBank ? "RBI Licensed Small finance bank" : "\(rated.agency) Rating", family: .walsheim, medium: false, size: 17, lineHeight: 22, color: Color.black.opacity(0.51)) // Gap: unbound black 51%
                        .fixedSize()
                    if !isBank {
                        // Gap: Md 19.23/27.1 at 7% tracking in #007DE4 has no text style or content token
                        GapText(rated.grade, family: .walsheim, medium: true, size: 19.23, lineHeight: 27.096, trackingPercent: 7, color: Color(hex: 0x007DE4)) // Gap: unbound #007DE4
                            .fixedSize()
                            // 137 along from the label's leading edge, 3 above its top
                            .offset(x: 137, y: -3)
                    }
                }
                .padding(.top, 22) // Gap: 22 under the rule, no spacing token
                .padding(.leading, 23) // Gap: 23 beside the label, no spacing token

                // Gap: Rg 13/18 in black 50% has no text style or content token
                GapText(note, family: .walsheim, medium: false, size: 13, lineHeight: 18, color: Color.black.opacity(0.5)) // Gap: unbound black 50%
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, SpacingScale.spaceSm)
                    .padding(.leading, 23) // Gap: 23 beside the note, no spacing token
                    .padding(.trailing, 16) // Gap: 16 beside the note, no spacing token
                    .padding(.bottom, 27) // Gap: 27 under the note, no spacing token
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 25, x: 0, y: 4) // Gap: 0 4 50 at 5%, not a Shadow style. ds-lint-ignore: no_raw_shadow
    }

    /// "TOP RATES" on the finance companies, "INSTANT WITHDRAWAL" on the banks
    private var badge: some View {
        HStack(spacing: 3) { // Gap: 3 between the picture and the label, no spacing token
            Image(isBank ? "FDBadgeInstant" : "FDBadgeTopRates")
                .resizable()
                .frame(width: 19, height: 19)
            // Gap: Rg 13/21 at 7% tracking in black 56% has no text style or content token
            GapText(isBank ? "INSTANT WITHDRAWAL" : "TOP RATES", family: .walsheim, medium: false, size: 13, lineHeight: 21, trackingPercent: 7, color: Color.black.opacity(0.56)) // Gap: unbound black 56%
                .fixedSize()
        }
        .padding(.horizontal, 3) // Gap: 3 inside the badge, no spacing token
        .padding(.vertical, 1) // Gap: 1 inside the badge, no spacing token
        .background(ColorScale.statusWarningSubtle)
    }
}

#Preview {
    FixedDepositsHomeView()
}
