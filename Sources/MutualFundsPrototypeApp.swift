import SwiftUI

@main
struct MutualFundsPrototypeApp: App {
    /// With no flag the app opens on the mutual funds homepage (`MutualFundsHomeV2View`); `-mf` opens it too, and
    /// `-mfHomeV1` opens its first version (`MutualFundsHomeView`).
    /// `-onboarding` (or any `-onboarding…` flag) opens the onboarding: the second one (`OnboardingFlowV2`), or the
    /// first with `-onboardingV1`. `-fd` (or any `-fd…` flag) opens the fixed deposits page, `-fund` the fund page,
    /// `-home` (or a flag that names a home version) the home page
    static let opensOnFixedDeposits = ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("-fd") }

    /// `-mf`, or no flag of ours at all: the mutual funds homepage. A flag that only picks a version inside the
    /// onboarding (`-reportSimple`, `-researchGather`) still opens the onboarding, as it did
    static let opensOnMutualFunds: Bool = {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-mf") { return true }
        return plainLaunch && !args.contains { ["-reportSimple", "-researchGather"].contains($0) }
    }()

    /// No flag of ours given
    static let plainLaunch: Bool = {
        let args = ProcessInfo.processInfo.arguments
        if args.contains(where: { $0.hasPrefix("-fd") || $0.hasPrefix("-onboarding") || $0.hasPrefix("-welcome") }) { return false }
        return !args.contains { ["chat", "-fund", "-home", "-widgetsOnly", "-homeV1", "-homeV2", "-homeV3", "-homeV4"].contains($0) }
    }()

    var body: some Scene {
        WindowGroup {
            // `-experience chat` opens the standalone chat (the "ChatPrototype" scheme sets it)
            if ProcessInfo.processInfo.arguments.contains("chat") {
                ChatExperienceView()
            } else if Self.opensOnFixedDeposits {
                // The page by default; `-fdListV1` keeps the earlier list
                if ProcessInfo.processInfo.arguments.contains("-fdListV1") {
                    FixedDepositsView()
                } else {
                    FixedDepositsHomeView()
                }
            } else if Self.opensOnMutualFunds {
                // The second homepage by default; `-mfHomeV1` keeps the first, with the fund houses' map
                if ProcessInfo.processInfo.arguments.contains("-mfHomeV1") {
                    MutualFundsHomeView()
                } else {
                    MutualFundsHomeV2View()
                }
            } else {
                // Nothing in the onboarding moves for the keyboard; each screen places itself around it
                RootView()
                    .ignoresSafeArea(.keyboard)
            }
        }
    }
}

/// Opens on the home page (the v5 living-pattern widgets by default; `-homeV1` for the Chats grid, `-homeV2` for the greeting, `-homeV3` for the pinned widgets, `-homeV4` for the plastic widgets); its Investments entries
/// and chats push the fund page. With no flag the app opens on the mutual funds homepage instead; launch with `-fund` for the fund page (pushed over the home page), `-home` for the
/// home page, `-onboarding` for the onboarding flow (`-onboardingStep N` starts it at step N), `-fd` for fixed deposits.
struct RootView: View {
    @State private var onboarded = {
        let args = ProcessInfo.processInfo.arguments
        // The onboarding shows only when asked for (`-onboarding`, or any `-onboarding…` flag)
        return !MutualFundsPrototypeApp.plainLaunch && !args.contains { $0.hasPrefix("-onboarding") }
    }()
    @State private var showsFund = ProcessInfo.processInfo.arguments.contains("-fund")
    /// The chat page and the icon it grew out of; `chatMove` and `chatGrow` run 0 (in the icon) → 1 (full screen)
    @State private var chatSource: ChatSource?
    @State private var chatMove: CGFloat = 0
    @State private var chatGrow: CGFloat = 0
    @State private var screen: CGSize = .zero
    /// The + button's market-mood dial
    @State private var showsMoodDial = false
    private let homeVersion = {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("-homeV1") ? 1 : args.contains("-homeV2") ? 2 : args.contains("-homeV3") ? 3 : args.contains("-homeV4") ? 4 : 5
    }()

    private static let push = Animation.spring(response: 0.45, dampingFraction: 0.92)
    // Opening: the page travels up a little ahead of its size, which swells just past full screen and settles back.
    // Closing: tighter, so it tucks into the icon with only a small give.
    private static let openMove = Animation.spring(response: 0.5, dampingFraction: 0.78)
    private static let openGrow = Animation.spring(response: 0.58, dampingFraction: 0.7)
    private static let closeMove = Animation.spring(response: 0.42, dampingFraction: 0.84)
    private static let closeGrow = Animation.spring(response: 0.46, dampingFraction: 0.76)

    var body: some View {
        ZStack {
            if onboarded {
                GeometryReader { geo in
                    ZStack {
                        // iOS push: the home page drifts left under the incoming fund page
                        home
                            .environment(\.openChat) { openChat(from: $0) }
                            .environment(\.openMoodDial) { showsMoodDial = true }
                            .offset(x: showsFund ? -geo.size.width * 0.3 : 0)
                            .overlay(Color.black.opacity(showsFund ? 0.08 : 0).allowsHitTesting(false))
                            .allowsHitTesting(!showsFund && chatSource == nil)
                            // Settles back slightly while the chat is open over it
                            .overlay(Color.black.opacity(0.12 * min(1, chatGrow)).allowsHitTesting(false))

                        if showsFund {
                            FundExperienceView()
                                .environment(\.goBack) { withAnimation(Self.push) { showsFund = false } }
                                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 0)
                                .transition(.move(edge: .trailing))
                                .zIndex(1)
                        }
                    }
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { screen = $0 }
                }
                .ignoresSafeArea()
                .transition(.opacity)

                if let chatSource {
                    ChatExperienceView(fresh: chatSource.fresh)
                        .environment(\.goBack) { closeChat() }
                        .modifier(ZoomFromSource(move: chatMove, grow: chatGrow, source: chatSource, screen: screen))
                        .zIndex(2)
                }

                if showsMoodDial {
                    MoodDialSheet { showsMoodDial = false }
                        .zIndex(3)
                }
            } else {
                // The second onboarding unless the first is asked for (`-onboardingV1`)
                Group {
                    switch OnboardingVersion.current {
                    case .v1: OnboardingFlow { withAnimation(.easeInOut(duration: 0.35)) { onboarded = true } }
                    case .v2: OnboardingFlowV2 { withAnimation(.easeInOut(duration: 0.35)) { onboarded = true } }
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

extension RootView {
    @ViewBuilder fileprivate var home: some View {
        let open = { withAnimation(Self.push) { showsFund = true } }
        switch homeVersion {
        case 1: HomeView(onOpenFund: open)
        case 2: HomeV2View(onOpenFund: open)
        case 3: HomeV3View(onOpenFund: open)
        case 4: HomeV4View(onOpenFund: open)
        default: HomeV5View(onOpenFund: open)
        }
    }

    /// Grows the chat page out of the tapped icon
    fileprivate func openChat(from source: ChatSource) {
        guard chatSource == nil else { return }
        chatMove = 0
        chatGrow = 0
        chatSource = source
        // Inserted at the icon first, then opened on the next frame
        DispatchQueue.main.async {
            withAnimation(Self.openMove) { chatMove = 1 }
            withAnimation(Self.openGrow) { chatGrow = 1 }
        }
    }

    /// Shrinks the chat back into the icon it came from
    fileprivate func closeChat() {
        withAnimation(Self.closeMove) { chatMove = 0 }
        withAnimation(Self.closeGrow) {
            chatGrow = 0
        } completion: {
            chatSource = nil
        }
    }
}

private struct GoBackKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    /// Pops the current page (the header's back chevron)
    var goBack: () -> Void {
        get { self[GoBackKey.self] }
        set { self[GoBackKey.self] = newValue }
    }
}
