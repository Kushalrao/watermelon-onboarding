import SwiftUI
import UserNotifications

/// The status bar's height. The onboarding runs edge to edge, so the flow measures it once, outside its screens,
/// and hands it down. (Asking the window for it while a screen is being drawn makes UIKit lay the window out in
/// the middle of SwiftUI's own pass; SwiftUI reports a cycle and that screen stops taking its state changes.)
private struct OnboardingTopKey: EnvironmentKey {
    static let defaultValue: CGFloat = 62
}

extension EnvironmentValues {
    var onboardingTop: CGFloat {
        get { self[OnboardingTopKey.self] }
        set { self[OnboardingTopKey.self] = newValue }
    }
}

/// "Lets personalise your advisor" (817:10812): once the mutual funds are connected. The screen comes in, the words
/// come up, stay long enough to read, and go; then the first of the personalising screens takes over.
struct OnboardingPersonaliseIntroView: View {
    let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 0 before the words arrive, 1 while they're up, 2 once they've gone
    @State private var beat = 0
    @Environment(\.onboardingTop) private var top

    var body: some View {
        ZStack(alignment: .topLeading) {
            ColorPrimitives.accentLavender900

            VStack(alignment: .leading, spacing: 0) {
                GapText("Lets personalise\nyour advisor", family: .reckless, medium: false, size: 47, lineHeight: 51, color: ColorPrimitives.accentLavender50)
                    .frame(width: 348, alignment: .leading)
                GapText("We’ll now quickly guide you through the\nbasics to give you a head start.", family: .walsheim, medium: false, size: 17, lineHeight: 23, color: ColorPrimitives.accentLavender200)
                    .frame(width: 344, alignment: .leading)
                    .padding(.top, 19)
            }
            .at(21, 332 - 44 + top)
            .frame(width: 390, alignment: .topLeading)
            .frame(maxWidth: .infinity)
            .opacity(beat == 1 ? 1 : 0)
            .offset(y: reduceMotion ? 0 : beat == 0 ? 14 : beat == 2 ? -10 : 0)
            .blur(radius: reduceMotion || beat == 1 ? 0 : 6)
            .accessibilityElement(children: .combine)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .task {
            // In once the screen's colour has arrived, up for long enough to read both lines, then out
            try? await Task.sleep(for: .seconds(0.45))
            withAnimation(.easeOut(duration: 0.7)) { beat = 1 }
            try? await Task.sleep(for: .seconds(3.3))
            withAnimation(.easeIn(duration: 0.5)) { beat = 2 }
            try? await Task.sleep(for: .seconds(0.55))
            guard !Task.isCancelled else { return }
            onContinue()
        }
    }
}

/// The ground the two advisor screens share (1027:11565): near white, with three pale shapes blurred right out
/// behind it, a green-yellow down the middle, a grey-green low on the right and a grey high on the right
struct AdvisorDawnBackground: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: 0xFCFCFC)
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Color(hex: 0xF0F6DF))
                    .frame(width: 165, height: 378)
                    .at(97, 118)
                Ellipse().fill(Color(hex: 0xD8E0DB))
                    .frame(width: 119.377, height: 273.036)
                    .rotationEffect(.degrees(-86.94))
                    .frame(width: 279.025, height: 133.796)
                    .at(166.38, 486.38)
                Ellipse().fill(Color(hex: 0xF0F0F0))
                    .frame(width: 359.537, height: 446)
                    .rotationEffect(.degrees(-3.73))
                    .frame(width: 387.814, height: 468.464)
                    .at(171, -19)
            }
            .frame(width: 390, height: 844, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .blur(radius: 72)
            Color.white.opacity(0.09)
        }
        // The screen it's on already runs edge to edge
        .accessibilityHidden(true)
    }
}

/// "Congrats! you have a proactive personal advisor now" (1027:11565): after the second report's Understood. The
/// words come up, stay long enough to read, and go; then the advisor is introduced. The onboarding's last screen,
/// "You’re in, have a wealthy life" (973:17796), is the same thing with other words.
struct OnboardingCongratsView: View {
    /// The words, a line each as the frame breaks them, where their top sits on the frame, and how they're read out
    var text = "Congrats! you\nhave a proactive\npersonal advisor\nnow"
    var textTop: CGFloat = 344
    var label = "Congrats! you have a proactive personal advisor now"
    /// The sea behind the words, which are set in white to stand on it
    var water = false
    let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.onboardingTop) private var top
    /// 0 before the words arrive, 1 while they're up, 2 once they've gone
    @State private var beat = 0
    /// When the light began coming at the screen, at the end, on water
    @State private var flareStart: Date?

    var body: some View {
        ZStack(alignment: .top) {
            if water {
                UnderwaterBackground(flareStart: flareStart)
            } else {
                AdvisorDawnBackground()
            }

            Group {
                if water {
                    // The frame's Medium, 45/51, in white on the deep water
                    Text(text)
                        .font(.custom("RecklessStandardS-TRIAL-Medium", fixedSize: 45))
                        .lineSpacing(51 - UIFont(name: "RecklessStandardS-TRIAL-Medium", size: 45)!.lineHeight)
                        .foregroundStyle(Color.white)
                } else {
                    // Gap: Reckless Medium 45/51 in #33302D has no text style or content token
                    GapText(text, family: .reckless, medium: true, size: 45, lineHeight: 51, color: Color(hex: 0x33302D))
                }
            }
                .multilineTextAlignment(.center)
                .frame(width: 352)
                .padding(.top, textTop - 44 + top)
                .opacity(beat == 1 ? 1 : 0)
                .offset(y: reduceMotion ? 0 : beat == 0 ? 14 : beat == 2 ? -10 : 0)
                .blur(radius: reduceMotion || beat == 1 ? 0 : 6)
                .accessibilityLabel(label)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .task {
            try? await Task.sleep(for: .seconds(0.45))
            // On water the words come in slowly
            let arrive = water ? 1.4 : 0.7
            withAnimation(.easeOut(duration: arrive)) { beat = 1 }
            // Up, and read, for three seconds once it's fully in
            try? await Task.sleep(for: .seconds(arrive + 3.0))
            withAnimation(.easeIn(duration: 0.5)) { beat = 2 }
            if water && !reduceMotion {
                // The shafts of light come at the screen until it's white, and the next screen arrives out of that
                flareStart = Date()
                try? await Task.sleep(for: .seconds(UnderwaterBackground.flareDuration))
            } else {
                try? await Task.sleep(for: .seconds(0.55))
            }
            guard !Task.isCancelled else { return }
            onContinue()
        }
    }
}

/// Under the sea, moving: the picture of the surface, the deep and the sand under `underwaterLight`
/// (`WaterCaustics.metal`), which sways it and lays the glints, the shafts of sunlight and the net of light on it
struct UnderwaterBackground: View {
    /// Set at the end: from then the light comes at the screen, to white in `flareDuration`
    var flareStart: Date?
    static let flareDuration = 1.3
    @State private var start = Date()

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSince(start)
                let flare = flareStart.map { min(max(context.date.timeIntervalSince($0) / Self.flareDuration, 0), 1) } ?? 0
                Image("WaterSea")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .layerEffect(
                        ShaderLibrary.underwaterLight(.float2(geo.size), .float(t), .float(flare)),
                        maxSampleOffset: CGSize(width: 16, height: 16)
                    )
            }
        }
        .background(Color(hex: 0x0A3A7A))
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Water over rock, moving: the rock's picture under the caustics shader (`WaterCaustics.metal`), stretched to the
/// screen as the design it came from stretches it
struct WaterCausticsBackground: View {
    @State private var start = Date.now

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSince(start)
                // The rock's colours: a soft copy of the reference photograph, its light greens and blues lifted a
                // little, cut to the screen's shape clear of its dark corner. It's drawn a little larger than the
                // screen and drifts very slowly under the water, so its dark parts move too.
                Image("WaterRock")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: geo.size.width * 1.14, height: geo.size.height * 1.14)
                    .offset(x: geo.size.width * 0.06 * sin(t * 0.11), y: geo.size.height * 0.06 * cos(t * 0.08))
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .layerEffect(
                        ShaderLibrary.waterCaustics(.float2(geo.size), .float(t)),
                        maxSampleOffset: CGSize(width: 8, height: 8)
                    )
            }
        }
        .background(Color(hex: 0x0B1420))
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// The advisor, and then where she may reach you. First "Arindam, meet your personal advisor" (973:16066): her
/// portrait with "Hello Arindam" pinned to its foot, the heading, a line under it, and "Great!". On "Great!" the
/// portrait goes up into the corner as her avatar, says its piece in a bubble, and the permissions card comes up
/// under it (973:16336): each line has a switch, and turning one on asks for whatever that channel needs. App
/// notifications need the system's permission, so the system asks, and the switch only stays on if it's given.
struct OnboardingCommunicationsView: View {
    /// Starts on the introduction; without it, straight on the permissions
    var introduces = false
    let onContinue: () -> Void

    private enum Stage { case meeting, permissions }
    private enum Channel: String, CaseIterable {
        case app = "Advisory notifications", whatsApp = "WhatsApp"
    }

    @State private var stage = Stage.permissions
    @State private var shown = false
    @State private var allowed: Set<Channel> = []
    /// How many of the notifications have come in
    @State private var arrived = 0
    /// Her message has come in, on the permissions
    @State private var bubbleShown = false
    /// The card has come up, a second after she's finished saying it
    @State private var cardUp = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.onboardingTop) private var top

    private static let move = Animation.spring(response: 0.6, dampingFraction: 0.84)
    /// The portrait is 186 × 192; as the avatar it's 63 across (973:16944)
    private static let avatarScale: CGFloat = 63 / 186

    var body: some View {
        let meeting = stage == .meeting
        // Laid out on the frame's 390, centred on the screen
        let side = (UIScreen.main.bounds.width - 390) / 2
        return ZStack(alignment: .topLeading) {
            AdvisorDawnBackground()

            Color.black.opacity(0.57)
                .frame(width: 372, height: 1)
                .at(side + 9, 48 - 44 + top)
                .opacity(meeting && shown ? 1 : 0)

            // 973:16266 → 973:16944: the portrait, and then the same picture small in the corner
            Image("MeetAdvisorPortrait")
                .frame(width: 394, height: 400)
                .frame(width: 186, height: 192)
                // Shadow/2 (0 4 97 +7 at 7%); SwiftUI can't draw the spread
                .shadow(color: Color.black.opacity(meeting ? 0.07 : 0), radius: 48.5, x: 0, y: 4)
                .scaleEffect(meeting ? (shown || reduceMotion ? 1 : 0.94) : Self.avatarScale)
                .position(
                    x: side + (meeting ? 195 : 15 + 31.5),
                    y: (meeting ? 106 + 96 : 61 + 32.5) - 44 + top
                )
                .opacity(shown ? 1 : 0)
                .accessibilityLabel("Your advisor")

            // 973:17040: what she says, over the foot of her picture; it arrives as the chat's bubbles do, once the
            // picture has settled in its corner
            if bubbleShown {
                AdvisorBubble(
                    text: "\(AppUser.name), I’ll reach out when something needs your attention. Choose where I can reach you.",
                    typed: true,
                    onTyped: bringCard
                )
                    .at(side + 35, 104 - 44 + top)
                    .transition(.scale(scale: 0.9, anchor: .bottomLeading).combined(with: .opacity).combined(with: .offset(y: 12)))
                    .zIndex(1)
            }

            Group {
                // 973:16327: 178 × 42, over the portrait's foot
                HStack(spacing: 8) {
                    Image("OnboardingWave")
                        .resizable()
                        .frame(width: 18.198, height: 18.426)
                    Text("Hello \(AppUser.name)")
                        .font(FigmaFont.walsheimMedium(19.45))
                        .foregroundStyle(Color.black)
                        .fixedSize()
                }
                .frame(width: 178, height: 42)
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().strokeBorder(ColorScale.borderSubtle, lineWidth: 0.7))
                .at(side + 106, 283 - 44 + top)

                // Gap: Reckless Medium 45/43 in #33302D has no text style or content token
                GapText("\(AppUser.name), meet\nyour personal\nadvisor", family: .reckless, medium: true, size: 45, lineHeight: 43, color: Color(hex: 0x33302D))
                    .multilineTextAlignment(.center)
                    .frame(width: 352)
                    .at(side + 19, 362 - 44 + top)
                    .accessibilityLabel("\(AppUser.name), meet your personal advisor")

                GapText("We’ll now quickly guide you through the\nbasics to give you a head start.", family: .walsheim, medium: false, size: 17, lineHeight: 23, color: ColorScale.contentSecondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 348)
                    .at(side + 21, 504 - 44 + top)
            }
            .opacity(meeting && shown ? 1 : 0)
            .offset(y: meeting ? (shown || reduceMotion ? 0 : 14) : -24)
            .accessibilityHidden(!meeting)

            // 973:16780: 364 × 494, 181 under the status bar
            if !meeting && cardUp {
                card
                    .at(side + 13, 225 - 44 + top)
                    .transition(.offset(y: 60).combined(with: .opacity))
            }

            // 973:16259 and 973:16343: the same button, "Great!" and then "Continue"
            Button {
                Haptics.tap()
                if meeting {
                    withAnimation(Self.move) { stage = .permissions }
                } else {
                    onContinue()
                }
            } label: {
                Text(meeting ? "Great!" : "Continue")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .contentTransition(.opacity)
                    .offset(x: 0.5)
                    .frame(width: 344, height: 49)
                    .background(Capsule().fill(Color(hex: 0x1F1513)))
                    .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
            }
            .buttonStyle(PressScaleStyle())
            .at(side + 23, 738 - 44 + top)
            // Away while she speaks, and back with the card
            .opacity(shown && (meeting || cardUp) ? 1 : 0)
            .allowsHitTesting(meeting || cardUp)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea()
        .onAppear {
            if introduces { stage = .meeting }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86).delay(0.1)) { shown = true }
        }
        .task(id: stage) {
            guard stage == .permissions, !bubbleShown else { return }
            try? await Task.sleep(for: .seconds(0.7))
            guard !Task.isCancelled else { return }
            Haptics.thresholdCrossed()
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) { bubbleShown = true }
        }
    }

    /// A second after her message is all there, the card comes up under it
    private func bringCard() {
        Task {
            try? await Task.sleep(for: .seconds(1))
            Haptics.tap()
            withAnimation(Self.move) { cardUp = true }
        }
    }

    // MARK: The card, 364 × 494

    private var card: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Color.white

            // 973:16781: the phone, 129 higher than its own box, so the card shows its notifications
            phone
                .frame(width: 364, height: 354, alignment: .top)
                .offset(y: -129)
                .frame(width: 364, height: 225, alignment: .top)
                .clipped()
                .accessibilityHidden(true)

            DsText("Select permissions you want\nadvisor to communicate from", variant: .h4)
                .frame(width: 326, alignment: .leading)
                .at(19, 252)
                .accessibilityLabel("Select permissions you want advisor to communicate from")

            channels
                .at(11, 337)
        }
        .frame(width: 364, height: 494, alignment: .topLeading)
        .clipShape(shape)
        .shadow(color: Color.black.opacity(0.07), radius: 48.5, x: 0, y: 4) // Shadow/2: 0 4 97 at 7%; the spread is not drawn
    }

    /// What reaches you where, newest first: WhatsApp, the app itself, and email. Written for the prototype.
    private static let notes: [(logo: String, title: String, detail: String, time: String)] = [
        ("CommsWhatsApp", "Decade Advisor", "Your SIP of ₹5,000 goes out tomorrow", "now"),
        ("DecadeAvatar", "Decade", "HDFC Flexi Cap moved up 2 ranks", "3 min ago"),
        ("CommsGmail", "Decade", "Your October portfolio review is ready", "10 min ago"),
    ]

    /// The phone's outline with three notifications in it, running off the foot of its box. They arrive the way
    /// they do on a lock screen: one at a time at the top, each pushing the earlier ones down.
    private var phone: some View {
        let shape = RoundedRectangle(cornerRadius: 37, style: .continuous)
        return ZStack(alignment: .top) {
            Color.white
            Capsule().fill(Color.black.opacity(0.34))
                .frame(width: 82, height: 20)
                .padding(.top, 8)
            VStack(spacing: 11.895) {
                ForEach(Array(Self.notes.enumerated()).suffix(arrived), id: \.offset) { _, note in
                    notification(note.logo, note.title, note.detail, note.time)
                        .transition(.asymmetric(
                            insertion: .offset(y: -34).combined(with: .scale(scale: 0.9, anchor: .top)).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .offset(x: 0.36)
            .padding(.top, 53.65)
        }
        .frame(width: 274, height: 476, alignment: .top)
        .clipShape(shape)
        .overlay(shape.strokeBorder(ColorScale.borderSubtle, lineWidth: 1))
        .padding(.top, 80)
        .task(id: stage) {
            guard stage == .permissions, arrived == 0 else { return }
            if reduceMotion { arrived = Self.notes.count; return }
            // Once the card's landed
            try? await Task.sleep(for: .seconds(0.75))
            for count in 1...Self.notes.count {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) { arrived = count }
                try? await Task.sleep(for: .seconds(0.7))
            }
        }
    }

    private func notification(_ logo: String, _ title: String, _ detail: String, _ time: String) -> some View {
        let quiet = Color(red: 60 / 255, green: 60 / 255, blue: 67 / 255).opacity(0.6)
        return ZStack(alignment: .topLeading) {
            Color(hex: 0xF5F5F5).opacity(0.5)
            Group {
                switch logo {
                case "CommsWhatsApp":
                    // WhatsApp's mark on its green
                    Circle().fill(Color(hex: 0x25D366))
                        .overlay(alignment: .topLeading) { Image(logo).at(5.42, 4.127) }
                case "CommsGmail":
                    Image(logo).overlay(Circle().strokeBorder(ColorScale.borderSubtle, lineWidth: 0.5))
                default:
                    Image(logo).resizable()
                }
            }
            .frame(width: 27.997, height: 27.997)
            .at(11.9, 9.1)
            // The frame sets these in Poppins Medium, white on the pale row; darkened here so they can be read
            Text(title)
                .font(.system(size: 11.199, weight: .medium))
                .tracking(0.112)
                .foregroundStyle(ColorScale.contentPrimary)
                .fixedSize()
                .at(44.79, 9.8)
            Text(detail)
                .font(.system(size: 8.399, weight: .medium))
                .tracking(0.084)
                .foregroundStyle(quiet)
                .lineLimit(1)
                .frame(width: 194, alignment: .leading)
                .at(44.79, 24.6)
            Text(time)
                .font(.system(size: 8.399, weight: .medium))
                .tracking(0.084)
                .foregroundStyle(quiet)
                .fixedSize()
                .frame(width: 238.6, alignment: .trailing)
                .padding(.top, 11.9)
        }
        .frame(width: 251.271, height: 46.195, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 9.099, style: .continuous))
    }

    // MARK: The channels, 342 × 130

    private var channels: some View {
        let shape = RoundedRectangle(cornerRadius: 23, style: .continuous)
        return VStack(spacing: 0) {
            ForEach(Channel.allCases, id: \.self) { channel in
                HStack(spacing: 0) {
                    Image("FDReviewRow")
                        .frame(width: 20.903, height: 19.262)
                        .accessibilityHidden(true)
                    DsText(channel.rawValue, variant: .p4, color: .contentTertiary)
                        .padding(.leading, 15.25)
                    Spacer(minLength: 0)
                    Toggle(channel.rawValue, isOn: Binding(
                        get: { allowed.contains(channel) },
                        set: { $0 ? allow(channel) : disallow(channel) }
                    ))
                    .labelsHidden()
                    .toggleStyle(PermissionSwitchStyle())
                }
                .padding(.leading, 16.85)
                .padding(.trailing, 21)
                .frame(height: 65)
                .overlay(alignment: .bottom) {
                    if channel != Channel.allCases.last { ColorScale.borderSubtle.frame(height: 0.7) }
                }
            }
        }
        .frame(width: 342, height: 130)
        .background(Color.white)
        .clipShape(shape)
        .overlay(shape.strokeBorder(ColorScale.borderSubtle, lineWidth: 0.7))
    }

    private func disallow(_ channel: Channel) {
        Haptics.tap()
        allowed.remove(channel)
    }

    /// Turning a channel on asks for what it needs. Only app notifications need anything from the system; the switch
    /// goes on while the system asks and comes back off if the answer's no.
    private func allow(_ channel: Channel) {
        Haptics.tap()
        allowed.insert(channel)
        guard channel == .app else { return }
        Task {
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if !granted {
                withAnimation { _ = allowed.remove(.app) }
            }
        }
    }
}

/// The permissions' switch (973:17981): 39 × 23 on surface/sunken-1 with a hairline, a 19 knob, green once it's on
private struct PermissionSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { configuration.isOn.toggle() }
        } label: {
            Circle()
                .fill(configuration.isOn ? ColorPrimitives.utilityGreen400 : ColorScale.contentDisabled)
                .frame(width: 19, height: 19)
                .padding(.horizontal, 2)
                .frame(width: 39, height: 23, alignment: configuration.isOn ? .trailing : .leading)
                .background(Capsule().fill(ColorScale.surfaceSunken1))
                .overlay(Capsule().strokeBorder(ColorScale.borderSubtle, lineWidth: 0.7))
                // A fuller target than the 23 it draws
                .padding(.vertical, 10)
                .padding(.leading, 12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Still a switch to anything that reads the screen
        .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } }
    }
}

/// What the advisor says from her corner (973:17040): 318 × 94, white, its tail at the lower left
struct AdvisorBubble: View {
    let text: String
    /// Typed out a letter at a time once it's up, the bubble already at its full size; `onTyped` when the last is in
    var typed = false
    var onTyped: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var count = 0
    /// 0 → 1 as the white washes across a new bubble
    @State private var splash: CGFloat = 0
    /// Letters a second
    private static let pace: Double = 45

    var body: some View {
        // The letters still to come are set but clear, so the lines never reflow as it types
        (Text(typed ? String(text.prefix(count)) : text)
            + Text(typed ? String(text.dropFirst(count)) : "").foregroundStyle(Color.clear))
            .font(FigmaFont.walsheim(17))
            .lineSpacing(21 - UIFont(name: "GTWalsheimTrial-Rg", size: 17)!.lineHeight)
            .foregroundStyle(ColorScale.contentPrimary)
            .frame(width: 265, alignment: .leading)
            .padding(.leading, 15)
            .padding(.top, 15)
            .frame(width: 318, height: 94, alignment: .topLeading)
            .background(BubbleSplashFill(progress: typed && !reduceMotion ? splash : 1))
            .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                Image("BubbleTail")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.white)
                    .frame(width: 24, height: 14)
                    .rotationEffect(.degrees(7.22))
                    .offset(x: 0.22, y: 8.45)
                    .accessibilityHidden(true)
            }
            .modifier(BubbleRipple(progress: typed && !reduceMotion ? splash : 1))
            .shadow(color: Color.black.opacity(0.03), radius: 7.5, x: 0, y: 3)
            .accessibilityLabel(text)
            .onAppear {
                guard typed, !reduceMotion else { return }
                // A new line: white washes over the bubble from the left, with a small ripple at its front
                withAnimation(.smooth(duration: 1.2).delay(0.1)) { splash = 1 }
            }
            .task {
                guard typed, count == 0 else { return }
                if reduceMotion {
                    count = text.count
                } else {
                    // Once the bubble itself has landed
                    try? await Task.sleep(for: .seconds(0.25))
                    for shown in 1...max(text.count, 1) {
                        guard !Task.isCancelled else { return }
                        count = shown
                        try? await Task.sleep(for: .seconds(1 / Self.pace))
                    }
                }
                guard !Task.isCancelled else { return }
                onTyped?()
            }
    }
}

/// The bubble's fill while white washes across it: a faint cool grey ahead of the front, white behind it
private struct BubbleSplashFill: View, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        // A long soft edge, as the system's own sheens have
        let front = -0.2 + 1.55 * progress
        let from = min(max(front - 0.35, 0), 1), to = min(max(front + 0.15, 0), 1)
        ZStack {
            Color.white
            LinearGradient(
                stops: [
                    .init(color: Color(hex: 0xEDF0F3).opacity(0), location: from),
                    .init(color: Color(hex: 0xEDF0F3), location: max(to, from)),
                ],
                startPoint: .leading, endPoint: .trailing
            )
        }
    }
}

/// The ripple at the front of that wash (`BubbleRipple.metal`)
private struct BubbleRipple: ViewModifier, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .visualEffect { view, proxy in
                view.distortionEffect(
                    ShaderLibrary.bubbleRipple(.float2(proxy.size), .float(progress)),
                    maxSampleOffset: CGSize(width: 2, height: 2),
                    isEnabled: progress > 0 && progress < 1
                )
            }
    }
}

/// The advisor in her corner (973:16944): the portrait, 63 across
struct AdvisorAvatar: View {
    var body: some View {
        Image("MeetAdvisorPortrait")
            .frame(width: 394, height: 400)
            .frame(width: 186, height: 192)
            .scaleEffect(63 / 186)
            .frame(width: 63, height: 65)
            .accessibilityHidden(true)
    }
}
