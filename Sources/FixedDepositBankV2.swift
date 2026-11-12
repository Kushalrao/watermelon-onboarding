import SwiftUI

/// Figma "iPhone 14 Plus - 434" (571:11578): the second version of a bank's page. A "Fixed Deposit" bar, then the
/// bank's card with its building across the top, "Things to know" as picture tiles, and the FDs on offer grouped by
/// how long they run. It is the default; `-fdBankV1` opens the first version (`FixedDepositBankView`).
struct FixedDepositBankV2View: View {
    let deposit: FixedDepositsView.Deposit
    var onBack: () -> Void = {}

    /// The plan whose row has grown into its card, and where that row sits on screen
    private struct OpenPlan: Equatable {
        let group: Int
        let offer: Int
        let frame: CGRect
    }

    @State private var plan: OpenPlan?
    /// false while the card is still (or again) its row
    @State private var planOpen = false
    private static let planTransition = Animation.spring(response: 0.55, dampingFraction: 0.86)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                identityCard
                    .askable(.bank(deposit.name, .identity, v2: true))
                    .padding(.top, 11) // Gap: 11 under the bar, no spacing token
                DsText("Things to know", variant: .h4)
                    .padding(.top, 27) // Gap: 27 above the section title, no spacing token
                thingsToKnowCard
                    .askable(.bank(deposit.name, .thingsToKnow, v2: true))
                    .padding(.top, 27) // Gap: 27 under the section title, no spacing token
                DsText("Available FD’s", variant: .h4)
                    .padding(.top, 46) // Gap: 46 above the section title, no spacing token
                VStack(spacing: SpacingScale.spaceMd) {
                    ForEach(Self.groups.indices, id: \.self) { index in
                        offersCard(index)
                            .askable(.bank(deposit.name, .offers(index), v2: true))
                    }
                }
                .padding(.top, 33) // Gap: 33 under the section title, no spacing token
            }
            .padding(.horizontal, 11) // Gap: cards sit 11 from the screen edge, no spacing token
            .padding(.bottom, 85) // Gap: 85 under the last card, no spacing token
        }
        // Holds and swipes rest while a plan is open over the page
        .allowsHitTesting(plan == nil)
        .background(ColorScale.surfaceBase.ignoresSafeArea())
        .overlay {
            if let plan {
                FixedDepositPlanLayer(
                    deposit: deposit,
                    offer: Self.groups[plan.group].offers[plan.offer],
                    icon: Self.groups[plan.group].icon,
                    origin: plan.frame,
                    open: planOpen,
                    onClose: closePlan
                )
            }
        }
        .preference(key: AdvisorBarHiddenKey.self, value: plan != nil)
        .preferredColorScheme(.light)
    }

    /// The row grows into the plan's card: placed over the row first, then opened on the next frame
    private func openPlan(group: Int, offer: Int, from frame: CGRect) {
        guard plan == nil else { return }
        Haptics.tap()
        planOpen = false
        plan = OpenPlan(group: group, offer: offer, frame: frame)
        DispatchQueue.main.async {
            withAnimation(Self.planTransition) { planOpen = true }
        }
    }

    /// The card folds back into its row
    private func closePlan() {
        guard plan != nil else { return }
        Haptics.settle()
        withAnimation(Self.planTransition) {
            planOpen = false
        } completion: {
            plan = nil
        }
    }

    /// "Suryoday SF Bank" on the list is "Suryoday Small Finance Bank" here
    private var fullName: String { deposit.name.replacingOccurrences(of: "SF Bank", with: "Small Finance Bank") }

    /// One of the page's cards on its own, for the copy a hold lifts out
    @ViewBuilder func section(_ section: FundContext.BankSection) -> some View {
        switch section {
        case .identity: identityCard
        case .thingsToKnow, .comparison, .available: thingsToKnowCard
        case .offers(let index): offersCard(index)
        }
    }

    // MARK: Bar

    private var header: some View {
        ZStack {
            // Gap: Md 17/23 at 5% tracking in black 50% has no text style or content token
            GapText("FIXED DEPOSIT", family: .walsheim, medium: true, size: 17, lineHeight: 23, trackingPercent: 5,
                    color: Color.black.opacity(0.5)) // Gap: unbound black 50%
            Button(action: onBack) {
                Image("FDBack")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .frame(maxWidth: .infinity, alignment: .leading)
            // The chevron's leading edge 20 from the screen's
            .offset(x: -8)
        }
        .frame(height: 63)
    }

    // MARK: Who it is

    private var identityCard: some View {
        Surface(surface: .surfaceWidget, radius: .radius27, shadow: .token(.shadow3)) {
            VStack(alignment: .leading, spacing: 0) {
                // The building, 378 × 290, showing its 174 from 44 down
                Color.clear
                    .frame(height: 174)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .top) {
                        GeometryReader { geo in
                            let scale = geo.size.width / 368
                            Image("FDBankHero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 378 * scale, height: 290 * scale)
                                .offset(x: -4 * scale, y: -44 * scale)
                        }
                    }
                    .clipped()
                    .accessibilityHidden(true)

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
                    .padding(.top, 11) // Gap: the logo sits 11 below the name's top
                }
                .padding(.top, 19) // Gap: 19 under the picture, no spacing token
                .padding(.leading, 23) // Gap: 23 beside the name, no spacing token
                .padding(.trailing, 17) // Gap: 17 beside the logo, no spacing token

                HStack(spacing: SpacingScale.spaceXs) {
                    DsText("Since 2008 •", variant: .p3, color: .contentTertiary)
                    Image("FDNSELogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 20, height: 19)
                        .clipped()
                        .accessibilityHidden(true)
                    DsText("NSE Listed Bank", variant: .p3, color: .contentTertiary)
                }
                .padding(.top, SpacingScale.spaceSm)
                .padding(.leading, 23) // Gap: 23 beside the line, no spacing token

                Surface(radius: .radius23, border: .borderSubtle, shadow: .none) {
                    VStack(spacing: 0) {
                        credential("RBI regulated with SFB License") {
                            Image("FDSealRBI")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 46)
                                .clipped()
                        }
                        Hairline(.borderSubtle)
                        credential("AAA rated by CRISIL") {
                            Image("FDCrisilLogo")
                                .resizable()
                                .frame(width: 40.7, height: 31.7)
                                .frame(width: 44, height: 46)
                        }
                    }
                }
                .padding(.top, 22) // Gap: 22 above the box, no spacing token
                .padding(.horizontal, SpacingScale.spaceMdLg)
                .padding(.bottom, 17) // Gap: 17 under the box, no spacing token
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// A seal beside what it vouches for
    private func credential(_ title: String, @ViewBuilder seal: () -> some View) -> some View {
        let seal = seal()
        return HStack(spacing: 11) { // Gap: 11 between the seal and its line, no spacing token
            seal.accessibilityHidden(true)
            // Gap: Rg 17/23 has no text style (P3 is 17/25, H6 is Md)
            GapText(title, family: .walsheim, medium: false, size: 17, lineHeight: 23, color: ColorScale.contentPrimary)
            Spacer(minLength: 0)
        }
        .padding(.leading, SpacingScale.spaceLg)
        .frame(height: 76)
    }

    // MARK: Things to know

    private var thingsToKnowCard: some View {
        Surface(surface: .surfaceWidget, radius: .radius27) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: SpacingScale.spaceMdLg) {
                    tile("Withdraw anytime") {
                        Image("FDKnowWithdraw").resizable().frame(width: 112, height: 90).offset(y: 8)
                    }
                    tile("Up to 5L insured by GICGC") {
                        Image("FDKnowInsured").resizable().frame(width: 115, height: 92).offset(y: 5)
                    }
                }
                HStack(spacing: SpacingScale.spaceMdLg) {
                    tile("Highest interest rate by bank") {
                        Image("FDKnowRate").resizable().frame(width: 147, height: 74).offset(x: -1.5, y: 15)
                    }
                    tile("Compared with other banks") { EmptyView() }
                }
                .padding(.top, 10) // Gap: 10 between the first two rows, no spacing token
                HStack(spacing: SpacingScale.spaceMdLg) {
                    tile("Get instant receipt") {
                        Image("FDKnowReceipt").resizable().frame(width: 95, height: 95).offset(y: 2)
                    }
                    Color.clear.frame(maxWidth: .infinity)
                }
                .padding(.top, 26) // Gap: 26 above the last row, no spacing token
            }
            .padding(.horizontal, SpacingScale.spaceMdLg)
            .padding(.vertical, 17) // Gap: 17 above and below the tiles, no spacing token
        }
    }

    /// A picture over two lines of what it stands for
    private func tile(_ label: String, @ViewBuilder picture: () -> some View) -> some View {
        let picture = picture()
        return Surface(radius: .radius23, border: .borderSubtle, shadow: .none) {
            ZStack(alignment: .top) {
                picture.accessibilityHidden(true)
                // Gap: Rg 17/21 has no text style (P3 is 17/25)
                GapText(label, family: .walsheim, medium: false, size: 17, lineHeight: 21, color: ColorScale.contentSecondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 131)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 110) // Gap: the label sits 110 down the tile
            }
            .frame(maxWidth: .infinity, minHeight: 172, maxHeight: 172, alignment: .top)
        }
    }

    // MARK: Available FDs

    private struct Group {
        let title: String
        let icon: String
        let offers: [FDOffer]
    }

    // Figma 571:11994: each group's rows carry the bars on the group's colour
    private static let groups = [
        Group(title: "More than 1 year", icon: "FDTermLong",
              offers: [FDOffer(term: "5 years", rate: "8.25", years: 5), FDOffer(term: "3 years", rate: "4.00", years: 3),
                       FDOffer(term: "1 year", rate: "4.00", years: 1)]),
        Group(title: "Up to 1 year", icon: "FDTermMid",
              offers: [FDOffer(term: "6 months", rate: "4.00", years: 0.5), FDOffer(term: "9 months", rate: "4.00", years: 0.75),
                       FDOffer(term: "1 year", rate: "4.00", years: 1)]),
        Group(title: "Up to 3 months", icon: "FDTermShort",
              offers: [FDOffer(term: "14 days", rate: "4.00", years: 14.0 / 365), FDOffer(term: "45 days", rate: "4.25", years: 45.0 / 365),
                       FDOffer(term: "90 days", rate: "4.50", years: 90.0 / 365)]),
    ]

    private func offersCard(_ index: Int) -> some View {
        let group = Self.groups[index]
        return Surface(surface: .surfaceWidget, radius: .radius27) {
            VStack(alignment: .leading, spacing: 0) {
                DsText(group.title, variant: .h5)
                    .padding(.top, SpacingScale.spaceXl)
                    .padding(.leading, SpacingScale.spaceXl)
                VStack(spacing: SpacingScale.spaceXs) {
                    ForEach(group.offers.indices, id: \.self) { offer in
                        offerRow(group: index, offer: offer)
                    }
                }
                .padding(.top, SpacingScale.spaceXl)
                .padding(.horizontal, SpacingScale.spaceLg)
                .padding(.bottom, 12) // Gap: 12 under the rows, no spacing token
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// A plan; a tap grows it into its card
    private func offerRow(group: Int, offer: Int) -> some View {
        Surface(surface: .surfaceWidget, radius: .radius23, border: .borderSubtle, shadow: .none) {
            FDOfferRowContent(offer: Self.groups[group].offers[offer], icon: Self.groups[group].icon)
        }
        // Gone from the page while it is the card
        .opacity(plan?.group == group && plan?.offer == offer ? 0 : 1)
        .overlay {
            GeometryReader { geo in
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { openPlan(group: group, offer: offer, from: geo.frame(in: .global)) }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    FixedDepositBankV2View(deposit: FixedDepositsView.deposits[9])
}
