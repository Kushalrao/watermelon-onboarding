import SwiftUI

/// Figma "iPhone 14 Plus - 432" (555:10021): one bank's page, pushed from its card on the fixed deposits list.
/// The bank's building up top, then four cards: who it is and how it is regulated, things to know, its interest
/// against two other banks, and the FDs on offer. The back chevron pops to the list.
struct FixedDepositBankView: View {
    let deposit: FixedDepositsView.Deposit
    var onBack: () -> Void = {}

    /// The frame is drawn 390 wide
    private static let designWidth: CGFloat = 390

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / Self.designWidth
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .top) {
                    Image("FDBankHero")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 487 * scale, height: 374 * scale)
                        .offset(x: -4.5 * scale)
                        .frame(width: geo.size.width, height: 374 * scale)
                        .clipped()
                        .accessibilityHidden(true)

                    // Scrolls away with the picture: the chevron's leading edge 20 in, its top 67 down the page
                    Button(action: onBack) {
                        Image("FDBack")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                    .offset(x: 3, y: 53.5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 0) {
                        identityCard
                            .askable(.bank(deposit.name, .identity, v2: false))
                        thingsToKnowCard
                            .askable(.bank(deposit.name, .thingsToKnow, v2: false))
                            .padding(.top, 19) // Gap: 19 between the cards, no spacing token
                        comparisonCard
                            .askable(.bank(deposit.name, .comparison, v2: false))
                            .padding(.top, 28) // Gap: 28 between the cards, no spacing token
                        DsText("Available FD’s", variant: .h4)
                            .padding(.top, 33) // Gap: 33 above the section title, no spacing token
                        availableCard
                            .askable(.bank(deposit.name, .available, v2: false))
                            .padding(.top, 23) // Gap: 23 under the section title, no spacing token
                    }
                    .padding(.horizontal, 11) // Gap: cards sit 11 from the screen edge, no spacing token
                    // The first card overlaps the foot of the picture by 20
                    .padding(.top, 354 * scale)
                    .padding(.bottom, 85) // Gap: 85 under the last card, no spacing token
                }
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .background(ColorScale.surfaceBase.ignoresSafeArea())
        .preferredColorScheme(.light)
    }

    /// "Suryoday SF Bank" on the list is "Suryoday Small Finance Bank" here
    private var fullName: String { deposit.name.replacingOccurrences(of: "SF Bank", with: "Small Finance Bank") }

    /// One of the page's cards on its own, for the copy a hold lifts out
    @ViewBuilder func section(_ section: FundContext.BankSection) -> some View {
        switch section {
        case .identity: identityCard
        case .thingsToKnow: thingsToKnowCard
        case .comparison: comparisonCard
        case .available, .offers: availableCard
        }
    }

    // MARK: Who it is

    private var identityCard: some View {
        Surface(surface: .surfaceWidget, radius: .radius27) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: SpacingScale.spaceMd) {
                    // Gap: Reckless Medium 35/43 has no text style (H2 is Regular 35/51)
                    GapText(fullName, family: .reckless, medium: true, size: 35, lineHeight: 43, color: ColorScale.contentPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Surface(surface: .surfaceWidget, radius: .radius15, border: .borderSubtle, shadow: .none) {
                        Image(deposit.logo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 37, height: 37)
                            .clipped()
                            .frame(width: 51, height: 51)
                    }
                    .padding(.top, SpacingScale.space2xs)
                }
                .padding(.top, 23) // Gap: 23 above the name, no spacing token
                .padding(.leading, 23) // Gap: 23 beside the name, no spacing token
                .padding(.trailing, 17) // Gap: 17 beside the logo, no spacing token

                DsText("Since 2008 • Public bank", variant: .p3, color: .contentTertiary)
                    .padding(.top, 6) // Gap: 6 under the name, no spacing token
                    .padding(.leading, 23) // Gap: 23 beside the line, no spacing token

                Surface(radius: .radius23, border: .borderSubtle, shadow: .none) {
                    VStack(alignment: .leading, spacing: 0) {
                        credential(seal: "FDSealRBI", sealDrop: 1, title: "RBI regulated",
                                   note: "It holds a small finance bank license issued by the RBI under Section 22 (1) of the Banking Regulation Act, 1949")
                            .padding(.top, SpacingScale.spaceMdLg)
                            .padding(.bottom, 23) // Gap: 23 above the rule, no spacing token
                        Hairline(.borderSubtle)
                        credential(seal: "FDSealCrisil", sealDrop: 5, title: "AAA rated by CRISIL",
                                   note: "AAA rating represents the highest degree of safety")
                            .padding(.top, SpacingScale.spaceMdLg)
                            .padding(.bottom, SpacingScale.spaceXl)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 19) // Gap: 19 above the box, no spacing token
                .padding(.horizontal, SpacingScale.spaceMdLg)
                .padding(.bottom, SpacingScale.spaceMdLg)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// A seal, what it vouches for, and a line on what that means
    private func credential(seal: String, sealDrop: CGFloat, title: String, note: String) -> some View {
        HStack(alignment: .top, spacing: 11) { // Gap: 11 between the seal and its text, no spacing token
            Image(seal)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 44, height: 46)
                .clipped()
                .offset(y: sealDrop)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) { // Gap: 1 between the title and its note, no spacing token
                DsText(title, variant: .h6)
                DsText(note, variant: .p5, color: .contentSecondary)
                    .frame(width: 263, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.leading, 10) // Gap: 10 beside the seal, no spacing token
    }

    // MARK: Things to know

    private var thingsToKnowCard: some View {
        Surface(surface: .surfaceWidget, radius: .radius27) {
            VStack(alignment: .leading, spacing: 0) {
                cardTitle("Things to know")
                Hairline(.borderSubtle)
                VStack(alignment: .leading, spacing: 33) { // Gap: 33 between the rows, no spacing token
                    point("Withdraw FD anytime after 7 days")
                    point("FD insured upto 5L by DICGC")
                    point("Get instant receipt on mail")
                }
                .padding(.top, SpacingScale.spaceXl)
                .padding(.leading, 19) // Gap: 19 beside the rows, no spacing token
                .padding(.bottom, 31) // Gap: 31 under the rows, no spacing token
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func point(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 17) { // Gap: 17 between the tick and its line, no spacing token
            Image("FDCheck")
                .offset(y: 1)
                .accessibilityHidden(true)
            // Gap: P3's type in black, which is not bound to a content token in the frame
            GapText(text, family: .walsheim, medium: false, size: 17, lineHeight: 25, color: Color.black) // Gap: unbound black
        }
    }

    /// A card's heading over its rule
    private func cardTitle(_ title: String) -> some View {
        DsText(title, variant: .h5)
            .padding(.vertical, SpacingScale.spaceLg)
            .padding(.leading, 19) // Gap: 19 beside the heading, no spacing token
    }

    // MARK: Interest comparison

    private struct Rival {
        let name: String
        let logo: String
        let rate: String
        let bar: CGFloat
        let leads: Bool
    }

    /// This bank against two other small finance banks, at the rates and bar lengths drawn in the frame
    private var rivals: [Rival] {
        let others = [("Unity SF Bank", "FDUnity"), ("Jana SF Bank", "FDJana"), ("Suryoday SF Bank", "FDSuryoday")]
            .filter { $0.0 != deposit.name }
        return [
            Rival(name: fullName, logo: deposit.logo, rate: "8.25%", bar: 160, leads: true),
            Rival(name: others[0].0, logo: others[0].1, rate: "7.5%", bar: 139, leads: false),
            Rival(name: others[1].0, logo: others[1].1, rate: "7.5%", bar: 104, leads: false),
        ]
    }

    private var comparisonCard: some View {
        Surface(surface: .surfaceWidget, radius: .radius27) {
            VStack(alignment: .leading, spacing: 0) {
                cardTitle("Interest comparison")
                Hairline(.borderSubtle)
                Surface(surface: .surfaceWidget, radius: .radius15, border: .borderDefault, shadow: .none) {
                    VStack(spacing: 0) {
                        ForEach(rivals, id: \.name) { rivalRow($0) }
                    }
                }
                .padding(.top, SpacingScale.spaceMdLg)
                .padding(.horizontal, 17) // Gap: 17 beside the box, no spacing token

                tenures
                    .frame(maxWidth: .infinity)
                    .padding(.top, 19) // Gap: 19 above the tenures, no spacing token
                    .padding(.bottom, SpacingScale.spaceXl)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func rivalRow(_ rival: Rival) -> some View {
        HStack(alignment: .top, spacing: 10) { // Gap: 10 between the logo and the name, no spacing token
            Image(rival.logo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 37, height: 37)
                .clipped()
                .padding(.top, 1) // Gap: the logo sits 1 below the name's top
            VStack(alignment: .leading, spacing: SpacingScale.spaceMd) {
                // Gap: P5's type in black 70%, which is not bound to a content token in the frame
                GapText(rival.name, family: .walsheim, medium: false, size: 13, lineHeight: 21, color: Color.black.opacity(0.7)) // Gap: unbound black 70%
                    .fixedSize()
                Capsule()
                    // Gap: the bars use primitives (utility-green/400 unbound as #3FD519, blue/300); no semantic colour
                    .fill(rival.leads ? ColorPrimitives.utilityGreen400 : ColorPrimitives.blue300) // ds-lint-ignore: no_tier1
                    .frame(width: rival.bar, height: 12)
            }
            Spacer(minLength: 0)
            Group {
                if rival.leads {
                    // Gap: utility-green/500 is a primitive with no content token
                    GapText(rival.rate, family: .walsheim, medium: false, size: 17, lineHeight: 23, trackingPercent: 9,
                            color: ColorPrimitives.utilityGreen500) // ds-lint-ignore: no_tier1
                } else {
                    DsText(rival.rate, variant: .n4, color: .contentSecondary)
                }
            }
            .padding(.top, 3) // Gap: the rate sits 3 below the name's top
        }
        .padding(.vertical, SpacingScale.spaceLg)
        .padding(.leading, 12) // Gap: 12 beside the logo, no spacing token
        .padding(.trailing, SpacingScale.spaceLg)
        .accessibilityElement(children: .combine)
    }

    /// 1M … All, with 3Y ringed, where the frame draws them across its 316pt row
    private var tenures: some View {
        let labels: [(String, CGFloat)] = [("1M", 9.5), ("6M", 71), ("1Y", 130.5), ("3Y", 188), ("5Y", 247), ("All", 306.5)]
        return ZStack {
            Capsule()
                .strokeBorder(Color.black.opacity(0.41), lineWidth: 1) // Gap: black 41%, 1pt; unbound in the frame
                .frame(width: 40, height: 31)
                .position(x: 188, y: 15.5)
            ForEach(labels, id: \.0) { label, x in
                // Gap: 15/21 at 7% tracking in black 60% has no text style or content token
                GapText(label, family: .walsheim, medium: false, size: 15, lineHeight: 21, trackingPercent: 7,
                        color: Color.black.opacity(0.6)) // Gap: unbound black 60%
                    .fixedSize()
                    .position(x: x, y: 15.5)
            }
        }
        .frame(width: 316, height: 31)
    }

    // MARK: Available FDs

    private var availableCard: some View {
        Surface(surface: .surfaceWidget, radius: .radius27) {
            VStack(alignment: .leading, spacing: 0) {
                Surface(surface: .surfaceWidget, radius: .radius23, border: .borderDefault, shadow: .none) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Gap: 17/21, 15/19 and Md 35.6/48 in unbound blacks; none is a text style
                        GapText("For 6 months", family: .walsheim, medium: false, size: 17, lineHeight: 21, color: Color.black) // Gap: unbound black
                        GapText("Mutual funds market", family: .walsheim, medium: false, size: 15, lineHeight: 19,
                                color: Color.black.opacity(0.57)) // Gap: unbound black 57%
                            .padding(.top, SpacingScale.space2xs)
                        GapText("1,292", family: .walsheim, medium: true, size: 35.613, lineHeight: 48, color: Color.black) // Gap: unbound black
                            .padding(.top, 11) // Gap: 11 above the figure, no spacing token
                    }
                    .padding(.top, 18) // Gap: 18 above the first line, no spacing token
                    .padding(.leading, 58) // Gap: 58 beside the lines, no spacing token
                    .frame(maxWidth: .infinity, minHeight: 192, maxHeight: 192, alignment: .topLeading)
                }
                .padding(SpacingScale.spaceLg)
            }
            .frame(maxWidth: .infinity, minHeight: 583, maxHeight: 583, alignment: .topLeading)
        }
    }
}

/// Text whose type or colour is drawn in the frame without a text style or colour token. Each use is a gap,
/// kept at the frame's exact values until it is bound in Figma.
struct GapText: View {
    enum Family { case reckless, walsheim }

    let string: String
    let spec: TextStyleSpec
    let color: Color

    init(_ string: String, family: Family, medium: Bool, size: CGFloat, lineHeight: CGFloat,
         trackingPercent: CGFloat = 0, color: Color) {
        self.string = string
        self.spec = TextStyleSpec(
            family: family == .reckless ? FoundationTokens.fontFamilyReckless : FoundationTokens.fontFamilyGtWalsheim, // ds-lint-ignore: no_tier1
            weight: family == .reckless
                ? (medium ? FoundationTokens.fontWeightRecklessMedium : FoundationTokens.fontWeightRecklessRegular) // ds-lint-ignore: no_tier1
                : (medium ? FoundationTokens.fontWeightGtwalsheimMedium : FoundationTokens.fontWeightGtwalsheimRegular), // ds-lint-ignore: no_tier1
            size: size, lineHeight: lineHeight, trackingPercent: trackingPercent
        )
        self.color = color
    }

    var body: some View {
        Text(verbatim: string) // ds-lint-ignore: no_raw_text
            .modifier(DsTextStyle(spec: spec))
            .foregroundStyle(color)
    }
}

#Preview {
    FixedDepositBankView(deposit: FixedDepositsView.deposits[9])
}
