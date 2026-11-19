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
    /// A report opens taller (1182:16908, 368 × 751), so its opening section fills it exactly
    static let reportHeight: CGFloat = 751

    /// While it works it asks a myth-busting question; for now it shows the turning cube instead
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
                        ReportResults(content: .portfolio, shown: resultsShown, onUnderstood: onUnderstood, height: doneHeight, onClose: onClose)
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
                // While it's prepared, only the cube (1182:17994), turning, without its arrow; it stands in the
                // middle of what's left of the sheet under the timer
                TurningCube(arrow: false)
                    .at((Self.width - TurningCube.canvas) / 2, 236 + (Self.whiteHeight - 236 - TurningCube.canvas) / 2)
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

/// What a report says: the first, on the topic that was asked about, and the one on the user's own equity funds.
/// Each is a header, a main line, and then sections: a chart or a table, with what it shows said over it.
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
    /// A question and its answer, and where the answer comes from when that's said under it
    struct Read {
        let question, answer: String
        var credit: String?
    }

    /// A question a section leaves you with, and what's said when it's opened
    struct Ask {
        let question, answer: String
    }

    /// Columns that can go below the floor, under a sentence with its figure picked out: `unit` points to a point
    /// of return, the floor `floor` down the card, and the scale's marks. A column with no colour is an outline.
    struct Bars {
        let tag, lead, figure, rest, caption: String
        let bars: [(label: String, change: Double, colour: UInt32?)]
        let unit, floor: CGFloat
        let ticks: [Int]
        var ask: Ask?
    }
    /// Four columns rising from a floor, the last filled
    struct Versus {
        let tag, text, title: String
        let columns: [Column]
        /// The scale's four marks, top down
        let ticks: [String]
        var ask: Ask?
    }
    /// A table, under a heading of its own if it opens a new part of the report, with a read under it if there is one
    struct Table {
        var heading: [String]?
        let tag: String
        var text: String?
        let first, values: String
        let rows: [Row]
        var read: Read?
        var ask: Ask?
    }
    /// The best and the worst, as two columns on a scale
    struct Extremes {
        let heading: [String]
        let tag, text: String
        let best, worst: (label: String, fund: String, logo: String, change: Double)
        let unit, floor: CGFloat
        let ticks: [Int]
    }
    enum Section {
        case bars(Bars), versus(Versus), table(Table), extremes(Extremes)
        /// Each category's strongest and weakest fund
        case spreads([Spread])
    }

    /// The header, the period over the main line, the main line's lines, and where the data is from
    let header, period: String
    let hero: [String]
    let source, sourceLogo: String
    /// Whether the cube's front face carries the rising arrow
    var arrow = true
    let sections: [Section]
    /// The read that closes the report, where there is one
    var readTitle = ""
    var reads: [Read] = []
}

extension ReportContent {
    /// The number in "+9.66%"
    static func figure(_ value: String) -> Double {
        Double(value.filter { "0123456789.-".contains($0) }) ?? 0
    }
    /// A change as it's written: its sign, one decimal (none for a round figure when `trimmed`), a percent sign
    static func percent(_ change: Double, trimmed: Bool = false) -> String {
        let figure = String(format: trimmed && change == change.rounded() ? "%.0f" : "%.1f", abs(change))
        return (change < 0 ? "-" : "+") + figure + "%"
    }
    /// "a, b and c"
    static func listed(_ items: [String]) -> String {
        items.count > 1 ? items.dropLast().joined(separator: ", ") + " and " + items[items.count - 1] : items.joined()
    }
    /// A column's name on one line
    static func flat(_ name: String) -> String { name.replacingOccurrences(of: "\n", with: " ") }
}

extension ReportContent {
    // The first report's figures, apart, so what's said over each table and chart is worked out from them
    private static let kinds = [Column(name: "Debt\nfunds", value: "+2.7%", height: 58), Column(name: "Hybrid\nfunds", value: "+4.0%", height: 85),
                                Column(name: "Index\nfunds", value: "+6.8%", height: 145), Column(name: "Equity\nfunds", value: "+7.1%", height: 151, filled: true)]
    private static let industries = [Row(icon: "ReportHealthcare", name: "Healthcare", value: "+20.05%", bar: 61, colour: 0x3FD519),
                                     Row(icon: "ReportTechnology", name: "Technology", value: "-7.51%", bar: -22, colour: 0xFFA99C),
                                     Row(icon: "ReportConsumer", name: "Consumer", value: "-19.62%", bar: -53, colour: 0xFF6E5F)]
    private static let categories = [Row(name: "Small cap", value: "+9.66%", bar: 61, colour: 0x3FD519),
                                     Row(name: "Mid cap", value: "+5.11%", bar: 37, colour: 0x7CE469),
                                     Row(name: "Multi cap", value: "+4.68%", bar: 32, colour: 0x7CE469),
                                     Row(name: "Flexi cap", value: "+3.73%", bar: 25, colour: 0xC6F8BD),
                                     Row(name: "Large & mid cap", value: "+3.06%", bar: 25, colour: 0xC6F8BD),
                                     Row(name: "Large cap", value: "+0.31%", bar: 2, colour: 0xDBD213)]
    /// The half years the first chart shows, oldest first, the last of them the six months the report is about
    private static let halves: [(label: String, change: Double)] =
        [("Dec 24 -\nMay 25", 2.7), ("Jun 25 -\nNov 25", 4.0), ("Dec 25 -\nMay 26", -6.8), ("last 6\nmonths", 7.1)]


    /// "Equity mutual funds 2026" (1080:14346, 1182:17998): the tags, sentences and questions come from the figures
    static let equityYear: ReportContent = {
        let last = halves[halves.count - 1].change, before = halves[halves.count - 2].change
        let byReturn = kinds.sorted { figure($0.value) > figure($1.value) }
        // "index (+6.8%), hybrid (+4.0%) and debt (+2.7%) funds", kept to three lines
        let others = listed(byReturn.dropFirst().map { "\(flat($0.name).lowercased().replacingOccurrences(of: " funds", with: "")) (\($0.value))" }) + " funds"
        let ranked = categories.sorted { figure($0.value) > figure($1.value) }
        let lead = String(format: "%.2f", figure(ranked[0].value) - figure(ranked[1].value))
        let top = industries.max { figure($0.value) < figure($1.value) }!
        // 1182:17531, 1182:17532: the year's best fund and its worst
        let best = (label: "Motilal\nOswal", fund: "Motilal Oswal Digital India fund", logo: "motilaloswalmf.com", change: 28.0)
        let worst = (label: "Nippon\nIndia", fund: "Nippon India Taiwan Equity Fund", logo: "FundNippon", change: -31.4)
        return ReportContent(
            header: "Equity mutual funds 2026", period: "Jun - Nov 2026",
            hero: ["Equity funds", "delivered a", "\(percent(last)) absolute", "return"],
            source: "Verified data source: Morningstar", sourceLogo: "ReportMorningstar",
            sections: [
                // 1174:16543, 1114:15914: 16pt to a point of return, the floor far enough up for the half year that fell
                .bars(Bars(
                    tag: last > before ? "Great half-year" : "Weaker half-year",
                    lead: "Equity funds returned an average of ", figure: percent(last),
                    rest: " in the last 6 months, against \(percent(before)) in the six months before.",
                    caption: "Equity funds, average absolute returns\n(Jun to 18 Nov)",
                    bars: halves.enumerated().map { index, half in
                        (half.label, half.change, half.change < 0 ? nil : index == halves.count - 1 ? 0x3FD519 : 0x0D6DDC)
                    },
                    unit: 16, floor: 178, ticks: [6, 3, 0, -3, -6],
                    // The market's fall and recovery are from 2026 market coverage (PrimeInvestor: the Nifty 50 down
                    // 6.86% for the year on 13 Aug; Zee Business and IIFL: pharma and banks at highs in November)
                    ask: Ask(question: "Why did it beat the previous six months?",
                             answer: "The six months before were a falling market: by mid-August the Nifty 50 was still down about 7% for the year. Prices then recovered, with banks and pharma among the leaders, and equity funds rose with them."))),
                // 1174:16544, 1174:16516: each column as tall as its figure, the scale's marks 3 points of return apart
                .versus(Versus(
                    tag: "Highest return in fund category",
                    text: "\(flat(byReturn[0].name)) returned \(byReturn[0].value), ahead of \(others).",
                    title: "Equity funds vs others", columns: kinds, ticks: ["9", "6", "3", "0"],
                    ask: Ask(question: "Why did equity beat the other fund types?",
                             answer: "Debt funds earn interest, which is steady but small. Hybrid funds hold part shares and part debt, so they landed in between. Equity funds are all shares: they carry the most risk, and in a market that was rising they gained the most. Index funds, which simply follow the market, were close behind."))),
                // 1182:16608, 1182:16610. "Small caps returned extra 2." in the frame: the extra is the lead over the next
                .table(Table(
                    heading: ["Funds", "performance"],
                    tag: "\(ranked[0].name)s returned an extra \(lead)%",
                    first: "Fund type", values: "Average return", rows: categories,
                    ask: Ask(question: "Why did \(ranked[0].name.lowercased())s do so much better?",
                             answer: "Smaller companies’ shares move more than large ones, both ways. In a year when prices recovered they rose the most: \(ranked[0].value) on average against \(ranked[ranked.count - 1].value) for \(ranked[ranked.count - 1].name.lowercased())s. They also had the widest gap between funds, from \(equitySpreads[0].best.value) to \(equitySpreads[0].worst.value)."))),
                // 1182:16660
                .table(Table(
                    tag: "\(top.name) led with \(top.value)", text: "Industry focused funds performance",
                    first: "Industry", values: "Average return", rows: industries,
        // From market coverage of the 2026 pharma rally (Zee Business, PrimeInvestor, Whalesbook, Business Standard),
                    // read 18 Nov 2026: steady earnings on demand at home, contract manufacturing moving to India, and money
                    // going to steadier sectors while the wider market fell. Not Morningstar's or Decade's own finding.
                                read: Read(question: "Why did healthcare do better?",
                                    answer: "Drug makers kept reporting steady earnings, helped by demand at home. Global firms moved more manufacturing to India, and in a weak market investors preferred steadier sectors like this one.",
                                    credit: "From market reports, Nov 2026"))),
                // 1182:17338, 1182:16824
                .extremes(Extremes(
                    heading: ["Fund selection", "matters"],
                    tag: "\(flat(best.label)) performed the best",
                    text: "The best fund returned \(percent(best.change, trimmed: true)) and the worst lost \(percent(worst.change, trimmed: true).dropFirst()), a gap of \(percent(best.change - worst.change).dropFirst().dropLast()) points.",
                    best: best, worst: worst, unit: 3.2, floor: 160, ticks: [20, 0, -20])),
                // 1182:16791. Advisorkhoj trailing returns, regular growth plans, as on 16 Nov 2026
                .spreads(equitySpreads),
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
    }()

    private static let equitySpreads: [Spread] = [
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
    ]

    /// The report on the user's own equity funds, which is what was asked ("How did my equity funds do this year?").
    /// The portfolio is assumed, as nothing real is imported: ₹30,00,000 invested, of which Kotak Large Cap
    /// ₹11,00,000 is the only equity fund; the rest is Axis Ultra Short Term ₹9,00,000, HDFC Short Term ₹6,00,000
    /// (debt) and ICICI Pru Gold ETF FOF ₹4,00,000. Kotak's one-year return, -0.17%, and its place among large cap
    /// funds (30th of 34, the strongest +11.37%, the weakest -3.56%) are as on 16 Nov 2026 (Advisorkhoj). The class
    /// averages are the first report's. Its sectors are Kotak's own, 31 Oct 2026; its largest holdings are from an
    /// undated aggregator page (mStock), so they are a guide, not this month's factsheet.
    static let portfolio: ReportContent = {
        let invested = 3_000_000.0, equity = 1_100_000.0, change = -0.17
        let share = String(format: "%.1f%%", equity / invested * 100)
        let classAverage = categories.first { $0.name == "Large cap" }!
        let ranked = categories.sorted { figure($0.value) > figure($1.value) }
        // The market by company size, largest first
        let caps = ["Large cap", "Mid cap", "Small cap"].compactMap { name in categories.first { $0.name == name } }
        let holdings: [(String, Double)] = [("ICICI Bank", 8.2), ("Reliance Industries", 6.0), ("HDFC Bank", 5.9),
                                            ("State Bank of India", 4.8), ("Larsen & Toubro", 4.1)]
        let topFive = holdings.reduce(0) { $0 + $1.1 }
        return ReportContent(
            header: "Your equity funds 2026", period: "Nov 2025 - Nov 2026",
            hero: ["\(share) of your", "money is in", "equity funds"],
            source: "Verified data source: MFCentral", sourceLogo: "MFCentralLogo",
            arrow: false,
            sections: [
                // The market's equity, by company size, against the user's: the columns as tall as their figures,
                // 64pt to 3 points of return
                .bars(Bars(
                    tag: change < figure(classAverage.value) ? "Your equity trailed the market" : "Your equity beat the market",
                    lead: "Your equity ended the year at ", figure: "\(String(format: "%.2f", change))%",
                    rest: ", against " + listed(caps.map { "\($0.name.lowercased().replacingOccurrences(of: " cap", with: "")) (\($0.value))" }) + " caps in the market.",
                    caption: "Equity funds by company size, average\none-year returns (to 16 Nov 2026)",
                    bars: [("Your\nequity", change, 0x0D6DDC)] + caps.map { (flat($0.name).replacingOccurrences(of: " ", with: "\n"), figure($0.value), UInt32?.none) },
                    unit: 64.0 / 3, floor: 266, ticks: [9, 6, 3, 0],
                    ask: Ask(question: "Why did my equity trail the market?",
                             answer: "All your equity money is in one large cap fund, and large cap was the weakest part of the market this year at \(classAverage.value). Mid and small cap funds, which you don’t hold, did most of the rising. Your fund also finished a little under the large cap average."))),
                // How much is held in equity
                .table(Table(
                    tag: "1 of your 4 funds is an equity fund",
                    text: "₹11,00,000 of the ₹30,00,000 you invested is in equity, all of it in Kotak Large Cap.",
                    first: "Type", values: "Share",
                    rows: [Row(name: "Equity", value: share, bar: 61, colour: 0x3FD519),
                           Row(name: "Debt", value: "50.0%", bar: 83, colour: 0x93C3D5),
                           Row(name: "Gold", value: "13.3%", bar: 22, colour: 0xDBD213)])),
                // How the equity fund did, among funds of its class: 15pt to a point of return
                .bars(Bars(
                    tag: "Kotak Large Cap ended at \(String(format: "%.2f", change))%",
                    lead: "Your ₹11,00,000 in Kotak Large Cap ended the year at ", figure: "\(String(format: "%.2f", change))%",
                    rest: ", and is worth ₹10,98,130 today.",
                    caption: "Large cap funds, one-year returns\n(to 16 Nov 2026)",
                    bars: [("Weakest\nfund", -3.56, nil), ("Your\nfund", change, 0x0D6DDC),
                           ("Class\naverage", figure(classAverage.value), nil), ("Strongest\nfund", 11.37, 0x3FD519)],
                    unit: 15, floor: 232, ticks: [12, 8, 4, 0, -4],
                    ask: Ask(question: "Why did Kotak Large Cap end lower?",
                             answer: "Mostly because of where it invests: large cap funds averaged only \(classAverage.value). Kotak finished \(String(format: "%.2f", figure(classAverage.value) - change)) points under that and ranked 30th of 34 similar funds. It also holds little of what led the year: under 5% of it is in pharma."))),
                // Its class against the others
                .table(Table(
                    heading: ["Fund class", "comparison"],
                    tag: "\(ranked[ranked.count - 1].name) was the weakest class",
                    text: "All your equity money is in large cap, which returned \(classAverage.value) on average. \(ranked[0].name)s led with \(ranked[0].value).",
                    first: "Fund type", values: "Average return",
                    rows: categories.map { $0.name == "Large cap" ? Row(name: "Large cap (yours)", value: $0.value, bar: $0.bar, colour: $0.colour) : $0 })),
                // What it holds by sector, against the sectors that moved most
                .table(Table(
                    heading: ["Sectoral", "comparison"],
                    tag: "Banks are 23.9% of your fund",
                    text: "Under 5% of Kotak Large Cap is in pharma, the sector that led the year. 5.9% is in IT, which fell.",
                    first: "Sector", values: "Share of fund",
                    rows: [Row(name: "Banks", value: "23.9%", bar: 61, colour: 0xFFC65A),
                           Row(name: "Petroleum products", value: "6.9%", bar: 18, colour: 0xECBE9B),
                           Row(name: "Finance", value: "6.0%", bar: 15, colour: 0x93C3D5),
                           Row(name: "IT software", value: "5.9%", bar: 15, colour: 0xDBD213)])),
                // What it holds, and whether anything should change
                .table(Table(
                    heading: ["Fund holdings", "review"],
                    tag: "Top 5 holdings are \(String(format: "%.0f", topFive))% of the fund",
                    text: "Kotak Large Cap mostly holds the country’s biggest banks and companies, much as the large cap index does. That is why it moves with the market.",
                    first: "Company", values: "Share of fund",
                    rows: holdings.map { Row(name: $0.0, value: String(format: "%.1f%%", $0.1), bar: CGFloat($0.1 / holdings[0].1 * 61).rounded(), colour: 0xC6F8BD) },
                    read: Read(question: "Do we suggest a change?",
                               answer: "Not yet. Large cap funds as a group made under 1% this year, so most of this result is the market. But Kotak’s regular plan ranked 30th of 34 similar funds. If it stays near the bottom next year, we would compare it with a low-cost large cap index fund."))),
            ]
        )
    }()
}


/// A report, 368 wide, in sections the scroll settles on, a dot for each (1080:14346, opening as 1182:17998): the
/// turning cube and the figure it turns on, then a chart or table to a section with what it shows said over it,
/// the strongest and weakest fund of each kind, and the read on it all.
private struct ReportResults: View {
    let content: ReportContent
    /// How many parts have come in: the header, the cube, the main line, the sections
    let shown: Int
    static let parts = 5
    /// "Understood", floating at the foot; the report on the user's own funds ends the chat with it
    var onUnderstood: (() -> Void)?
    /// The sheet's height, which shrinks when the suggestion comes out under it
    var height: CGFloat = AnalysisSheet.reportHeight
    var onClose: () -> Void = {}
    /// Scrolled a little way in: it's being read
    var onRead: () -> Void = {}
    /// The section at the top of the sheet
    @State private var section = 0
    /// How tall each section has turned out, the opening first and the closing read last
    @State private var heights: [Int: CGFloat] = [:]
    /// The questions that have been opened to their answers
    @State private var answered: Set<String> = []
    /// The question just opened, whose answer the report brings into view
    @State private var justOpened: String?

    private static let secondary = Color(hex: 0x645F5F)
    private static let hairline = Color.black.opacity(0.09)

    /// "Understood", floating at the foot over a soft fade of the page, 334 × 45, 31pt up
    private func understood(_ action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [Self.paper.opacity(0), Self.paper], startPoint: .top, endPoint: .bottom)
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
            .background(Self.paper)
        }
    }

    /// "Report" and its mark (1080:14415), the close (1080:14421), and the rule under them
    private var header: some View {
        ZStack(alignment: .topLeading) {
            Image("ReportIcon").frame(width: 24.92, height: 21).at(19, 15)
            Text(content.header)
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

    // MARK: Equity funds vs others (1114:15914), 334 × 334

    /// Four kinds of fund as columns on a scale of 0 to 8, equity's filled green; they rise once the card is seen
    private func versusCard(_ item: ReportContent.Versus) -> some View {
        let shape = RoundedRectangle(cornerRadius: 13, style: .continuous)
        return SeenOnce { seen in
            ZStack(alignment: .topLeading) {
                Color.white
                Text(item.title)
                    .font(FigmaFont.walsheimMedium(19))
                    .foregroundStyle(Color(hex: 0x212121))
                    .fixedSize()
                    .frame(height: 27)
                    .at(13, 13)
                ZStack(alignment: .topLeading) {
                    ForEach(Array([(89.0, 0.05), (112.0, 0.05), (152.0, 0.05), (192.0, 0.05), (209.0, 0.05)].enumerated()), id: \.offset) { _, line in
                        Color.black.opacity(line.1).frame(width: 338, height: 1).at(-5, line.0 - 0.5)
                    }
                    ForEach(Array(item.columns.enumerated()), id: \.offset) { index, column in
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
                    ForEach(Array(zip(item.ticks, [8.0, 72.0, 136.0, 200.0]).enumerated()), id: \.offset) { _, tick in
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

    /// A row: its icon if it has one, its name, and its bar out from the axis with the figure beside it
    @ViewBuilder private func tableRow(_ row: ReportContent.Row, at y: CGFloat, seen: Bool) -> some View {
        if let icon = row.icon {
            Image(icon).frame(width: 17, height: 17).at(13, y + 2)
        }
        rowLabel(row.name).at(row.icon == nil ? 19 : 34, y)
        bar(row.bar, colour: row.colour, grown: seen).at(row.bar < 0 ? 172 + row.bar : 172, y + 3)
        rowValue(row.value).at(row.bar < 0 ? 183 : 172 + row.bar + 11, y)
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

    /// `raised` is the sectioned report's card: no outline, lifted off the page by a soft shadow
    private func card<Content: View>(height: CGFloat, raised: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 13, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Color.white
            content()
        }
        .frame(width: 334, height: height, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Self.hairline.opacity(raised ? 0 : 1), lineWidth: 1))
        .shadow(color: Color.black.opacity(raised ? 0.05 : 0), radius: 50, x: 0, y: 4)
    }

    /// A table (1098:14599, 1098:14514): what's listed and "Average return" over a rule, then its rows, 40pt apart
    private func table<Rows: View>(_ first: String, _ values: String, height: CGFloat, @ViewBuilder rows: @escaping (Bool) -> Rows) -> some View {
        SeenOnce { seen in card(height: height, raised: true) {
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

// MARK: - The report's sections (1080:14346, opening as 1182:17998)

private extension ReportResults {
    static var rule: Color { Color.black.opacity(0.45) }
    static var paper: Color { Color(hex: 0xFCFCFA) }
    /// What Understood covers at the foot, its fade apart
    var covered: CGFloat { onUnderstood == nil ? 0 : 76 }
    /// The opening, the sections, and the closing read where there is one
    var count: Int { 1 + content.sections.count + (content.reads.isEmpty ? 0 : 1) }

    /// How much of a section is air under what's in it
    func slack(_ index: Int) -> CGFloat {
        guard index > 0 else { return 697 - (341 + CGFloat(content.hero.count) * 51 + 40) }
        guard index <= content.sections.count else { return 40 }
        switch content.sections[index - 1] {
        case .versus(let item): return item.ask == nil ? 60 : 99
        case .extremes: return 55
        case .spreads: return 33
        case .bars, .table: return 60
        }
    }
    /// Where each section starts. Until one has been laid out it's taken to be a sheet tall.
    var sectionTops: [CGFloat] {
        (0..<count - 1).reduce(into: [CGFloat(0)]) { tops, index in tops.append(tops[tops.count - 1] + (heights[index] ?? 700)) }
    }
    /// Where what's in each section ends, a little air under it: the scroll stops there on its way to the next
    /// section only when that's below the sheet's foot
    var sectionFeet: [CGFloat] {
        sectionTops.enumerated().map { index, top in top + (heights[index] ?? 700) - slack(index) + 24 }
    }

    var body: some View {
        let tops = sectionTops
        return VStack(spacing: 0) {
            // The header stays where it is while the rest scrolls under it
            header
                .frame(width: AnalysisSheet.width, height: 51, alignment: .topLeading)
                .arrivingUp(shown > 0)
            ScrollViewReader { scroll in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    opening.measured(0, into: $heights)
                    Group {
                        ForEach(Array(content.sections.enumerated()), id: \.offset) { index, item in
                            Group {
                                switch item {
                                case .bars(let item): bars(item)
                                case .versus(let item): versus(item)
                                case .table(let item): table(item)
                                case .extremes(let item): extremes(item)
                                case .spreads(let items): spreads(items)
                                }
                            }
                            .measured(index + 1, into: $heights)
                        }
                        if !content.reads.isEmpty { ourRead }
                    }
                    .arrivingUp(shown > 3)
                }
                .frame(width: 334, alignment: .leading)
                .padding(.leading, 17)
                .frame(width: AnalysisSheet.width, alignment: .leading)
                // what the sheet has given up at its foot, so the last of it can still be brought into view
                .padding(.bottom, AnalysisSheet.reportHeight - height + covered)
            }
            .scrollTargetBehavior(SectionSnap(tops: tops, feet: sectionFeet, sheet: height - 51 - covered))
            .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y >= 100 } action: { _, reading in
                if reading { onRead() }
            }
            .onScrollGeometryChange(for: Int.self) { geometry in
                max(0, (tops.lastIndex { $0 <= geometry.contentOffset.y + 120 }) ?? 0)
            } action: { _, index in
                // a light tick as one section gives way to the next, either way
                Haptics.thresholdCrossed()
                withAnimation(.easeOut(duration: 0.2)) { section = index }
            }
            // An opened question's answer is brought up clear of the sheet's foot, and of what covers it
            .onChange(of: justOpened) { _, question in
                guard let question else { return }
                let foot = (height - 51 - covered - 16) / (AnalysisSheet.reportHeight - 51)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    scroll.scrollTo("answer " + question, anchor: UnitPoint(x: 0.5, y: foot))
                }
                justOpened = nil
            }
            }
        }
        // Laid out at its full height whatever the sheet shows of it: when the sheet gives up its foot to the
        // suggestion mid-scroll, the scroll isn't resized under the finger, only covered
        .frame(width: AnalysisSheet.width, height: AnalysisSheet.reportHeight, alignment: .top)
        .background(Self.paper)
        // the header's rule, as dark as the sections' (1182:16918)
        .overlay(alignment: .top) { Self.rule.frame(width: 330, height: 1).padding(.top, 50.5).arrivingUp(shown > 0) }
        // 1182:17545: a dot for each section down the right edge, the one being read darker
        .overlay(alignment: .topTrailing) {
            VStack(spacing: 15) {
                ForEach(0..<tops.count, id: \.self) { index in
                    Circle()
                        .fill(Color(hex: index == section ? 0x8C8886 : 0xDFDCDA))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.top, 272)
            .padding(.trailing, 6)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .arrivingUp(shown > 2)
        }
        .frame(width: AnalysisSheet.width, height: height, alignment: .top)
        .overlay(alignment: .bottom) {
            if let onUnderstood { understood(onUnderstood).arrivingUp(shown > 1) }
        }
    }

    /// A section of a set height: a rule across its head, and what's in it placed from its top-left corner
    func sectionFrame<Content: View>(height: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .topLeading) {
            Self.rule.frame(width: 334, height: 1).at(0, -0.5)
            content()
        }
        .frame(width: 334, height: height, alignment: .topLeading)
    }

    /// The top of the report (1182:17998): a cube that keeps turning to another face, and the figure the report
    /// turns on. Its name is in the header.
    var opening: some View {
        let foot = 341 + CGFloat(content.hero.count) * 51
        return ZStack(alignment: .topLeading) {
            // 1182:17994, 165 × 160 at (85, 71); its canvas is wider, for the corners that swing out as it turns
            TurningCube(arrow: content.arrow)
                .at(85 + TurningCube.rest.width / 2 - TurningCube.canvas / 2, 71 + TurningCube.rest.height / 2 - TurningCube.canvas / 2)
                .arrivingUp(shown > 1)
            Group {
                Text(content.period)
                    .font(FigmaFont.walsheim(15))
                    .foregroundStyle(Self.secondary)
                    .frame(height: 21)
                    .at(0, 313)
                // the frame's line runs to two lines; the source sits 13 under however many this one takes
                display(content.hero, font: FigmaFont.reckless(53), colour: Color(hex: 0x3FD519))
                    .at(0, 341)
                HStack(spacing: 5) {
                    Text(content.source)
                        .font(FigmaFont.recklessRegular(19))
                        .foregroundStyle(Color(hex: 0x787373))
                        .fixedSize()
                    Image(content.sourceLogo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 18, height: 17)
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                }
                .frame(height: 27)
                .at(0, foot + 13)
            }
            .arrivingUp(shown > 2)
        }
        .frame(width: 334, height: 697, alignment: .topLeading)
    }

    /// "Great half-year" (1174:16543): columns on a scale, some of them below the floor (1114:15914)
    func bars(_ item: ReportContent.Bars) -> some View {
        let unit = item.unit, floor = item.floor
        return asking(item.ask, under: item.ask == nil ? 654 : 611, air: 60) {
            tag(item.tag).at(0, 17)
            (Text(item.lead)
             + Text(item.figure).foregroundStyle(Color(hex: item.figure.hasPrefix("-") ? 0xF0453A : 0x00A800))
             + Text(item.rest))
                .font(FigmaFont.walsheim(19))
                .lineSpacing(27 - 19 * 1.2)
                .foregroundStyle(Color(hex: 0x212121))
                .frame(width: 334, alignment: .leading)
                .at(0, 53)
            Text(item.caption)
                .font(FigmaFont.walsheim(15))
                .lineSpacing(21 - 15 * 1.2)
                .foregroundStyle(Self.secondary)
                .frame(width: 332, alignment: .leading)
                .at(0, 163)
            columns(height: 376, floor: floor, labels: 333,
                    rules: item.ticks.filter { $0 != 0 }.map { (floor - CGFloat($0) * unit, 338, 0.05) } + [(floor, 338, 0.14), (326, 338, 0.25)],
                    ticks: item.ticks.map { ("\($0)", floor - CGFloat($0) * unit) },
                    bars: item.bars.enumerated().map { index, bar in
                        Bar(x: 15 + CGFloat(index) * 79, height: CGFloat(bar.change) * unit, value: ReportContent.percent(bar.change),
                            label: bar.label, colour: bar.colour)
                    }) { EmptyView() }
                .at(0, 218)
        }
    }

    /// "Highest return in fund category" (1174:16544): four columns from a floor (1174:16516)
    func versus(_ item: ReportContent.Versus) -> some View {
        asking(item.ask, under: item.ask == nil ? 606 : 563, air: 99) {
            tag(item.tag).at(0, 45)
            paragraph(item.text).at(0, 86)
            versusCard(item).at(0, 212)
        }
    }

    /// A table (1182:16610, 1182:16660): its heading if it opens a new part of the report (1182:16608), what it shows
    /// in a few words, a sentence, the rows, and under them a read or a question. As tall as all that comes to.
    func table(_ item: ReportContent.Table) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let heading = item.heading {
                display(heading, font: FigmaFont.recklessRegular(53), colour: Color(hex: 0x282424)).padding(.top, 37)
                tag(item.tag).padding(.top, 28)
            } else {
                tag(item.tag).padding(.top, 37)
            }
            if let text = item.text {
                paragraph(text).fixedSize(horizontal: false, vertical: true).padding(.top, 23)
            }
            table(item.first, item.values, height: 62 + CGFloat(item.rows.count) * 40) { seen in
                ForEach(Array(item.rows.enumerated()), id: \.offset) { index, row in
                    tableRow(row, at: 66 + CGFloat(index) * 40, seen: seen)
                }
            }
            .padding(.top, item.text == nil ? 27 : 23)
            // what's behind it, set as the read at the report's end is
            if let read = item.read {
                self.read(read).fixedSize(horizontal: false, vertical: true).padding(.top, 28)
            }
            if let question = item.ask {
                ask(question).padding(.leading, 10).padding(.top, 17)
            }
        }
        .padding(.bottom, 60)
        .frame(width: 334, alignment: .leading)
        .overlay(alignment: .top) { Self.rule.frame(width: 334, height: 1).offset(y: -0.5) }
    }

    /// "Fund selection matters" (1182:17338): the best fund against the worst (1182:16824)
    func extremes(_ item: ReportContent.Extremes) -> some View {
        let unit = item.unit, floor = item.floor
        return sectionFrame(height: 845) {
            display(item.heading, font: FigmaFont.recklessRegular(53), colour: Color(hex: 0x282424)).at(0, 47)
            tag(item.tag).at(0, 179)
            paragraph(item.text).at(0, 225)
            columns(height: 462, floor: floor, labels: 303,
                    rules: item.ticks.filter { $0 != 0 }.map { (floor - CGFloat($0) * unit, 338, 0.05) } + [(floor, 300, 0.25), (296, 338, 0.25)],
                    ticks: item.ticks.map { ("\($0)", floor - CGFloat($0) * unit) },
                    bars: [Bar(x: 62, height: CGFloat(item.best.change) * unit, value: ReportContent.percent(item.best.change, trimmed: true),
                               label: item.best.label, colour: 0x3FD519),
                           Bar(x: 212, height: CGFloat(item.worst.change) * unit, value: ReportContent.percent(item.worst.change, trimmed: true),
                               label: item.worst.label, colour: nil)]) {
                extreme("Highest", fund: item.best.fund, logo: item.best.logo, best: true).at(11, 373)
                Self.hairline.frame(width: 334, height: 1).at(0, 404.5)
                extreme("Worst", fund: item.worst.fund, logo: item.worst.logo, best: false).at(11, 416)
            }
            .at(0, 328)
        }
    }

    /// Each category's name over its strongest and weakest fund (1182:16791)
    func spreads(_ items: [ReportContent.Spread]) -> some View {
        sectionFrame(height: 36 + CGFloat(items.count) * 207 + 33) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let y = 36 + CGFloat(index) * 207
                Text(item.label)
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color(hex: 0x282424))
                    .frame(width: 334, height: 25)
                    .at(0, y)
                spread(item).at(0, y + 36)
            }
        }
    }

    /// "Our read" (1182:16774), then the read on the year as it was
    var ourRead: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Self.rule.frame(width: 334, height: 1).at(0, -0.5)
                display(["Our read"], font: FigmaFont.recklessRegular(53), colour: Color(hex: 0x282424)).at(0, 47)
                Text(content.readTitle)
                    .font(FigmaFont.reckless(35))
                    .foregroundStyle(Color(hex: 0x33302D))
                    .frame(height: 43)
                    .at(0, 145)
            }
            .frame(width: 334, height: 215, alignment: .topLeading)
            VStack(alignment: .leading, spacing: 21) {
                ForEach(Array(content.reads.enumerated()), id: \.offset) { _, item in
                    read(item).padding(.bottom, item.credit == nil ? 0 : 27)
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: The pieces the sections are made of

    /// Display type whose lines sit 51 apart, closer than the face sets them by itself, so each line is placed
    func display(_ lines: [String], font: Font, colour: Color) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                Text(line).fixedSize().frame(height: 51).at(0, CGFloat(index) * 51)
            }
        }
        .font(font)
        .foregroundStyle(colour)
        .frame(width: 334, height: CGFloat(lines.count) * 51, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lines.joined(separator: " "))
        .accessibilityAddTraits(.isHeader)
    }

    /// What a section found, in a few words, lavender, a thumb before it (1174:16543)
    func tag(_ text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: 0x8D6197))
                .frame(width: 20, height: 23)
            Text(text)
                .font(FigmaFont.walsheimMedium(17))
                .foregroundStyle(Color(hex: 0x5C4261))
                .fixedSize()
        }
        .frame(height: 24)
        .accessibilityElement(children: .combine)
    }

    func paragraph(_ text: String) -> some View {
        Text(text)
            .font(FigmaFont.walsheim(19))
            .lineSpacing(27 - 19 * 1.2)
            .foregroundStyle(Color(hex: 0x212121))
            .frame(width: 334, alignment: .leading)
    }

    /// A section laid out to a set height, with its question, if it has one, hung under it: the question opens to
    /// its answer where it is, and the section grows by that much
    func asking<Content: View>(_ ask: ReportContent.Ask?, under height: CGFloat, air: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionFrame(height: height, content: content)
            if let ask {
                self.ask(ask).padding(.leading, 10)
                Color.clear.frame(height: air)
            }
        }
        .frame(width: 334, alignment: .leading)
    }

    /// A question the section leaves you with (1182:16777), 328 × 52.4. Tapped, it opens where it is: the pill
    /// grows down into a card with the answer under the question, and closes again on another tap.
    func ask(_ item: ReportContent.Ask) -> some View {
        let open = answered.contains(item.question)
        // the pill's own rounding, so it's the same shape growing
        let shape = RoundedRectangle(cornerRadius: 26.2, style: .continuous)
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                if open { answered.remove(item.question) } else { answered.insert(item.question) }
            }
            if !open {
                // once it has grown
                Task {
                    try? await Task.sleep(for: .seconds(0.05))
                    justOpened = item.question
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.question)
                    .font(FigmaFont.walsheim(15))
                    .foregroundStyle(open ? Color(hex: 0x212121) : Self.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52.4)
                if open {
                    Text(item.answer)
                        .font(FigmaFont.walsheim(15))
                        .lineSpacing(21 - 15 * 1.2)
                        .foregroundStyle(Self.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 17)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 17)
            .frame(width: 328)
            .background(Color.white)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color(hex: 0xD2CECC), lineWidth: 0.7))
            .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityHint(open ? "Hides the answer" : "Shows the answer")
        // its foot, for the report to bring into view
        .overlay(alignment: .bottom) { Color.clear.frame(height: 1).id("answer " + item.question) }
    }

    /// A column: where it stands, how far it rises from the floor (or drops, when negative), and what's written
    /// over and under it. With no colour it's an outline.
    struct Bar {
        let x, height: CGFloat
        let value, label: String
        let colour: UInt32?
    }

    /// Columns against a scale (1114:15914, 1182:16824), which grow from the floor once the card is seen. `ticks`
    /// are the scale's marks and how far down the card each sits.
    func columns<Foot: View>(height: CGFloat, floor: CGFloat, labels: CGFloat, rules: [(CGFloat, CGFloat, Double)],
                             ticks: [(String, CGFloat)], bars: [Bar],
                             @ViewBuilder foot: @escaping () -> Foot) -> some View {
        SeenOnce { seen in card(height: height, raised: true) {
            ForEach(Array(rules.enumerated()), id: \.offset) { _, rule in
                Color.black.opacity(rule.2).frame(width: rule.1, height: 1).at(-5, rule.0 - 0.5)
            }
            ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                let size = seen ? abs(bar.height) : 0
                Rectangle()
                    .fill(bar.colour.map { Color(hex: $0) } ?? Color.white)
                    .overlay(Rectangle().strokeBorder(Color(hex: 0x8D8888), lineWidth: bar.colour == nil ? 1 : 0))
                    .frame(width: 43, height: size)
                    .at(bar.x, bar.height < 0 ? floor : floor - size)
                Text(bar.value)
                    .font(FigmaFont.walsheimMedium(15))
                    .tracking(0.45)
                    .foregroundStyle(Color.black.opacity(0.9))
                    .fixedSize()
                    .frame(width: 79, height: 21)
                    .at(bar.x - 18, bar.height < 0 ? floor + size + 8 : floor - size - 24)
                Text(bar.label)
                    .font(FigmaFont.walsheim(12))
                    .tracking(0.84)
                    .lineSpacing(17 - 12 * 1.2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.black.opacity(0.6))
                    .frame(width: 79, height: 34, alignment: .top)
                    .at(bar.x - 18, labels)
            }
            ForEach(Array(ticks.enumerated()), id: \.offset) { _, tick in
                Text(tick.0)
                    .font(FigmaFont.walsheim(12))
                    .tracking(0.84)
                    .foregroundStyle(Color.black.opacity(0.4))
                    .fixedSize()
                    .frame(width: 30, height: 17)
                    .at(300.5, tick.1 - 8.5)
            }
            foot()
        } }
    }

    /// "Highest" or "Worst", and the fund it was (1182:17531, 1182:17532)
    func extreme(_ title: String, fund: String, logo: String, best: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 5) {
                Image(systemName: best ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: best ? 0x3FD519 : 0xFF6E5F))
                Text(title)
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(Color(hex: best ? 0x00A800 : 0xF0453A))
                    .fixedSize()
            }
            .frame(height: 21)
            smallLogo(logo).at(71, 1)
            Text(fund)
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Self.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(width: 212, height: 21, alignment: .leading)
                .at(95, 0)
        }
        .frame(width: 316, height: 21, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }

    /// A fund house's mark, 19 square: one of ours where we have it, otherwise its site's icon
    @ViewBuilder func smallLogo(_ logo: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)
        if UIImage(named: logo) != nil {
            Image(logo).resizable().aspectRatio(contentMode: .fill).frame(width: 19, height: 19).clipShape(shape)
        } else {
            AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(logo)&sz=64")) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.black.opacity(0.06)
            }
            .frame(width: 19, height: 19)
            .clipShape(shape)
        }
    }
}

/// The cube at the top of the report (1182:17994): drawn in line, the back showing through its top and left sides,
/// its front face pale green with an arrow rising across it. It keeps turning a quarter at a time, over and then
/// up, and comes to rest in the same pose with another face in front, on which the arrow is drawn again, line by
/// line: its shaft, then the two strokes of its head.
private struct TurningCube: View {
    /// Whether the face in front carries the arrow; without it the face is only tinted
    var arrow = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var began = Date()

    /// The cube at rest: a 128 square in front, the one behind it 37 left and 32 up
    static let rest = CGSize(width: 165, height: 160)
    static let canvas: CGFloat = 280
    private static let half: CGFloat = 64
    /// How far a point moves across and up for each point it is further away
    private static let lean = CGSize(width: 37.0 / 128, height: 32.0 / 128)
    /// A rest on a face, then the turn to the next
    private static let resting = 1.9, turning = 1.5
    /// The arrow starts being drawn this far into the turn that brings its face round
    private static let drawnFrom = 0.55
    private static let tint = Color(hex: 0xECFBCB), ink = Color(hex: 0x94B900)
    /// The arrow, on a face that runs from -1 to 1 each way: from its tail up to its tip, and the two strokes of
    /// its head, each out from the tip
    private static let shaft = (CGPoint(x: -0.648, y: 0.656), CGPoint(x: 0.661, y: -0.65))
    private static let head = [CGPoint(x: -0.355, y: -0.65), CGPoint(x: 0.661, y: 0.366)]

    private typealias Vector = SIMD3<Double>
    /// A face: the way it looks out, and the two directions across it
    private typealias Face = (out: Vector, across: Vector, along: Vector)

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            Canvas { context, size in
                draw(&context, size: size, at: reduceMotion ? nil : timeline.date.timeIntervalSince(began))
            }
        }
        .frame(width: Self.canvas, height: Self.canvas)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// `time` is nil when it shouldn't move: at rest, the arrow whole
    private func draw(_ context: inout GraphicsContext, size: CGSize, at time: TimeInterval?) {
        let cycle = Self.resting + Self.turning
        let step = Int((time ?? 0) / cycle)
        let local = (time ?? 0) - Double(step) * cycle
        let progress = min(max((local - Self.resting) / Self.turning, 0), 1)
        // eased in and out, so it sets off and settles gently
        let eased = progress * progress * progress * (progress * (progress * 6 - 15) + 10)
        let quarter = Double.pi / 2 * ([0, 1].contains(step % 4) ? 1 : -1)
        let aboutUpright = step % 2 == 0

        func turn(_ p: Vector, by angle: Double) -> Vector {
            let c = cos(angle), s = sin(angle)
            return aboutUpright ? Vector(p.x * c + p.z * s, p.y, -p.x * s + p.z * c)
                                : Vector(p.x, p.y * c - p.z * s, p.y * s + p.z * c)
        }
        func placed(_ p: Vector) -> CGPoint {
            let now = turn(p, by: eased * quarter)
            return CGPoint(x: size.width / 2 + (now.x - now.z * Self.lean.width) * Self.half,
                           y: size.height / 2 + (now.y - now.z * Self.lean.height) * Self.half)
        }
        // The line of sight: points along it land on the same spot
        let sight = Vector(Double(Self.lean.width), Double(Self.lean.height), 1)
        let reach = (sight * sight).sum().squareRoot()
        /// How solid a face is: wholly when it's square to us, not at all once it has turned well away. So as the
        /// cube turns the face in front thins out and the one coming round fills in, nothing all at once.
        func solid(_ face: Face) -> Double {
            let facing = -(turn(face.out, by: eased * quarter) * sight).sum() / reach
            let t = min(max((facing - 0.5) / 0.35, 0), 1)
            return t * t * (3 - 2 * t)
        }
        func outline(_ face: Face) -> Path {
            var path = Path()
            path.addLines([face.out - face.across - face.along, face.out + face.across - face.along,
                           face.out + face.across + face.along, face.out - face.across + face.along].map(placed))
            path.closeSubpath()
            return path
        }

        let front: Face = (Vector(0, 0, -1), Vector(1, 0, 0), Vector(0, 1, 0))
        // The face this turn brings to the front, the right way up when it gets there
        let next: Face = (turn(front.out, by: -quarter), turn(front.across, by: -quarter), turn(front.along, by: -quarter))
        let sides: [Face] = [front, (Vector(0, 0, 1), Vector(1, 0, 0), Vector(0, 1, 0)),
                             (Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, 0, 1)), (Vector(1, 0, 0), Vector(0, 1, 0), Vector(0, 0, 1)),
                             (Vector(0, -1, 0), Vector(1, 0, 0), Vector(0, 0, 1)), (Vector(0, 1, 0), Vector(1, 0, 0), Vector(0, 0, 1))]
        let line = StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
        // It's made of line: every edge shows, the far ones through the sides,
        for side in sides { context.stroke(outline(side), with: .color(.black), style: line) }

        // except behind the face that's towards us, which is tinted and carries the arrow
        func arrow(on face: Face, drawnFor elapsed: Double) {
            let alpha = solid(face)
            guard alpha > 0 else { return }
            let path = outline(face)
            context.fill(path, with: .color(Self.tint.opacity(alpha)))
            context.stroke(path, with: .color(.black), style: line)
            guard self.arrow else { return }
            func stroke(from a: CGPoint, to b: CGPoint, over start: Double, _ length: Double) {
                let t = min(max((elapsed - start) / length, 0), 1)
                let drawn = t * t * (3 - 2 * t)
                guard drawn > 0 else { return }
                func point(_ p: CGPoint) -> CGPoint { placed(face.out + face.across * Double(p.x) + face.along * Double(p.y)) }
                let from = point(a), to = point(b)
                var path = Path()
                path.move(to: from)
                path.addLine(to: CGPoint(x: from.x + (to.x - from.x) * drawn, y: from.y + (to.y - from.y) * drawn))
                context.stroke(path, with: .color(Self.ink.opacity(alpha)), style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
            }
            // the shaft from its tail to the tip, then the head's two strokes out from the tip
            stroke(from: Self.shaft.0, to: Self.shaft.1, over: 0, 0.6)
            for end in Self.head { stroke(from: Self.shaft.1, to: end, over: 0.5, 0.4) }
        }
        guard let time else { return arrow(on: front, drawnFor: .infinity) }
        if progress > 0 {
            // Turning: the face that's leaving keeps its arrow as it fades; the one arriving has its drawn
            arrow(on: front, drawnFor: .infinity)
            arrow(on: next, drawnFor: local - Self.resting - Self.turning * Self.drawnFrom)
        } else {
            // At rest: what was begun in the turn is finished; the very first time, it's drawn from nothing
            arrow(on: front, drawnFor: time < cycle ? local - 0.6 : local + Self.turning * (1 - Self.drawnFrom))
        }
    }
}

/// Settles the report on its sections, firmly. The slightest flick takes you to the next section's head when
/// the one you're on has been seen to its foot, and to its foot first when it's taller than the sheet; inside a
/// section too long for that, it scrolls freely and only stops at the section's end.
private struct SectionSnap: ScrollTargetBehavior {
    let tops: [CGFloat]
    /// Where each section's contents end
    let feet: [CGFloat]
    /// How much of the report shows under its header
    let sheet: CGFloat

    /// How little a flick has to move it to be taken on to the next stop, and how far from a stop it can be
    /// left and still be drawn onto it
    private static let nudge: CGFloat = 14, reach: CGFloat = 230

    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        let from = context.originalTarget.rect.minY
        let natural = target.rect.minY
        let quick = abs(context.velocity.dy) >= 80
        var to = natural

        if natural - from > Self.nudge, let index = tops.firstIndex(where: { $0 > from + 1 }) {
            let next = tops[index]
            // its foot first, if what's in it runs on below the sheet
            let foot = min(feet[index - 1], next) - sheet
            let stop = foot - from > 24 ? foot : next
            if quick || natural <= next + Self.reach {
                // Straight to the next section when this one has been seen to its end (whatever's left is empty);
                // to its foot when that's within a sheet's height; otherwise freely, as far as the foot
                to = (stop == next || stop - from <= sheet || stop - natural < Self.reach) ? stop : min(natural, stop)
            }
        } else if from - natural > Self.nudge, let previous = tops.last(where: { $0 < from - 1 }) {
            if quick || natural >= previous - Self.reach {
                to = (from - previous <= sheet * 1.25 || natural - previous < Self.reach) ? previous : max(natural, previous)
            }
        }
        // Left to rest near a section's head, or where a tall one's foot comes into view, it settles there, but
        // never back onto the stop it was flicked away from (the last section has no next to go to, and has to
        // scroll freely)
        if to == natural {
            let footStops = zip(tops, feet).map { top, foot in (top: top, stop: foot - sheet) }.filter { $0.stop - $0.top > 24 }.map(\.stop)
            if let nearest = (tops + footStops).min(by: { abs($0 - to) < abs($1 - to) }), abs(nearest - to) < Self.reach {
                let leftBehind = (natural - from > Self.nudge && nearest <= from + 1) || (from - natural > Self.nudge && nearest >= from - 1)
                if !leftBehind { to = nearest }
            }
        }
        target.rect.origin.y = min(max(to, 0), max(0, context.contentSize.height - context.containerSize.height))
    }
}

/// "How did my equity funds do this year?" (the chip of 1114:15906, 53 tall), dark: what's suggested next from the first report. It
/// comes out under the sheet as the report is read, and waits in the chat once the report is closed.
struct PortfolioAskChip: View {
    /// More room inside the pill, on every side: under the report it's given a little more than in the chat
    var room: CGFloat = 0
    let action: () -> Void

    /// As tall as it stands in the chat
    static let height: CGFloat = 53

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
            .padding(.horizontal, 17 + room)
            // Wider by what's added at its sides, so the question is set no smaller for it
            .frame(maxWidth: 352 + room * 2)
            .frame(height: Self.height + room * 2)
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
    /// Tells `heights` how tall it has turned out
    func measured(_ index: Int, into heights: Binding<[Int: CGFloat]>) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.size.height } action: { heights.wrappedValue[index] = $0 }
    }

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
