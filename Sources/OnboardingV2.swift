import SwiftUI

/// Which onboarding a launch runs. The second is the one being built and is what opens by default; the first is
/// kept whole and opens with `-onboardingV1`. A screen the two share reads this where the second differs from it.
enum OnboardingVersion {
    case v1, v2

    static let current: OnboardingVersion = ProcessInfo.processInfo.arguments.contains("-onboardingV1") ? .v1 : .v2
}

/// The second onboarding: its own intro (`OnboardingIntroV2View`: the welcome, the number, the code and the KYC
/// details, with no PAN looked up on the way), and then its own opening (step 20,
/// `OnboardingWelcomeV2View`), which runs from its welcome through the chat, the research and the report on the
/// phone it draws, to the hold and swipe gestures. That is all of it: the swipe's Continue ends the onboarding.
/// None of the first onboarding's later screens (its welcome and chat, the congratulations, the advisor and her
/// permissions, the three guides, the farewell) are part of it; they stay in `OnboardingFlow`, which is left as it is.
struct OnboardingFlowV2: View {
    /// Called when the last step is done
    let onFinish: () -> Void

    @State private var step = OnboardingFlowV2.startStep
    @State private var introStage = OnboardingIntroStage()
    /// The status bar's height, for the screens that place themselves under it
    @State private var top: CGFloat = 62

    /// `-onboardingIntroV1`: the first onboarding's intro in place of this one's
    private static let firstIntro = ProcessInfo.processInfo.arguments.contains("-onboardingIntroV1")

    /// `-onboardingStep N` starts the flow at step N (0, or 20 for the opening); otherwise from the top
    private static var startStep: Int {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-onboardingStep"), i + 1 < args.count, let n = Int(args[i + 1]) else {
            return 0
        }
        return n
    }

    var body: some View {
        ZStack {
            switch step {
            case 0:
                // Its own way in (1341:1275 onwards); the first onboarding's, with the PAN looked up and found, is
                // kept and comes back with `-onboardingIntroV1`
                Group {
                    if Self.firstIntro {
                        OnboardingIntroView(onContinue: advance, stage: introStage)
                    } else {
                        OnboardingIntroV2View(onContinue: advance)
                    }
                }
                // Stays put while the next screen's colour flows up over it, then goes
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.animation(.linear(duration: 0.01).delay(OnboardingDecadeWelcomeView.flowDuration))
                ))
            case 20:
                // Its own opening (1267:12910 onwards), right after the PAN: it brings its ground in, flowing up over
                // the intro
                OnboardingWelcomeV2View(onContinue: advance)
                    .transition(.asymmetric(insertion: .identity, removal: .opacity))
                    .zIndex(1)
            default:
                // Not a step of this flow
                OnboardingBackground()
                    .transition(.opacity)
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

    private func advance() {
        Haptics.tap()
        switch step {
        case 0: withAnimation(.easeInOut(duration: 0.4)) { step = 20 }
        // After the opening there is nothing more: the onboarding is done
        default: onFinish()
        }
    }
}
