import SwiftUI

/// Pull-down global search, like Spotlight on the Mac. Pulling the home page down past `threshold` and letting go
/// opens it: the page sinks a little and recedes, and the search bar drops in from 1.3× to its size with the keyboard
/// already up. Tapping outside, Cancel, or a result closes it.
struct QuickSearchOverlay: View {
    /// One thing search can find: an SF Symbol or an asset for its mark, and words beyond its title to match on
    struct Item: Identifiable {
        var icon = "magnifyingglass"
        var image: String? = nil
        let title: String
        let detail: String
        var keywords = ""
        var id: String { title }
    }

    var placeholder = "Search funds, chats, anything"
    /// What to search; the home page's own suggestions when nil
    var items: [Item]? = nil
    var onPick: (Item) -> Void = { _ in }
    let onClose: () -> Void

    @State private var query = ""
    @State private var shown = false
    @FocusState private var focused: Bool

    /// How far the page has to be pulled before letting go opens search
    static let threshold: CGFloat = 70

    private static let suggestions: [Item] = [
        Item(icon: "chart.line.uptrend.xyaxis", title: "HSBC Midcap Direct Growth", detail: "Fund"),
        Item(icon: "bubble.left", title: "SBI Mutual fund discussion", detail: "Chat"),
        Item(icon: "calendar", title: "Next SIP on 1 Dec", detail: "Reminder"),
        Item(icon: "shield", title: "Term insurance", detail: "Chat"),
    ]

    /// With nothing typed, the first few; otherwise whatever the words match, by title, kind or keyword
    private var results: [Item] {
        let all = items ?? Self.suggestions
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if q.isEmpty { return Array(all.prefix(items == nil ? all.count : 7)) }
        return Array(all.filter { ($0.title + " " + $0.detail + " " + $0.keywords).lowercased().contains(q) }.prefix(7))
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Tap anywhere outside to close
            Color.black.opacity(shown ? 0.08 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { close() }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.55))
                    TextField("", text: $query, prompt: Text(placeholder).foregroundStyle(Color.black.opacity(0.4)))
                        .font(FigmaFont.walsheim(18))
                        .foregroundStyle(Color.black)
                        .focused($focused)
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Color.black.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .frame(height: 58)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.7), lineWidth: 0.8))
                .shadow(color: Color.black.opacity(0.14), radius: 30, x: 0, y: 14)

                if !results.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.offset) { index, item in
                            Button { close { onPick(item) } } label: {
                                HStack(spacing: 12) {
                                    if let image = item.image {
                                        Image(image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 32, height: 32)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    } else {
                                        Image(systemName: item.icon)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(Color.black.opacity(0.7))
                                            .frame(width: 32, height: 32)
                                            .background(Circle().fill(Color.black.opacity(0.05)))
                                    }
                                    Text(item.title)
                                        .font(FigmaFont.walsheim(16))
                                        .foregroundStyle(Color.black)
                                        .lineLimit(1)
                                    Spacer(minLength: 8)
                                    Text(item.detail)
                                        .font(FigmaFont.walsheim(13))
                                        .foregroundStyle(Color.black.opacity(0.4))
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 50)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if index < results.count - 1 {
                                Rectangle().fill(Color.black.opacity(0.06)).frame(height: 0.5).padding(.leading, 58)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 24, x: 0, y: 10)
                }

                HStack {
                    Spacer()
                    Button("Cancel") { close() }
                        .font(FigmaFont.walsheimMedium(15))
                        .foregroundStyle(Color.black.opacity(0.6))
                }
                .padding(.horizontal, 6)
            }
            .padding(.horizontal, 15)
            .padding(.top, 62)
            // Drops in from 1.3× to its size
            .scaleEffect(shown ? 1 : 1.3, anchor: .top)
            .opacity(shown ? 1 : 0)
            .blur(radius: shown ? 0 : 6)
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) { shown = true }
            // Keyboard comes up as the bar lands
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { focused = true }
        }
    }

    private func close(then: @escaping () -> Void = {}) {
        focused = false
        withAnimation(.easeIn(duration: 0.18)) { shown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            onClose()
            then()
        }
    }
}
