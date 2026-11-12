import SwiftUI

/// The fund page's "Ask your advisor" pill and mic, pinned to the foot of any page: a tap grows it into the
/// composer above the keyboard. With no tabs under it here, the pill rests just above the home indicator.
///
/// It also carries the fund page's two ways of asking about a widget, for any view marked `askable(_:)` inside
/// the page: hold it to lift it out with questions, or swipe it right to send it to the composer as context.
private struct AdvisorBar: ViewModifier {
    @State private var isComposing = false
    @State private var composeProgress: CGFloat = 0
    @State private var text = ""
    @State private var composerContext: FundContext?
    @FocusState private var focused: Bool
    @StateObject private var keyboard = KeyboardObserver()

    @State private var heldWidget: HeldWidget?
    @State private var holdProgress: CGFloat = 0
    @State private var holdChipsOut = false
    /// A layer of the page has taken over the screen (a plan's card), so the pill steps out of its way
    @State private var hidden = false

    private static let transition = Animation.spring(response: 0.5, dampingFraction: 0.86)
    /// The pill is 53 tall and sits 13 above the home indicator's 34
    private static let pillRise: CGFloat = 100

    func body(content: Content) -> some View {
        content
            .environment(\.askAbout, AskAbout(held: heldWidget?.context, hold: hold, send: { open(with: $0) }))
            .overlay {
                GeometryReader { geo in
                    ZStack {
                        ComposerLayer(
                            isFocused: $focused,
                            text: $text,
                            viewport: geo.size,
                            keyboardHeight: keyboard.height,
                            isComposing: isComposing,
                            context: composerContext,
                            pillTop: geo.size.height - Self.pillRise,
                            onOpen: { open(with: nil) },
                            onClose: close
                        )
                        // Above everything: while a widget is held, a tap anywhere else puts it back
                        HeldWidgetLayer(
                            frame: heldWidget?.frame,
                            questions: heldWidget?.context.questions ?? [],
                            progress: holdProgress,
                            chipsOut: holdChipsOut,
                            onDismiss: release
                        ) { heldWidget?.context.widget }
                    }
                    .modifier(AnimatedComposeProgress(progress: composeProgress))
                }
                .ignoresSafeArea()
                .opacity(hidden ? 0 : 1)
                .allowsHitTesting(!hidden)
                .animation(.easeOut(duration: 0.2), value: hidden)
            }
            .onPreferenceChange(AdvisorBarHiddenKey.self) { hidden = $0 }
            .onChange(of: focused) { _, isFocused in
                // Keyboard put away some other way: fold the card back into the pill
                if !isFocused && isComposing { close() }
            }
    }

    private func open(with context: FundContext?) {
        guard !isComposing, heldWidget == nil else { return }
        Haptics.tap()
        composerContext = context
        isComposing = true
        focused = true
        withAnimation(Self.transition) { composeProgress = 1 }
    }

    private func close() {
        guard isComposing else { return }
        Haptics.settle()
        isComposing = false
        focused = false
        withAnimation(Self.transition) { composeProgress = 0 }
        // Drop the attached context once the card has folded back into the pill
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !isComposing { composerContext = nil }
        }
    }

    private func hold(_ context: FundContext, frame: CGRect) {
        guard heldWidget == nil, !isComposing else { return }
        Haptics.lift()
        heldWidget = HeldWidget(context: context, frame: frame)
        holdProgress = 0
        holdChipsOut = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) { holdProgress = 1 }
        DispatchQueue.main.async { holdChipsOut = true }
    }

    private func release() {
        guard heldWidget != nil else { return }
        Haptics.settle()
        holdChipsOut = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            holdProgress = 0
        } completion: {
            heldWidget = nil
        }
    }
}

/// What a page under an advisor bar can do with one of its widgets
struct AskAbout {
    /// The widget lifted out by a hold, if any
    var held: FundContext?
    var hold: (FundContext, CGRect) -> Void = { _, _ in }
    var send: (FundContext) -> Void = { _ in }
}

private struct AskAboutKey: EnvironmentKey {
    static let defaultValue = AskAbout()
}

extension EnvironmentValues {
    var askAbout: AskAbout {
        get { self[AskAboutKey.self] }
        set { self[AskAboutKey.self] = newValue }
    }
}

private struct Askable: ViewModifier {
    let context: FundContext
    @Environment(\.askAbout) private var ask

    func body(content: Content) -> some View {
        content
            .widgetHold(isHeld: ask.held == context) { ask.hold(context, $0) }
            .contextSwipe { ask.send(context) }
    }
}

extension View {
    /// Pins the "Ask your advisor" pill to the foot of the page
    func advisorBar() -> some View { modifier(AdvisorBar()) }

    /// Hold to lift this widget out with questions; swipe it right to ask about it. Needs `advisorBar()` above it.
    func askable(_ context: FundContext) -> some View { modifier(Askable(context: context)) }
}
