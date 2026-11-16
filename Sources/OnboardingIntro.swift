import AVFoundation
import SwiftUI

/// The first onboarding screen and the one after it, as one surface.
///
/// Welcome — Figma "iPhone 14 Plus - 439" (802:5409): the reader's picture across the top of the page under the Decade
/// mark, "Your Research Backed Personal Advisor" and a line about it under that, a dark Agree and Continue, and a
/// link to the terms.
///
/// Phone — Figma "iPhone 14 Plus - 395" (679:22978): tapping Agree and Continue doesn't slide in a new page. The
/// page shrinks into a card that fits the phone-number form, the picture and copy fade away, the Decade wordmark
/// glides to the card's top-left, a full-width Verify comes in under the card, and the number pad comes up.
///
/// One-time password — Figma "iPhone 14 Plus - 288" (31:1021): Verify sends the phone card back, smaller, keeping just
/// the number that was entered, while the OTP card drops in over it from 1.3× to its size. The number pad stays up.
///
/// KYC — Figma "iPhone 14 Plus - 397" (679:23694): the second Verify puts the keyboard away and does it again. The
/// OTP card slips away behind with the phone card, and a white "Confirm kyc" card lands over them from 1.3× with a
/// slowly turning particle sphere in its box. Five seconds later the sphere swells, flattens over the box and
/// resolves, top to bottom, into the PAN card that was found, with a live hologram. The card then grows into
/// "Confirm your details" (679:23796) with "Change details" under the PAN card, and Verify becomes Confirm.
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
            .overlay {
                if stage.showsTerms {
                    OnboardingTermsSheet(top: Self.statusBarHeight + 16) {
                        withAnimation(.spring(duration: 0.45, bounce: 0.12)) { stage.showsTerms = false }
                    }
                }
            }
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
                // The welcome fills the screen; the phone card is what it shrinks into
                .at(stage.otp ? 35 : stage.phone ? 13 : -Self.margin, stage.otp ? 0 : stage.phone ? 4 : -(Self.statusBarHeight + 13))
                // Slips away behind once the OTP card has stepped back over it
                .scaleEffect(stage.identity ? 0.9 : 1, anchor: .top)
                .opacity(stage.identity ? 0 : 1)

            // Lands from 1.3× over the phone card as it steps back
            if stage.otp {
                otpCard
                    .at(13, 51)
                    // Slips away behind in turn once the KYC card has landed over it
                    .scaleEffect(stage.identity ? 0.9 : 1, anchor: .top)
                    .opacity(stage.identity ? 0 : 1)
                    .transition(.scale(scale: 1.3).combined(with: .opacity))
            }

            // And again over the OTP card
            if stage.identity {
                kycCard
                    .at(13, 4)
                    // Solid almost at once, so the cards behind never show through while it scales in
                    .transition(.scale(scale: 1.3).combined(with: .opacity.animation(.easeOut(duration: 0.12))))
                    // Over the Verify button as it fades
                    .zIndex(1)
            }

            agreeButton
                .at(19, 558)
                .opacity(stage.welcomeShown ? 1 : 0)
                .scaleEffect(stage.welcomeShown ? 1 : 0.96)
                .allowsHitTesting(!stage.phone)

            termsLink
                .at(81, 701)
                .opacity(stage.welcomeShown ? 1 : 0)
                .allowsHitTesting(!stage.phone)

            verifyButton
                // Full width under the phone card (679:23205), then small under the later cards' right edge
                .at(verifyWide ? 23 : 280, stage.identity ? 687 : stage.otp ? 358 : 356)
                .opacity(verifyShown ? 1 : 0)
                .scaleEffect(verifyShown ? 1 : 0.9)
                // Waits for the PAN card while the sphere turns
                .allowsHitTesting(verifyShown && (!stage.identity || stage.idCard))
        }
        .frame(width: 390, alignment: .topLeading)
        // The flow ignores the safe area: 13pt below the status bar, as in Figma
        .padding(.top, Self.statusBarHeight + 13)
    }

    /// Under the phone and OTP forms and the KYC card
    private var verifyShown: Bool {
        stage.identity || stage.formShown || stage.otp
    }

    /// Full width under the phone card and the KYC card, small under the OTP card
    private var verifyWide: Bool { !stage.otp || stage.identity }

    /// The app window's top inset. Not the key window's: while the number pad is up that's the keyboard's, with none.
    private static var statusBarHeight: CGFloat {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        return scene?.windows.first?.safeAreaInsets.top ?? 44
    }

    private static var screenSize: CGSize {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        return scene?.screen.bounds.size ?? CGSize(width: 390, height: 844)
    }

    /// The 390-wide layout sits in the middle of the screen; this is what's left on each side
    private static var margin: CGFloat { (screenSize.width - 390) / 2 }
    /// How much taller the status bar is than the frame's 44
    private static var drop: CGFloat { statusBarHeight - 44 }

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

            // The welcome's and the phone card's surface/base, giving way to the blobs once the OTP card lands
            ColorScale.surfaceBase
                .opacity(stage.otp && !stage.identity ? 0 : 1)
        }
    }

    // MARK: Card — 364 × 640 (130:1924) shrinking to 364 × 339 (31:900), then back to 321 × 299 (31:1217)

    private var card: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            // The welcome (802:5409): the reader's picture across the top under the Decade mark and its rule, then the
            // heading and its line on surface/base
            Group {
                ColorScale.surfaceBase

                // Gap: Figma #FDF6EE behind the picture, unbound
                Color(hex: 0xFDF6EE)
                    .frame(width: Self.screenSize.width, height: 351 + Self.drop)
                    .overlay(alignment: .topLeading) {
                        let fit = Self.screenSize.width / 390
                        Image("OnboardingReader")
                            .resizable()
                            .frame(width: 481 * fit, height: 579 * fit)
                            .offset(x: -129 * fit, y: -52 * fit + Self.drop)
                    }
                    .clipped()

                // Gap: Figma black 57%, 1 pt, no token
                Color.black.opacity(0.57)
                    .frame(width: 358, height: 1)
                    .at(13 + Self.margin, 101 + Self.drop)

                // Gap: Reckless Medium 45/49 in #33302D; H1 is Regular and the colour is unbound
                GapText("Your Research Backed Personal Advisor", family: .reckless, medium: true, size: 45, lineHeight: 49, color: Color(hex: 0x33302D))
                    .frame(width: 355, alignment: .leading)
                    .at(18 + Self.margin, 380 + Self.drop)

                DsText("Thoughtful wealth management for people who’ve outgrown generic advice.", variant: .p3, color: .contentSecondary)
                    .frame(width: 312, alignment: .leading)
                    .at(18 + Self.margin, 542 + Self.drop)
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
        // Gap: Shadow/1 under the phone card is 0 4 100 +12 at 5%; SwiftUI can't draw the spread
        .shadow(color: Color.black.opacity(stage.phone && !stage.otp ? 0.05 : 0.08), radius: 50, x: 0, y: 4)
    }

    private var cardSize: CGSize {
        stage.otp ? CGSize(width: 321, height: 298.95) : stage.phone ? CGSize(width: 364, height: 339) : Self.screenSize
    }

    private var cardCorner: CGFloat { stage.otp ? 23 : stage.phone ? 27 : 0 }

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
        }
        .frame(width: 364, height: 288, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 50, x: 0, y: 4)
    }

    // MARK: KYC card (679:23697 → 679:23799), 364 × 512 growing to 364 × 572

    /// "Confirm kyc" over a rule, the heading, and the box the sphere turns in. Once the PAN card is found the heading
    /// changes, "Personal details" comes in over the box and "Change details" under it, and the card grows to fit.
    private var kycCard: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            Image("OnboardingKycCard")
                .frame(width: 24.924, height: 21)
                .at(17, 16)
            // Gap: Md 19/29 in black has no text style
            GapText("Confirm kyc", family: .walsheim, medium: true, size: 19, lineHeight: 29, color: Color.black)
                .fixedSize()
                .at(53, 12)

            // Gap: Figma black 57%, 1 pt, no token
            Color.black.opacity(0.57)
                .frame(width: 328, height: 1)
                .at(18, 52)

            // Gap: Reckless Medium 45/49 in #33302D; H1 is Regular and the colour is unbound. Broken as in the frame:
            // left alone, iOS evens the two lines out
            GapText("Verify your pan\ndetails", family: .reckless, medium: true, size: 45, lineHeight: 49, color: Color(hex: 0x33302D))
                .frame(width: 318, alignment: .leading)
                .at(17, 76)
                .opacity(stage.idCard ? 0 : 1)
            GapText("Confirm your\ndetails", family: .reckless, medium: true, size: 45, lineHeight: 49, color: Color(hex: 0x33302D))
                .frame(width: 318, alignment: .leading)
                .at(17, 76)
                .opacity(stage.idCard ? 1 : 0)

            DsText("Personal details", variant: .h4)
                .fixedSize()
                .at(17, 199)
                .opacity(stage.idCard ? 1 : 0)

            // 802:5818 / 802:5673: the earlier 364 × 255 card, drawn at 330 wide
            identityCard
                .scaleEffect(330.0 / 364, anchor: .topLeading)
                .frame(width: 330, height: 231.882, alignment: .topLeading)
                .at(17, 245)

            changeDetailsButton
                .at(17, 500)
                .opacity(stage.idCard ? 1 : 0)
                .allowsHitTesting(stage.idCard)
        }
        .frame(width: 364, height: stage.idCard ? 572 : 512, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        // Gap: Shadow/1 (0 4 100 +12 at 5%) then Shadow/2 (0 4 97 +7 at 7%); SwiftUI can't draw the spread
        .shadow(color: Color.black.opacity(stage.idCard ? 0.07 : 0.05), radius: 50, x: 0, y: 4)
    }

    /// "Change details" (802:5687), 330 × 45: outlined, under the PAN card
    private var changeDetailsButton: some View {
        Button {
            Haptics.tap()
        } label: {
            Text("Change details")
                .font(FigmaFont.walsheimMedium(17))
                .foregroundStyle(Color(hex: 0x212121))
                .frame(width: 330, height: 45)
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().strokeBorder(ColorScale.borderSubtle, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
        }
        .buttonStyle(PressScaleStyle())
    }

    /// The box in the KYC card: the particle sphere turning in it, a little above centre. Five seconds in, the sphere
    /// swells and flattens over the whole box and the PAN card is revealed from the top down.
    private var identityCard: some View {
        let shape = RoundedRectangle(cornerRadius: 19, style: .continuous)
        return ZStack(alignment: .topLeading) {
            // Swapped outright: the reveal's last frame is already the finished card
            if stage.idCard {
                panCard
                    .background(Self.panTint)
                    .transition(.identity)
            } else {
                SphereToCardReveal(start: stage.identityStart) { panCard.background(Self.panTint) }
                    .transition(.identity)
            }
        }
        .frame(width: 364, height: 255, alignment: .topLeading)
        .clipShape(shape)
        .modifier(RevealBump(start: stage.identityStart, active: stage.identity && !stage.idCard))
        .overlay(shape.strokeBorder(ColorScale.borderSubtle, lineWidth: 0.7))
        .task(id: stage.identity) {
            guard stage.identity, !stage.idCard else { return }
            let left = SphereToCardReveal.endsAt - Date().timeIntervalSince(stage.identityStart)
            try? await Task.sleep(for: .seconds(max(0, left)))
            guard !Task.isCancelled else { return }
            // The card is fully revealed by now; this brings in the rest of the KYC card around it
            withAnimation(.easeInOut(duration: 0.45)) { stage.idCard = true }
        }
    }

    /// Gap: the PAN card's faint cool tint over white (802:5673), 13%; the frame's gradient has no token
    private static let panTint = ZStack {
        Color.white
        LinearGradient(colors: [Color(red: 182 / 255, green: 183 / 255, blue: 205 / 255).opacity(0.13),
                                Color(red: 173 / 255, green: 202 / 255, blue: 225 / 255).opacity(0.13)],
                       startPoint: .leading, endPoint: .trailing)
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

    /// The Decade wordmark with its mark: at the welcome's top-left (802:5413, 26pt at 15, 59), then a touch smaller at
    /// the phone card's (679:23675, 24.2pt at 17, 13). It's drawn once at 45pt and scaled down, so it glides between the two.
    private var wordmark: some View {
        let scale: CGFloat = (stage.phone ? 24.206 : 25.999) / 45
        // Gap: Figma #33302D on the welcome's mark and wordmark, black on the phone card's; neither is a token
        let ink = stage.phone ? Color.black : Color(hex: 0x33302D)
        let markSize: CGFloat = stage.phone ? 18.254 : 19.606
        return ZStack(alignment: .topLeading) {
            Image("DecadeMarkPlum")
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(ink)
                .frame(width: markSize, height: markSize)
                .offset(x: stage.phone ? 17 : 15 + Self.margin, y: stage.phone ? 17.76 : 64.1 + Self.drop)
            Text("Decade")
                .font(FigmaFont.superMedium(45))
                .tracking(-0.45)
                .foregroundStyle(ink)
                .fixedSize()
                .frame(height: 46)
                .scaleEffect(scale, anchor: .topLeading)
                .offset(x: stage.phone ? 40.42 : 40.15 + Self.margin, y: stage.phone ? 14.1 : 60.2 + Self.drop)
        }
        .allowsHitTesting(false)
    }

    // MARK: Phone form (31:901, 31:904)

    private var phoneForm: some View {
        ZStack(alignment: .topLeading) {
            // Gap: Figma black 57%, 1 pt, no token
            Color.black.opacity(0.57)
                .frame(width: 328, height: 1)
                .at(18, 52)

            DsText("Add your mobile number", variant: .h4)
                .fixedSize()
                .at(17, 149)

            ZStack(alignment: .topLeading) {
                // Gap: Rg 35/48 at 7% tracking has no text style
                GapText("+91", family: .walsheim, medium: false, size: 35, lineHeight: 48, trackingPercent: 7, color: ColorScale.contentTertiary)
                    .fixedSize()
                    .at(12, 11)
                PhoneNumberField(number: $stage.number)
                    .frame(width: 245, height: 48)
                    .at(77, 11)
                Rectangle()
                    .fill(Color(hex: 0xEBEBEB))
                    .frame(width: 329, height: 1)
                    .at(0, 67)
                Text("We will send the confirmation on your mobile to confirm it.")
                    .font(FigmaFont.walsheim(13))
                    .lineSpacing(1)
                    .foregroundStyle(Color(hex: 0x212121).opacity(0.47))
                    .frame(width: 286, alignment: .leading)
                    .at(13, 74)
            }
            .frame(width: 330, height: 117, alignment: .topLeading)
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color(hex: 0xC2C2C2).opacity(0.33), lineWidth: 1))
            .at(17, 195)
        }
    }

    // MARK: Buttons

    /// Agree and Continue (802:5419), 352 × 51
    private var agreeButton: some View {
        Button(action: agree) {
            DsText("Agree and Continue", variant: .h6, color: .contentOnColor)
                .frame(width: 352, height: 51)
                // Gap: Figma #1F1513 fill, 2 pt black 5% border and 0 3 30 +8 3% shadow; none are tokens
                .background(Capsule().fill(Color(hex: 0x1F1513)))
                .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
                .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
        }
        .buttonStyle(PressScaleStyle())
    }

    /// "Read the terms and conditions" with its chevron (802:5458), 229 × 21
    private var termsLink: some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(duration: 0.5, bounce: 0.18)) { stage.showsTerms = true }
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
    }

    /// Verify: 344 × 45 under the phone card (679:23205) and at the foot of the KYC step (802:5552), where it turns
    /// into Confirm; 93 × 45 under the OTP card's right edge (31:906)
    private var verifyButton: some View {
        Button(action: verify) {
            ZStack {
                Text(stage.idCard ? "Confirm" : "Verify")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .offset(x: verifyWide ? -0.5 : -9)
                Image("VerifyChevron")
                    .frame(width: 23, height: 23)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 5)
            }
            .frame(width: verifyWide ? 344 : 93, height: 45)
            // Gap: Figma #1F1513 fill, 2 pt black 5% border and 0 3 30 +8 3% shadow; none are tokens
            .background(Capsule().fill(Color(hex: 0x1F1513)))
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
    /// The terms sheet is up over the welcome. `-onboardingTerms` opens on it.
    var showsTerms = args.contains("-onboardingTerms")
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

/// The big mobile-number entry (679:23200): digits only, at most 10, with the number pad up as soon as
/// it appears. A UIKit field so its first-responder work stays out of the morphing card's SwiftUI updates.
private struct PhoneNumberField: UIViewRepresentable {
    @Binding var number: String

    private static let font = UIFont(name: "GTWalsheimTrial-Rg", size: 35) ?? .systemFont(ofSize: 35)
    /// content/secondary
    private static let ink = UIColor(ColorScale.contentSecondary)

    func makeUIView(context: Context) -> UITextField {
        // Takes focus as soon as it's on screen, retrying through the morph
        let field = OneTimeCodeField.FocusOnArrival()
        field.keyboardType = .numberPad
        field.textContentType = .telephoneNumber
        field.font = Self.font
        field.textColor = Self.ink
        field.tintColor = Self.ink
        field.defaultTextAttributes[.kern] = 2.45
        field.attributedPlaceholder = NSAttributedString(string: "9871156837", attributes: [
            .font: Self.font, .kern: 2.45, .foregroundColor: Self.ink.withAlphaComponent(0.25),
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
