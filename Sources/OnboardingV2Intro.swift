import SwiftUI

/// The second onboarding's way in, before its opening: four frames of 390 × 840 on the advisor's ground.
///
/// - "Personal wealth advisor for life decisions" (1341:1275): the head of a phone with her picture on it and a
///   conversation with her about money going on under that, and over its foot the Decade mark, the heading, a
///   line about it, Agree & Continue and a link to the terms.
/// - "Add your mobile number" (1362:6812): under the status bar's rule, the heading, a card with the number
///   being typed, and Continue; the number pad is up.
/// - "Enter one time password" (1362:6984): the same, the card with the number it was sent to (and a way back to
///   change it) over the code being typed.
/// - "Verify your KYC details" (1362:7246): once the code's been confirmed this comes up over that, ground and
///   all. In its card the PAN card is looked up with the first onboarding's reveal, made of lines: lines run
///   down the box, slowing and spreading, then unfurl into a ruled field and resolve top to bottom into the card
///   (in place of the frame's name, PAN and date of birth fields); Gender comes in under it and Continue wakes. Continue confirms them: a green tick stands where the
///   heading was (1362:7450), and after a moment it goes on.
///
/// The first onboarding's own intro is kept where it was, and `-onboardingIntroV1` puts it back here.
struct OnboardingIntroV2View: View {
    let onContinue: () -> Void

    enum Stage: Int, Comparable {
        case welcome, mobile, otp, kyc

        static func < (a: Stage, b: Stage) -> Bool { a.rawValue < b.rawValue }

        var heading: String? {
            switch self {
            case .welcome: nil
            case .mobile: "Add your mobile number"
            case .otp: "Enter one time password"
            case .kyc: "Verify your KYC details"
            }
        }
    }

    @State private var stage = OnboardingIntroV2View.startStage
    @State private var number = OnboardingIntroV2View.startStage > .mobile ? "9871167820" : ""
    @State private var code = ""
    @State private var gender = "Male"
    @State private var showsTerms = false
    /// The details have been confirmed: a tick stands where their heading was, and it goes on
    @State private var verified = false
    /// The PAN card has been found: it's there in full, Gender is under it and Continue wakes. `-onboardingPAN` opens
    /// on it; `-onboardingIdentity` opens on the KYC card while it's still being looked up.
    @State private var found = ProcessInfo.processInfo.arguments.contains("-onboardingPAN")
    /// When the KYC card came up; the lookup's reveal runs from here
    @State private var lookupStart = Date.now
    @Environment(\.onboardingTop) private var top
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// `-onboardingPhone`, `-onboardingOTP` and `-onboardingPAN` (or `-onboardingIdentity`) open on the frames
    /// after the first, as they do in the first onboarding
    private static var startStage: Stage {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-onboardingPAN") || args.contains("-onboardingIdentity") { return .kyc }
        if args.contains("-onboardingOTP") { return .otp }
        if args.contains("-onboardingPhone") { return .mobile }
        return .welcome
    }

    private static let move = Animation.spring(response: 0.6, dampingFraction: 0.84)
    private static let outline = Color(hex: 0xC6C6C6)
    private static let line = Color(red: 194 / 255, green: 194 / 255, blue: 194 / 255).opacity(0.33)
    private static let ink = Color(hex: 0x212121)
    /// A card coming in under its heading, and going as the next one's comes
    private static let card = AnyTransition.asymmetric(
        insertion: .offset(y: 36).combined(with: .opacity).animation(move.delay(0.2)),
        removal: .scale(scale: 0.96).combined(with: .opacity).animation(.easeIn(duration: 0.22))
    )

    var body: some View {
        // Laid out on the frame's 390, centred on the screen; its 44 of status bar is the device's own
        let screen = UIScreen.main.bounds.width
        let side = (screen - 390) / 2
        return ZStack(alignment: .topLeading) {
            if stage == .welcome {
                welcome(side: side, screen: screen)
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity.animation(.easeIn(duration: 0.3))))
            }

            if stage >= .mobile {
                // 1362:6866
                Color.black.opacity(0.57)
                    .frame(width: 372, height: 1)
                    .at(side + 9, 48 - 44 + top)
                    .accessibilityHidden(true)
                    .transition(.opacity.animation(.easeOut(duration: 0.4).delay(0.2)))
            }

            if stage == .mobile || stage == .otp, let heading = stage.heading {
                self.heading(heading, side: side)
            }
            if stage == .mobile {
                mobileCard
                    .at(side + 17, 212 - 44 + top)
                    .transition(Self.card)
            }
            if stage == .otp {
                otpCard
                    .at(side + 17, 204 - 44 + top)
                    .transition(Self.card)
            }
            if stage == .mobile || stage == .otp {
                // 1362:6822, 1362:6994
                OnboardingConfirmButton(enabled: stage == .mobile ? number.count == 10 : code.count == 6, action: next)
                    .at(side + 23, 437 - 44 + top)
                    .transition(.asymmetric(
                        insertion: .offset(y: 20).combined(with: .opacity).animation(Self.move.delay(0.3)),
                        removal: .opacity.animation(.easeIn(duration: 0.2))
                    ))
            }

            if stage == .kyc {
                // Over all of that, ground and all, from the foot of the screen
                kyc(side: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(AdvisorDawnBackground().ignoresSafeArea())
                    .transition(.asymmetric(insertion: .move(edge: .bottom).animation(.spring(response: 0.55, dampingFraction: 0.9)),
                                            removal: .opacity))
                    .zIndex(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AdvisorDawnBackground().ignoresSafeArea())
        .overlay {
            if showsTerms {
                OnboardingTermsSheet(top: top + 16) {
                    withAnimation(.spring(duration: 0.45, bounce: 0.12)) { showsTerms = false }
                }
            }
        }
        .preferredColorScheme(.light)
        .ignoresSafeArea()
    }

    private func next() {
        Haptics.tap()
        switch stage {
        case .welcome:
            withAnimation(Self.move) { stage = .mobile }
        case .mobile:
            withAnimation(Self.move) { stage = .otp }
        case .otp:
            // The pad goes down as the details come up over it
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            lookupStart = .now
            withAnimation(Self.move) { stage = .kyc }
        case .kyc:
            // 1362:7450: confirmed. The tick, a moment to see it, and on
            guard !verified else { return }
            withAnimation(Self.move) { verified = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { onContinue() }
        }
    }

    /// 1362:6819: GT Walsheim Medium 35/39, centred on 352, broken where the frames break it (after its third word)
    private func heading(_ words: String, side: CGFloat) -> some View {
        let parts = words.split(separator: " ")
        let lines = parts.prefix(3).joined(separator: " ") + "\n" + parts.dropFirst(3).joined(separator: " ")
        // Gap: GT Walsheim Medium 35/39 has no text style; the colour is content/primary
        return GapText(lines, family: .walsheim, medium: true, size: 35, lineHeight: 39, color: ColorScale.contentPrimary)
            .multilineTextAlignment(.center)
            .frame(width: 352)
            .at(side + 19, 80 - 44 + top)
            .accessibilityLabel(words)
            .accessibilityAddTraits(.isHeader)
            .id(words)
            .transition(OnboardingWelcomeV2View.words)
    }

    // MARK: - Welcome (1341:1275)

    private func welcome(side: CGFloat, screen: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // 1341:1672: the head of a phone, 302 across, cut off where the page comes over it
            phone
                .frame(width: 302, height: 390 - 63.8, alignment: .topLeading)
                .clipped()
                .at(side + 44, 63.8 - 44 + top)
                .accessibilityHidden(true)

            // 1341:1403: the page over its foot, white at 69% (the frame blurs what's behind it right out)
            Color.white.opacity(0.69)
                .frame(width: screen)
                .padding(.top, 390 - 44 + top)
                .accessibilityHidden(true)

            // 1341:1761: the mark and "Decade"
            Image("DecadeMarkPlum")
                .renderingMode(.template)
                .resizable()
                // Gap: #33302D, unbound
                .foregroundStyle(Color(hex: 0x33302D))
                .frame(width: 19.606, height: 19.606)
                .at(side + 138, 405.115 - 44 + top)
                .accessibilityHidden(true)
            // Gap: GT Super Text Medium 25.999/28.983, tracking -1%, drawn at 45 and scaled as the first onboarding's is
            Text("Decade")
                .font(FigmaFont.superMedium(45))
                .tracking(-0.45)
                .foregroundStyle(Color(hex: 0x33302D))
                .fixedSize()
                .frame(height: 46)
                .scaleEffect(25.999 / 45, anchor: .topLeading)
                .frame(width: 88, height: 29, alignment: .topLeading)
                .at(side + 163.147, 401.2 - 44 + top)

            // Gap: Reckless Medium 45/51 in #33302D has no text style or content token
            GapText("Personal wealth advisor for life decisions", family: .reckless, medium: true, size: 45, lineHeight: 51, color: Color(hex: 0x33302D))
                .multilineTextAlignment(.center)
                .frame(width: 352)
                .at(side + 19, 443 - 44 + top)
                .accessibilityAddTraits(.isHeader)
            // Gap: GT Walsheim Regular 17/23 has no text style here; the colour is content/secondary
            GapText("Thoughtful wealth management for people who’ve outgrown generic advice.", family: .walsheim, medium: false, size: 17, lineHeight: 23, color: ColorScale.contentSecondary)
                .multilineTextAlignment(.center)
                .frame(width: 347)
                .at(side + 21, 613 - 44 + top)

            // 1341:1285
            OnboardingConfirmButton(title: "Agree & Continue", action: next)
                .at(side + 23, 690 - 44 + top)

            // 1341:1395: 229 × 21
            Button {
                Haptics.tap()
                withAnimation(.spring(duration: 0.5, bounce: 0.18)) { showsTerms = true }
            } label: {
                ZStack(alignment: .topLeading) {
                    // Gap: Rg 15/21 in black 70% has no text style or content token
                    GapText("Read the terms and conditions", family: .walsheim, medium: false, size: 15, lineHeight: 21, color: Color.black.opacity(0.7))
                        .fixedSize()
                    Image("OnboardingTermsChevron")
                        .frame(width: 21, height: 21)
                        .at(208, 0)
                }
                .frame(width: 229, height: 21, alignment: .topLeading)
                .contentShape(Rectangle().inset(by: -12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Read the terms and conditions")
            .at(side + 80, 766 - 44 + top)
        }
    }

    /// 1341:1672, 302 × 529.399: the phone the opening draws, a little smaller: its outline, its screen 10.786 in,
    /// its island, and her picture under that
    private var phone: some View {
        ZStack(alignment: .topLeading) {
            OpenFrame(radius: 53.03, line: 1.798).fill(Self.outline, style: FillStyle(eoFill: true))
            ZStack {
                OpenFrame(radius: 44.042, line: 0).fill(Color.white)
                OpenFrame(radius: 44.042, line: 2.696).fill(Self.outline, style: FillStyle(eoFill: true))
            }
            .frame(width: 280.429, height: 518.613)
            .at(10.786, 10.786)
            // 1341:1676: surface/base on it
            Color(hex: 0xFCFCFA)
                .frame(width: 275.036, height: 513.22)
                .clipShape(RoundedRectangle(cornerRadius: 41.345, style: .continuous))
                .at(13.482, 13.482)
            // On its screen under her picture, a conversation with her going on (not in the frame, which has the
            // screen bare): the app's own chat at the screen's 280.429 for the app's 390, down to where the page
            // comes over the phone
            IntroChat()
                .at(10.786, 118)
            // 1341:1698: 53.34 × 55.061
            Image("MeetAdvisorPortrait")
                .frame(width: 394, height: 400)
                .scaleEffect(53.34 / 186)
                .frame(width: 53.34, height: 55.061)
                .at(13.482 + 110.554, 13.482 + 42.244)
            // 1341:1759
            Capsule().fill(Color.black)
                .frame(width: 79.994, height: 23.369)
                .at(111.452, 22.47)
        }
        .frame(width: 302, height: 529.399, alignment: .topLeading)
    }

    /// A conversation about money, going on by itself on the welcome's phone: the app's own chat bubbles
    /// (`ChatBubble`, `TypingBubble`) at the phone's scale. A question goes in, she's seen to be typing, her answer
    /// comes, and on to the next; the earlier ones go up and fade out under her picture, and after the last it
    /// starts again. With Reduce Motion the first question and its answer are simply there.
    private struct IntroChat: View {
        private struct Line: Identifiable {
            let id: Int
            let message: ChatMessage
        }

        @State private var lines: [Line] = []
        @State private var typing = false
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        /// The phone's screen for the app's 390
        private static let scale: CGFloat = 280.429 / 390
        /// What shows of the screen from where it starts, under her picture, to where the page comes over it
        private static let showing: CGFloat = 326.2 - 118 - 6
        /// What's asked, and what she says to it
        private static let script: [(ask: String, answer: String)] = [
            ("Should I keep my SIP going while the market is down?", "Yes. A dip is when your SIP buys more units for the same amount."),
            ("How much should I keep as an emergency fund?", "About six months of expenses, somewhere you can reach it the same day."),
            ("Am I too heavy on small caps?", "They’re 40% of your equity. I’d bring that nearer 20% over a few months."),
            ("Index fund or active fund for large caps?", "For large caps a low-cost index fund has been hard to beat."),
            ("Two of my funds look the same to me.", "They are: they hold 61% of the same stocks. One of them is enough."),
            ("Can I still save tax this year?", "You have room left under 80C. An ELSS SIP would use it."),
        ]

        var body: some View {
            VStack(spacing: 14) {
                ForEach(lines) { line in
                    ChatBubble(message: line.message, showsRead: false)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.86, anchor: line.message.fromAgent ? .bottomLeading : .bottomTrailing)
                                .combined(with: .opacity).combined(with: .offset(y: 16)),
                            removal: .opacity
                        ))
                }
                if typing {
                    TypingBubble()
                        .transition(.asymmetric(insertion: .scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity),
                                                removal: .opacity.animation(.easeIn(duration: 0.12))))
                }
            }
            .padding(.bottom, 14)
            .frame(width: 390, height: Self.showing / Self.scale, alignment: .bottom)
            // Fading out towards her picture
            .mask(LinearGradient(stops: [.init(color: .black.opacity(0), location: 0), .init(color: .black, location: 0.28),
                                         .init(color: .black, location: 1)], startPoint: .top, endPoint: .bottom))
            .scaleEffect(Self.scale, anchor: .topLeading)
            .frame(width: 280.429, height: Self.showing, alignment: .topLeading)
            .allowsHitTesting(false)
            .task {
                func line(_ index: Int, _ text: String, fromAgent: Bool) -> Line {
                    Line(id: index, message: ChatMessage(text: text, fromAgent: fromAgent))
                }
                guard !reduceMotion else {
                    lines = [line(0, Self.script[0].ask, fromAgent: false), line(1, Self.script[0].answer, fromAgent: true)]
                    return
                }
                let landing = Animation.spring(response: 0.5, dampingFraction: 0.82)
                var said = 0
                do {
                    try await Task.sleep(for: .seconds(0.7))
                    while true {
                        let turn = Self.script[(said / 2) % Self.script.count]
                        withAnimation(landing) {
                            lines.append(line(said, turn.ask, fromAgent: false))
                            lines = Array(lines.suffix(5))
                        }
                        try await Task.sleep(for: .seconds(0.9))
                        withAnimation(landing) { typing = true }
                        try await Task.sleep(for: .seconds(1.3))
                        withAnimation(landing) {
                            typing = false
                            lines.append(line(said + 1, turn.answer, fromAgent: true))
                            lines = Array(lines.suffix(5))
                        }
                        said += 2
                        try await Task.sleep(for: .seconds(2.4))
                    }
                } catch {}
            }
        }
    }

    // MARK: - Mobile number (1362:6825), 356 × 191

    private var mobileCard: some View {
        ZStack(alignment: .topLeading) {
            // Gap: GT Walsheim Medium 17/23 on content/primary
            GapText("Add your mobile number", family: .walsheim, medium: true, size: 17, lineHeight: 23, color: ColorScale.contentPrimary)
                .fixedSize()
                .at(17, 17)
                .accessibilityHidden(true)

            // 1362:6924
            ZStack(alignment: .topLeading) {
                // Gap: GT Walsheim Regular 35/48, tracking 7%, has no text style; the colour is content/tertiary
                GapText("+91", family: .walsheim, medium: false, size: 35, lineHeight: 48, trackingPercent: 7, color: ColorScale.contentTertiary)
                    .fixedSize()
                    .at(12, 11)
                PhoneNumberField(number: $number)
                    .frame(width: 245, height: 48)
                    .at(77, 11)
                    .accessibilityLabel("Mobile number")
                Self.line.frame(width: 329, height: 1).at(0, 67)
                // Gap: Rg 13/17 in #212121 at 47%
                GapText("We will send the confirmation on your mobile to confirm it.", family: .walsheim, medium: false, size: 13, lineHeight: 17, color: Self.ink.opacity(0.47))
                    .frame(width: 286, alignment: .leading)
                    .at(13, 74)
            }
            .frame(width: 330, height: 117, alignment: .topLeading)
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(Self.line, lineWidth: 1))
            .at(13, 57)
        }
        .frame(width: 356, height: 191, alignment: .topLeading)
        .modifier(Carded())
    }

    // MARK: - One-time password (1362:6996), 356 × 199

    private var otpCard: some View {
        ZStack(alignment: .topLeading) {
            // 1362:7237: the number it went to
            Image("PhoneGlyph")
                .frame(width: 21, height: 21)
                .at(17, 22)
                .accessibilityHidden(true)
            // Gap: Rg 17/25, tracking 3%, in #212121 at 93%
            GapText(number.isEmpty ? "9871167820" : number, family: .walsheim, medium: false, size: 17, lineHeight: 25, trackingPercent: 3, color: Self.ink.opacity(0.93))
                .fixedSize()
                .at(41.5, 20)

            // 1362:7242: 123 × 31, back to the number
            Button {
                Haptics.tap()
                code = ""
                withAnimation(Self.move) { stage = .mobile }
            } label: {
                ZStack(alignment: .topLeading) {
                    // Gap: Rg 13/21 in #212121 at 93%, on #F5F5F5
                    GapText("Change number", family: .walsheim, medium: false, size: 13, lineHeight: 21, color: Self.ink.opacity(0.93))
                        .fixedSize()
                        .at(7, 5)
                    Image("EditPencil").frame(width: 9, height: 9).at(107, 11)
                }
                .frame(width: 123, height: 31, alignment: .topLeading)
                .background(Capsule().fill(Color(hex: 0xF5F5F5)))
            }
            .buttonStyle(PressScaleStyle())
            .accessibilityLabel("Change number")
            .at(215.5, 17)

            // 1362:7227
            ZStack(alignment: .topLeading) {
                OneTimeCodeField(code: $code)
                    .frame(width: 330, height: 67)
                    .accessibilityLabel("One time password")
                codeText
                    .frame(width: 330, height: 48)
                    .at(0, 11)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                Self.line.frame(width: 316, height: 1).at(1, 68)
                HStack(spacing: 3) {
                    // Gap: Rg 13/17 in #1DB124
                    GapText("Confirmation OTP sent", family: .walsheim, medium: false, size: 13, lineHeight: 17, color: Color(hex: 0x1DB124))
                        .fixedSize()
                    Image("V2OtpSentCheck").frame(width: 17, height: 17)
                }
                .at(89, 79)
            }
            .frame(width: 330, height: 107, alignment: .topLeading)
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(Self.line, lineWidth: 1))
            .at(13, 75)
        }
        .frame(width: 356, height: 199, alignment: .topLeading)
        .modifier(Carded())
    }

    /// The code as far as it's been typed, three and three: what's in is content/primary, the noughts standing in
    /// for the rest are content/disabled, as the frame has all six
    private var codeText: some View {
        let typed = Array(code)
        func part(_ range: Range<Int>) -> Text {
            range.reduce(Text("")) { text, i in
                text + Text(i < typed.count ? String(typed[i]) : "0")
                    .foregroundColor(i < typed.count ? ColorScale.contentPrimary : ColorScale.contentDisabled)
            }
        }
        // Gap: GT Walsheim Medium 35/48, tracking 23%, has no text style
        return (part(0..<3) + Text("-").foregroundColor(typed.count > 3 ? ColorScale.contentPrimary : ColorScale.contentDisabled) + part(3..<6))
            .font(FigmaFont.walsheimMedium(35))
            .tracking(8.05)
            .frame(maxWidth: .infinity)
    }

    // MARK: - KYC (1362:7246)

    private func kyc(side: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.57)
                .frame(width: 372, height: 1)
                .at(side + 9, 48 - 44 + top)
                .accessibilityHidden(true)
            if verified {
                // 1362:7536: in #3FD519, where the heading was
                DoneTick(tint: Color(hex: 0x3FD519))
                    .at(side + 159, 83 - 44 + top)
            } else {
                heading("Verify your KYC details", side: side)
            }

            // The frame's card (1362:7379), with the PAN card being looked up where its name, PAN and date of birth
            // were; once it's found, Gender comes in under it and the card grows to hold it
            ZStack(alignment: .topLeading) {
                // Gap: GT Walsheim Medium 17/23 on content/primary, as the frame's field names
                GapText("Your PAN card", family: .walsheim, medium: true, size: 17, lineHeight: 23, color: ColorScale.contentPrimary)
                    .fixedSize()
                    .at(13, 17)
                    .accessibilityHidden(true)
                panLookup
                    .at(13, Self.panTop)
                if found {
                    // 1362:7429: outlined in border/default, and it opens
                    Menu {
                        ForEach(["Female", "Male", "Other"], id: \.self) { option in
                            Button(option) { gender = option }
                        }
                    } label: {
                        field("Gender", height: 55, border: ColorScale.borderDefault) {
                            value(gender)
                            Image("GenderChevron").frame(width: 25, height: 25).at(292, 15)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Gender")
                    .accessibilityValue(gender)
                    .at(13, Self.genderTop)
                    .transition(.offset(y: 14).combined(with: .opacity).animation(Self.move.delay(0.15)))
                }
            }
            .frame(width: 356, height: found ? Self.genderTop + 91 + 17 : Self.panTop + Self.panHeight + 17, alignment: .topLeading)
            .modifier(Carded())
            .at(side + 17, 189 - 44 + top)

            // 1362:7256: wakes once the card's been found
            OnboardingConfirmButton(enabled: found, action: next)
                .at(side + 23, 730 - 44 + top)
        }
    }

    // MARK: - PAN lookup (the first onboarding's, 44:3351 and 930:10749, in this card)

    /// Where the PAN card's box sits in the KYC card, and how tall it is at the card's 330 across
    private static let panTop: CGFloat = 53
    private static let panHeight: CGFloat = 255 * 330 / 364
    private static let genderTop: CGFloat = panTop + panHeight + 22

    /// The box the PAN card is looked up in: lines running down it, which unfurl into a ruled field over the box and
    /// resolve, top to bottom, into the card that was found (`LinesToCardReveal`), then the card itself. Drawn at
    /// the card's own 364 × 255 and set into the KYC card at 330 across, in the box its fields have.
    private var panLookup: some View {
        let scale: CGFloat = 364 / 330
        let shape = RoundedRectangle(cornerRadius: 15 * scale, style: .continuous)
        return ZStack(alignment: .topLeading) {
            // Swapped outright: the reveal's last frame is already the finished card
            if found {
                FoundPanCard()
                    .transition(.identity)
            } else {
                LinesToCardReveal(start: lookupStart) { FoundPanCard() }
                    .transition(.identity)
            }
        }
        .frame(width: 364, height: 255, alignment: .topLeading)
        .clipShape(shape)
        .modifier(RevealBump(start: lookupStart, active: !found))
        .overlay(shape.strokeBorder(Self.line, lineWidth: scale))
        .scaleEffect(1 / scale, anchor: .topLeading)
        .frame(width: 330, height: Self.panHeight, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(found ? "PAN card. VANGIPURAPPU VENKATA, ABCDE8283D, born 15/08/1999" : "Finding your PAN card")
        .task {
            guard !found else { return }
            if !reduceMotion {
                let left = LinesToCardReveal.endsAt - Date().timeIntervalSince(lookupStart)
                try? await Task.sleep(for: .seconds(max(0, left)))
                guard !Task.isCancelled else { return }
            }
            withAnimation(.easeInOut(duration: 0.45)) { found = true }
        }
    }

    /// The PAN card's lookup, with the first onboarding's reveal (`SphereToCardReveal`) and its timings, made of
    /// lines in place of the sphere's particles. Lines run down the box from its top, one after another: the first
    /// come quickly and close together, and as it goes on they slow and come further and further apart. 1.9 seconds
    /// in they unfurl: each line opens out into several, which go to their own rows of an even field of ruled lines
    /// covering the card, top rows first. Right behind that a front runs down the card: where it passes each line
    /// settles into the surface and the card shows through in the strips between them, until the whole card is
    /// there. The same ticks as it sweeps, and the same swell under it.
    /// Times are seconds after `start`, when the KYC card came up; drawn in the card's 364 × 255.
    private struct LinesToCardReveal: View {
        let start: Date
        private let card: AnyView

        init<Card: View>(start: Date, @ViewBuilder card: () -> Card) {
            self.start = start
            self.card = AnyView(card())
        }

        // The sphere's own times
        private static var growAt: Double { SphereToCardReveal.growAt }
        private static let growFor = 1.0
        private static let flattenAt = growAt + 0.2
        private static let flattenFor = 1.0
        private static let flattenStagger = 0.55
        private static let revealAt = growAt + 1.05
        private static let revealFor = 2.4 / 1.7
        static var endsAt: Double { SphereToCardReveal.endsAt }
        private static let frontScatter = 30.0
        private static let frontSoftness = 18.0

        private static let size = CGSize(width: 364, height: 255)
        /// The rows of the field the lines unfurl into
        private static let count = 46
        /// How fast the lines run down, in points a second: at first, and by the time they unfurl
        private static let fastest = 430.0, slowest = 45.0
        /// How far behind the first line each one comes: 8 pt at first, and 0.42 more with each line
        private static let gap = 8.0, widening = 0.21
        /// How ragged the front is from one row to the next, 0 to 1 each
        private static let lag: [Double] = {
            var random = SeededRandom(state: 0x11E5_C0DE)
            return (0..<count).map { _ in random.next() }
        }()

        var body: some View {
            TimelineView(.animation) { context in
                let e = context.date.timeIntervalSince(start)
                let front = Self.front(e)
                ZStack(alignment: .topLeading) {
                    // The light ground behind it (930:10749)
                    SphereToCardReveal.backdrop
                    if e > Self.revealAt {
                        card
                            .mask(Canvas { ctx, _ in Self.drawMask(in: &ctx, front: front) })
                    }
                    Canvas(rendersAsynchronously: true) { ctx, _ in
                        Self.drawLines(in: &ctx, e: e, front: front)
                    }
                }
                .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
            }
            .task { await playSweepHaptics() }
        }

        /// As the sphere's: a fine run of soft ticks while the front sweeps down, one for each band of the card it
        /// crosses, then one firmer tap once the card is all there
        private func playSweepHaptics() async {
            let band = 9.0
            var lastBand = -1
            var random = SeededRandom(state: 0xB0B)
            Haptics.prepare()
            while !Task.isCancelled {
                let e = Date().timeIntervalSince(start)
                if e >= Self.endsAt - 0.1 {
                    if lastBand >= 0 { Haptics.revealSettled() }
                    return
                }
                let front = Self.front(e)
                if front >= 0, front <= Self.size.height {
                    let current = Int(front / band)
                    if current > lastBand {
                        lastBand = current
                        let fade = 1 - 0.4 * front / Self.size.height
                        Haptics.revealGrain(intensity: (0.32 + 0.18 * random.next()) * fade)
                    }
                }
                try? await Task.sleep(for: .milliseconds(8))
            }
        }

        /// The reveal front's height on the card: from above the top edge to past the bottom
        private static func front(_ e: Double) -> Double {
            let p = max(0, min(1, (e - revealAt) / revealFor))
            let eased = 1 - (1 - p) * (1 - p)
            return -frontScatter - frontSoftness + eased * (size.height + 2 * (frontScatter + frontSoftness))
        }

        /// How far past a point the front has gone, 0…1
        private static func passed(_ y: Double, lag: Double, front: Double) -> Double {
            max(0, min(1, (front - y - lag * frontScatter) / frontSoftness))
        }

        private static func ease(_ x: Double) -> Double {
            let p = max(0, min(1, x))
            return p * p * (3 - 2 * p)
        }

        /// How far the first line has run by `e`: quickly at first, slowing all the way to when they unfurl, and
        /// drifting on at that after
        private static func run(_ e: Double) -> Double {
            let t = max(0, min(e, flattenAt))
            let left = 1 - t / flattenAt
            // v = slowest + (fastest - slowest) × left², summed
            return slowest * max(0, e) + (fastest - slowest) * flattenAt / 3 * (1 - left * left * left)
        }

        /// How far behind the first line the `k`th comes
        private static func behind(_ k: Int) -> Double {
            gap * Double(k) + widening * Double(k * k)
        }

        /// The lines in the box when they unfurl, from the top one down
        private static let unfurling: [Int] = {
            let ran = run(flattenAt)
            return (0..<400).filter { behind($0) <= ran && ran - behind($0) <= Double(size.height) }.reversed()
        }()

        /// The card in the strips between the rows, each showing as the front passes it
        private static func drawMask(in ctx: inout GraphicsContext, front: Double) {
            let strip = Double(size.height) / Double(count)
            for i in 0..<count {
                let y = Double(i) * strip
                let amount = passed(y + strip / 2, lag: lag[i] * 0.5, front: front)
                guard amount > 0 else { break }
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: strip + 0.5)), with: .color(Color.black.opacity(amount)))
            }
        }

        private static func drawLines(in ctx: inout GraphicsContext, e: Double, front: Double) {
            let ran = run(e)
            let height = Double(size.height)
            let line = StrokeStyle(lineWidth: 1, lineCap: .butt)
            /// A line's ink where it is in the box: coming in at the top, going out at the bottom
            func ink(_ y: Double) -> Double { 0.86 * ease(y / 14) * ease((height - y) / 22) }
            func stroke(_ y: Double, _ opacity: Double) {
                guard opacity > 0.01 else { return }
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(path, with: .color(Color.black.opacity(opacity)), style: line)
            }

            // Running down: every line there's been, wherever it's in the box. Those in it when they unfurl are
            // drawn below, as the rows they open into
            if e < flattenAt {
                var k = 0
                while behind(k) <= ran {
                    let y = ran - behind(k)
                    if y <= height { stroke(y, ink(y)) }
                    k += 1
                }
                return
            }

            // Unfurled: each row comes out of the line it's shared out to, in order down the box, top rows first
            let lines = unfurling
            guard !lines.isEmpty else { return }
            var drawn = -1
            for row in 0..<count {
                let home = (Double(row) + 0.5) * height / Double(count)
                let gone = passed(home, lag: lag[row] * 0.5, front: front)
                guard gone < 1 else { continue }
                let share = min(lines.count - 1, row * lines.count / count)
                let from = ran - behind(lines[share])
                let flat = ease((e - flattenAt - flattenStagger * home / height) / flattenFor)
                // Until a line opens out it's one line, not as many as its rows
                if flat <= 0 {
                    guard share != drawn else { continue }
                    drawn = share
                }
                let y = from + (home - from) * flat
                let still = from <= height ? ink(from) : 0
                // As it opens its rows lie on one another: each is as much lighter as together they're the one line
                let each = flat > 0 ? 1 - pow(1 - still, Double(lines.count) / Double(count)) : still
                stroke(y, (each + (0.62 - each) * flat) * (1 - gone))
            }
        }
    }

    /// The PAN card that was found (44:3351), as the first onboarding draws it, with this onboarding's details:
    /// department header, ruled panel with name, PAN and date of birth, and the live hologram, on its faint cool tint
    private struct FoundPanCard: View {
        var body: some View {
            let rule = Color(hex: 0x615E5C).opacity(0.22)
            return ZStack(alignment: .topLeading) {
                // Gap: the card's faint cool tint over white (802:5673), 13%; the frame's gradient has no token
                Color.white
                LinearGradient(colors: [Color(red: 182 / 255, green: 183 / 255, blue: 205 / 255).opacity(0.13),
                                        Color(red: 173 / 255, green: 202 / 255, blue: 225 / 255).opacity(0.13)],
                               startPoint: .leading, endPoint: .trailing)

                Image("PanHeader")
                    .resizable()
                    .frame(width: 354, height: 118)
                    .offset(y: -30.9)
                    .frame(width: 354, height: 56, alignment: .top)
                    .clipped()
                    .at(5, 5)

                rule.frame(width: 364, height: 1).at(0, 65.5)
                rule.frame(width: 364, height: 1).at(0, 210.5)
                rule.frame(width: 1, height: 144).at(7.5, 66)
                rule.frame(width: 1, height: 144).at(12.5, 66)

                line("Name", "VANGIPURAPPU VENKATA").at(26, 77)
                line("Pan Account Number", "ABCDE8283D").at(26, 122)
                line("Date of Birth", "15/08/1999").at(26, 167)

                HologramSticker()
                    .frame(width: 80, height: 78)
                    .at(270, 118)
            }
            .frame(width: 364, height: 255, alignment: .topLeading)
        }

        private func line(_ label: String, _ value: String) -> some View {
            VStack(alignment: .leading, spacing: 0) {
                // Gap: Rg 12/15 in #212121 at 67%, and Rg 14/23 at 5% tracking in black 95%, as on the first onboarding's
                GapText(label, family: .walsheim, medium: false, size: 12, lineHeight: 15, color: Color(hex: 0x212121).opacity(0.67))
                    .fixedSize()
                GapText(value, family: .walsheim, medium: false, size: 14, lineHeight: 23, trackingPercent: 5, color: Color.black.opacity(0.95))
                    .fixedSize()
            }
        }
    }

    /// One of the details: what it is, 23 high, and its box 36 down, 330 across
    private func field<Content: View>(_ name: String, height: CGFloat, border: Color = OnboardingIntroV2View.line,
                                      @ViewBuilder content: () -> Content) -> some View {
        ZStack(alignment: .topLeading) {
            // Gap: GT Walsheim Medium 17/23 on content/primary
            GapText(name, family: .walsheim, medium: true, size: 17, lineHeight: 23, color: ColorScale.contentPrimary)
                .fixedSize()
            ZStack(alignment: .topLeading) { content() }
                .frame(width: 330, height: height, alignment: .topLeading)
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).strokeBorder(border, lineWidth: 1))
                .at(0, 36)
        }
        .frame(width: 330, height: 36 + height, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }

    /// What's in a box: GT Walsheim Regular 15/21 on content/primary, 15 in and 17 down
    private func value(_ words: String) -> some View {
        // Gap: GT Walsheim Regular 15/21 has no text style here
        GapText(words, family: .walsheim, medium: false, size: 15, lineHeight: 21, color: ColorScale.contentPrimary)
            .fixedSize()
            .at(15, 17)
    }

    /// A card: #FEFEFE, radius/27, Shadow/1 (0 4 100 +12 at 5%; SwiftUI can't draw the spread)
    private struct Carded: ViewModifier {
        func body(content: Content) -> some View {
            let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
            content
                // Gap: #FEFEFE, unbound
                .background(Color(hex: 0xFEFEFE))
                .clipShape(shape)
                .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
        }
    }
}
