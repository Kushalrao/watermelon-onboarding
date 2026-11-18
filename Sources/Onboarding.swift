import SwiftUI

/// Walks the user through the interactions, one screen at a time.
struct OnboardingFlow: View {
    /// Called when the last step is done
    let onFinish: () -> Void

    @State private var step = OnboardingFlow.debugStartStep
    @State private var introStage = OnboardingIntroStage()
    /// The status bar's height, for the screens that place themselves under it
    @State private var top: CGFloat = 62

    /// Launch argument `-onboardingStep N` starts the flow at step N. With no flag of ours at all the app opens on
    /// the congratulations over water (step 10), the screen being worked on; `-onboarding` starts from the top.
    private static var debugStartStep: Int {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-onboardingStep"), i + 1 < args.count, let n = Int(args[i + 1]) else {
            return MutualFundsPrototypeApp.plainLaunch ? 10 : 0
        }
        return n
    }

    var body: some View {
        ZStack {
            switch step {
            case 0:
                OnboardingIntroView(onContinue: advance, stage: introStage)
                    // Stays put while the advisory screen's colour flows up over it, then goes
                    .transition(.asymmetric(
                        insertion: Self.pageTransition,
                        removal: .opacity.animation(.linear(duration: 0.01).delay(OnboardingDecadeWelcomeView.flowDuration))
                    ))
            case 1:
                OnboardingDecadeWelcomeView(onContinue: advance)
                    // It brings its own background in, flowing up over the intro, and stays put while the advisory
                    // screen's colour flows up over it in turn
                    .transition(.asymmetric(
                        insertion: .identity,
                        removal: .opacity.animation(.linear(duration: 0.01).delay(OnboardingAdvisoryView.flowDuration))
                    ))
                    .zIndex(1)
            case 2:
                // The advisory chat and research (99:1576 onwards), on the welcome's Continue
                OnboardingAdvisoryView(onContinue: advance)
                    .transition(.asymmetric(insertion: .identity, removal: Self.pageTransition))
                    .zIndex(2)
            case 3:
                OnboardingWelcomeView(onContinue: advance)
                    .transition(Self.pageTransition)
            case 4:
                OnboardingHoldView(onContinue: advance)
                    .transition(Self.pageTransition)
            case 5:
                OnboardingSwipeView(onContinue: advance)
                    .transition(Self.pageTransition)
            case 6:
                OnboardingComplexityView(onContinue: advance)
                    .transition(Self.pageTransition)
            case 10:
                // After the second report's Understood: "Congrats! you have a proactive personal advisor now"
                // (1027:11565), its ground coming in over the chat
                OnboardingCongratsView(water: true, onContinue: advance)
                    .transition(.opacity)
                    .zIndex(3)
            case 15:
                // then the advisor herself (973:16066), who goes up into the corner for the permissions (973:16336)
                OnboardingCommunicationsView(introduces: true, onContinue: advance)
                    .transition(.opacity)
                    .zIndex(3)
            case 11:
                // The permissions on their own, for `-onboardingStep 11`
                OnboardingCommunicationsView(onContinue: advance)
                    .transition(.opacity)
                    .zIndex(3)
            case 12:
                // The three guides (973:17046, 973:17264, 973:17547): how plainly things are put, hold, and swipe
                OnboardingComplexityGuideView(onContinue: advance)
                    .transition(.opacity)
                    .zIndex(3)
            case 13:
                OnboardingHoldGuideView(onContinue: advance)
                    .transition(.opacity)
                    .zIndex(3)
            case 14:
                OnboardingSwipeGuideView(onContinue: advance)
                    .transition(.opacity)
                    .zIndex(3)
            case 16:
                // The last screen (973:17796): "You’re in, have a wealthy life", and then the app
                OnboardingCongratsView(text: "You’re in, have a\nwealthy life", textTop: 356, label: "You’re in, have a wealthy life", onContinue: advance)
                    .transition(.opacity)
                    .zIndex(3)
            default:
                // Next screen not designed yet
                OnboardingBackground()
                    .transition(Self.pageTransition)
            }
        }
        .environment(\.onboardingTop, top)
        .ignoresSafeArea()
        // Read from the window once the flow is on screen (not while anything is being drawn), and handed down
        .onAppear {
            let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            if let inset = scene?.windows.first?.safeAreaInsets.top, inset > 0 { top = inset }
        }
    }

    private static let pageTransition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )

    private func advance() {
        Haptics.tap()
        // Intro → welcome → advisory: each brings its colour in over the last; the rest slide
        let animation: Animation = step <= 1 ? .easeInOut(duration: 0.4) : .spring(response: 0.45, dampingFraction: 0.9)
        switch step {
        // Past the chat and the import the personalising screens take over; the screens numbered 2 to 6 are the
        // earlier flow, reached only with `-onboardingStep`
        case 1: withAnimation(animation) { step = 10 }
        // The congratulations, then the advisor and her permissions, then the guides
        case 10: withAnimation(.easeInOut(duration: 0.3)) { step = 15 }
        case 15, 11: withAnimation(.easeInOut(duration: 0.35)) { step = 12 }
        case 12, 13: withAnimation(.easeInOut(duration: 0.35)) { step += 1 }
        // After the last guide, the farewell; when its words have gone the onboarding ends
        case 14: withAnimation(.easeInOut(duration: 0.4)) { step = 16 }
        case 16: onFinish()
        default: withAnimation(animation) { step += 1 }
        }
    }
}

/// White → #F7F7F7, shared by every onboarding screen
struct OnboardingBackground: View {
    var body: some View {
        LinearGradient(colors: [Color.white, Color(hex: 0xF7F7F7)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

/// Figma: "iPhone 14 Plus - 231" (771:12502), 390 × 840
struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color.white, Color(hex: 0xF7F7F7)], startPoint: .top, endPoint: .bottom)

            Text("Hi \(AppUser.name)")
                .font(FigmaFont.recklessRegular(47))
                .foregroundStyle(Color.ink)
                .frame(width: 348, alignment: .leading)
                .at(23, 292)

            Text("We’ll now quickly guide you through the basics to give you a head start.")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black)
                .frame(width: 344, alignment: .leading)
                .at(23, 354)

            OnboardingButton(title: "Continue", action: onContinue)
                .at(23, 463)
        }
        .frame(width: MutualFundScreen.canvasWidth, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(LinearGradient(colors: [Color.white, Color(hex: 0xF7F7F7)], startPoint: .top, endPoint: .bottom))
    }
}

/// Black pill button (771:12505), 344 × 51
struct OnboardingButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FigmaFont.walsheimMedium(17))
                .foregroundStyle(Color.white)
                .frame(width: 344, height: 51)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 100))
                .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.black.opacity(0.05), lineWidth: 2))
                .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
        .animation(.easeInOut(duration: 0.3), value: enabled)
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
