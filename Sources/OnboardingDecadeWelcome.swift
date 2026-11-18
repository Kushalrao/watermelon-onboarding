import SwiftUI

/// Figma "iPhone 14 Plus - 435" (679:24216): after the PAN card's Confirm. The background flows up over the identity
/// screen first, then "Hello Arindam" and the "Welcome to Decade Wealth Advisory" card land, the card from 1.1× with
/// its photo, and the three ways of working settle in one under another. A moment later Continue comes in under it.
///
/// Continue turns the card into a chat with the agent (699:24516) under a pinned Decade pill: it sheds the photo and
/// the welcome. What the research runs on comes up first as a navy sheet (699:24374); once that's understood the
/// agent says "Good evening" and asks "Lets start with a topic you’re interested in?" over topics to start on, in
/// two rows. The one tapped goes in as the user's message; the agent types, replies to it, scrolls up
/// and types once more over a "Mutual funds research plan" chip (141:3970), and 1.7s later the plan, written for
/// that topic, opens over the chat (141:3447) as the card steps back.
///
/// When the research's 59 seconds are up (146:4575) the plan folds back into its chip if it's open, the chat moves on,
/// the chip rising to just under the heading, and what was found comes in under it: the counts, then "We have all
/// its required to analyze it now". "Find insights from research" forms below the card, the way Continue did.
///
/// That sends too (146:4796): the results scroll up under the heading, the message goes in, the agent types over a
/// "Creating analysis" chip, and 1.7s later the analysis opens over the chat (146:5043), white, with its own minute.
/// It asks a question to bust a myth while it works (148:5339), and when the minute is up it turns black and becomes
/// the analysis (146:4908). The card behind folds either sheet back into its chip.
///
/// A few seconds on, the analysis folds itself away into the chat as an "Analysed" card (148:5848) that opens it
/// again. The agent types, the chat moves on to "Advice is personal" (148:5935), the heading becoming "Advisory
/// Decisioning", and a sheet rises asking to connect the user's mutual funds (148:6020).
struct OnboardingDecadeWelcomeView: View {
    let onContinue: () -> Void

    /// How far up the screen the background has flowed, 0…1
    @State private var flow: CGFloat = 0
    @State private var shown = false
    /// How many of the "How we work" rows have come in
    @State private var rowsShown = 0
    /// The photo has shortened to make room for Continue under the card
    @State private var compact = false
    @State private var button = ButtonStage.hidden

    private enum ButtonStage { case hidden, dot, open }

    /// Continue has been pressed: the card is a chat
    @State private var chatting = OnboardingDecadeWelcomeView.startsInChat
    @State private var sent = false
    @State private var headingShown = false
    @State private var replyShown = false
    @State private var planShown = false
    /// The agent's offer to help (225:11830), then the topics to start on, one by one: the label, then each
    @State private var topicsShown = 0
    /// The topic the user started on
    @State private var topic: Topic? = OnboardingDecadeWelcomeView.startsInChat ? Topic.all[0] : nil
    /// The avatar goes as soon as a topic's sent; the topic is pinned over the card 1.7s later, the card making room
    /// The chat has Decade pinned over it from the start (316:17768), no avatar in the card
    @State private var avatarGone = OnboardingDecadeWelcomeView.startsInChat
    @State private var topicPinned = OnboardingDecadeWelcomeView.startsInChat
    /// The pin has flipped over from Decade to the topic that was picked
    @State private var topicFlipped = OnboardingDecadeWelcomeView.startsInChat

    /// Something to research first (225:11836): what the user sends, how the agent answers, and the plan's title
    struct Topic: Equatable {
        let title: String, reply: String, plan: String
        /// What it's called once it's picked, pinned over the chat (269:3110)
        var short = ""
        /// The line over the question on its card (1080:14025)
        var label = "Mutual funds"

        static let all = [
            Topic(title: "How have equity mutual funds done over the last year and what does that tell us about the future?",
                  reply: "Good place to start. I’ll compare a year of returns across equity fund categories, see which held up and which slipped, and what that tells us.",
                  plan: "Equity mutual funds, the last year", short: "Mutual funds performance"),
            Topic(title: "Can mutual funds still make me wealthy?",
                  reply: "A fair question. I’ll set long-run fund returns against inflation, fixed deposits and the index, and see what steady investing has really added up to.",
                  plan: "Mutual funds and building wealth", short: "Wealth from mutual funds"),
            Topic(title: "How do I know if my mutual fund portfolio is good?",
                  reply: "I’ll go through what makes a portfolio hold up: how its funds rank, where they overlap, what they cost and how they’ve done against their benchmarks.",
                  plan: "What makes a good portfolio", short: "A good fund portfolio", label: "Fixed deposit"),
            Topic(title: "Do Fixed deposits really make sense in 2027?",
                  reply: "I’ll look at where deposit rates stand against inflation and tax, and set them beside debt funds and other safe options for the year ahead.",
                  plan: "Fixed deposits in 2027", short: "Fixed deposits in 2027", label: "Mutual funds market"),
            Topic(title: "How can I invest 10 Lakh for maximum returns in 5 years, and what are the risks?",
                  reply: "I’ll compare what five years has done for deposits, debt and equity funds, and how much each can fall along the way, so the returns come with their risks.",
                  plan: "10 Lakh over 5 years", short: "Investing 10 Lakh for 5 years", label: "Fixed deposit"),
        ]
    }
    /// Where the agent's dots are showing, in the chat's own coordinates; nil when it isn't typing
    @State private var typingAt: CGFloat?
    /// How far the chat has scrolled up under the heading
    @State private var scroll: CGFloat = 0
    @State private var sheetUp = false
    /// When the research began, the first time the plan opened; its timer carries on through closing and reopening
    @State private var researchStarted: Date?
    /// The sheets that have been open once already, and come back without their parts arriving again
    @State private var researchSeen = false
    @State private var analysisSeen = false
    /// The myth's answer, kept for when the analysis opens again
    @State private var mythAnswer: Bool?
    /// The sheet is folding back into the plan chip
    @State private var sheetClosing = false
    /// The card is stepped back behind the open sheet
    private var steppedBack: Bool {
        (sheetUp && !sheetClosing) || connectUp || researchIntroUp || advisorUp || personalPrompt != nil
    }
    /// "Decade Research" (233:12750) is up, before the agent's first message
    @State private var researchIntroUp = false
    /// The research is done (146:4575)
    @State private var researchDone = false
    /// How many of the results have come in: the three counts, then the heading
    @State private var resultsShown = 0

    /// Which sheet opens over the chat, and folds back into its chip
    @State private var activeSheet = SheetKind.research
    private enum SheetKind { case research, analysis }
    /// "Find insights from research" has been sent (146:4796)
    @State private var insightsSent = false
    @State private var insightsShown = false
    @State private var analysisTyping = false
    @State private var analysisChipShown = false
    @State private var analysisStarted: Date?
    /// The analysis's minute is up: its sheet is black, the analysis itself (146:4908)
    @State private var analysisDone = false
    /// The analysis is kept in the chat as a card (148:5911)
    @State private var analysisStored = false
    @State private var adviceTyping = false
    /// "Wealth advise is useful when its personalized" (256:15910), then the prompts
    @State private var adviceShown = false
    /// How many of the personal-advice prompts have come in
    @State private var advicePromptsShown = 0
    /// The prompt tapped, opening "Connect your mutual funds portfolio for personal advise" (256:15540) with it
    @State private var personalPrompt: Int?
    /// Its second page, "We will import mutual funds via MFCentral" (256:15592)
    @State private var importUp = false
    /// The import itself is running, over everything (817:7117). `-importFlow` opens on it.
    @State private var importRunning = ProcessInfo.processInfo.arguments.contains("-importFlow")
    /// The import's done: the chat's card says so (1012:11077)
    @State private var fundsConnected = false
    /// With the funds in, a second report is prepared, as a card under the connected one, and then opens
    @State private var portfolioReportShown = false
    /// Back from connecting: the agent types, thanks for it, and goes through the funds before the report
    /// The first report has been scrolled 100pt: its suggestion comes out from under the sheet
    @State private var suggestionPopped = false
    @State private var thanksTyping = false
    @State private var thanksShown = false
    @State private var portfolioThinking: Date?
    @State private var portfolioReportReady = false
    /// "Jojo's Personal Wealth Advisor" is up (243:14078), on its way to asking for the funds
    @State private var advisorUp = false
    /// The chat has moved on to decisions: its heading says so (148:6059)
    @State private var deciding = false
    /// "Connect your Mutual funds safely" is up (148:6099)
    @State private var connectUp = false
    /// The window's height and insets; the onboarding runs edge to edge, so SwiftUI doesn't hand them down. Read once
    /// it's on screen.
    @State private var insets: (height: CGFloat, top: CGFloat, bottom: CGFloat) = (874, 62, 34)
    @State private var screenWidth: CGFloat = 402
    /// The card: 364 wide as the welcome; as the chat, 93% of the screen's width
    private var cardWidth: CGFloat { chatting ? (screenWidth * 0.93).rounded() : 364 }
    /// Where things sit in the insights chat, in the card, before it scrolls
    private enum AdviceY {
        static let card: CGFloat = 384
        static let dots: CGFloat = 697
        static let heading: CGFloat = 727
        /// The prompts, under the line's three 27pt lines
        /// "Wealth advise is useful when its personalized" (256:15910): three of the chat's heading lines, then its time
        static let headingHeight: CGFloat = 3 * 43
        static let prompts: CGFloat = heading + headingHeight + 10 + 19 + 18
        /// The stored analysis scrolls the chat up this much, and the advice this much more
        static let storedScroll: CGFloat = 140
        static let adviceScroll: CGFloat = 480
    }
    /// Where the stored analysis sits in the card
    private var analysedOrigin: CGPoint { CGPoint(x: 17, y: AdviceY.card + Self.analysisLift + laterLayers + drift) }
    /// The analysis's part of the chat sits this much lower than in Figma (146:4796), right under the results
    /// The analysis's part sits this much lower than the results' own coordinates, right under the agent's message
    private static let analysisLift: CGFloat = 106 - 129 + 82
    private static let insights = ChatMessage(text: "Find insights from research", fromAgent: false)
    /// Where "Creating analysis" sits in the card (146:4893)
    /// It takes the dots' place, as the research plan's chip does
    private static let analysisChipOrigin = CGPoint(x: 17, y: 384 + analysisLift)

    /// `-welcomeChat` opens on the chat, with the research plan up
    private static let startsInChat = startsDone || ProcessInfo.processInfo.arguments.contains("-welcomeChat")

    /// `-welcomeDone` opens on the chat with the research done
    private static let startsDone = startsInAnalysis || ProcessInfo.processInfo.arguments.contains("-welcomeDone")
    /// `-welcomeAnalysis` opens with the analysis up, `-analysisDone` with it finished
    private static let startsInAnalysis = startsAnalysisDone || ProcessInfo.processInfo.arguments.contains("-welcomeAnalysis")
    private static let startsAnalysisDone = startsAdvice || ProcessInfo.processInfo.arguments.contains("-analysisDone")

    /// `-welcomeAdvice` opens with the analysis stored and the connect sheet up
    private static let startsAdvice = ProcessInfo.processInfo.arguments.contains("-welcomeAdvice")
    /// Where things sit in the chat, from its top (106pt down the card), as in 225:11778 and 141:3970
    /// The chat's headings (256:15910): Reckless 37 on 43pt lines, each line set on its own
    static let headingSize: CGFloat = 37
    static let headingLine: CGFloat = 43
    private static let questionLines = ["Lets start with a topic", "you’re interested in?"]
    /// "We have all its required to analyze it now", as the agent's message: a two-line bubble, its time under it
    /// counted separately
    private static let resultsHeadingHeight: CGFloat = 82
    private static let adviceLines = ["Wealth advise is", "useful when its", "personalized"]
    /// What a user might ask once advice is personal; the first from 256:15542
    /// in two rows (294:16526)
    static let advicePrompts = [
        "How can I improve my portfolio for better profits?",
        "Which of my funds are holding me back?",
        "How much should I invest each month?",
        "Am I taking too much risk for my goals?",
        "Are my funds overlapping too much?",
        "Should I switch any fund to a direct plan?",
    ]
    private static let promptRows = 2
    /// Both rows, 13pt apart
    static let promptsHeight: CGFloat = ConnectActionCard.size.height + 12

    private enum ChatY {
        /// The opening question sits lower in the card, centred, with the topics under it (316:17768)
        static let open: CGFloat = 68
        static let heading: CGFloat = 113
        /// Everything under the question sits this much higher than it did under the larger, four-line one
        static let lift: CGFloat = 51
        static let topicsLabel: CGFloat = 271 - lift + open
        static let topics: CGFloat = 247
        /// The user's message goes in where the topics were, its time under it
        static let sent: CGFloat = 262 - lift + open
        static let time: CGFloat = sent + 104
        static let replyDots: CGFloat = sent + 146
        static let reply: CGFloat = sent + 150
        static let lastDots: CGFloat = sent + 352
        /// The chip takes the dots' place, 26pt under the reply's time, now the dots go as it lands
        static let plan: CGFloat = sent + 352
        /// The reply's arrival scrolls the chat up by this much, leaving the reply just under the avatar
        static let scroll: CGFloat = 390 - lift
        /// and the research being done, this much, taking the reply up under it too
        static let doneScroll: CGFloat = scroll + 281 - 65 + open
    }
    /// The plan chip's top left in the card: in the chat, then risen to just under the avatar once the research is done
    private var chipOrigin: CGPoint {
        researchDone ? CGPoint(x: 17, y: 106 + laterLayers + drift)
                     : CGPoint(x: 17, y: 106 - scroll + ChatY.plan + drift)
    }
    /// The open sheet's chip: where it folds back to, and how wide it is
    private var foldOrigin: CGPoint {
        switch activeSheet {
        case .research: chipOrigin
        case .analysis:
            CGPoint(x: Self.analysisChipOrigin.x, y: Self.analysisChipOrigin.y + laterLayers + drift)
        }
    }

    // MARK: Scrolling

    /// The results and everything after them are laid out for the chat scrolled to `ChatY.doneScroll`; they move with
    /// it from there, as one conversation
    private var laterLayers: CGFloat { ChatY.doneScroll - scroll }
    /// How far down the card the chat shows, in its own coordinates, with the chat unscrolled: under the avatar's
    /// band to just short of the card's foot
    private var visibleDepth: CGFloat { chatHeight - (106 - headerLift) - 24 }
    /// Where the newest thing's foot is kept: a little below the middle, so what's just arrived reads at eye level
    /// rather than down at the card's foot
    private var readingDepth: CGFloat { visibleDepth * 0.66 }
    /// Scrolls only as far as needed for something ending at `bottom` (in the chat's coordinates) to be seen, and
    /// never back down
    /// `toFoot` lets something tall settle at the card's foot instead, so what heads it stays in view.
    private func keepInView(_ bottom: CGFloat, toFoot: Bool = false) {
        let needed = bottom - (toFoot ? visibleDepth : readingDepth)
        guard needed > scroll else { return }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { scroll = needed }
    }
    /// Where the results' and the analysis's own coordinates sit in the chat's
    private static func inResults(_ y: CGFloat) -> CGFloat { y + 44 + ChatY.doneScroll - 106 }
    private static func inAnalysis(_ y: CGFloat) -> CGFloat { y + analysisLift + ChatY.doneScroll - 106 }

    // MARK: Scrolling back

    /// How far the chat has been pulled down by hand, to see what came before; it settles back to the latest as
    /// anything new arrives
    @State private var pulledBack: CGFloat = 0
    @GestureState private var pulling: CGFloat = 0
    /// How far the chat has moved up by itself, all told: as far as it can be pulled back, to the first heading
    private var autoScroll: CGFloat { scroll }
    /// The pull, held between the latest and the first message, giving a little at either end
    /// Once a topic's picked the avatar goes, and the chat rises into its place (269:3110)
    private var headerLift: CGFloat { avatarGone ? 86 : 0 }
    /// The pull, less the avatar's room once it's gone: what every layer of the chat moves by
    private var drift: CGFloat { back - headerLift }
    /// The topic, pinned over the card once it's picked, and the room it takes there
    private static let pillSpace: CGFloat = 47 + 11

    private var back: CGFloat {
        let raw = pulledBack + pulling
        if raw < 0 { return raw * 0.3 }
        if raw > autoScroll { return autoScroll + (raw - autoScroll) * 0.3 }
        return raw
    }
    private var scrollBack: some Gesture {
        DragGesture(minimumDistance: 8)
            // Only up and down; sideways drags belong to the rows of cards
            .updating($pulling) { value, state, _ in
                if abs(value.translation.height) > abs(value.translation.width) { state = value.translation.height }
            }
            .onEnded { value in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                let flung = pulledBack + value.translation.height
                    + (value.predictedEndTranslation.height - value.translation.height) * 0.5
                withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                    pulledBack = min(max(flung, 0), autoScroll)
                }
            }
    }
    /// Anything new in the chat brings it back to the latest
    private var latest: [CGFloat] {
        [scroll, typingAt ?? -1, CGFloat(resultsShown), CGFloat(advicePromptsShown),
         adviceTyping ? 1 : 0, analysisTyping ? 1 : 0, steppedBack ? 1 : 0]
    }
    private var foldSize: CGSize {
        switch activeSheet {
        case .research: CGSize(width: 283, height: 53)
        case .analysis: ReportPreparingCard.size
        }
    }
    /// The analysis's sheet is black once it's done, and 40pt taller, 20 of it upward
    /// The finished analysis is a taller sheet, standing 20pt higher
    private var analysisTall: Bool { activeSheet == .analysis && analysisDone }
    private var sheetHeight: CGFloat { analysisTall ? AnalysisSheet.blackHeight - (suggestionOut ? Self.suggestionRoom : 0) : 612 }
    /// The first report is open and being read: its suggested question has come out under the sheet, which gives
    /// up this much height for it (the chip's 53 and 12 between them)
    private var suggestionOut: Bool {
        suggestionPopped && sheetUp && !sheetClosing && analysisTall && !portfolioReportReady && !analysisStored
    }
    private static let suggestionRoom: CGFloat = 65
    /// The card is shorter by this much once compact (736 → 652, the photo 316 → 220)
    private var lift: CGFloat { compact ? 92 : 0 }

    /// How long the background takes to flow up the screen
    static let flowDuration = OnboardingAdvisoryView.flowDuration
    private static let flowEdge: CGFloat = 220

    /// The cards' and sheets' shadow: 21% black, 117pt soft, 4pt down
    static let cardShadow = 0.21
    static let cardShadowRadius: CGFloat = 117

    static let rows = ["Advisory Research", "Advisory Analysis", "Advisory Decisioning"]
    static let rowDetail = "We constantly look at market and find"
    /// What the welcome promises, one under each tile (952:11704)
    static let promises = ["Pro-active\nadvisor", "Research\nbacked", "SEBI backed"]
    private static let hairline = Color(red: 194 / 255, green: 194 / 255, blue: 194 / 255).opacity(0.53)

    var body: some View {
        // Hung from the top, as in Figma: the welcome 21 below the status bar (952:11575), the chat 11 below it
        ZStack(alignment: .top) {
            card
                .scaleEffect(shown ? 1 : 1.1)
                .opacity(shown ? 1 : 0)
                .padding(.top, (chatting ? 11 : 21) + (topicPinned ? Self.pillSpace : 0))

            // The topic that was picked, pinned over the chat (269:3110)
            if topicPinned {
                FlipPill(topic: topic?.short, flipped: topicFlipped, width: cardWidth - 20)
                    // With a sheet up it's what shows of the chat behind, so it puts the sheet away
                    .onTapGesture { if steppedBack { closeSheet() } }
                    .accessibilityAddTraits(steppedBack ? .isButton : [])
                    .padding(.top, 11)
                    .transition(.offset(y: -80).combined(with: .opacity))
                    .zIndex(1)
            }

            // The button under the card (952:11679), 344 × 49, 686 below the status bar
            if !chatting {
                continueButton
                    .padding(.top, 686)
                    .transition(.opacity)
            }

            // "Connect securely" on the chat's action card: how the funds will be brought in (952:13599), 13 under the
            // status bar
            if personalPrompt != nil {
                MFCentralImportSheet(onContinue: startImport, onUpload: {}, onClose: closeSheet)
                    .padding(.top, 13)
                    .transition(.move(edge: .bottom).combined(with: .opacity.animation(.easeOut(duration: 0.2))))
                    .zIndex(3)
            }

            // What the advisor will do with the funds (243:14078); Continue goes on to asking for them
            if advisorUp {
                ResearchIntroSheet(content: .advisor(name: AppUser.name), onUnderstood: advisorContinue)
                    .padding(.top, 109)
                    .transition(.move(edge: .bottom).combined(with: .opacity.animation(.easeOut(duration: 0.2))))
                    .zIndex(3)
            }

            // Asking for the funds (148:6099), 109pt below the status bar
            if connectUp {
                ConnectFundsSheet(onContinue: {}, onUpload: {})
                    .padding(.top, 109)
                    .transition(.move(edge: .bottom).combined(with: .opacity.animation(.easeOut(duration: 0.2))))
                    .zIndex(3)
            }

            // How the research is done (233:12750), before the agent says anything
            if researchIntroUp {
                ResearchPreviewSheet(onUnderstood: dismissResearchIntro)
                    .padding(.top, 116)
                    .transition(.move(edge: .bottom).combined(with: .opacity.animation(.easeOut(duration: 0.2))))
                    .zIndex(3)
            }

            // The research plan (141:3689), 127pt below the status bar, over the card as it steps back
            if sheetUp {
                sheet
                    .padding(.top, 127)
                    .transition(.move(edge: .bottom).combined(with: .opacity.animation(.easeOut(duration: 0.2))))
                    .zIndex(2)
            }

            // What's suggested next, out from under the report at its right edge, the sheet shorter to make room
            if suggestionOut {
                PortfolioAskChip(action: askPortfolio)
                    .frame(width: 368, alignment: .trailing)
                    .padding(.top, 127 - 20 + sheetHeight + 12)
                    .transition(.offset(y: 90).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        // Hung from the status bar's foot
        .padding(.top, insets.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(background.mask(flowMask).ignoresSafeArea())
        // Hung from the top: when the keyboard shrinks the space the page, which doesn't shrink with it, would
        // otherwise be centred in what's left and ride up under the status bar
        .overlay(alignment: .top) {
            if importRunning {
                MFImportView(top: insets.top, onDone: finishImport)
                    .ignoresSafeArea(.keyboard)
                    .transition(.opacity)
            }
        }
        .onAppear {
            let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            if let window = scene?.windows.first {
                insets = (window.bounds.height, window.safeAreaInsets.top, window.safeAreaInsets.bottom)
                screenWidth = window.bounds.width
            }
        }
        .preferredColorScheme(.light)
        // The import's answer field brings the keyboard up; nothing here should move for it
        .ignoresSafeArea(.keyboard)
        .task {
            guard !chatting else {
                // Opened straight on the chat, with the plan up
                (flow, shown, rowsShown, compact, sent, headingShown, replyShown, planShown, typingAt, scroll)
                    = (1, true, 3, true, true, true, true, true, ChatY.lastDots, max(0, ChatY.plan + 53 - readingDepth))
                if Self.startsDone {
                    (researchDone, resultsShown, typingAt, scroll) = (true, 4, nil, Self.inResults(271 + Self.resultsHeadingHeight + 29) - readingDepth)
                    if !Self.startsInAnalysis {
                        // and on to the analysis, as it would
                        startInsights()
                    } else {
                        (insightsSent, analysisTyping, analysisChipShown) = (true, false, true)
                        analysisDone = Self.startsAnalysisDone
                        activeSheet = .analysis
                        if Self.startsAdvice {
                            (analysisStarted, analysisTyping, analysisChipShown, analysisStored) = (.now, false, true, true)
                            (scroll, adviceShown, deciding) = (Self.inAnalysis(Self.adviceTop + 200) - visibleDepth, true, true)
                            advicePromptsShown = 1
                            // `-connectFlow`: the connect sheet up, moving on to its second page a moment later
                            if ProcessInfo.processInfo.arguments.contains("-connectFlow") {
                                personalPrompt = 0
                            }
                        } else {
                            sheetUp = true
                            startAnalysis()
                        }
                    }
                } else {
                    // `-researchClosed`: the research running in the chat, its sheet not open
                    sheetUp = !ProcessInfo.processInfo.arguments.contains("-researchClosed")
                    if !sheetUp { typingAt = nil }
                    startResearch()
                }
                return
            }
            await play()
        }
    }

    /// Continue: the card turns into the chat, and the agent opens it: a heading, an offer to help, and topics
    private func send() {
        Haptics.tap()
        withAnimation(.spring(response: 0.62, dampingFraction: 0.86)) {
            chatting = true
            button = .hidden
            // Decade pinned over the chat from the start, the card under it
            avatarGone = true
            topicPinned = true
        }
        // A second in, how the research is done comes up first; the agent speaks once it's understood
        Task {
            try? await Task.sleep(for: .seconds(1))
            Haptics.tap()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { researchIntroUp = true }
        }
    }

    /// How far down the live research reaches: its status line and, when it's showing one, its card
    private func researchFoot(_ live: CGFloat) -> CGFloat {
        // its status line, then (when it's showing one) its card and the source line under that
        ChatY.plan + 65 + 21 + (live > 0 ? 13 + live + 8 + 15 : 0) + 16
    }

    /// The import's own last screen moved on from: back to the chat, where the card now reads as connected
    private func finishImport() {
        Haptics.tap()
        fundsConnected = true
        withAnimation(.easeInOut(duration: 0.4)) { importRunning = false }
        Task { await preparePortfolioReport() }
    }

    /// With the funds in, the agent prepares one more report: its card under the connected one for a few seconds,
    /// then the report itself, whose Understood ends the chat
    private func preparePortfolioReport() async {
        // Thanks, and what it'll do next, as a message
        try? await Task.sleep(for: .seconds(0.9))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { thanksTyping = true }
        try? await Task.sleep(for: .seconds(1.1))
        Haptics.thresholdCrossed()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            thanksTyping = false
            thanksShown = true
        }
        // then straight into the work, shown as it goes through the funds; no plan first
        try? await Task.sleep(for: .seconds(0.6))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { portfolioThinking = .now }
        try? await Task.sleep(for: .seconds(ResearchLive.portfolioDuration))
        guard !Task.isCancelled else { return }
        // and the report it prepares from that
        Haptics.revealGrain(intensity: 0.4)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { portfolioReportShown = true }
        try? await Task.sleep(for: .seconds(3))
        guard !Task.isCancelled else { return }
        portfolioReportReady = true
        Haptics.expand()
        activeSheet = .analysis
        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { sheetUp = true }
    }

    /// Where the second report's card sits: under the connected card and its tail
    private static let portfolioReportTop = AdviceY.prompts + ConnectActionCard.size.height + 26

    /// The MFCentral sheet's Continue: the sheet goes and the import takes the screen
    private func startImport() {
        Haptics.tap()
        withAnimation(.easeInOut(duration: 0.35)) {
            importRunning = true
            personalPrompt = nil
        }
    }

    /// "Understood", or the card behind tapped: the sheet goes, and the agent opens the chat
    private func dismissResearchIntro() {
        guard researchIntroUp else { return }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) { researchIntroUp = false }
        greet()
    }

    /// The agent opens the chat (233:12632): it asks what to start on, with topics under it
    private func greet() {
        Task {
            try? await Task.sleep(for: .seconds(0.45))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { typingAt = ChatY.heading }
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                typingAt = nil
                headingShown = true
            }
            Haptics.thresholdCrossed()
            // and the topics to start on, under it (233:12632)
            try? await Task.sleep(for: .seconds(0.45))
            for _ in 0...Topic.all.count {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.84)) { topicsShown += 1 }
                Haptics.revealGrain(intensity: 0.4)
                try? await Task.sleep(for: .seconds(0.12))
            }
        }
    }

    /// A topic tapped: it goes in as the user's message, and the agent answers and plans the research around it
    private func start(_ chosen: Topic) {
        guard topic == nil else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
            topic = chosen
            topicsShown = 0
        }
        // and as it goes, the pin over the chat flips from Decade to the topic
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { topicFlipped = true }
        }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) { sent = true }
            try? await Task.sleep(for: .seconds(0.45))
            keepInView(ChatY.replyDots + 40)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { typingAt = ChatY.replyDots }
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                typingAt = nil
                replyShown = true
            }
            // the reply, 5 lines and its time, kept up where it reads
            keepInView(ChatY.reply + 175)
            Haptics.thresholdCrossed()
            // Then it types once more, over the research plan it's putting together, the chat moving up only as
            // far as it needs to
            try? await Task.sleep(for: .seconds(0.9))
            // room for the dots only, then for the chip as it arrives
            keepInView(ChatY.lastDots + 40)
            try? await Task.sleep(for: .seconds(0.25))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { typingAt = ChatY.lastDots }
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                planShown = true
                typingAt = nil
            }
            keepInView(ChatY.plan + 53)
            Haptics.settle()
            // and the research starts on it, what it's doing told under the chip; the plan opens from the chip
            startResearch()
        }
    }

    private func openPlan() {
        guard !sheetUp else { return }
        Haptics.tap()
        activeSheet = .research
        startResearch()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { sheetUp = true }
    }

    /// The research runs from the first time the plan opens, and when its time is up the chat moves on to the results
    private func startResearch() {
        guard researchStarted == nil else { return }
        researchStarted = .now
        Task {
            try? await Task.sleep(for: .seconds(ResearchSheet.researchDuration))
            await finishResearch()
        }
    }

    private func finishResearch() async {
        if steppedBack {
            closeSheet()
            try? await Task.sleep(for: .seconds(0.7))
        }
        Haptics.thresholdCrossed()
        withAnimation(.spring(response: 0.7, dampingFraction: 0.88)) {
            researchDone = true
            typingAt = nil
        }
        // the results, under the chip, heading and time
        keepInView(Self.inResults(271 + Self.resultsHeadingHeight + 29))
        try? await Task.sleep(for: .seconds(0.35))
        for _ in 0..<4 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { resultsShown += 1 }
            Haptics.revealGrain(intensity: 0.45)
            try? await Task.sleep(for: .seconds(resultsShown == 3 ? 0.3 : 0.12))
        }
        // and the agent goes straight on to the analysis, without asking
        try? await Task.sleep(for: .seconds(1.2))
        startInsights()
    }

    /// With the results in, the agent sets to work on the analysis by itself: it types under them, over a
    /// "Creating analysis" chip, and the analysis opens a moment later
    private func startInsights() {
        withAnimation(.spring(response: 0.62, dampingFraction: 0.86)) { insightsSent = true }
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            keepInView(Self.inAnalysis(384 + 40))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { analysisTyping = true }
            try? await Task.sleep(for: .seconds(0.9))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                analysisChipShown = true
                analysisTyping = false
            }
            // the report on its way
            keepInView(Self.inAnalysis(384 + ReportPreparingCard.size.height + 16))
            Haptics.settle()
            // It works on it from here, the chip opening it; it comes up by itself once it's done
            startAnalysis()
        }
    }

    private func openAnalysis() {
        guard !sheetUp else { return }
        Haptics.tap()
        activeSheet = .analysis
        startAnalysis()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { sheetUp = true }
    }

    /// The analysis has its own minute, from the first time it opens
    private func startAnalysis() {
        guard analysisStarted == nil else { return }
        analysisStarted = .now
        guard !analysisDone else { return }
        Task {
            try? await Task.sleep(for: .seconds(ResearchSheet.analysisDuration))
            Haptics.thresholdCrossed()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.88)) {
                analysisDone = true
                analysisTyping = false
            }
            // Shown whether or not it was folded away; Understood, or its close, keeps it in the chat
            if !sheetUp { openAnalysis() }
        }
    }

    /// The analysis folds itself away into the chat as a card that opens it again, and the agent moves on: advice
    /// is personal, so it asks for the user's funds
    private func storeAnalysis() async {
        guard !analysisStored else { return }
        Haptics.tap()
        // The question goes in as the user's own message, the report folding back into its card
        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) {
            analysisStored = true
            analysisTyping = false
            if sheetUp { sheetClosing = true }
        }
        try? await Task.sleep(for: .seconds(0.65))
        var quiet = Transaction()
        quiet.disablesAnimations = true
        withTransaction(quiet) {
            sheetUp = false
            sheetClosing = false
        }
        try? await Task.sleep(for: .seconds(0.5))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { adviceTyping = true }
        try? await Task.sleep(for: .seconds(1.5))
        Haptics.thresholdCrossed()
        // and the agent answers in a bubble: that's personal advice, which needs the funds
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            adviceTyping = false
            adviceShown = true
            deciding = true
        }
        // then its card asking for them
        try? await Task.sleep(for: .seconds(1.2))
        Haptics.revealGrain(intensity: 0.4)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { advicePromptsShown = 1 }
    }

    /// Where the question and what follows it sit in the analysis's part of the chat: under the report's card and
    /// its time
    private static let adviceTop: CGFloat = AdviceY.card + ReportPreparingCard.size.height + 10 + 19 + 16

    /// A personal-advice prompt tapped: advice that personal needs the funds
    private func askPersonal(_ index: Int) {
        guard !steppedBack else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { personalPrompt = index }
    }

    /// The close on the analysis: put away into its card, which opens it again
    private func doneWithAnalysis() {
        closeSheet()
    }

    /// The suggested question, from under the report or from the chat: asked in the chat, the first time
    private func askPortfolio() {
        if analysisDone && !analysisStored {
            Task { await storeAnalysis() }
        } else {
            closeSheet()
        }
    }

    /// Continue on the advisor sheet: on to connecting the funds
    private func advisorContinue() {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) { advisorUp = false }
        Task {
            try? await Task.sleep(for: .seconds(0.25))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { connectUp = true }
        }
    }

    /// "View analysis" on the stored card: the analysis opens out of it again
    private func viewAnalysis() {
        guard !steppedBack else { return }
        Haptics.tap()
        activeSheet = .analysis
        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { sheetUp = true }
    }

    private func closeConnect() {
        Haptics.tap()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) { connectUp = false }
    }

    /// Tapping the card behind: the sheet folds back into the chip it came from, as the chat comes forward to its
    /// own size, and once it's there the chip is the chat's own again
    private func closeSheet() {
        if researchIntroUp { Haptics.tap(); dismissResearchIntro(); return }
        if connectUp { closeConnect(); return }
        if personalPrompt != nil {
            Haptics.tap()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) { personalPrompt = nil }
            return
        }
        if advisorUp {
            Haptics.tap()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) { advisorUp = false }
            return
        }
        guard steppedBack else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) { sheetClosing = true }
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            var quiet = Transaction()
            quiet.disablesAnimations = true
            withTransaction(quiet) {
                sheetUp = false
                sheetClosing = false
                switch activeSheet {
                case .research: researchSeen = true
                case .analysis: analysisSeen = true
                }
            }
        }
    }

    /// Where the open sheet's chip sits relative to the sheet's centre, once the card is back at its size: the chip's
    /// centre against the sheet's, 127 + half its height down, and the card's, 182 across
    private var chipOffset: CGSize {
        CGSize(width: foldOrigin.x + foldSize.width / 2 - cardWidth / 2,
               height: 11 + foldOrigin.y + foldSize.height / 2 - (127 + sheetHeight / 2))
    }

    /// The open sheet (141:3689 or 146:5076), which can fold down into its chip: its outline shrinks to the chip's
    /// and moves onto it while its contents give way to the chip's face
    private var sheet: some View {
        let size = sheetClosing ? foldSize : CGSize(width: 368, height: sheetHeight)
        let outline = RoundedRectangle(cornerRadius: sheetClosing ? min(29, foldSize.height / 2) : 27, style: .continuous)
        return ZStack {
            Group {
                switch activeSheet {
                case .research:
                    ResearchSheet(style: .welcome, researchStarted: researchStarted, heading: topic?.plan, animatesIn: !researchSeen,
                                  researching: researchStarted != nil && !researchDone, onClose: closeSheet)
                case .analysis:
                    AnalysisSheet(started: analysisStarted ?? .now, done: analysisDone, answer: $mythAnswer, animatesIn: !analysisSeen,
                                  onClose: doneWithAnalysis, portfolio: portfolioReportReady,
                                  // On the second report, Understood ends the chat: on to the congratulations
                                  onUnderstood: portfolioReportReady ? { Haptics.tap(); onContinue() } : askPortfolio,
                                  doneHeight: sheetHeight,
                                  onRead: {
                                      guard !suggestionPopped else { return }
                                      Haptics.revealGrain(intensity: 0.45)
                                      withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { suggestionPopped = true }
                                  })
                }
            }
            .scaleEffect(sheetClosing ? 0.85 : 1)
            .opacity(sheetClosing ? 0 : 1)
            Group {
                switch activeSheet {
                case .research: planChipFace
                case .analysis:
                    analysisChipFace
                }
            }
            .opacity(sheetClosing ? 1 : 0)
        }
        .frame(width: 368, height: sheetHeight)
        .mask(outline.frame(width: size.width, height: size.height))
        .background(
            outline
                .fill(Color.white)
                .frame(width: size.width, height: size.height)
                .shadow(color: Color.black.opacity(sheetClosing ? 0.03 : Self.cardShadow), radius: sheetClosing ? 30 : Self.cardShadowRadius, x: 0, y: 4)
        )
        // The black sheet stands 20pt higher (146:4908)
        .offset(sheetClosing ? chipOffset : CGSize(width: 0, height: analysisTall ? -20 : 0))
        .allowsHitTesting(!sheetClosing)
    }

    private func play() async {
        withAnimation(.easeInOut(duration: Self.flowDuration)) { flow = 1 }
        try? await Task.sleep(for: .seconds(Self.flowDuration * 0.7))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.62, dampingFraction: 0.86)) { shown = true }
        try? await Task.sleep(for: .seconds(0.35))
        for _ in Self.rows {
            try? await Task.sleep(for: .seconds(0.12))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { rowsShown += 1 }
        }
        // A beat to read it, then Continue comes in under the card
        try? await Task.sleep(for: .seconds(0.6))
        guard !Task.isCancelled else { return }
        Haptics.settle()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { button = .open }
    }

    /// The full-width button under the welcome card (952:11679): 344 × 49, the label centred
    private var continueButton: some View {
        Button(action: send) {
            Text("Lets get started")
                .font(FigmaFont.walsheimMedium(17))
                .foregroundStyle(Color.white)
                .offset(x: 0.5)
                .frame(width: 344, height: 49)
                // Gap: Figma #1F1513 fill and Shadow/1 (0 4 100 +12 at 5%), drawn without its spread
                .background(Capsule().fill(Color(hex: 0x1F1513)))
                .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
        }
        .buttonStyle(PressScaleStyle())
        .scaleEffect(button == .open ? 1 : 0.96)
        .opacity(button == .open ? 1 : 0)
        .allowsHitTesting(button == .open)
        .accessibilityHidden(button != .open)
    }

    /// Black pill with a chevron: a 45pt dot first, then it stretches out to the left and the words come in
    private func pillButton(_ title: String, width: CGFloat, stage: ButtonStage, action: @escaping () -> Void) -> some View {
        let shape = Capsule()
        return Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .fixedSize()
                    .opacity(stage == .open ? 1 : 0)
                    .offset(x: stage == .open ? 0 : 14)
                Image("ContinueChevron")
                    .frame(width: 23, height: 23)
            }
            .padding(.trailing, 9)
            .frame(width: stage == .open ? width : 45, height: 45, alignment: .trailing)
            .background(Color.black)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .scaleEffect(stage == .hidden ? 0.3 : 1, anchor: .trailing)
        .opacity(stage == .hidden ? 0 : 1)
        .allowsHitTesting(stage == .open)
    }

    /// Once chatting, the card runs down to the foot of the screen, 11pt short of it, as it sits 11pt under the top
    private var chatHeight: CGFloat { insets.height - insets.top - insets.bottom - 19 - (topicPinned ? Self.pillSpace : 0) }

    /// Opaque from the bottom up to the rising edge, feathered so the background seeps rather than wipes
    private var flowMask: some View {
        GeometryReader { geo in
            let travel = geo.size.height + Self.flowEdge
            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: Self.flowEdge)
                Color.black
                    .frame(height: geo.size.height)
            }
            .offset(y: geo.size.height - flow * travel)
        }
        .ignoresSafeArea()
    }

    /// surface/base, as in the frames (679:24216, 699:24516)
    private var background: some View { ColorScale.surfaceBase }

    /// "Flight card background" (952:11578), 364 × 622; the chat's card (699:24519) once chatting
    private var card: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            if chatting {
                chat
                    .offset(y: 106 - scroll + drift)
                    .transition(.identity)
            }
            if researchDone {
                results
                    // 44pt lower than in Figma, for the avatar; and on with the insights chat as it moves on
                    .offset(y: 44 + laterLayers + drift)
                    .transition(.identity)
            }
            if insightsSent {
                analysisChat
                    .transition(.identity)
            }
            if chatting {
                // The heading's white band, which the chat scrolls up under (141:3980)
                Color.white
                    .frame(width: cardWidth, height: 105 - headerLift)
                    .transition(.identity)
            }

            Group {

            // 952:11684: the photo across the top of the card, 218 tall
            Image("WelcomeAdvisoryPhoto")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 378, height: 290)
                .offset(x: -6, y: -44)
                .frame(width: 364, height: 218, alignment: .topLeading)
                .clipped()
                .scaleEffect(shown ? 1 : 1.06)

            // "Hello Arindam" with its wave (952:11707), inside the card now
            HStack(spacing: 10) {
                Image("OnboardingWave")
                    .frame(width: 25.261, height: 25.577)
                DsText("Hello \(AppUser.name)", variant: .h3)
                    .fixedSize()
            }
            .frame(width: 364, height: 39)
            .at(0, 253)

            // Gap: Reckless Medium 35/43 has no text style; the colour is content/primary
            GapText("Welcome to Decade Wealth Advisory", family: .reckless, medium: true, size: 35, lineHeight: 43, color: ColorScale.contentPrimary)
                .multilineTextAlignment(.center)
                .frame(width: 318)
                .at(23, 299)

            // 952:11687: three outlined tiles, each over its line
            ForEach(Array(Self.promises.enumerated()), id: \.offset) { index, promise in
                let centre = 64.5 + 118 * CGFloat(index)
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(ColorScale.borderSubtle, lineWidth: 1)
                    .frame(width: 93, height: 91)
                    .at(centre - 46.5, 422)
                    .accessibilityHidden(true)
                Text(promise)
                    .font(FigmaFont.walsheim(17))
                    .lineSpacing(23 - UIFont(name: "GTWalsheimTrial-Rg", size: 17)!.lineHeight)
                    .foregroundStyle(ColorScale.contentSecondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 111, alignment: .top)
                    .at(centre - 55.5, 524)
            }
            }
            // The welcome goes, rising a little as it fades
            .opacity(chatting ? 0 : 1)
            .offset(y: chatting ? -30 : 0)
            // Faded out, but still where the topics are; it mustn't catch their taps
            .allowsHitTesting(!chatting)

            // The agent, heading the chat (225:11773)
            if chatting {
                VStack(spacing: 1) {
                    Image("DecadeAvatar").frame(width: 61, height: 61)
                    Text("Decade")
                        .font(FigmaFont.reckless(19))
                        .foregroundStyle(Color(hex: 0x212121).opacity(0.74))
                        .frame(height: 25)
                }
                .frame(width: cardWidth)
                .at(0.5, 11)
                // gone once a topic's picked, the topic pinned above the card in its place
                .opacity(avatarGone ? 0 : 1)
                .scaleEffect(avatarGone ? 0.8 : 1, anchor: .top)
                .transition(.scale(scale: 0.8, anchor: .top).combined(with: .opacity))
            }

            // Over the heading band, so it can rise to just under the heading when the research is done
            if planShown {
                planChip
                    .at(chipOrigin.x, chipOrigin.y)
                    // It sits over the heading band, so it fades as the results scroll up past it
                    .opacity(chipOrigin.y < 100 - headerLift ? 0 : 1)
                    .animation(.easeOut(duration: 0.2), value: chipOrigin.y < 100 - headerLift)
                    .transition(.scale(scale: 0.9, anchor: .leading).combined(with: .opacity).combined(with: .offset(y: 8)))
            }
        }
        .frame(width: cardWidth, height: chatting ? chatHeight : 622, alignment: .topLeading)
        // radius/27 as the welcome, radius/23 as the chat (699:24519)
        .clipShape(RoundedRectangle(cornerRadius: chatting ? 23 : 27, style: .continuous))
        // Pulled down to see what came before, while nothing's open over it
        .simultaneousGesture(scrollBack, including: chatting && !steppedBack ? .all : .subviews)
        .onChange(of: latest) { _, _ in
            guard pulledBack != 0 else { return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) { pulledBack = 0 }
        }
        // Gap: Shadow/3 (0 2 85 +7 at 11%) as the welcome, Shadow/1 (0 4 100 +12 at 5%) as the chat; no spread in SwiftUI
        .shadow(color: Color.black.opacity(chatting ? 0.05 : 0.11), radius: chatting ? 50 : 42, x: 0, y: chatting ? 4 : 2)
        // Steps back under the research plan (141:4031: 338 wide, from the top); tapping it there brings it forward
        .scaleEffect(steppedBack ? 338 / 364 : 1, anchor: .top)
        .overlay {
            if steppedBack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: closeSheet)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel("Back to chat")
            }
        }
    }

    /// The conversation, laid out from its top as in Figma
    private var chat: some View {
        ZStack(alignment: .topLeading) {
            if headingShown {
                // "Good evening" with its wave (802:6023), over the question
                HStack(spacing: 10) {
                    Image("OnboardingWave")
                        .frame(width: 25.261, height: 25.577)
                    DsText("Good evening", variant: .h3)
                        .fixedSize()
                }
                .frame(width: cardWidth, height: 39)
                .at(0, ChatY.heading - 54)
                .transition(.opacity.combined(with: .offset(y: 10)))
                // 699:24520: Reckless Medium 35 on 43pt lines, tighter than the font's own, so each is set on its own
                VStack(alignment: .center, spacing: 0) {
                    ForEach(Self.questionLines, id: \.self) { line in
                        Text(line)
                            .font(FigmaFont.reckless(35))
                            .fixedSize()
                            .frame(height: 43)
                    }
                }
                // Gap: Figma #33302D, unbound
                .foregroundStyle(Color(hex: 0x33302D))
                .frame(width: cardWidth)
                .at(0, ChatY.heading)
                .transition(.opacity.combined(with: .offset(y: 10)))
            }
            topics
            // While the research runs, what it's doing, and now and then the data it's going over (270:16266)
            if let researchStarted, !researchDone, planShown {
                ResearchLive(started: researchStarted, equityYear: topic == Topic.all[0]) { height in
                    keepInView(researchFoot(height))
                }
                .frame(width: ResearchLive.cardWidth, alignment: .leading)
                .at((cardWidth - ResearchLive.cardWidth) / 2, ChatY.plan + 65)
                .transition(.opacity)
            }
            if sent, let topic {
                ChatBubble(message: ChatMessage(text: topic.title, fromAgent: false), showsRead: false, timestamp: Self.sentAt)
                    .frame(width: cardWidth)
                    // 11pt in from the card's right edge, as in 141:3682
                    .offset(x: 4)
                    .at(0, ChatY.sent)
                    .transition(.scale(scale: 0.9, anchor: .bottomTrailing).combined(with: .opacity).combined(with: .offset(y: 12)))
            }
            if replyShown, let topic {
                ChatBubble(message: ChatMessage(text: topic.reply, fromAgent: true), showsRead: false, timestamp: Self.sentAt)
                    .frame(width: cardWidth)
                    .offset(x: 2)
                    .at(0, ChatY.reply)
                    .transition(.scale(scale: 0.9, anchor: .bottomLeading).combined(with: .opacity).combined(with: .offset(y: 12)))
            }
            if let y = typingAt {
                TypingBubble()
                    .frame(width: cardWidth)
                    .at(0, y)
                    .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
            }
        }
        .frame(width: cardWidth, alignment: .topLeading)
    }

    /// The topics as cards under the question (699:24609 onwards): two rows, running off the card's right edge
    private var topics: some View {
        // Across first: the top row fills before the bottom one
        let top = Array(Topic.all.indices.prefix((Topic.all.count + 1) / 2))
        let bottom = Array(Topic.all.indices.dropFirst(top.count))
        return SidewaysRail(width: cardWidth) {
            VStack(alignment: .leading, spacing: 17) {
                ForEach([top, bottom], id: \.self) { row in
                    HStack(alignment: .top, spacing: 17) {
                        ForEach(row, id: \.self) { index in
                            let option = Topic.all[index]
                            Button { start(option) } label: { topicCard(option, index: index) }
                                .buttonStyle(.plain)
                                .accessibilityLabel(option.title)
                                .opacity(topicsShown > index + 1 ? 1 : 0)
                                .offset(y: topicsShown > index + 1 ? 0 : 12)
                                .allowsHitTesting(topicsShown > index + 1)
                                .accessibilityHidden(topicsShown <= index + 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 19)
            .padding(.vertical, 20)
        }
        .frame(width: cardWidth, height: 192 + 17 + 192 + 40, alignment: .topLeading)
        .at(0, ChatY.topics - 20)
        .allowsHitTesting(topicsShown > 1)
    }

    /// What each topic's card shows over its question (256:15685): bars, in the scale of Figma's earlier, larger
    /// chart, and a colour; or, for the third, a ring
    private static let topicCharts: [(bars: [CGFloat], color: Color)?] = [
        ([30.75, 37.5, 49.125, 72.75], Color(hex: 0x19D522)),
        ([53, 43, 28, 21].map { $0 / 0.7105 }, Color(hex: 0xE3521B)),
        nil,
    ]

    /// One topic (1080:14026), 186 × 192: what it's about, the arrow, and the question under them
    @ViewBuilder private func topicCard(_ topic: Topic, index: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 33, style: .continuous)
        // The fourth and fifth share the last wash
        let wash = Self.topicWashes[min(index, Self.topicWashes.count - 1)]
        ZStack(alignment: .topLeading) {
            Color(hex: 0xFEFEFE)
            LinearGradient(colors: wash.colors.map { Color(hex: $0).opacity(wash.opacity) }, startPoint: .leading, endPoint: .trailing)
            Text(topic.label)
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Color.black.opacity(0.57))
                .fixedSize()
                .frame(height: 19)
                .at(15, 13)
            Text(topic.title)
                .font(FigmaFont.walsheim(17))
                .lineSpacing(21 - 17 * 1.2)
                .foregroundStyle(Color.black)
                .frame(width: 156, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .at(15, 47)
            Image("OnboardingTopicArrowWhite")
                .frame(width: 23, height: 23)
                .at(150, 13)
        }
        .frame(width: 186, height: 192, alignment: .topLeading)
        .clipShape(shape)
    }

    /// Gap: the topic cards' washes over #FEFEFE, left to right, read off 699:24609, 802:6031, 802:6043 and 802:6037
    /// (their gradients don't export cleanly); none are tokens
    private static let topicWashes: [(colors: [UInt32], opacity: Double)] = [
        ([0xFFCB41, 0xFFC189], 0.13),
        ([0xB6B7CD, 0xADCAE1], 0.12),
        ([0xB9D4C9, 0xB8C6A3], 0.13),
        ([0xFFE589, 0xD1B8C9], 0.15),
    ]

/// The personal-advice prompts' washes of colour, left to right, sampled from 316:18337 (its gradients don't
    /// export cleanly): top row yellow-to-peach and mauve-to-lavender, under them sage-and-mint and gold-to-blush;
    /// the third column's two in the same family
    private static let adviceWashes: [[(UInt32, Double)]] = [
        [(0xFFCB44, 0), (0xFEC569, 0.5), (0xFBC08D, 1)],
        [(0xCDB7B0, 0), (0xC4B9C0, 0.33), (0xB7B7CC, 0.66), (0xB5B8CE, 1)],
        [(0xB9C7D9, 0), (0xB3C6DF, 0.5), (0xADCAE1, 1)],
        [(0xCECDB5, 0), (0xBAD4C9, 0.33), (0xB9CEBB, 0.66), (0xB8C9AB, 1)],
        [(0xE3D39F, 0), (0xE2D4AB, 0.33), (0xD8CFB6, 0.83), (0xD5C4C2, 1)],
        [(0xFFD27A, 0), (0xF6C9A4, 0.6), (0xE9C3B8, 1)],
    ]

    /// A personal-advice prompt (316:18134), 186 × 192: "Mutual funds market" and the question on a wash of colour
    static func advicePromptCard(_ title: String, index: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 33, style: .continuous)
        let wash = adviceWashes[index % adviceWashes.count].map { Gradient.Stop(color: Color(hex: $0.0), location: $0.1) }
        return ZStack(alignment: .topLeading) {
            LinearGradient(stops: wash, startPoint: .leading, endPoint: .trailing)
            Text("Mutual funds market")
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Color.black.opacity(0.61))
                .fixedSize()
                .frame(height: 19)
                .at(15, 13)
            Text(title)
                .font(FigmaFont.walsheim(17))
                .lineSpacing(21 - 17 * 1.2)
                .foregroundStyle(Color.black)
                .frame(width: 156, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .at(15, 110)
        }
        .frame(width: 186, height: 192, alignment: .topLeading)
        .clipShape(shape)
        .shadow(color: Color.black.opacity(0.07), radius: 22, x: 0, y: 2)
    }

    /// A prompt as the connect sheet shows it (802:6423, 817:6434), 186 × 192: the label, the question and its arrow,
    /// on a faint wash of colour, or on plain #FEFEFE with a hairline edge
    static func tintedPromptCard(_ title: String, washed: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 33, style: .continuous)
        let wash = topicWashes[0]
        return ZStack(alignment: .topLeading) {
            Color(hex: 0xFEFEFE)
            if washed {
                LinearGradient(colors: wash.colors.map { Color(hex: $0).opacity(wash.opacity) }, startPoint: .leading, endPoint: .trailing)
            }
            Text("Mutual funds market")
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Color.black.opacity(0.57))
                .fixedSize()
                .frame(height: 19)
                .at(15, 13)
            Text(title)
                .font(FigmaFont.walsheim(17))
                .lineSpacing(21 - 17 * 1.2)
                .foregroundStyle(Color.black)
                .frame(width: 140, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .at(15, 110)
            Image("OnboardingTopicArrow")
                .frame(width: 23, height: 23)
                .at(150, 110)
        }
        .frame(width: 186, height: 192, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(ColorScale.borderSubtle.opacity(washed ? 0 : 1), lineWidth: 0.7))
    }

    /// A prompt as a card (256:15732): "Mutual funds market", a small chart or ring, then the question
    static func promptCard(_ title: String, chart index: Int, height: CGFloat = 192) -> some View {
        let shape = RoundedRectangle(cornerRadius: 33, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Color(hex: 0xFEFEFE)
            Text("Mutual funds market")
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Color.black.opacity(0.57))
                .fixedSize()
                .frame(height: 19)
                .at(15, 13)
            if let chart = Self.topicCharts[index % Self.topicCharts.count] {
                // The earlier 126 × 103 chart, at 89.5 × 73
                Self.topicChart(chart.bars, color: chart.color)
                    .scaleEffect(0.7105, anchor: .topLeading)
                    .frame(width: 89.5, height: 73, alignment: .topLeading)
                    .at(15, 32)
            } else {
                // 256:15712: a ring
                Circle()
                    .stroke(Color(hex: 0x167CCC), lineWidth: 3)
                    .frame(width: 55, height: 55)
                    .at(15 + 1.5, 32 + 9.5)
            }
            Text(title)
                .font(FigmaFont.walsheim(17))
                .lineSpacing(21 - 17 * 1.2)
                .foregroundStyle(Color.black)
                .multilineTextAlignment(.leading)
                .frame(width: 156, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .at(15, 110)
        }
        .frame(width: 186, height: height, alignment: .topLeading)
        .clipShape(shape)
        .shadow(color: Color.black.opacity(0.07), radius: 22, x: 0, y: 2)
    }

    /// 126 × 103: four bars on faint rules, the periods under them, and the scale down the right
    private static func topicChart(_ bars: [CGFloat], color: Color) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach([0.56, 45.56, 90.56], id: \.self) { y in
                Rectangle().fill(Color.black.opacity(0.05))
                    .frame(width: 111, height: 0.375)
                    .at(0, y - 0.19)
            }
            ForEach(Array(bars.enumerated()), id: \.offset) { i, height in
                Rectangle().fill(color)
                    .frame(width: 16.125, height: height)
                    .at(7.5 + CGFloat(i) * 29.625, 90.75 - height)
            }
            HStack(spacing: 0) {
                ForEach(["6M", "1Y", "3Y", "5Y"], id: \.self) { period in
                    Text(period)
                    if period != "5Y" { Spacer(minLength: 0) }
                }
            }
            .font(FigmaFont.walsheim(4.5))
            .tracking(0.315)
            .foregroundStyle(Color.black.opacity(0.6))
            .frame(width: 95.25, height: 6.375)
            .at(12, 96.38)
            ForEach([12.38, 42.38, 87.37], id: \.self) { y in
                Text("¢900")
                    .font(FigmaFont.walsheim(4.5))
                    .tracking(0.315)
                    .foregroundStyle(Color.black.opacity(0.4))
                    .frame(width: 30, height: 6.375, alignment: .trailing)
                    .at(126.38 - 30, y)
            }
        }
        .frame(width: 126, height: 102.75, alignment: .topLeading)
    }

    /// Asking for the insights (146:4796): the message, the agent typing, and the analysis it's creating
    private var analysisChat: some View {
        ZStack(alignment: .topLeading) {
            if insightsShown {
                // Its foot where the 97pt bubble's is in Figma, whatever its height
                ChatBubble(message: Self.insights, showsRead: false, timestamp: Self.sentAt)
                    .frame(width: cardWidth)
                    .offset(x: 4)
                    .at(0, 252)
                    .transition(.scale(scale: 0.9, anchor: .bottomTrailing).combined(with: .opacity).combined(with: .offset(y: 12)))
            }
            if analysisTyping {
                TypingBubble()
                    .frame(width: cardWidth)
                    .at(0, 384)
                    .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
            }
            if analysisChipShown {
                // The report (1027:11737): being prepared while the analysis is built, and after that the way back
                // into it. It opens by itself once done.
                Button(action: openAnalysis) { analysisChipFace }
                    .buttonStyle(.plain)
                    .accessibilityLabel(analysisDone ? "View analysis" : "Preparing report")
                    .at(Self.analysisChipOrigin.x, Self.analysisChipOrigin.y - Self.analysisLift)
                    .transition(.scale(scale: 0.94, anchor: .topLeading).combined(with: .opacity).combined(with: .offset(y: 12)))
            }
            if analysisStored {
                Self.stamp.at(17, AdviceY.card + ReportPreparingCard.size.height + 10)
                    .opacity(sheetUp && activeSheet == .analysis ? 0 : 1)
            }
            // What was asked from the report, and what follows, as the chat's own bubbles and cards
            VStack(alignment: .leading, spacing: 18) {
                // With the report closed and nothing asked yet, the same suggestion waits here, at the right
                if analysisDone, !analysisStored, !(sheetUp && activeSheet == .analysis) {
                    PortfolioAskChip(action: askPortfolio)
                        .frame(width: cardWidth - 11, alignment: .trailing)
                        .transition(.scale(scale: 0.9, anchor: .bottomTrailing).combined(with: .opacity))
                }
                if analysisStored {
                    ChatBubble(message: ChatMessage(text: PortfolioAskChip.question, fromAgent: false), showsRead: false, timestamp: Self.sentAt)
                        .frame(width: cardWidth)
                        .offset(x: 4)
                        .transition(.scale(scale: 0.9, anchor: .bottomTrailing).combined(with: .opacity).combined(with: .offset(y: 12)))
                }
                if adviceTyping {
                    TypingBubble()
                        .frame(width: cardWidth)
                        .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
                }
                if adviceShown {
                    ChatBubble(message: ChatMessage(text: "That’s a personal advisory question. To answer it I need access to your mutual funds.", fromAgent: true),
                               showsRead: false, timestamp: Self.sentAt)
                        .frame(width: cardWidth)
                        .offset(x: 2)
                        .transition(.scale(scale: 0.9, anchor: .bottomLeading).combined(with: .opacity).combined(with: .offset(y: 12)))
                    // What it needs for that, as its own card in the chat (1012:10877); no prompts, no sheet first
                    if advicePromptsShown > 0 {
                        ConnectActionCard(connected: fundsConnected, onConnect: { askPersonal(0) })
                            .padding(.leading, 17)
                            .transition(.scale(scale: 0.92, anchor: .bottomLeading).combined(with: .opacity).combined(with: .offset(y: 14)))
                    }
                    if thanksTyping {
                        TypingBubble()
                            .frame(width: cardWidth)
                            .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
                    }
                    if thanksShown {
                        ChatBubble(message: ChatMessage(text: "Thanks for connecting. I’ll now check how this affects your portfolio.", fromAgent: true),
                                   showsRead: false, timestamp: Self.sentAt)
                            .frame(width: cardWidth)
                            .offset(x: 2)
                            .transition(.scale(scale: 0.9, anchor: .bottomLeading).combined(with: .opacity).combined(with: .offset(y: 12)))
                    }
                    // Going through the funds, as the research showed its work; it gives way to the report
                    if let portfolioThinking, !portfolioReportShown {
                        ResearchLive(started: portfolioThinking, portfolio: true)
                            .frame(width: ResearchLive.cardWidth, alignment: .leading)
                            .padding(.leading, (cardWidth - ResearchLive.cardWidth) / 2)
                            .transition(.opacity)
                    }
                    // and, once it has, the report it prepares on them (1027:11737 again)
                    if portfolioReportShown {
                        ReportPreparingCard(title: "Your portfolio performance", subject: "Your mutual funds")
                            .padding(.leading, 17)
                            .transition(.scale(scale: 0.94, anchor: .topLeading).combined(with: .opacity).combined(with: .offset(y: 12)))
                    }
                }
            }
            .frame(width: cardWidth, alignment: .topLeading)
            // The chat follows it down as it grows
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                guard height > 0 else { return }
                keepInView(Self.inAnalysis(Self.adviceTop + height + 24), toFoot: true)
            }
            .at(0, Self.adviceTop)
        }
        .frame(width: cardWidth, alignment: .topLeading)
        .offset(y: Self.analysisLift + laterLayers + drift)
    }

    /// The analysis on its way, as the report's card
    private var analysisChipFace: some View {
        ReportPreparingCard(title: topic?.short ?? "Small caps performance", subject: topic?.plan ?? "Small cap funds",
                            ready: analysisDone)
    }

    /// What the research found (146:4615, 146:4794): the counts, sideways, then the heading
    private var results: some View {
        ZStack(alignment: .topLeading) {
            SidewaysRail(width: cardWidth) {
                HStack(spacing: 7) {
                    ForEach(Array(ResearchSheet.counts.enumerated()), id: \.offset) { index, count in
                        ResearchSheet.countTile(count)
                            .opacity(resultsShown > index ? 1 : 0)
                            .offset(y: resultsShown > index ? 0 : 14)
                    }
                }
                .padding(.horizontal, 21)
            }
            .frame(width: cardWidth, height: 104)
            .at(0, 126)
            MorningstarMark()
                .opacity(resultsShown > 2 ? 1 : 0)
                .at(21, 238)

            ChatBubble(message: ChatMessage(text: "We have all its required to analyze it now", fromAgent: true),
                       showsRead: false, timestamp: Self.sentAt)
                .frame(width: cardWidth)
                .offset(x: 2)
                .opacity(resultsShown > 3 ? 1 : 0)
                .scaleEffect(resultsShown > 3 ? 1 : 0.9, anchor: .bottomLeading)
                .offset(y: resultsShown > 3 ? 0 : 12)
                .at(0, 271)
        }
    }

    /// "Mutual funds research plan" (146:4320), 283 × 53: the plan the agent is preparing; opens it
    private var planChip: some View {
        Button(action: openPlan) { planChipFace }
            .buttonStyle(.plain)
            .accessibilityLabel("Mutual funds research plan")
    }

    private var planChipFace: some View {
        let shape = Capsule()
        return HStack(spacing: 0) {
                Image("PlanDoc")
                    .frame(width: 17, height: 17)
                    .padding(.leading, 15)
                Text("Mutual funds research plan")
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color.black)
                    .fixedSize()
                    .padding(.leading, 11)
                Spacer(minLength: 0)
                Image("PlanChevron")
                    .frame(width: 23, height: 23)
                    .padding(.trailing, 5)
            }
            .frame(width: 283, height: 53)
            .background(Color.white)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
    }

    /// An agent's message's time, under it on the left
    private static var stamp: some View {
        Text(sentAt)
            .font(FigmaFont.walsheim(13))
            .foregroundStyle(Color(hex: 0x89898D))
            .frame(height: 19)
    }

    /// When the message went, as a time
    private static let sentAt: String = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: .now)
    }()

    /// The three ways of working (137:3241), 330 × 219
    private var list: some View {
        let shape = RoundedRectangle(cornerRadius: 23, style: .continuous)
        return ZStack(alignment: .topLeading) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { index, title in
                let top = 73 * CGFloat(index)
                ZStack(alignment: .topLeading) {
                    Image("OnboardingWayYellow")
                        .frame(width: 39, height: 39)
                        .at(14, 16)
                    Text(index == 0 && deciding ? "Advisory Decisioning" : title)
                        .font(FigmaFont.walsheim(17))
                        .foregroundStyle(Color.black.opacity(0.85))
                        .frame(height: 25)
                        .at(67, 12)
                    Text(Self.rowDetail)
                        .font(FigmaFont.walsheim(13))
                        .foregroundStyle(Color.black.opacity(0.45))
                        .frame(height: 21)
                        .at(67, 38)
                }
                .frame(width: 330, height: 73, alignment: .topLeading)
                .opacity(rowsShown > index && !(chatting && index > 0) ? 1 : 0)
                .offset(y: rowsShown > index ? 0 : 10)
                .at(0, top)
                if index > 0 {
                    Self.hairline
                        .frame(width: 330, height: 1)
                        .at(-1, top - 1)
                }
            }
        }
        // Down to its first row as the chat's heading
        .frame(width: 330, height: chatting ? 73 : 219, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Self.hairline, lineWidth: 1))
    }
}

#Preview {
    OnboardingDecadeWelcomeView(onContinue: {})
}

/// A row of cards that slides sideways under a horizontal drag, and lets vertical ones through to the chat it sits
/// in, which a horizontal scroll view wouldn't
struct SidewaysRail<Content: View>: View {
    let width: CGFloat
    @ViewBuilder let content: Content

    @State private var offset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @GestureState private var drag: CGFloat = 0

    var body: some View {
        let reach = max(0, contentWidth - width)
        let raw = offset + drag
        // Gives a little past either end
        let shown = raw > 0 ? raw * 0.3 : raw < -reach ? -reach + (raw + reach) * 0.3 : raw
        content
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { contentWidth = $0 }
            .offset(x: shown)
            .frame(width: width, alignment: .leading)
            .contentShape(Rectangle())
            // Over the cards' own taps, so a drag never counts as one
            .highPriorityGesture(
                DragGesture(minimumDistance: 8)
                    .updating($drag) { value, state, _ in
                        if abs(value.translation.width) > abs(value.translation.height) { state = value.translation.width }
                    }
                    .onEnded { value in
                        guard abs(value.translation.width) > abs(value.translation.height) else { return }
                        let flung = offset + value.translation.width
                            + (value.predictedEndTranslation.width - value.translation.width) * 0.6
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                            offset = min(0, max(-reach, flung))
                        }
                    }
            )
    }
}

/// Pinned over the chat: Decade, on white (316:17791), until a topic's picked, when it flips over to the topic (269:3110)
struct FlipPill: View {
    let topic: String?
    let flipped: Bool
    var width: CGFloat = 348

    var body: some View {
        Color.clear
            .frame(width: width, height: 47)
            .modifier(Flip(angle: flipped ? 180 : 0, front: decade, back: TopicPill(title: topic ?? "", width: width)))
    }

    /// Turns about its long axis, showing the front until it's edge-on, then the back
    private struct Flip<Front: View, Back: View>: ViewModifier, Animatable {
        var angle: Double
        let front: Front
        let back: Back
        var animatableData: Double {
            get { angle }
            set { angle = newValue }
        }

        func body(content: Content) -> some View {
            ZStack {
                if angle < 90 {
                    front
                } else {
                    back.rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                }
            }
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        }
    }

    private var decade: some View {
        HStack(spacing: 8) {
            Image("DecadeMarkWhite")
                .renderingMode(.template)
                .foregroundStyle(Color.black)
                .frame(width: 33, height: 33)
            Text("Decade")
                .font(FigmaFont.walsheimMedium(19))
                .foregroundStyle(Color.black.opacity(0.85))
        }
        .padding(.leading, 11)
        .frame(width: width, height: 47, alignment: .leading)
        .background(Capsule().fill(ColorScale.surfaceWidget))
        .overlay(Capsule().strokeBorder(ColorScale.borderSubtle, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

/// The topic picked, pinned over the chat (269:3110), 348 × 47: a light blue capsule with its icon and name
struct TopicPill: View {
    let title: String
    var width: CGFloat = 348

    var body: some View {
        HStack(spacing: 8) {
            icon
            Text(title)
                .font(FigmaFont.walsheimMedium(19))
                .foregroundStyle(Color.black.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.leading, 11)
        .frame(width: width, height: 47, alignment: .leading)
        .background(Capsule().fill(Color(hex: 0xDEF4FA)))
        .accessibilityElement(children: .combine)
    }

    /// 269:3053: the bank, in a soft green coin
    private var icon: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(hex: 0x87C28E), Color(hex: 0xDAF6B6)],
                                         startPoint: UnitPoint(x: 0.25, y: 0.06), endPoint: UnitPoint(x: 0.78, y: 0.94)))
            Circle().fill(LinearGradient(stops: [.init(color: Color(hex: 0x567C6D), location: 0),
                                                 .init(color: Color(hex: 0xDAF6B6).opacity(0), location: 0.5)],
                                         startPoint: UnitPoint(x: 0.49, y: 0.05), endPoint: UnitPoint(x: 0.78, y: 0.94)))
                .opacity(0.6)
            Circle().fill(LinearGradient(stops: [.init(color: Color(hex: 0xF6F48B).opacity(0.7), location: 0),
                                                 .init(color: Color(hex: 0xDAF6B6).opacity(0), location: 0.5)],
                                         startPoint: .trailing, endPoint: .leading))
            Circle().strokeBorder(Color.white.opacity(0.55), lineWidth: 1.5)
                .blur(radius: 0.8)
                .padding(1.5)
            Image("TopicBank")
                .resizable()
                .frame(width: 32, height: 32)
                .offset(y: -0.7)
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
        .background(Circle().fill(Color.white).shadow(color: Color.black.opacity(0.07), radius: 5, x: 0, y: 0.7))
        .frame(width: 33, height: 33)
    }
}

/// 323:18755: five funds' last six months, as grey bars in an outlined box on black (AMFI NAVs, May to 5 Nov 2026)
private struct TopicReturnsMini: View {
    private static let rows: [(ticker: String, name: String, domain: String, ret: Double)] = [
        ("SBI", "Healthcare", "sbimf.com", 15.5),
        ("ICICI", "Technology", "icicipruamc.com", 10.4),
        ("DSP", "Small Cap", "dspim.com", 8.1),
        ("SBI", "Gold", "sbimf.com", -4.9),
        ("ICICI", "Infra", "icicipruamc.com", -5.1),
    ]
    private static let step: CGFloat = 18.81

    var body: some View {
        let box = RoundedRectangle(cornerRadius: 15, style: .continuous)
        ZStack(alignment: .topLeading) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { i, r in
                let y = 3 + CGFloat(i) * Self.step
                Text(r.ticker)
                    .font(FigmaFont.walsheim(6))
                    .foregroundStyle(Color.white)
                    .fixedSize()
                    .at(6.9, y + 1.4)
                SourceLogo(domain: r.domain)
                    .scaleEffect(6.9 / 17)
                    .frame(width: 6.9, height: 6.9)
                    .at(26, y + 1.8)
                Text(r.name)
                    .font(FigmaFont.walsheim(6))
                    .tracking(0.42)
                    .foregroundStyle(Color.white.opacity(0.4))
                    .fixedSize()
                    .at(34.5, y + 1.4)
                let w = 66.5 * CGFloat(abs(r.ret) / 15.5)
                Rectangle()
                    .fill(r.ret < 0 ? Color(hex: 0xD9D9D9) : i % 2 == 0 ? Color(hex: 0xD3D3D3) : Color(hex: 0x989898))
                    .frame(width: max(w, 4), height: 10.55)
                    .at(r.ret < 0 ? 82.6 - max(w, 4) : 82.6, y)
                Text(String(format: "%+.1f%%", r.ret))
                    .font(FigmaFont.walsheim(5.5))
                    .tracking(0.39)
                    .foregroundStyle(r.ret < 0 ? Color.white.opacity(0.5) : Color.black.opacity(0.55))
                    .fixedSize()
                    .at(r.ret < 0 ? 85 : 85, y + 1.6)
                if i > 0 {
                    Rectangle().fill(Color.white.opacity(0.08)).frame(width: 162, height: 0.6).at(0, y - 4.1)
                }
            }
        }
        .frame(width: 162, height: 90, alignment: .topLeading)
        .clipShape(box)
        .overlay(box.strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
    }
}

/// 316:18561: a rating scale from red to green, a marker near the low end, and ticks along it
private struct TopicRatingMini: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(stops: [.init(color: Color(hex: 0xF87D7F), location: 0),
                                   .init(color: Color(hex: 0xF6D642), location: 0.61),
                                   .init(color: Color(hex: 0xC3E882), location: 1)],
                           startPoint: .leading, endPoint: .trailing)
                .frame(width: 137, height: 32)
                .at(0, 13.6)
            ForEach([13.5, 39.0, 64.6, 90.2, 115.7], id: \.self) { x in
                Rectangle().fill(Color.white.opacity(0.6)).frame(width: 0.7, height: 16.3).at(x, 21.4)
            }
            Capsule()
                .fill(Color.white)
                .overlay(Capsule().strokeBorder(Color(hex: 0xB6C0CC), lineWidth: 0.7))
                .shadow(color: Color.black.opacity(0.13), radius: 1.4, x: 0, y: 2.8)
                .frame(width: 5.7, height: 38.3)
                .at(17, 10.8)
            ForEach(Array([("1★", 0.0), ("3★", 62.0), ("5★", 124.0)].enumerated()), id: \.offset) { _, l in
                Text(l.0)
                    .font(FigmaFont.walsheim(8.5))
                    .foregroundStyle(Color.black.opacity(0.54))
                    .fixedSize()
                    .at(l.1, 50)
            }
        }
        .frame(width: 156, height: 73, alignment: .topLeading)
    }
}
