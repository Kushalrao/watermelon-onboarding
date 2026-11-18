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
    /// The finished sheet's height; the first report gives some up to the suggestion that comes out under it
    var doneHeight: CGFloat = AnalysisSheet.blackHeight
    /// The first report is being read: it has been scrolled a little way
    var onRead: () -> Void = {}
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
                        ReportResults(content: .portfolio, shown: resultsShown, onUnderstood: onUnderstood, onClose: onClose)
                    } else {
                        ReportResults(content: .equityYear, shown: resultsShown, height: doneHeight, onClose: onClose, onRead: onRead)
                    }
                }
                    .transition(.opacity.animation(.easeOut(duration: 0.35).delay(0.15)))
            }
        }
        .frame(width: Self.width, height: done ? doneHeight : Self.whiteHeight, alignment: .topLeading)
        .onAppear {
            // Back again: all there from its first frame
            guard !animatesIn else { return }
            revealed = 5
            if done { resultsShown = ReportResults.parts }
        }
        .task { await reveal() }
        .onChange(of: done) { _, isDone in
            if isDone { Task { await revealResults() } }
        }
    }

    private func reveal() async {
        guard animatesIn else {
            revealed = 5
            if done { resultsShown = ReportResults.parts }
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
        for _ in 0..<ReportResults.parts {
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

// MARK: - The reports (1080:14346)

/// What a report says: the first, on the topic that was asked about, and the one on the user's own funds
struct ReportContent {
    struct Column {
        let name, value: String
        let height: CGFloat
        var filled = false
    }
    struct Row {
        var icon: String?
        let name, value: String
        /// Its bar's length; leftward from the axis when negative
        let bar: CGFloat
        let colour: UInt32
    }
    /// `logo` is one of our fund marks, or the fund house's site
    struct Fund {
        let logo, name, value: String
        let up: Bool
    }
    struct Spread {
        let label: String
        let best, worst: Fund
    }

    let title, chip, summary: String
    /// "Performance data that we have found: Data from", in its two lines, then whose data and their mark
    let headingLines: [String]
    let sourceName, sourceLogo: String
    let chartTitle: String
    let columns: [Column]
    /// The scale's four marks, top down
    let ticks: [String]
    let chartNote: String
    let firstTitle, firstColumn: String
    var firstValues = "Average return"
    let firstRows: [Row]
    let secondTitle, secondNote, secondColumn: String
    var secondValues = "Average return"
    let secondRows: [Row]
    let source: String
    let spreadTitle, spreadNote: String
    let spreads: [Spread]
    let readTitle: String
    let reads: [Read]

    /// A question and its answer, and where the answer comes from when that's said under it
    struct Read {
        let question, answer: String
        var credit: String?
    }
}

extension ReportContent {
    private static let yearInShort = "Most Indian equity fund categories gained over the past year, but returns varied widely. Large-cap funds, which invest mainly in the biggest listed companies, ended close to flat. Mid-cap funds gained 4.68% on average. Small-cap funds, which invest mainly in smaller listed companies, gained 9.66%."

    /// "Equity mutual funds performance 26" (1080:14346)
    static let equityYear = ReportContent(
        title: "Equity mutual funds performance 26",
        chip: "Mutual funds research plan",
        summary: yearInShort,
        headingLines: ["Performance data that we", "have found: Data from"], sourceName: "Morningstar", sourceLogo: "ReportMorningstar",
        chartTitle: "Equity funds vs others",
        columns: [Column(name: "Debt\nfunds", value: "+2.7%", height: 43), Column(name: "Hybrid\nfunds", value: "+4.0%", height: 88),
                  Column(name: "Index\nfunds", value: "+6.8%", height: 156), Column(name: "Equity\nfunds", value: "+7.1%", height: 181, filled: true)],
        ticks: ["8", "5", "3", "0"],
        chartNote: "Over six months equity did roughly 2.5x debt and 1.8x hybrid, but on one year debt actually beat equity (4.4% vs 2.8%) because of the September crash, and the metals that led for three years lost a quarter of their value in six months. The 3-year column is the one that matches the long-run pattern: equity ~12%, hybrid -9%, debt ~ 6.5%.",
        firstTitle: "Industry focused funds performance", firstColumn: "Industry",
        firstRows: [Row(icon: "ReportHealthcare", name: "Healthcare", value: "+20.05%", bar: 61, colour: 0x3FD519),
                    Row(icon: "ReportTechnology", name: "Technology", value: "-7.51%", bar: -22, colour: 0xFFA99C),
                    Row(icon: "ReportConsumer", name: "Consumer", value: "-19.62%", bar: -53, colour: 0xFF6E5F)],
        secondTitle: "Scheme categories performance",
        secondNote: "Value after one year at the average return for each type of fund", secondColumn: "Fund type",
        secondRows: [Row(name: "Small cap", value: "+9.66%", bar: 61, colour: 0x3FD519),
                     Row(name: "Mid cap", value: "+5.11%", bar: 37, colour: 0x7CE469),
                     Row(name: "Multi cap", value: "+4.68%", bar: 32, colour: 0x7CE469),
                     Row(name: "Flexi cap", value: "+3.73%", bar: 25, colour: 0xC6F8BD),
                     Row(name: "Large & mid cap", value: "+3.06%", bar: 25, colour: 0xC6F8BD),
                     Row(name: "Large cap", value: "+0.31%", bar: 2, colour: 0xDBD213)],
        source: "Fund data from MorningStar",
        spreadTitle: "How much did fund selection matter?",
        spreadNote: "In small caps alone, ₹10,000 ended the year between ₹9,520 and ₹12,371, a gap of ₹2,851. Which fund an investor held mattered as much as which category.",
        // Advisorkhoj trailing returns, regular growth plans, as on 16 Nov 2026: each category's strongest and weakest
        spreads: [
            Spread(label: "Small cap", best: Fund(logo: "boimf.in", name: "Bank of India Small Cap", value: "+23.71%", up: true),
                   worst: Fund(logo: "FundHDFC", name: "HDFC Small Cap Fund", value: "-4.80%", up: false)),
            Spread(label: "Mid cap", best: Fund(logo: "assetmanagement.hsbc.co.in", name: "HSBC Midcap Fund", value: "+14.65%", up: true),
                   worst: Fund(logo: "franklintempletonindia.com", name: "Franklin India Mid Cap", value: "-1.49%", up: false)),
            Spread(label: "Multi cap", best: Fund(logo: "growwmf.in", name: "Groww Multicap Fund", value: "+14.08%", up: true),
                   worst: Fund(logo: "FundHDFC", name: "HDFC Multi Cap Fund", value: "-2.56%", up: false)),
            Spread(label: "Flexi cap", best: Fund(logo: "itiamc.com", name: "ITI Flexi Cap Fund", value: "+13.51%", up: true),
                   worst: Fund(logo: "samcomf.com", name: "Samco Flexi Cap Fund", value: "-7.34%", up: false)),
            Spread(label: "Large & mid cap", best: Fund(logo: "invescomutualfund.com", name: "Invesco India Large & Mid Cap", value: "+12.49%", up: true),
                   worst: Fund(logo: "tatamutualfund.com", name: "Tata Large & Mid Cap", value: "-7.27%", up: false)),
            Spread(label: "Large cap", best: Fund(logo: "taurusmutualfund.com", name: "Taurus Large Cap Fund", value: "+11.37%", up: true),
                   worst: Fund(logo: "samcomf.com", name: "Samco Large Cap Fund", value: "-3.56%", up: false)),
        ],
        readTitle: "Our read on the year",
        // 1118:16027
        reads: [Read(question: "Would last years results help you pick next year’s winner?",
                     answer: "Decade ranked funds by their returns over three years, then checked where the same funds finished over the next three. For funds buying shares in large companies, knowing who led the first time told us little about who would lead next. We found much the same for funds investing in mid-sized companies."),
                Read(question: "What about other funds?",
                     answer: "Among the small-company funds we studied, earlier winners tended to slip down the list. Among funds free to buy companies of any size, earlier winners were somewhat more likely to stay ahead. We studied 12 to 32 funds of each kind. That gives us a reason to question last year’s rankings. It leaves plenty of uncertainty about next year.",
                     credit: "From Decade Research"),
                Read(question: "What else does Decade look at in a fund?",
                     answer: "We looked at what happened when share prices fell. During the biggest fall we found, ₹10,000 invested at the high would have shrunk to ₹6,910 at the low. The fund fell harder than most other funds investing in small companies.\nThe fund charged lower fees than most similar funds. Over the period we studied, it also earned more than a low-cost fund that tracks the small-company market.\n\nDecade’s rating was Neutral, 2.5 out of 5. The fees and returns counted in its favour. The size of its losses counted against it. We also had a concern about how much money it managed. As a fund grows, it can get harder to buy enough shares in small companies.")]
    )

    /// The report on the user's own four funds. One-year returns are real, as on 16 Nov 2026 (Advisorkhoj; Groww for
    /// Axis's direct plan); the amounts are an assumed portfolio worth about ₹31 lakh, as nothing real is imported:
    /// Kotak Large Cap ₹11,00,000 at -0.17%, Axis Ultra Short Term ₹9,00,000 at 6.7%, HDFC Short Term ₹6,00,000 at
    /// 4.29%, ICICI Pru Gold ETF FOF ₹4,00,000 at 5.77%: ₹30,00,000 invested, ₹1,07,250 gained, ₹31,07,250 now.
    static let portfolio = ReportContent(
        title: "Your mutual funds performance 26",
        chip: "Your MFCentral statement",
        summary: "\(AppUser.name), your portfolio is worth ₹31,07,250 today. Your four funds gained ₹1,07,250 over the past year, about 3.6% on the ₹30,00,000 you had invested. Your debt and gold funds finished a little ahead of similar funds. Kotak Large Cap ended slightly down.",
        headingLines: ["How your four funds", "have done: Data from"], sourceName: "MFCentral", sourceLogo: "MFCentralLogo",
        chartTitle: "Your funds this year",
        columns: [Column(name: "Kotak\nLarge Cap", value: "-0.2%", height: 2), Column(name: "HDFC\nShort Term", value: "+4.3%", height: 103),
                  Column(name: "ICICI\nGold FOF", value: "+5.8%", height: 139), Column(name: "Axis\nUltra Short", value: "+6.7%", height: 162, filled: true)],
        ticks: ["8", "5", "3", "0"],
        chartNote: "One-year returns to 16 November 2026, for the plans you hold. Your two debt funds did what they are meant to do, steady single digits. Gold added 5.77% after its run of the last three years. Kotak Large Cap is your only equity fund, and it finished at -0.17% in a year when the average large-cap fund made 0.96%.",
        firstTitle: "Your funds against similar funds", firstColumn: "Fund", firstValues: "Against average",
        firstRows: [Row(name: "Axis Ultra Short", value: "+0.20%", bar: 10, colour: 0x3FD519),
                    Row(name: "HDFC Short Term", value: "+0.19%", bar: 10, colour: 0x7CE469),
                    Row(name: "ICICI Gold FOF", value: "+0.07%", bar: 4, colour: 0xC6F8BD),
                    Row(name: "Kotak Large Cap", value: "-1.13%", bar: -28, colour: 0xFF6E5F)],
        secondTitle: "Where your money is",
        secondNote: "Share of the ₹30,00,000 you had invested, by type of fund", secondColumn: "Fund type", secondValues: "Share",
        secondRows: [Row(name: "Large cap", value: "36.7%", bar: 61, colour: 0xFFC65A),
                     Row(name: "Ultra short debt", value: "30.0%", bar: 50, colour: 0xECBE9B),
                     Row(name: "Short term debt", value: "20.0%", bar: 33, colour: 0x93C3D5),
                     Row(name: "Gold", value: "13.3%", bar: 22, colour: 0xDBD213)],
        source: "Returns from Advisorkhoj and Groww, 16 Nov",
        spreadTitle: "Strongest and weakest of each kind",
        spreadNote: "For each kind of fund you hold, the best and the worst one-year return among similar funds. Yours made -0.17% (Kotak), 6.7% (Axis, direct plan), 4.29% (HDFC) and 5.77% (ICICI).",
        spreads: [
            Spread(label: "Large cap", best: Fund(logo: "taurusmutualfund.com", name: "Taurus Large Cap Fund", value: "+11.37%", up: true),
                   worst: Fund(logo: "samcomf.com", name: "Samco Large Cap Fund", value: "-3.56%", up: false)),
            Spread(label: "Ultra short duration", best: Fund(logo: "barodabnpparibasmf.in", name: "Baroda BNP Paribas Ultra Short", value: "+6.38%", up: true),
                   worst: Fund(logo: "sundarammutual.com", name: "Sundaram Ultra Short Term", value: "+2.31%", up: false)),
            Spread(label: "Short duration", best: Fund(logo: "bandhanmutual.com", name: "Bandhan Short Term Fund", value: "+5.19%", up: true),
                   worst: Fund(logo: "miraeassetmf.co.in", name: "Mirae Asset Short Term", value: "+3.33%", up: false)),
            Spread(label: "Gold funds", best: Fund(logo: "invescomutualfund.com", name: "Invesco India Gold ETF FOF", value: "+6.32%", up: true),
                   worst: Fund(logo: "growwmf.in", name: "Groww Gold ETF FOF", value: "+5.01%", up: false)),
        ],
        readTitle: "Our read on your year",
        reads: [Read(question: "Which fund helped most, and which held you back?",
                 answer: "Axis Ultra Short Term added the most, about ₹60,300 on ₹9,00,000. Kotak Large Cap held you back: it ended ₹1,870 down, where the average large-cap fund would have made about ₹10,560 on the same money."),
                Read(question: "Should one weak year worry you?",
                 answer: "Not by itself. Large-cap funds as a group made under 1% this year, so most of Kotak’s result is the market it invests in. What is worth watching is where it stood among similar funds: its regular plan ranked 30th of 34. If that repeats over a longer period, it is a reason to look again.")]
    )
}


/// A report, 368 wide and long, scrolling: its header and title, where it came from, what happened in short, then
/// the data (a chart, two tables, and the strongest and weakest fund of each category) and the read on it.
private struct ReportResults: View {
    let content: ReportContent
    /// How many parts have come in: the title, the chip and date, the summary, the data, the read
    let shown: Int
    static let parts = 5
    /// "Understood", floating at the foot; the report on the user's own funds ends the chat with it
    var onUnderstood: (() -> Void)?
    /// The sheet's height, which shrinks when the suggestion comes out under it
    var height: CGFloat = AnalysisSheet.blackHeight
    var onClose: () -> Void = {}
    /// Scrolled a little way in: it's being read
    var onRead: () -> Void = {}

    private static let today: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: .now)
    }()
    private static let secondary = Color(hex: 0x645F5F)
    private static let hairline = Color.black.opacity(0.09)

    // Where things sit: the tables and the cards under them take the height their rows need
    private var firstHeight: CGFloat { 62 + CGFloat(content.firstRows.count) * 40 }
    private var secondHeight: CGFloat { 62 + CGFloat(content.secondRows.count) * 40 }
    private var secondTop: CGFloat { 46 + firstHeight + 33 }
    private var sourceTop: CGFloat { secondTop + 85 + secondHeight + 11 }
    private var spreadTop: CGFloat { sourceTop + 79 }
    private var dataHeight: CGFloat { spreadTop + 116 + CGFloat(content.spreads.count) * 207 - 63 }
    private var readTop: CGFloat { 1273 + dataHeight + 79 }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    Group {
                        header
                        Text(content.title)
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
                        Text(content.summary)
                            .font(FigmaFont.recklessRegular(19))
                            .lineSpacing(27 - 19 * 1.2)
                            .foregroundStyle(Color(hex: 0x282424))
                            .frame(width: 319, height: 216, alignment: .topLeading)
                            .at(32, 325)
                    }
                    .arrivingUp(shown > 2)

                    Group {
                        dataHeading.at(17, 588)
                        versusCard.at(17, 738)
                        // 1114:15989: what the chart leaves out
                        Text(content.chartNote)
                            .font(FigmaFont.walsheim(13))
                            .lineSpacing(21 - 13 * 1.2)
                            .foregroundStyle(Color(hex: 0x787373))
                            .frame(width: 330, height: 147, alignment: .topLeading)
                            .at(19, 1087)
                        data.at(17, 1273)
                    }
                    .arrivingUp(shown > 3)

                    Text(content.readTitle)
                        .font(FigmaFont.reckless(35))
                        .foregroundStyle(Color(hex: 0x33302D))
                        .frame(height: 43)
                        .at(17, readTop)
                        .arrivingUp(shown > 4)
                }
                .frame(width: AnalysisSheet.width, height: readTop + 70, alignment: .topLeading)

                // 1118:16027: each question and its answer, 21 apart, and 48 after one that says where it's from
                VStack(alignment: .leading, spacing: 21) {
                    ForEach(Array(content.reads.enumerated()), id: \.offset) { _, item in
                        read(item).padding(.bottom, item.credit == nil ? 0 : 27)
                    }
                }
                .padding(.leading, 17)
                // with room at the foot to scroll the last of it clear of Understood
                .padding(.bottom, onUnderstood == nil ? 30 : 120)
                .arrivingUp(shown > 4)
            }
        }
        // 100pt in, it is being read
        .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y >= 100 } action: { _, reading in
            if reading { onRead() }
        }
        .frame(width: AnalysisSheet.width, height: height)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            if let onUnderstood { understood(onUnderstood).arrivingUp(shown > 1) }
        }
    }

    /// "Understood", floating at the foot over a soft white fade, 334 × 45, 31pt up
    private func understood(_ action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.white.opacity(0), .white], startPoint: .top, endPoint: .bottom)
                .frame(height: 40)
                .allowsHitTesting(false)
            Button {
                Haptics.tap()
                action()
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
            Text(content.chip)
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
            ForEach(Array(content.headingLines.enumerated()), id: \.offset) { index, line in
                Text(line).fixedSize().frame(height: 39).at(0, CGFloat(index) * 39)
            }
            Image(content.sourceLogo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 31)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .at(0, 85)
            Text(content.sourceName).fixedSize().frame(height: 39).at(38, 78)
        }
        .font(FigmaFont.recklessRegular(27))
        .foregroundStyle(Color(hex: 0x33302D))
        .frame(width: 334, height: 117, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel((content.headingLines + [content.sourceName]).joined(separator: " "))
    }

    // MARK: Equity funds vs others (1114:15914), 334 × 334

    /// Four kinds of fund as columns on a scale of 0 to 8, equity's filled green; they rise once the card is seen
    private var versusCard: some View {
        let shape = RoundedRectangle(cornerRadius: 13, style: .continuous)
        return SeenOnce { seen in
            ZStack(alignment: .topLeading) {
                Color.white
                Text(content.chartTitle)
                    .font(FigmaFont.walsheimMedium(19))
                    .foregroundStyle(Color(hex: 0x212121))
                    .fixedSize()
                    .frame(height: 27)
                    .at(13, 13)
                ZStack(alignment: .topLeading) {
                    ForEach(Array([(89.0, 0.05), (112.0, 0.05), (152.0, 0.05), (192.0, 0.05), (209.0, 0.05)].enumerated()), id: \.offset) { _, line in
                        Color.black.opacity(line.1).frame(width: 338, height: 1).at(-5, line.0 - 0.5)
                    }
                    ForEach(Array(content.columns.enumerated()), id: \.offset) { index, column in
                        let x = 15 + CGFloat(index) * 79
                        let last = column.filled
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
                    ForEach(Array(zip(content.ticks, [8.0, 72.0, 136.0, 200.0]).enumerated()), id: \.offset) { _, tick in
                        Text(tick.0)
                            .font(FigmaFont.walsheim(12))
                            .tracking(0.84)
                            .foregroundStyle(Color.black.opacity(0.4))
                            .fixedSize()
                            .frame(width: 30, height: 17)
                            .at(300.5, tick.1)
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

    private var data: some View {
        ZStack(alignment: .topLeading) {
            heading(content.firstTitle).at(2, 0)
            table(content.firstColumn, content.firstValues, height: firstHeight) { seen in
                ForEach(Array(content.firstRows.enumerated()), id: \.offset) { index, row in
                    tableRow(row, at: 66 + CGFloat(index) * 40, seen: seen)
                }
            }
            .at(0, 46)

            heading(content.secondTitle).at(2, secondTop)
            note(content.secondNote).at(2, secondTop + 32)
            table(content.secondColumn, content.secondValues, height: secondHeight) { seen in
                ForEach(Array(content.secondRows.enumerated()), id: \.offset) { index, row in
                    tableRow(row, at: 66 + CGFloat(index) * 40, seen: seen)
                }
            }
            .at(0, secondTop + 85)
            HStack(spacing: 1) {
                Text(content.source)
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(Color.black.opacity(0.47))
                Image("SourceChevron").frame(width: 19, height: 19)
            }
            .frame(height: 21)
            .at(0, sourceTop)

            heading(content.spreadTitle).at(0, spreadTop)
            note(content.spreadNote).at(2, spreadTop + 32)
            // 1107:14682 onwards: each category's name over its strongest and weakest fund
            ForEach(Array(content.spreads.enumerated()), id: \.offset) { index, item in
                let y = spreadTop + 116 + CGFloat(index) * 207
                Text(item.label)
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color(hex: 0x282424))
                    .frame(width: 334, height: 25)
                    .at(0, y)
                spread(item).at(0, y + 36)
            }
        }
        .frame(width: 334, height: dataHeight, alignment: .topLeading)
    }

    /// A row: its icon if it has one, its name, and its bar out from the axis with the figure beside it
    @ViewBuilder private func tableRow(_ row: ReportContent.Row, at y: CGFloat, seen: Bool) -> some View {
        if let icon = row.icon {
            Image(icon).frame(width: 17, height: 17).at(13, y + 2)
        }
        rowLabel(row.name).at(row.icon == nil ? 19 : 34, y)
        bar(row.bar, colour: row.colour, grown: seen).at(row.bar < 0 ? 172 + row.bar : 172, y + 3)
        rowValue(row.value).at(row.bar < 0 ? 183 : 172 + row.bar + 11, y)
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
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: 122, alignment: .leading)
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
    private func table<Rows: View>(_ first: String, _ values: String, height: CGFloat, @ViewBuilder rows: @escaping (Bool) -> Rows) -> some View {
        SeenOnce { seen in card(height: height) {
            ForEach(Array([(first, 17.0), (values, 172.0)].enumerated()), id: \.offset) { _, column in
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
    private func spread(_ item: ReportContent.Spread) -> some View {
        SeenOnce { seen in card(height: 144) {
            ForEach(Array([item.best, item.worst].enumerated()), id: \.offset) { index, fund in
                let top = CGFloat(index) * 72
                // the worse of the two sits 2pt higher in the frame
                let line = index == 0 ? 16.0 : 14.0
                fundLogo(fund.logo).at(13, top + 17)
                Text(fund.name)
                    .font(FigmaFont.walsheim(15))
                    .lineSpacing(21 - 15 * 1.2)
                    .foregroundStyle(Self.secondary)
                    .lineLimit(2)
                    .frame(width: 129, alignment: .leading)
                    .at(59, top + 15)
                Self.hairline.frame(width: 1, height: 72).at(194.5, top)
                // the falling line only for a fund that fell; a weakest fund can still have gained
                Image(fund.value.hasPrefix("-") ? "ReportTrendDown" : "ReportTrendUp")
                    .frame(width: 33, height: 27)
                    // drawn in from its start once the card has been seen
                    .mask(alignment: .leading) { Rectangle().frame(width: seen ? 33 : 0) }
                    .at(205, top + line)
                Text(fund.value)
                    .font(FigmaFont.walsheimMedium(19))
                    .foregroundStyle(Color(hex: fund.value.hasPrefix("-") ? 0xF0453A : 0x00A800))
                    .fixedSize()
                    .frame(width: 100, height: 27, alignment: .trailing)
                    .at(221, top + line)
            }
            Self.hairline.frame(width: 334, height: 1).at(0, 71.5)
        } }
    }

    /// A fund house's mark, 37 square: one of ours where we have it, otherwise its site's icon
    @ViewBuilder private func fundLogo(_ logo: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
        if UIImage(named: logo) != nil {
            Image(logo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 43)
                .frame(width: 37, height: 37)
                .clipShape(shape)
        } else {
            AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(logo)&sz=128")) { image in
                image.resizable().aspectRatio(contentMode: .fit).padding(5)
            } placeholder: {
                Text(logo.prefix(1).uppercased())
                    .font(FigmaFont.walsheimMedium(15))
                    .foregroundStyle(Color.black.opacity(0.5))
            }
            .frame(width: 37, height: 37)
            .background(Color.black.opacity(0.04))
            .clipShape(shape)
        }
    }

    // MARK: The read (1107:14887 onwards)

    private func read(_ item: ReportContent.Read) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(item.question)
                .font(FigmaFont.walsheimMedium(19))
                .lineSpacing(27 - 19 * 1.2)
                .foregroundStyle(Color.black)
            Text(item.answer)
                .font(FigmaFont.walsheim(19))
                .lineSpacing(27 - 19 * 1.2)
                .foregroundStyle(Self.secondary)
            if let credit = item.credit {
                Text(credit)
                    .font(FigmaFont.recklessRegular(19))
                    .foregroundStyle(Self.secondary)
                    .frame(height: 27)
            }
        }
        .frame(width: 334, alignment: .leading)
    }
}

/// "How did my equity funds do this year?" (the chip of 1114:15906, 53 tall), dark: what's suggested next from the first report. It
/// comes out under the sheet as the report is read, and waits in the chat once the report is closed.
struct PortfolioAskChip: View {
    let action: () -> Void

    /// What's suggested, and what goes in as the user's message when it's taken
    static let question = "How did my equity funds do this year?"

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 0) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.white)
                    .frame(width: 25, height: 23)
                Text(Self.question)
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color.white)
                    // The question is longer than the frame's; it's set a touch smaller if it must, to stay on a line
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .padding(.leading, 7)
                    .padding(.trailing, 8)
                Image("OnboardingTopicArrowWhite").frame(width: 23, height: 23)
            }
            .padding(.horizontal, 17)
            .frame(maxWidth: 352)
            .frame(height: 53)
            .background(Color(hex: 0x2C2825))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Self.question)
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
