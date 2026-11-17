import SwiftUI
import UIKit
import UIKit.UIGestureRecognizerSubclass

/// Text that can be selected the way the system's can: a long press picks up the word under the finger, with the
/// handles to stretch it and the menu over it. Drawn by a text view, since SwiftUI's own `Text` only offers the
/// whole string to copy. Lays out as `Text` does with the same font and line spacing: no insets, no padding.
struct SelectableText: View {
    enum Face {
        case walsheim(CGFloat), walsheimMedium(CGFloat), reckless(CGFloat), recklessRegular(CGFloat)

        var font: UIFont {
            let (name, size): (String, CGFloat) = switch self {
            case .walsheim(let s): ("GTWalsheimTrial-Rg", s)
            case .walsheimMedium(let s): ("GTWalsheimTrial-Md", s)
            case .reckless(let s): ("RecklessStandardS-TRIAL-Medium", s)
            case .recklessRegular(let s): ("RecklessStandardS-TRIAL-Regular", s)
            }
            return UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
        }
    }

    let string: String
    let face: Face
    let color: Color
    var lineSpacing: CGFloat = 0

    init(_ string: String, _ face: Face, color: Color, lineSpacing: CGFloat = 0) {
        self.string = string
        self.face = face
        self.color = color
        self.lineSpacing = lineSpacing
    }

    var body: some View {
        Field(string: string, font: face.font, color: UIColor(color), lineSpacing: lineSpacing)
    }

    private struct Field: UIViewRepresentable {
        let string: String
        let font: UIFont
        let color: UIColor
        let lineSpacing: CGFloat

        func makeUIView(context: Context) -> SelectableTextView {
            let view = SelectableTextView()
            view.isEditable = false
            view.isSelectable = true
            view.isScrollEnabled = false
            view.backgroundColor = .clear
            view.textContainerInset = .zero
            view.textContainer.lineFragmentPadding = 0
            view.adjustsFontForContentSizeCategory = false
            view.clipsToBounds = false
            // The selection and its handles in the page's ink, not the system's blue
            view.tintColor = UIColor(Color.ink)
            // Read out, and found, as the plain text it stands in for
            view.isAccessibilityElement = true
            view.accessibilityTraits = .staticText
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            return view
        }

        func updateUIView(_ view: SelectableTextView, context: Context) {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = lineSpacing
            let attributed = NSAttributedString(string: string, attributes: [
                .font: font, .foregroundColor: color, .paragraphStyle: paragraph,
            ])
            if view.attributedText != attributed { view.attributedText = attributed }
            view.accessibilityLabel = string
        }

        func sizeThatFits(_ proposal: ProposedViewSize, uiView: SelectableTextView, context: Context) -> CGSize? {
            let width = proposal.width ?? .greatestFiniteMagnitude
            let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            return CGSize(width: ceil(fitted.width), height: ceil(fitted.height))
        }
    }
}

/// What's selected on the page, once the selection has been left alone for a moment: the page's own suggestions
/// come up beside it then, in place of the system's menu.
@Observable final class TextSelectionCenter {
    static let shared = TextSelectionCenter()

    /// The selected words; nil while nothing's selected, or while the selection is still being made
    private(set) var text: String?
    /// Where they are on screen (it moves with the page)
    private(set) var rect: CGRect = .zero
    /// Where the suggestions are on screen, so a tap on them isn't taken as a tap away
    @ObservationIgnored var menuFrame: CGRect = .zero
    @ObservationIgnored fileprivate weak var source: SelectableTextView?

    /// How long a selection has to be left alone before the suggestions come
    static let settle: TimeInterval = 0.45

    fileprivate func show(_ text: String, at rect: CGRect, from source: SelectableTextView) {
        self.source = source
        self.rect = rect
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { self.text = text }
    }

    fileprivate func move(to rect: CGRect) { self.rect = rect }

    fileprivate func hide() {
        guard text != nil else { return }
        withAnimation(.easeOut(duration: 0.12)) { text = nil }
    }

    /// Lets the selection go
    func clear() {
        source?.selectedTextRange = nil
        source?.resignFirstResponder()
        hide()
    }
}

/// The text view behind `SelectableText`. Every one on screen is known here, so a gesture that would otherwise take
/// a long press (a widget's lift) can stand aside when the finger is on text. The system's menu never shows over a
/// selection: once the finger's up and the selection's been still for `TextSelectionCenter.settle`, it's handed to the page.
final class SelectableTextView: UITextView, UITextViewDelegate {
    private static let all = NSHashTable<SelectableTextView>.weakObjects()
    private static let dismissers = NSMapTable<UIWindow, UITapGestureRecognizer>.weakToStrongObjects()

    fileprivate var settling: DispatchWorkItem?
    private var scrolling: NSKeyValueObservation?

    /// Whether `point`, in `view`'s measure, is on selectable text
    static func isText(at point: CGPoint, in view: UIView) -> Bool {
        all.allObjects.contains { text in
            text.window != nil && !text.isHidden && text.bounds.contains(view.convert(point, to: text))
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window else { return }
        delegate = self
        Self.all.add(self)
        // One tap listener a window: a tap anywhere off the text that holds a selection lets it go
        if Self.dismissers.object(forKey: window) == nil {
            let tap = UITapGestureRecognizer(target: SelectableTextView.self, action: #selector(SelectableTextView.tapped(_:)))
            tap.cancelsTouchesInView = false
            tap.delaysTouchesEnded = false
            window.addGestureRecognizer(tap)
            Self.dismissers.setObject(tap, forKey: window)
            // and one that only watches for the finger going down and coming up
            window.addGestureRecognizer(FingerWatch())
        }
    }

    /// Whether a finger is on the screen
    fileprivate static var fingerDown = false

    /// The finger went down, or came up. While it's down the selection is still being made (the word picked up, and
    /// then dragged out over more of them), so the wait for it to settle only starts once the finger's gone
    fileprivate static func finger(down: Bool) {
        fingerDown = down
        for text in all.allObjects where text.selectedRange.length > 0 {
            if down { text.settling?.cancel() } else if TextSelectionCenter.shared.text == nil { text.waitToSettle() }
        }
    }

    private func waitToSettle() {
        settling?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.settled() }
        settling = work
        DispatchQueue.main.asyncAfter(deadline: .now() + TextSelectionCenter.settle, execute: work)
    }

    @objc private static func tapped(_ tap: UITapGestureRecognizer) {
        guard let window = tap.view else { return }
        // A tap on the suggestions is theirs
        if TextSelectionCenter.shared.text != nil, TextSelectionCenter.shared.menuFrame.contains(tap.location(in: window)) { return }
        for text in all.allObjects where text.selectedRange.length > 0 {
            if !text.bounds.contains(tap.location(in: text)) {
                text.selectedTextRange = nil
                text.resignFirstResponder()
            }
        }
    }

    // MARK: No system menu

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool { false }

    func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        UIMenu(children: [])
    }

    // MARK: The selection, handed to the page once it's still

    func textViewDidChangeSelection(_ textView: UITextView) {
        let center = TextSelectionCenter.shared
        settling?.cancel()
        scrolling = nil
        guard selectedRange.length > 0 else {
            if center.source === self { center.hide() }
            return
        }
        // Being made, or stretched: nothing shows until it's left alone. Only one text holds a selection at a time
        if let other = center.source, other !== self { other.selectedTextRange = nil }
        center.hide()
        // With the finger still down it's not finished; the wait starts when the finger comes up
        if !Self.fingerDown { waitToSettle() }
    }

    private func settled() {
        guard !Self.fingerDown else { return }
        guard let range = selectedTextRange, let words = text(in: range), !words.isEmpty, let rect = selectionRect() else { return }
        TextSelectionCenter.shared.show(words, at: rect, from: self)
        // The page scrolls under the finger: the suggestions go with the words
        var ancestor = superview
        while let view = ancestor, !(view is UIScrollView) { ancestor = view.superview }
        scrolling = (ancestor as? UIScrollView)?.observe(\.contentOffset) { [weak self] _, _ in
            guard let self, TextSelectionCenter.shared.source === self, let rect = self.selectionRect() else { return }
            TextSelectionCenter.shared.move(to: rect)
        }
    }

    /// The selected words' box on screen
    private func selectionRect() -> CGRect? {
        guard let range = selectedTextRange else { return nil }
        let boxes = selectionRects(for: range).map(\.rect).filter { $0.width > 0.5 }
        guard let first = boxes.first else { return nil }
        return convert(boxes.dropFirst().reduce(first) { $0.union($1) }, to: nil)
    }
}

/// Watches the finger go down and come up anywhere in the window, and takes nothing: it never recognises, so
/// every touch goes on to whatever it was for.
private final class FingerWatch: UIGestureRecognizer {
    private var count = 0

    init() {
        super.init(target: nil, action: nil)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        // A finger on the suggestions is choosing one, not selecting
        let window = view
        let onMenu = TextSelectionCenter.shared.text != nil && touches.contains { TextSelectionCenter.shared.menuFrame.contains($0.location(in: window)) }
        count += touches.count
        if !onMenu { SelectableTextView.finger(down: true) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) { lifted(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) { lifted(touches) }

    private func lifted(_ touches: Set<UITouch>) {
        count = max(0, count - touches.count)
        guard count == 0 else { return }
        SelectableTextView.finger(down: false)
        state = .failed
    }

    override func reset() {
        super.reset()
        count = 0
    }

    override func canPrevent(_ other: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by other: UIGestureRecognizer) -> Bool { false }
}

// MARK: - The page's suggestions for a selection

/// What the advisor could be asked about the words selected
enum SelectionQuestions {
    private static let known: [(words: [String], questions: [String])] = [
        (["expense ratio", "expense"], ["Is this expense ratio low?", "How do expenses eat my returns?"]),
        (["commission"], ["Who earns commission on funds?", "What do commissions cost me?"]),
        (["reinvest", "earnings", "paying them out"], ["How does reinvesting grow my money?", "Growth or payout: which suits me?"]),
        (["direct"], ["Direct or regular: which is better?", "How much do I save with direct?"]),
        (["midcap", "mid-sized"], ["Are midcaps risky for me?", "How have midcaps done lately?"]),
        (["growth"], ["What is a growth fund?", "Growth or payout: which suits me?"]),
        (["risk", "appetite"], ["Why is this risky for me?", "How much risk should I take?"]),
        (["goal"], ["Why do my goals stretch?", "How can I stay on track?"]),
        (["performance", "gone down"], ["Why has performance dropped?", "Should I wait or exit?"]),
        (["nav"], ["What is NAV?", "Does a high NAV matter?"]),
        (["hsbc"], ["Is HSBC a good fund house?", "Who manages this fund?"]),
        (["1st of every month", "month"], ["What happens on the 1st?", "Can I change my SIP date?"]),
    ]

    static func questions(for selection: String) -> [String] {
        let words = selection.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = words.lowercased()
        if let match = known.first(where: { entry in entry.words.contains { lower.contains($0) } }) {
            return match.questions
        }
        // A word or two: asked about by name. More than that: asked about as a passage
        if words.split(separator: " ").count <= 3 {
            let quoted = words.count > 22 ? String(words.prefix(21)) + "…" : words
            return ["What does “\(quoted)” mean?", "Why does “\(quoted)” matter?"]
        }
        return ["Explain this in simple words", "What does this mean for me?"]
    }
}

/// The suggestions, by the selected words: the questions that could be asked about them, and Copy. Under the
/// words where there's room above the floating bar, over them where there isn't.
struct SelectionSuggestionsLayer: View {
    /// A question was picked
    let onAsk: (String) -> Void

    private var center: TextSelectionCenter { .shared }
    @State private var size: CGSize = .zero
    @State private var copied = false

    private static let gap: CGFloat = 18      // clear of the selection's handles
    private static let margin: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            if let words = center.text {
                let rect = center.rect
                let below = rect.maxY + Self.gap
                // The floating bar and tabs take the last 190
                let fitsBelow = below + size.height <= geo.size.height - 190
                let y = fitsBelow ? below : max(60, rect.minY - Self.gap - size.height)
                let x = max(Self.margin, min(rect.minX, geo.size.width - Self.margin - size.width))

                VStack(alignment: .leading, spacing: 13) {
                    ForEach(SelectionQuestions.questions(for: words), id: \.self) { question in
                        Button {
                            Haptics.tap()
                            center.clear()
                            onAsk(question)
                        } label: {
                            QuestionChip(title: question)
                        }
                        .buttonStyle(PressScaleStyle())
                    }

                    Button {
                        UIPasteboard.general.string = words
                        Haptics.tap()
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            center.clear()
                            copied = false
                        }
                    } label: {
                        CopyChip(copied: copied)
                    }
                    .buttonStyle(PressScaleStyle())
                }
                .lineLimit(1)
                .frame(maxWidth: geo.size.width - Self.margin * 2, alignment: .leading)
                .fixedSize()
                .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { center.menuFrame = $0 }
                .at(x, y)
                // Out of the words, and back into them
                .transition(.scale(scale: 0.3, anchor: fitsBelow ? .topLeading : .bottomLeading).combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
    }
}

/// Copy, beside the questions: the same pill, without the advisor
private struct CopyChip: View {
    let copied: Bool

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: copied ? "checkmark" : "square.on.square")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.7))
                .frame(width: 20)
                .contentTransition(.symbolEffect(.replace))
            Text(copied ? "Copied" : "Copy")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black)
        }
        .padding(.leading, 18)
        .padding(.trailing, 23)
        .frame(height: 49)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 100))
        .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.black.opacity(0.05), lineWidth: 2))
        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
    }
}
