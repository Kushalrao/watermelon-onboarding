import SwiftUI
import Combine

// MARK: - Animated compose progress (0 = "Ask anything" pill in the bar, 1 = composer card above the keyboard)

private struct ComposeProgressKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var composeProgress: CGFloat {
        get { self[ComposeProgressKey.self] }
        set { self[ComposeProgressKey.self] = newValue }
    }
}

/// Interpolated by SwiftUI during `withAnimation`, so the pill → card morph is evaluated every frame.
struct AnimatedComposeProgress: ViewModifier, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.environment(\.composeProgress, progress)
    }
}

// MARK: - Keyboard height

final class KeyboardObserver: ObservableObject {
    /// Last known keyboard height; kept after the keyboard hides so the card has a target while morphing out.
    @Published var height: CGFloat = 0
    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .compactMap { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) }
            .map { max(0, UIScreen.main.bounds.height - $0.minY) }
            .filter { $0 > 0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.height = $0 }
    }
}

// MARK: - Composer (717:10766): the "Ask anything" pill expanded into a card above the keyboard

struct ComposerLayer: View {
    @Environment(\.composeProgress) private var p
    @FocusState.Binding var isFocused: Bool
    @Binding var text: String
    let viewport: CGSize
    let keyboardHeight: CGFloat
    let isComposing: Bool
    /// Widget attached by swiping it right; nil for a plain tap on the input
    let context: FundContext?
    /// Onboarding: no keyboard — the card sits at the bottom of the screen, and there is no pill at rest
    var bottomAligned: Bool = false
    /// With `bottomAligned`: y the card should float above (e.g. the top of a button); defaults to the home indicator
    var floatAbove: CGFloat? = nil
    /// Top of the pill at rest; defaults to the fund page's place above its tabs
    var pillTop: CGFloat? = nil
    /// A page's own button beside the pill (659:19931, "View plans"): the pill is then narrower, with no plus
    /// and no mic at rest
    var action: (title: String, run: () -> Void)? = nil
    /// With an action, at the end of the page: the pill rises onto the button and both run the full width
    var stacked: Bool = false
    let onOpen: () -> Void
    let onClose: () -> Void

    // "Ask your advisor" pill floating above the tabs (865:13542)
    private static let pillSize = CGSize(width: 294, height: 53)
    // Card (717:10768): 368 × 323, 17pt above the keyboard; the scrim starts at y 64.
    // Without a context chip the card loses the chip's row (the text field moves up to y 79).
    private static let cardSize = CGSize(width: 368, height: 323)
    private static let chipRowHeight: CGFloat = 171 - 79
    private static let cardKeyboardGap: CGFloat = 17
    private static let scrimTop: CGFloat = 64
    private static let fallbackKeyboardHeight: CGFloat = 336

    private func lerp(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * p }

    var body: some View {
        let keyboardTop = bottomAligned
            ? (floatAbove.map { $0 - 14 + Self.cardKeyboardGap } ?? viewport.height - 34)   // 14pt above it
            : viewport.height - (keyboardHeight > 0 ? keyboardHeight : Self.fallbackKeyboardHeight)
        // Beside an action the pill gives up 162: the 155 button and 7 between them
        let restTop = pillTop ?? FloatingTabs.pillTop(viewportHeight: viewport.height)
        let isStacked = stacked && action != nil
        // Stacked, the pill and its mic (53, 9 clear of the pill) share a row 6 shorter than the button and centred on it
        // The button fits its title: 155 for "View plans" (31 before the title, 12 and the 8 chevron after it, 27 to the edge)
        let titleWidth = action.map { ($0.title as NSString).size(withAttributes: [.font: UIFont(name: "GTWalsheimTrial-Rg", size: 17) ?? .systemFont(ofSize: 17)]).width } ?? 0
        let restActionWidth = max(155, (titleWidth + 78).rounded(.up))
        let pillWidth = action == nil ? Self.pillSize.width : isStacked ? viewport.width - 34 - 6 - 62 : viewport.width - 34 - restActionWidth - 7
        // Stacked, the pill sits 7 above the button, which keeps the bar's place
        // Stacked, the button is 5 taller, growing upwards from the bar's foot
        let actionHeight: CGFloat = isStacked ? 58 : 53
        let pill = CGRect(x: isStacked ? 20 : 17, y: restTop - (isStacked ? Self.pillSize.height + 7 + 5 : 0), width: pillWidth, height: Self.pillSize.height)
        // The mic rests 9 beside the pill (303 across the fund page's bar)
        let micRestX = action == nil ? 303 : pill.width + 9
        let actionWidth: CGFloat = isStacked ? viewport.width - 34 : restActionWidth
        // Where the avatar and the prompt rest in the pill: after the plus, or from the pill's edge beside an action
        let avatarX: CGFloat = action == nil ? 41 : 12.3
        let promptX: CGFloat = action == nil ? 78 : 49.3
        let cardHeight = Self.cardSize.height - (context == nil ? Self.chipRowHeight : 0)
        let card = CGRect(
            x: 11, y: keyboardTop - Self.cardKeyboardGap - cardHeight,
            width: Self.cardSize.width, height: cardHeight
        )
        let textY: CGFloat = context == nil ? 79 : 171
        let frame = CGRect(
            x: lerp(pill.minX, card.minX), y: lerp(pill.minY, card.minY),
            width: lerp(pill.width, card.width), height: lerp(pill.height, card.height)
        )
        let radius = lerp(100, 23)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        // Card-only content arrives over the second half of the morph
        let detail = max(0, (p - 0.55) / 0.45)
        let promptOut = 1 - min(1, p / 0.45)

        ZStack(alignment: .topLeading) {
            // Scrim (717:10767): transparent at the top → 18% black at the keyboard
            LinearGradient(colors: [Color.black.opacity(0), Color.black.opacity(0.18)], startPoint: .top, endPoint: .bottom)
                .frame(width: viewport.width, height: max(1, keyboardTop - Self.scrimTop))
                .at(0, Self.scrimTop)
                .opacity(p)
                .allowsHitTesting(isComposing)
                .onTapGesture(perform: onClose)

            // Surface
            shape
                .fill(Color(hex: 0xF9F9F9))
                .overlay(shape.stroke(Color.black.opacity(lerp(0.31, 0.04)), lineWidth: 0.7))
                .shadow(color: Color.black.opacity(lerp(0.03, 0.23)), radius: lerp(15, 7.5), x: 0, y: 3)
                .frame(width: frame.width, height: frame.height)
                // contentShape BEFORE positioning — after the padding it would cover the whole page
                .contentShape(Rectangle())
                .onTapGesture { if !isComposing { onOpen() } }
                .at(frame.minX, frame.minY)

            // Context chip (717:10770) — only when a widget was swiped in
            if let context {
                contextChip(context)
                    .opacity(detail)
                    .offset(y: (1 - detail) * 10)
                    .allowsHitTesting(false)
                    .at(frame.minX + 13, frame.minY + 79)
            }

            // Avatar + name (717:10791)
            ZStack(alignment: .topLeading) {
                Image("ChatAvatarLarge")
                    .resizable()
                    .frame(width: 67, height: 67)
                    .at(5, -3)
                Text("Akshima")
                    .font(FigmaFont.reckless(19))
                    .foregroundStyle(Color(hex: 0x212121).opacity(0.74))
                    .frame(width: 76, height: 25)
                    .at(0, 62)
            }
            .frame(width: 76, height: 87, alignment: .topLeading)
            .opacity(detail)
            .allowsHitTesting(false)
            .at(frame.minX + 17, frame.minY - 19)

            // Close (717:10790) — U+100184 = xmark
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(detail)
            .allowsHitTesting(isComposing)
            .position(x: frame.minX + 324 + 11.5, y: frame.minY + 19 + 13.5)

            // Advisor avatar inside the pill (865:13546); the composer's large avatar takes over as it opens
            Image("PillAvatar")
                .resizable()
                .frame(width: 32.9508, height: 32.9508)
                .opacity(promptOut)
                .allowsHitTesting(false)
                .at(frame.minX + avatarX - 1.475, frame.minY + 12 - 1.475)

            // Text field: pill (78, 15) → card (17, 171)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    // Beside a wide button there is no room for the whole prompt
                    Text(pill.width < 185 ? "Ask advisor" : "Ask your advisor")
                        .font(FigmaFont.walsheim(17))
                        .foregroundStyle(Color.black.opacity(0.67))
                        .opacity(promptOut)
                    Text("Start typing")
                        .font(FigmaFont.walsheim(17))
                        .foregroundStyle(Color.black.opacity(0.67))
                        .opacity(1 - promptOut)
                }
                TextField("", text: $text)
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color.black.opacity(0.83))
                    .focused($isFocused)
                    .submitLabel(.send)
                    .allowsHitTesting(isComposing)
            }
            .frame(width: lerp(pill.width - promptX - 12, card.width - 34), height: 23, alignment: .leading)
            .allowsHitTesting(isComposing)
            .at(frame.minX + lerp(promptX, 17), frame.minY + lerp(15, textY))

            // Plus: pill centre (20.5, 27.3) → card (17, 290.8)
            Image("PlusIcon")
                .resizable()
                .frame(width: 13.0239, height: 13.0156)
                .opacity(action == nil ? 1 : detail)
                .allowsHitTesting(false)
                .at(frame.minX + lerp(20.5 - 6.51, 17), frame.minY + lerp(27.33 - 6.51, card.height - 18.46 - 13.0156))

            // Mic: beside the pill (303, 0 of the bar row) → inside the card (300, 255). SVG carries its shadow (129 × 129).
            Image(p < 0.5 ? "MicButton" : "MicButtonComposer")
                .resizable()
                .frame(width: 129, height: 129)
                // Beside an action the mic is only there once the bar has stacked: it pops in past its size and
                // settles, riding along as the pill stretches, and shrinks away when the bar goes back
                .scaleEffect(action == nil || isStacked ? 1 : p)
                .opacity(action == nil || isStacked ? 1 : detail)
                .animation(.spring(duration: 0.55, bounce: 0.5), value: isStacked)
                .allowsHitTesting(false)
                .at(frame.minX + lerp(micRestX, 300) - 38, frame.minY + lerp(0, card.height - 14.3 - 53) - 35)

            // The page's own button beside the pill (659:19997): 155 × 53, gone while composing
            if let action {
                Button(action: action.run) {
                    // The title and chevron keep to the middle as the button widens (31 and 120.3 across its 155 at rest)
                    HStack(spacing: 12) {
                        Text(action.title)
                            .font(FigmaFont.walsheim(17))
                            .foregroundStyle(Color.white)
                            .fixedSize()
                        Image("FDBarChevron")
                            .rotationEffect(.degrees(180))
                    }
                    .offset(x: 2)
                    .frame(width: actionWidth, height: actionHeight)
                    .background(Capsule().fill(Color(hex: 0x1F1513)))
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.12), lineWidth: 0.7))
                    .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(action.title)
                .opacity(promptOut)
                .allowsHitTesting(!isComposing)
                .at(viewport.width - 17 - actionWidth, restTop - (actionHeight - 53))
                // A page can bring its button in later: it grows out of the bar's trailing end as the pill makes room
                .transition(.scale(scale: 0.4, anchor: UnitPoint(x: 1 - 94.5 / viewport.width, y: (restTop + 26.5) / viewport.height)).combined(with: .opacity))
            }
        }
        .frame(width: viewport.width, height: viewport.height, alignment: .topLeading)
        .opacity(bottomAligned ? min(1, p * 4) : 1)
        .allowsHitTesting(!bottomAligned || isComposing)
    }

    private func contextChip(_ context: FundContext) -> some View {
        ZStack(alignment: .topLeading) {
            Color.white

            Group {
                if context.hasLogo {
                    Image(context.icon).resizable().aspectRatio(contentMode: .fill)
                } else {
                    Image(context.icon).resizable().frame(width: 36, height: 39)
                }
            }
            .frame(width: 37, height: 37)
            .clipped()
            .at(13, 17)

            Text(context.title)
                .font(FigmaFont.walsheim(15))
                .foregroundStyle(Color.black.opacity(0.83))
                .at(61, 17)

            Text(context.subtitle)
                .font(FigmaFont.walsheim(14))
                .foregroundStyle(Color.black.opacity(0.56))
                // A long line (a fund's name) stops short of the sparkline
                .lineLimit(1)
                .frame(maxWidth: 190, alignment: .leading)
                .at(61, 39)

            if let deposit = context.deposit {
                Text(deposit.rate)
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color(hex: 0x01B405))
                    .frame(width: 340 - 17, height: 37, alignment: .trailing)
                    .at(0, 17)
            } else {
                Image("Sparkline")
                    .resizable()
                    .frame(width: 37.9174, height: 31)
                    .at(259, 20)
            }

            Rectangle()
                .fill(Color.black.opacity(0.09))
                .frame(width: 340, height: 1)
                .at(0, 70)
        }
        .frame(width: 340, height: 71)
        .clipped()
        .overlay(Rectangle().stroke(Color.black.opacity(0.05), lineWidth: 0.945))
        .shadow(color: Color.black.opacity(0.03), radius: 38, x: 0, y: 3)
    }
}
