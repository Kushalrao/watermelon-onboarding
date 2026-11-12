import SwiftUI

/// Figma "iPhone 14 Plus - 341" (213:10609): the fixed deposits on offer. A back / grid / search bar, the title, a
/// row of filters (All, NBFC's, Small Finance Banks) that narrows the list, then a card per issuer with its rate,
/// CRISIL rating and lock-in. "Compare returns" floats over the bottom of the list. `-fd` opens on it.
///
/// Compare returns opens a sheet for the amount and tenure, the page stepping back behind it. Calculating sends it
/// back down and the list comes forward with each deposit's maturity value (213:10918), and the floating button
/// becomes a bar holding the amount, which reopens the sheet, and the tenure, which changes the returns in place.
struct FixedDepositsView: View {
    var onBack: () -> Void = {}

    @State private var filter = Filter.all
    /// How many of the cards have come in, for their arrival
    @State private var shown = 0
    @Namespace private var pill

    /// The amount to compare on, once calculated
    @State private var amount: Int?
    @State private var tenure = Tenure.oneYear
    /// The compare sheet is up, and the page stepped back behind it
    @State private var sheetUp = false
    /// The bank whose page is pushed over the list
    @State private var openedBank: Deposit?

    // Hold a card to lift it out with questions; swipe it right to ask about it
    @State private var heldWidget: HeldWidget?
    @State private var holdProgress: CGFloat = 0
    @State private var holdChipsOut = false
    @State private var isComposing = false
    @State private var composeProgress: CGFloat = 0
    @State private var composerText = ""
    @State private var composerContext: FundContext?
    @FocusState private var composerFocused: Bool
    @StateObject private var keyboard = KeyboardObserver()

    /// The tenures every issuer's rates are given for (NBFC deposits start at 12 months)
    enum Tenure: String, CaseIterable {
        case oneYear = "1Y", twoYears = "2Y", threeYears = "3Y", fiveYears = "5Y"
        var years: Double {
            switch self {
            case .oneYear: 1
            case .twoYears: 2
            case .threeYears: 3
            case .fiveYears: 5
            }
        }
        /// "1 yr", for the card's rates row
        var label: String { "\(Int(years)) yr" }
    }

    /// "7.85%", "7.00%": two places, as rate cards quote them
    static func percent(_ value: Double) -> String { String(format: "%.2f%%", value) }

    /// What a deposit pays back at maturity, compounded quarterly
    static func maturity(of amount: Int, rate: Double, over tenure: Tenure) -> Int {
        let quarters = tenure.years * 4
        return Int((Double(amount) * pow(1 + rate / 100 / 4, quarters)).rounded())
    }

    /// "Rs1,50,000": rupees, grouped the Indian way
    static func rupees(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return "Rs" + (formatter.string(from: NSNumber(value: value)) ?? "\(value)")
    }

    enum Filter: String, CaseIterable {
        case all = "All", nbfc = "NBFC’s", smallFinance = "Small Finance Banks"
    }

    /// One issuer's deposit: real cumulative rates for general depositors under ₹3 crore, from each issuer's own
    /// rate card (Oct–Nov 2026) where it could be read, else the most recent aggregator listing
    struct Deposit: Identifiable {
        let name: String, logo: String, kind: Kind
        /// % p.a. for 1, 2, 3 and 5 years; nil where it isn't offered
        let rates: [Double?]
        let rating: Rating
        var id: String { name }

        enum Kind: String { case nbfc = "NBFC", housing = "Housing Finance", smallFinance = "Small Finance Bank" }

        enum Rating {
            /// Agency and grade, e.g. CRISIL AAA
            case agency(String, String)
            /// Bank deposits: DICGC insured up to ₹5 lakh
            case insured
        }

        func rate(for tenure: Tenure) -> Double? { rates[Tenure.allCases.firstIndex(of: tenure)!] }
        /// Its best rate across the tenures
        var best: Double { rates.compactMap { $0 }.max() ?? 0 }
        var rate: String { FixedDepositsView.percent(best) }
        /// NBFC and housing finance deposits can't be withdrawn in their first three months (RBI); banks' can,
        /// with a penalty
        var lockIn: String { kind == .smallFinance ? "None" : "3M" }
        var ratingShort: String {
            switch rating {
            case .agency(let agency, let grade): "\(agency) \(grade)"
            case .insured: "DICGC insured"
            }
        }
    }

    static let deposits: [Deposit] = [
        // NBFCs and housing finance companies, as in 177:8618
        Deposit(name: "Shriram Finance", logo: "FDShriram", kind: .nbfc,
                rates: [7.00, 7.50, 7.85, 7.85], rating: .agency("CRISIL", "AAA")),
        Deposit(name: "Mahindra Finance", logo: "FDMahindra", kind: .nbfc,
                rates: [6.85, 7.05, 7.80, 7.45], rating: .agency("CRISIL", "AAA")),
        Deposit(name: "Bajaj Finance", logo: "FDBajaj", kind: .nbfc,
                rates: [6.80, 7.00, 7.75, 7.75], rating: .agency("CRISIL", "AAA")),
        Deposit(name: "Sundaram Finance", logo: "FDSundaram", kind: .nbfc,
                rates: [7.00, 7.25, 7.50, nil], rating: .agency("CRISIL", "AAA")),
        Deposit(name: "LIC Housing Finance", logo: "FDLICHousing", kind: .housing,
                rates: [6.70, 6.95, 7.20, 7.35], rating: .agency("CRISIL", "AAA")),
        Deposit(name: "PNB Housing Finance", logo: "FDPNBHousing", kind: .housing,
                rates: [6.80, 7.00, 7.25, 7.40], rating: .agency("CRISIL", "AA+")),
        Deposit(name: "ICICI Home Finance", logo: "FDICICIHome", kind: .housing,
                rates: [7.05, 7.10, 7.20, 7.30], rating: .agency("CRISIL", "AAA")),
        // Muthoot Finance doesn't take deposits; Muthoot Capital is the group's deposit-taking company
        Deposit(name: "Muthoot Capital", logo: "FDMuthoot", kind: .nbfc,
                rates: [7.90, 8.65, 8.95, 8.50], rating: .agency("CRISIL", "AA-")),
        Deposit(name: "Manipal Housing Finance", logo: "FDManipal", kind: .housing,
                rates: [8.25, 8.25, 8.25, 7.75], rating: .agency("ACUITE", "A")),
        // Small finance banks, as in 177:8734
        Deposit(name: "Suryoday SF Bank", logo: "FDSuryoday", kind: .smallFinance,
                rates: [7.25, 7.25, 7.25, 8.25], rating: .insured),
        Deposit(name: "Unity SF Bank", logo: "FDUnity", kind: .smallFinance,
                rates: [7.50, 6.75, 6.75, 6.75], rating: .insured),
        Deposit(name: "Jana SF Bank", logo: "FDJana", kind: .smallFinance,
                rates: [7.00, 7.30, 8.00, 7.77], rating: .insured),
        Deposit(name: "Ujjivan SF Bank", logo: "FDUjjivan", kind: .smallFinance,
                rates: [7.25, 7.55, 7.25, 7.20], rating: .insured),
        Deposit(name: "Utkarsh SF Bank", logo: "FDLICHousing", kind: .smallFinance,
                rates: [6.00, 7.50, 7.50, 7.00], rating: .insured),
        Deposit(name: "AU SF Bank", logo: "FDAU", kind: .smallFinance,
                rates: [6.35, 7.00, 7.40, 6.75], rating: .insured),
    ]

    private var visible: [Deposit] {
        switch filter {
        case .all: Self.deposits
        case .nbfc: Self.deposits.filter { $0.kind != .smallFinance }
        case .smallFinance: Self.deposits.filter { $0.kind == .smallFinance }
        }
    }

    /// The home indicator's height, so the page can run under it while the floating bar sits above it
    @State private var bottomInset: CGFloat = 34

    var body: some View {
        ZStack(alignment: .bottom) {
            page
                .accessibilityHidden(openedBank != nil)
                // To the screen's foot, so its backdrop isn't cut short above the home indicator
                .ignoresSafeArea(.container, edges: .bottom)
                // Steps back behind the sheet; a tap on it puts the sheet away
                // Rounded once stepped back; at rest the clip reaches past the screen's edges, so nothing is cut short
                .clipShape(RoundedRectangle(cornerRadius: RadiusToken.radius27.value, style: .continuous).inset(by: sheetUp ? 0 : -80))
                .scaleEffect(sheetUp ? 0.9 : 1, anchor: .top)
                .overlay {
                    if sheetUp {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { closeSheet() }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityLabel("Back to deposits")
                    }
                }

            if sheetUp {
                CompareReturnsSheet(amount: amount) { entered in
                    Haptics.settle()
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
                        amount = entered
                        sheetUp = false
                    }
                }
                .padding(.bottom, SpacingScale.spaceLg)
                .transition(.move(edge: .bottom).combined(with: .opacity.animation(.easeOut(duration: 0.2))))
                .zIndex(2)
            }
        }
        .overlay { askLayers }
        .overlay {
            // iOS push: the bank's page comes in from the trailing edge, over the list
            ZStack {
                if let openedBank {
                    let close = { withAnimation(.spring(response: 0.45, dampingFraction: 0.92)) { self.openedBank = nil } }
                    // The second version by default; `-fdBankV1` keeps the first
                    Group {
                        if ProcessInfo.processInfo.arguments.contains("-fdBankV1") {
                            FixedDepositBankView(deposit: openedBank, onBack: close)
                        } else {
                            FixedDepositBankV2View(deposit: openedBank, onBack: close)
                        }
                    }
                    // The advisor stays at the foot of the bank's page, as on the fund page
                    .advisorBar()
                    .transition(.move(edge: .trailing))
                }
            }
        }
                .background {
            // surfaceSunken2 shows round the page once it steps back; the page itself is surfaceBase
            (sheetUp ? ColorScale.surfaceSunken2 : ColorScale.surfaceBase)
                .ignoresSafeArea()
        }
        .background(GeometryReader { geo in
            Color.clear.onAppear { bottomInset = geo.safeAreaInsets.bottom }
        })
        .preferredColorScheme(.light)
        .task {
            for _ in Self.deposits {
                try? await Task.sleep(for: .seconds(0.07))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { shown += 1 }
            }
        }
    }

    /// The composer a swiped card rises into, over the keyboard, and the card a hold lifts out
    private var askLayers: some View {
        GeometryReader { geo in
            ZStack {
                let keyboardTop = geo.size.height - (keyboard.height > 0 ? keyboard.height : 336)
                ComposerLayer(
                    isFocused: $composerFocused,
                    text: $composerText,
                    viewport: geo.size,
                    keyboardHeight: keyboard.height,
                    isComposing: isComposing,
                    context: composerContext,
                    bottomAligned: true,
                    // its card 17pt above the keyboard
                    floatAbove: keyboardTop - 3,
                    onOpen: {},
                    onClose: closeComposer
                )
                HeldWidgetLayer(
                    frame: heldWidget?.frame,
                    questions: heldWidget?.context.questions ?? [],
                    progress: holdProgress,
                    chipsOut: holdChipsOut,
                    onDismiss: releaseWidget
                ) {
                    if let deposit = heldWidget?.context.deposit {
                        DepositCard(deposit: deposit, tenure: amount == nil ? nil : tenure, maturity: maturity(of: deposit))
                    }
                }
            }
            .modifier(AnimatedComposeProgress(progress: composeProgress))
        }
        .ignoresSafeArea()
        .onChange(of: composerFocused) { _, focused in
            // Keyboard put away some other way: fold the card back down
            if !focused && isComposing { closeComposer() }
        }
    }

    private func maturity(of deposit: Deposit) -> Int? {
        guard let amount, let rate = deposit.rate(for: tenure) else { return nil }
        return Self.maturity(of: amount, rate: rate, over: tenure)
    }

    private func holdCard(_ deposit: Deposit, frame: CGRect) {
        guard heldWidget == nil, !isComposing, !sheetUp else { return }
        Haptics.lift()
        heldWidget = HeldWidget(context: .deposit(deposit.name), frame: frame)
        holdProgress = 0
        holdChipsOut = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) { holdProgress = 1 }
        DispatchQueue.main.async { holdChipsOut = true }
    }

    private func releaseWidget() {
        guard heldWidget != nil else { return }
        Haptics.settle()
        holdChipsOut = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            holdProgress = 0
        } completion: {
            heldWidget = nil
        }
    }

    private func openComposer(with deposit: Deposit) {
        guard !isComposing, heldWidget == nil, !sheetUp else { return }
        Haptics.tap()
        composerContext = .deposit(deposit.name)
        isComposing = true
        composerFocused = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { composeProgress = 1 }
    }

    private func closeComposer() {
        guard isComposing else { return }
        Haptics.settle()
        isComposing = false
        composerFocused = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { composeProgress = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !isComposing { composerContext = nil; composerText = "" }
        }
    }

    private func openBank(_ deposit: Deposit) {
        guard heldWidget == nil, !isComposing, !sheetUp else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.92)) { openedBank = deposit }
    }

    private func openSheet() {
        Haptics.tap()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) { sheetUp = true }
    }

    private func closeSheet() {
        Haptics.tap()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) { sheetUp = false }
    }

    private var page: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                Stack(gap: .spaceXl) {
                    Stack(paddingHorizontal: .space2xl) {
                        DsText("Fixed Deposits", variant: .h1)
                    }

                    filters

                    Stack(gap: .spaceXl, paddingHorizontal: .space2xl) {
                        ForEach(Array(visible.enumerated()), id: \.element.id) { index, deposit in
                            DepositCard(deposit: deposit, tenure: amount == nil ? nil : tenure, maturity: maturity(of: deposit))
                                .contentShape(Rectangle())
                                .onTapGesture { openBank(deposit) }
                                .accessibilityAddTraits(.isButton)
                                .widgetHold(isHeld: heldWidget?.context == .deposit(deposit.name)) { holdCard(deposit, frame: $0) }
                                .contextSwipe { openComposer(with: deposit) }
                                .opacity(shown > index ? 1 : 0)
                                .offset(y: shown > index ? 0 : 16)
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        }
                    }
                    // Room to scroll the last card clear of "Compare returns"
                    .padding(.bottom, SpacingScale.space10xl)
                }
                .padding(.top, SpacingScale.spaceMd)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .safeAreaInset(edge: .top, spacing: 0) { header }

            Group {
                if let amount {
                    returnsBar(amount)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                } else {
                    compareButton
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .padding(.bottom, SpacingScale.spaceLg)
            .padding(.bottom, bottomInset)
            .opacity(shown > 0 ? 1 : 0)
            .offset(y: shown > 0 ? 0 : 30)
        }
        .background(ColorScale.surfaceBase)
    }

    /// The amount and tenure the returns are worked out on: the amount reopens the sheet, the tenure changes
    /// them in place, the cross goes back to the rates
    private func returnsBar(_ amount: Int) -> some View {
        Surface(surface: .surfaceRaised, shape: .capsule, shadow: .token(.shadow3)) {
            Stack(direction: .horizontal, gap: .spaceMd, paddingVertical: .spaceXs, alignment: .center) {
                Button(action: openSheet) {
                    Stack(direction: .horizontal, gap: .spaceXs, alignment: .center) {
                        DsText(Self.rupees(amount), variant: .n4)
                            .fixedSize()
                            .contentTransition(.numericText())
                        Image(systemName: "pencil")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13, height: 13)
                            .foregroundStyle(ColorScale.contentTertiary)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit amount")

                Hairline(.borderDefault, axis: .vertical)

                TenurePicker(tenure: $tenure)
                Spacer(minLength: 0)

                // Back to the rates, and "Compare returns"
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { self.amount = nil }
                } label: {
                    Surface(surface: .surfaceSunken2, shape: .capsule) {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 11, height: 11)
                            .foregroundStyle(ColorScale.contentSecondary)
                            .frame(width: 29, height: 29)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear amount")
            }
            .padding(.leading, SpacingScale.spaceXl)
            .padding(.trailing, SpacingScale.spaceXs)
            .frame(maxWidth: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, SpacingScale.spaceLg)
    }

    /// Back, then the grid and search
    private var header: some View {
        Stack(direction: .horizontal, gap: .spaceXl, paddingHorizontal: .space2xl, paddingVertical: .spaceMd, alignment: .center) {
            Button {
                Haptics.tap()
                onBack()
            } label: {
                Image("FDBack")
                    .frame(width: 10, height: 17)
                    // 44 × 44 to tap, the chevron at its leading edge so it sits on the page margin
                    .frame(width: 44, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer(minLength: 0)

            // The grid: five dots
            ZStack(alignment: .topLeading) {
                ForEach(Array([(3, 2), (3, 10), (10, 18), (17, 2), (17, 10)].enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(ColorScale.contentSecondary)
                        .frame(width: 5, height: 5)
                        .offset(x: CGFloat(p.0), y: CGFloat(p.1))
                }
            }
            .frame(width: 25, height: 25, alignment: .topLeading)

            Image("FDSearch")
                .frame(width: 27, height: 27)
        }
        .frame(maxWidth: .infinity)
        .background(ColorScale.surfaceBase)
    }

    /// All, NBFC's, Small Finance Banks: the chosen one ringed; runs off the right edge and scrolls
    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Stack(direction: .horizontal, gap: .spaceXs, paddingHorizontal: .space2xl, alignment: .center) {
                ForEach(Filter.allCases, id: \.self) { option in
                    Button {
                        guard option != filter else { return }
                        Haptics.tap()
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) { filter = option }
                    } label: {
                        Stack(paddingHorizontal: .spaceXl, paddingVertical: .spaceMdLg) {
                            DsText(option.rawValue, variant: .h6, color: option == filter ? .contentPrimary : .contentTertiary)
                                .fixedSize()
                        }
                        .background {
                            if option == filter {
                                Surface(shape: .capsule, border: .borderStrong) { Color.clear }
                                    .matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// "Compare returns", floating over the foot of the list
    private var compareButton: some View {
        Button(action: openSheet) {
            Surface(surface: .surfaceRaised, shape: .capsule, shadow: .token(.shadow3)) {
                Stack(direction: .horizontal, gap: .spaceMd, paddingHorizontal: .spaceXl, paddingVertical: .spaceLg, alignment: .center) {
                    Image("FDCompare").frame(width: 17, height: 17)
                    DsText("Compare returns", variant: .h6)
                        .fixedSize()
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// One issuer: who, at what rate, how safe, for how long
struct DepositCard: View {
    let deposit: FixedDepositsView.Deposit
    /// The tenure the returns are worked out on, once an amount's been entered
    var tenure: FixedDepositsView.Tenure? = nil
    /// What it pays back, once an amount's been entered; the rate then sits under it, quieter
    var maturity: Int?

    var body: some View {
        Surface(surface: .surfaceWidget, radius: .radius23) {
            Stack {
                Stack(direction: .horizontal, gap: .spaceMdLg, padding: .spaceXl, alignment: .center) {
                    Image(deposit.logo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 37, height: 37)
                        .clipped()
                    Stack(gap: .space2xs) {
                        DsText(deposit.name, variant: .h5)
                        DsText(deposit.kind.rawValue, variant: .lb1, color: .contentTertiary)
                    }
                    Spacer(minLength: 0)
                    returns
                }

                Hairline(.borderSubtle)

                Stack(gap: .spaceMd, padding: .spaceXl) {
                    Stack(direction: .horizontal, gap: .spaceMd, alignment: .center) {
                        DsText(ratingTitle, variant: .p3, color: .contentSecondary)
                        DsText(ratingValue, variant: .h5)
                    }
                    DsText(ratingNote, variant: .p5, color: .contentTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Stack(paddingHorizontal: .spaceXl) { Hairline(.borderSubtle) }

                Stack(direction: .horizontal, gap: .spaceMd, padding: .spaceXl, alignment: .center) {
                    DsText("Lock-in period", variant: .p3, color: .contentSecondary)
                    DsText(deposit.lockIn, variant: .h5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Its best rate against "PA"; or, once an amount's in, what it pays back with that tenure's rate under it
    @ViewBuilder private var returns: some View {
        if let tenure {
            Stack(alignment: .trailing) {
                if let maturity {
                    DsText(FixedDepositsView.rupees(maturity), variant: .n3, color: .statusSuccessText)
                        .contentTransition(.numericText())
                } else {
                    DsText("No \(tenure.label) FD", variant: .p3, color: .contentTertiary)
                }
                DsText(deposit.rate(for: tenure).map(FixedDepositsView.percent) ?? "Up to \(deposit.rate)",
                       variant: .n5, color: .contentTertiary)
                    .contentTransition(.numericText())
            }
            .fixedSize()
            .transition(.opacity.combined(with: .offset(y: 6)))
        } else {
            Stack(direction: .horizontal, gap: .spaceXs, alignment: Alignment(horizontal: .trailing, vertical: .firstTextBaseline)) {
                DsText(deposit.rate, variant: .n3, color: .statusSuccessText)
                DsText("PA", variant: .lb1, color: .contentTertiary)
            }
            .fixedSize()
            .transition(.opacity)
        }
    }

    private var ratingTitle: String {
        switch deposit.rating {
        case .agency(let agency, _): "\(agency) Rating"
        case .insured: "Insured up to"
        }
    }

    private var ratingValue: String {
        switch deposit.rating {
        case .agency(_, let grade): grade
        case .insured: "₹5L"
        }
    }

    private var ratingNote: String {
        switch deposit.rating {
        case .agency(_, let grade):
            let safety = grade.hasPrefix("AAA") ? "the highest" : grade.hasPrefix("AA") ? "a high" : "an adequate"
            return "\(grade) means \(safety) degree of safety for timely repayment of interest and principal."
        case .insured:
            return "Bank deposits are insured by DICGC, up to ₹5 lakh per depositor, principal and interest."
        }
    }
}

#Preview {
    FixedDepositsView()
}

/// 1Y, 2Y, 3Y, 5Y as pills, the chosen one filled
private struct TenurePicker: View {
    @Binding var tenure: FixedDepositsView.Tenure

    var body: some View {
        Stack(direction: .horizontal, gap: .spaceXs, alignment: .center) {
            ForEach(FixedDepositsView.Tenure.allCases, id: \.self) { option in
                let chosen = option == tenure
                Button {
                    guard !chosen else { return }
                    Haptics.tap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) { tenure = option }
                } label: {
                    Surface(surface: chosen ? .surfaceInverse : .surfaceBase, shape: .capsule,
                            border: chosen ? nil : .borderDefault) {
                        Stack(paddingHorizontal: .spaceMd, paddingVertical: .spaceXs) {
                            DsText(option.rawValue, variant: .lb1, color: chosen ? .contentInverse : .contentPrimary)
                                .fixedSize()
                        }
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// "Enter investment amount", on the inverse surface: the amount in a box over its own number pad, and
/// "Calculate Returns" between them
private struct CompareReturnsSheet: View {
    let amount: Int?
    let onCalculate: (Int) -> Void

    @State private var digits = ""

    private var entered: Int? { Int(digits).flatMap { $0 > 0 ? $0 : nil } }

    var body: some View {
        Surface(surface: .surfaceInverse, radius: .radius35, shadow: .token(.shadow3)) {
            Stack(gap: .space3xl, paddingHorizontal: .space2xl, paddingVertical: .spaceXl, alignment: .center) {
                Stack(gap: .spaceMdLg, alignment: .center) {
                    // The grid mark
                    ZStack(alignment: .topLeading) {
                        ForEach(Array([(3.96, 2.64), (3.96, 13.2), (13.2, 23.76), (22.44, 2.64), (22.44, 13.2)].enumerated()),
                                id: \.offset) { _, p in
                            Circle().fill(ColorScale.contentInverse).frame(width: 6.6, height: 6.6).offset(x: p.0, y: p.1)
                        }
                    }
                    .frame(width: 33, height: 33, alignment: .topLeading)

                    DsText("Enter investment amount", variant: .h2, color: .contentInverse)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                amountBox

                Button {
                    guard let entered else { return }
                    onCalculate(entered)
                } label: {
                    Surface(surface: .surfaceRaised, shape: .capsule, shadow: .none) {
                        Stack(direction: .horizontal, gap: .space2xs, paddingVertical: .spaceMd, alignment: .center) {
                            DsText("Calculate Returns", variant: .h6)
                                .fixedSize()
                            Image("PlanChevron").frame(width: 23, height: 23)
                        }
                        .padding(.leading, SpacingScale.spaceXl)
                        .padding(.trailing, SpacingScale.spaceSm)
                    }
                }
                .buttonStyle(.plain)
                .disabled(entered == nil)
                .opacity(entered == nil ? 0.35 : 1)
                .animation(.easeInOut(duration: 0.2), value: entered == nil)

                keypad
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, SpacingScale.spaceMdLg)
        .onAppear {
            if let amount { digits = String(amount) }
        }
    }

    /// The amount: "₹" and the figure grouped the Indian way, over its label
    private var amountBox: some View {
        Surface(radius: .radius15, border: .borderStrong) {
            Stack(alignment: .center) {
                DsText("₹" + (entered.map { String(FixedDepositsView.rupees($0).dropFirst(2)) } ?? "0"),
                       variant: .n1, color: entered == nil ? .contentDisabled : .contentInverse)
                    .contentTransition(.numericText())
                    .padding(.vertical, SpacingScale.spaceMd)
                    .accessibilityIdentifier("Amount")
                Hairline(.borderStrong)
                DsText("Investment amount", variant: .p4, color: .contentInverse)
                    .padding(.vertical, SpacingScale.spaceSm)
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// 1–9 in three columns, then 0 in the middle, with a way to take a digit back beside it
    private var keypad: some View {
        Stack(gap: .spaceMd) {
            ForEach(0..<3, id: \.self) { row in
                Stack(direction: .horizontal) {
                    ForEach(1...3, id: \.self) { column in key(String(row * 3 + column)) }
                }
            }
            Stack(direction: .horizontal) {
                Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                key("0")
                Button {
                    guard !digits.isEmpty else { return }
                    Haptics.tap()
                    withAnimation(.snappy(duration: 0.2)) { _ = digits.removeLast() }
                } label: {
                    Image(systemName: "delete.backward")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 29, height: 23)
                        .foregroundStyle(ColorScale.contentDisabled)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete")
            }
        }
    }

    private func key(_ digit: String) -> some View {
        Button {
            guard digits.count < 9, !(digits.isEmpty && digit == "0") else { return }
            Haptics.tap()
            withAnimation(.snappy(duration: 0.2)) { digits += digit }
        } label: {
            DsText(digit, variant: .n1, color: .contentInverse)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(KeyPress())
    }
}

/// A key dims and dips as it's pressed
private struct KeyPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.45 : 1)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
