import SwiftUI

/// The analysis the agent runs once the research is in. It opens over the chat like the research plan did, white,
/// with its own minute on the clock (146:5043); while it works it asks a question to bust a myth, a fund to weigh
/// up and a Yes or No, and answers whichever way it's taken (148:5339). When the minute is up the sheet turns black
/// and becomes the analysis itself (146:4908): what it found, section by section, all of it scrolling.
struct AnalysisSheet: View {
    /// When the analysis began; the timer counts down from here
    let started: Date
    /// The minute is up: the sheet is the black analysis
    let done: Bool

    /// The white phase's parts that have come in: title and timer, "While it happens", the fund, the question, the
    /// buttons
    @State private var revealed = 0
    /// The answer that was given, if any; kept by the chat, so it's still there when the sheet opens again
    @Binding var answer: Bool?
    /// Its parts come in one by one only the first time it opens; after that it's simply there
    var animatesIn = true
    /// The close at the header's right
    var onClose: () -> Void = {}
    /// "Understood", floating at the foot once the analysis is done
    var onUnderstood: () -> Void = {}
    /// The black phase's parts that have come in, top down
    @State private var resultsShown = 0

    static let width: CGFloat = 368
    static let whiteHeight: CGFloat = 612
    static let blackHeight: CGFloat = 652

    /// While it works it asks a myth-busting question; for now it has you draw a curve instead (`CurveGuess`)
    static let asksMyth = false

    /// The myths it busts while it works; one designed so far
    static let questions: [Myth] = [
        Myth(fund: "Axis Bluechip Fund", logo: "FundAxis", rating: "Rated 5",
             question: "Would you consider investing in a fund like this? It was 5 star for 3 years.",
             yes: "Most people would. It was a top fund in 2019, but today it’s last in its class. The three stocks that made it famous stopped growing, and the fund kept holding them. Stars tell you what a fund did, not what it’s doing.",
             no: "Good instinct. It was a top fund in 2019, and today it’s last in its class. The three stocks that made it famous stopped growing, and the fund kept holding them. Five stars didn’t warn anyone. That’s why we look at what a fund is doing now."),
    ]

    struct Myth {
        let fund: String, logo: String, rating: String, question: String
        /// What it says back, depending on the answer
        let yes: String, no: String
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if !done {
                working
                    .transition(.opacity.animation(.easeOut(duration: 0.3)))
            }
            if done {
                AnalysisResults(shown: resultsShown, onClose: onClose, onUnderstood: onUnderstood)
                    .transition(.opacity.animation(.easeOut(duration: 0.35).delay(0.15)))
            }
        }
        .frame(width: Self.width, height: done ? Self.blackHeight : Self.whiteHeight, alignment: .topLeading)
        .onAppear {
            // Back again: all there from its first frame
            guard !animatesIn else { return }
            revealed = 5
            if done { resultsShown = AnalysisResults.parts }
        }
        .task { await reveal() }
        .onChange(of: done) { _, isDone in
            if isDone { Task { await revealResults() } }
        }
    }

    private func reveal() async {
        guard animatesIn else {
            revealed = 5
            if done { resultsShown = AnalysisResults.parts }
            return
        }
        if done {
            await revealResults()
            return
        }
        for beat in [0.15, 0.5, 0.45, 0.4, 0.45] {
            try? await Task.sleep(for: .seconds(beat))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { revealed += 1 }
            Haptics.revealGrain(intensity: 0.45)
        }
    }

    private func revealResults() async {
        guard resultsShown == 0 else { return }
        try? await Task.sleep(for: .seconds(0.25))
        for _ in 0..<AnalysisResults.parts {
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) { resultsShown += 1 }
            Haptics.revealGrain(intensity: 0.4)
            try? await Task.sleep(for: .seconds(0.14))
        }
    }

    private var myth: Myth { Self.questions[0] }

    // MARK: White: while it works (146:5043)

    private var working: some View {
        ZStack(alignment: .topLeading) {
            Self.header("Analyzing", dark: false, onClose: onClose)
                .at(17, 17)
                .arrivingUp(revealed > 0)
            Group {
                Text("Mutual funds analysis")
                    .font(FigmaFont.reckless(37))
                    .lineSpacing(43 - 37 * 1.2)
                    .foregroundStyle(Color.black.opacity(0.93))
                    .frame(width: 342, alignment: .leading)
                    .at(17, 57)
                ResearchTimer(started: started, duration: ResearchSheet.analysisDuration)
                    .at(17, 153)
            }
            .arrivingUp(revealed > 0)

            if Self.asksMyth {
            Text("While it happens")
                .font(FigmaFont.walsheim(27))
                .foregroundStyle(Color(hex: 0x212121))
                .frame(width: Self.width, height: 33)
                .at(0.5, 236)
                .arrivingUp(revealed > 1)

            fundCard
                .at(13, 295)
                .arrivingUp(revealed > 2)

            // The question, then the answer in its place
            Text(myth.question)
                .font(FigmaFont.walsheim(21))
                .lineSpacing(29 - 21 * 1.2)
                .foregroundStyle(Color(hex: 0x212121))
                .multilineTextAlignment(.center)
                .frame(width: 330)
                .at(19, 411)
                .opacity(answer == nil ? 1 : 0)
                .arrivingUp(revealed > 3)

            if let answer {
                Text(answer ? myth.yes : myth.no)
                    .font(FigmaFont.walsheim(19))
                    .lineSpacing(25 - 19 * 1.2)
                    .foregroundStyle(Color(hex: 0x212121))
                    .frame(width: 340, alignment: .leading)
                    .at(13, 411)
                    .transition(.opacity.combined(with: .offset(y: 10)).animation(.easeOut(duration: 0.4).delay(0.2)))
            }

            HStack(spacing: 23) {
                choice("No", icon: "AnswerCross", width: 72, value: false)
                choice("Yes", icon: "AnswerCheck", width: 75, value: true)
            }
            .at(89, 552)
            .opacity(answer == nil ? 1 : 0)
            .scaleEffect(answer == nil ? 1 : 0.9)
            .arrivingUp(revealed > 4)
            .allowsHitTesting(answer == nil && revealed > 4)
            } else {
                // For now: draw a curve and it finds the fund (312:16623)
                CurveGuess()
                    .at(0, 236)
                    .arrivingUp(revealed > 1)
            }
        }
        .frame(width: Self.width, height: Self.whiteHeight, alignment: .topLeading)
    }

    /// "Analyzing" or "Analyzed" (241:13403), Walsheim Medium 23, with a close level with it at the right
    static func header(_ title: String, dark: Bool, onClose: @escaping () -> Void) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .font(FigmaFont.walsheimMedium(23))
                .foregroundStyle(dark ? Color.white : Color.black)
                .frame(height: 29)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6))
                    .frame(width: 29, height: 29)
                    .background(Circle().fill(dark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close analysis")
            .padding(.trailing, -7.5)
        }
        .frame(width: width - 34, height: 29)
    }

    /// The fund in question (148:5173), 342 × 98: a white strip in a wash of colour
    private var fundCard: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 241 / 255, green: 191 / 255, blue: 149 / 255),
                                    Color(red: 200 / 255, green: 185 / 255, blue: 198 / 255)],
                           startPoint: .leading, endPoint: .trailing)
            ZStack(alignment: .topLeading) {
                Color.white
                Image(myth.logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 37, height: 37)
                    .at(12, 16)
                Text(myth.fund)
                    .font(FigmaFont.walsheim(16))
                    .foregroundStyle(Color.black.opacity(0.7))
                    .frame(height: 23)
                    .at(59, 25)
                Color.black.opacity(0.09)
                    .frame(width: 1, height: 72)
                    .at(213, 0)
                // "Rated 5" (146:5159)
                Text(myth.rating)
                    .font(FigmaFont.walsheim(19))
                    .foregroundStyle(Color.black)
                    .fixedSize()
                    .frame(height: 27)
                    .at(227, 16)
            }
            .frame(width: 318, height: 72, alignment: .topLeading)
            .overlay(Rectangle().strokeBorder(Color.black.opacity(0.09), lineWidth: 1))
        }
        .frame(width: 342, height: 98)
    }

    private func choice(_ title: String, icon: String, width: CGFloat, value: Bool) -> some View {
        let shape = Capsule()
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { answer = value }
        } label: {
            HStack(spacing: 4.5) {
                Text(title)
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .fixedSize()
                Image(icon).frame(width: 23, height: 23)
            }
            .padding(.leading, 12)
            .frame(width: width, height: 45, alignment: .leading)
            .background(Color.black)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Black: the analysis (146:4908)

/// What the analysis found, on black: scrolls
private struct AnalysisResults: View {
    /// How many parts have come in: the title, the chip and date, then each section's heading, note and card
    let shown: Int
    var onClose: () -> Void = {}
    var onUnderstood: () -> Void = {}
    static let parts = 5

    private static let note = "Mid and small caps peaked in May and sold off from September; large caps held."
    private static let today: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: .now)
    }()

    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                Group {
                    AnalysisSheet.header("Analyzed", dark: false, onClose: onClose)
                        .at(17, 17)
                    Text("Mutual funds analysis")
                        .font(FigmaFont.reckless(37))
                        .lineSpacing(43 - 37 * 1.2)
                        .foregroundStyle(Color.black.opacity(0.93))
                        .frame(width: 342, alignment: .leading)
                        .at(17, 57)
                }
                .arrivingUp(shown > 0)

                Group {
                    planChip.at(17, 156)
                    Text("Just now • \(Self.today)")
                        .font(FigmaFont.walsheim(13))
                        .foregroundStyle(Color.black.opacity(0.47))
                        .frame(height: 15)
                        .at(17, 216)
                    MorningstarMark()
                        .at(17, 240)
                }
                .arrivingUp(shown > 1)

                section("Fund rank movements", top: 292) { rankCard }
                    .arrivingUp(shown > 2)
                section("Label vs reality", top: 560) { labelCard }
                    .arrivingUp(shown > 3)
                section("Fund managers", top: 910) { managersCard }
                    .arrivingUp(shown > 4)
            }
            // with room at the foot to scroll the last card clear of Understood
            .frame(width: AnalysisSheet.width, height: 1169 + 90, alignment: .topLeading)
        }
        .frame(width: AnalysisSheet.width, height: AnalysisSheet.blackHeight)
        .background(Color.white)
        .overlay(alignment: .bottom) { understood.arrivingUp(shown > 1) }
    }

    /// "Understood", floating at the foot over a soft white fade, 334 × 45, 31pt up
    private var understood: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.white.opacity(0), .white], startPoint: .top, endPoint: .bottom)
                .frame(height: 40)
                .allowsHitTesting(false)
            Button {
                Haptics.tap()
                onUnderstood()
            } label: {
                Text("Understood")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .frame(width: 334, height: 45)
                    .background(Color.black)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 31)
            .background(Color.white)
        }
    }

    /// A section: its heading, a note under it, then its card, 53pt below the heading
    private func section<Card: View>(_ title: String, top: CGFloat, @ViewBuilder card: () -> Card) -> some View {
        ZStack(alignment: .topLeading) {
            Text(title)
                .font(FigmaFont.walsheim(19))
                .foregroundStyle(Color.black)
                .frame(height: 27)
                .at(17, 0)
            Text(Self.note)
                .font(FigmaFont.walsheim(13))
                .lineSpacing(17 - 13 * 1.2)
                .foregroundStyle(Color.black.opacity(0.47))
                .frame(width: 314, alignment: .leading)
                .at(17, 32)
            card()
                .at(15, 85)
        }
        .at(0, top)
    }

    /// "Mutual funds research plan", as it is in the chat (146:4320)
    private var planChip: some View {
        HStack(spacing: 0) {
            Image("PlanDoc").frame(width: 17, height: 17).padding(.leading, 15)
            Text("Mutual funds research plan")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black)
                .fixedSize()
                .padding(.leading, 11)
            Spacer(minLength: 0)
            Image("PlanChevron").frame(width: 23, height: 23).padding(.trailing, 5)
        }
        .frame(width: 283, height: 53)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
        .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
    }

    private func whiteCard<Content: View>(height: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 13, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Color.white
            content()
        }
        .frame(width: 338, height: height, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.black.opacity(0.09), lineWidth: 1))
    }

    private func logo(_ name: String) -> some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 36, height: 39)
            .frame(width: 37, height: 37)
            .clipped()
    }

    private static let hairline = Color.black.opacity(0.09)

    /// Two funds that fell from 5th to 20th in their class (154:6792), 338 × 144
    private var rankCard: some View {
        whiteCard(height: 144) {
            ForEach(Array([("FundNippon", "Nippon India Small Cap"), ("FundQuant", "Quant Small Cap")].enumerated()),
                    id: \.offset) { index, fund in
                let top = CGFloat(index) * 72
                logo(fund.0).at(8, top + 16)
                Text(fund.1)
                    .font(FigmaFont.walsheim(15))
                    .foregroundStyle(Color.black.opacity(0.9))
                    .frame(height: 21)
                    .at(53, top + 15)
                Text("India’s largest small cap")
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(Color.black.opacity(0.47))
                    .frame(height: 21)
                    .at(53, top + 37)
                Self.hairline.frame(width: 1, height: 72).at(218, top)
                Text("5")
                    .font(FigmaFont.walsheim(22))
                    .foregroundStyle(Color.black.opacity(0.6))
                    .frame(height: 31)
                    .at(242, top + 20)
                Image("PlanChevron").frame(width: 23, height: 23).at(262, top + 24)
                Text("20")
                    .font(FigmaFont.walsheimMedium(22))
                    .foregroundStyle(Color.black)
                    .frame(height: 31)
                    .at(289, top + 20)
            }
            Self.hairline.frame(width: 338, height: 1).at(0, 71)
        }
    }

    /// What a flexi cap fund is really holding (154:6813), 338 × 226
    private var labelCard: some View {
        whiteCard(height: 226) {
            logo("FundPPFAS").at(8, 12)
            Text("Parag Parikh Flexi Cap")
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Color.black.opacity(0.9))
                .frame(height: 21)
                .at(53, 21)
            Self.hairline.frame(width: 338, height: 1).at(0, 62)

            allocation("Large cap", share: "63%", bar: 199.08, colour: 0xFFC65A, top: 75)
            allocation("Mid cap", share: "7.95%", bar: 23, colour: 0xECBE9B, top: 109)
            allocation("Small cap", share: "5.95%", bar: 17, colour: 0x93C3D5, top: 147)

            Self.hairline.frame(width: 338, height: 1).at(0, 184)
            source("Verified from August factsheet").at(10, 191)
        }
    }

    private func allocation(_ label: String, share: String, bar: CGFloat, colour: UInt32, top: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color(hex: colour).frame(width: bar, height: 15)
            Text(share)
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Color.black.opacity(0.9))
                .fixedSize()
                .padding(.leading, 10)
            Text(label)
                .font(FigmaFont.walsheimMedium(13))
                .tracking(0.65)
                .textCase(.uppercase)
                .foregroundStyle(Color.black.opacity(0.9))
                .fixedSize()
                .padding(.leading, 10)
        }
        .frame(height: 21)
        .at(10, top - 3)
    }

    private func source(_ text: String) -> some View {
        HStack(spacing: 1) {
            Text(text)
                .font(FigmaFont.walsheim(13))
                .foregroundStyle(Color.black.opacity(0.47))
            Image("SourceChevron").frame(width: 19, height: 19)
        }
        .frame(height: 21)
    }

    /// A change of manager (154:6832), 338 × 134
    private var managersCard: some View {
        whiteCard(height: 134) {
            logo("FundHDFC").at(8, 12)
            Text("HDFC Flexi cap")
                .font(FigmaFont.walsheim(13))
                .foregroundStyle(Color.black.opacity(0.57))
                .frame(height: 19)
                .at(59, 14)
            Text("Roshi Jain out (resigned Nov 2025), Amit Ganatra has joined.")
                .font(FigmaFont.walsheim(15))
                .lineSpacing(21 - 15 * 1.2)
                .foregroundStyle(Color.black.opacity(0.9))
                .frame(width: 262, alignment: .leading)
                .at(59, 34)
            Self.hairline.frame(width: 338, height: 1).at(0, 92)
            source("Effective from Nov 2025").at(58, 99)
        }
    }
}

private extension View {
    /// Comes in from a little below, fading up
    func arrivingUp(_ arrived: Bool) -> some View {
        opacity(arrived ? 1 : 0)
            .offset(y: arrived ? 0 : 14)
    }
}

#Preview {
    AnalysisSheet(started: .now, done: true, answer: .constant(nil))
        .background(Color.black)
}
