import SwiftUI

/// The fund page's "Ask your advisor" pill and mic, pinned to the foot of any page: a tap grows it into the
/// composer above the keyboard. With no tabs under it here, the pill rests just above the home indicator.
///
/// It also carries the fund page's two ways of asking about a widget, for any view marked `askable(_:)` inside
/// the page: hold it to lift it out with questions, or swipe it right to send it to the composer as context.
private struct AdvisorBar: ViewModifier {
    /// The pill is drawn at rest. A mutual fund's page has a bar of its own ("Ask advisor" and "Start SIP") and
    /// borrows only the composer, which then comes out of that bar's pill, and the hold.
    var restingPill = true
    /// How far above the foot of the screen the pill's top is: the pill is 53 tall and sits 13 above the home
    /// indicator's 34
    var pillRise: CGFloat = 100

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
    /// The page's own button beside the pill, by its title ("View plans"), and how often it has been tapped
    @State private var actionTitle: String?
    @State private var actionTaps = 0
    /// The page has reached its end: the pill rises onto the button and both run the full width
    @State private var stacked = false
    @State private var appeared = Date()

    private static let transition = Animation.spring(response: 0.5, dampingFraction: 0.86)

    func body(content: Content) -> some View {
        content
            .environment(\.askAbout, AskAbout(held: heldWidget?.context, hold: hold, send: { open(with: $0) }, open: { open(with: nil) }))
            // A fund's page takes its own bar out of the way while the composer is up
            .transformPreference(FundFootCoveredKey.self) { $0 = $0 || (!restingPill && isComposing) }
            .environment(\.advisorBarActionTaps, actionTaps)
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
                            pillTop: geo.size.height - pillRise,
                            action: actionTitle.map { title in (title, { Haptics.tap(); actionTaps += 1 }) },
                            stacked: stacked,
                            onOpen: { open(with: nil) },
                            onClose: close
                        )
                        .opacity(restingPill ? 1 : min(1, composeProgress * 5))
                        .allowsHitTesting(restingPill || isComposing)
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
            .onPreferenceChange(AdvisorBarActionKey.self) { title in
                guard title != actionTitle else { return }
                // A page that opens with its button has it from the start; one that brings it in later springs it in
                if Date().timeIntervalSince(appeared) < 0.8 {
                    actionTitle = title
                } else {
                    Haptics.tap()
                    withAnimation(.spring(duration: 0.55, bounce: 0.28)) { actionTitle = title }
                }
            }
            .onPreferenceChange(AdvisorBarStackedKey.self) { atEnd in
                guard atEnd != stacked else { return }
                Haptics.tap()
                withAnimation(.spring(duration: 0.55, bounce: 0.28)) { stacked = atEnd }
            }
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
    /// Opens the composer with nothing attached
    var open: () -> Void = {}
}

/// Set by a page that wants its own button beside the advisor pill: the button's title
struct AdvisorBarActionKey: PreferenceKey {
    static let defaultValue: String? = nil
    static func reduce(value: inout String?, nextValue: () -> String?) { value = value ?? nextValue() }
}

/// Set by a page with its own button in the bar once it is scrolled to its end
struct AdvisorBarStackedKey: PreferenceKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}

private struct AdvisorBarActionTapsKey: EnvironmentKey {
    static let defaultValue = 0
}

extension EnvironmentValues {
    /// Counts taps on the page's button beside the advisor pill; a page watches it change
    var advisorBarActionTaps: Int {
        get { self[AdvisorBarActionTapsKey.self] }
        set { self[AdvisorBarActionTapsKey.self] = newValue }
    }
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

/// Sits inside a page under an advisor bar and reports taps on the page's button beside the pill
struct AdvisorBarActionListener: View {
    let onTap: () -> Void
    @Environment(\.advisorBarActionTaps) private var taps

    var body: some View {
        Color.clear
            .allowsHitTesting(false)
            .onChange(of: taps) { onTap() }
    }
}

extension View {
    /// Pins the "Ask your advisor" pill to the foot of the page
    func advisorBar() -> some View { modifier(AdvisorBar()) }

    /// The advisor's composer and the hold for a page that draws its own bar: nothing is drawn at rest, and the
    /// composer comes out of where that bar's pill is, `pillRise` above the foot of the screen
    func advisorComposer(pillRise: CGFloat) -> some View { modifier(AdvisorBar(restingPill: false, pillRise: pillRise)) }

    /// Hold to lift this widget out with questions; swipe it right to ask about it. Needs `advisorBar()` above it.
    func askable(_ context: FundContext) -> some View { modifier(Askable(context: context)) }
}
