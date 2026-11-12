import SwiftUI

/// Figma "iPhone 14 Plus - 336" (130:2823): after the PAN card's Verify. The soft background flows up over the identity
/// screen first, then the "Welcome to Decade Advisory" card lands from 1.1× with its photo, and the three ways of
/// working settle in one under another. A moment later (141:3372) the photo shortens, pulling the card up, and a
/// Continue button forms under it, the way the advisory chat button does: a dot with the chevron that stretches out.
///
/// Continue turns the card into a chat with the agent (225:11648): it sheds the photo and the welcome for the Decade
/// avatar, and the agent asks "Jojo, lets start with a topic you’re interested in?" over three topics
/// to start on (225:11778). The one tapped goes in as the user's message; the agent types, replies to it, scrolls up
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

        static let all = [
            Topic(title: "How mutual funds performed in the last 6 months?",
                  reply: "Good place to start. I’ll go through six months of NAVs, portfolio disclosures and factsheets across categories, and see which funds held up, which slipped, and why.",
                  plan: "Mutual funds, the last 6 months", short: "Mutual funds performance"),
            Topic(title: "Why some high rated funds have performed badly?",
                  reply: "Ratings look backwards, so this is worth digging into. I’ll set star ratings against recent returns, holdings and manager changes, and find where they part ways.",
                  plan: "High rated funds, falling behind", short: "High rated funds slipping"),
            Topic(title: "How fund managers are positioned with current geopolitical situation?",
                  reply: "I’ll read the latest portfolio disclosures and fund manager commentary to see how they’ve moved across sectors and markets as things have shifted.",
                  plan: "Fund managers and geopolitics", short: "Fund managers & geopolitics"),
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
    private static let questionLines = ["Jojo, lets start", "with a topic you’re", "interested in?"]
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
    static let promptsHeight: CGFloat = 192 * 2 + 13

    private enum ChatY {
        /// The opening question sits lower in the card, centred, with the topics under it (316:17768)
        static let open: CGFloat = 68
        static let heading: CGFloat = 25 + open + 3
        /// Everything under the question sits this much higher than it did under the larger, four-line one
        static let lift: CGFloat = 51
        static let topicsLabel: CGFloat = 271 - lift + open
        static let topics: CGFloat = 309 - lift + open
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
            analysisStored ? analysedOrigin
                           : CGPoint(x: Self.analysisChipOrigin.x, y: Self.analysisChipOrigin.y + laterLayers + drift)
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
    private static let pillSpace: CGFloat = 47 + 8

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
        case .analysis: analysisStored ? CGSize(width: 299, height: 275) : CGSize(width: 209, height: 53)
        }
    }
    /// The analysis's sheet is black once it's done, and 40pt taller, 20 of it upward
    /// The finished analysis is a taller sheet, standing 20pt higher
    private var analysisTall: Bool { activeSheet == .analysis && analysisDone }
    private var sheetHeight: CGFloat { analysisTall ? AnalysisSheet.blackHeight : 612 }
    /// The card is shorter by this much once compact (736 → 652, the photo 316 → 220)
    private var lift: CGFloat { compact ? 92 : 0 }

    /// How long the background takes to flow up the screen
    static let flowDuration = OnboardingAdvisoryView.flowDuration
    private static let flowEdge: CGFloat = 220

    /// The cards' and sheets' shadow: 21% black, 117pt soft, 4pt down
    static let cardShadow = 0.21
    static let cardShadowRadius: CGFloat = 117

    private static let rows = ["Advisory Research", "Advisory Analysis", "Advisory Decisioning"]
    private static let rowDetail = "We constantly look at market and find"
    private static let hairline = Color(red: 194 / 255, green: 194 / 255, blue: 194 / 255).opacity(0.53)

    var body: some View {
        // Hung from the top, as in Figma: 55pt down, 11 below the status bar
        ZStack(alignment: .top) {
            card
                .scaleEffect(shown ? 1 : 1.1)
                .opacity(shown ? 1 : 0)
                .padding(.top, 11 + (topicPinned ? Self.pillSpace : 0))

            // The topic that was picked, pinned over the chat (269:3110)
            if topicPinned {
                FlipPill(topic: topic?.short, flipped: topicFlipped, width: cardWidth - 16)
                    // With a sheet up it's what shows of the chat behind, so it puts the sheet away
                    .onTapGesture { if steppedBack { closeSheet() } }
                    .accessibilityAddTraits(steppedBack ? .isButton : [])
                    .padding(.top, 11)
                    .transition(.offset(y: -80).combined(with: .opacity))
                    .zIndex(1)
            }

            // "Continue" (141:3285), 119 × 45, 19pt under the compact card, 25 in from the right
            continueButton
                .frame(width: MutualFundScreen.canvasWidth, alignment: .trailing)
                .padding(.trailing, 25)
                .padding(.top, 682)

            // Asking for the funds for personal advice, with the prompt that was tapped (256:15540)
            // and, on Continue, how they'll be brought in (256:15592), in the same sheet
            if let personalPrompt {
                ConnectFlowSheet(prompt: Self.advicePrompts[personalPrompt], chart: personalPrompt, importing: $importUp)
                    .padding(.top, 36)
                    .transition(.move(edge: .bottom).combined(with: .opacity.animation(.easeOut(duration: 0.2))))
                    .zIndex(3)
            }

            // What the advisor will do with the funds (243:14078); Continue goes on to asking for them
            if advisorUp {
                ResearchIntroSheet(content: .advisor(name: "Jojo"), onUnderstood: advisorContinue)
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
                ResearchIntroSheet(onUnderstood: dismissResearchIntro)
                    .padding(.top, 109)
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
        }
        // Hung from the status bar's foot
        .padding(.top, insets.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(background.mask(flowMask).ignoresSafeArea())
        .onAppear {
            let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            if let window = scene?.windows.first {
                insets = (window.bounds.height, window.safeAreaInsets.top, window.safeAreaInsets.bottom)
                screenWidth = window.bounds.width
            }
        }
        .preferredColorScheme(.light)
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
                            (analysisStarted, analysisTyping, analysisChipShown, analysisStored) = (.now, false, false, true)
                            (scroll, adviceShown, deciding) = (Self.inAnalysis(AdviceY.prompts + Self.promptsHeight) - visibleDepth, true, true)
                            advicePromptsShown = Self.advicePrompts.count
                            // `-connectFlow`: the connect sheet up, moving on to its second page a moment later
                            if ProcessInfo.processInfo.arguments.contains("-connectFlow") {
                                personalPrompt = 0
                                Task {
                                    try? await Task.sleep(for: .seconds(1.5))
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) { importUp = true }
                                }
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
            for _ in 0..<4 {
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
            // the chip, and what it's doing under it
            keepInView(Self.inAnalysis(384 + 65 + 21 + 16))
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
        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) {
            analysisStored = true
            analysisTyping = false
            analysisChipShown = false
            if sheetUp { sheetClosing = true }
        }
        try? await Task.sleep(for: .seconds(0.65))
        var quiet = Transaction()
        quiet.disablesAnimations = true
        withTransaction(quiet) {
            sheetUp = false
            sheetClosing = false
        }
        keepInView(Self.inAnalysis(AdviceY.card + 275 + 29))
        try? await Task.sleep(for: .seconds(0.5))
        // room for the dots only, then for each thing as it arrives
        keepInView(Self.inAnalysis(AdviceY.dots + 40))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { adviceTyping = true }
        try? await Task.sleep(for: .seconds(1.5))
        Haptics.thresholdCrossed()
        // "Wealth advise is useful when its personalized" (256:15910)
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            adviceTyping = false
            adviceShown = true
            deciding = true
        }
        keepInView(Self.inAnalysis(AdviceY.heading + AdviceY.headingHeight + 29))
        // then what could be sent, once it's personal
        try? await Task.sleep(for: .seconds(1.2))
        keepInView(Self.inAnalysis(AdviceY.prompts + Self.promptsHeight), toFoot: true)
        // one by one, slowly, each easing up into place
        for _ in Self.advicePrompts {
            withAnimation(.easeOut(duration: 0.7)) { advicePromptsShown += 1 }
            Haptics.revealGrain(intensity: 0.4)
            try? await Task.sleep(for: .seconds(0.45))
        }
    }

    /// A personal-advice prompt tapped: advice that personal needs the funds
    private func askPersonal(_ index: Int) {
        guard !steppedBack else { return }
        Haptics.tap()
        // on its first page
        importUp = false
        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { personalPrompt = index }
    }

    /// Understood, or the close, on the finished analysis: kept in the chat the first time; just put away after
    private func doneWithAnalysis() {
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
                                  onClose: doneWithAnalysis, onUnderstood: doneWithAnalysis)
                }
            }
            .scaleEffect(sheetClosing ? 0.85 : 1)
            .opacity(sheetClosing ? 0 : 1)
            Group {
                switch activeSheet {
                case .research: planChipFace
                case .analysis:
                    if analysisStored { AnalysedCard(onView: {}) } else { analysisChipFace }
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
        // A beat to read it, then the photo gives up some height and Continue forms in the room it leaves
        try? await Task.sleep(for: .seconds(1.2))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.88)) { compact = true }
        try? await Task.sleep(for: .seconds(0.3))
        Haptics.settle()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.7)) { button = .dot }
        try? await Task.sleep(for: .seconds(0.22))
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) { button = .open }
    }

    /// Black pill with a chevron: a 45pt dot first, then it stretches out to the left and the word comes in
    private var continueButton: some View {
        pillButton("Continue", width: 119, stage: button, action: send)
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
    private var chatHeight: CGFloat { insets.height - insets.top - insets.bottom - 22 - (topicPinned ? Self.pillSpace : 0) }

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

    /// The soft backdrop the advisory screens share
    private var background: some View { DecadeBackdrop() }

    /// "Flight card background" (137:3194), 364 × 736; 652 once compact, 613 as the chat
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

            // 137:3196: the photo, cropped to the top of the card, over the brown it was shot against
            LinearGradient(colors: [Color(hex: 0xAD898E), Color(hex: 0x70523A)], startPoint: .top, endPoint: .bottom)
                .overlay {
                    Image("WelcomePhone")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 572, height: 775)
                        .offset(x: 15, y: -0.5)
                }
                .frame(width: 364, height: 316 - lift)
                .clipped()
                .scaleEffect(shown ? 1 : 1.06)
                .at(0, -18)

            Text("Hello Jojo")
                .font(FigmaFont.walsheimMedium(23))
                .foregroundStyle(Color.black)
                .frame(width: 364, height: 29)
                .at(0.5, 321 - lift)

            Text("Welcome to Decade Advisory")
                .font(FigmaFont.reckless(44))
                .lineSpacing(45 - 44 * 1.2)
                .foregroundStyle(Color(hex: 0x212121))
                .multilineTextAlignment(.center)
                .frame(width: 330)
                .at(17, 357 - lift)

            Text("How we work")
                .font(FigmaFont.walsheimMedium(15))
                .tracking(1.05)
                .textCase(.uppercase)
                .foregroundStyle(Color.black.opacity(0.46))
                .frame(width: 364, height: 23)
                .at(0.5, 464 - lift)
            }
            // The welcome goes, rising a little as it fades
            .opacity(chatting ? 0 : 1)
            .offset(y: chatting ? -30 : 0)
            // Faded out, but still where the topics are; it mustn't catch their taps
            .allowsHitTesting(!chatting)

            // 17pt off the bottom, 25 once compact; it gives way to the avatar once chatting
            list
                .at(17, 736 - 17 - 219 - (compact ? 92 : 0))
                .opacity(chatting ? 0 : 1)
                .offset(y: chatting ? -30 : 0)
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
        .frame(width: cardWidth, height: chatting ? chatHeight : 736 - (compact ? 84 : 0),
               alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        // Pulled down to see what came before, while nothing's open over it
        .simultaneousGesture(scrollBack, including: chatting && !steppedBack ? .all : .subviews)
        .onChange(of: latest) { _, _ in
            guard pulledBack != 0 else { return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) { pulledBack = 0 }
        }
        .shadow(color: Color.black.opacity(Self.cardShadow), radius: Self.cardShadowRadius, x: 0, y: 4)
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
                // 45pt lines, tighter than the font's own, so each is set on its own
                VStack(alignment: .center, spacing: 0) {
                    ForEach(Self.questionLines, id: \.self) { line in
                        Text(line)
                            .font(FigmaFont.reckless(Self.headingSize))
                            .frame(height: Self.headingLine)
                    }
                }
                .foregroundStyle(Color(hex: 0x212121))
                .frame(width: cardWidth)
                .at(0, ChatY.heading)
                .transition(.opacity.combined(with: .offset(y: 10)))
            }
            topics
            // While the research runs, what it's doing, and now and then the data it's going over (270:16266)
            if let researchStarted, !researchDone, planShown {
                ResearchLive(started: researchStarted) { height in
                    keepInView(ChatY.plan + 65 + 21 + (height > 0 ? 13 + height + 8 + 15 : 0) + 16)
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

    /// "Popular right now" and the topics as cards (233:12989), under the question
    private var topics: some View {
        ZStack(alignment: .topLeading) {
            // "Popular right now" (233:13015), over the cards
            Text("Popular right now")
                .font(FigmaFont.walsheimMedium(15))
                .tracking(1.05)
                .textCase(.uppercase)
                .foregroundStyle(Color.black.opacity(0.46))
                .frame(width: cardWidth, height: 23)
                .at(0, ChatY.topicsLabel)
                .opacity(topicsShown > 0 ? 1 : 0)
                .offset(y: topicsShown > 0 ? 0 : 10)
            // The topics as cards, sideways (233:13249): 221 × 242, 21pt apart, running off the card's edge
            SidewaysRail(width: cardWidth) {
                HStack(alignment: .top, spacing: 11) {
                    ForEach(Array(Topic.all.enumerated()), id: \.offset) { index, option in
                        Button { start(option) } label: { topicCard(option, index: index) }
                            .buttonStyle(.plain)
                            .accessibilityLabel(option.title)
                            .opacity(topicsShown > index + 1 ? 1 : 0)
                            .offset(y: topicsShown > index + 1 ? 0 : 12)
                            .allowsHitTesting(topicsShown > index + 1)
                            .accessibilityHidden(topicsShown <= index + 1)
                    }
                }
                .padding(.horizontal, 17)
                // Room for the cards' shadows
                .padding(.vertical, 20)
            }
            .frame(width: cardWidth, height: 282)
            .at(0, ChatY.topics - 20)
            .allowsHitTesting(topicsShown > 1)
        }
    }

    /// What each topic's card shows over its question (256:15685): bars, in the scale of Figma's earlier, larger
    /// chart, and a colour; or, for the third, a ring
    private static let topicCharts: [(bars: [CGFloat], color: Color)?] = [
        ([30.75, 37.5, 49.125, 72.75], Color(hex: 0x19D522)),
        ([53, 43, 28, 21].map { $0 / 0.7105 }, Color(hex: 0xE3521B)),
        nil,
    ]

    /// One topic (256:15732), 186 wide: "Mutual funds market", a small chart, then the question; 192 tall, or 213
    /// for a four-line question
    /// The opening topics (316:18557): a dark card of fund returns as bars, a white one with a rating scale, and
    /// one with rising bars
    @ViewBuilder private func topicCard(_ topic: Topic, index: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 33, style: .continuous)
        let dark = index == 0
        ZStack(alignment: .topLeading) {
            (dark ? Color(hex: 0x151515) : Color(hex: 0xFEFEFE))
            if !dark {
                Text("Mutual funds market")
                    .font(FigmaFont.walsheim(15))
                    .foregroundStyle(Color.black.opacity(0.57))
                    .fixedSize()
                    .frame(height: 19)
                    .at(15, 13)
            }
            Group {
                switch index {
                case 0: TopicReturnsMini().offset(x: -3, y: -19)
                case 1: TopicRatingMini()
                default:
                    Self.topicChart([30.75, 37.5, 49.125, 72.75], color: Color(hex: 0x19D522))
                        .scaleEffect(0.7105, anchor: .topLeading)
                        .frame(width: 89.5, height: 73, alignment: .topLeading)
                }
            }
            .at(15, 32)
            Text(topic.title)
                .font(FigmaFont.walsheim(17))
                .lineSpacing(21 - 17 * 1.2)
                .foregroundStyle(dark ? Color.white : Color.black)
                .frame(width: 156, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .at(15, 110)
        }
        .frame(width: 186, height: index == 2 ? 213 : 192, alignment: .topLeading)
        .clipShape(shape)
        .shadow(color: Color.black.opacity(0.07), radius: 22, x: 0, y: 2)
    }

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
                Button(action: openAnalysis) { analysisChipFace }
                    .buttonStyle(.plain)
                    .at(Self.analysisChipOrigin.x, Self.analysisChipOrigin.y - Self.analysisLift)
                    .transition(.scale(scale: 0.9, anchor: .leading).combined(with: .opacity).combined(with: .offset(y: 8)))
            }
            // While it works, what it's doing, as the research's line did
            if let analysisStarted, analysisChipShown, !analysisDone, !analysisStored {
                AnalysisLive(started: analysisStarted, duration: ResearchSheet.analysisDuration)
                    .at(Self.analysisChipOrigin.x + 11, Self.analysisChipOrigin.y - Self.analysisLift + 65)
                    .transition(.opacity)
            }
            // The analysis, kept (148:5911); it appears under the sheet folding into it
            if analysisStored {
                AnalysedCard(onView: viewAnalysis)
                    .at(17, AdviceY.card)
                    .opacity(sheetUp && activeSheet == .analysis ? 0 : 1)
                    .transition(.identity)
                Self.stamp.at(17, AdviceY.card + 275 + 10)
                    .opacity(sheetUp && activeSheet == .analysis ? 0 : 1)
            }
            if adviceTyping {
                TypingBubble()
                    .frame(width: cardWidth)
                    .at(0, AdviceY.dots)
                    .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
            }
            if adviceShown {
                // Lines tighter than the font's own, so each is set on its own
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Self.adviceLines, id: \.self) { line in
                        Text(line)
                            .font(FigmaFont.reckless(Self.headingSize))
                            .frame(height: Self.headingLine)
                    }
                }
                .foregroundStyle(Color(hex: 0x212121))
                .at(17, AdviceY.heading)
                .transition(.opacity.combined(with: .offset(y: 10)))
                Self.stamp.at(17, AdviceY.heading + AdviceY.headingHeight + 10)
                    .transition(.opacity)
                // What could be asked, sideways like the topics
                SidewaysRail(width: cardWidth) {
                    VStack(alignment: .leading, spacing: 13) {
                        ForEach(0..<Self.promptRows, id: \.self) { row in
                            let perRow = Self.advicePrompts.count / Self.promptRows
                            HStack(alignment: .top, spacing: 11) {
                                ForEach(row * perRow..<(row + 1) * perRow, id: \.self) { index in
                                    let prompt = Self.advicePrompts[index]
                                    Button { askPersonal(index) } label: { Self.advicePromptCard(prompt, index: index) }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(prompt)
                                        .opacity(advicePromptsShown > index ? 1 : 0)
                                        .scaleEffect(advicePromptsShown > index ? 1 : 0.94)
                                        .offset(y: advicePromptsShown > index ? 0 : 24)
                                        .allowsHitTesting(advicePromptsShown > index)
                                        .accessibilityHidden(advicePromptsShown <= index)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 17)
                    .padding(.vertical, 20)
                }
                .frame(width: cardWidth, height: Self.promptsHeight + 40)
                .at(0, AdviceY.prompts - 20)
            }
        }
        .frame(width: cardWidth, alignment: .topLeading)
        .offset(y: Self.analysisLift + laterLayers + drift)
    }

    /// "Creating analysis" (146:4893), 209 × 53; "Analysis ready" once it's done
    private var analysisChipFace: some View {
        let shape = Capsule()
        return HStack(spacing: 0) {
            Image("PlanDoc")
                .frame(width: 17, height: 17)
                .padding(.leading, 15)
            Text(analysisDone ? "Analysis ready" : "Creating analysis")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black)
                .fixedSize()
                .padding(.leading, 11)
                .contentTransition(.opacity)
            Spacer(minLength: 0)
            Image("PlanChevron")
                .frame(width: 23, height: 23)
                .padding(.trailing, 5)
        }
        .frame(width: 209, height: 53)
        .background(Color.white)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
        .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
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
                    Image("HowWeWorkGlyph")
                        .frame(width: 33, height: 33)
                        .at(14, [16, 17, 20][index])
                    Text(index == 0 && deciding ? "Advisory Decisioning" : title)
                        .font(FigmaFont.walsheim(17))
                        .foregroundStyle(Color.black.opacity(0.85))
                        .frame(height: 25)
                        .at(57, 12)
                    Text(Self.rowDetail)
                        .font(FigmaFont.walsheim(13))
                        .foregroundStyle(Color.black.opacity(0.45))
                        .frame(height: 21)
                        .at(57, 38)
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
        .background(Capsule().fill(Color.white))
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
