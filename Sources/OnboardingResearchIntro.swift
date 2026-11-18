import SwiftUI

/// "Decade Research" (233:12750), 364 × 636: before the agent says anything, how its research is done. The same
/// sheet, with its own words, introduces the personal advisor once the analysis is done (243:14078).
struct ResearchIntroSheet: View {
    struct Content {
        let titleLines: [String]
        let titleSize: CGFloat, titleLineHeight: CGFloat, titleTop: CGFloat
        let subtitle: String
        let rows: [String]
        let button: String

        static let research = Content(titleLines: ["Decade", "Research"], titleSize: 67, titleLineHeight: 57, titleTop: 37,
                                      subtitle: "Our wealth intelligence is powered with",
                                      rows: ["Data from Morningstar", "Team of SEBI registered advisors",
                                             "24/7 tracking of market", "We "],
                                      button: "Understood")
        /// 243:14078
        static func advisor(name: String) -> Content {
            Content(titleLines: ["\(name)’s Personal", "Wealth Advisor"], titleSize: 45, titleLineHeight: 49, titleTop: 45,
                    subtitle: "Connect your Mutual funds to use wealth intelligence",
                    rows: ["Analyze your portfolio", "Create portfolio strategy", "Achieve goals for you",
                           "Suggest changes from market"],
                    button: "Continue")
        }
    }

    var content: Content = .research
    let onUnderstood: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        ZStack(alignment: .topLeading) {
            Color(hex: 0x151515)

            // Lines tighter than the font's own, so each is set on its own
            VStack(spacing: 0) {
                ForEach(content.titleLines, id: \.self) { line in
                    Text(line)
                        .font(FigmaFont.reckless(content.titleSize))
                        .fixedSize()
                        .frame(height: content.titleLineHeight)
                }
            }
            .foregroundStyle(Color.white.opacity(0.93))
            .frame(width: 334)
            .at(15, content.titleTop)

            Text(content.subtitle)
                .font(FigmaFont.walsheimMedium(23))
                .lineSpacing(29 - 23 * 1.2)
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .frame(width: 292)
                .at(36, 196)

            sourceList
                .at(17, 279)

            Button {
                Haptics.tap()
                onUnderstood()
            } label: {
                Text(content.button)
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.black)
                    .frame(width: 334, height: 45)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .at(15, 560)
        }
        .frame(width: 364, height: 636, alignment: .topLeading)
        .clipShape(shape)
        .contentShape(shape)
        .shadow(color: Color.black.opacity(OnboardingDecadeWelcomeView.cardShadow), radius: OnboardingDecadeWelcomeView.cardShadowRadius, x: 0, y: 4)
    }

    /// The four sources (233:12755), 330 × 252, 63pt a row, hairlines between
    private var sourceList: some View {
        let shape = RoundedRectangle(cornerRadius: 17, style: .continuous)
        return ZStack(alignment: .topLeading) {
            ForEach(Array(content.rows.enumerated()), id: \.offset) { i, title in
                let y = CGFloat(i) * 63
                ZStack(alignment: .topLeading) {
                    Image("MFCentralMark")
                        .resizable()
                        .frame(width: 26, height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .at(13, 13)
                    Text(title)
                        .font(FigmaFont.walsheim(17))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .fixedSize()
                        .frame(height: 23)
                        .at(48, 9)
                    Text("SEBI and AMFI-regulated platform")
                        .font(FigmaFont.walsheim(13))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .fixedSize()
                        .frame(height: 19)
                        .at(48, 35)
                }
                .frame(width: 330, height: 63, alignment: .topLeading)
                .offset(y: y)
                if i > 0 {
                    Rectangle()
                        .fill(Color(red: 194 / 255, green: 194 / 255, blue: 194 / 255).opacity(0.17))
                        .frame(width: 329, height: 1)
                        .at(1, y)
                }
            }
        }
        .frame(width: 330, height: 252, alignment: .topLeading)
        .overlay(shape.strokeBorder(Color(red: 194 / 255, green: 194 / 255, blue: 194 / 255).opacity(0.17), lineWidth: 1))
    }
}

/// "Decade Research" (952:11921), 368 × 631: before the agent says anything, what its wealth intelligence runs on.
/// White, with the three ways of working and a black Understood.
struct ResearchPreviewSheet: View {
    let onUnderstood: () -> Void

    /// The three things it runs on, each with a line saying what that means (952:11973). The third is still the
    /// design's placeholder.
    private static let points: [(title: String, detail: String)] = [
        ("Data backed with Morningstar", "Fund data, ratings and returns come from Morningstar’s research."),
        ("SEBI registered advisory team", "The advice is shaped and reviewed by advisors registered with SEBI."),
        ("Advisory Decisioning", "Thoughtful wealth management for people who’ve outgrown generic advice."),
    ]

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        ZStack(alignment: .topLeading) {
            Color.white

            // 952:12025: the mark, then "Decade R" upright and "esearch" in italic, 235 across
            HStack(spacing: 0) {
                Image("OnboardingDecadeMarkInk")
                    .frame(width: 33, height: 33)
                    .accessibilityHidden(true)
                (Text("Decade R").font(.custom("RecklessStandardS-TRIAL-Medium", fixedSize: 27))
                    + Text("esearch").font(.custom("RecklessStandardS-TRIAL-MediumItalic", fixedSize: 27)))
                    .foregroundStyle(ColorScale.contentPrimary)
                    .fixedSize()
                    .frame(height: 35)
                    .padding(.leading, 5)
            }
            .frame(width: 368, height: 35)
            .at(0.5, 9)

            Color.black.opacity(0.57)
                .frame(width: 334, height: 1)
                .at(17, 52)

            // Gap: GT Walsheim Medium 35/43 has no text style; the colour is content/primary
            GapText("Wealth intelligence\nis powered with", family: .walsheim, medium: true, size: 35, lineHeight: 43, color: ColorScale.contentPrimary)
                .multilineTextAlignment(.center)
                .frame(width: 318)
                .at(23, 100)

            // 952:11973: the three ways of working, 98 apart
            ForEach(Array(Self.points.enumerated()), id: \.offset) { index, point in
                ZStack(alignment: .topLeading) {
                    Image("OnboardingWayCheck")
                        .frame(width: 33, height: 33)
                        .accessibilityHidden(true)
                    Text(point.title)
                        .font(FigmaFont.walsheim(17))
                        .foregroundStyle(ColorScale.contentPrimary)
                        .fixedSize()
                        .frame(height: 25)
                        .at(44, 1)
                    Text(point.detail)
                        .font(FigmaFont.walsheim(13))
                        .lineSpacing(21 - UIFont(name: "GTWalsheimTrial-Rg", size: 13)!.lineHeight)
                        .foregroundStyle(ColorScale.contentSecondary)
                        .frame(width: 286, alignment: .leading)
                        .at(44, 29)
                }
                .frame(width: 330, height: 71, alignment: .topLeading)
                .at(19, 231 + 98 * CGFloat(index))
            }

            Button {
                Haptics.tap()
                onUnderstood()
            } label: {
                Text("Understood")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .offset(x: 0.5)
                    .frame(width: 330, height: 49)
                    .background(Capsule().fill(Color(hex: 0x1F1513)))
                    .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
            }
            .buttonStyle(PressScaleStyle())
            .at(19, 555)
        }
        .frame(width: 368, height: 631, alignment: .topLeading)
        .clipShape(shape)
        .contentShape(shape)
        // 0 4 130 +15 at 9% in Figma; SwiftUI can't draw the spread
        .shadow(color: Color.black.opacity(0.09), radius: 65, x: 0, y: 4)
    }
}

#Preview {
    VStack {
        ResearchIntroSheet(onUnderstood: {})
        ResearchIntroSheet(content: .advisor(name: AppUser.name), onUnderstood: {})
    }
}
