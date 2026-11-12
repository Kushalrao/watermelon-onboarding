import SwiftUI

/// The pages behind the floating tabs (881:13651)
enum FundTab: String, CaseIterable {
    case market = "Market"
    case forYou = "For you"
    case research = "Research"
}

/// Market and For you side by side: the selected one is on screen, the other waits off the edge it slides in from.
/// Research has no page yet, so selecting it leaves the current page in place.
struct TabPages<Market: View>: View {
    let tab: FundTab
    let width: CGFloat
    var onContext: (FundContext) -> Void = { _ in }
    var heldContext: FundContext? = nil
    var onHold: (FundContext, CGRect) -> Void = { _, _ in }
    @ViewBuilder let market: () -> Market

    @State private var shown: FundTab = .market

    var body: some View {
        let onForYou = shown == .forYou

        ZStack(alignment: .top) {
            market()
                .offset(x: onForYou ? -width : 0)
                .allowsHitTesting(!onForYou)

            ForYouScreen(isActive: onForYou, onContext: onContext, heldContext: heldContext, onHold: onHold)
                .offset(x: onForYou ? 0 : width)
                .allowsHitTesting(onForYou)
        }
        .onChange(of: tab) { _, new in
            guard new != .research else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) { shown = new }
        }
    }
}

/// Figma: "iPhone 14 Plus - 254" (node 885:14154), 390 × 2156 — the "For you" tab.
struct ForYouScreen: View {
    /// True while this tab is on screen; switching to it plays the paragraph reveal
    var isActive: Bool = false
    var onContext: (FundContext) -> Void = { _ in }
    var heldContext: FundContext? = nil
    var onHold: (FundContext, CGRect) -> Void = { _, _ in }

    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                BackgroundBlobs()

                Image("ForYouIllustration")
                    .resizable()
                    .frame(width: 205, height: 157.002)
                    .at(93, 131.53)

                // Advisor avatar with the HSBC badge (897:16493)
                ZStack(alignment: .topLeading) {
                    Image("AdvisorAvatar")
                        .resizable()
                        .frame(width: 47, height: 47)

                    HSBCLogoCrop(slot: CGSize(width: 18, height: 18), scaleW: 3.4151, scaleH: 1.9428, leftPct: -0.4348, topPct: -0.4714)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 5.625))
                        .at(31, 31)
                }
                .frame(width: 50, height: 50, alignment: .topLeading)
                .at(17, 326)

                Text("Analysed for you")
                    .font(FigmaFont.reckless(43))
                    .foregroundStyle(Color.ink)
                    .frame(width: 356, alignment: .leading)
                    .at(17, 376)

                RevealParagraph(
                    text: "Ashima, we strongly suggest do not think the fund for you as fund goals and its performance doesn’t help your portfolio yet in long run.",
                    isRevealed: isActive
                )
                .at(17, 441)

                ResearchPill().at(17, 580)

                FundSummaryCard()
                    .widgetHold(isHeld: heldContext == .summary) { onHold(.summary, $0) }
                    .contextSwipe { onContext(.summary) }
                    .at(11, 670)

                Text("Details")
                    .font(FigmaFont.reckless(43))
                    .foregroundStyle(Color.ink)
                    .at(17, 1005)

                FundPerformanceCard()
                    .widgetHold(isHeld: heldContext == .fundPerformance) { onHold(.fundPerformance, $0) }
                    .contextSwipe { onContext(.fundPerformance) }
                    .at(11, 1077)
            }
            .frame(width: MutualFundScreen.canvasWidth, height: MutualFundScreen.canvasHeight, alignment: .topLeading)
            .clipped()
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Paragraph reveal (ported from "swipe thorugh" `MainCard.backFace`)

/// A gray copy fades out while a gradient copy is wiped in from the top with a soft edge; the lines spread
/// from a squeezed height, then lift and tighten slightly to settle, and the colour fades to the paragraph gray.
struct RevealParagraph: View {
    let text: String
    let isRevealed: Bool
    var fontSize: CGFloat = 23
    var lineSpacing: CGFloat = 1
    /// Top → bottom colours of the copy that wipes in (the reference's magenta → yellow-green by default)
    var gradient: [Color] = [
        Color(red: 0.89, green: 0.10, blue: 0.63),
        Color(red: 0.84, green: 0.88, blue: 0.05)
    ]

    @State private var lineHeightFactor: CGFloat = 0    // 0 = compressed (-24%), 1 = normal
    @State private var textOpacity: CGFloat = 0        // 0 = invisible, 1 = full
    @State private var liftOffset: CGFloat = 0         // final lift
    @State private var finalTighten: CGFloat = 0       // small top-aligned tighten at end
    @State private var grayOut: CGFloat = 0            // after the settle: gradient → the paragraph's gray

    var body: some View {
        let yScale = 0.76 + 0.24 * lineHeightFactor  // 0.76 → 1.0

        ZStack {
            // Base: gray text, always visible, fades out as gradient comes in
            paragraph
                .foregroundColor(Color.gray.opacity(0.35))
                .opacity(1.0 - textOpacity)

            // Gradient text: flows in from top
            paragraph
                .foregroundStyle(
                    LinearGradient(
                        colors: gradient,
                        startPoint: UnitPoint(x: 0.5, y: -0.1),
                        endPoint: UnitPoint(x: 0.5, y: 0.05 + lineHeightFactor * 0.95)
                    )
                )
                .mask(
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.white)
                                .frame(height: geo.size.height * textOpacity)
                            LinearGradient(
                                colors: [.white, .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 40)
                            Spacer(minLength: 0)
                        }
                    }
                )
                .opacity(1.0 - grayOut)

            // Resting colour: once settled, the gradient gives way to the Figma paragraph gray (885:14365)
            paragraph
                .foregroundStyle(Color.black.opacity(0.71))
                .opacity(grayOut)
        }
        .scaleEffect(x: 1, y: yScale, anchor: .center)
        .scaleEffect(x: 1, y: 1.0 - finalTighten, anchor: .top)
        .offset(y: liftOffset)
        .onChange(of: isRevealed) {
            if isRevealed {
                // Reset immediately
                lineHeightFactor = 0
                textOpacity = 0
                liftOffset = 0
                finalTighten = 0
                grayOut = 0

                // Phase 1: Fade in + expand + gradient flows down
                // Continuous soft haptic pulses during expansion
                let hapticGen = UIImpactFeedbackGenerator(style: .soft)
                hapticGen.prepare()
                for i in 0..<8 {
                    let time = 0.3 + Double(i) * 0.075
                    let intensity = 0.5 - Double(i) * 0.05  // fades from 0.5 → 0.15
                    DispatchQueue.main.asyncAfter(deadline: .now() + time) {
                        hapticGen.impactOccurred(intensity: max(0.15, intensity))
                    }
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                    lineHeightFactor = 1.0
                    textOpacity = 1.0
                }

                // Phase 2: Settle — lift, tighten, gradient shifts up
                withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                    liftOffset = -4
                    finalTighten = 0.05
                    lineHeightFactor = 0.92
                }

                // Phase 3: once settled (0.8 + 0.6s), the colour fades to gray
                withAnimation(.easeInOut(duration: 0.6).delay(1.4)) {
                    grayOut = 1
                }
            } else {
                // Leaving the tab: back to the start, like the reference's Back button
                lineHeightFactor = 0
                textOpacity = 0
                liftOffset = 0
                finalTighten = 0
                grayOut = 0
            }
        }
    }

    /// Figma paragraph styling (885:14365): GT Walsheim 23 / 29, 356 wide, left aligned
    private var paragraph: some View {
        Text(text)
            .font(FigmaFont.walsheim(fontSize))
            .lineSpacing(lineSpacing)
            .frame(width: 356, alignment: .leading)
    }
}

// MARK: - "View our research" pill + mic (907:16605)

private struct ResearchPill: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Button(action: { Haptics.tap() }) {
                ZStack(alignment: .topLeading) {
                    Capsule()
                        .fill(Color(hex: 0xF9F9F9))
                        .overlay(Capsule().stroke(Color.black.opacity(0.31), lineWidth: 0.7))
                        .shadow(color: Color.black.opacity(0.03), radius: 7.5, x: 0, y: 3)

                    // Figma: U+10342F in SF Compact Rounded Regular = "text.below.folder" (907:16984)
                    Image(systemName: "text.below.folder")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.67))
                        .frame(height: 23)
                        .at(17, 15)

                    Text("View our research")
                        .font(FigmaFont.walsheim(17))
                        .foregroundStyle(Color.black.opacity(0.67))
                        .frame(height: 23)
                        .at(47, 15)
                }
                .frame(width: 294, height: 53)
            }
            .buttonStyle(.plain)

            // SVG carries its shadow (129 × 129 around the 53pt button)
            Image("MicButton")
                .resizable()
                .frame(width: 129, height: 129)
                .allowsHitTesting(false)
                .at(303 - 38, -35)
        }
        .frame(width: 356, height: 53, alignment: .topLeading)
    }
}

// MARK: - Cards with the blue outline (897:16483 / 897:15428)

private struct OutlinedCard<Content: View>: View {
    let title: String
    let height: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            Text(title)
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black.opacity(0.93))
                .frame(height: 25)
                .at(17, 15)

            Rectangle()
                .fill(Color.black.opacity(0.07))
                .frame(width: 368, height: 2)
                .at(0, 54)

            content()
        }
        .frame(width: 368, height: height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).strokeBorder(Color(hex: 0x7DC5F2), lineWidth: 3))
        .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
    }
}

/// Bars that rise left to right, bottom-aligned (Frame 2349 / Rectangles 1763–1766)
private struct BarGlyph: View {
    let bars: [(height: CGFloat, color: Color)]

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                Capsule()
                    .fill(bar.color)
                    .frame(width: 7, height: bar.height)
            }
        }
    }
}

struct FundSummaryCard: View {
    var body: some View {
        OutlinedCard(title: "Summary", height: 280) {
            Image("SummaryRiskIcon")
                .resizable()
                .frame(width: 45, height: 30)
                .at(21, 76)

            Text("High risk for your appetite")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black)
                .frame(height: 25)
                .at(21 + 58, 76 + 2)

            Image("SummaryGoalsIcon")
                .resizable()
                .frame(width: 43, height: 30)
                .at(21, 137 + 8)

            Text("Your goals stretch by 2 years with this fund")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black)
                .frame(width: 267, alignment: .leading)
                .at(21 + 58, 137)

            BarGlyph(bars: [
                (24, Color(hex: 0xF53B3E)), (20, Color(hex: 0xD56719)),
                (20, Color(hex: 0xD56719)), (14, Color(hex: 0xFF7C5C)),
            ])
            .frame(width: 43, height: 24, alignment: .bottomLeading)
            .at(21, 218 + 1)

            Text("Fund performance has gone down")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black)
                .frame(height: 25)
                .at(21 + 58, 218)
        }
    }
}

struct FundPerformanceCard: View {
    var body: some View {
        OutlinedCard(title: "Fund performance", height: 235) {
            Text("Doing great")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black.opacity(0.93))
                .frame(width: 91, height: 25, alignment: .trailing)
                .at(241, 15)

            BarGlyph(bars: [(16, .gain3F), (19, .gain3F), (25, .gain3F), (36, .gain3F)])
                .frame(width: 43, height: 36, alignment: .bottomLeading)
                .at(21, 79)

            Text("Steady growth over years")
                .font(FigmaFont.walsheimMedium(17))
                .foregroundStyle(Color.black)
                .frame(height: 25)
                .at(79, 72)

            Text("NAV re-invested")
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Color.black.opacity(0.43))
                .frame(height: 23)
                .at(79, 100)
        }
    }
}

private extension Color {
    static let gain3F = Color(hex: 0x3FD519)
}
