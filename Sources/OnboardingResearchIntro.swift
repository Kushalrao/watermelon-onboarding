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

#Preview {
    VStack {
        ResearchIntroSheet(onUnderstood: {})
        ResearchIntroSheet(content: .advisor(name: "Jojo"), onUnderstood: {})
    }
}
