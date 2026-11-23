import SwiftUI

/// The second onboarding's opening, right after the PAN: seven frames of 390 × 840 on one ground.
///
/// A Continue apart, three of welcome:
/// - "Welcome to new standard of wealth advisory" (1267:12910): under the status bar's rule, "Hello" and the name,
///   the heading, what the advisory promises on four cards, two by two between the margins, and Continue.
/// - "Proactive, so you don’t miss" (1251:12475, its phone 1341:2551) and "Analysis backed by research"
///   (1267:15806). On the first, the heading over a phone that stands up out of the foot of the screen, with
///   what the advisor has noticed by itself told on it one at a time: each comes out of a handle at the top, is
///   read, and closes into a handle under it as the next comes out, on three washes of colour in turn. On the second, for now, there's no phone: a book on the page, drawn
///   as the report's cube is, its pages blank and turning. (Before that, and kept behind `-researchGather`: a
///   phone on which documents drawn in lines come in to fill it, moving and changing all the while, and draw
///   together into one of its research reports, which scrolls itself up it, held for as long as a finger is on it.)
///
/// Then the advisor:
/// - First (1341:2567) what there is to ask about, fund houses' and companies' marks and questions about them,
///   comes at the screen and goes away into it, one thing after another; she comes in over all of it, larger than
///   the screen, and down to her size.
/// - "Meet your personal advisor" (1362:5808): her portrait, "Hello" and the name under it, and at the foot of
///   the page the "Ask your advisor" pill, with "Tap to try!" pointing at it. (The pill is the phone's own, the
///   phone drawn larger and none of it shown but the pill. "Access your advisor anytime", 1249:6146, which had the
///   pill on the foot of a phone after a round "Say Hi", is no longer gone through; its `access` stays in the list.)
/// - Tapped (1362:6195), a tick stands where the heading was, and the pill rides up over a keyboard, both still
///   on the page; after a beat they go down, and it's the phone, at its size and in its place:
/// - "Tell your advisor to research on a topic" (1251:7096): the phone with prompts in two columns, and "Select
///   any topic" pointing at them.
/// - Picked, a tick stands where the heading was, at once, and on the phone, on its yellow wash, the documents the report
///   is made from keep coming, each large and going away smaller, and then draw together; as they do the phone rises
///   under "Wealth simplified for you", and what grows out of where they met is the simple report alone, which
///   scrolls. Then Continue. That version is kept behind `-reportSimple`. What runs without it:
/// - Picked, a tick stands where the heading was, at once, and the phone shows what the advisor goes through
///   (1354:3723): its plan, what it gathered, the counts and the sites it read, one under another, only the top
///   one clear and the rest lost in a blur that deepens down the screen. All of it goes up a part at a time, with
///   a rest after each. Under it the first onboarding's chat itself, already asked that, has run to its report at
///   many times its pace, unseen.
/// - When that has had its time, "Wealth simplified for you" (1249:4944): the phone
///   rises, and as it does the report is there out of focus and comes clear from the top down, as what she went
///   through did and much faster. Then a line comes in
///   across its screen from the right to the middle (1249:5255), the report to its left and the same thing put
///   simply to its right (1277:18139). It goes across and back twice to show it moves, and comes to rest with
///   three quarters of the screen simple. The line is dragged either way; dragged all the way left, the heading
///   becomes "Decades of research, simplified for you".
/// - "Lets see how to use the app" (1362:7957): those words alone in the middle of the page, with no phone, for a
///   couple of seconds, and on by itself.
/// - "Hold any widget to get curious" (1249:2716) and "Swipe and get specific" (1251:6920): a widget on the
///   phone's screen, under her picture, for the first onboarding's hold and then its swipe. Neither has a
///   Continue: done, a tick stands where the heading was, and a moment after what it brought up it goes on by itself.
/// - "Adjust to what feels comfortable": after the swipe and on the phone the same way, the first onboarding's
///   reading-level card and its slider (792:13117), the chart gone up to the place above it. This one has a Continue.
/// - Last, "All set! Connect your portfolio & get insights" (1251:12800): her picture and the name again, the
///   heading, three things that can be asked once the funds are in, and "Connect mutual funds", which brings up how
///   they're brought in through MFCentral (the first onboarding's sheet for it). Going on from that ends the onboarding.
///
/// It arrives as the first onboarding's welcome does: its ground flows up over the PAN screen, what's on it settles
/// in, and Continue comes up once that's been read. Between frames the ground and the rule stay where they are; the
/// words change over, and what's under them goes and comes.
struct OnboardingWelcomeV2View: View {
    let onContinue: () -> Void

    @Environment(\.onboardingTop) private var top
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far up the ground has flowed, 0 to 1
    @State private var flow: CGFloat = 0
    @State private var shown = false
    @State private var buttonShown = false
    @State private var stage = OnboardingWelcomeV2View.startStage
    /// The line between the report and its simple version. It's kept apart from this view's own state, and only
    /// `CompareLayer` reads where it stands, so dragging the line redraws that and nothing else: not the page,
    /// and not the chat with its report under it, which is what made the drag drag
    @State private var compare = Compare()

    @Observable final class Compare {
        /// Where the line stands across the phone's screen: 0 at its left edge (all simple) to 1 at its right (all
        /// the report)
        var split: CGFloat = 1 {
            didSet {
                // (kept apart from where the line is, so that only a change of sides is told to what reads it)
                let leads = split > 0.5
                if leads != reportLeads { reportLeads = leads }
            }
        }
        /// The report has more of the screen than its simple version: more than half
        private(set) var reportLeads = true
        /// The line has been shown moving and has come to rest, or a finger has taken it: from then the side with
        /// less of the screen is out of focus
        var focusing = false
        var shown = false
        /// A finger has been on the line: it's no longer shown how it moves
        var touched = false
        /// The line's been dragged all the way left, to nothing but the simple version: the heading says so
        var simplified = false
    }
    /// Continue has come up
    @State private var controlsShown = false
    /// The frame's gesture, the hold or the swipe, has been done: Continue comes up
    @State private var gestureDone = false
    /// Continue's been tapped after the hold: its widget is going back to its place, and the next frame follows
    @State private var holdLeaving = false
    /// With a gesture done and what it brings up there to see, how long that's left before it goes on by itself
    private static let gestureRest: TimeInterval = 0.6
    /// The chat on the phone, unseen, has its report up
    @State private var chatReported = false
    /// and what she went through for it has been shown: the report is what's on the phone now
    @State private var reportShown = OnboardingWelcomeV2View.startStage > .chat
    /// How far down the phone's screen the report is clear, as it's shown: it comes out of a blur from the top,
    /// as what she went through did, and much faster
    @State private var reportFront: CGFloat = 0
    /// and it's clear all the way down: the blurred one over it is done with
    @State private var reportCleared = OnboardingWelcomeV2View.startStage > .chat
    /// Before she's met: she has come in over what was going away (`WorldBefore`), down to her size
    @State private var advisorIn = false
    /// What was going away has been taken in under her
    @State private var worldGone = false
    /// and she's there to be met: the heading, her name and "Say Hi"
    @State private var met = false
    /// "We will import mutual funds via MFCentral" is up, from the last frame's button
    @State private var mfCentralUp = false

    enum Stage: Int, Comparable {
        case welcome, simplest, research, meet, access, typing, topics, chat, simple, usage, hold, swipe, levels, connect

        static func < (a: Stage, b: Stage) -> Bool { a.rawValue < b.rawValue }

        /// Nothing over the keyboard frame
        var heading: String? {
            switch self {
            case .welcome: "Welcome to new standard of wealth advisory"
            case .simplest: "Proactive, so you don’t miss"
            case .research: "Analysis backed by research"
            case .meet: "Meet your personal advisor"
            case .access: "Access your advisor anytime"
            case .typing: nil
            case .topics: "Tell your advisor to research on a topic"
            case .chat: nil
            case .simple: "Wealth simplified for you"
            case .usage: "Lets see how to use the app"
            case .hold: "Hold any widget to get curious"
            case .swipe: "Swipe and get specific"
            case .levels: "Adjust to what feels comfortable"
            case .connect: "All set! Connect your portfolio & get insights"
            }
        }

        /// The heading as the frame breaks it, where that isn't where it would break by itself
        var headingLines: String? {
            switch self {
            case .access: "Access your advisor\nanytime"
            case .hold: "Hold any widget\nto get curious"
            case .levels: "Adjust to what\nfeels comfortable"
            case .simple: "Wealth simplified\nfor you"
            case .simplest: "Proactive, so you\ndon’t miss"
            case .research: "Analysis backed\nby research"
            case .usage: "Lets see how to use\nthe app"
            default: heading
            }
        }

        /// Where the heading's top sits on the frame
        var headingTop: CGFloat {
            switch self {
            case .welcome: 120
            case .simplest, .research: 120
            // 1362:8052: in the middle of the page
            case .usage: 381
            case .meet: 106
            case .access, .typing, .chat, .simple, .hold, .swipe, .levels: 104
            case .connect: 274
            case .topics: 109
            }
        }

        /// Where the advisor's phone stands (1249:6253, 1251:6731, 1277:16355, 1251:12128)
        var deviceTop: CGFloat {
            switch self {
            case .typing: 189
            case .topics: 239
            case .chat: 269
            // (and where it's left from, on the last frame)
            case .simple, .usage, .hold, .swipe, .levels, .connect: 217
            default: 30
            }
        }

        /// How far down the page's own colour is laid over the phone's head (1251:6329, 1251:6435, 1251:12073)
        var veil: CGFloat {
            switch self {
            case .access: 476
            case .chat: 325
            default: 377
            }
        }
    }

    /// `-onboardingV2Stage N` opens on its Nth frame (0 to 13)
    private static var startStage: Stage {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-onboardingV2Stage"), i + 1 < args.count, let n = Int(args[i + 1]) else {
            return .welcome
        }
        return Stage(rawValue: n) ?? .welcome
    }

    /// What the advisory promises, on a card (1267:15780): under a cube in one of three tints
    struct Card: Hashable {
        let promise: String
        let cube: String
        /// The frame draws each cube at its own size; this is how far across
        let cubeWidth: CGFloat
    }

    /// The frame's four cards, a row each (1267:15779)
    static let rows: [[Card]] = [
        [
            Card(promise: "Advice backed by real research", cube: "TopicCubeGreen", cubeWidth: 56.719),
            Card(promise: "Advice built around your goals only", cube: "TopicCubeAmber", cubeWidth: 63.695),
        ],
        [
            Card(promise: "Always active, we spot things before you do", cube: "TopicCubePink", cubeWidth: 59.813),
            Card(promise: "Recommendations from SEBI-registered advisors", cube: "TopicCubeGreen", cubeWidth: 56.719),
        ],
    ]

    /// The prompts' washes of colour, left to right, read off the frames (their gradients don't export cleanly):
    /// yellow to peach, mauve to lavender, the same paler, sage, and two that are barely there. The first frames'
    /// phone (1267:12887) shows four of them down it; the last one's (1277:16357) six, in two columns. Both have
    /// more under those, below the screen's foot.
    private static let washes: [[UInt32]] = [
        [0xFFCB43, 0xFEC855, 0xFFC669, 0xFEC27C, 0xFBC18E],
        [0xD2BBB3, 0xC3B8C0, 0xB6B7CD, 0xB5B9CF, 0xB4BAD0],
        [0xE2D3CE, 0xD9D2D7, 0xD1D2DF, 0xD0D2E0, 0xCFD3E1],
        [0xDFDECF, 0xD5E0D6, 0xD0DFD6, 0xD0DCCE, 0xD0DBC9],
        [0xF7F2E1, 0xF5F1E3, 0xF2EFE6, 0xF1EDE9, 0xF0EAEB],
        [0xF8F4DE, 0xF3F2E4, 0xEEF0E9, 0xE9EFEF, 0xE4EDF5],
    ]

    /// What every prompt on the phone asks (the frame's stand-in), as the chat's topic: what's sent, the agent's
    /// reply to it, and what its research plan is called. The research and the report are the equity one's.
    private static let asked = OnboardingDecadeWelcomeView.Topic(
        title: "How mutual funds performed in the last 6 months?",
        reply: "Good place to start. I’ll compare the last six months of returns across equity fund categories, see which held up and which slipped, and what that tells us.",
        plan: "Mutual funds, the last 6 months", short: "Mutual funds performance")
    /// The chat on the phone is the app's own at this scale: its card, 368 across, is 283 there (1251:12227)
    private static let chatScale: CGFloat = 283.0 / 368
    /// and it all goes this many times faster than in the first onboarding: the messages, the research, the report.
    /// It isn't seen until its report is up, which has to be within the three seconds `ResearchRun` takes.
    private static let chatPace: Double = 40
    /// Beside its simple version the report is a little larger: 294.4 across (1249:5010), its top 47.2 down the phone
    private static let reportScale: CGFloat = 0.8
    /// Where the line comes to rest: a quarter of the way across, three quarters of the screen simple
    private static let splitRest: CGFloat = 0.25
    /// How it gets there: in from the right, and across and back twice, each for this long
    private static let splitSway: [(to: CGFloat, time: TimeInterval)] = [(0.25, 0.7), (0.72, 0.6), (0.18, 0.6), (0.6, 0.55)]
    /// The heading once the line's been dragged all the way left
    private static let simplifiedHeading = "Decades of research, simplified for you"
    /// Beside each other, how far out of focus the side with less of the screen is, and how slowly the two change over
    fileprivate static let unfocused: CGFloat = 7
    fileprivate static let refocusing = Animation.easeInOut(duration: 0.9)

    private static let flowEdge: CGFloat = 220
    private static let phoneTop: CGFloat = 274
    private static let outline = Color(hex: 0xC6C6C6)
    private static let move = Animation.spring(response: 0.6, dampingFraction: 0.84)

    /// How the words change over: the old ones lift away as they blur out, the new come up into focus after them
    static let words = AnyTransition.asymmetric(
        insertion: .modifier(active: Wording(lift: 14, shown: false), identity: Wording(lift: 0, shown: true))
            .animation(.easeOut(duration: 0.6).delay(0.25)),
        removal: .modifier(active: Wording(lift: -10, shown: false), identity: Wording(lift: 0, shown: true))
            .animation(.easeIn(duration: 0.3))
    )
    /// What points something out comes in last, once what it points at has settled: the words,
    private static let pointer = AnyTransition.asymmetric(
        insertion: .modifier(active: Wording(lift: 8, shown: false), identity: Wording(lift: 0, shown: true))
            .animation(.easeOut(duration: 0.5).delay(0.6)),
        removal: .opacity.animation(.easeIn(duration: 0.2))
    )
    /// and then the line from them, which draws itself (`DrawnArrow`) and only fades when it goes
    private static let drawn = AnyTransition.asymmetric(insertion: .identity, removal: .opacity.animation(.easeIn(duration: 0.2)))

    /// The tick, once the heading it stands in for has gone; how it forms is its own (`DoneTick`)
    private static let ticked = AnyTransition.asymmetric(
        insertion: .identity,
        removal: .modifier(active: Wording(lift: -10, shown: false), identity: Wording(lift: 0, shown: true))
            .animation(.easeIn(duration: 0.3))
    )

    /// A widget arriving on the phone once it's there, and going as the next frame's comes
    private static let widget = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.94).combined(with: .opacity).animation(.spring(response: 0.6, dampingFraction: 0.84).delay(0.35)),
        removal: .opacity.animation(.easeIn(duration: 0.25))
    )

    private struct Wording: ViewModifier {
        let lift: CGFloat
        let shown: Bool

        func body(content: Content) -> some View {
            content
                .opacity(shown ? 1 : 0)
                .blur(radius: shown ? 0 : 6)
                .offset(y: lift)
        }
    }

    var body: some View {
        // Laid out on the frame's 390, centred on the screen; its 44 of status bar is the device's own
        let screen = UIScreen.main.bounds.width
        let side = (screen - 390) / 2
        // Only this of `compare` is read here; where the line stands is `CompareLayer`'s
        let simplified = stage == .simple && compare.simplified
        return ZStack(alignment: .topLeading) {
            Group {
                if stage == .welcome {
                    // 1267:15779: 19 in from the frame's edge. The frame's two cards and the 17 between them come to
                    // 389, more than the 352 there is, so all four are drawn smaller by that much and stay put.
                    VStack(alignment: .leading, spacing: 17 * Self.cardScale) {
                        ForEach(Self.rows, id: \.self) { row in
                            HStack(alignment: .top, spacing: 17 * Self.cardScale) {
                                ForEach(Array(row.enumerated()), id: \.offset) { _, card in
                                    self.card(card)
                                }
                            }
                        }
                    }
                    .frame(width: 352, height: 401 * Self.cardScale, alignment: .topLeading)
                    .at(side + 19, 295 - 44 + top)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)).animation(.easeIn(duration: 0.3)))
                }

                if stage == .research, !Self.gathers {
                    // Under "Analysis backed by research", for now: a book on the page, its pages turning, and no
                    // phone
                    TurningBook()
                        .at(side, 268 - 44 + top)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.94).combined(with: .opacity).animation(Self.move.delay(0.25)),
                            removal: .scale(scale: 0.94).combined(with: .opacity).animation(.easeIn(duration: 0.3))
                        ))
                }

                if stage == .simplest {
                    // 1341:2551: the phone with what she has noticed told on it one at a time, 327 across, up out
                    // of the foot of the screen, which cuts it off
                    noticing
                        .frame(height: max(0, UIScreen.main.bounds.height - (Self.phoneTop - 44 + top)), alignment: .top)
                        .clipped()
                        .at(side + 31.5, Self.phoneTop - 44 + top)
                        .transition(.asymmetric(
                            insertion: .offset(y: 160).combined(with: .opacity).animation(Self.move.delay(0.2)),
                            removal: .offset(y: 220).combined(with: .opacity).animation(.easeIn(duration: 0.35))
                        ))
                }

                if stage == .research, Self.gathers {
                    // 1267:12885: up out of the foot of the screen, which cuts it off
                    phone
                        .frame(height: max(0, UIScreen.main.bounds.height - (Self.phoneTop - 44 + top)), alignment: .top)
                        .clipped()
                        .at(side + 27, Self.phoneTop - 44 + top)
                        .transition(.asymmetric(
                            insertion: .offset(y: 160).combined(with: .opacity).animation(Self.move.delay(0.2)),
                            removal: .offset(y: 220).combined(with: .opacity).animation(.easeIn(duration: 0.35))
                        ))
                }

                if stage == .meet {
                    if !met {
                        // 1341:2567: what there is to ask about, going away, until she comes in over it
                        WorldBefore(gone: worldGone)
                            .at(side, top - 44)
                            .transition(.identity)
                    }
                    meeting(side: side)
                        .transition(.asymmetric(
                            insertion: .identity,
                            removal: .scale(scale: 0.9).combined(with: .opacity).animation(.easeIn(duration: 0.3))
                        ))
                }

                if (stage == .meet && met) || (stage >= .access && stage < .connect && stage != .usage) {
                    // 1249:6253: the advisor's phone, which moves down the page as it goes, and leaves by its foot.
                    // Under her when she's met, and with its keyboard up, there's none of the phone to see: only
                    // its pill, and then its keyboard, on the page and at the page's size (1362:5896, 1362:6270: the
                    // pill 354.113 across for the phone's 272), the pill where those frames have it. Then it's the
                    // phone, back at its size and in its place.
                    let zoom = lone ? Self.loneZoom : 1
                    let pill = CGPoint(x: 18.943, y: stage == .meet ? 714 : 463)
                    let phone = CGPoint(x: side + 27, y: stage.deviceTop - 44 + top)
                    device
                        .scaleEffect(zoom, anchor: .topLeading)
                        .offset(x: lone ? side + pill.x - 32 * zoom - phone.x : 0,
                                y: lone ? pill.y - (15 + (stage == .meet ? 568 : 337)) * zoom - 44 + top - phone.y : 0)
                        .at(phone.x, phone.y)
                        .transition(.asymmetric(
                            insertion: .offset(y: 260).combined(with: .opacity).animation(Self.move.delay(0.15)),
                            removal: .offset(y: 320).combined(with: .opacity).animation(.easeIn(duration: 0.35))
                        ))
                }

                if stage == .connect {
                    connecting(side: side)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.94).combined(with: .opacity).animation(Self.move.delay(0.3)),
                            removal: .opacity.animation(.easeIn(duration: 0.3))
                        ))
                }

                if stage >= .access, stage < .simple {
                    // 1251:6329: the page's own colour over the phone's head, thinning out to nothing at its foot
                    LinearGradient(
                        stops: [.init(color: Color(hex: 0xF3F4F2), location: 0), .init(color: Color(hex: 0xF3F4F2), location: 0.70786),
                                .init(color: Color(hex: 0xF3F4F2).opacity(0), location: 1)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(width: screen, height: stage.veil - 44 + top)
                    // (lifted while there's none of the phone to see)
                    .opacity(stage == .typing ? 0 : 1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    // there before the phone has come up under it; and it lifts as the phone rises clear of it
                    .transition(.asymmetric(insertion: .opacity.animation(.easeOut(duration: 0.15)),
                                            removal: .opacity.animation(.easeInOut(duration: 0.5))))
                }

                if stage == .topics {
                    // 1267:13004 and 1267:13005: said over the phone, and the line from it round and down to the prompts
                    GapText("Select any topic", family: .walsheim, medium: true, size: 17, lineHeight: 23, color: Color.black.opacity(0.67))
                        .fixedSize()
                        .at(side + 133, 203 - 44 + top)
                        .transition(Self.pointer)
                    DrawnArrow.topic
                        .at(side + 193, 232 - 44 + top)
                        .transition(Self.drawn)
                }

                // 1267:15956
                Color.black.opacity(0.57)
                    .frame(width: 372, height: 1)
                    .at(side + 9, 48 - 44 + top)
                    .accessibilityHidden(true)

                if stage == .welcome {
                    // 1267:15960: the wave and "Hello Arindam", centred
                    HStack(spacing: 9.5) {
                        Image("OnboardingWave")
                            .frame(width: 25.261, height: 25.577)
                            .accessibilityHidden(true)
                        DsText("Hello \(AppUser.name)", variant: .h3)
                            .fixedSize()
                    }
                    .frame(width: 390, height: 39)
                    .at(side, 70 - 44 + top)
                    .transition(Self.words)
                }

                if stage == .typing || stage == .chat || ((stage == .hold || stage == .swipe) && gestureDone) {
                    // 1251:6831: the hold's been done, or the swipe, or a topic's been picked, and the tick stands
                    // where the heading was. So it does once her pill's been tried (1362:6363, a little lower)
                    DoneTick()
                        .at(side + 159, (stage == .typing ? 113 : 95) - 44 + top)
                        .transition(Self.ticked)
                } else if stage != .meet || met,
                          let heading = simplified ? Self.simplifiedHeading : stage.heading,
                          let lines = simplified ? "Decades of research,\nsimplified for you" : stage.headingLines {
                    Group {
                        if stage <= .meet || stage == .connect {
                            // Gap: Reckless Medium 45/51 (45/43 over the portrait) in #33302D has no text style or content token
                            GapText(lines, family: .reckless, medium: true, size: 45, lineHeight: stage == .meet ? 43 : 51, color: Color(hex: 0x33302D))
                                .multilineTextAlignment(.center)
                                .frame(width: 352)
                                .at(side + 19, stage.headingTop - 44 + top)
                        } else {
                            // Gap: GT Walsheim Medium 35/39 has no text style; the colour is content/primary
                            GapText(lines, family: .walsheim, medium: true, size: 35, lineHeight: 39, color: ColorScale.contentPrimary)
                                .multilineTextAlignment(.center)
                                .frame(width: 335)
                                .at(side + 28, stage.headingTop - 44 + top)
                        }
                    }
                    .accessibilityLabel(heading)
                    .id(simplified ? -1 : stage.rawValue)
                    .transition(Self.words)
                }
            }
            .scaleEffect(shown ? 1 : 1.1)
            .opacity(shown ? 1 : 0)

            if stage <= .research {
                // 1267:12998
                OnboardingConfirmButton(action: next)
                    .scaleEffect(buttonShown ? 1 : 0.96)
                    .opacity(buttonShown ? 1 : 0)
                    .allowsHitTesting(buttonShown)
                    .accessibilityHidden(!buttonShown)
                    .at(side + 23, 738 - 44 + top)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)).animation(.easeIn(duration: 0.25)))
            }

            if stage == .simple, controlsShown {
                // 1251:7090
                OnboardingConfirmButton(action: next)
                    .at(side + 23, 738 - 44 + top)
                    .transition(.offset(y: 30).combined(with: .opacity))
            }

            // The widget on the phone (1251:6862, 1251:7050), 10 in from its screen's edge and 188 down it; what lifts
            // out of it, or rises over the page for it, has the whole screen
            if stage == .hold {
                // Continue puts it back in its place if it's lifted out, and only then goes on
                OnboardingV2HoldWidget(origin: CGPoint(x: side + 49, y: 217 + 12 + 188 - 44 + top), leaving: holdLeaving, onSettled: advance) {
                    withAnimation(Self.move) { gestureDone = true }
                    // Its questions are out by now. A moment to see them, and it goes on by itself: no Continue here
                    DispatchQueue.main.asyncAfter(deadline: .now() + Self.gestureRest) {
                        if stage == .hold { holdLeaving = true }
                    }
                }
                // Back in its place, it's gone at once: the same card on the phone (`shelf`) is there under it, and
                // is the one that moves up
                .transition(.asymmetric(insertion: Self.widget, removal: .identity))
                // (given its place over the page, which what's leaving a stack otherwise loses, and goes behind it)
                .zIndex(1)
            }
            if stage == .swipe {
                // It comes up the phone from the place below, as the hold's widget goes up to the one above; the
                // phone's foot cuts it off on the way
                OnboardingV2SwipeWidget(origin: CGPoint(x: side + 49, y: 217 + 12 + 188.812 - 44 + top),
                                        screen: CGRect(x: side + 27 + 12, y: 217 + 12 - 44 + top, width: 312, height: 577),
                                        rise: Self.shelfPitch, cutBelow: 217 + 589 - 44 + top) {
                    withAnimation(Self.move) { gestureDone = true }
                    // The composer takes half a second to open from here; the same moment once it has, and on
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Self.gestureRest) {
                        if stage == .swipe { advance() }
                    }
                }
                .transition(.asymmetric(insertion: .identity, removal: .opacity.animation(.easeIn(duration: 0.25))))
                .zIndex(1)
            }
            if stage == .levels {
                // After the swipe, the reading-level card and its slider, as the first onboarding has them
                // (792:13117): it comes up the phone as the swipe's widget did, the chart going up to the place above
                OnboardingV2LevelsWidget(origin: CGPoint(x: side + 49, y: 217 + 12 + Self.levelsTop - 44 + top),
                                         rise: Self.levelsPitch, cutBelow: 217 + 589 - 44 + top)
                    .transition(.asymmetric(insertion: .identity, removal: .opacity.animation(.easeIn(duration: 0.25))))
                    .zIndex(1)
                // and this one is gone on from with Continue
                OnboardingConfirmButton(action: next)
                    .at(side + 23, 738 - 44 + top)
                    .transition(.asymmetric(insertion: .offset(y: 30).combined(with: .opacity).animation(Self.move.delay(0.5)),
                                            removal: .opacity.animation(.easeIn(duration: 0.2))))
                    .zIndex(2)
            }
            if stage == .connect {
                // 1277:19189
                OnboardingConfirmButton(title: "Connect mutual funds") {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { mfCentralUp = true }
                }
                .at(side + 23, 738 - 44 + top)
                .transition(.offset(y: 30).combined(with: .opacity).animation(Self.move.delay(0.6)))

                if mfCentralUp {
                    // Behind it, a tap puts it away
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { closeMFCentral() }
                        .accessibilityHidden(true)
                    // 952:13599, the first onboarding's: 13 under the status bar, up from the foot of the page
                    MFCentralImportSheet(onContinue: onContinue, onUpload: {}, onClose: closeMFCentral)
                        .frame(maxWidth: .infinity)
                        .padding(.top, top + 13)
                        .transition(.move(edge: .bottom).combined(with: .opacity.animation(.easeOut(duration: 0.2))))
                }
            }

            if stage == .meet, met {
                // 1362:5961 and 1362:5962: said over her pill at the foot of the page, and the line down to it
                GapText("Tap to try!", family: .walsheim, medium: true, size: 17, lineHeight: 23, color: Color.black.opacity(0.67))
                    .fixedSize()
                    .at(side + 131, 570 - 44 + top)
                    .transition(Self.pointer)
                DrawnArrow.tryIt
                    .at(side + 76.954, 603 - 44 + top)
                    .transition(Self.drawn)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AdvisorDawnBackground().mask(flowMask).ignoresSafeArea())
        .ignoresSafeArea()
        .preferredColorScheme(.light)
        .task { await play() }
        .task(id: stage) {
            switch stage {
            case .usage:
                // 1362:7957: said on a page of its own, between what the advisor does and how the app is used: it
                // comes, is read, and goes
                try? await Task.sleep(for: .seconds(1.9))
                guard !Task.isCancelled else { return }
                advance()
            case .typing:
                // The keyboard frame is only passed through: long enough for the line to close round the pill and
                // be seen there, and on to the prompts
                try? await Task.sleep(for: .seconds(1.9))
                guard !Task.isCancelled else { return }
                next()
            case .simple where !Self.compares:
                // The simple report is all there is on the phone: once it's there and the phone has risen, Continue
                try? await Task.sleep(for: .seconds(1.3))
                guard !Task.isCancelled else { return }
                withAnimation(Self.move) { controlsShown = true }
            case .chat where !Self.compares:
                // The documents gather on the phone (`SimpleMaking`) for as long as they did when this was done for
                // the research; as they draw together the phone comes up for the next frame, and the simple report
                // grows out of where they met
                guard !reduceMotion else {
                    reportShown = true
                    try? await Task.sleep(for: .seconds(1.2))
                    guard !Task.isCancelled, stage == .chat else { return }
                    return next()
                }
                try? await Task.sleep(for: .seconds(SimpleMaking.leadIn + SimpleMaking.gathering + 0.2))
                guard !Task.isCancelled, stage == .chat else { return }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) { reportShown = true }
                next()
            case .simple:
                // Once the phone has risen, the line comes in from the right, the simple version following it in. It
                // goes across and back twice, to show that it moves, and comes to rest with three quarters of the
                // screen simple; a finger on it at any point and it's the finger's. Then Continue
                try? await Task.sleep(for: .seconds(0.9))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.2)) { compare.shown = true }
                try? await Task.sleep(for: .seconds(0.15))
                Haptics.settle()
                if !reduceMotion {
                    for sway in Self.splitSway {
                        guard !Task.isCancelled, !compare.touched else { break }
                        withAnimation(.easeInOut(duration: sway.time)) { compare.split = sway.to }
                        try? await Task.sleep(for: .seconds(sway.time))
                    }
                }
                guard !Task.isCancelled else { return }
                if !compare.touched {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { compare.split = Self.splitRest }
                    try? await Task.sleep(for: .seconds(0.5))
                    guard !Task.isCancelled else { return }
                }
                // at rest: the side with less of the screen goes out of focus
                compare.focusing = true
                withAnimation(Self.move) { controlsShown = true }
            case .chat:
                // What she goes through is shown, going up the phone a part at a time; then the
                // report, which the chat under it has had up for a while by then (it's waited for if not), shown
                // as the phone comes up for its simple version
                try? await Task.sleep(for: .seconds(ResearchRun.duration))
                while !chatReported, !Task.isCancelled { try? await Task.sleep(for: .seconds(0.05)) }
                guard !Task.isCancelled else { return }
                if reduceMotion {
                    reportCleared = true
                    withAnimation(.easeInOut(duration: 0.45)) { reportShown = true }
                } else {
                    // It's there out of focus as she gives way to it, and comes clear from the top down, fast: as
                    // the phone comes up with it for the next frame, not before. (On its own, since going on to
                    // that frame ends this.)
                    withAnimation(.easeInOut(duration: 0.22)) { reportShown = true }
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(0.14))
                        withAnimation(.easeIn(duration: 0.5)) { reportFront = 760 }
                        try? await Task.sleep(for: .seconds(0.56))
                        reportCleared = true
                    }
                }
                guard stage == .chat else { return }
                next()
            case .meet:
                // Before she's met, what there is to ask about comes at the screen and goes away into it, one thing
                // after another; she comes in over all of it, larger than the screen, and down to her size with it
                // under her. Then she's met.
                guard !reduceMotion else {
                    advisorIn = true
                    met = true
                    return
                }
                let clock = ContinuousClock()
                let began = clock.now
                Haptics.prepare()
                // a light tick as each comes onto the screen, the frame's seven a little firmer than the many
                for appearance in WorldBefore.appearances {
                    try? await clock.sleep(until: began.advanced(by: .seconds(appearance.at)))
                    guard !Task.isCancelled else { return }
                    Haptics.beat(strength: appearance.small ? 0.15 : 0.7)
                }
                try? await clock.sleep(until: began.advanced(by: .seconds(WorldBefore.leadIn + WorldBefore.covered)))
                guard !Task.isCancelled else { return }
                // and two strong knocks as she does
                Haptics.landed()
                advisorIn = true
                withAnimation(.easeIn(duration: 0.4)) { worldGone = true }
                try? await Task.sleep(for: .seconds(WorldBefore.advisorSettles))
                guard !Task.isCancelled else { return }
                withAnimation(Self.move) { met = true }
            default:
                break
            }
        }
    }

    private func closeMFCentral() {
        Haptics.tap()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) { mfCentralUp = false }
    }

    /// The chat's report is up on the phone, under what she's shown going through: once it has settled there
    private func reportUp() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { chatReported = true }
    }

    /// Continue, "Say Hi", the pill, or a prompt: on to the next frame, and after the last, on with the onboarding
    /// Continue's been tapped
    private func next() {
        Haptics.tap()
        advance()
    }

    /// On to the next frame, tapped for or not
    private func advance() {
        // (from meeting her it's straight to her pill tried: the frame between, with the pill on a phone, is no
        // longer part of it)
        guard let following = Stage(rawValue: stage.rawValue + (stage == .meet ? 2 : 1)) else { return onContinue() }
        withAnimation(Self.move) {
            stage = following
            gestureDone = false
            holdLeaving = false
        }
    }

    // MARK: - Welcome

    /// The phone as it was under the research heading (1277:19454), 336 × 668: a pale outline of one, and on it the
    /// documents gathered into the report. Kept for `-researchGather`.
    private var phone: some View {
        ZStack(alignment: .topLeading) {
            OpenFrame(radius: 59, line: 0).fill(Color.white.opacity(0.5))
            OpenFrame(radius: 59, line: 2).fill(Self.outline, style: FillStyle(eoFill: true))
            // What the report's made from is gathered on the card, and comes together as one of the reports itself,
            // reading itself out; a finger holds it
            ReportAssembly()
                // 0 1.457 41.525 +3.643 at 7%; SwiftUI can't draw the spread
                .shadow(color: Color.black.opacity(0.07), radius: 20.8, x: 0, y: 1.457)
                .at(4.5, 4)
        }
        .frame(width: 336, height: 668, alignment: .topLeading)
        // What's on it is a picture of the app
        .accessibilityHidden(true)
    }

    /// 1341:2551, 327 × 573.223: the phone under "Proactive, so you don’t miss". Its outline, its screen 11.679 in
    /// on surface/base with a sunken card low down on it, and what she has noticed, told one at a time
    /// (`FindingsTurn`)
    private var noticing: some View {
        ZStack(alignment: .topLeading) {
            OpenFrame(radius: 57.42, line: 1.946).fill(Self.outline, style: FillStyle(eoFill: true))
            ZStack {
                OpenFrame(radius: 47.688, line: 0).fill(Color.white)
                OpenFrame(radius: 47.688, line: 2.92).fill(Self.outline, style: FillStyle(eoFill: true))
            }
            .frame(width: 303.643, height: 561.545)
            .at(11.679, 11.678)
            // 1341:2555 and the sunken card on it (1341:2556)
            ZStack(alignment: .topLeading) {
                ColorScale.surfaceBase
                RoundedRectangle(cornerRadius: 22.384, style: .continuous)
                    .fill(ColorScale.surfaceSunken1)
                    // Gap: black at 5%, 0.973 across, unbound
                    .overlay(RoundedRectangle(cornerRadius: 22.384, style: .continuous).strokeBorder(Color.black.opacity(0.05), lineWidth: 0.973))
                    .frame(width: 284.179, height: 261.795)
                    .at(6.813, 454.492)
                FindingsTurn()
            }
            .frame(width: 297.804, height: 555.705, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 44.768, style: .continuous))
            .at(14.598, 14.598)
        }
        .frame(width: 327, height: 573.223, alignment: .topLeading)
        // What's on it is a picture of the app
        .accessibilityHidden(true)
    }

    /// What the advisor notices by itself, told one at a time between two handles on the phone's screen
    /// (1341:2557, 1362:8363, 1362:8364; laid out on the screen's 297.804). One comes down out of the upper handle
    /// and opens into its card, 269 × 119; it's left there to be read; then it closes down into the lower handle
    /// as the next comes out of the upper one, the two at once. The cards take the prompts' washes in turn: the
    /// yellow to peach (1341:2557), the mauve to lavender (1277:19369), and the pale green (1277:19375), on which
    /// the words are black. They're the ones the frames had going up the phone before, the first two the frames'
    /// own, and they come round again after the last. With Reduce Motion the first is simply there.
    private struct FindingsTurn: View {
        /// The one being told; the one before it is closing, or closed, in the lower handle
        @State private var index = 0
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        /// The first two are the frames' (1277:19458, 1277:19464); the rest are stand-ins in the same vein
        static let findings = [
            "We found a regular fund in your portfolio",
            "Your FD is matured, we suggest re-investing",
            "Two of your funds hold the same stocks",
            "Your SIP is due tomorrow, balance is low",
            "A fund you hold has a new manager",
            "Small caps are now 40% of your money",
            "You can still save tax this year",
            "Your emergency fund covers only 2 months",
        ]

        /// On the screen: the upper handle, the card, and the lower handle
        fileprivate static let upper = CGRect(x: 123.902, y: 16.402, width: 51, height: 9)
        fileprivate static let card = CGRect(x: 14.902, y: 38.402, width: 269, height: 119)
        fileprivate static let lower = CGRect(x: 123.902, y: 170.402, width: 51, height: 9)
        // Gap: #C1C1C1, unbound
        fileprivate static let handle = Color(hex: 0xC1C1C1)
        /// The one going and the one coming, together and unhurried
        fileprivate static let turning = Animation.spring(response: 0.75, dampingFraction: 0.88)
        /// Seconds from one coming to the next
        private static let every: Double = 3.1
        /// Which of the prompts' washes each takes in turn, and whether its words are black on it
        fileprivate static let looks: [(wash: Int, dark: Bool)] = [(0, false), (1, false), (3, true)]

        var body: some View {
            ZStack(alignment: .topLeading) {
                Capsule().fill(Self.handle)
                    .frame(width: Self.upper.width, height: Self.upper.height)
                    .at(Self.upper.minX, Self.upper.minY)
                Capsule().fill(Self.handle)
                    .frame(width: Self.lower.width, height: Self.lower.height)
                    .at(Self.lower.minX, Self.lower.minY)

                // The one before, going into the lower handle, under the one coming out of the upper
                ForEach([index - 1, index], id: \.self) { each in
                    if each >= 0 {
                        Told(index: each, closing: each < index, still: reduceMotion)
                    }
                }
            }
            .frame(width: 297.804, height: 555.705, alignment: .topLeading)
            .task {
                guard !reduceMotion else { return }
                do {
                    while true {
                        try await Task.sleep(for: .seconds(Self.every))
                        index += 1
                    }
                } catch {}
            }
        }

        /// One of them: in the upper handle, a handle's size and grey, until it's on the screen; then its card;
        /// then, `closing`, the same in the lower handle
        private struct Told: View {
            let index: Int
            let closing: Bool
            let still: Bool

            @State private var out = false

            var body: some View {
                let open = out && !closing
                let rect = closing ? FindingsTurn.lower : out ? FindingsTurn.card : FindingsTurn.upper
                let look = FindingsTurn.looks[index % FindingsTurn.looks.count]
                return ZStack(alignment: .topLeading) {
                    LinearGradient(colors: OnboardingWelcomeV2View.washes[look.wash].map { Color(hex: $0) }, startPoint: .leading, endPoint: .trailing)
                    FindingsTurn.handle.opacity(open ? 0 : 1)
                    // Gap: GT Walsheim Medium 26.25/28.06 has no text style; content/on-color, or black on the pale wash
                    GapText(FindingsTurn.findings[index % FindingsTurn.findings.count], family: .walsheim, medium: true, size: 26.25, lineHeight: 28.06,
                            color: look.dark ? Color.black : Color.white)
                        .frame(width: 241.297, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 0, height: 0, alignment: .topLeading)
                        .offset(x: 14.173, y: 17)
                        .opacity(open ? 1 : 0)
                        .animation(open ? .easeOut(duration: 0.4).delay(0.22) : .easeIn(duration: 0.22), value: open)
                }
                .frame(width: rect.width, height: rect.height, alignment: .topLeading)
                .clipShape(RoundedRectangle(cornerRadius: open ? 13.673 : 4.5, style: .continuous))
                // Shadow/2 (0 4 97 +7 at 7%), only while it's a card; SwiftUI can't draw the spread
                .shadow(color: Color.black.opacity(open ? 0.07 : 0), radius: 48.5, x: 0, y: 4)
                .offset(x: rect.minX, y: rect.minY)
                .animation(FindingsTurn.turning, value: closing)
                .onAppear {
                    guard !still else { return out = true }
                    // (the very first after a moment, once the phone is up)
                    withAnimation(FindingsTurn.turning.delay(index == 0 ? 0.6 : 0)) { out = true }
                }
            }
        }
    }

    /// Once a topic's picked the report is made and put beside its simple version: what the advisor goes through
    /// (`ResearchRun`), her report, and the line dragged between that and the simple one (`CompareLayer`). That is
    /// what runs. `-reportSimple` runs the other version instead, in which the documents stream in and the simple
    /// report is all that's shown (`SimpleMaking`).
    private static let compares = !ProcessInfo.processInfo.arguments.contains("-reportSimple")

    /// `-researchGather`: under "Analysis backed by research" the documents are gathered into the report, as they
    /// were before the book
    private static let gathers = ProcessInfo.processInfo.arguments.contains("-researchGather")

    /// A book on the page, 390 × 440, its pages turning: drawn as the cube at the top of the report is
    /// (`TurningCube`, 1182:17994), in black line from the same side and above, with no colour (its pages are the
    /// report's paper) and nothing on any page. It lies open towards us, each side bowed up from the spine, with a couple of
    /// pages more showing under each and the boards under those. A rest, and the page on the right comes over to
    /// the left, bending as it goes. With Reduce Motion it lies still.
    private struct TurningBook: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var began = Date()

        private static let size = CGSize(width: 390, height: 440)
        /// Where the middle of its spine is: a little right of the middle, as the spine is the furthest of it away
        private static let middle = CGPoint(x: 206, y: 224)
        /// Points to one of its own measures: the boards come to within a few points of the frame's margins
        private static let half: CGFloat = 132
        /// How far a point moves across and up for each measure it is further away: the cube's
        private static let lean = CGSize(width: 37.0 / 128, height: 32.0 / 128)
        /// A page: across from the spine, and up or down from its middle
        private static let wide = 1.2, tall = 0.84
        /// How far the spine is behind the pages' outer edges, and how far the pages lie open towards us (radians)
        private static let set = 0.36, open = 0.24
        /// How much a page at rest bows, from steeper at the spine to flatter at its edge
        private static let bow = 0.5
        /// A rest, then a page turned
        private static let resting = 0.8, turning = 1.3
        // Gap: the report's paper, #FCFCFA
        private static let paper = Color(hex: 0xFCFCFA)
        /// A page as it lies, seen from above: points from the spine out to its edge, across and away
        private struct Sheet {
            var points: [(x: Double, z: Double)] = []

            /// From the spine at `angle` round from lying flat to the right (a quarter turn is straight at us),
            /// `bend` steeper than that at the spine and as much flatter at its edge, `wide` long
            init(angle: Double, bend: Double, wide: Double, from spine: Double) {
                let steps = 12
                var x = 0.0, z = spine
                points.append((x, z))
                for i in 0..<steps {
                    let turned = angle + bend * (0.5 - (Double(i) + 0.5) / Double(steps))
                    x += wide / Double(steps) * cos(turned)
                    z -= wide / Double(steps) * sin(turned)
                    points.append((x, z))
                }
            }

            /// Where it is `u` of the way out from the spine (0 to 1)
            func at(_ u: Double) -> (x: Double, z: Double) {
                let place = min(max(u, 0), 1) * Double(points.count - 1)
                let i = min(Int(place), points.count - 2)
                let f = place - Double(i)
                return (points[i].x + (points[i + 1].x - points[i].x) * f, points[i].z + (points[i + 1].z - points[i].z) * f)
            }
        }

        var body: some View {
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                Canvas { context, _ in
                    draw(&context, at: reduceMotion ? nil : timeline.date.timeIntervalSince(began))
                }
            }
            .frame(width: Self.size.width, height: Self.size.height)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { began = Date() }
        }

        /// `time` is nil when it shouldn't move: lying open
        private func draw(_ context: inout GraphicsContext, at time: TimeInterval?) {
            let cycle = Self.resting + Self.turning
            let local = (time ?? 0).truncatingRemainder(dividingBy: cycle)
            let progress = min(max((local - Self.resting) / Self.turning, 0), 1)
            // eased in and out, so the page sets off and lands gently
            let eased = progress * progress * progress * (progress * (progress * 6 - 15) + 10)
            let line = StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)

            func placed(_ x: Double, _ y: Double, _ z: Double) -> CGPoint {
                CGPoint(x: Self.middle.x + (x - z * Self.lean.width) * Self.half,
                        y: Self.middle.y + (y - z * Self.lean.height) * Self.half)
            }
            /// A page's outline: along its head, down its edge, back along its foot
            func outline(_ sheet: Sheet, tall: Double = Self.tall) -> Path {
                var path = Path()
                path.addLines(sheet.points.map { placed($0.x, -tall, $0.z) } + sheet.points.reversed().map { placed($0.x, tall, $0.z) })
                path.closeSubpath()
                return path
            }
            let right = Sheet(angle: Self.open, bend: Self.bow, wide: Self.wide, from: Self.set)
            let left = Sheet(angle: .pi - Self.open, bend: -Self.bow, wide: Self.wide, from: Self.set)

            // The boards, a little larger than the pages and flatter, in line only; and the spine between them
            for side in [0.0, 1.0] {
                let board = Sheet(angle: side == 0 ? Self.open - 0.13 : .pi - Self.open + 0.13, bend: side == 0 ? 0.12 : -0.12,
                                  wide: Self.wide + 0.09, from: Self.set + 0.07)
                context.stroke(outline(board, tall: Self.tall + 0.07), with: .color(.black), style: line)
            }
            // The pages under the ones on top, their edges showing
            for under in [2.0, 1.0] {
                for side in [0.0, 1.0] {
                    let lower = Sheet(angle: side == 0 ? Self.open - 0.045 * under : .pi - Self.open + 0.045 * under,
                                      bend: side == 0 ? Self.bow * 0.8 : -Self.bow * 0.8, wide: Self.wide, from: Self.set + 0.02 * under)
                    let path = outline(lower)
                    context.fill(path, with: .color(Self.paper))
                    context.stroke(path, with: .color(.black), style: line)
                }
            }

            // On the left, what has been turned: paper
            let read = outline(left)
            context.fill(read, with: .color(Self.paper))
            context.stroke(read, with: .color(.black), style: line)

            // On the right, the page towards us. While a page is turning it's the next one, uncovered
            let facing = outline(right)
            context.fill(facing, with: .color(Self.paper))
            context.stroke(facing, with: .color(.black), style: line)
            guard time != nil, progress > 0 else { return }

            // The page turning: over from the right to the left, its edge behind its spine as it goes
            let angle = Self.open + (.pi - 2 * Self.open) * eased
            let turned = Sheet(angle: angle, bend: Self.bow * (1 - 2 * eased) + 0.95 * sin(.pi * eased), wide: Self.wide, from: Self.set)
            let path = outline(turned)
            context.fill(path, with: .color(Self.paper))
            context.stroke(path, with: .color(.black), style: line)
        }
    }

    /// The simple report being made, on the phone's screen (312 × 641) once a topic's picked: on the report's
    /// own yellow-to-peach wash, the documents drawn in line keep coming, each large at first and going away into the screen, smaller and
    /// smaller, in no order (`DocStream`), then draw together to the middle of what shows of the screen;
    /// `formed`, the simple report (`SimpleReport`) grows out of where they met, out of a blur. With Reduce
    /// Motion the report is simply there.
    private struct SimpleMaking: View {
        /// The report is to be shown: the documents have drawn together
        let formed: Bool

        /// When the documents began to come in
        @State private var began: Date?
        /// The documents are done with, and out of the way
        @State private var cleared = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        /// Seconds before the first document, while the prompts go from the phone; and of gathering before they
        /// draw together
        static let leadIn: Double = 0.45
        static let gathering: Double = 3.3
        /// The middle of what shows of the screen, above the foot of the device
        private static let middle = CGPoint(x: 156, y: 282)

        var body: some View {
            let shape = UnevenRoundedRectangle(topLeadingRadius: 49, topTrailingRadius: 49, style: .continuous)
            return ZStack(alignment: .topLeading) {
                LinearGradient(colors: OnboardingWelcomeV2View.washes[0].map { Color(hex: $0) }, startPoint: .leading, endPoint: .trailing)

                if let began, !cleared {
                    DocStream(began: began, drawnAt: Self.gathering, middle: Self.middle)
                        .frame(width: 312, height: 641)
                }

                SimpleReport(height: 641)
                    .scaleEffect(formed ? 1 : 0.16, anchor: UnitPoint(x: 0.5, y: Self.middle.y / 641))
                    .blur(radius: formed ? 0 : 14)
                    .opacity(formed ? 1 : 0)
                    .allowsHitTesting(formed)
                    .accessibilityHidden(!formed)
            }
            .frame(width: 312, height: 641, alignment: .topLeading)
            .clipShape(shape)
            .task {
                guard !reduceMotion else { return cleared = true }
                do {
                    try await Task.sleep(for: .seconds(Self.leadIn))
                    began = Date()
                } catch {}
            }
            .onChange(of: formed) { _, formed in
                guard formed else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { cleared = true }
            }
        }
    }

    /// Documents coming at the screen without end, drawn afresh each frame from the time since they `began`: one
    /// every tenth of a second or so, each from its own place, in no order. Each is large when it comes, the lines
    /// on it being drawn, and goes away into the screen, smaller all the time, towards a point part of the way
    /// from its own place to the `middle`, until it's too small to see. So there are always some large and near
    /// and many small and far. `drawnAt` seconds in, no more come and those there all go to the `middle`.
    private struct DocStream: View {
        let began: Date
        let drawnAt: Double
        let middle: CGPoint

        private struct Coming {
            /// Where it is when it's a document's own size
            let place: CGPoint
            let kind: Int
            let tint: Int
        }

        /// Seconds from one coming to the next, and that each is on its way
        private static let every: Double = 0.1
        private static let lasting: Double = 2.7
        /// How many times its own size it comes in at, and how fast it shrinks (the size it has left, each second, as a power of e)
        private static let near: Double = 3.8
        private static let going: Double = 1.2
        /// How far from the middle, of its own distance, the point each goes away to is
        private static let apart: CGFloat = 0.4
        /// Where each of them is to be, and what's on it, shuffled once and kept; they come round again
        private static let comings: [Coming] = {
            var seed: UInt64 = 0xD1B54A32D192ED03
            func random() -> CGFloat {
                seed ^= seed << 13
                seed ^= seed >> 7
                seed ^= seed << 17
                return CGFloat(seed % 10_000) / 10_000
            }
            return (0..<64).map { i in
                // across the screen and down what shows of it, no two in a row in the same part of it
                let column = CGFloat((i * 3) % 5), row = CGFloat((i * 5 + i / 5) % 6)
                return Coming(place: CGPoint(x: 28 + (column + random()) * 51, y: 60 + (row + random()) * 80),
                              kind: Int(random() * CGFloat(DocSheet.kinds)) % DocSheet.kinds,
                              tint: Int(random() * CGFloat(DocSheet.tints.count)) % DocSheet.tints.count)
            }
        }()

        var body: some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince(began)
                Canvas { context, _ in
                    draw(in: &context, at: t)
                }
            }
            .allowsHitTesting(false)
        }

        private func draw(in context: inout GraphicsContext, at t: Double) {
            // the ones still on their way, the furthest gone first, so the near ones are over them
            let last = Int(min(t, drawnAt - 0.25) / Self.every)
            let first = max(0, Int((t - Self.lasting) / Self.every) + 1)
            guard last >= first else { return }
            let drawn = min(1, max(0, (t - drawnAt) / 0.4))
            let meeting = drawn * drawn
            for index in first...last {
                let coming = Self.comings[index % Self.comings.count]
                let age = t - Double(index) * Self.every
                guard age >= 0 else { continue }
                var scale = CGFloat(Self.near * exp(-Self.going * age))
                var opacity = min(1, age / 0.22) * Double(min(1, max(0, (scale - 0.13) / 0.22)))
                let towards = CGPoint(x: middle.x + (coming.place.x - middle.x) * Self.apart,
                                      y: middle.y + (coming.place.y - middle.y) * Self.apart)
                var centre = CGPoint(x: towards.x + (coming.place.x - towards.x) * scale,
                                     y: towards.y + (coming.place.y - towards.y) * scale)
                // and at the end, to the middle with the rest
                centre.x += (middle.x - centre.x) * 0.94 * meeting
                centre.y += (middle.y - centre.y) * 0.94 * meeting
                scale *= 1 - 0.7 * meeting
                opacity *= 1 - meeting
                guard opacity > 0.01 else { continue }

                var sheet = context
                sheet.opacity = opacity
                sheet.translateBy(x: centre.x, y: centre.y)
                sheet.scaleBy(x: scale, y: scale)
                sheet.translateBy(x: -DocSheet.size.width / 2, y: -DocSheet.size.height / 2)
                let through = min(1, max(0, (age - 0.1) / 0.7))
                DocSheet.draw(in: &sheet, kind: coming.kind, tint: coming.tint, lines: 1 - pow(1 - through, 3), edge: 1)
            }
        }
    }

    /// The report being made, on the phone's card (327 × 669.995): documents come in from all round to a grid
    /// that never sits still (`GatherField`), then draw together to the middle of what shows of the card, and the
    /// report grows out from where they meet. The report is `ReportReel`, 368 across at the card's 327, laid out
    /// from the start and kept at its top until it's shown. With Reduce Motion the report is simply there.
    private struct ReportAssembly: View {
        /// When the documents began to come in
        @State private var began: Date?
        @State private var formed = false
        /// The documents are done with, and out of the way
        @State private var cleared = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        private static let size = CGSize(width: 327, height: 669.995)
        /// The middle of what shows of the card, above the foot of the screen: where they meet
        private static let middle = CGPoint(x: 163.5, y: 285)
        /// Seconds of gathering before they draw together
        private static let gathering: Double = 3.3

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: 51.88, style: .continuous)
            return ZStack(alignment: .topLeading) {
                // The card the findings were on, which they leave to it
                LinearGradient(colors: OnboardingWelcomeV2View.washes[0].map { Color(hex: $0) }, startPoint: .leading, endPoint: .trailing)

                if let began, !cleared {
                    GatherField(began: began, drawnAt: Self.gathering, middle: Self.middle)
                        .frame(width: Self.size.width, height: Self.size.height)
                }

                ReportReel(held: !formed)
                    .frame(width: 368, height: Self.size.height * 368 / 327)
                    .scaleEffect(327.0 / 368, anchor: .topLeading)
                    .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
                    .clipShape(shape)
                    .scaleEffect(formed ? 1 : 0.16, anchor: UnitPoint(x: 0.5, y: Self.middle.y / Self.size.height))
                    .opacity(formed ? 1 : 0)
                    .allowsHitTesting(formed)
            }
            .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
            .clipShape(shape)
            .task {
                guard !reduceMotion else {
                    formed = true
                    cleared = true
                    return
                }
                do {
                    // once the findings have gone from the card
                    try await Task.sleep(for: .seconds(0.3))
                    began = Date()
                    // gathered, and then as they meet
                    try await Task.sleep(for: .seconds(Self.gathering + 0.2))
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) { formed = true }
                    try await Task.sleep(for: .seconds(0.9))
                    cleared = true
                } catch {}
            }
        }
    }

    /// The documents being gathered, drawn afresh each frame from the time since they `began`. Five columns of
    /// them, 8 apart, each column moving slowly up or down past the next and coming round again. Each comes in
    /// from nearer and further out, out of focus, at its own moment in the first second, and its lines are drawn
    /// in as it lands. From then on, every couple of seconds, it's lost in light and is another document when the
    /// light's gone, its lines drawn in again; two soft lights wander over the card behind them. `drawnAt` seconds
    /// in, they all go to the `middle`, smaller and fainter as they meet.
    private struct GatherField: View {
        let began: Date
        let drawnAt: Double
        let middle: CGPoint

        private struct Slot {
            let column: Int
            let row: Int
            /// Seconds in that it sets off
            let arrives: Double
            /// How long it's one document before it's the next, and how long the first lasts
            let every: Double
            let first: Double
            let kind: Int
            let step: Int
            let tint: Int
        }

        private static let columns = 5
        /// Down each column: enough to fill the card and one over, so it comes round unseen
        private static let rows = 10
        private static let pitch = CGSize(width: DocSheet.size.width + 8, height: DocSheet.size.height + 8)
        /// Points a second a column moves
        private static let drift: Double = 13
        /// How long the last one waits before coming in
        private static let spread: Double = 1.1
        /// Shuffled once and kept
        private static let slots: [Slot] = {
            var seed: UInt64 = 0x2545F4914F6CDD1D
            func random() -> Double {
                seed ^= seed << 13
                seed ^= seed >> 7
                seed ^= seed << 17
                return Double(seed % 10_000) / 10_000
            }
            var kinds: [Int] = []
            return (0..<columns * rows).map { i in
                let column = i / rows, row = i % rows
                var kind = Int(random() * Double(DocSheet.kinds))
                // not what's over it, or beside it
                while (row > 0 && kinds[i - 1] == kind) || (column > 0 && kinds[i - rows] == kind) { kind = (kind + 1) % DocSheet.kinds }
                kinds.append(kind)
                return Slot(column: column, row: row, arrives: random() * spread,
                            every: 1.7 + random() * 1.3, first: 0.9 + random() * 1.6,
                            kind: kind, step: random() < 0.5 ? 1 : 5, tint: Int(random() * Double(DocSheet.tints.count)))
            }
        }()

        var body: some View {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince(began)
                Canvas { context, size in
                    draw(in: &context, size: size, at: t)
                }
            }
            .allowsHitTesting(false)
        }

        private func clamp(_ x: Double) -> Double { min(1, max(0, x)) }
        private func easeOut(_ x: Double) -> Double { 1 - pow(1 - clamp(x), 3) }

        private func draw(in context: inout GraphicsContext, size: CGSize, at t: Double) {
            // Two lights, wandering
            for (i, light) in [(1.0, 0.0), (0.74, 2.1)].enumerated() {
                let centre = CGPoint(x: middle.x + 120 * sin(t * 0.9 * light.0 + light.1),
                                     y: middle.y + 210 * cos(t * 0.7 * light.0 + light.1 * 1.7))
                let radius: CGFloat = i == 0 ? 170 : 130
                context.fill(Path(ellipseIn: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2)),
                             with: .radialGradient(Gradient(colors: [Color.white.opacity(0.5), Color.white.opacity(0)]),
                                                   center: centre, startRadius: 0, endRadius: radius))
            }

            // The whole of it settles back a little as it fills
            let settle = 1 + 0.07 * (1 - easeOut(t / 1.9))
            // and at the end they all go to the middle
            let drawn = clamp((t - drawnAt) / 0.4)
            let meeting = drawn * drawn
            let loop = Double(Self.rows) * Self.pitch.height

            for slot in Self.slots {
                let since = t - slot.arrives
                guard since > 0 else { continue }

                // Where it is: its column's on the move, even ones up and odd ones down, and comes round again
                let moved = (slot.column % 2 == 0 ? -1.0 : 1.0) * Self.drift * t
                var y = (30 + Double(slot.row) * Self.pitch.height + moved).truncatingRemainder(dividingBy: loop)
                if y < -Self.pitch.height { y += loop }
                if y >= loop - Self.pitch.height { y -= loop }
                guard y < size.height else { continue }
                var centre = CGPoint(x: 20 + Double(slot.column) * Self.pitch.width + DocSheet.size.width / 2, y: y + DocSheet.size.height / 2)
                centre = CGPoint(x: middle.x + (centre.x - middle.x) * settle, y: middle.y + (centre.y - middle.y) * settle)
                let out = CGSize(width: centre.x - middle.x, height: centre.y - middle.y)

                // Coming in
                let landing = easeOut(since / 0.55)
                var scale = settle * (1.7 - 0.7 * landing)
                var opacity = clamp(since / 0.25)
                centre.x += out.width * 0.5 * (1 - landing)
                centre.y += out.height * 0.5 * (1 - landing)

                // Which document it is by now, how far its lines have got, and how much light it's lost in
                var kind = slot.kind, tint = slot.tint
                var lines = easeOut((since - 0.15) / 0.6)
                var light = 0.0
                let turn = since - slot.first
                if turn > -0.22 {
                    let turns = max(0, turn) / slot.every
                    let within = turn < 0 ? turn : (turns - turns.rounded(.down)) * slot.every
                    if turn >= 0 {
                        let count = Int(turns.rounded(.down)) + 1
                        kind = (slot.kind + count * slot.step) % DocSheet.kinds
                        tint = (slot.tint + count) % DocSheet.tints.count
                        lines = easeOut((within - 0.08) / 0.6)
                        light = pow(1 - clamp(within / 0.5), 2)
                    }
                    // and going into the light again, before the next
                    let leaving = turn < 0 ? clamp((turn + 0.22) / 0.22) : clamp((within - (slot.every - 0.22)) / 0.22)
                    if leaving > 0 {
                        light = max(light, leaving)
                        lines *= 1 - leaving
                    }
                }
                scale *= 1 + 0.07 * light

                // Meeting the rest
                centre.x -= out.width * 0.92 * meeting
                centre.y -= out.height * 0.92 * meeting
                scale *= 1 - 0.7 * meeting
                opacity *= 1 - meeting
                guard opacity > 0.01 else { continue }

                var sheet = context
                sheet.opacity = opacity
                sheet.translateBy(x: centre.x, y: centre.y)
                sheet.scaleBy(x: scale, y: scale)
                sheet.translateBy(x: -DocSheet.size.width / 2, y: -DocSheet.size.height / 2)
                if light > 0.02 {
                    // the light it's lost in, spilling round it
                    var glow = sheet
                    glow.addFilter(.blur(radius: 7))
                    glow.opacity = opacity * light * 0.95
                    glow.fill(Path(roundedRect: CGRect(origin: .zero, size: DocSheet.size).insetBy(dx: -4, dy: -4), cornerRadius: 10, style: .continuous),
                              with: .color(.white))
                }
                let blur = 6 * (1 - landing)
                if blur > 0.3 {
                    sheet.addFilter(.blur(radius: blur))
                    sheet.drawLayer { layer in
                        DocSheet.draw(in: &layer, kind: kind, tint: tint, lines: lines, edge: 1 - light * 0.8)
                    }
                } else {
                    DocSheet.draw(in: &sheet, kind: kind, tint: tint, lines: lines, edge: 1 - light * 0.8)
                }
            }
        }
    }

    /// A document as it's gathered, 51 × 66: a white page drawn in hairlines, as the cards' cubes are, with one
    /// part of it in a cube's tint: a page of writing, a graph, bars, a table, a ring or a headed note. What's on
    /// the page is drawn as far as `lines` (0 to 1), one line after another; `edge` is how much its outline shows.
    private enum DocSheet {
        static let size = CGSize(width: 51, height: 66)
        static let kinds = 6
        /// The cubes' faces and the marks on them: green, amber, pink
        static let tints: [(wash: UInt32, mark: UInt32)] = [(0xECFBCB, 0x94B900), (0xFFF1CC, 0x815800), (0xFFE9EE, 0xA03450)]

        static func draw(in context: inout GraphicsContext, kind: Int, tint: Int, lines: Double, edge: Double) {
            let hair: CGFloat = 0.6
            let page = Path(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: hair / 2, dy: hair / 2), cornerRadius: 7, style: .continuous)
            context.fill(page, with: .color(.white))
            defer { context.stroke(page, with: .color(Color.black.opacity(edge)), lineWidth: hair) }
            guard lines > 0 else { return }

            let wash = GraphicsContext.Shading.color(Color(hex: tints[tint].wash).opacity(min(1, lines * 2)))
            let mark = GraphicsContext.Shading.color(Color(hex: tints[tint].mark))
            let ink = GraphicsContext.Shading.color(.black)
            let faint = GraphicsContext.Shading.color(Color.black.opacity(0.42))

            /// How far the `i`th of `count` things has got: each starts after the one before, and all are done at 1
            func reach(_ i: Int, of count: Int) -> CGFloat {
                let each = 1 / (1 + Double(count - 1) * 0.35)
                return CGFloat(min(1, max(0, (lines - Double(i) * 0.35 * each) / each)))
            }
            func stroke(_ points: [CGPoint], _ shading: GraphicsContext.Shading, upTo: CGFloat, width: CGFloat = hair, round: Bool = false) {
                guard upTo > 0 else { return }
                var path = Path()
                path.addLines(points)
                context.stroke(path.trimmedPath(from: 0, to: upTo), with: shading,
                               style: StrokeStyle(lineWidth: width, lineCap: round ? .round : .butt, lineJoin: .round))
            }
            // a line of writing, from the page's left margin
            func rule(_ y: CGFloat, _ length: CGFloat, _ i: Int, of count: Int) {
                stroke([CGPoint(x: 7, y: y), CGPoint(x: 7 + length, y: y)], faint, upTo: reach(i, of: count))
            }
            func title(_ y: CGFloat, _ length: CGFloat, of count: Int) {
                stroke([CGPoint(x: 7, y: y), CGPoint(x: 7 + length, y: y)], ink, upTo: reach(0, of: count), width: 1.5, round: true)
            }
            func box(_ rect: CGRect, upTo: CGFloat) {
                guard upTo > 0 else { return }
                context.stroke(Path(rect).trimmedPath(from: 0, to: upTo), with: ink, lineWidth: hair)
            }

            switch kind {
            case 0:
                // a page of writing
                title(12, 22, of: 8)
                for (i, length) in [37, 33, 37, 27, 37, 35, 19].enumerated() { rule(20 + CGFloat(i) * 6, CGFloat(length), i + 1, of: 8) }
            case 1:
                // a graph going up, and what's said of it
                let frame = CGRect(x: 7, y: 8, width: 37, height: 25)
                context.fill(Path(frame), with: wash)
                box(frame, upTo: reach(0, of: 5))
                stroke([(10, 28), (15, 23), (20, 25), (26, 18), (32, 20), (41, 12)].map { CGPoint(x: $0.0, y: $0.1) }, mark,
                       upTo: reach(1, of: 5), width: 1, round: true)
                for (i, length) in [37, 31, 22].enumerated() { rule(41 + CGFloat(i) * 6, CGFloat(length), i + 2, of: 5) }
            case 2:
                // bars, the last the tallest and the one filled
                title(12, 17, of: 8)
                stroke([CGPoint(x: 7, y: 45), CGPoint(x: 44, y: 45)], ink, upTo: reach(1, of: 8))
                let heights: [CGFloat] = [9, 15, 12, 24]
                for (i, full) in heights.enumerated() {
                    let height = full * reach(i + 2, of: 8)
                    guard height > 0.3 else { continue }
                    let bar = Path(CGRect(x: 9 + CGFloat(i) * 9, y: 45 - height, width: 6, height: height))
                    if i == heights.count - 1 { context.fill(bar, with: wash) }
                    context.stroke(bar, with: ink, lineWidth: hair)
                }
                rule(52, 37, 6, of: 8)
                rule(58, 24, 7, of: 8)
            case 3:
                // a table under its heading
                context.fill(Path(CGRect(x: 7, y: 9, width: 37, height: 8)), with: wash)
                box(CGRect(x: 7, y: 9, width: 37, height: 33), upTo: reach(0, of: 7))
                for (i, y) in ([17, 25.5, 33.5] as [CGFloat]).enumerated() {
                    stroke([CGPoint(x: 7, y: y), CGPoint(x: 44, y: y)], ink, upTo: reach(i + 1, of: 7))
                }
                stroke([CGPoint(x: 22, y: 9), CGPoint(x: 22, y: 42)], ink, upTo: reach(4, of: 7))
                rule(50, 30, 5, of: 7)
                rule(56, 18, 6, of: 7)
            case 4:
                // a ring, a share of it marked
                let centre = CGPoint(x: 25.5, y: 25)
                let round = reach(0, of: 4)
                if round > 0 {
                    var share = Path()
                    share.move(to: centre)
                    share.addArc(center: centre, radius: 14, startAngle: .degrees(-90), endAngle: .degrees(-90 + 125 * reach(1, of: 4)), clockwise: false)
                    share.closeSubpath()
                    context.fill(share, with: wash)
                    context.stroke(share, with: ink, lineWidth: hair)
                    var ring = Path()
                    ring.addArc(center: centre, radius: 14, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * round), clockwise: false)
                    context.stroke(ring, with: ink, lineWidth: hair)
                    let eye = Path(ellipseIn: CGRect(x: centre.x - 6, y: centre.y - 6, width: 12, height: 12))
                    context.fill(eye, with: .color(.white))
                    context.stroke(eye.trimmedPath(from: 0, to: round), with: ink, lineWidth: hair)
                }
                rule(48, 37, 2, of: 4)
                rule(54, 26, 3, of: 4)
            default:
                // a note under a band, with a mark on it
                let band = CGRect(x: 7, y: 8, width: 37, height: 10)
                context.fill(Path(band), with: wash)
                box(band, upTo: reach(0, of: 8))
                stroke([(10, 15.5), (15, 10.5)].map { CGPoint(x: $0.0, y: $0.1) }, mark, upTo: reach(1, of: 8), width: 1, round: true)
                stroke([CGPoint(x: 11.5, y: 10.5), CGPoint(x: 15, y: 10.5), CGPoint(x: 15, y: 14)], mark, upTo: reach(1, of: 8), width: 1, round: true)
                for (i, length) in [37, 34, 37, 29, 37, 21].enumerated() { rule(26 + CGFloat(i) * 6, CGFloat(length), i + 2, of: 8) }
            }
        }
    }

    /// A prompt on a phone (1267:12888, 1277:16358): what it's about, and the question, on a wash of colour
    private func prompt(_ wash: [UInt32], width: CGFloat, height: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: 19, style: .continuous)
        return ZStack(alignment: .topLeading) {
            LinearGradient(colors: wash.map { Color(hex: $0) }, startPoint: .leading, endPoint: .trailing)
            // Gap: GT Walsheim Regular 12.298/15.577 and 13.937/17.217 have no text style (the 15 and 17 of the app's
            // own prompt card, at the phone's scale)
            GapText("Mutual funds market", family: .walsheim, medium: false, size: 12.298, lineHeight: 15.577, color: Color.black.opacity(0.61))
                .fixedSize()
                .at(12.3, height / 2 - 68.27)
            GapText("How mutual funds performed in the last 6 months?", family: .walsheim, medium: false, size: 13.937, lineHeight: 17.217, color: Color.black)
                .frame(width: 127.896, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .at(12.3, height - 66.67)
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .clipShape(shape)
        // 0 1.64 46.731 +4.099 at 7%; SwiftUI can't draw the spread
        .shadow(color: Color.black.opacity(0.07), radius: 23.4, x: 0, y: 1.64)
    }

    /// How much smaller than the frame's the cards are drawn, so two of them and the space between fit the 352
    /// between the frame's margins
    static let cardScale: CGFloat = 352.0 / (186 * 2 + 17)

    /// One card (1267:15780), 186 × 192 on #FEFEFE in the frame, and everything on it, drawn at `cardScale`
    private func card(_ card: Card) -> some View {
        let k = Self.cardScale
        return ZStack(alignment: .topLeading) {
            Color(hex: 0xFEFEFE)
            // 1267:15916: the cube, its front face tinted and an arrow rising across it; 91.354 × 88.242 as drawn
            Image(card.cube)
                .resizable()
                .frame(width: card.cubeWidth * k, height: card.cubeWidth * 88.242 / 91.354 * k)
                .at(15 * k, 15 * k)
                .accessibilityHidden(true)
            // Gap: GT Walsheim Regular 19/21 has no text style. Its top is half way down the card. The frame's 156
            // across is a hair short of "Recommendations", which would break in two, so it has 160.
            GapText(card.promise, family: .walsheim, medium: false, size: 19 * k, lineHeight: 21 * k, color: Color.black)
                .frame(width: 160 * k, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .at(15 * k, 96 * k)
        }
        .frame(width: 186 * k, height: 192 * k, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 33 * k, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: - The advisor

    /// 1245:2411: her portrait, 186 × 192, and "Hello" with the name on a pill over its foot
    private func meeting(side: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // Shadow/2 (0 4 97 +7 at 7%); SwiftUI can't draw the spread
            Image("MeetAdvisorPortrait")
                .frame(width: 394, height: 400)
                .frame(width: 186, height: 192)
                .shadow(color: Color.black.opacity(0.07), radius: 48.5, x: 0, y: 4)
                .accessibilityLabel("Your advisor")
                // She comes up from the foot of the screen, larger than it, over everything on it, and down to
                // this: her size and her place on the one spring, which takes her a little smaller and higher than
                // she ends, and back
                .opacity(advisorIn ? 1 : 0)
                .animation(.easeOut(duration: WorldBefore.advisorFade), value: advisorIn)
                .scaleEffect(advisorIn ? 1 : WorldBefore.advisorFrom)
                .offset(y: advisorIn ? 0 : WorldBefore.advisorBelow)
                .animation(WorldBefore.advisorSpring, value: advisorIn)
                .accessibilityHidden(!advisorIn)
                .at(side + 102, 248 - 44 + top)

            if met {
                // 1245:2473: 178 × 42
                HStack(spacing: 8) {
                    Image("OnboardingWave")
                        .resizable()
                        .frame(width: 18.198, height: 18.426)
                        .accessibilityHidden(true)
                    // Gap: GT Walsheim Medium 19.45/28.095 has no text style
                    GapText("Hello \(AppUser.name)", family: .walsheim, medium: true, size: 19.45, lineHeight: 28.095, color: Color.black)
                        .fixedSize()
                }
                .frame(width: 178, height: 42)
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().strokeBorder(ColorScale.borderSubtle, lineWidth: 0.7))
                .at(side + 106, 425 - 44 + top)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
    }

    /// What can be asked once the funds are connected (1277:19218 onwards; the frame repeats one stand-in). These
    /// are the first onboarding's own prompts for personal advice.
    private static let personal = Array(OnboardingDecadeWelcomeView.advicePrompts.prefix(3))

    /// The last frame under its heading and over its button (1251:12800): her picture, smaller than when she was
    /// met, "Hello" and the name on its foot, and the three questions
    private func connecting(side: CGFloat) -> some View {
        // The portrait and its pill are the meeting's at 144.384 of its 186
        let scale: CGFloat = 144.384 / 186
        return ZStack(alignment: .topLeading) {
            // Shadow/2 (0 4 97 +7 at 7%) at that scale; SwiftUI can't draw the spread
            Image("MeetAdvisorPortrait")
                .frame(width: 394, height: 400)
                .scaleEffect(scale)
                .frame(width: 144.384, height: 149.041)
                .shadow(color: Color.black.opacity(0.07), radius: 48.5 * scale, x: 0, y: 4 * scale)
                .accessibilityLabel("Your advisor")
                .at(side + 123, 80 - 44 + top)

            // 1277:19332: 138.174 × 32.603
            HStack(spacing: 6.2) {
                Image("OnboardingWave")
                    .resizable()
                    .frame(width: 14.126, height: 14.303)
                    .accessibilityHidden(true)
                // Gap: GT Walsheim Medium 15.099/21.809 has no text style
                GapText("Hello \(AppUser.name)", family: .walsheim, medium: true, size: 15.099, lineHeight: 21.809, color: Color.black)
                    .fixedSize()
            }
            .frame(width: 138.174, height: 32.603)
            .background(Capsule().fill(Color.white))
            .overlay(Capsule().strokeBorder(ColorScale.borderSubtle, lineWidth: 0.543))
            .at(side + 126, 217.4 - 44 + top)

            // 1277:19218, 1277:19252, 1277:19261: 356 × 76, 3 apart
            VStack(spacing: 3) {
                ForEach(Self.personal, id: \.self) { question in
                    HStack(spacing: 15) {
                        // 1277:19220: the green cube, 39 across
                        Image("TopicCubeGreen")
                            .resizable()
                            .frame(width: 39.153, height: 37.818)
                            .accessibilityHidden(true)
                        // Gap: GT Walsheim Regular 19/23 has no text style
                        GapText(question, family: .walsheim, medium: false, size: 19, lineHeight: 23, color: Color.black)
                            .frame(width: 243, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 19)
                    .frame(width: 356, height: 76)
                    .background(RoundedRectangle(cornerRadius: 21, style: .continuous).fill(Color(hex: 0xFEFEFE)))
                }
            }
            .at(side + 17, 476 - 44 + top)
        }
    }

    /// The advisor's phone (1249:6253), 336 × 668: its body, and on it either the screen with the pill (and the
    /// keyboard, once that's tapped) or, on the last frame, her picture over the prompts
    /// There's none of the phone to see, only its pill and its keyboard, on the page at the page's size: under her
    /// when she's met, and while the keyboard is up
    private var lone: Bool { stage == .meet || stage == .typing }
    /// How much larger than on the phone they're drawn then: the pill's 272 is 354.113 on the page
    private static let loneZoom: CGFloat = 354.113 / 272

    private var device: some View {
        ZStack(alignment: .topLeading) {
            Group {
                OpenFrame(radius: 59, line: 0).fill(Color.white.opacity(0.5))
                OpenFrame(radius: 59, line: 2).fill(Self.outline, style: FillStyle(eoFill: true))
            }
            .opacity(lone ? 0 : 1)

            if stage < .topics {
                // 1249:6255: the screen, 12 in
                screen
                    .opacity(lone ? 0 : 1)
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
            }
            if stage == .topics {
                Group {
                    // 1277:16357: two columns, 9 between them and 10 between the rows; a tap on any picks it
                    VStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: 9) {
                                ForEach(0..<2, id: \.self) { column in
                                    Button(action: next) {
                                        prompt(Self.washes[row * 2 + column], width: 152.5, height: 157.739)
                                    }
                                    .buttonStyle(PressScaleStyle())
                                    .accessibilityLabel("How mutual funds performed in the last 6 months?")
                                }
                            }
                        }
                    }
                    .at(11, 168)
                }
                .transition(.asymmetric(
                    insertion: .offset(y: 60).combined(with: .opacity).animation(Self.move.delay(0.15)),
                    removal: .opacity.animation(.easeIn(duration: 0.25))
                ))
            }
            if stage <= .topics {
                // 1249:6256: what's on it, 15 in. It's kept for the prompts' frame, where the pill and the
                // keyboard go down out of it
                ZStack(alignment: .topLeading) {
                    if stage == .access {
                        // 1267:13003 and 1267:13002: said over the pill, and the line from it down to it
                        GapText("Tap to try!", family: .walsheim, medium: true, size: 17, lineHeight: 23, color: Color.black.opacity(0.67))
                            .fixedSize()
                            .at(115, 433)
                            .transition(Self.pointer)
                        DrawnArrow.tryIt
                            .at(60.954, 466)
                            .transition(Self.drawn)
                    }

                    if stage < .topics {
                        // 1249:6260: the pill, which rides up over the keyboard. Her picture is in it until
                        // it's tapped; from then it's the one over the phone (`AdvisorFlight`), in the same place
                        Button(action: next) { askPill(pictured: stage <= .access) }
                            .buttonStyle(PressScaleStyle())
                            .disabled(stage > .access)
                            .accessibilityLabel("Ask your advisor")
                            // Tapped, the line that pointed at it runs round it instead, as it rides up
                            .overlay { if stage == .typing { InputRing() } }
                            .at(17, stage <= .access ? 568 : 337)
                            // and it goes back down with the keyboard, the two as one
                            .transition(.asymmetric(insertion: .identity, removal: .offset(y: Self.typingDrop).animation(Self.move)))
                    }

                    if stage == .typing {
                        // (1362:6365 has it 362 across at 14, 549 on the page, a little smaller than the pill's
                        // size makes it, so it's drawn that much smaller and where that puts it)
                        keyboard
                            .scaleEffect(362 / (284 * Self.loneZoom), anchor: .topLeading)
                            .at((14 - 18.943) / Self.loneZoom + 17, (549 - 463) / Self.loneZoom + 337)
                            .transition(.asymmetric(
                                insertion: .offset(y: 240).animation(Self.move),
                                removal: .offset(y: Self.typingDrop).animation(Self.move)
                            ))
                    }
                }
                .frame(width: 306, height: 638, alignment: .topLeading)
                .clipShape(RoundedRectangle(cornerRadius: 46, style: .continuous))
                .at(15, 15)
            }
            if stage < .topics {
                island
                    .opacity(lone ? 0 : 1)
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
            }
            if stage <= .topics {
                // 1277:16379: her picture, small, at the head of the phone (the page's colour lies over it). It's
                // the pill's own, which leaves the pill as that goes down, and grows on its way up
                AdvisorFlight(up: stage == .topics)
                    // in the pill, the pill's own is the one seen. Only its showing is at once: it still rides up
                    // with the pill
                    .animation(nil) { $0.opacity(stage <= .access ? 0 : 1) }
                    .at(stage == .topics ? AdvisorFlight.head.x : AdvisorFlight.pill.x,
                        stage == .topics ? AdvisorFlight.head.y : AdvisorFlight.pill.y + (stage <= .access ? 568 - 337 : 0))
                    .transition(.asymmetric(insertion: .identity, removal: .opacity.animation(.easeIn(duration: 0.25))))
            }
            if stage >= .hold {
                Group {
                    screen
                    shelf
                    island
                }
                .transition(.opacity.animation(.easeOut(duration: 0.35)))
            }
            if stage >= .chat, stage <= .simple {
                Group {
                    screen
                    if Self.compares {
                        // 1251:12227: the chat, on the screen; unseen until its report is what's to be shown
                        chat
                            // Beside its simple version, whichever of the two has less of the screen is out of
                            // focus; they change over slowly as the line is taken across the middle
                            .blur(radius: compare.focusing && !compare.reportLeads ? Self.unfocused : 0)
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 49, topTrailingRadius: 49, style: .continuous))
                            .animation(Self.refocusing, value: compare.focusing && !compare.reportLeads)
                            .at(12, 12)
                            .opacity(reportShown ? 1 : 0)
                            .accessibilityHidden(!reportShown)
                        if !reportCleared {
                            // The same chat again, run alongside and out of focus, over the first from `reportFront`
                            // down: what the report comes clear out of
                            chat
                                .background(Color.white)
                                .blur(radius: 14, opaque: true)
                                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 49, topTrailingRadius: 49, style: .continuous))
                                .mask(alignment: .top) {
                                    VStack(spacing: 0) {
                                        Color.clear.frame(height: max(0, reportFront))
                                        LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                                            .frame(height: 110)
                                        Color.black
                                    }
                                }
                                .at(12, 12)
                                .opacity(reportShown ? 1 : 0)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                        if !reportShown {
                            // 1354:3726: what she goes through to get there, over it
                            ResearchRun()
                                .at(16, 15)
                                .transition(.opacity)
                                // (kept over the screen as it goes: what's leaving a stack otherwise drops behind it)
                                .zIndex(1)
                        }
                        if stage == .simple {
                            CompareLayer(compare: compare)
                                .zIndex(2)
                        }
                    } else {
                        // What it's made from is gathered on the screen, and comes together as the simple report
                        // alone: no report beside it, and no line
                        SimpleMaking(formed: reportShown)
                            .at(12, 12)
                    }
                    island
                        .zIndex(3)
                }
                .transition(.asymmetric(insertion: .opacity.animation(.easeOut(duration: 0.4).delay(0.2)),
                                        removal: .opacity.animation(.easeIn(duration: 0.3))))
            }
        }
        // 1249:4951: from there on the phone is cut off square, 589 down
        .frame(width: 336, height: stage >= .simple ? 589 : 668, alignment: .topLeading)
        .clipped()
    }

    /// From one card's top on the phone to the next's: a card's 269 and the 13 between
    private static let shelfPitch: CGFloat = 282
    /// For the reading levels after the swipe: how far down the screen their card sits (higher than the widgets
    /// before it, so its slider is clear of Continue), and how far the swipe's chart goes up to make way for it
    private static let levelsTop: CGFloat = 138
    private static let levelsPitch: CGFloat = 340

    /// The hold's widget in the place above its own, faint; or a place below that, as it was
    private struct Shelved: ViewModifier {
        let below: Bool
        var pitch = OnboardingWelcomeV2View.shelfPitch

        func body(content: Content) -> some View {
            content
                .opacity(below ? 1 : 0.25)
                .offset(y: below ? pitch : 0)
        }
    }

    /// 1251:6901: a card with nothing on it yet
    private var blankCard: some View {
        RoundedRectangle(cornerRadius: 23, style: .continuous)
            .fill(ColorScale.surfaceSunken1)
            .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).strokeBorder(Color.black.opacity(0.05), lineWidth: 1))
            .frame(width: 292, height: 269)
    }

    /// What's on the phone behind the gestures' widget (1249:2755): the page's colour, a blank card above the
    /// widget's place and one below (1251:6901, 1251:6882), and her picture, small, on the upper one (1277:18770).
    ///
    /// From the hold to the swipe (its widget back in its place first, if it was lifted out) it all moves up a
    /// place, as a page of cards would: the upper blank card goes out
    /// of the top, the hold's widget goes up to where that was and is left there, faint; the lower blank card comes
    /// up to the middle and gives way to the swipe's widget, which comes with it (`OnboardingV2SwipeWidget`); and a
    /// new blank card comes up into the place below.
    private var shelf: some View {
        ZStack(alignment: .topLeading) {
            ColorScale.surfaceBase
            if stage == .hold {
                blankCard
                    .at(10, -94)
                    .transition(.asymmetric(insertion: .identity, removal: .offset(y: -Self.shelfPitch).animation(Self.move)))
                blankCard
                    .at(10, 470)
                    .transition(.asymmetric(insertion: .identity,
                                            removal: .offset(y: -Self.shelfPitch).combined(with: .opacity).animation(Self.move)))
            } else if stage == .swipe {
                // 1251:6862, as the hold had it, done with: from where the hold left it, as it was, up and fainter
                ComplexityCard(level: .simply, soft: true, width: 292)
                    .at(10, -94)
                    .transition(.asymmetric(
                        insertion: .modifier(active: Shelved(below: true), identity: Shelved(below: false)).animation(Self.move),
                        removal: .offset(y: -Self.levelsPitch).combined(with: .opacity).animation(Self.move)
                    ))
                blankCard
                    .at(10, 467)
                    .transition(.asymmetric(insertion: .offset(y: Self.shelfPitch).animation(Self.move),
                                            removal: .offset(y: -Self.levelsPitch).combined(with: .opacity).animation(Self.move)))
            } else {
                // The swipe's chart, done with in its turn: from where the swipe left it, up and fainter
                MSFTChartCard()
                    .clipShape(RoundedRectangle(cornerRadius: 23 * 364 / 292, style: .continuous))
                    .frame(width: 364, height: 330, alignment: .topLeading)
                    .scaleEffect(292.0 / 364, anchor: .topLeading)
                    .frame(width: 292, height: 264.725, alignment: .topLeading)
                    .at(10, 188.812 - Self.levelsPitch)
                    .transition(.asymmetric(
                        insertion: .modifier(active: Shelved(below: true, pitch: Self.levelsPitch),
                                             identity: Shelved(below: false, pitch: Self.levelsPitch)).animation(Self.move),
                        removal: .identity
                    ))
            }
            Image("MeetAdvisorPortrait")
                .frame(width: 394, height: 400)
                .scaleEffect(59.346 / 186)
                .frame(width: 59.346, height: 61.26)
                .at(126, 50)
        }
        .frame(width: 312, height: 577, alignment: .topLeading)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 49, topTrailingRadius: 49, style: .continuous))
        // inside the screen's outline
        .mask(OpenFrame(radius: 49, line: 0).frame(width: 312, height: 641).frame(height: 577, alignment: .top))
        .at(12, 12)
        .accessibilityHidden(true)
    }

    /// The report and its simple version, side by side on the phone's screen (in the phone's own measure, 336 × 589):
    /// the simple version from the line to the screen's right edge, and the line. It draws itself from `Compare`,
    /// so it is all that's redrawn as the line moves.
    private struct CompareLayer: View {
        let compare: Compare
        /// Where the line stood when the drag began
        @State private var dragFrom: CGFloat?

        var body: some View {
            ZStack(alignment: .topLeading) {
                simple
                divider
            }
            .frame(width: 336, height: 589, alignment: .topLeading)
        }

        /// How far across the screen's 312 the middle of the line is: its 13 stay within it
        private var lineX: CGFloat { 6.5 + compare.split * 299 }

        /// The line between the two (1249:5255): 13 across on white, from the screen's top to the phone's foot, cut to
        /// the screen's corners at either end of its run; the island lies over it. It's dragged across; let go near
        /// the left edge, it goes all the way, and the heading changes for it.
        private var divider: some View {
            Color.white
                .frame(width: 13, height: 577)
                // 0 2 34 +6 at 9%; SwiftUI can't draw the spread
                .shadow(color: Color.black.opacity(0.09), radius: 17, x: 0, y: 2)
                .frame(width: 56, height: 577)
                .contentShape(Rectangle())
                .gesture(
                    // Measured on the screen, not on the line itself, which moves under the finger as it's dragged
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            if dragFrom == nil {
                                dragFrom = compare.split
                                compare.touched = true
                                compare.focusing = true
                                Haptics.prepare()
                            }
                            // straight to where the finger is, whatever else is still settling
                            var direct = Transaction()
                            direct.disablesAnimations = true
                            withTransaction(direct) {
                                compare.split = min(1, max(0, (dragFrom ?? compare.split) + value.translation.width / 299))
                            }
                        }
                        .onEnded { _ in
                            dragFrom = nil
                            guard compare.split < 0.08 else { return }
                            // all the way: nothing but the simple version, and the heading says what that is
                            if compare.split > 0 || !compare.simplified { Haptics.tap() }
                            withAnimation(OnboardingWelcomeV2View.move) {
                                compare.split = 0
                                compare.simplified = true
                            }
                        }
                )
                .at(12 + lineX - 28, 12)
                .mask(alignment: .topLeading) {
                    UnevenRoundedRectangle(topLeadingRadius: 49, topTrailingRadius: 49, style: .continuous)
                        .frame(width: 312, height: 577)
                        .at(12, 12)
                }
                .opacity(compare.shown ? 1 : 0)
                .accessibilityElement()
                .accessibilityLabel("Between the report and its simple version")
                .accessibilityValue("\(Int(((1 - compare.split) * 100).rounded())) percent simple")
                .accessibilityAdjustableAction { direction in
                    compare.touched = true
                    compare.focusing = true
                    withAnimation(OnboardingWelcomeV2View.move) {
                        compare.split = min(1, max(0, compare.split + (direction == .increment ? -0.25 : 0.25)))
                        if compare.split == 0 { compare.simplified = true }
                    }
                }
        }

        /// The report put simply (`SimpleReport`), over the screen from the line to its right edge
        private var simple: some View {
            SimpleReport(height: 577)
                // out of focus while the report has more of the screen (as the report is while this has)
                .blur(radius: compare.focusing && compare.reportLeads ? OnboardingWelcomeV2View.unfocused : 0, opaque: true)
                .animation(OnboardingWelcomeV2View.refocusing, value: compare.focusing && compare.reportLeads)
                // Only from the line rightwards: it keeps its place as the line moves over it, and takes touches only there
                .frame(width: max(0, 312 - lineX), height: 577, alignment: .trailing)
                .contentShape(Rectangle())
                .clipped()
                .at(12 + lineX, 12)
                .opacity(compare.shown ? 1 : 0)
        }
    }

    /// The report put simply (1277:18163), on the phone's screen: 312 across and `height` of it showing. The frame's
    /// card is 327 across; it's drawn at the screen's 312, on the yellow-to-peach wash, and it starts under the
    /// phone's island and scrolls, since what's under the phone covers its foot.
    private struct SimpleReport: View {
        var height: CGFloat = 577

        var body: some View {
            let scale: CGFloat = 312.0 / 327
            return ScrollView(showsIndicators: false) {
                VStack(spacing: 18.66) {
                    // 1277:18173
                    simpleCard(height: 146.617) {
                        // Gap: GT Walsheim Regular 31.101/36.432 has no text style
                        GapText("Equity funds did +7.1% returns", family: .walsheim, medium: false, size: 31.101, lineHeight: 36.432, color: ColorScale.contentPrimary)
                            .frame(width: 266.576, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .at(15.11, 15.11)
                        HStack(spacing: 3.55) {
                            Image("ReportMorningstar")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 12.776, height: 12.103)
                                .clipShape(RoundedRectangle(cornerRadius: 2.133, style: .continuous))
                                .accessibilityHidden(true)
                            // Gap: Reckless Regular 13.507/19.193; the colour is content/tertiary
                            GapText("Verified data source: Morningstar", family: .reckless, medium: false, size: 13.507, lineHeight: 19.193, color: ColorScale.contentTertiary)
                                .fixedSize()
                        }
                        .at(15.11, 114.63)
                    }
                    // 1277:18164: the four kinds of fund, equity's the tallest and the only one filled
                    simpleCard(height: 172.386) {
                        let bars: [(label: String, x: CGFloat, height: CGFloat)] = [
                            ("Debt\nfunds", 23.99, 24.88), ("Hybrid\nfunds", 94.19, 49.761),
                            ("Index\nfunds", 164.39, 88.859), ("Equity\nfunds", 234.59, 103.076),
                        ]
                        ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                            Group {
                                if index == bars.count - 1 {
                                    Color(hex: 0x3FD519)
                                } else {
                                    Color.white.overlay(Rectangle().strokeBorder(ColorScale.borderStrong, lineWidth: 0.889))
                                }
                            }
                            .frame(width: 38.209, height: bar.height)
                            .at(bar.x, 172.386 - 55.09 - bar.height)
                            // Gap: GT Walsheim Regular 10.663/15.106, tracking 7%, black at 60%
                            GapText(bar.label, family: .walsheim, medium: false, size: 10.663, lineHeight: 15.106, trackingPercent: 7, color: Color.black.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .frame(width: 48.872)
                                .at(bar.x + 38.209 / 2 - 48.872 / 2, 130.62)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Equity funds returned more than index, hybrid and debt funds")
                    // 1277:18178 and 1277:18180
                    simpleNote("Equity funds did well as war fears eased and oil got cheaper, so foreign investors started buying again.", height: 122.625)
                    simpleNote("Small-cap funds did better because they had fallen much more earlier, so they had more room to bounce back", height: 146.617)
                }
                // under the island, and its last card clear of what's under the phone
                .padding(.top, 48)
                .padding(.bottom, 190)
                .frame(width: 327)
            }
            .frame(width: 327, height: height / scale)
            .background(LinearGradient(colors: OnboardingWelcomeV2View.washes[0].map { Color(hex: $0) }, startPoint: .leading, endPoint: .trailing))
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: 312, height: height, alignment: .topLeading)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 49, topTrailingRadius: 49, style: .continuous))
        }

        /// One of its cards, 296.788 across on white
        private func simpleCard<Content: View>(height: CGFloat, @ViewBuilder content: () -> Content) -> some View {
            ZStack(alignment: .topLeading) {
                Color.white
                content()
            }
            .frame(width: 296.788, height: height, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 15.106, style: .continuous))
        }

        /// A card of plain words (1277:18178)
        private func simpleNote(_ text: String, height: CGFloat) -> some View {
            simpleCard(height: height) {
                // Gap: GT Walsheim Regular 20.438/23.992 has no text style; the colour is content/secondary
                GapText(text, family: .walsheim, medium: false, size: 20.438, lineHeight: 23.992, color: ColorScale.contentSecondary)
                    .frame(width: 270.13, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .at(13.33, 13.33)
            }
        }
    }

    /// The phone's screen (1249:6255), 312 × 641, 12 in: white, outlined as the phone is
    private var screen: some View {
        ZStack {
            OpenFrame(radius: 49, line: 0).fill(Color.white)
            OpenFrame(radius: 49, line: 3).fill(Self.outline, style: FillStyle(eoFill: true))
        }
        .frame(width: 312, height: 641)
        .at(12, 12)
        .accessibilityHidden(true)
    }

    /// 1249:6257
    private var island: some View {
        Capsule().fill(Color.black)
            .frame(width: 89, height: 26)
            .at(124, 25)
            .accessibilityHidden(true)
    }

    /// The first onboarding's chat, run on the phone's screen (1251:12227): laid out in its own points, in the
    /// room the screen has down to the foot of the real one, and drawn at the phone's scale. Beside its simple
    /// version it's drawn a little larger and higher, so the report's top is where the frame has it (1249:5010).
    private var chat: some View {
        let showing = min(641, UIScreen.main.bounds.height - (Stage.chat.deviceTop - 44 + top) - 12)
        let room = CGSize(width: 312 / Self.chatScale, height: showing / Self.chatScale)
        let beside = stage == .simple
        return OnboardingDecadeWelcomeView(onContinue: {}, embedded: .init(topic: Self.asked, size: room, pace: Self.chatPace, onReport: reportUp))
            .frame(width: room.width, height: room.height)
            .scaleEffect(beside ? Self.reportScale : Self.chatScale, anchor: .top)
            // the report hangs 56 down its room; 47.2 down the phone is 35.2 down the screen
            .offset(y: beside ? 35.2 - 56 * Self.reportScale : 0)
            .frame(width: 312, height: showing, alignment: .top)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 49, topTrailingRadius: 49, style: .continuous))
    }

    /// "Ask your advisor" (1249:6260), 272 × 53: the plus, her picture, and the words
    /// How far the pill and the keyboard go down to leave the screen
    private static let typingDrop: CGFloat = 330

    private func askPill(pictured: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            Capsule().fill(Color(hex: 0xF9F9F9))
            // 1249:6261: a lighter band along its top and foot
            RoundedRectangle(cornerRadius: 37, style: .continuous)
                .strokeBorder(Color.white.opacity(0.63), lineWidth: 5)
                .mask(VStack(spacing: 0) { Color.black.frame(height: 5); Color.clear; Color.black.frame(height: 5) })
                .padding(.vertical, 1.3)
            Capsule().strokeBorder(Color.black.opacity(0.31), lineWidth: 0.7)
            Image("PlusIcon")
                .resizable()
                .frame(width: 13.0239, height: 13.0156)
                .at(13.3, 26.5 + 0.83 - 6.51)
            // 30 across, in a 32.95 frame
            Image("PillAvatar")
                .frame(width: 32.9508, height: 32.9508)
                .opacity(pictured ? 1 : 0)
                // gone at once, as the one over the phone takes its place
                .animation(nil, value: pictured)
                .at(36.3 - 1.475, 26.5 + 0.5 - 16.475)
            // Gap: black at 67% is not a content token
            GapText("Ask your advisor", family: .walsheim, medium: false, size: 17, lineHeight: 23, color: Color.black.opacity(0.67))
                .fixedSize()
                .at(75.3, 15)
        }
        .frame(width: 272, height: 53, alignment: .topLeading)
        .shadow(color: Color.black.opacity(0.03), radius: 7.5, x: 0, y: 3)
    }

    /// The keyboard as the frame draws it (1251:6800)
    private var keyboard: some View { OnboardingV2Keyboard() }

    // MARK: - Arrival

    /// As the first welcome arrives: the ground flows up, what's on it comes in, and after a beat to read, Continue
    private func play() async {
        withAnimation(.easeInOut(duration: OnboardingDecadeWelcomeView.flowDuration)) { flow = 1 }
        try? await Task.sleep(for: .seconds(OnboardingDecadeWelcomeView.flowDuration * 0.7))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.62, dampingFraction: 0.86)) { shown = true }
        try? await Task.sleep(for: .seconds(1.3))
        guard !Task.isCancelled else { return }
        Haptics.settle()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { buttonShown = true }
    }

    /// Opaque from the bottom up to the rising edge, feathered so the ground seeps in rather than wipes
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
}

/// The hint's line again, once the pill it pointed at has been tapped: the same 3 of yellow, with no arrowhead,
/// running once round the pill from where the arrow touched it, 5 clear of its edge. It's laid over the pill, so it
/// rides up with it.
/// The keyboard as the second onboarding's phone has it (1251:6800), 284 × 186: blank keys, each where it is there.
/// Under the pill once that's tapped, and under the composer the swipe brings up.
struct OnboardingV2Keyboard: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 19, style: .continuous)
        // x, y, width; all 32 tall
        let keys: [(CGFloat, CGFloat, CGFloat)] =
            stride(from: 12.3, through: 244.3, by: 29).map { ($0, 12.3, 24) }
            + stride(from: 19.3, through: 236.3, by: 31).map { ($0, 53.3, 24) }
            + [(12.3, 94.3, 45)] + stride(from: 65.3, through: 189.3, by: 31).map { ($0, 94.3, 24) } + [(224.3, 94.3, 46)]
            + [(8.3, 135.3, 34), (49.3, 135.3, 180), (236.3, 135.3, 34)]
        return ZStack(alignment: .topLeading) {
            shape.fill(Color(hex: 0xF9F9F9))
            shape.strokeBorder(Color.black.opacity(0.11), lineWidth: 0.7)
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(hex: 0xEAEBE9))
                    .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous).strokeBorder(Color.black.opacity(0.07), lineWidth: 0.7))
                    .frame(width: key.2, height: 32)
                    .at(key.0, key.1)
            }
        }
        .frame(width: 284, height: 186, alignment: .topLeading)
        .shadow(color: Color.black.opacity(0.03), radius: 7.5, x: 0, y: 3)
        .accessibilityHidden(true)
    }
}

/// What the advisor goes through for the topic picked, on the phone's screen (1354:3726, 305 × 635): the research
/// sheet's own parts at the phone's scale (its 330 across is 284.392 here), one under another: the plan, what was
/// gathered, three counts, and the sites read. Only what's at the top of the screen is clear; from there down
/// it's lost in a blur that deepens to the foot (1362:5784), which stays where it is. The whole of it goes up the
/// screen a part at a time, with a rest after each: the plan gives way to what was gathered, that to the counts,
/// and then the sites one row after another, each clear as it gets to the top. Nothing is brought in: it's all
/// there from the start. It's a picture of the research, not the research: the chat under it is the real one.
/// With Reduce Motion it stays where it starts.
private struct ResearchRun: View {
    /// Seconds it's shown for, before the report
    static let duration: Double = 4.75

    @State private var began = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let scale: CGFloat = 284.392 / 330
    private static let size = CGSize(width: 305, height: 635)
    private static let line = Color(red: 194 / 255, green: 194 / 255, blue: 194 / 255).opacity(0.33)
    private static let ink = Color(red: 33 / 255, green: 33 / 255, blue: 33 / 255)
    /// Down the screen, where the blur begins (as the frame has it, under the first part), how far below that it's
    /// at its deepest, and how deep that is
    private static let front: CGFloat = 96
    private static let depth: CGFloat = 300
    private static let deepest: CGFloat = 24
    /// How far each step takes it up, on the sheet's own measure: past the plan, past what was gathered, past the
    /// counts, and then a site's row at a time
    private static let rises: [CGFloat] = [50, 74, 121.2] + Array(repeating: 44, count: 20)
    /// Seconds before the first step, from one step to the next, and that a step takes of that: the rest is its rest
    private static let waits: Double = 0.55
    private static let every: Double = 0.5
    private static let moving: Double = 0.3
    /// Sites enough to be still coming up at the foot when it ends
    private static let rows = 22

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            parts(risen: reduceMotion ? 0 : Self.risen(at: timeline.date.timeIntervalSince(began)))
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 47.69, style: .continuous))
        // 0 3.076 76.902 +9.228 at 5%; SwiftUI can't draw the spread
        .background(
            RoundedRectangle(cornerRadius: 47.69, style: .continuous).fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 38.45, x: 0, y: 3.076)
        )
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Researching it")
        .onAppear { began = Date() }
    }

    /// How far up it has gone, `t` seconds in, on the sheet's own measure: a step at a time, each eased in and out
    /// and followed by its rest
    private static func risen(at t: Double) -> CGFloat {
        var risen: CGFloat = 0
        for (index, rise) in rises.enumerated() {
            let through = min(1, max(0, (t - waits - every * Double(index)) / moving))
            guard through > 0 else { break }
            risen += rise * CGFloat(through * through * (3 - 2 * through))
        }
        return risen
    }

    /// 1354:5542: all of it, laid out on the sheet's own 330 from 10 across and 50.69 down the screen, `risen` up
    /// from there; each part as lost in the blur as it is far below where the blur begins, and gone as it goes
    /// off the top
    private func parts(risen: CGFloat) -> some View {
        // for something whose middle is `y` down the sheet
        func hazed(_ y: CGFloat) -> CGFloat {
            min(1, max(0, (50.69 + (y - risen) * Self.scale - Self.front) / Self.depth))
        }
        func leaving(_ y: CGFloat) -> CGFloat {
            min(1, max(0, (50.69 + (y - risen) * Self.scale - 4) / 30))
        }
        return ZStack(alignment: .topLeading) {
            // 1354:5508
            box(radius: 13, width: 330, height: 43) {
                Image("ResearchDoc").frame(width: 17, height: 17).at(12, 13)
                // Gap: GT Walsheim Regular 14/17, #212121 at 67%
                Text("Research plan created")
                    .font(FigmaFont.walsheim(14))
                    .foregroundStyle(Self.ink.opacity(0.67))
                    .fixedSize()
                    .frame(height: 17)
                    .at(38, 12)
            }
            .modifier(Hazed(by: hazed(21), deepest: Self.deepest, shown: leaving(21)))
            // 1354:5531
            box(radius: 13, width: 330, height: 63) {
                Image("ResearchGlobe").frame(width: 17, height: 17).at(12, 13)
                Text("Gathered 890 resources")
                    .font(FigmaFont.walsheim(14))
                    .foregroundStyle(Self.ink.opacity(0.67))
                    .fixedSize()
                    .frame(height: 17)
                    .at(38, 12)
                // Gap: GT Walsheim Regular 13/17, #212121 at 47%
                Text("Credible sources verified by research agent")
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(Self.ink.opacity(0.47))
                    .fixedSize()
                    .frame(height: 17)
                    .at(38, 32)
            }
            .modifier(Hazed(by: hazed(81), deepest: Self.deepest, shown: leaving(81)))
            .at(0, 50)
            // 1354:5513, 1354:5519, 1354:5525: the sheet's own counts, the third running off the screen's edge
            ForEach(Array(ResearchSheet.counts.enumerated()), id: \.offset) { index, count in
                ResearchSheet.countTile(count)
                    .modifier(Hazed(by: hazed(176), deepest: Self.deepest, shown: leaving(176)))
                    .at(CGFloat(index) * 120, 124)
            }
            // 1354:5471: the sites, 44 a row with a line under each, in a box that runs on down past the foot
            box(radius: 17, width: 330, height: CGFloat(Self.rows) * 44) {
                ForEach(0..<Self.rows, id: \.self) { index in
                    let middle = 245.2 + CGFloat(index) * 44 + 22
                    row(ResearchSource.all[index % ResearchSource.all.count])
                        .modifier(Hazed(by: hazed(middle), deepest: Self.deepest, shown: leaving(middle)))
                        .at(0, CGFloat(index) * 44)
                }
            }
            .at(0, 245.2)
        }
        .frame(width: 330, height: 245.2 + CGFloat(Self.rows) * 44, alignment: .topLeading)
        .offset(y: -risen)
        .scaleEffect(Self.scale, anchor: .topLeading)
        .frame(width: 330 * Self.scale, height: Self.size.height, alignment: .topLeading)
        .at(10, 50.69)
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .background(Color.white)
        // 1362:5784's wash over the blur: white, from none where it begins to 39% 541 further down
        .overlay(alignment: .top) {
            LinearGradient(colors: [Color.white.opacity(0), Color.white.opacity(0.39)], startPoint: .top, endPoint: .bottom)
                .frame(height: 541)
                .offset(y: Self.front)
        }
        .clipped()
    }

    /// One site read (1354:5472): its mark, the page and where it is
    private func row(_ source: ResearchSource) -> some View {
        ZStack(alignment: .topLeading) {
            SourceLogo(domain: source.domain).at(12, 12.8)
            // Gap: GT Walsheim Regular 13/17, #212121 at 67% and at 47%
            Text(source.title)
                .font(FigmaFont.walsheim(13))
                .foregroundStyle(Self.ink.opacity(0.67))
                .lineLimit(1)
                .frame(width: 201, height: 17, alignment: .leading)
                .at(38, 12.8)
            Text(source.domain)
                .font(FigmaFont.walsheim(13))
                .foregroundStyle(Self.ink.opacity(0.47))
                .lineLimit(1)
                .frame(width: 76, height: 17, alignment: .leading)
                .at(244, 12.8)
            Self.line.frame(width: 316, height: 1).at(1, 42.8)
        }
        .frame(width: 330, height: 44, alignment: .topLeading)
    }

    /// One of its boxes: white, outlined in the sheet's line
    private func box<Content: View>(radius: CGFloat, width: CGFloat, height: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return ZStack(alignment: .topLeading) { content() }
            .frame(width: width, height: height, alignment: .topLeading)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Self.line, lineWidth: 1))
    }

    /// Lost in the blur by so much (0 to 1): out of focus, and fainter; and `shown` as it goes off the top (1 to 0)
    private struct Hazed: ViewModifier {
        let by: CGFloat
        let deepest: CGFloat
        var shown: CGFloat = 1

        func body(content: Content) -> some View {
            content
                .blur(radius: deepest * by)
                .opacity((1 - 0.45 * by) * shown)
        }
    }
}

/// Before the advisor is met (1341:2567): what there is to ask about, on the frame's 390 × 840. Fund houses' and
/// companies' marks on tiles, the frame's seven, some with a question or two under them, and fifty more, smaller,
/// all round them, come at the screen one after another, each
/// large at first, and go away into it, smaller and smaller, towards where she will stand: each to a point part
/// of the way there from its own place, so that large it's still on the screen. The frame is one moment of that:
/// each passes through its place and size there. When she comes in over them (`gone`), what's left of them goes
/// under her.
private struct WorldBefore: View {
    /// She has come in over them
    let gone: Bool

    @State private var out = false

    /// The middle of her portrait on the frame (1245:2411): where they're all going
    private static let centre = CGPoint(x: 195, y: 344)
    /// Seconds before the first sets off, while the frame before clears
    static let leadIn: Double = 0.35
    /// How many times longer their passing takes than when it was first set: when each sets off, how long it's
    /// going, and when she comes
    private static let pace: Double = 2
    /// Seconds after that when she comes in over them
    static let covered: Double = 2.4 * pace
    /// How fast she comes in, of the pace she was first given
    private static let advisorPace: Double = 0.4
    /// How many times her size she comes in at: larger than the screen
    static let advisorFrom: CGFloat = 4.2
    /// The spring she comes down to her size and up to her place on: loose enough to go past both and come back
    static let advisorSpring = Animation.spring(response: 0.72 / advisorPace, dampingFraction: 0.68)
    /// Seconds for her to come out of nothing as she starts, and after she starts that she's as good as settled
    static let advisorFade: Double = 0.12 / advisorPace
    static let advisorSettles: Double = 0.95 / advisorPace
    /// A tile's side when it comes in, and when it would be done going away: the frame's seven, and the rest
    private static let near: CGFloat = 280
    private static let far: CGFloat = 12
    private static let nearSmall: CGFloat = 150
    private static let farSmall: CGFloat = 7
    /// How far from the middle, of its own distance on the frame, the point each goes away to is
    private static let apart: CGFloat = 0.45
    /// The light each comes in lost in: how far it spills round it, on an 87 tile, and the seconds it takes to clear
    private static let spill: CGFloat = 7
    private static let clearing: Double = 0.7
    /// How far below her place she comes in from: her middle near the foot of the screen
    static let advisorBelow: CGFloat = 400
    /// Seconds from one to the other, fast at first and slower all the time
    private static let going: Double = 3.2 * pace
    /// The frame's seven are laid out with their tiles at twice the frame's 87, to be sharp while they're large
    private static let unit: CGFloat = 2

    private struct Thing: Identifiable {
        let id: Int
        let mark: String
        /// How large the mark is drawn on the tile's 87
        var markSize = CGSize(width: 106, height: 106)
        /// Where it stands on the frame, and its tile's side there
        let at: CGPoint
        let side: CGFloat
        /// The questions under it, the tile's and their places across, and the first question's down
        var asks: [String] = []
        var tileX: CGFloat = 0
        var askX: CGFloat = 7
        var askY: CGFloat = 102
        /// Seconds after the first that it sets off, at the pace first set
        let starts: Double
        var sets: Double { starts * WorldBefore.pace }
        /// One of the many round the frame's seven: smaller, a tile and no more, laid out at the frame's own size
        var small = false

        var near: CGFloat { small ? WorldBefore.nearSmall : WorldBefore.near }
        var far: CGFloat { small ? WorldBefore.farSmall : WorldBefore.far }
        var unit: CGFloat { small ? 1 : WorldBefore.unit }

        /// Across and down it all, on an 87 tile
        var size: CGSize {
            asks.isEmpty ? CGSize(width: 87, height: 87) : CGSize(width: 259, height: askY + 68 * CGFloat(asks.count - 1) + 57)
        }
    }

    /// Fifty more listed companies and fund houses, from their sites' own icons, and whether each fills its tile
    /// or stands on the tile's white
    private static let marks: [(name: String, fills: Bool)] = [
        ("WorldZee", true), ("WorldWaaree", false), ("WorldVarun", false), ("WorldPVRInox", true),
        ("WorldOberoi", false), ("WorldNivaBupa", false), ("WorldLenskart", true), ("WorldHDFCLife", true),
        ("WorldDixon", false), ("WorldDivis", false), ("WorldCanara", false), ("WorldAUBank", false),
        ("WorldNykaa", true), ("WorldTechMahindra", false), ("WorldSwiggy", true), ("WorldSunPharma", false),
        ("WorldPFC", false), ("WorldNestle", false), ("WorldIxigo", true), ("WorldIndusInd", true),
        ("WorldIndiaMart", false), ("WorldGlenmark", false), ("WorldDMart", false), ("WorldCarTrade", false),
        ("WorldUnitedSpirits", false), ("WorldTata", false), ("WorldShree", false), ("WorldPrestige", false),
        ("WorldPolycab", true), ("WorldNaukri", true), ("WorldMaxHealth", true), ("WorldKFin", false),
        ("WorldBosch", false), ("WorldIndiGo", true), ("WorldIRCTC", false), ("WorldHUL", false),
        ("WorldColgate", false), ("WorldUrban", true), ("WorldSBICard", false), ("WorldVodafone", false),
        ("WorldDelhivery", true), ("WorldLIC", true), ("WorldPowerGrid", false), ("WorldAxisMF", true),
        ("WorldHDFCAMC", false), ("WorldKotakMF", false), ("WorldHSBCMF", false), ("WorldHeliosMF", true),
        ("WorldZerodhaFund", true), ("WorldBandhanMF", false),
    ]

    /// Those fifty, round the frame's seven and under them: each in a cell of its own, six across and nine down
    /// the frame, a little off the cell's middle, 36 to 58 across there, setting off one after another through the
    /// first second and three quarters. Which cell, how far off, how large and when are shuffled once and kept.
    private static let many: [Thing] = {
        var seed: UInt64 = 0x9E3779B97F4A7C15
        func random() -> CGFloat {
            seed ^= seed << 13
            seed ^= seed >> 7
            seed ^= seed << 17
            return CGFloat(seed % 10_000) / 10_000
        }
        var cells = Array(0..<54)
        var order = Array(0..<marks.count)
        for i in stride(from: cells.count - 1, to: 0, by: -1) { cells.swapAt(i, Int(random() * CGFloat(i + 1))) }
        for i in stride(from: order.count - 1, to: 0, by: -1) { order.swapAt(i, Int(random() * CGFloat(i + 1))) }
        return marks.enumerated().map { i, mark in
            let side = 36 + random() * 22
            let cell = CGSize(width: 390.0 / 6, height: (800.0 - 60) / 9)
            let middle = CGPoint(x: (CGFloat(cells[i] % 6) + 0.5 + (random() - 0.5) * 0.5) * cell.width,
                                 y: 60 + (CGFloat(cells[i] / 6) + 0.5 + (random() - 0.5) * 0.5) * cell.height)
            return Thing(id: 100 + i, mark: mark.name,
                         markSize: mark.fills ? CGSize(width: 87, height: 87) : CGSize(width: 62, height: 62),
                         at: CGPoint(x: middle.x - side / 2, y: middle.y - side / 2), side: side,
                         starts: Double(order[i]) / Double(marks.count - 1) * 1.75, small: true)
        }
    }()

    /// The frame's seven: the smallest on the frame set off first
    private static let things: [Thing] = [
        // 1349:2759
        Thing(id: 0, mark: "WorldMicrosoft", at: CGPoint(x: 60, y: 420), side: 50.722,
              asks: ["Will Microsoft make profits?", "Will Microsoft make profits?"], starts: 0),
        // 1349:2787
        Thing(id: 1, mark: "WorldPPFAS", at: CGPoint(x: 3, y: 147), side: 87,
              asks: ["Is Parag Pareikh still a great choice?"], starts: 0.22),
        // 1349:2742
        Thing(id: 2, mark: "WorldMRF", markSize: CGSize(width: 87, height: 87), at: CGPoint(x: 151, y: 128), side: 87, starts: 0.4),
        // 1349:2744
        Thing(id: 3, mark: "WorldHDFC", markSize: CGSize(width: 107, height: 94), at: CGPoint(x: -2, y: 350), side: 87, starts: 0.58),
        // 1349:2740
        Thing(id: 4, mark: "WorldTree", at: CGPoint(x: 108, y: 620), side: 87, starts: 0.76),
        // 1349:2770: its tile on the right
        Thing(id: 5, mark: "WorldZomato", at: CGPoint(x: 103, y: 168), side: 106.483,
              asks: ["Will Microsoft make profits?", "Will Microsoft make profits?"], tileX: 172, askX: -2, askY: 100, starts: 0.98),
        // 1349:2736
        Thing(id: 6, mark: "WorldMotilal", at: CGPoint(x: 222, y: 473), side: 187, starts: 1.25),
    ]

    /// When each comes onto the screen, in seconds from the start and in order, and whether it's one of the many
    static let appearances: [(at: Double, small: Bool)] = (many + things)
        .map { (at: leadIn + $0.sets, small: $0.small) }
        .sorted { $0.at < $1.at }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Self.many + Self.things) { thing in
                // Laid out where it would be with its tile at its `unit` times 87, and drawn larger or smaller about
                // the point it's going away to, which moves it towards that as it shrinks
                let scale = thing.side / 87
                let middle = CGPoint(x: thing.at.x + thing.size.width * scale / 2, y: thing.at.y + thing.size.height * scale / 2)
                let vanishing = CGPoint(x: Self.centre.x + (middle.x - Self.centre.x) * Self.apart,
                                        y: Self.centre.y + (middle.y - Self.centre.y) * Self.apart)
                let place = CGPoint(x: vanishing.x + (thing.at.x - vanishing.x) * thing.unit / scale,
                                    y: vanishing.y + (thing.at.y - vanishing.y) * thing.unit / scale)
                drawn(thing, lit: !out)
                    .fixedSize()
                    .frame(width: 0, height: 0, alignment: .topLeading)
                    .offset(x: place.x, y: place.y)
                    .frame(width: 390, height: 840, alignment: .topLeading)
                    .opacity(out && !gone ? 1 : 0)
                    .animation(gone ? .easeIn(duration: 0.16) : .easeOut(duration: 0.25).delay(Self.leadIn + thing.sets), value: out && !gone)
                    .scaleEffect(gone ? 0.02 : (out ? thing.far : thing.near) / (87 * thing.unit),
                                 anchor: UnitPoint(x: vanishing.x / 390, y: vanishing.y / 840))
                    .animation(.timingCurve(0.215, 0.61, 0.355, 1, duration: Self.going).delay(Self.leadIn + thing.sets), value: out)
            }
        }
        .frame(width: 390, height: 840, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { out = true }
    }

    /// One of them at `unit` times the frame's own size for an 87 tile: the tile (1349:2784), and its questions.
    /// `lit`, each part of it is lost in light, as the documents gathered for the report are: white, with the light
    /// spilling round it. It comes out of that as it comes in.
    private func drawn(_ thing: Thing, lit: Bool) -> some View {
        let u = thing.unit
        let clearing = Animation.easeOut(duration: Self.clearing).delay(Self.leadIn + thing.sets + 0.1)
        let tile = RoundedRectangle(cornerRadius: 29 * u, style: .continuous)
        return ZStack(alignment: .topLeading) {
            ZStack {
                // Gap: #FEFEFE, unbound
                Color(hex: 0xFEFEFE)
                Image(thing.mark)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thing.markSize.width * u, height: thing.markSize.height * u)
                Color.white
                    .opacity(lit ? 1 : 0)
                    .animation(clearing, value: lit)
            }
            .frame(width: 87 * u, height: 87 * u)
            .clipShape(tile)
            .background {
                // (the many small ones come out of the light without it spilling: fifty more blurs for what, on
                // this ground, hardly shows)
                if !thing.small {
                    tile.fill(Color.white)
                        .padding(-Self.spill * u)
                        .blur(radius: Self.spill * 1.6 * u)
                        .opacity(lit ? 1 : 0)
                        .animation(clearing, value: lit)
                }
            }
            // Shadow/2 (0 4 97 +7 at 7%); SwiftUI can't draw the spread
            .shadow(color: Color.black.opacity(0.07), radius: 48.5 * u, x: 0, y: 4 * u)
            .at(thing.tileX * u, 0)

            ForEach(Array(thing.asks.enumerated()), id: \.offset) { index, ask in
                // 1349:2780: 252 × 57, the question from 21 in and cut off at the pill's end, as the frame has it
                // Gap: GT Walsheim Regular 17/23 has no text style
                GapText(ask, family: .walsheim, medium: false, size: 17 * u, lineHeight: 23 * u, color: Color.black)
                    .fixedSize()
                    .opacity(lit ? 0 : 1)
                    .animation(clearing, value: lit)
                    .padding(.leading, 21 * u)
                    .frame(width: 252 * u, height: 57 * u, alignment: .leading)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .background(
                        Capsule().fill(Color.white)
                            .padding(-Self.spill * u)
                            .blur(radius: Self.spill * 1.6 * u)
                            .opacity(lit ? 1 : 0)
                            .animation(clearing, value: lit)
                    )
                    // Gap: black at 5%, 2 across, unbound
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2 * u))
                    // 0 3 30 +8 at 3%; SwiftUI can't draw the spread
                    .shadow(color: Color.black.opacity(0.03), radius: 15 * u, x: 0, y: 3 * u)
                    .at(thing.askX * u, (thing.askY + 68 * CGFloat(index)) * u)
            }
        }
    }
}

/// The tick that takes the heading's place once the hold's been done (1251:6831), 72 across: the disc springs up
/// out of nothing, and then the tick is drawn through it, from its short stroke's start round to its long one's end.
/// The tick is the drawing's own, cut out of the disc; what forms it is a cover in the disc's colour laid along
/// it, which draws back.
struct DoneTick: View {
    /// Its disc: content/primary's near-black as the frames first had it (1251:6831)
    var tint = Color(hex: 0x282424)

    @State private var disc = false
    @State private var drawn: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Down the middle of the cut-out tick, and 5 on past each of its ends, which the cover's square ends clear
    private static let stroke = Path { path in
        path.move(to: CGPoint(x: 19.4, y: 34.7))
        path.addLine(to: CGPoint(x: 32.1, y: 49.8))
        path.addLine(to: CGPoint(x: 51.8, y: 19.5))
    }

    var body: some View {
        Image("V2HoldTick")
            .renderingMode(.template)
            .foregroundStyle(tint)
            .frame(width: 72, height: 72)
            .overlay {
                Self.stroke
                    .trim(from: drawn, to: 1)
                    // wider than the tick, so none of it shows until it's drawn
                    .stroke(tint, style: StrokeStyle(lineWidth: 10, lineCap: .butt, lineJoin: .round))
            }
            // one thing as it fades up, so the tick under its cover doesn't show through
            .compositingGroup()
            .scaleEffect(disc ? 1 : 0.4)
            .opacity(disc ? 1 : 0)
            .accessibilityElement()
            .accessibilityLabel("Done")
            .accessibilityAddTraits(.isImage)
            .onAppear {
                guard !reduceMotion else {
                    disc = true
                    drawn = 1
                    return
                }
                // after the heading's gone
                withAnimation(.spring(response: 0.45, dampingFraction: 0.68).delay(0.15)) { disc = true }
                withAnimation(.easeInOut(duration: 0.35).delay(0.35)) { drawn = 1 }
            }
    }
}

/// Her picture on its way from the pill to the head of the phone. The pill's round one and the portrait are one
/// drawing (the round one is its 97…298 across at 30 / 201), so it's the portrait throughout: cut round and at the
/// pill's size while it's down, and opened out to its own card and size as it goes up. The pill's own lies over it
/// while it's down, for the hair's breadth more that one shows at its rim, and fades as it leaves.
///
/// It takes no room; it's placed by the drawing's top left corner.
private struct AdvisorFlight: View {
    let up: Bool

    private static let small: CGFloat = 30.0 / 201
    private static let large: CGFloat = 59.346 / 186

    /// Where the drawing's corner is with the picture in the pill (the pill at 17, 337 on the screen's 15, 15; its
    /// picture's 30 at 34.825 + 1.475, 10.525 + 1.475 on that),
    static let pill = CGPoint(x: 15 + 17 + 34.825 + 1.475 - 97 * small, y: 15 + 337 + 10.525 + 1.475 - 93 * small)
    /// and with the portrait at the head of the phone (59.346 × 61.26 at 138, 17, the drawing's middle on its own)
    static let head = CGPoint(x: 138 + 59.346 / 2 - 197 * large, y: 17 + 61.26 / 2 - 200 * large)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("MeetAdvisorPortrait")
                .frame(width: 394, height: 400)
                .mask(alignment: .topLeading) {
                    // its own card (186 × 192 at 104, 100, cornered 73), or the round of the pill's
                    RoundedRectangle(cornerRadius: up ? 73 : 100.5)
                        .frame(width: up ? 186 : 201, height: up ? 192 : 201)
                        .at(up ? 104 : 97, up ? 100 : 93)
                }
            Image("PillAvatar")
                .frame(width: 32.9508, height: 32.9508)
                .scaleEffect(1 / Self.small, anchor: .topLeading)
                .frame(width: 0, height: 0, alignment: .topLeading)
                .at(97 - 1.475 / Self.small, 93 - 1.475 / Self.small)
                .opacity(up ? 0 : 1)
        }
        .frame(width: 394, height: 400, alignment: .topLeading)
        .scaleEffect(up ? Self.large : Self.small, anchor: .topLeading)
        .frame(width: 0, height: 0, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct InputRing: View {
    @State private var drawn: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far out from the pill's edge the line's middle runs: its 3 lie against the pill, 1 of them over the
    /// pill's own 0.7 of border, with nothing between the two
    private static let clear: CGFloat = 0.5

    /// Round a capsule, clockwise, from a point along its top edge
    private struct Round: Shape {
        /// How far along the top edge it starts
        let from: CGFloat

        func path(in rect: CGRect) -> Path {
            let radius = rect.height / 2
            let start = CGPoint(x: rect.minX + max(radius, from), y: rect.minY)
            var path = Path()
            path.move(to: start)
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.midY), radius: radius,
                        startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.midY), radius: radius,
                        startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
            path.addLine(to: start)
            return path
        }
    }

    var body: some View {
        // the arrow's own colours, top to bottom (1267:13002)
        LinearGradient(colors: [Color(hex: 0xF7BD89), Color(hex: 0xFFCA4B)], startPoint: .top, endPoint: .bottom)
            .mask {
                // the arrow came down onto the pill 55 along it
                Round(from: 55 + Self.clear)
                    .trim(from: 0, to: drawn)
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .padding(1.5)
            }
            .padding(-Self.clear - 1.5)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                guard !reduceMotion else { return drawn = 1 }
                try? await Task.sleep(for: .seconds(0.12))
                withAnimation(.easeInOut(duration: 0.8)) { drawn = 1 }
            }
    }
}

/// The line from a hint to what it points at (1267:13002, 1267:13005): 3 thick, round a corner of 12, ending in an
/// arrowhead. It isn't there when its frame arrives; once what it points at has settled it runs out from the words'
/// end along its path, and the arrowhead opens at its tip as it gets there.
private struct DrawnArrow: View {
    let size: CGSize
    /// From the words' end to the tip
    let shaft: Path
    let tip: CGPoint
    /// Top to bottom across its frame
    let stops: [Gradient.Stop]

    @State private var line: CGFloat = 0
    @State private var head: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far each side of the arrowhead reaches back from the tip, across and up
    private static let reach: CGFloat = 9.546

    /// "Tap to try!" down to the pill (1267:13002), 93.046 × 89: down from under the words, round to the left, and down
    static let tryIt = DrawnArrow(
        size: CGSize(width: 93.046, height: 89),
        shaft: Path { path in
            path.move(to: CGPoint(x: 91.546, y: 0))
            path.addLine(to: CGPoint(x: 91.546, y: 43))
            path.addArc(tangent1End: CGPoint(x: 91.546, y: 55), tangent2End: CGPoint(x: 79.546, y: 55), radius: 12)
            path.addLine(to: CGPoint(x: 23.046, y: 55))
            path.addArc(tangent1End: CGPoint(x: 11.046, y: 55), tangent2End: CGPoint(x: 11.046, y: 67), radius: 12)
            path.addLine(to: CGPoint(x: 11.046, y: 87.5))
        },
        tip: CGPoint(x: 11.046, y: 87.5),
        stops: [.init(color: Color(hex: 0xF7BD89), location: 0), .init(color: Color(hex: 0xFFCA4B), location: 87.5 / 89)]
    )

    /// "Select any topic" down to the prompts (1267:13005, which the frame mirrors), 101.046 × 133.5: out to the
    /// right from the words, round, and down
    static let topic = DrawnArrow(
        size: CGSize(width: 101.046, height: 133.5),
        shaft: Path { path in
            path.move(to: CGPoint(x: 0, y: 1.5))
            path.addLine(to: CGPoint(x: 78, y: 1.5))
            path.addArc(tangent1End: CGPoint(x: 90, y: 1.5), tangent2End: CGPoint(x: 90, y: 13.5), radius: 12)
            path.addLine(to: CGPoint(x: 90, y: 132))
        },
        tip: CGPoint(x: 90, y: 132),
        stops: [.init(color: Color(hex: 0xB4BAD1), location: 19 / 133.5), .init(color: Color(hex: 0xCFBAB5), location: 132 / 133.5)]
    )

    private func side(_ direction: CGFloat) -> Path {
        Path { path in
            path.move(to: tip)
            path.addLine(to: CGPoint(x: tip.x + Self.reach * direction, y: tip.y - Self.reach))
        }
    }

    var body: some View {
        LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
            .mask {
                ZStack {
                    shaft.trim(from: 0, to: line)
                        .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .butt, lineJoin: .round))
                    side(-1).trim(from: 0, to: head)
                        .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    side(1).trim(from: 0, to: head)
                        .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
            }
            .frame(width: size.width, height: size.height)
            .accessibilityHidden(true)
            .task {
                guard !reduceMotion else { return (line, head) = (1, 1) }
                // after the words it runs from
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.7)) { line = 1 }
                try? await Task.sleep(for: .seconds(0.62))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.25)) { head = 1 }
            }
    }
}

/// A rounded rectangle with an outline along its top and sides and none along its foot, as the frames draw the
/// phones (a border on three sides): the line thins away round the bottom corners. With `line` 0 it's the whole
/// shape, for the fill; otherwise the band between it and the shape inside, to be filled even-odd.
struct OpenFrame: Shape {
    let radius: CGFloat
    let line: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: radius, style: .continuous)
        guard line > 0 else { return path }
        // Inside: in by the line at the top and sides and flush with the foot, its bottom corners stretched to meet it
        let inner = CGRect(x: rect.minX + line, y: rect.minY + line, width: rect.width - line * 2, height: rect.height - line)
        let r = radius - line
        // How far a quarter-circle's control points sit from its ends
        let k: CGFloat = 0.5523
        path.move(to: CGPoint(x: inner.minX + r, y: inner.minY))
        path.addLine(to: CGPoint(x: inner.maxX - r, y: inner.minY))
        path.addCurve(to: CGPoint(x: inner.maxX, y: inner.minY + r),
                      control1: CGPoint(x: inner.maxX - r * (1 - k), y: inner.minY),
                      control2: CGPoint(x: inner.maxX, y: inner.minY + r * (1 - k)))
        path.addLine(to: CGPoint(x: inner.maxX, y: inner.maxY - radius))
        path.addCurve(to: CGPoint(x: inner.maxX - r, y: inner.maxY),
                      control1: CGPoint(x: inner.maxX, y: inner.maxY - radius * (1 - k)),
                      control2: CGPoint(x: inner.maxX - r * (1 - k), y: inner.maxY))
        path.addLine(to: CGPoint(x: inner.minX + r, y: inner.maxY))
        path.addCurve(to: CGPoint(x: inner.minX, y: inner.maxY - radius),
                      control1: CGPoint(x: inner.minX + r * (1 - k), y: inner.maxY),
                      control2: CGPoint(x: inner.minX, y: inner.maxY - radius * (1 - k)))
        path.addLine(to: CGPoint(x: inner.minX, y: inner.minY + r))
        path.addCurve(to: CGPoint(x: inner.minX + r, y: inner.minY),
                      control1: CGPoint(x: inner.minX, y: inner.minY + r * (1 - k)),
                      control2: CGPoint(x: inner.minX + r * (1 - k), y: inner.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    OnboardingWelcomeV2View(onContinue: {})
}
