import SwiftUI

/// A widget lifted out of the page by a long press (753:12431): it floats with a large drop shadow
/// and question chips emerge from its bottom-left corner. Stays until the user taps outside.
struct HeldWidget: Equatable {
    let context: FundContext
    /// The widget's frame on screen at the moment it was picked up
    let frame: CGRect
}

struct HeldWidgetLayer<Widget: View>: View {
    /// The lifted widget's frame on screen; nil when nothing is held
    let frame: CGRect?
    let questions: [String]
    /// 0 = resting in the page, 1 = fully lifted
    let progress: CGFloat
    /// Chips animate out of the widget's corner when this turns true, one after another
    let chipsOut: Bool
    let onDismiss: () -> Void
    @ViewBuilder let widget: () -> Widget

    private let chipGap: CGFloat = 16      // 254 - 238
    private let chipSpacing: CGFloat = 76  // 330 - 254

    var body: some View {
        if let original = frame {
            let p = progress
            let radius = 23 * p
            // A widget low on the page rises as it lifts so its chips stay on screen (above the floating bar)
            let chipsBottom = original.maxY + chipGap + chipSpacing * CGFloat(max(0, questions.count - 1)) + 63
            let available = UIScreen.main.bounds.height - 190
            let rise = max(min(0, available - chipsBottom), 60 - original.minY)
            let frame = original.offsetBy(dx: 0, dy: rise * p)

            ZStack(alignment: .topLeading) {
                // Tap anywhere outside to put the widget back
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onDismiss)

                // The lifted widget (753:12109): rounded 23, hairline border, big soft shadow
                widget()
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(Color.black.opacity(0.04), lineWidth: 1)
                    )
                    .shadow(color: Color(hex: 0x61625F).opacity(0.23 * p), radius: 60 * p, x: 0, y: 3)
                    .shadow(color: Color(hex: 0x61625F).opacity(0.12 * p), radius: 120 * p, x: 0, y: 3)
                    .scaleEffect(1 + 0.03 * p, anchor: .center)
                    .frame(width: frame.width, height: frame.height)
                    .at(frame.minX, frame.minY)

                // Question chips grow out of the widget's bottom-left corner one after the other,
                // each one quicker than the last (see `Stagger`)
                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    let restingY = frame.maxY + chipGap + chipSpacing * CGFloat(index)
                    let timing = Stagger.arrival(index, first: 0.5)

                    QuestionChip(title: question)
                        .scaleEffect(chipsOut ? 1 : 0.3, anchor: .topLeading)
                        .opacity(chipsOut ? 1 : 0)
                        .offset(y: chipsOut ? 0 : frame.maxY - 24 - restingY)
                        .animation(
                            chipsOut
                                ? .spring(response: timing.response, dampingFraction: 0.78).delay(timing.delay)
                                : .easeOut(duration: 0.12),
                            value: chipsOut
                        )
                        .at(frame.minX, restingY)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .allowsHitTesting(p > 0.5)
        }
    }
}

/// Suggested question chip (753:12225 / 753:12364), 63 tall, hugs its text
private struct QuestionChip: View {
    let title: String

    var body: some View {
        HStack(spacing: 0) {
            // Avatar with a small HSBC badge (753:12299)
            ZStack(alignment: .topLeading) {
                Image("ChatAvatarSmall")
                    .resizable()
                    .frame(width: 38.54, height: 38.54)

                HSBCLogoCrop(slot: CGSize(width: 15.105, height: 16.544), scaleW: 2.9091, scaleH: 1.9428, leftPct: -0.2963, topPct: -0.4714)
                    .offset(x: -0.72, y: -0.72)
                    .frame(width: 14.386, height: 14.386, alignment: .topLeading)
                    .clipped()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 2.877))
                    .overlay(RoundedRectangle(cornerRadius: 2.877).stroke(Color.white, lineWidth: 1.439))
                    .at(26.24, 26.24)
            }
            .frame(width: 41, height: 41)
            .padding(.leading, 11)

            Text(title)
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.black)
                .padding(.leading, 15)
                .padding(.trailing, 23)
        }
        .frame(height: 63)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 100))
        .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.black.opacity(0.05), lineWidth: 2))
        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
    }
}
