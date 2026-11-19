import SwiftUI

/// "Importing Mutual funds from MFCentral" (952:13767 → 952:14516 → 952:14603 → 952:14919): after the MFCentral
/// sheet's Continue. Under a "Mutual funds" pill, a card with the houses' marks, the heading, and a box of three
/// steps that are ticked off as the import gets through them, the way an agent reports its work. It stops twice
/// for the user: a one-time password, in a sheet over the number pad, and then MFCentral's security questions,
/// in a sheet from the foot. When the setup's complete the card clears to just the houses' marks while the funds load,
/// and then shows what came in (1027:11251): the funds, and what the advisor has for them; View goes back to the chat.
struct MFImportView: View {
    /// The status bar's height: the pill hangs 9 below it
    let top: CGFloat
    let onDone: () -> Void

    private enum Phase: Int, Comparable {
        case connecting, connected, otp, verified, questions, finishing, complete, loading, imported
        static func < (a: Phase, b: Phase) -> Bool { a.rawValue < b.rawValue }
    }

    @State private var phase = Phase.connecting
    @State private var code = ""
    @State private var question = 0
    @State private var answer = ""
    /// The answer field has the keyboard up
    @State private var answering = false
    /// How far the screen's top has been moved off the display's, by the keyboard
    @State private var drift: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Placeholder questions, written for the prototype
    private static let questions = ["Where were you born", "What was the name of your first school"]
    private static let otp = "889302"
    private static let rise = Animation.spring(response: 0.55, dampingFraction: 0.86)
    private static let hairline = Color(hex: 0xC2C2C2).opacity(0.33)

    var body: some View {
        // Laid over the page rather than sizing it: when the keyboard shrinks the space, content taller than what's
        // left would otherwise be pushed up under the status bar
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // With the keyboard up the screen this sits in is re-centred in the room that's left, half the
            // keyboard's height higher; the page is put back by however far its own top has ridden up
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { drift = $0 }
            .overlay(alignment: .top) { page.offset(y: -drift) }
            .background(ColorScale.surfaceBase.ignoresSafeArea())
            .ignoresSafeArea(.keyboard)
            .preferredColorScheme(.light)
            .task { await run() }
    }

    private var page: some View {
        ZStack(alignment: .top) {
            // 952:13799: the pill, 348 × 47, 9 under the status bar
            HStack(spacing: 10.076) {
                Image("OnboardingKycCard")
                    .frame(width: 24.924, height: 21)
                    .accessibilityHidden(true)
                Text("Mutual funds")
                    .font(FigmaFont.walsheimMedium(19))
                    .foregroundStyle(Color.black)
                    .fixedSize()
            }
            .frame(width: 348, height: 47)
            .background(Capsule().fill(ColorScale.surfaceWidget))
            .overlay(Capsule().strokeBorder(ColorScale.borderSubtle, lineWidth: 1))
            .padding(.top, top + 9)

            card
                .padding(.top, top + 69)

            // 952:14421: under the card
            Text("We suggest not closing the app, connecting will take\nmaximum of 2 mins")
                .font(FigmaFont.walsheim(13))
                .lineSpacing(17 - UIFont(name: "GTWalsheimTrial-Rg", size: 13)!.lineHeight)
                .foregroundStyle(Color(hex: 0x212121).opacity(0.47))
                .multilineTextAlignment(.center)
                .frame(width: 348)
                .padding(.top, top + 709)
                .opacity(phase == .imported ? 0 : 1)

            if phase == .otp {
                otpSheet
                    .padding(.top, top + 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if phase == .questions {
                questionSheet
                    // Lifted clear of the keyboard while an answer's being typed
                    .padding(.top, top + (answering ? 20 : 201))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: answering)
    }

    // MARK: The run

    private func pause(_ seconds: Double) async -> Bool {
        try? await Task.sleep(for: .seconds(seconds))
        return !Task.isCancelled
    }

    /// Connecting, then the account's connected and the mobile needs verifying, then the one-time password
    private func run() async {
        guard await pause(2.6) else { return }
        Haptics.thresholdCrossed()
        withAnimation(Self.rise) { phase = .connected }
        guard await pause(1.9) else { return }
        Haptics.expand()
        withAnimation(Self.rise) { phase = .otp }
    }

    /// All six digits are in: the sheet goes, the step's ticked, and the questions come
    private func confirmCode() {
        guard phase == .otp else { return }
        Haptics.tap()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation(Self.rise) { phase = .verified }
        Task {
            guard await pause(1.5) else { return }
            Haptics.expand()
            withAnimation(Self.rise) { phase = .questions }
        }
    }

    /// "I know the answer" and "I don't remember" both move on: to the next question, then to the finish
    private func confirmAnswer() {
        guard phase == .questions else { return }
        Haptics.tap()
        if question + 1 < Self.questions.count {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                question += 1
                answer = ""
            }
            return
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        answering = false
        withAnimation(Self.rise) { phase = .finishing }
        Task {
            guard await pause(1.6) else { return }
            Haptics.revealSettled()
            withAnimation(Self.rise) { phase = .complete }
            // 952:15070: the steps are done with; the houses come to the middle of the card while the funds load
            guard await pause(1.1) else { return }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.86)) { phase = .loading }
            guard await pause(3.6) else { return }
            Haptics.expand()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { phase = .imported }
        }
    }

    // MARK: The card (952:13770), 368 × 619

    private var card: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            // The houses' tiles, each riding up and down a little on its own beat while the import runs
            MFHouseTiles(still: phase == .imported)
            // To the middle of the card while the funds load (952:15070)
            .offset(y: phase >= .loading ? 202 : 0)
            // and gone once they're in
            .scaleEffect(phase == .imported ? 0.85 : 1)
            .opacity(phase == .imported ? 0 : 1)
            .accessibilityHidden(true)

            Text("Importing Mutual\nfunds from MFCentral")
                .font(FigmaFont.walsheimMedium(33))
                .lineSpacing(41 - UIFont(name: "GTWalsheimTrial-Md", size: 33)!.lineHeight)
                .foregroundStyle(Color.black.opacity(0.93))
                .multilineTextAlignment(.center)
                .frame(width: 330)
                .at(19, 240)
                .opacity(phase >= .loading ? 0 : 1)
                .offset(y: phase >= .loading ? 24 : 0)

            steps
                .at(19, 349)
                .opacity(phase >= .loading ? 0 : 1)
                .offset(y: phase >= .loading ? 24 : 0)

            if phase == .imported {
                imported
                    .transition(.opacity.combined(with: .offset(y: 16)))
            }
        }
        // 619 while it works, 684 for what it brought in (1027:11254)
        .frame(width: 368, height: phase == .imported ? 684 : 619, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        // Shadow/1 (0 4 100 +12 at 5%); SwiftUI can't draw the spread
        .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
    }

    // MARK: Imported (1027:11254)

    /// The funds the frame lists
    private static let funds: [(logo: String, name: String)] = [
        ("ImportFund1", "ICICI Prudential Gold ETF FOF Regular Growth"),
        ("ImportFund2", "Axis Ultra Short Term Fund Direct Growth"),
        ("ImportFund3", "HDFC Short Term Fund Regular Growth"),
        ("ImportFund4", "Kotak Large Cap Fund Direct Growth"),
    ]

    /// What came in, in the card's own measure: the tick, the heading, the funds in a box that scrolls, and the
    /// advisor's two lines under them
    private var imported: some View {
        ZStack(alignment: .topLeading) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 50, weight: .regular))
                .foregroundStyle(ColorPrimitives.utilityGreen500)
                .frame(width: 54, height: 54)
                .at(157, 26)
                .accessibilityHidden(true)

            Text("Mutual fund portfolio\nimported securely")
                .font(FigmaFont.walsheimMedium(33))
                .lineSpacing(41 - UIFont(name: "GTWalsheimTrial-Md", size: 33)!.lineHeight)
                .foregroundStyle(Color.black.opacity(0.93))
                .multilineTextAlignment(.center)
                .frame(width: 330)
                .at(19, 105)

            DsText("Funds in your portfolio", variant: .h6, color: .contentSecondary)
                .fixedSize()
                .frame(width: 368)
                .at(0, 216)

            fundsBox
                .at(19, 256)

            DsText("From wealth advisor", variant: .h6, color: .contentSecondary)
                .fixedSize()
                .frame(width: 368)
                .at(0, 469)

            // 1027:12342: the advisor's read, ready to open
            advisorRow(
                title: "How my equity funds performed", detail: "This is our read on We will notify you when ready", titleLeft: 53
            ) {
                Image("ImportReadCheck")
                    .frame(width: 39, height: 39)
                    .background(ColorPrimitives.utilityGreen400)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            } trailing: {
                // Nothing is designed behind View yet; it goes back to the chat, where the card reads as connected
                Button {
                    Haptics.tap()
                    onDone()
                } label: {
                    Text("View")
                        .font(FigmaFont.walsheimMedium(13))
                        .foregroundStyle(Color.white)
                        .frame(width: 61, height: 37)
                        .background(Capsule().fill(Color.black))
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
                        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
                }
                .buttonStyle(PressScaleStyle())
            }
            .at(19, 502)

            // 1027:12315: the analysis, under way
            advisorRow(title: "Portfolio analysis started", detail: "We will notify you when it is ready", titleLeft: 48) {
                Image("ImportAnalysing")
                    .frame(width: 39, height: 39)
            } trailing: {
                VStack(spacing: 0) {
                    Text("30")
                        .font(FigmaFont.walsheim(15))
                        .foregroundStyle(ColorScale.contentSecondary)
                        .frame(height: 21)
                    Text("mins")
                        .font(FigmaFont.walsheim(11))
                        .foregroundStyle(ColorScale.contentDisabled)
                        .frame(height: 15)
                }
                .offset(y: 0.5)
                .frame(width: 43, height: 43)
                .background(ColorScale.surfaceSunken1)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: Color.black.opacity(0.07), radius: 48.5, x: 0, y: 4)
            }
            .at(19, 585)
        }
        .frame(width: 368, height: 684, alignment: .topLeading)
    }

    /// 1027:11257: 330 × 175, a 76 row a fund; the list runs on under the box's foot and scrolls
    private var fundsBox: some View {
        let shape = RoundedRectangle(cornerRadius: 15, style: .continuous)
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(Self.funds.enumerated()), id: \.offset) { index, fund in
                    HStack(alignment: .top, spacing: 0) {
                        Image(fund.logo)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: index == 1 ? 22 : 31, height: index == 1 ? 25 : 31)
                            .frame(width: 31, height: 31)
                            .background(ColorScale.surfaceSunken1)
                            .clipShape(RoundedRectangle(cornerRadius: 9.118, style: .continuous))
                            .padding(.top, 3)
                            .accessibilityHidden(true)
                        Text(fund.name)
                            .font(FigmaFont.walsheim(17))
                            .lineSpacing(23 - UIFont(name: "GTWalsheimTrial-Rg", size: 17)!.lineHeight)
                            .foregroundStyle(Color.black.opacity(0.61))
                            .frame(width: 252, alignment: .leading)
                            .padding(.leading, 11)
                    }
                    .padding(.leading, 14)
                    .padding(.top, 14)
                    .frame(width: 330, height: 75, alignment: .topLeading)
                    Color(hex: 0xEBEBEB).frame(width: 329, height: 1)
                }
            }
        }
        .frame(width: 330, height: 175)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Self.hairline, lineWidth: 1))
    }

    /// One of the advisor's lines: 330 × 69 on the page's own colour, a 39 tile, two lines of words, and what's at its end
    private func advisorRow<Lead: View, Trail: View>(
        title: String, detail: String, titleLeft: CGFloat,
        @ViewBuilder lead: () -> Lead, @ViewBuilder trailing: () -> Trail
    ) -> some View {
        ZStack(alignment: .topLeading) {
            ColorScale.surfaceBase
            lead()
                .at(15, 15)
                .accessibilityHidden(true)
            Text(title)
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(ColorScale.contentPrimary)
                // A longer title than the frame's is set a little smaller, to stay clear of what's at the row's end
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: titleLeft == 53 ? 188 : 208, height: 23, alignment: .leading)
                .at(15 + titleLeft, 13)
            Text(detail)
                .font(FigmaFont.walsheim(13))
                .foregroundStyle(Color(hex: 0x212121).opacity(0.47))
                .lineLimit(1)
                .frame(width: titleLeft == 53 ? 176 : 208, height: 17, alignment: .leading)
                .at(15 + titleLeft, 39)
            trailing()
                .frame(width: 300, height: 69, alignment: .trailing)
                .at(15, 0)
        }
        .frame(width: 330, height: 69, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    // MARK: The steps (952:14404), 330 × 183

    private enum StepState { case pending, active, done }

    /// Each step as it stands: its title, the line under it while it's the one being worked on, and its state
    private var stepRows: [(title: String, detail: String?, state: StepState)] {
        func state(_ from: Phase, _ to: Phase) -> StepState { phase < from ? .pending : phase < to ? .active : .done }
        let mobile = state(.connected, .verified)
        let security = state(.verified, .complete)
        return [
            (phase < .connected ? "Connecting securely" : "Account connected", phase < .connected ? "MFCentral.com" : nil,
             phase < .connected ? .active : .done),
            (mobile == .done ? "Mobile verified" : "Mobile verification",
             mobile == .active ? (phase == .otp ? "Sending OTP to your mobile" : "Verifying account with secure OTP") : nil, mobile),
            (security == .done ? "Security verified" : "Security questions",
             security == .active ? (phase == .finishing ? "Checking your answers" : "Verifying it’s you") : nil, security),
        ]
    }

    private var steps: some View {
        let rows = stepRows
        // A step that's done is 52 tall, the one being worked on 74, one still to come 54; the last takes what's
        // left of the 183. With all three done they share it.
        let heights: [CGFloat] = {
            if phase >= .complete { return [61, 61, 61] }
            let first: [CGFloat] = rows.prefix(2).map { $0.state == .done ? 52 : $0.state == .active ? 74 : 54 }
            return first + [183 - first[0] - first[1]]
        }()
        let tops: [CGFloat] = [0, heights[0], heights[0] + heights[1]]
        let shape = RoundedRectangle(cornerRadius: 15, style: .continuous)

        return ZStack(alignment: .topLeading) {
            ForEach(0..<3, id: \.self) { index in
                let row = rows[index]
                let titleTop = tops[index] + (index == 0 ? 14 : 15)

                if index > 0 {
                    Color(hex: 0xEBEBEB)
                        .frame(width: 279, height: 1)
                        .at(50, tops[index] - 1)
                }

                // The mark before it: a tick once done, a dot until then
                let markTop: CGFloat = row.state == .done ? titleTop + 3
                    : row.state == .active ? (index == 0 ? 17 : tops[index] + 25) : titleTop - 1
                Group {
                    if row.state == .done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(ColorPrimitives.utilityGreen500)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    } else {
                        Circle()
                            .fill(Color(red: 58 / 255, green: 58 / 255, blue: 58 / 255).opacity(0.35))
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(width: 25, height: 25)
                .at(14, markTop)
                .accessibilityHidden(true)

                // Joined to the step being worked on (952:14885)
                if row.state == .done, index < 2, rows[index + 1].state == .active {
                    Color(hex: 0xDFDCDA)
                        .frame(width: 1, height: 40)
                        .at(26, titleTop + 29)
                        .transition(.opacity)
                }

                Text(row.title)
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(row.state == .pending ? ColorScale.contentTertiary : ColorScale.contentPrimary)
                    .fixedSize()
                    .frame(height: 23)
                    .contentTransition(.opacity)
                    .at(50 + (index == 0 && row.state == .active ? 0 : 1), titleTop)

                if let detail = row.detail {
                    HStack(spacing: 5) {
                        if index == 0 {
                            // 952:14425: MFCentral's mark, 17 across
                            Image("MFCentralIcon")
                                .resizable()
                                .frame(width: 21.474, height: 21.474)
                                .frame(width: 17, height: 17)
                                .clipShape(RoundedRectangle(cornerRadius: 4.474, style: .continuous))
                        }
                        Text(index == 0 ? detail.uppercased() : detail)
                            .font(FigmaFont.walsheim(13))
                            .tracking(index == 0 ? 0.39 : 0)
                            .foregroundStyle(Color.black.opacity(0.35))
                            .fixedSize()
                            .contentTransition(.opacity)
                    }
                    .frame(height: 21)
                    .at(index == 0 ? 50 : 51, titleTop + 24)
                    .transition(.opacity)
                }
            }
        }
        .frame(width: 330, height: 183, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Self.hairline, lineWidth: 1))
    }

    // MARK: One-time password (952:14708), 364 × 387

    private var otpSheet: some View {
        let shape = RoundedRectangle(cornerRadius: 23, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Color.white

            Image("ImportKey")
                .rotationEffect(.degrees(90))
                .frame(width: 51, height: 50)
                .at(156, 36.3)
                .accessibilityHidden(true)

            DsText("MFCentral OTP", variant: .h4)
                .fixedSize()
                .frame(width: 364)
                .at(2.5, 134)

            Text("Enter the one-time password\nsent to your mobile")
                .font(FigmaFont.walsheim(19))
                .lineSpacing(25 - UIFont(name: "GTWalsheimTrial-Rg", size: 19)!.lineHeight)
                .foregroundStyle(ColorScale.contentPrimary)
                .multilineTextAlignment(.center)
                .frame(width: 318)
                .at(22.3, 179.3)

            ZStack(alignment: .topLeading) {
                codeText
                    .frame(width: 318, height: 48)
                    .at(0, 11)
                Color(hex: 0xEBEBEB)
                    .frame(width: 316, height: 1)
                    .at(0, 67)
                HStack(spacing: 5) {
                    Text("Confirmation OTP sent")
                        .font(FigmaFont.walsheim(13))
                        .foregroundStyle(Color(hex: 0x1DB124))
                        .fixedSize()
                    Image("ImportSentCheck")
                        .frame(width: 17, height: 17)
                }
                .frame(width: 318, height: 17)
                .at(0.5, 78)

                // The entry itself: unseen, it holds the number pad up and takes what's typed or offered
                OTPField(code: $code, offer: Self.otp)
                    .frame(width: 318, height: 66)
                    .opacity(0.02)
            }
            .frame(width: 318, height: 107, alignment: .topLeading)
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Self.hairline, lineWidth: 1))
            .at(22.3, 246.3)
        }
        .frame(width: 364, height: 387, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(ColorScale.borderSubtle, lineWidth: 0.7))
        // Shadow/3 (0 2 85 +7 at 11%); SwiftUI can't draw the spread
        .shadow(color: Color.black.opacity(0.11), radius: 42.5, x: 0, y: 2)
        .onChange(of: code) { _, entered in
            guard entered.count == 6 else { return }
            // A beat to see the last digit land
            Task {
                guard await pause(0.45) else { return }
                confirmCode()
            }
        }
    }

    /// "000-000": the digits that have come in, in ink, the rest pale zeros
    private var codeText: some View {
        let digits = Array(code)
        var text = Text("")
        for i in 0..<6 {
            if i == 3 { text = text + Text("-").foregroundColor(ColorScale.contentDisabled) }
            let typed = i < digits.count
            text = text + Text(typed ? String(digits[i]) : "0")
                .foregroundColor(typed ? ColorScale.contentPrimary : ColorScale.contentDisabled)
        }
        return text
            .font(FigmaFont.walsheimMedium(35))
            .tracking(8.05)
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.2), value: code)
            .accessibilityHidden(true)
    }

    // MARK: Security question (952:14976), 364 × 526

    private var questionSheet: some View {
        let shape = RoundedRectangle(cornerRadius: 23, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Color.white

            Image("ImportKey")
                .rotationEffect(.degrees(90))
                .frame(width: 51, height: 50)
                .at(156, 36.3)
                .accessibilityHidden(true)

            DsText("Answer security question", variant: .h4)
                .fixedSize()
                .frame(width: 364)
                .at(2.5, 147.3)

            DsText("You would have set this up while creating your MFCentral account", variant: .p4, color: .contentSecondary)
                .multilineTextAlignment(.center)
                .frame(width: 290)
                .at(37, 181.3)

            DsText(Self.questions[question], variant: .h6)
                .frame(width: 330, alignment: .leading)
                .at(17, 260.3)
                .id(question)
                .transition(.opacity)

            ZStack(alignment: .leading) {
                if answer.isEmpty {
                    DsText("Enter answer", variant: .p4, color: .contentTertiary)
                        .allowsHitTesting(false)
                }
                AnswerField(text: $answer, editing: $answering, onReturn: confirmAnswer)
                    .frame(height: 55)
            }
            .padding(.horizontal, 14)
            .frame(width: 330, height: 55)
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Self.hairline, lineWidth: 1))
            .at(17, 296.3)

            // 973:15155: the label a little left of centre, the tick after it
            Button(action: confirmAnswer) {
                ZStack(alignment: .leading) {
                    Text("I know the answer")
                        .font(FigmaFont.walsheimMedium(17))
                        .foregroundStyle(Color.white)
                        .frame(width: 318)
                        .offset(x: -7)
                    Image("ImportKnowCheck")
                        .frame(width: 28, height: 27)
                        .offset(x: 228)
                }
                .frame(width: 318, height: 49)
                .background(Capsule().fill(Color(hex: 0x1F1513)))
                .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
            }
            .buttonStyle(PressScaleStyle())
            .at(23, 396.7)

            // 973:15157
            Button(action: confirmAnswer) {
                HStack(spacing: 1) {
                    Text("I don’t remember")
                        .font(FigmaFont.walsheim(15))
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .frame(width: 21, height: 21)
                }
                .foregroundStyle(Color.black.opacity(0.7))
                .frame(height: 21)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(width: 364)
            .at(0.5, 462.7)
        }
        .frame(width: 364, height: 526, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(ColorScale.borderSubtle, lineWidth: 0.7))
        // Shadow/3 (0 2 85 +7 at 11%); SwiftUI can't draw the spread
        .shadow(color: Color.black.opacity(0.11), radius: 42.5, x: 0, y: 2)
    }
}

/// The fund houses' nine tiles (952:14376 onwards, with the houses' own logos), in a 368 × 220 band. They rest where the frames scatter them
/// and turn slowly as one, as if set on a tilted disc: round the back they shrink a little and slip behind, at
/// the front they come forward, each breathing on its own beat. The loader over the MFCentral screens.
struct MFHouseTiles: View {
    /// Held still (and with Reduce Motion)
    var still = false
    @State private var began = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Each house's tile: its mark, where its centre sits across the card, and its top
    private static let houses: [(logo: String, centre: CGFloat, top: CGFloat)] = [
        // The fund houses themselves: HDFC, PPFAS, ICICI Prudential, SBI, Kotak, Axis, Quant, Nippon India, HSBC
        ("ImportFund3", 80.5, 28), ("FundPPFAS", 180.5, 21), ("ImportFund1", 264.5, 21),
        ("FDGrowthSBI", 80.5, 110), ("ImportFund4", 150.5, 86), ("ImportFund2", 220.5, 86),
        ("FundQuant", 286.5, 92), ("FundNippon", 158.5, 158), ("ImportHouseHSBC", 246.5, 158),
    ]
    /// The cluster's middle, which they turn about
    private static let middle = CGPoint(x: 184, y: 115)
    /// How flat the disc looks: its depth drawn at this much of its width
    private static let tilt = 0.62
    /// Seconds for one turn
    private static let period = 46.0

    var body: some View {
        TimelineView(.animation(paused: reduceMotion || still)) { timeline in
            let elapsed = reduceMotion ? 0 : timeline.date.timeIntervalSince(began)
            let turn = elapsed / Self.period * 2 * .pi
            ZStack(alignment: .topLeading) {
                ForEach(Array(Self.houses.enumerated()), id: \.offset) { index, house in
                    // On the disc: the frame's place about the middle, its depth stretched back out
                    let px = Double(house.centre - Self.middle.x)
                    let py = Double(house.top + 25.5 - Self.middle.y) / Self.tilt
                    let x = px * cos(turn) - py * sin(turn)
                    let depth = px * sin(turn) + py * cos(turn)
                    // -1 at the back, 1 at the front
                    let near = max(-1, min(1, depth / 140))
                    let breath = 1 + 0.03 * sin(elapsed * 0.9 + Double(index) * 1.7)
                    houseTile(house.logo)
                        .scaleEffect((1 + 0.09 * near) * breath)
                        .at(Self.middle.x + x - 25.5, Self.middle.y + depth * Self.tilt - 25.5)
                        .zIndex(depth)
                }
            }
        }
        .frame(width: 368, height: 220, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    /// A 51 tile (952:14376): white, hairline border, the mark 37 across inside
    private func houseTile(_ logo: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 15, style: .continuous)
        // Whole, whatever its shape: some marks are square, some wide
        return Image(logo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 37, height: 37)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .frame(width: 51, height: 51)
        .background(Color.white)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color(hex: 0xEBE9E8), lineWidth: 0.7))
    }
}

/// The answer's entry (817:6768): a UIKit field, so taking the keyboard doesn't have SwiftUI push the page up to
/// show it; the page makes its own room
private struct AnswerField: UIViewRepresentable {
    @Binding var text: String
    @Binding var editing: Bool
    let onReturn: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.font = UIFont(name: "GTWalsheimTrial-Rg", size: 15) ?? .systemFont(ofSize: 15)
        field.textColor = UIColor(ColorScale.contentPrimary)
        field.tintColor = UIColor(ColorScale.contentPrimary)
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.accessibilityLabel = "Answer"
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        if field.text != text { field.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AnswerField
        init(parent: AnswerField) { self.parent = parent }

        @objc func changed(_ field: UITextField) { parent.text = field.text ?? "" }
        func textFieldDidBeginEditing(_ field: UITextField) { parent.editing = true }
        func textFieldDidEndEditing(_ field: UITextField) { parent.editing = false }
        func textFieldShouldReturn(_ field: UITextField) -> Bool {
            parent.onReturn()
            return false
        }
    }
}

/// The one-time password's entry: a UIKit field that takes the number pad as soon as it's on screen, with the
/// code "From Messages" offered in a bar over the keys, as iOS offers it; a tap on the offer fills it in
private struct OTPField: UIViewRepresentable {
    @Binding var code: String
    let offer: String

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.keyboardType = .numberPad
        field.textContentType = .oneTimeCode
        field.tintColor = .clear
        field.textColor = .clear
        field.accessibilityLabel = "One-time password"
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)

        // 952:14748's suggestion row: "From Messages" over the code, between two hairlines
        let bar = UIInputView(frame: CGRect(x: 0, y: 0, width: 0, height: 48), inputViewStyle: .keyboard)
        var config = UIButton.Configuration.plain()
        var title = AttributedString("From Messages\n" + offer)
        title.font = .systemFont(ofSize: 12)
        if let range = title.range(of: offer) { title[range].font = .systemFont(ofSize: 16) }
        title.foregroundColor = .label
        config.attributedTitle = title
        config.titleAlignment = .center
        let button = UIButton(configuration: config)
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.accessibilityLabel = "From Messages " + offer
        button.addTarget(context.coordinator, action: #selector(Coordinator.take), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(button)
        var constraints = [
            button.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            button.heightAnchor.constraint(equalToConstant: 48),
        ]
        for side in [44.0, -44.0] {
            let rule = UIView()
            rule.backgroundColor = UIColor.black.withAlphaComponent(0.1)
            rule.translatesAutoresizingMaskIntoConstraints = false
            bar.addSubview(rule)
            constraints += [
                rule.widthAnchor.constraint(equalToConstant: 1),
                rule.heightAnchor.constraint(equalToConstant: 25),
                rule.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
                side > 0 ? rule.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: side)
                    : rule.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: side),
            ]
        }
        NSLayoutConstraint.activate(constraints)
        field.inputAccessoryView = bar
        context.coordinator.field = field

        // Up with the sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { field.becomeFirstResponder() }
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        if field.text != code { field.text = code }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: OTPField
        weak var field: UITextField?
        init(parent: OTPField) { self.parent = parent }

        @objc func changed(_ field: UITextField) {
            let digits = String((field.text ?? "").filter(\.isNumber).prefix(6))
            if field.text != digits { field.text = digits }
            if parent.code != digits { parent.code = digits }
        }

        /// The offered code, taken
        @objc func take() {
            field?.text = parent.offer
            parent.code = parent.offer
        }

        func textField(_ field: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = field.text ?? ""
            guard let swift = Range(range, in: current) else { return false }
            let next = current.replacingCharacters(in: swift, with: string)
            return next.count <= 6 && next.allSatisfy(\.isNumber)
        }
    }
}

#Preview {
    MFImportView(top: 62, onDone: {})
}
