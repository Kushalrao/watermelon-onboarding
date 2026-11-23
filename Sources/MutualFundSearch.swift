import SwiftUI

/// What goes in a mutual funds page's search field (Figma 101:18267 on the explore page, 13:5408 on a category's):
/// the field's own word in capitals while nothing is typed, what is typed once something is, and, while search
/// is in use, a cross at the trailing end that cancels it. The pill round it is the page's own, which runs the
/// width of the page while search is in use, with the page's back button out of the way.
///
/// The frames draw the field at rest only; how it is typed into is made here.
struct FundSearchField: View {
    /// The field's word at rest: "SEARCH MID CAP"
    let prompt: String
    /// The size its words are set at: 15 on the explore page, 17 on a category's
    var size: CGFloat = 15
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
    /// Search is in use: the cross is there
    var active = false
    /// The cross was tapped: the page ends the search
    var onCancel: () -> Void = {}

    private static let promptInk = Color.black.opacity(0.5) // Gap: black 50%, the search field's word, is unbound

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    // Gap: Md 15/21 and 17/23 at 5% tracking, in capitals, have no text style
                    GapText(prompt, family: .walsheim, medium: true, size: size, lineHeight: size + 6, trackingPercent: 5, color: Self.promptInk)
                        .fixedSize()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                TextField("", text: $text)
                    .font(FigmaFont.walsheimMedium(size)) // ds-lint-ignore: no_hand_set_type (a text field's own type; DsText sets labels, not fields)
                    .foregroundStyle(ColorScale.contentPrimary)
                    .tint(ColorScale.contentPrimary)
                    .focused(focused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityLabel(prompt.capitalized)
            }
            if active {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .medium)) // ds-lint-ignore: no_hand_set_type (an SF Symbol's size and weight)
                        .foregroundStyle(ColorScale.contentSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel search")
                .transition(.opacity)
            }
        }
    }
}

extension ListedFund {
    /// Every word typed is in the fund's name or its house's, whatever the case: what a category's page filters
    /// its own funds by. Nothing typed matches every fund.
    func matches(_ typed: String) -> Bool {
        let words = typed.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        guard !words.isEmpty else { return true }
        let named = "\(name) \(house)".lowercased()
        return words.allSatisfy { named.contains($0) }
    }
}

/// Lays views out in rows, as many to a row as fit its width, each row starting at the leading edge
struct FlowRows: Layout {
    var spacing: CGFloat

    private func rows(_ subviews: Subviews, width: CGFloat) -> [[(index: Int, size: CGSize)]] {
        var rows: [[(index: Int, size: CGSize)]] = [[]]
        var used: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !rows[rows.count - 1].isEmpty, used + spacing + size.width > width {
                rows.append([])
                used = 0
            }
            used += (rows[rows.count - 1].isEmpty ? 0 : spacing) + size.width
            rows[rows.count - 1].append((index, size))
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(subviews, width: proposal.width ?? .infinity)
        var widest: CGFloat = 0
        var height: CGFloat = 0
        for row in rows {
            var across: CGFloat = 0
            var tall: CGFloat = 0
            for item in row {
                across += item.size.width
                tall = max(tall, item.size.height)
            }
            across += spacing * CGFloat(max(row.count - 1, 0))
            widest = max(widest, across)
            height += tall
        }
        height += spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(subviews, width: bounds.width) {
            var x = bounds.minX
            var tall: CGFloat = 0
            for item in row { tall = max(tall, item.size.height) }
            for item in row {
                let place = CGPoint(x: x, y: y + (tall - item.size.height) / 2)
                subviews[item.index].place(at: place, proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += tall + spacing
        }
    }
}

/// A kind of fund as a chip: its orb and its name in a white pill (Figma 47:7332, 111:20982). Gap: #FEFEFE with a
/// 1 pt edge in the frames; here the white widget surface with the hairline.
struct FundKindChip: View {
    let title: String
    /// The orb, an image set's name
    let orb: String

    var body: some View {
        Surface(surface: .surfaceWidget, shape: .capsule, border: .borderSubtle, shadow: .token(.shadow1)) {
            Stack(direction: .horizontal, gap: .spaceMd, alignment: .center) {
                // The orb is drawn with its own soft shadow, 44.18 across around its 27
                Image(orb)
                    .resizable()
                    .frame(width: 44.18, height: 44.18)
                    .frame(width: 27, height: 27)
                    .accessibilityHidden(true)
                // Gap: P4 on the 21 pt line this file gives it (the token's line is 23)
                GapText(title, family: .walsheim, medium: false, size: 15, lineHeight: 21, color: ColorScale.contentPrimary)
                    .fixedSize()
            }
            .padding(.horizontal, SpacingScale.spaceLg)
            .padding(.vertical, 12) // Gap: 12 above and below, edge included, no spacing token
            .clipShape(Capsule())
        }
        .contentShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// What a list of funds' two columns are, over the funds (Figma 111:21200, 111:20976): "FUND", and "3Y RETURNS"
/// with an arrow, which does not open anything yet
struct FundColumns: View {
    private static let ink = Color.black.opacity(0.5) // Gap: black 50%, a list's column names, is unbound

    var body: some View {
        HStack(spacing: 5.86) { // Gap: 5.86 from the words to the arrow, no spacing token
            // Gap: Md 15/21 at 5% tracking, in capitals, has no text style
            GapText("FUND", family: .walsheim, medium: true, size: 15, lineHeight: 21, trackingPercent: 5, color: Self.ink)
                .fixedSize()
            Spacer(minLength: 0)
            GapText("3Y RETURNS", family: .walsheim, medium: true, size: 15, lineHeight: 21, trackingPercent: 5, color: Self.ink)
                .fixedSize()
            Image("MFExploreChevronDown")
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Funds, by what they have returned a year over three years")
    }
}
