import SwiftUI

/// One FD on offer at a bank: how long it runs and what it pays
struct FDOffer: Equatable {
    let term: String
    /// The rate as the frame writes it, without the sign ("8.25")
    let rate: String
    /// Its length in years, for working out what it pays back
    let years: Double

    /// What `amount` grows to over the term, compounded quarterly as the list's returns are
    func maturity(of amount: Int) -> Int {
        Int((Double(amount) * pow(1 + (Double(rate) ?? 0) / 100 / 4, years * 4)).rounded())
    }
}

/// A plan's row on the bank's page: its group's swatch, the term, the rate and a chevron. Also what the plan's
/// card starts out as when the row grows into it.
struct FDOfferRowContent: View {
    let offer: FDOffer
    let swatch: Color

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: RadiusToken.radius15.value, style: .continuous)
                .fill(swatch)
                .frame(width: 39, height: 39)
            // Gap: P3's size at 17/23 in black, unbound in the frame
            GapText(offer.term, family: .walsheim, medium: false, size: 17, lineHeight: 23, color: Color.black) // Gap: unbound black
                .padding(.leading, SpacingScale.spaceLg)
            Spacer(minLength: 0)
            FDRateText(rate: offer.rate)
            Image("FDRowChevron")
                .padding(.leading, SpacingScale.spaceMd)
                .accessibilityHidden(true)
        }
        .padding(.leading, 16) // Gap: 16 beside the swatch, no spacing token
        .padding(.trailing, 17) // Gap: 17 beside the chevron, no spacing token
        .frame(height: 75)
    }
}

/// A rate in the plans' green
struct FDRateText: View {
    let rate: String

    var body: some View {
        // Gap: Md 19/25 at 9% tracking in utility-green/500 has no text style or content token
        GapText(rate + "%", family: .walsheim, medium: true, size: 19, lineHeight: 25, trackingPercent: 9,
                color: ColorPrimitives.utilityGreen500) // ds-lint-ignore: no_tier1
    }
}

/// Figma "iPhone 14 Plus - 447" (599:14609): a plan opened from its row on the bank's page. Not a push: the row
/// itself grows into the card (the plan, how its interest is paid, and the amount), the page fading away behind
/// it while the number pad and "Continue" come up underneath. Once typing an amount has paused, the foot of the card opens to
/// say what the FD will be worth at maturity. The chevron folds the card back into its row.
struct FixedDepositPlanLayer: View {
    let deposit: FixedDepositsView.Deposit
    let offer: FDOffer
    let swatch: Color
    /// The row's frame on screen, where the card grows from and folds back to
    let origin: CGRect
    /// false = still the row, true = the card
    let open: Bool
    let onClose: () -> Void

    @State private var digits = ""
    /// How far the card has been pulled down; let go far enough and it folds back into its row
    @State private var pull: CGFloat = 0
    private static let pullToClose: CGFloat = 90
    /// The card's foot is open on the maturity value: only once typing has paused, and shut again by the next key
    @State private var showsMaturity = false
    /// How long after the last key the foot waits before opening
    private static let typingPause: Duration = .milliseconds(650)

    private var entered: Int? { Int(digits).flatMap { $0 > 0 ? $0 : nil } }

    /// The trial restyle of Figma "iPhone 14 Plus - 450" (599:16575): a green-tinted ground, a taller card that
    /// holds the number pad, a tinted plan box, a black-ringed amount and an olive maturity line. Its values are
    /// written out as drawn, not bound to tokens, so it can be dropped again: `-fdPlanV1` shows the first styling,
    /// and deleting the `restyled` branches restores it for good.
    private let restyled = !ProcessInfo.processInfo.arguments.contains("-fdPlanV1")
    /// The restyled card: 664 tall whatever the amount, so the pad inside it never moves
    private static let restyledHeight: CGFloat = 664

    /// The card is 364 wide on the 390 frame, 13 from each edge; 338 tall, 382 once its foot is open
    private static let margin: CGFloat = 13
    private static let closedHeight: CGFloat = 338
    private static let openHeight: CGFloat = 382

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width - Self.margin * 2
            let target = CGRect(x: Self.margin, y: geo.safeAreaInsets.top + 17, width: cardWidth,
                                height: restyled ? Self.restyledHeight : showsMaturity ? Self.openHeight : Self.closedHeight)
            let rect = open ? target : origin
            // The row's 23 corners; the restyled card's are 27
            let shape = RoundedRectangle(cornerRadius: open && restyled ? 27 : 23, style: .continuous) // Gap: trial styling, as drawn

            ZStack(alignment: .topLeading) {
                // The page gives way to the plan's own ground
                (restyled ? Color(hex: 0xF8FAF5) : ColorScale.surfaceBase) // Gap: trial styling, as drawn
                    // The page starts to show through as the card is pulled down
                    .opacity(open ? 1 - min(0.6, pull / 300) : 0)
                    .contentShape(Rectangle())

                // The pad sits where it would under the card with its foot open, so it holds still as that opens
                // (restyled, the pad is inside the card)
                if !restyled {
                    keypad
                        .frame(width: geo.size.width)
                        .offset(y: target.minY + Self.openHeight + 26 + (open ? 0 : 40))
                        .opacity(open ? 1 : 0)
                }

                // Pinned to the foot of the screen: 27 above the home indicator's 34, as in the frame (21 restyled)
                continueButton
                    .frame(width: geo.size.width)
                    .offset(y: geo.safeAreaInsets.top + geo.size.height - (restyled ? 21 : 27) - 51 + (open ? 0 : 40))
                    .opacity(open ? 1 : 0)

                ZStack(alignment: .top) {
                    card(width: cardWidth)
                        .frame(width: cardWidth, height: restyled ? Self.restyledHeight : Self.openHeight, alignment: .top)
                        .opacity(open ? 1 : 0)
                    FDOfferRowContent(offer: offer, swatch: swatch)
                        .frame(width: origin.width, height: origin.height)
                        .opacity(open ? 0 : 1)
                        .accessibilityHidden(true)
                }
                .frame(width: rect.width, height: rect.height, alignment: .top)
                .background(ColorScale.surfaceWidget)
                .clipShape(shape)
                // The row's outline, lost as it lifts into a card
                .overlay(shape.strokeBorder(ColorScale.borderSubtle, lineWidth: BorderTokens.hairline).opacity(open ? 0 : 1))
                .dsShadow(open ? .shadow2 : nil)
                .offset(x: rect.minX, y: rect.minY + pull)
                .gesture(pullDown)
            }
            .frame(width: geo.size.width, height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom,
                   alignment: .topLeading)
            .ignoresSafeArea()
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: showsMaturity)
        // Restarted by every key: the foot opens only if nothing more is typed for the pause
        .task(id: digits) {
            showsMaturity = false
            guard entered != nil else { return }
            try? await Task.sleep(for: Self.typingPause)
            guard !Task.isCancelled else { return }
            showsMaturity = true
        }
    }

    /// The card follows a pull down (and barely gives to a push up). Let go past the threshold, or with a flick,
    /// and it folds back into its row; otherwise it settles back.
    private var pullDown: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let y = value.translation.height
                pull = y > 0 ? y : y / 6
            }
            .onEnded { value in
                let closes = value.translation.height > Self.pullToClose || value.predictedEndTranslation.height > 260
                if closes {
                    // The fold back starts from where the card was let go
                    onClose()
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) { pull = 0 }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { pull = 0 }
                }
            }
    }

    // MARK: Card

    private func card(width: CGFloat) -> some View {
        cardTop
            .frame(height: restyled ? Self.restyledHeight : nil, alignment: .top)
            .overlay(alignment: .top) {
                if restyled {
                    keypad.padding(.top, 400) // Gap: trial styling, the pad 400 down the card as drawn
                }
            }
    }

    private var cardTop: some View {
        VStack(spacing: 0) {
            ZStack {
                DsText("Fixed deposit", variant: .h6, color: .contentSecondary)
                Button(action: onClose) {
                    Image("FDBack")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close plan")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 3) // Gap: the chevron's leading edge 20 into the card
            }
            .frame(height: 63)

            planBox
                .padding(.top, restyled ? 11 : SpacingScale.spaceXs)
                .padding(.horizontal, 11) // Gap: 11 beside the box, no spacing token
            amountBox
                .padding(.top, 16) // Gap: 16 between the boxes, no spacing token
                .padding(.horizontal, 10) // Gap: 10 beside the box, no spacing token
        }
    }

    private var logoBox: some View {
        Surface(surface: .surfaceWidget, radius: .radius15, border: .borderSubtle, shadow: .none) {
            Image(deposit.logo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 37, height: 37)
                .clipped()
                .frame(width: 51, height: 51)
        }
        .accessibilityHidden(true)
    }

    /// The payout row's own mark, in the logo's box. The frame repeats the bank's logo here, which it isn't meant
    /// to be; a calendar stands in until the row's icon is drawn.
    private var payoutBox: some View {
        Surface(surface: .surfaceWidget, radius: .radius15, border: .borderSubtle, shadow: .none) {
            // Restyled, the frame leaves the box empty
            Image(systemName: "calendar")
                .resizable()
                .scaledToFit()
                .frame(width: 23, height: 23)
                .foregroundStyle(ColorScale.contentSecondary)
                .opacity(restyled ? 0 : 1)
                .frame(width: 51, height: 51)
        }
        .accessibilityHidden(true)
    }

    /// The plan, then how its interest is paid
    private var planBox: some View {
        Surface(radius: .radius23, border: .borderSubtle, shadow: .none) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: SpacingScale.spaceMdLg) {
                    logoBox
                        .padding(.top, SpacingScale.spaceMdLg)
                    VStack(alignment: .leading, spacing: 1) { // Gap: 1 between the term and the bank, no spacing token
                        DsText(offer.term.prefix(1).uppercased() + offer.term.dropFirst().capitalized, variant: .h6)
                        // Gap: P5's type in black 50%, which is not bound to a content token in the frame
                        GapText(deposit.name, family: .walsheim, medium: false, size: 13, lineHeight: 21, color: Color.black.opacity(0.5)) // Gap: unbound black 50%
                    }
                    .padding(.top, 16) // Gap: 16 above the term, no spacing token
                    Spacer(minLength: 0)
                    FDRateText(rate: offer.rate)
                        .padding(.top, 16) // Gap: 16 above the rate, no spacing token
                }
                .padding(.leading, SpacingScale.spaceMd)
                .padding(.trailing, 17) // Gap: 17 beside the rate, no spacing token
                .frame(height: 76, alignment: .top)

                Hairline(.borderSubtle)

                HStack(spacing: SpacingScale.spaceMdLg) {
                    payoutBox
                    // Gap: Rg 17/23 has no text style (P3 is 17/25, H6 is Md)
                    GapText("Interest payout", family: .walsheim, medium: false, size: 17, lineHeight: 23, color: ColorScale.contentPrimary)
                    Spacer(minLength: 0)
                    HStack(spacing: SpacingScale.spaceXs) {
                        // Gap: P5's type in #212121 93%, unbound in the frame
                        GapText("Monthly", family: .walsheim, medium: false, size: 13, lineHeight: 21, color: Color(hex: 0x212121).opacity(0.93)) // Gap: unbound #212121 93%
                        Image("FDPencil").accessibilityHidden(true)
                    }
                    .padding(.horizontal, SpacingScale.spaceSm)
                    .padding(.vertical, SpacingScale.spaceXs)
                    .background(Capsule().fill(Color(hex: 0xF5F5F5))) // Gap: #F5F5F5 is unbound (surface/sunken-1 is #F5F3F2)
                }
                .padding(.leading, SpacingScale.spaceMd)
                .padding(.trailing, 19) // Gap: 19 beside the pill, no spacing token
                .frame(height: 77)
            }
        }
        .background(restyled ? Color(hex: 0xF5F5F2) : Color.clear, in: RoundedRectangle(cornerRadius: 23, style: .continuous)) // Gap: trial styling, as drawn
    }

    /// The amount, and under a rule what it will be worth at maturity; the foot stays shut while an amount is being typed
    private var amountBox: some View {
        let shape = RoundedRectangle(cornerRadius: 17, style: .continuous) // Gap: 17 is not a Radius variable
        return VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: SpacingScale.space2xs) {
                // Gap: Md 49.583/54.839 and Md 50.452/68 have no text style
                GapText("Rs", family: .walsheim, medium: true, size: 49.583, lineHeight: 54.839,
                        color: entered == nil ? ColorScale.contentDisabled : ColorScale.contentPrimary)
                GapText(entered.map { String(FixedDepositsView.rupees($0).dropFirst(2)) } ?? "0",
                        family: .walsheim, medium: true, size: 50.452, lineHeight: 68,
                        color: entered == nil ? ColorScale.contentDisabled : ColorScale.contentPrimary)
                    .contentTransition(.numericText())
            }
            .fixedSize()
            .padding(.top, restyled ? 15 : 14) // Gap: 14 above the amount, no spacing token (15 restyled, inside its 2pt ring)
            .padding(.bottom, SpacingScale.spaceMd)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("Plan amount")

            Hairline(.borderSubtle)
            // Gap: Rg 13/17 in utility-green/500 has no text style or content token
            GapText("Your FD at maturity will be " + FixedDepositsView.rupees(offer.maturity(of: entered ?? 0)),
                    family: .walsheim, medium: false, size: 13, lineHeight: 17,
                    color: restyled ? Color(hex: 0xB7AD00) : ColorPrimitives.utilityGreen500) // Gap: trial styling, as drawn. ds-lint-ignore: no_tier1
                .contentTransition(.numericText())
                .padding(.top, 11) // Gap: 11 under the rule, no spacing token
                .opacity(showsMaturity ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: showsMaturity ? 135 : restyled ? 93 : 91, alignment: .top)
        .background(ColorScale.surfaceWidget)
        .clipShape(shape)
        .overlay(shape.strokeBorder(restyled ? Color.black : ColorScale.borderSubtle, lineWidth: restyled ? 2 : BorderTokens.hairline)) // Gap: trial styling, a 2pt black ring as drawn
        .shadow(color: Color.black.opacity(restyled ? 0.05 : 0), radius: 42, x: 0, y: 2) // Gap: trial styling, 0 2 84 at 5% as drawn. ds-lint-ignore: no_raw_shadow
    }

    // MARK: Pad

    /// 1–9 in three columns 129.5 apart, then 0 in the middle. The frame draws no way to take a digit back, so one
    /// sits beside the 0, as on the list's amount sheet.
    private var keypad: some View {
        VStack(spacing: SpacingScale.spaceMdLg) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(1...3, id: \.self) { column in key(String(row * 3 + column)) }
                }
            }
            HStack(spacing: 0) {
                Color.clear.frame(width: 129.5, height: 48)
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
                        .foregroundStyle(ColorScale.contentQuaternary)
                        .frame(width: 129.5, height: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlanKeyPress())
                .accessibilityLabel("Delete")
            }
        }
    }

    private func key(_ digit: String) -> some View {
        Button {
            guard digits.count < 7, !(digits.isEmpty && digit == "0") else { return }
            Haptics.tap()
            withAnimation(.snappy(duration: 0.2)) { digits += digit }
        } label: {
            // Gap: Md 35.613/48 has no text style (N1 is 35/43 at 9% tracking)
            GapText(digit, family: .walsheim, medium: true, size: 35.613, lineHeight: 48, color: ColorScale.contentSecondary)
                .frame(width: 129.5, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlanKeyPress())
    }

    private var continueButton: some View {
        Button { Haptics.tap() } label: {
            DsText("Continue", variant: .h6, color: .contentOnColor)
                .frame(width: 344, height: 51)
                .background(Capsule().fill(Color(hex: 0x1F1513))) // Gap: #1F1513 is unbound
                .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2)) // Gap: 2pt black 5%, unbound
                .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3) // Gap: 0 3 30 +8 at 3%, not a Shadow style. ds-lint-ignore: no_raw_shadow
        }
        .buttonStyle(.plain)
    }
}

/// A key dims and dips as it's pressed
private struct PlanKeyPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.45 : 1)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Set by a page whose own layer takes over the screen, so the advisor pill steps out of its way
struct AdvisorBarHiddenKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}
