import SwiftUI

/// Pull-down global search, like Spotlight on the Mac. Pulling the home page down past `threshold` and letting go
/// opens it: the page sinks a little and recedes, and the search bar drops in from 1.3× to its size with the keyboard
/// already up. Tapping outside, Cancel, or a result closes it.
struct QuickSearchOverlay: View {
    let onClose: () -> Void

    @State private var query = ""
    @State private var shown = false
    @FocusState private var focused: Bool

    /// How far the page has to be pulled before letting go opens search
    static let threshold: CGFloat = 70

    private static let suggestions: [(icon: String, title: String, detail: String)] = [
        ("chart.line.uptrend.xyaxis", "HSBC Midcap Direct Growth", "Fund"),
        ("bubble.left", "SBI Mutual fund discussion", "Chat"),
        ("calendar", "Next SIP on 1 Dec", "Reminder"),
        ("shield", "Term insurance", "Chat"),
    ]

    private var results: [(icon: String, title: String, detail: String)] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty ? Self.suggestions : Self.suggestions.filter { $0.title.lowercased().contains(q) }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Tap anywhere outside to close
            Color.black.opacity(shown ? 0.08 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: close)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.55))
                    TextField("", text: $query, prompt: Text("Search funds, chats, anything").foregroundStyle(Color.black.opacity(0.4)))
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
                            Button(action: close) {
                                HStack(spacing: 12) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.black.opacity(0.7))
                                        .frame(width: 32, height: 32)
                                        .background(Circle().fill(Color.black.opacity(0.05)))
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
                    Button("Cancel", action: close)
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

    private func close() {
        focused = false
        withAnimation(.easeIn(duration: 0.18)) { shown = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: onClose)
    }
}
