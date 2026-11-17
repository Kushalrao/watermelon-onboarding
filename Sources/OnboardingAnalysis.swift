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
    /// The second report, on the user's own funds, once they're in; the first is the report on the topic
    var portfolio = false
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
                Group {
                    if portfolio {
                        AnalysisResults(shown: resultsShown, onClose: onClose, onUnderstood: onUnderstood)
                    } else {
                        ReportResults(shown: resultsShown, onClose: onClose, onAsk: onUnderstood)
                    }
                }
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

// MARK: - The first report (1080:14346)

/// "Equity mutual funds performance 26": the report on the first topic, 368 wide and 4465 long, scrolling. Its
/// header and title, the plan it came from, what happened in short, then the data (industries, categories, and
/// the best and worst fund of each), the read on the year, and at the foot the question that leads on.
private struct ReportResults: View {
    /// How many parts have come in: the title, the chip and date, the summary, the data, the read
    let shown: Int
    var onClose: () -> Void = {}
    /// "How this affects my portfolio?", at the foot
    var onAsk: () -> Void = {}

    private static let today: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: .now)
    }()
    private static let summary = "Most Indian equity fund categories gained over the past year, but returns varied widely. Large-cap funds, which invest mainly in the biggest listed companies, ended close to flat. Mid-cap funds gained 4.68% on average. Small-cap funds, which invest mainly in smaller listed companies, gained 9.66%."
    private static let secondary = Color(hex: 0x645F5F)
    private static let hairline = Color.black.opacity(0.09)

    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                Group {
                    header
                    Text("Equity mutual funds performance 26")
                        .font(FigmaFont.reckless(37))
                        .lineSpacing(43 - 37 * 1.2)
                        .foregroundStyle(Color.black.opacity(0.93))
                        .frame(width: 342, alignment: .leading)
                        .at(17, 80)
                }
                .arrivingUp(shown > 0)

                Group {
                    planChip.at(17, 179)
                    Text("Just now • \(Self.today)")
                        .font(FigmaFont.walsheim(13))
                        .foregroundStyle(Color.black.opacity(0.97))
                        .frame(height: 15)
                        .at(17, 243)
                }
                .arrivingUp(shown > 1)

                Group {
                    // 1107:14893: the year in short, a rule down its left
                    Color.black.opacity(0.13).frame(width: 1, height: 215).at(17, 326)
                    Text(Self.summary)
                        .font(FigmaFont.recklessRegular(19))
                        .lineSpacing(27 - 19 * 1.2)
                        .foregroundStyle(Color(hex: 0x282424))
                        .frame(width: 319, alignment: .leading)
                        .at(32, 325)
                }
                .arrivingUp(shown > 2)

                Group {
                    dataHeading.at(17, 588)
                    versusCard.at(17, 738)
                    // 1114:15989: what the chart leaves out
                    Text("Over six months equity did roughly 2.5x debt and 1.8x hybrid, but on one year debt actually beat equity (4.4% vs 2.8%) because of the September crash, and the metals that led for three years lost a quarter of their value in six months. The 3-year column is the one that matches the long-run pattern: equity ~12%, hybrid -9%, debt ~ 6.5%.")
                        .font(FigmaFont.walsheim(13))
                        .lineSpacing(21 - 13 * 1.2)
                        .foregroundStyle(Color(hex: 0x787373))
                        .frame(width: 330, alignment: .leading)
                        .at(19, 1087)
                    data.at(17, 1273)
                }
                .arrivingUp(shown > 3)

                Group {
                    Text("Our read on the year")
                        .font(FigmaFont.reckless(35))
                        .foregroundStyle(Color(hex: 0x33302D))
                        .frame(height: 43)
                        .at(17, 3421)
                    read("Would last years results help you pick next year’s winner?", top: 3491)
                    read("What happened in the market this week?", top: 3830)
                    askChip.at(24, 4389)
                }
                .arrivingUp(shown > 4)
            }
            .frame(width: AnalysisSheet.width, height: 4465, alignment: .topLeading)
        }
        .frame(width: AnalysisSheet.width, height: AnalysisSheet.blackHeight)
        .background(Color.white)
    }

    /// "Report" and its mark (1080:14415), the close (1080:14421), and the rule under them
    private var header: some View {
        ZStack(alignment: .topLeading) {
            Image("ReportIcon").frame(width: 24.92, height: 21).at(19, 15)
            Text("Report")
                .font(FigmaFont.walsheimMedium(19))
                .foregroundStyle(Color.black)
                .frame(height: 29)
                .at(55, 11)
            Button(action: onClose) {
                Image("ReportClose")
                    .frame(width: 27, height: 27)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close analysis")
            .at(322 - 8.5, 12 - 8.5)
            Color.black.opacity(0.09).frame(width: 330, height: 1).at(19, 50.5)
        }
    }

    /// "Mutual funds research plan" (1080:14406), 283 × 53, greyed
    private var planChip: some View {
        HStack(spacing: 0) {
            Image("PlanDoc").frame(width: 17, height: 17).padding(.leading, 17)
            Text("Mutual funds research plan")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black)
                .fixedSize()
                .padding(.leading, 9)
            Spacer(minLength: 0)
            Image("PlanChevron").frame(width: 23, height: 23).padding(.trailing, 7)
        }
        .frame(width: 283, height: 53)
        .background(Color.black.opacity(0.04))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.black.opacity(0.13), lineWidth: 2))
    }

    /// "Performance data that we have found: Data from Morningstar" (1111:15159), the mark before its name
    private var dataHeading: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(["Performance data that we", "have found: Data from"].enumerated()), id: \.offset) { index, line in
                Text(line).fixedSize().frame(height: 39).at(0, CGFloat(index) * 39)
            }
            Image("ReportMorningstar").resizable().frame(width: 30, height: 31).at(0, 85)
            Text("Morningstar").fixedSize().frame(height: 39).at(38, 78)
        }
        .font(FigmaFont.recklessRegular(27))
        .foregroundStyle(Color(hex: 0x33302D))
        .frame(width: 334, height: 117, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Performance data that we have found: Data from Morningstar")
    }

    // MARK: Equity funds vs others (1114:15914), 334 × 334

    private static let versus: [(name: String, value: String, height: CGFloat)] = [
        ("Debt\nfunds", "+2.7%", 43), ("Hybrid\nfunds", "+4.0%", 88), ("Index\nfunds", "+6.8%", 156), ("Equity\nfunds", "+7.1%", 181),
    ]

    /// Four kinds of fund as columns on a scale of 0 to 8, equity's filled green; they rise once the card is seen
    private var versusCard: some View {
        let shape = RoundedRectangle(cornerRadius: 13, style: .continuous)
        return SeenOnce { seen in
            ZStack(alignment: .topLeading) {
                Color.white
                Text("Equity funds vs others")
                    .font(FigmaFont.walsheimMedium(19))
                    .foregroundStyle(Color(hex: 0x212121))
                    .fixedSize()
                    .frame(height: 27)
                    .at(13, 13)
                ZStack(alignment: .topLeading) {
                    ForEach(Array([(89.0, 0.05), (112.0, 0.05), (152.0, 0.05), (192.0, 0.05), (209.0, 0.05)].enumerated()), id: \.offset) { _, line in
                        Color.black.opacity(line.1).frame(width: 338, height: 1).at(-5, line.0 - 0.5)
                    }
                    ForEach(Array(Self.versus.enumerated()), id: \.offset) { index, column in
                        let x = 15 + CGFloat(index) * 79
                        let last = index == Self.versus.count - 1
                        let height = seen ? column.height : 0
                        Rectangle()
                            .fill(last ? Color(hex: 0x3FD519) : Color.white)
                            .overlay(Rectangle().strokeBorder(Color(hex: 0x8D8888), lineWidth: last ? 0 : 1))
                            .frame(width: 43, height: height)
                            .at(x, 209 - height)
                        Text(column.value)
                            .font(FigmaFont.walsheimMedium(15))
                            .tracking(0.45)
                            .foregroundStyle(Color.black.opacity(0.9))
                            .fixedSize()
                            .frame(width: 79, height: 21)
                            .at(x - 18, 209 - height - 24)
                        Text(column.name)
                            .font(FigmaFont.walsheim(12))
                            .tracking(0.84)
                            .lineSpacing(17 - 12 * 1.2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.black.opacity(0.6))
                            .frame(width: 79, height: 34)
                            .at(x - 18, 224)
                    }
                    ForEach(Array([("8", 8.0), ("5", 72.0), ("3", 136.0), ("0", 200.0)].enumerated()), id: \.offset) { _, tick in
                        Text(tick.0)
                            .font(FigmaFont.walsheim(12))
                            .tracking(0.84)
                            .foregroundStyle(Color.black.opacity(0.4))
                            .frame(width: 20, height: 17)
                            .at(305.5, tick.1)
                    }
                }
                .frame(width: 333, height: 241, alignment: .topLeading)
                .at(0, 57)
            }
            .frame(width: 334, height: 334, alignment: .topLeading)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color(hex: 0xDFDCDA), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
        }
    }

    // MARK: The data (1111:15158), 334 × 2069

    private static let industries: [(icon: String, name: String, value: String, bar: CGFloat, colour: UInt32)] = [
        ("ReportHealthcare", "Healthcare", "+20.05%", 61, 0x3FD519),
        ("ReportTechnology", "Technology", "-7.51%", -22, 0xFFA99C),
        ("ReportConsumer", "Consumer", "-19.62%", -53, 0xFF6E5F),
    ]
    private static let categories: [(name: String, value: String, bar: CGFloat, colour: UInt32)] = [
        ("Small cap", "+9.66%", 61, 0x3FD519),
        ("Mid cap", "+5.11%", 37, 0x7CE469),
        ("Multi cap", "+4.68%", 32, 0x7CE469),
        ("Flexi cap", "+3.73%", 25, 0xC6F8BD),
        ("Large & mid cap", "+3.06%", 25, 0xC6F8BD),
        ("Large cap", "+0.31%", 2, 0xDBD213),
    ]

    private var data: some View {
        ZStack(alignment: .topLeading) {
            heading("Industry focused funds performance").at(2, 0)
            table("Industry", height: 182) { seen in
                ForEach(Array(Self.industries.enumerated()), id: \.offset) { index, row in
                    let y = 66 + CGFloat(index) * 40
                    Image(row.icon).frame(width: 17, height: 17).at(13, y + 2)
                    rowLabel(row.name).at(34, y)
                    bar(row.bar, colour: row.colour, grown: seen).at(row.bar < 0 ? 172 + row.bar : 172, y + 3)
                    rowValue(row.value).at(row.bar < 0 ? 183 : 172 + row.bar + 11, y)
                }
            }
            .at(0, 46)

            heading("Scheme categories performance").at(2, 261)
            note("Value after one year at the average return for each type of fund").at(2, 293)
            table("Fund type", height: 302) { seen in
                ForEach(Array(Self.categories.enumerated()), id: \.offset) { index, row in
                    let y = 66 + CGFloat(index) * 40
                    rowLabel(row.name).at(19, y)
                    bar(row.bar, colour: row.colour, grown: seen).at(172, y + 3)
                    rowValue(row.value).at(172 + row.bar + 11, y)
                }
            }
            .at(0, 346)
            HStack(spacing: 1) {
                Text("Fund data from MorningStar")
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(Color.black.opacity(0.47))
                Image("SourceChevron").frame(width: 19, height: 19)
            }
            .frame(height: 21)
            .at(0, 659)

            heading("How much did fund selection matter?").at(0, 738)
            note("In small-caps alone, ₹10,000 ended the year between ₹9,208 and ₹12,658, a gap of ₹3,450. Which fund an investor held mattered as much as which category.")
                .at(2, 770)
            // 1107:14682 onwards: six of them, each the category's name over its best and worst fund
            ForEach(0..<6, id: \.self) { index in
                let y = 854 + CGFloat(index) * 207
                Text("Small Cap")
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color(hex: 0x282424))
                    .frame(width: 334, height: 25)
                    .at(0, y)
                spread.at(0, y + 36)
            }
        }
        .frame(width: 334, height: 2069, alignment: .topLeading)
    }

    private func heading(_ text: String) -> some View {
        Text(text)
            .font(FigmaFont.walsheimMedium(19))
            .foregroundStyle(Color.black)
            .fixedSize()
            .frame(height: 27)
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(FigmaFont.walsheim(13))
            .lineSpacing(17 - 13 * 1.2)
            .foregroundStyle(Color.black.opacity(0.47))
            .frame(width: 314, alignment: .leading)
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text)
            .font(FigmaFont.walsheim(15))
            .foregroundStyle(Self.secondary)
            .fixedSize()
            .frame(height: 21)
    }

    private func rowValue(_ text: String) -> some View {
        Text(text)
            .font(FigmaFont.walsheim(15))
            .tracking(0.45)
            .foregroundStyle(Color.black.opacity(0.9))
            .fixedSize()
            .frame(height: 21)
    }

    /// A bar, grown out from the axis (rightward, or leftward for a loss) once its table has been seen
    private func bar(_ width: CGFloat, colour: UInt32, grown: Bool) -> some View {
        Color(hex: colour)
            .frame(width: grown ? abs(width) : 0, height: 15)
            .frame(width: abs(width), height: 15, alignment: width < 0 ? .trailing : .leading)
    }

    private func card<Content: View>(height: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 13, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Color.white
            content()
        }
        .frame(width: 334, height: height, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Self.hairline, lineWidth: 1))
    }

    /// A table (1098:14599, 1098:14514): what's listed and "Average return" over a rule, then its rows, 40pt apart
    private func table<Rows: View>(_ first: String, height: CGFloat, @ViewBuilder rows: @escaping (Bool) -> Rows) -> some View {
        SeenOnce { seen in card(height: height) {
            ForEach(Array([(first, 17.0), ("Average return", 172.0)].enumerated()), id: \.offset) { _, column in
                Text(column.0)
                    .font(FigmaFont.walsheimMedium(15))
                    .foregroundStyle(Color.black.opacity(0.9))
                    .fixedSize()
                    .frame(height: 21)
                    .at(column.1, 15)
            }
            Self.hairline.frame(width: 334, height: 1).at(0, 50.5)
            rows(seen)
        } }
    }

    /// A category's best and worst fund (1107:14660), 334 × 144: logo, name, the year's line, and the return
    private var spread: some View {
        SeenOnce { seen in card(height: 144) {
            ForEach(Array([("FundNippon", "Nippon India Small Cap", "ReportTrendUp", "+26.58%", 0x00A800 as UInt32, 16.0),
                           ("FundHDFC", "HDFC Small Cap Fund", "ReportTrendDown", "-7.92%", 0xF0453A, 14.0)].enumerated()),
                    id: \.offset) { index, fund in
                let top = CGFloat(index) * 72
                Image(fund.0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 43)
                    .frame(width: 37, height: 37)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .at(13, top + 17)
                Text(fund.1)
                    .font(FigmaFont.walsheim(15))
                    .lineSpacing(21 - 15 * 1.2)
                    .foregroundStyle(Self.secondary)
                    .frame(width: 129, alignment: .leading)
                    .at(59, top + 15)
                Self.hairline.frame(width: 1, height: 72).at(194.5, top)
                Image(fund.2)
                    .frame(width: 33, height: 27)
                    // drawn in from its start once the card has been seen
                    .mask(alignment: .leading) { Rectangle().frame(width: seen ? 33 : 0) }
                    .at(205, top + fund.5)
                Text(fund.3)
                    .font(FigmaFont.walsheimMedium(19))
                    .foregroundStyle(Color(hex: fund.4))
                    .fixedSize()
                    .frame(width: 100, height: 27, alignment: .trailing)
                    .at(221, top + fund.5)
            }
            Self.hairline.frame(width: 334, height: 1).at(0, 71.5)
        } }
    }

    // MARK: The read (1107:14887 onwards)

    private func read(_ question: String, top: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Text(question)
                .font(FigmaFont.walsheimMedium(19))
                .lineSpacing(27 - 19 * 1.2)
                .foregroundStyle(Color.black)
                .frame(width: 334, alignment: .leading)
            Text(Self.summary)
                .font(FigmaFont.walsheim(19))
                .lineSpacing(27 - 19 * 1.2)
                .foregroundStyle(Self.secondary)
                .frame(width: 334, alignment: .leading)
                .at(0, 69)
        }
        .at(17, top)
    }

    /// "How this affects my portfolio?" (1114:15906), 321 × 53, dark: the way on from the report
    private var askChip: some View {
        Button {
            Haptics.tap()
            onAsk()
        } label: {
            HStack(spacing: 0) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.white)
                    .frame(width: 25, height: 23)
                Text("How this affects my portfolio?")
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color.white)
                    .fixedSize()
                    .padding(.leading, 7)
                Spacer(minLength: 0)
                Image("OnboardingTopicArrowWhite").frame(width: 23, height: 23)
            }
            .padding(.horizontal, 17)
            .frame(width: 321, height: 53)
            .background(Color(hex: 0x2C2825))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("How this affects my portfolio?")
    }
}

/// Tells its content when it has scrolled into view, the first time only, so a graph can grow into place once
private struct SeenOnce<Content: View>: View {
    @ViewBuilder let content: (Bool) -> Content
    @State private var seen = false

    var body: some View {
        content(seen)
            .onScrollVisibilityChange(threshold: 0.6) { visible in
                guard visible, !seen else { return }
                withAnimation(.spring(response: 0.9, dampingFraction: 0.86)) { seen = true }
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
