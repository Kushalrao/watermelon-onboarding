import SwiftUI

/// The analysis, kept in the chat once it's done (148:5911), 299 × 275: a wash of colour with "Analysed" over the
/// Decade wordmark, a line from the agent, and a way back into it
struct AnalysedCard: View {
    var name = "Jojo"
    let onView: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 29, style: .continuous)
        ZStack(alignment: .topLeading) {
            Color.white

            ZStack(alignment: .topLeading) {
                LinearGradient(stops: [
                    .init(color: Color(red: 1, green: 203 / 255, blue: 65 / 255), location: 0),
                    .init(color: Color(red: 1, green: 193 / 255, blue: 137 / 255), location: 0.91),
                    .init(color: Color(red: 248 / 255, green: 192 / 255, blue: 143 / 255), location: 1),
                ], startPoint: .leading, endPoint: .trailing)
                Text("Analysed")
                    .font(.custom("RecklessStandardS-TRIAL-SemiBold", fixedSize: 39))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFF8ED), .white], startPoint: .leading, endPoint: .trailing))
                    .shadow(color: Color.black.opacity(0.25), radius: 22, x: 0, y: 2)
                    .frame(height: 51)
                    .at(17, 13)
                Image("DecadeWordmarkBrown")
                    .frame(width: 129, height: 25)
                    .at(17, 107)
            }
            .frame(width: 299, height: 149, alignment: .topLeading)
            .clipped()

            Text("\(name), I have analyzed the requested fund for you.")
                .font(FigmaFont.walsheim(15))
                .lineSpacing(21 - 15 * 1.2)
                .foregroundStyle(Color.black.opacity(0.6))
                .frame(width: 265, alignment: .leading)
                .at(15, 165)

            Button(action: onView) {
                Text("View analysis")
                    .font(FigmaFont.walsheimMedium(13))
                    .foregroundStyle(Color.white)
                    .frame(width: 105, height: 37)
                    .background(Color.black)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .at(17, 221)
        }
        .frame(width: 299, height: 275, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.black.opacity(0.11), lineWidth: 2))
    }
}

/// "Connect your Mutual funds safely" (148:6099), 364 × 636: advice needs the funds, so it asks for them
struct ConnectFundsSheet: View {
    let onContinue: () -> Void
    let onUpload: () -> Void

    /// Its parts that have come in: the photo, the heading, MFCentral, the buttons
    @State private var shown = 0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        ZStack(alignment: .topLeading) {
            Color(hex: 0x151515)

            // 148:6129: the photo, over the brown it was shot against
            LinearGradient(colors: [Color(hex: 0xAD898E), Color(hex: 0x70523A)], startPoint: .top, endPoint: .bottom)
                .overlay {
                    Image("ConnectPhone")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 440, height: 597)
                        .offset(x: 15, y: 11)
                }
                .frame(width: 364, height: 199)
                .clipped()
                // Taller than its frame, and clipping doesn't stop it catching taps above the sheet
                .allowsHitTesting(false)
                .scaleEffect(shown > 0 ? 1 : 1.08)
                .opacity(shown > 0 ? 1 : 0)

            Group {
                Text("Required for Wealth Advisory")
                    .font(FigmaFont.walsheimMedium(23))
                    .foregroundStyle(Color.white)
                    .frame(width: 364, height: 29)
                    .at(0, 216)
                Text("Connect your Mutual funds safely")
                    .font(FigmaFont.reckless(44))
                    .lineSpacing(45 - 44 * 1.2)
                    .foregroundStyle(Color.white.opacity(0.93))
                    .multilineTextAlignment(.center)
                    .frame(width: 334)
                    .at(15, 260)
            }
            .rising(shown > 1)

            mfCentral
                .at(17, 418)
                .rising(shown > 2)

            Group {
                Button {
                    Haptics.tap()
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(FigmaFont.walsheimMedium(17))
                        .foregroundStyle(Color.black)
                        .frame(width: 334, height: 45)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
                        .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .at(15, 522)

                Button {
                    Haptics.tap()
                    onUpload()
                } label: {
                    HStack(spacing: 1) {
                        Text("Upload your portfolio yourself")
                            .font(FigmaFont.walsheim(15))
                            .foregroundStyle(Color.white.opacity(0.7))
                        Image("UploadChevron")
                            .frame(width: 21, height: 21)
                            .opacity(0.7)
                    }
                    .frame(width: 364, height: 21)
                }
                .buttonStyle(.plain)
                .at(0, 584)
            }
            .rising(shown > 3)
        }
        .frame(width: 364, height: 636, alignment: .topLeading)
        .clipShape(shape)
        .contentShape(shape)
        .shadow(color: Color.black.opacity(OnboardingDecadeWelcomeView.cardShadow), radius: OnboardingDecadeWelcomeView.cardShadowRadius, x: 0, y: 4)
        .task {
            for beat in [0.1, 0.25, 0.2, 0.2] {
                try? await Task.sleep(for: .seconds(beat))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) { shown += 1 }
            }
        }
    }

    /// "We use MFCentral for mutual funds" (154:7184), 330 × 63
    private var mfCentral: some View {
        let shape = RoundedRectangle(cornerRadius: 17, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Image("MFCentralMark")
                .resizable()
                .frame(width: 26, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .at(12, 12)
            Text("We use MFCentral for mutual funds")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.white.opacity(0.85))
                .fixedSize()
                .frame(height: 23)
                .at(47, 8)
            Text("SEBI and AMFI-regulated platform")
                .font(FigmaFont.walsheim(13))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(height: 19)
                .at(47, 34)
        }
        .frame(width: 330, height: 63, alignment: .topLeading)
        .overlay(shape.strokeBorder(Color(red: 194 / 255, green: 194 / 255, blue: 194 / 255).opacity(0.17), lineWidth: 1))
    }
}

/// "Connect your mutual funds portfolio for personal advise" (256:15540), 368 × 719: the prompt that was tapped,
/// over why advice like it needs the funds
struct PersonalAdviceSheet: View {
    let prompt: String
    let chart: Int
    /// Without its own shadow, for when it's one page of `ConnectFlowSheet`
    var framed = true
    let onContinue: () -> Void

    private static let rows = ["Analyze your portfolio", "Create portfolio strategy", "Achieve goals for you"]
    private static let line = Color(red: 194 / 255, green: 194 / 255, blue: 194 / 255).opacity(0.37)

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        ZStack(alignment: .topLeading) {
            Color.white

            OnboardingDecadeWelcomeView.advicePromptCard(prompt, index: chart)
                .shadow(color: Color.black.opacity(0.11), radius: 34, x: 0, y: 2)
                .at(91, 27)

            Text("Connect your mutual funds portfolio for personal advise")
                .font(FigmaFont.walsheimMedium(33))
                .lineSpacing(39 - 33 * 1.2)
                .foregroundStyle(Color.black.opacity(0.93))
                .multilineTextAlignment(.center)
                .frame(width: 342)
                .at(13, 246)

            Text("Connect your Mutual funds to use wealth intelligence")
                .font(FigmaFont.walsheim(17))
                .lineSpacing(23 - 17 * 1.2)
                .foregroundStyle(Color.black.opacity(0.61))
                .multilineTextAlignment(.center)
                .frame(width: 290)
                .at(37, 370)

            rows.at(19, 431)

            Button {
                Haptics.tap()
                onContinue()
            } label: {
                Text("Continue")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .frame(width: 334, height: 45)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .at(15, 647)
        }
        .frame(width: 368, height: 719, alignment: .topLeading)
        .clipShape(shape)
        .contentShape(shape)
        .shadow(color: Color.black.opacity(framed ? OnboardingDecadeWelcomeView.cardShadow : 0), radius: OnboardingDecadeWelcomeView.cardShadowRadius, x: 0, y: 4)
    }

    /// 256:15565, 330 × 189: three rows of 63, hairlines between
    private var rows: some View {
        let shape = RoundedRectangle(cornerRadius: 17, style: .continuous)
        return ZStack(alignment: .topLeading) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { i, title in
                let y = CGFloat(i) * 63
                Image("MFCentralMark")
                    .resizable()
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .at(12, y + 12)
                Text(title)
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .fixedSize()
                    .frame(height: 23)
                    .at(47, y + 8)
                Text("SEBI and AMFI-regulated platform")
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(Color.black.opacity(0.55))
                    .fixedSize()
                    .frame(height: 19)
                    .at(47, y + 34)
                if i > 0 {
                    Self.line.frame(width: 329, height: 1).at(0, y - 1)
                }
            }
        }
        .frame(width: 330, height: 189, alignment: .topLeading)
        .overlay(shape.strokeBorder(Self.line, lineWidth: 1))
    }
}

/// "We will import mutual funds via MFCentral" (256:15592), 368 × 719: the photo, two reassurances, Continue, and
/// the way round it
struct MFCentralImportSheet: View {
    var framed = true
    let onContinue: () -> Void
    let onUpload: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        ZStack(alignment: .topLeading) {
            Color.white

            // 256:15656: the photo, over the brown it was shot against
            LinearGradient(colors: [Color(hex: 0xAD898E), Color(hex: 0x70523A)], startPoint: .top, endPoint: .bottom)
                .overlay {
                    Image("ConnectPhone")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 440, height: 597)
                        .offset(x: 15, y: 10.5)
                }
                .frame(width: 368, height: 296)
                .clipped()
                .allowsHitTesting(false)

            Text("We will import mutual funds via MFCentral")
                .font(FigmaFont.walsheimMedium(33))
                .lineSpacing(39 - 33 * 1.2)
                .foregroundStyle(Color.black.opacity(0.93))
                .multilineTextAlignment(.center)
                .frame(width: 346)
                .at(11, 323)

            point("MFCentral is SEBI and AMFI-regulated platform") {
                Image("MFShield").frame(width: 25, height: 25)
            }
            .at(37, 428)

            point("Secure import with one time password sent on your registered mobile number") {
                // 256:15676: five green dots
                ZStack(alignment: .topLeading) {
                    ForEach(Array([CGPoint(x: 3, y: 2), CGPoint(x: 3, y: 10), CGPoint(x: 10, y: 18),
                                   CGPoint(x: 17, y: 2), CGPoint(x: 17, y: 10)].enumerated()), id: \.offset) { _, p in
                        Circle().fill(Color(hex: 0x19D522)).frame(width: 5, height: 5).at(p.x, p.y)
                    }
                }
                .frame(width: 25, height: 25, alignment: .topLeading)
            }
            .at(37, 497)

            Button {
                Haptics.tap()
                onContinue()
            } label: {
                Text("Continue")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .frame(width: 314, height: 45)
                    .background(Color.black)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .at(27, 594)

            Button {
                Haptics.tap()
                onUpload()
            } label: {
                HStack(spacing: 1) {
                    Text("Upload your portfolio yourself")
                        .font(FigmaFont.walsheim(15))
                        .foregroundStyle(Color.black.opacity(0.7))
                    Image("ImportChevron").frame(width: 21, height: 21)
                }
                .frame(width: 368, height: 21)
            }
            .buttonStyle(.plain)
            .at(0, 664)
        }
        .frame(width: 368, height: 719, alignment: .topLeading)
        .clipShape(shape)
        .contentShape(shape)
        .shadow(color: Color.black.opacity(framed ? OnboardingDecadeWelcomeView.cardShadow : 0), radius: OnboardingDecadeWelcomeView.cardShadowRadius, x: 0, y: 4)
    }

    /// An icon and a line beside it, 36pt in
    private func point<Icon: View>(_ text: String, @ViewBuilder icon: () -> Icon) -> some View {
        ZStack(alignment: .topLeading) {
            icon().at(0, 3)
            Text(text)
                .font(FigmaFont.walsheim(17))
                .lineSpacing(23 - 17 * 1.2)
                .foregroundStyle(Color.black.opacity(0.61))
                .frame(width: 258, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .at(36, 0)
        }
        .frame(width: 294, alignment: .topLeading)
    }
}

/// Asking for the funds, then how they'll be brought in, as one sheet: Continue slides the first page off to the
/// left and the second in from the right, the sheet itself staying put
struct ConnectFlowSheet: View {
    let prompt: String
    let chart: Int
    /// On the second page, "We will import mutual funds via MFCentral"
    @Binding var importing: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        ZStack {
            if !importing {
                PersonalAdviceSheet(prompt: prompt, chart: chart, framed: false) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) { importing = true }
                }
                .transition(.move(edge: .leading))
            } else {
                MFCentralImportSheet(framed: false, onContinue: {}, onUpload: {})
                    .transition(.move(edge: .trailing))
            }
        }
        .frame(width: 368, height: 719)
        .background(Color.white)
        .clipShape(shape)
        .contentShape(shape)
        .shadow(color: Color.black.opacity(OnboardingDecadeWelcomeView.cardShadow), radius: OnboardingDecadeWelcomeView.cardShadowRadius, x: 0, y: 4)
    }
}

private extension View {
    func rising(_ shown: Bool) -> some View {
        opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
    }
}

#Preview {
    VStack {
        AnalysedCard(onView: {})
        ConnectFundsSheet(onContinue: {}, onUpload: {})
        PersonalAdviceSheet(prompt: OnboardingDecadeWelcomeView.advicePrompts[0], chart: 0, onContinue: {})
        MFCentralImportSheet(onContinue: {}, onUpload: {})
    }
}
