import SwiftUI

@main
struct MutualFundsPrototypeApp: App {
    /// Opens on the fixed deposits page by default; `-onboarding…`, `-home`, `-fund`, `-widgetsOnly` and
    /// `-homeV1…V4` open the rest of the app instead
    static let opensOnFixedDeposits: Bool = {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-fd") { return true }
        return !args.contains { $0.hasPrefix("-onboarding") || $0.hasPrefix("-home") || $0 == "-fund" || $0 == "-widgetsOnly" }
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
            } else {
                RootView()
            }
        }
    }
}

/// Opens on the home page (the v5 living-pattern widgets by default; `-homeV1` for the Chats grid, `-homeV2` for the greeting, `-homeV3` for the pinned widgets, `-homeV4` for the plastic widgets); its Investments entries
/// and chats push the fund page. The onboarding flow shows first (`-onboardingStep N` starts
/// it at step N); launch with `-home` to skip straight to the home page, `-fund` to open on the fund page, `-fd` for fixed deposits.
struct RootView: View {
    @State private var onboarded = {
        let args = ProcessInfo.processInfo.arguments
        // Onboarding comes first by default; `-home` (or a flag that names a home version or the fund page) skips it
        if args.contains(where: { $0.hasPrefix("-onboarding") }) { return false }
        return args.contains { ["-home", "-fund", "-widgetsOnly", "-homeV1", "-homeV2", "-homeV3", "-homeV4"].contains($0) }
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
                OnboardingFlow { withAnimation(.easeInOut(duration: 0.35)) { onboarded = true } }
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
