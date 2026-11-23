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
///   all, with what was found for the number: the name, the PAN, the date of birth and the gender, and Continue.
///   Continue confirms them: a green tick stands where the heading was (1362:7450), and after a moment it goes on.
///
/// Nothing is looked up on the way: the first onboarding's sphere that turns into the PAN card as it's found
/// (`OnboardingIntroView`) isn't part of this. It's kept where it was, and `-onboardingIntroV1` puts it back here.
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
    @Environment(\.onboardingTop) private var top

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

            // 1362:7379: 356 × 514
            ZStack(alignment: .topLeading) {
                // 1362:7435
                field("Full name", height: 108) {
                    value("Venkata")
                    Self.line.frame(width: 329, height: 1).at(1, 55)
                    // Gap: Rg 13/17 in #212121 at 47%
                    GapText("Make sure it matches the name on your government ID", family: .walsheim, medium: false, size: 13, lineHeight: 17, color: Self.ink.opacity(0.47))
                        .frame(width: 241, alignment: .leading)
                        .at(15, 63)
                }
                .at(13, 17)
                // 1362:7441
                field("PAN", height: 55) { value("ABCDE8283D") }
                    .at(13, 182)
                // 1362:7445 (the frame has the PAN again here; the date is the first onboarding's)
                field("Date of birth", height: 55) { value("15/08/1999") }
                    .at(13, 294)
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
                .at(13, 406)
            }
            .frame(width: 356, height: 514, alignment: .topLeading)
            .modifier(Carded())
            .at(side + 17, 189 - 44 + top)

            // 1362:7256
            OnboardingConfirmButton(action: next)
                .at(side + 23, 730 - 44 + top)
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
