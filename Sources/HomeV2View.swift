import SwiftUI

/// Figma: "iPhone 14 Plus - 272" (node 962:22359) — the second home page: a greeting with today's summary.
/// The hand waves once when the page appears. Tapping the Investments row or a chat opens the fund page.
struct HomeV2View: View {
    var onOpenFund: () -> Void = {}

    @State private var waved = false
    /// 0 = the summary paragraph takes no space, 1 = its full height; grows with its reveal, pushing the rest down
    @State private var paragraphSpace: CGFloat = 0

    /// Paragraph top (228) to the timestamp (399) in Figma
    private static let paragraphHeight: CGFloat = 171
    /// Extra room above the horse and greeting; the search button stays at its Figma spot
    private static let topSpace: CGFloat = 240

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        BackgroundBlobs(wash: 0.87)

                        // A puppeted horse walks in from the left and stops here (replaces the 962:25128 mark)
                        WalkingHorse(start: waved)
                            .at(4, Self.topSpace + 48)

                        // Figma: U+1002AB in SF Compact Rounded Regular 23 = "magnifyingglass"
                        Button(action: { Haptics.tap() }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 23, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.black.opacity(0.73))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .at(367 - 33, 69 - 10)

                        Text("Hello Jojo")
                            .font(FigmaFont.reckless(43))
                            .foregroundStyle(Color.ink)
                            .at(17, Self.topSpace + 166)

                        // Same reveal as "Analysed for you", in grays only (dark → light), settling to the 71% black
                        RevealParagraph(
                            text: "Your accounts look in control this morning. Savings are on track, your investments are doing their job quietly, and there’s nothing unusual in your spending. You’re in a good place.",
                            isRevealed: waved,
                            fontSize: 21,
                            lineSpacing: 2,
                            gradient: [Color(white: 0.12), Color(white: 0.72)]
                        )
                        // Only the part that has made room so far is shown
                        .frame(width: 356, height: Self.paragraphHeight * paragraphSpace, alignment: .top)
                        .clipped()
                        .at(17, Self.topSpace + 228)

                        belowParagraph
                            .offset(y: Self.topSpace - Self.paragraphHeight * (1 - paragraphSpace))
                    }
                    // Room below the last chat for the floating nav
                    .frame(width: 390, height: 1150 + Self.topSpace, alignment: .topLeading)
                    .clipped()
                    .frame(maxWidth: .infinity)
                }

                // Same spot as the v1 home (Figma 114pt above the bottom, pulled 20pt lower)
                HomeNavBar(
                    left: "HomeV2NavLeft", right: "HomeV2NavRight",
                    leftArt: CGRect(x: -67, y: -64, width: 348, height: 197),
                    rightArt: CGRect(x: -67, y: -64, width: 254, height: 197)
                )
                .at(17, geo.size.height - 94)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .background(Color.screenBackground)
        }
        .ignoresSafeArea()
        .onAppear {
            // Wave once, just after the page settles; the paragraph opens up in step with its wipe
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                waved = true
                withAnimation(.easeOut(duration: 0.6).delay(0.3)) { paragraphSpace = 1 }
            }
        }
    }

    /// Everything under the summary paragraph, at its Figma positions
    private var belowParagraph: some View {
        ZStack(alignment: .topLeading) {
                        Text("Just now • 01:22 PM")
                            .font(FigmaFont.walsheim(13))
                            .tracking(1.17)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.black.opacity(0.47))
                            .at(17, 399)

                        StatusCard(onOpenFund: onOpenFund)
                            .at(11, 443)

                        Text("Last week")
                            .font(FigmaFont.walsheimMedium(23))
                            .foregroundStyle(Color.black)
                            .at(15, 645)

                        VStack(spacing: 5) {
                            ForEach(ChatPreview.all) { chat in
                                ChatRow(chat: chat, action: onOpenFund)
                            }
                        }
                        .at(15, 691)
        }
    }
}

// MARK: - Today's status (962:23550)

private struct StatusCard: View {
    let onOpenFund: () -> Void

    private let rows: [(title: String, status: String, color: UInt32, y: CGFloat)] = [
        ("Investments", "Consistent this month", 0x2ACA1F, 0),
        ("Portfolio strength", "Strong", 0x0DC1D8, 57),
        ("Market", "Short term effects", 0xCE9C03, 114),
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white

            ForEach(rows, id: \.title) { row in
                Button {
                    Haptics.tap()
                    if row.title == "Investments" { onOpenFund() }
                } label: {
                    ZStack(alignment: .topLeading) {
                        Color.white

                        // Figma: U+10321F in SF Compact Rounded Regular 19 = "graph.2d"
                        Image(systemName: "graph.2d")
                            .font(.system(size: 19, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.black)
                            .frame(height: 25)
                            .at(17, 15)

                        Text(row.title)
                            .font(FigmaFont.walsheim(17))
                            .foregroundStyle(Color.black)
                            .frame(height: 29)
                            .at(47, 13)

                        Text(row.status)
                            .font(FigmaFont.walsheimMedium(15))
                            .foregroundStyle(Color(hex: row.color))
                            .frame(width: 334, height: 23, alignment: .trailing)
                            .at(17, 18)
                    }
                    .frame(width: 368, height: 57)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .at(0, row.y)
            }

            ForEach([57, 114], id: \.self) { y in
                Rectangle()
                    .fill(Color.black.opacity(0.17))
                    .frame(width: 368, height: 1)
                    .at(0, CGFloat(y))
            }
        }
        .frame(width: 368, height: 169)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
    }
}

#Preview {
    HomeV2View()
}
