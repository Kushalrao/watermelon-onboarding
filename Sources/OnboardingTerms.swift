import SwiftUI

/// The terms and conditions sheet (832:13925), up from the welcome's "Read the terms and conditions": a white card
/// with the Decade mark over a rule, the heading and its line, the terms scrolling under them, and Understood at its foot.
struct OnboardingTermsSheet: View {
    /// Where the card's top sits, below the status bar
    let top: CGFloat
    let onClose: () -> Void

    /// Placeholder terms, written for the prototype
    private static let sections: [(title: String, body: String)] = [
        ("1. About these terms", "These terms govern your use of the Decade app and the advisory services offered through it. By tapping Agree and Continue you confirm that you have read and accepted them."),
        ("2. Eligibility", "You must be a resident of India, at least 18 years old, and hold a valid PAN to open an account. We may ask for further documents to complete your KYC."),
        ("3. Advisory services", "Decade provides research-backed recommendations based on the details you share. Recommendations are not guarantees. You decide whether to act on any advice, and every transaction needs your confirmation."),
        ("4. Your information", "You agree to give accurate information about your income, goals and existing investments, and to keep it up to date. Advice built on incomplete details may not suit you."),
        ("5. Connecting your investments", "With your consent we fetch your mutual fund and deposit holdings from registrars and account aggregators. You can withdraw this consent at any time in Settings."),
        ("6. Fees", "Advisory fees, where they apply, are shown to you before you subscribe. We do not earn commissions from the products we recommend."),
        ("7. Market risk", "Investments are subject to market risks. Past performance does not indicate future returns, and the value of your investments can go down as well as up."),
        ("8. Privacy", "We collect and process your data as set out in our privacy policy. We do not sell your personal information to third parties."),
        ("9. Ending your account", "You may close your account at any time. We may suspend an account that breaches these terms or where the law requires us to."),
        ("10. Changes", "We may update these terms from time to time. We will let you know in the app before any change takes effect."),
        ("11. Contact", "For questions or complaints, write to our support team from the Help section of the app. We aim to reply within two working days."),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Gap: the page behind dims a little; the frame shows it, no token
                Color.black.opacity(0.05)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onClose)
                    .transition(.opacity)

                card(height: geo.size.height - top - 65)
                    .padding(.top, top)
                    .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea()
    }

    private func card(height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color.white

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Gap: Md 33/39 in black 93% has no text style or content token
                    GapText("Terms & Conditions", family: .walsheim, medium: true, size: 33, lineHeight: 39, color: Color.black.opacity(0.93))
                    // Gap: Rg 17/23 in black 61%
                    GapText("Connect your Mutual funds to use wealth intelligence", family: .walsheim, medium: false, size: 17, lineHeight: 23, color: Color.black.opacity(0.61))
                        .padding(.top, 9)
                    ForEach(Self.sections, id: \.title) { section in
                        GapText(section.title, family: .walsheim, medium: true, size: 17, lineHeight: 23, color: Color.black.opacity(0.93))
                            .padding(.top, 27)
                        GapText(section.body, family: .walsheim, medium: false, size: 17, lineHeight: 23, color: Color.black.opacity(0.61))
                            .padding(.top, 5)
                    }
                }
                .frame(width: 322, alignment: .leading)
                .padding(.leading, 23)
                .padding(.top, 22)
                .padding(.bottom, 110)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 60)

            // The terms fade out behind Understood
            LinearGradient(colors: [Color.white.opacity(0), Color.white], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.3))
                .frame(height: 120)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)

            // 832:13973: the mark and wordmark, 26pt at 23, 15
            Image("DecadeMarkPlum")
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(Color(hex: 0x33302D))
                .frame(width: 19.606, height: 19.606)
                .at(23, 20.1)
            Text("Decade")
                .font(FigmaFont.superMedium(25.999))
                .tracking(-0.26)
                .foregroundStyle(Color(hex: 0x33302D))
                .fixedSize()
                .frame(height: 29)
                .at(48.15, 15)

            // Gap: Figma black 57%, 1 pt, no token
            Color.black.opacity(0.57)
                .frame(height: 1)
                .at(0, 58)

            // Understood (832:13970), 334 × 45, 27 above the card's foot
            Button {
                Haptics.tap()
                onClose()
            } label: {
                Text("Understood")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .frame(width: 334, height: 45)
                    .background(Capsule().fill(Color.black))
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
            }
            .buttonStyle(PressScaleStyle())
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 27)
            .padding(.leading, 15)
        }
        .frame(width: 368, height: height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        // Gap: 0 4 130 +15 at 9% in Figma; SwiftUI can't draw the spread
        .shadow(color: Color.black.opacity(0.09), radius: 65, x: 0, y: 4)
    }
}
