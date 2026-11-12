import AVFoundation
import SwiftUI

/// The first onboarding screen and the one after it, as one surface.
///
/// Welcome — Figma "iPhone 14 Plus - 84" (130:1921): a tall white card with the watch-movement film playing on peach
/// in its top half under the Decade mark, "Personal Wealth Advisory Standard" and a line about it under that, a link
/// to the terms, and a dark Agree & Continue below the card, on white.
///
/// Phone — Figma "iPhone 14 Plus - 287" (31:801): tapping Agree & Continue doesn't slide in a new page. The same card
/// shrinks to fit the phone-number form, the film and copy fade away, the Decade wordmark glides up to become the
/// card's heading, the white gives way to the pale blobs, and the number pad comes up.
///
/// One-time password — Figma "iPhone 14 Plus - 288" (31:1021): Verify sends the phone card back, smaller, keeping just
/// the number that was entered, while the OTP card drops in over it from 1.3× to its size. The number pad stays up.
///
/// Identity — Figma "iPhone 14 Plus - 291" (44:2228): the second Verify puts the keyboard away and does it again. The
/// OTP card steps back to become the "Verify your identity" heading card, the phone card slips away behind it, and a
/// black card with a slowly turning particle sphere lands over them from 1.3×. Five seconds later the sphere swells,
/// flattens over the card and resolves, top to bottom, into the PAN card (44:3351) that was found, with a live
/// hologram, and Verify comes back.
struct OnboardingIntroView: View {
    let onContinue: () -> Void

    /// The film that fills the card's media area
    static let videoName = "watch_movement"
    /// The same film on black, for the black version
    static let blackVideoName = "watch_movement_black"

    /// Owned by the flow, so the morph survives this view being rebuilt
    @Bindable var stage: OnboardingIntroStage

    private static let morph = Animation.spring(response: 0.62, dampingFraction: 0.86)

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) { content }
            .preferredColorScheme(.light)
            .background(background.ignoresSafeArea())
            // The number pad rises over the empty lower half; the card stays put
            .ignoresSafeArea(.keyboard)
    }

    /// Laid over the page rather than sizing it: when the number pad shrinks the space, content taller than what's
    /// left would otherwise be re-centred and pushed up under the status bar
    private var content: some View {
        ZStack(alignment: .topLeading) {
            card
                .at(stage.otp ? 35 : 13, stage.phone ? 0 : 9)
                // Slips away behind once the OTP card has stepped back over it
                .scaleEffect(stage.identity ? 0.9 : 1, anchor: .top)
                .opacity(stage.identity ? 0 : 1)

            // Lands from 1.3× over the phone card as it steps back
            if stage.otp {
                otpCard
                    .at(stage.identity ? 27 : 13, stage.identity ? 19 : 51)
                    .transition(.scale(scale: 1.3).combined(with: .opacity))
            }

            // And again over the OTP card
            if stage.identity {
                identityCard
                    .at(13, 158)
                    // Solid almost at once, so the black never washes grey over the white cards while it scales in
                    .transition(.scale(scale: 1.3).combined(with: .opacity.animation(.easeOut(duration: 0.12))))
                    // Over the Verify button as it fades
                    .zIndex(1)
            }

            agreeButton
                .at(86, 690)
                .opacity(stage.welcomeShown ? 1 : 0)
                .scaleEffect(stage.welcomeShown ? 1 : 0.96)
                .allowsHitTesting(!stage.phone)

            verifyButton
                .at(280, stage.identity ? 469 : 358)
                .opacity(verifyShown ? 1 : 0)
                .scaleEffect(verifyShown ? 1 : 0.9)
                .allowsHitTesting(verifyShown)
        }
        .frame(width: 390, alignment: .topLeading)
        // The flow ignores the safe area: 13pt below the status bar, as in Figma
        .padding(.top, Self.statusBarHeight + 13)
    }

    /// Under the phone and OTP forms, then gone while the sphere turns, then back under the PAN card
    private var verifyShown: Bool {
        stage.identity ? stage.idCard : stage.formShown || stage.otp
    }

    /// The app window's top inset. Not the key window's: while the number pad is up that's the keyboard's, with none.
    private static var statusBarHeight: CGFloat {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        return scene?.windows.first?.safeAreaInsets.top ?? 44
    }

    // MARK: Morph

    private func agree() {
        Haptics.tap()
        withAnimation(.easeOut(duration: 0.18)) { stage.welcomeShown = false }
        withAnimation(Self.morph) { stage.phone = true }
        withAnimation(.easeOut(duration: 0.35).delay(0.28)) { stage.formShown = true }
    }

    /// Back from the OTP to the number: the OTP card goes, the phone card comes forward with its form and number pad
    private func changeNumber() {
        Haptics.tap()
        stage.code = ""
        withAnimation(Self.morph) { stage.otp = false }
        withAnimation(.easeOut(duration: 0.35).delay(0.28)) { stage.formShown = true }
    }

    private func verify() {
        guard stage.otp else {
            // The phone card steps back with just its number; the OTP card lands over it
            Haptics.tap()
            withAnimation(.easeOut(duration: 0.18)) { stage.formShown = false }
            stage.otpSentAt = .now
            withAnimation(Self.morph) { stage.otp = true }
            return
        }
        guard stage.identity else {
            // The OTP card steps back into the heading; the sphere card lands over it
            Haptics.tap()
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            stage.identityStart = .now
            withAnimation(Self.morph) { stage.identity = true }
            return
        }
        onContinue()
    }

    // MARK: Background

    /// Dusk gradient (17:833) fading to the pale page (31:801): four soft ellipses under a frosted white sheet
    private var background: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: 0xFCFCFC)
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Color(hex: 0xF6F5DF))
                    .frame(width: 165, height: 378)
                    .position(x: 97 + 82.5, y: 118 + 189)
                Ellipse().fill(Color(hex: 0xBBC5B0))
                    .frame(width: 119.377, height: 273.036)
                    .rotationEffect(.degrees(-86.94))
                    .position(x: 146.5, y: 625.9)
                Ellipse().fill(Color(hex: 0xF0F0F0))
                    .frame(width: 359.537, height: 446)
                    .rotationEffect(.degrees(-3.73))
                    .position(x: 364.9, y: 215.2)
                Ellipse().fill(Color(hex: 0xF0F0F0))
                    .frame(width: 359.537, height: 446)
                    .rotationEffect(.degrees(-3.73))
                    .position(x: 268.9, y: 513.2)
            }
            .frame(width: 390, height: 840, alignment: .topLeading)
            .blur(radius: 72)
            .frame(maxWidth: .infinity, alignment: .top)
            Color.white.opacity(0.87)

            // The welcome's surface/base, giving way to the blobs as the card turns
            ColorScale.surfaceBase
                .opacity(stage.phone ? 0 : 1)
        }
    }

    // MARK: Card — 364 × 640 (130:1924) shrinking to 364 × 339 (31:900), then back to 321 × 299 (31:1217)

    private var card: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            // The welcome (555:9689): a rule under the Decade mark, the heading and its line, then the watch movement
            Group {
                // Gap: Figma black 57%, 1 pt, no token
                Color.black.opacity(0.57)
                    .frame(width: 328, height: 1)
                    .at(18, 52)

                DsText("Personal advisory wealth standard", variant: .h1)
                    .frame(width: 330, alignment: .leading)
                    .at(17, 70)

                DsText("Thoughtful wealth management for people who’ve outgrown generic advice.", variant: .p3)
                    .frame(width: 312, alignment: .leading)
                    .at(17, 226)

                media
                    .at(0, 290)
            }
            .opacity(stage.welcomeShown ? 1 : 0)

            // Built once the card turns, so its number pad comes up as the form lands
            if stage.phone {
                phoneForm
                    .opacity(stage.formShown ? 1 : 0)
                    .offset(y: stage.formShown ? 0 : 14)
            }

            wordmark
                .opacity(stage.otp ? 0 : 1)

            numberRow
                .at(15.5, 13)
                .opacity(stage.otp ? 1 : 0)
                .offset(y: stage.otp ? 0 : 8)

            // 316:16628: back to the number, to change it
            changeNumberButton
                .at(181, 10)
                .opacity(stage.otp && !stage.identity ? 1 : 0)
                .offset(y: stage.otp ? 0 : 8)
                .allowsHitTesting(stage.otp && !stage.identity)
        }
        .frame(width: cardSize.width, height: cardSize.height, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: cardCorner, style: .continuous).stroke(Color.white.opacity(0.09), lineWidth: 3))
        // Gap: the welcome's shadow is 0 4 100 +23 at 8% in Figma, not a Shadow/* style; SwiftUI can't draw the spread
        .shadow(color: Color.black.opacity(0.08), radius: 50, x: 0, y: 4)
    }

    private var cardSize: CGSize {
        stage.otp ? CGSize(width: 321, height: 298.95) : CGSize(width: 364, height: stage.phone ? 339 : 652)
    }

    private var cardCorner: CGFloat { stage.otp ? 23 : stage.phone ? 27 : RadiusToken.radius23.value }

    /// "Change number" (316:16628), 123 × 31: a grey capsule with a pencil
    private var changeNumberButton: some View {
        Button(action: changeNumber) {
            HStack(spacing: 5) {
                Text("Change number")
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(Color(hex: 0x212121).opacity(0.93))
                Image(systemName: "pencil")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: 0x212121).opacity(0.93))
            }
            .frame(width: 123, height: 31)
            .background(Capsule().fill(Color(hex: 0xF5F5F5)))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// What the phone card keeps once it has stepped back: the number that was entered (31:1231)
    private var numberRow: some View {
        HStack(spacing: 3.5) {
            Image("PhoneGlyph")
                .frame(width: 21, height: 21)
            Text(stage.number.isEmpty ? "9871156837" : stage.number)
                .font(FigmaFont.walsheim(17))
                .tracking(0.51)
                .foregroundStyle(Color(hex: 0x212121).opacity(0.93))
        }
    }

    // MARK: OTP card (31:1120), 364 × 288

    private var otpCard: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            Text("Enter the one-time password sent to your mobile")
                .font(FigmaFont.walsheim(19))
                .lineSpacing(2)
                .foregroundStyle(Color(hex: 0x212121).opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(width: 260)
                .at(52, 37)
                .opacity(stage.identity ? 0 : 1)

            // The heading it becomes once it steps back (44:2328)
            Text("Verify your identity")
                .font(FigmaFont.reckless(45))
                .tracking(-0.45)
                .foregroundStyle(Color.black.opacity(0.93))
                .multilineTextAlignment(.center)
                .frame(width: 318)
                .at(9, 23)
                .opacity(stage.identity ? 1 : 0)

            ZStack(alignment: .topLeading) {
                OneTimeCodeField(code: $stage.code)
                    .frame(width: 318, height: 67)
                Self.codeText(stage.code)
                    .frame(width: 318, height: 48)
                    .at(0, 11)
                    .allowsHitTesting(false)
                Rectangle()
                    .fill(Color(hex: 0xEBEBEB))
                    .frame(width: 316, height: 1)
                    .at(0, 67)
                OTPResendStatus(sentAt: stage.otpSentAt) {
                    Haptics.tap()
                    stage.code = ""
                    stage.otpSentAt = .now
                }
                .frame(width: 318, height: 40)
                .at(0, 67)
            }
            .frame(width: 318, height: 107, alignment: .topLeading)
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color(hex: 0xC2C2C2).opacity(0.33), lineWidth: 1))
            .at(23, 104)
            .opacity(stage.identity ? 0 : 1)
        }
        // 364 × 288, stepping back to the 336 × 181 heading card (44:2327)
        .frame(width: stage.identity ? 336 : 364, height: stage.identity ? 181 : 288, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 50, x: 0, y: 4)
    }

    // MARK: Identity card (44:2329 → 44:3351), 364 × 255

    /// Black, with the particle sphere (44:2367) turning in it, a little above centre. Five seconds in, the sphere
    /// swells and flattens over the whole card, the card turns white, and the PAN card is revealed from the top down.
    private var identityCard: some View {
        let corner: CGFloat = stage.idCard ? 19 : 27
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        return ZStack(alignment: .topLeading) {
            // Swapped outright: the reveal's last frame is already the finished card
            if stage.idCard {
                Color.white
                    .transition(.identity)
                panCard
                    .transition(.identity)
            } else {
                SphereToCardReveal(start: stage.identityStart) { panCard.background(Color.white) }
                    .transition(.identity)
            }
        }
        .frame(width: 364, height: 255, alignment: .topLeading)
        .clipShape(shape)
        .modifier(RevealBump(start: stage.identityStart, active: stage.identity && !stage.idCard))
        .overlay(shape.strokeBorder(Color(red: 100 / 255, green: 96 / 255, blue: 92 / 255).opacity(stage.idCard ? 0.17 : 0), lineWidth: 0.7))
        .shadow(color: Color.black.opacity(stage.idCard ? 0.11 : 0.08), radius: stage.idCard ? 58 : 50, x: 0, y: 4)
        .task(id: stage.identity) {
            guard stage.identity, !stage.idCard else { return }
            let left = SphereToCardReveal.endsAt - Date().timeIntervalSince(stage.identityStart)
            try? await Task.sleep(for: .seconds(max(0, left)))
            guard !Task.isCancelled else { return }
            // The card is fully revealed by now; this just settles its corners and edge and brings Verify back
            withAnimation(.easeInOut(duration: 0.45)) { stage.idCard = true }
        }
    }

    /// The PAN card that was found (44:3351): department header, ruled panel with name, PAN and date of birth, and the
    /// hologram sticker
    private var panCard: some View {
        let rule = Color(hex: 0x615E5C).opacity(0.22)
        return ZStack(alignment: .topLeading) {
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

            field("Name", "VANGIPURAPPU VENKATA").at(26, 77)
            field("Pan Account Number", "ABCDE1234K").at(26, 122)
            field("Date of Birth", "15/08/1999").at(26, 167)

            HologramSticker()
                .frame(width: 80, height: 78)
                .at(270, 118)
        }
        .frame(width: 364, height: 255, alignment: .topLeading)
    }

    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(FigmaFont.walsheim(12))
                .foregroundStyle(Color(hex: 0x212121).opacity(0.67))
                .frame(height: 15, alignment: .leading)
            Text(value)
                .font(FigmaFont.walsheim(14))
                .tracking(0.7)
                .foregroundStyle(Color.black.opacity(0.95))
                .frame(height: 23, alignment: .leading)
        }
    }

    /// "000-000" (31:1213): typed digits fill in from the left in ink, the rest stay as pale zeros
    private static func codeText(_ code: String) -> some View {
        let digits = Array(code)
        var text = Text("")
        for i in 0..<6 {
            if i == 3 { text = text + Text("-").foregroundColor(Color(hex: 0x212121).opacity(0.35)) }
            let typed = i < digits.count
            text = text + Text(typed ? String(digits[i]) : "0")
                .foregroundColor(Color(hex: 0x212121).opacity(typed ? 0.85 : 0.35))
        }
        return text
            .font(FigmaFont.walsheimMedium(35))
            .tracking(8.05)
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.2), value: code)
    }

    /// The Decade wordmark: at the card's top-left with its mark (555:9693, 26pt at 19, 13), then the card's heading
    /// (31:1013, 45pt at 23, 30). It's drawn once at 45pt and scaled down for the welcome, so it glides between the two.
    private var wordmark: some View {
        let scale: CGFloat = stage.phone ? 1 : 25.999 / 45
        // Gap: Figma #33302D on the mark and wordmark, no token
        let ink = Color(hex: 0x33302D)
        return ZStack(alignment: .topLeading) {
            Image("DecadeMarkPlum")
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(ink)
                .frame(width: 19.606, height: 19.606)
                .offset(x: stage.phone ? -12 : 19, y: stage.phone ? 40 : 18.1)
                .opacity(stage.phone ? 0 : 1)
            Text("Decade")
                .font(FigmaFont.superMedium(45))
                .tracking(-0.45)
                .foregroundStyle(stage.phone ? Color.black.opacity(0.93) : ink)
                .fixedSize()
                .frame(height: 46)
                .scaleEffect(scale, anchor: .topLeading)
                .offset(x: stage.phone ? 23 : 44.15, y: stage.phone ? 30 : 14.2)
        }
        .allowsHitTesting(false)
    }

    /// The watch movement (555:9690): 364 × 362 at the card's foot, the picture 311 square in its middle
    private var media: some View {
        // Gap: Figma #F7F4F4, unbound; surface/sunken-1 (#F5F3F2) is the nearest role
        Color(hex: 0xF7F4F4)
            .frame(width: 364, height: 362)
            .overlay {
                Image("OnboardingWatch")
                    .resizable()
                    .frame(width: 311, height: 311)
                    .offset(x: -0.5, y: 0.5)
            }
    }

    // MARK: Phone form (31:901, 31:904)

    private var phoneForm: some View {
        ZStack(alignment: .topLeading) {
            Text("Add your mobile number linked with official records")
                .font(FigmaFont.walsheim(19))
                .lineSpacing(2)
                .foregroundStyle(Color(hex: 0x212121).opacity(0.85))
                .frame(width: 318, alignment: .leading)
                .at(23, 141)

            ZStack(alignment: .topLeading) {
                PhoneNumberField(number: $stage.number)
                    .frame(width: 300, height: 48)
                    .at(13, 11)
                Rectangle()
                    .fill(Color(hex: 0xEBEBEB))
                    .frame(width: 316, height: 1)
                    .at(0, 67)
                Text("We will send the confirmation on your mobile to confirm it.")
                    .font(FigmaFont.walsheim(13))
                    .lineSpacing(1)
                    .foregroundStyle(Color(hex: 0x212121).opacity(0.47))
                    .frame(width: 286, alignment: .leading)
                    .at(13, 74)
            }
            .frame(width: 318, height: 117, alignment: .topLeading)
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color(hex: 0xC2C2C2).opacity(0.33), lineWidth: 1))
            .at(23, 199)
        }
    }

    // MARK: Buttons

    /// Agree & Continue (555:9681), 218 × 53
    private var agreeButton: some View {
        Button(action: agree) {
            DsText("Agree & Continue", variant: .h6, color: .contentOnColor)
                .frame(width: 218, height: 53)
                // Gap: Figma #341F1B fill, 2 pt black 5% border and 0 3 30 +8 3% shadow; none are tokens
                .background(Capsule().fill(Color(hex: 0x341F1B)))
                .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
                .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
        }
        .buttonStyle(PressScaleStyle())
    }

    /// Verify (31:906), 93 × 45, under the card's right edge
    private var verifyButton: some View {
        Button(action: verify) {
            ZStack {
                Text("Verify")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .offset(x: -9)
                Image("VerifyChevron")
                    .frame(width: 23, height: 23)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 5)
            }
            .frame(width: 93, height: 45)
            .background(Capsule().fill(Color.black))
            .overlay(Capsule().stroke(Color.black.opacity(0.05), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
        }
        .buttonStyle(PressScaleStyle())
    }
}

/// Where the first onboarding surface is: the welcome card, the phone-number form it shrinks into, or the
/// one-time-password card that lands over it, then the identity sphere. `-onboardingPhone` / `-onboardingOTP` /
/// `-onboardingIdentity` open on those stages.
@Observable final class OnboardingIntroStage {
    private static let args = ProcessInfo.processInfo.arguments
    private static let startsAtIdentity = args.contains("-onboardingIdentity") || args.contains("-onboardingPAN")
    private static let startsAtOTP = args.contains("-onboardingOTP") || startsAtIdentity
    /// false = welcome, true = phone number (and beyond)
    var phone = args.contains("-onboardingPhone") || startsAtOTP
    /// The welcome copy goes out quickly; the form comes in once the card has mostly settled
    var welcomeShown = !(args.contains("-onboardingPhone") || startsAtOTP)
    var formShown = args.contains("-onboardingPhone")
    /// The phone card has gone back and the OTP card is up
    var otp = startsAtOTP
    /// The OTP card has become the heading and the sphere card is up
    var identity = startsAtIdentity
    /// The welcome's black version (130:1977): the film on black under a white wordmark, rather than on peach (130:1921).
    /// `-welcomeBlack` opens on it; tapping the film switches between the two.
    var black = args.contains("-welcomeBlack")
    /// The sphere card has turned into the PAN card. `-onboardingPAN` opens on it.
    var idCard = args.contains("-onboardingPAN")
    /// When the sphere card landed; its reveal runs from here
    var identityStart = Date.now
    var number = startsAtOTP ? "9871167820" : ""
    var code = ""
    /// When the code last went out; the resend waits 25s from here
    var otpSentAt = Date.now
}

/// Under the code (31:1215 → 316:16747 → 316:16950): "Confirmation OTP sent" in green for a moment, then a count
/// down to when it can be sent again, then "Did not receive code yet?" with Resend Code
private struct OTPResendStatus: View {
    let sentAt: Date
    let onResend: () -> Void

    private static let wait = 25.0
    private static let confirming = 2.0
    private static let grey = Color(hex: 0x212121).opacity(0.47)

    var body: some View {
        TimelineView(.periodic(from: sentAt, by: 0.25)) { context in
            let elapsed = context.date.timeIntervalSince(sentAt)
            ZStack {
                if elapsed < Self.confirming {
                    Text("Confirmation OTP sent")
                        .foregroundStyle(Color(hex: 0x1DB124))
                        .transition(.opacity)
                } else if elapsed < Self.wait {
                    let left = Int(ceil(Self.wait - elapsed))
                    Text("Resend pin in \(left) secs")
                        .foregroundStyle(Self.grey)
                        .contentTransition(.numericText(countsDown: true))
                        .transition(.opacity)
                } else {
                    HStack(spacing: 0) {
                        Text("Did not receive code yet?")
                            .foregroundStyle(Self.grey)
                        Spacer(minLength: 0)
                        Button(action: onResend) {
                            HStack(spacing: 4) {
                                Text("Resend Code")
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundStyle(Color(hex: 0x212121).opacity(0.93))
                            .frame(height: 30)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 17)
                    .transition(.opacity)
                }
            }
            .font(FigmaFont.walsheim(13))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeOut(duration: 0.3), value: elapsed < Self.confirming)
            .animation(.easeOut(duration: 0.3), value: elapsed < Self.wait)
        }
    }
}

/// The big mobile-number entry (31:905): digits only, at most 10, widely tracked, with the number pad up as soon as
/// it appears. A UIKit field so its first-responder work stays out of the morphing card's SwiftUI updates.
private struct PhoneNumberField: UIViewRepresentable {
    @Binding var number: String

    private static let font = UIFont(name: "GTWalsheimTrial-Rg", size: 35) ?? .systemFont(ofSize: 35)
    private static let ink = UIColor(red: 33 / 255, green: 33 / 255, blue: 33 / 255, alpha: 0.85)

    func makeUIView(context: Context) -> UITextField {
        // Takes focus as soon as it's on screen, retrying through the morph
        let field = OneTimeCodeField.FocusOnArrival()
        field.keyboardType = .numberPad
        field.textContentType = .telephoneNumber
        field.font = Self.font
        field.textColor = Self.ink
        field.tintColor = Self.ink
        field.defaultTextAttributes[.kern] = 8.05
        field.attributedPlaceholder = NSAttributedString(string: "9871156837", attributes: [
            .font: Self.font, .kern: 8.05, .foregroundColor: Self.ink.withAlphaComponent(0.18),
        ])
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        if field.text != number { field.text = number }
    }

    func makeCoordinator() -> Coordinator { Coordinator(number: $number) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let number: Binding<String>
        init(number: Binding<String>) { self.number = number }

        @objc func changed(_ field: UITextField) { number.wrappedValue = field.text ?? "" }

        func textField(_ field: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard string.allSatisfy(\.isNumber) else { return false }
            let current = field.text ?? ""
            guard let r = Range(range, in: current) else { return false }
            return current.replacingCharacters(in: r, with: string).count <= 10
        }
    }
}

/// Takes the one-time code from the number pad (or the "From Messages" suggestion): an invisible field, up to six
/// digits, drawn by the card's "000-000" instead
private struct OneTimeCodeField: UIViewRepresentable {
    @Binding var code: String

    func makeUIView(context: Context) -> UITextField {
        let field = FocusOnArrival()
        field.keyboardType = .numberPad
        field.textContentType = .oneTimeCode
        field.textColor = .clear
        field.tintColor = .clear
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        return field
    }

    /// Takes focus the moment it's on screen (for the code field, straight over from the phone field, so the number
    /// pad never drops)
    final class FocusOnArrival: UITextField {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            take(tries: 12)
        }

        /// Mid-transition the field can refuse focus for a frame or two, so it keeps asking briefly
        private func take(tries: Int) {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.window != nil, !self.isFirstResponder else { return }
                if !self.becomeFirstResponder(), tries > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.take(tries: tries - 1) }
                }
            }
        }
    }

    func updateUIView(_ field: UITextField, context: Context) {
        if field.text != code { field.text = code }
    }

    func makeCoordinator() -> Coordinator { Coordinator(code: $code) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let code: Binding<String>
        init(code: Binding<String>) { self.code = code }

        @objc func changed(_ field: UITextField) { code.wrappedValue = field.text ?? "" }

        func textField(_ field: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard string.allSatisfy(\.isNumber) else { return false }
            let current = field.text ?? ""
            guard let r = Range(range, in: current) else { return false }
            return current.replacingCharacters(in: r, with: string).count <= 6
        }
    }
}

/// A muted, endlessly looping video from the app bundle, filling its frame. Shows nothing if the file isn't bundled.
struct LoopingVideo: UIViewRepresentable {
    let name: String
    var ext = "mp4"

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return view }
        let player = AVQueuePlayer()
        player.isMuted = true
        // Plays alongside whatever else is playing and never takes over audio
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        view.looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        player.play()
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {}

    final class PlayerView: UIView {
        var looper: AVPlayerLooper?
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

#Preview {
    OnboardingIntroView(onContinue: {}, stage: OnboardingIntroStage())
}

/// The swell that travels down the identity card with the reveal (`RevealBump.metal`). Drawn with room around the
/// card so its sides can bow out past their edges.
private struct RevealBump: ViewModifier {
    let start: Date
    let active: Bool
    private static let room: CGFloat = 12

    func body(content: Content) -> some View {
        // One structure throughout, paused once done: swapping views here would re-insert the card and replay its
        // entrance
        TimelineView(.animation(paused: !active)) { context in
            let bump = active ? SphereToCardReveal.bump(context.date.timeIntervalSince(start)) : (y: 0, strength: 0)
            content
                .padding(Self.room)
                .distortionEffect(
                    ShaderLibrary.revealBump(
                        .float(bump.y + Self.room), .float(182 + Self.room), .float(46), .float(bump.strength)
                    ),
                    maxSampleOffset: CGSize(width: Self.room, height: Self.room),
                    isEnabled: bump.strength > 0
                )
                .padding(-Self.room)
        }
    }
}
