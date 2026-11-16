import SwiftUI

/// Figma "iPhone 14 Plus - 483" (903:3294): one of your own fixed deposits, grown out of its row under "Your
/// deposits". A card with the bar, how long it has left in a ring, what it holds and its certificate; how it's
/// growing; and the terms it was booked on.
struct FixedDepositHeldView: View {
    let deposit: FDHeldDeposit
    var onBack: () -> Void = {}

    /// 0 = the ring hasn't started, 1 = drawn as far as the term has run
    @State private var ringDrawn: CGFloat = 0
    /// The ring has grown out to its size
    @State private var ringOut = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                summaryCard
                    .padding(.top, SpacingScale.spaceSm)
                    .padding(.horizontal, 13) // Gap: the card sits 13 from the screen edge, no spacing token
                growthCard
                    .padding(.top, 57) // Gap: 57 between the cards, no spacing token
                    .padding(.horizontal, 13) // Gap: the card sits 13 from the screen edge, no spacing token
                DsText("About your FD", variant: .h5)
                    .padding(.top, 101) // Gap: 101 above the title, no spacing token
                    .padding(.leading, 18) // Gap: 18 beside the title, no spacing token
                termsCard
                    .padding(.top, 27) // Gap: 27 under the title, no spacing token
                    .padding(.horizontal, SpacingScale.spaceSm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Room to scroll the last card clear of the advisor pill
            .padding(.bottom, SpacingScale.space10xl)
        }
        .background(ColorScale.surfaceBase.ignoresSafeArea())
    }

    // MARK: Bar

    /// The bar sits inside the first card and scrolls with it
    private var header: some View {
        ZStack {
            // Gap: Md 17/23 at 5% tracking in black 50% has no text style or content token
            GapText("FIXED DEPOSIT", family: .walsheim, medium: true, size: 17, lineHeight: 23, trackingPercent: 5,
                    color: Color.black.opacity(0.5)) // Gap: unbound black 50%
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12.5) // Gap: 15 to the 39 button, no spacing token
        }
        .frame(height: 63)
    }

    // MARK: Months left

    /// The 188 ring, 24 thick: how much of the term is done, in green over a pale track. When the
    /// page opens it grows out from nothing, pushing what's under it down as it takes its room, and then the green runs
    /// round from twelve o'clock.
    private var ring: some View {
        ZStack {
            FDGlassRing(progress: 0.25 * ringDrawn)
            VStack(spacing: 0) {
                // Gap: Md 35/39 in accent-lavender/900, a primitive with no content token
                GapText("39", family: .walsheim, medium: true, size: 35, lineHeight: 39, color: ColorPrimitives.accentLavender900) // ds-lint-ignore: no_tier1
                    .fixedSize()
                // Gap: Rg 15/23 in black 43% has no text style or content token
                GapText("Months left", family: .walsheim, medium: false, size: 15, lineHeight: 23, color: Color.black.opacity(0.43)) // Gap: unbound black 43%
                    .fixedSize()
            }
        }
        .frame(width: 188, height: 188)
        .scaleEffect(ringOut ? 1 : 0)
        // Its room opens with it: nothing at first, then the ring and the 37 under it
        .frame(height: ringOut ? 188 + 37 : 0, alignment: .top)
        .onAppear {
            if reduceMotion {
                ringOut = true
                ringDrawn = 1
                return
            }
            // Once the page has slid in: out it comes, and the green follows
            withAnimation(Self.spring.delay(0.35)) { ringOut = true }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.86).delay(0.65)) { ringDrawn = 1 }
        }
        .accessibilityElement()
        .accessibilityLabel("39 months left")
    }

    /// The spring the pages' own moves use
    private static let spring = Animation.spring(response: 0.5, dampingFraction: 0.86)

    // MARK: What it holds

    /// The first card (903:3339): the bar, the ring, whose deposit it is, what's in it, and its certificate
    private var summaryCard: some View {
        Surface(surface: .surfaceWidget, radius: .radius27, shadow: .token(.shadow1)) {
            VStack(spacing: 0) {
                header
                ring
                    .padding(.top, SpacingScale.space2xl)
                HStack(spacing: 0) {
                    Image(deposit.logo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 16.686, height: 16.686)
                        .clipped()
                        .frame(width: 23, height: 23)
                        .background(ColorScale.surfaceWidget)
                        .clipShape(RoundedRectangle(cornerRadius: 6.765, style: .continuous)) // Gap: 6.765 is not a Radius variable
                        .overlay(RoundedRectangle(cornerRadius: 6.765, style: .continuous).strokeBorder(ColorScale.borderSubtle, lineWidth: 0.316)) // Gap: 6.765 radius, 0.316 stroke, neither a token
                    Image("FDSealRBI")
                        .resizable()
                        .frame(width: 21, height: 21)
                        .padding(.leading, SpacingScale.spaceXs)
                    // Gap: Rg 17/23 in black 70% has no content token
                    GapText(deposit.licence, family: .walsheim, medium: false, size: 17, lineHeight: 23, color: Color.black.opacity(0.7)) // Gap: unbound black 70%
                        .fixedSize()
                        .padding(.leading, 6) // Gap: 6 beside the seal, no spacing token
                }
                .frame(height: 23)
                .accessibilityElement(children: .combine)

                // Gap: Reckless Medium 29/37 in #212121 has no text style or content token
                GapText(deposit.title, family: .reckless, medium: true, size: 29, lineHeight: 37, color: Color(hex: 0x212121)) // Gap: unbound #212121
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 9) // Gap: 9 under the line, no spacing token

                Surface(surface: .surfaceBase, radius: .radius23, border: .borderSubtle, shadow: .none) {
                    HStack(spacing: 0) {
                        DsText("Fixed Deposit", variant: .p4, color: .contentTertiary)
                        Spacer(minLength: 0)
                        // Gap: Md 19/31 at 3% tracking has no text style
                        GapText("Rs80,020", family: .walsheim, medium: true, size: 19, lineHeight: 31, trackingPercent: 3, color: ColorScale.contentPrimary)
                            .fixedSize()
                    }
                    .padding(.horizontal, SpacingScale.spaceLg)
                    .frame(height: 61)
                }
                .padding(.top, 13) // Gap: 13 under the title, no spacing token
                .padding(.horizontal, 13) // Gap: 13 beside the box, no spacing token

                certificateButton
                    .padding(.top, 13) // Gap: 13 under the box, no spacing token
                    .padding(.horizontal, 19) // Gap: 19 beside the button, no spacing token
                    .padding(.bottom, 22) // Gap: 22 under the button, no spacing token
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// "View FD Certificate" (903:3349): an outlined pill, 51 tall. Nothing is designed behind it yet.
    private var certificateButton: some View {
        Button {
            Haptics.tap()
        } label: {
            DsText("View FD Certificate", variant: .h6)
                .frame(maxWidth: .infinity)
                .frame(height: 51)
                .background(ColorScale.surfaceWidget)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(ColorScale.borderSubtle, lineWidth: 0.7)) // Gap: 0.7 is not a stroke token
                .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3) // Gap: 0 3 30 at 3%, not a Shadow style. ds-lint-ignore: no_raw_shadow
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Growth

    /// "Fixed deposit growth" (903:3317) over the deposits chart, whose lines draw once the page has opened
    private var growthCard: some View {
        Surface(surface: .surfaceWidget, radius: .radius23, shadow: .token(.shadow2)) {
            VStack(alignment: .leading, spacing: 0) {
                DsText("Fixed deposit growth", variant: .h5)
                    .padding(.top, 17) // Gap: 17 above the title, no spacing token
                    .padding(.leading, 17) // Gap: 17 beside the title, no spacing token
                FDProjectionChart(delay: 0.5)
                    .padding(.top, 41) // Gap: 41 under the title, no spacing token
                    .padding(.leading, SpacingScale.spaceLg)
                    .padding(.trailing, SpacingScale.spaceMdLg)
                    .padding(.bottom, 85) // Gap: 85 under the chart, no spacing token
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: About your FD

    private var termsCard: some View {
        let shape = RoundedRectangle(cornerRadius: 17, style: .continuous) // Gap: 17 is not a Radius variable
        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                Image(deposit.logo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 37, height: 37)
                    .clipped()
                    .padding(.top, 3) // Gap: the logo sits 3 below the name's top
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) { // Gap: 1 between the lines, no spacing token
                    // Gap: Md 19/25 in black 83% has no text style or content token
                    GapText(deposit.name, family: .walsheim, medium: true, size: 19, lineHeight: 25, color: Color.black.opacity(0.83)) // Gap: unbound black 83%
                    DsText("Booked on ", variant: .p4, color: .contentTertiary)
                }
                .padding(.leading, 15) // Gap: 15 beside the logo, no spacing token
                Spacer(minLength: 0)
                Image("FDYoursChevron")
                    .rotationEffect(.degrees(180))
                    .padding(.top, 13) // Gap: the chevron sits 13 below the name's top
                    .accessibilityHidden(true)
            }
            .padding(.leading, 23) // Gap: 23 beside the logo, no spacing token
            .padding(.trailing, 19) // Gap: 19 beside the chevron, no spacing token
            .padding(.top, 23) // Gap: 23 above the name, no spacing token
            .frame(height: 94, alignment: .top)
            Rectangle().fill(Color.black.opacity(0.09)).frame(height: 1) // Gap: black 9% rule, unbound

            // Gap: the values are H6's type in accent-lavender/600 and utility-green/500, primitives with no content token
            term("Fixed deposit", "Rs1,68,000", ColorPrimitives.accentLavender600) // ds-lint-ignore: no_tier1
            divider
            term("Interest rate", "8.75%", ColorPrimitives.utilityGreen500) // ds-lint-ignore: no_tier1
            divider
            term("Maturity", "Aug 2031", ColorScale.contentSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 272, alignment: .top)
        .background(ColorScale.surfaceWidget)
        .clipShape(shape)
        .shadow(color: Color.black.opacity(0.05), radius: 25, x: 0, y: 4) // Gap: 0 4 50 at 5%, not a Shadow style. ds-lint-ignore: no_raw_shadow
        .accessibilityElement(children: .combine)
    }

    private var divider: some View {
        Rectangle().fill(Color.black.opacity(0.1)) // Gap: black 10% rule, unbound
            .frame(height: 1)
            .padding(.horizontal, SpacingScale.spaceLg)
    }

    private func term(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 0) {
            DsText(label, variant: .p4, color: .contentTertiary)
            Spacer(minLength: 0)
            GapText(value, family: .walsheim, medium: true, size: 17, lineHeight: 23, color: color)
                .fixedSize()
        }
        .padding(.horizontal, 17) // Gap: 17 beside the line, no spacing token
        .frame(height: 56)
    }
}

/// A progress ring in glass, 188 across and 24 thick: a clear tube for the track, and the done part as a lightly lit
/// green tube inside it, bright along its outer edge, shaded along its inner one, glowing a little onto the page. Its ends are cut square.
private struct FDGlassRing: View {
    /// 0…1 of the way round, from twelve o'clock
    var progress: CGFloat

    /// The frame draws it 18.844 thick; made thicker on request
    private static let width: CGFloat = 24

    var body: some View {
        let w = Self.width
        ZStack {
            // The track: a pale tube, lit from above
            Circle()
                .stroke(
                    LinearGradient(colors: [ColorScale.surfaceWidget, ColorScale.surfaceSunken2], startPoint: .top, endPoint: .bottom),
                    lineWidth: w // Gap: 24 is not a stroke token
                )
                .padding(w / 2) // Gap: half the stroke, so it runs inside the 188; no spacing token
            // its hollow: a soft shade just inside the upper edge
            Circle()
                .stroke(Color.black.opacity(0.06), lineWidth: 3) // Gap: unbound black 6%, 3 is not a stroke token
                .blur(radius: 2.5)
                .offset(y: 2)
                .padding(1.5) // Gap: half the 3 stroke, no spacing token
                .mask(Circle().stroke(lineWidth: w).padding(w / 2)) // Gap: the track's own shape
            // and the glint round its rims
            Circle()
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 1) // Gap: unbound white 90%
            Circle()
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1) // Gap: unbound black 5%
                .padding(w) // Gap: the tube's inner rim, no spacing token

            // The done part, in green
            arc(inset: w / 2)
                .stroke(
                    LinearGradient(colors: [Color(hex: 0x5FE23C), Color(hex: 0x3FD519), Color(hex: 0x35C812)], startPoint: .topLeading, endPoint: .bottomTrailing), // Gap: unbound, the frame's #3FD519 lit and shaded
                    style: StrokeStyle(lineWidth: w, lineCap: .butt) // Gap: 24 is not a stroke token
                )
                .shadow(color: Color(hex: 0x3FD519).opacity(0.15), radius: 5, x: 0, y: 2) // Gap: the glass's own glow, not a Shadow style. ds-lint-ignore: no_raw_shadow
            // shaded along its inner edge
            arc(inset: w * 0.8)
                .stroke(Color.black.opacity(0.03), style: StrokeStyle(lineWidth: w * 0.3, lineCap: .butt)) // Gap: unbound black 3%
                .blur(radius: 2)
            // and bright along its outer one
            arc(inset: w * 0.3)
                .stroke(
                    LinearGradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0.06)], startPoint: .top, endPoint: .bottom), // Gap: unbound white
                    style: StrokeStyle(lineWidth: w * 0.26, lineCap: .butt)
                )
                .blur(radius: 1.2)
                .blendMode(.plusLighter)
        }
        .frame(width: 188, height: 188)
    }

    /// The done part's path at `inset` from the ring's outer edge, from twelve o'clock clockwise
    private func arc(inset: CGFloat) -> some Shape {
        Circle()
            .inset(by: inset)
            .trim(from: 0, to: max(0, progress))
            .rotation(.degrees(-90))
    }
}
