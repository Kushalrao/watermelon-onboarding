import SwiftUI

/// Figma: "iPhone 14 Plus - 228" (717:11319) — a chat with the agent. You type; the agent answers with
/// a canned reply after a short typing indicator.
struct ChatExperienceView: View {
    /// A brand-new conversation: it starts empty, the agent thinks for a moment and then opens with a message
    var fresh = false

    @State private var messages: [ChatMessage]
    @State private var draft = ""
    @State private var agentTyping = false
    @State private var tab: ChatTab = .chat
    @State private var replyIndex = 0
    @State private var pendingReplies = 0

    /// How long the agent "types" before replying
    private static let typingDuration: Double = 30
    @FocusState private var inputFocused: Bool

    init(fresh: Bool = false) {
        self.fresh = fresh
        _messages = State(initialValue: fresh ? [] : ChatMessage.seed)
    }

    /// How long the agent thinks before its opening message lands
    private static let openingDelay: Double = 4
    @Environment(\.goBack) private var goBack

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 23) {
                        ForEach(messages) { message in
                            ChatBubble(message: message, showsRead: message.id == lastUserMessageID)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.9, anchor: message.fromAgent ? .bottomLeading : .bottomTrailing)
                                        .combined(with: .opacity)
                                        .combined(with: .offset(y: 12)),
                                    removal: .opacity
                                ))
                        }
                        if agentTyping {
                            TypingBubble()
                                .id("typing")
                                .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
                        }
                    }
                    .padding(.top, 23)
                    .padding(.bottom, 24)
                    .frame(width: 390)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) { scrollToEnd(proxy) }
                .onChange(of: agentTyping) { scrollToEnd(proxy) }
                .onChange(of: inputFocused) { scrollToEnd(proxy) }
            }

            inputBar
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear(perform: openConversation)
    }

    /// New chat: the agent's thinking dots come in once the page has opened, and its first message replaces them
    private func openConversation() {
        guard fresh, messages.isEmpty, !agentTyping else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { agentTyping = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.openingDelay) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                agentTyping = false
                messages.append(ChatMessage(text: ChatMessage.opening, fromAgent: true))
            }
            Haptics.thresholdCrossed()
        }
    }

    private var lastUserMessageID: UUID? { messages.last(where: { !$0.fromAgent })?.id }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            if agentTyping { proxy.scrollTo("typing", anchor: .bottom) }
            else if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
        }
    }

    // MARK: Header (back · avatar + name · more, then the Chat / Widgets switch)

    private var header: some View {
        ZStack(alignment: .top) {
            HStack {
                CircleChromeButton(systemName: "chevron.backward", action: goBack)
                Spacer()
                CircleChromeButton(systemName: "ellipsis")
            }
            .padding(.horizontal, 15)
            .padding(.top, 3)

            VStack(spacing: 5) {
                // Avatar (753:11910) with the Microsoft badge (753:11976)
                ZStack(alignment: .topLeading) {
                    Image("ChatAvatarHeader")
                        .resizable()
                        .frame(width: 53.58, height: 53.58)
                    Image("MetaIcon")
                        .resizable()
                        .frame(width: 21, height: 23)
                        .frame(width: 16, height: 16)
                        .clipped()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white, lineWidth: 2))
                        .offset(x: 38.48, y: 38.48)
                }
                .frame(width: 57, height: 57, alignment: .topLeading)

                Text("Microsoft ETF’s")
                    .font(FigmaFont.reckless(19))
                    .foregroundStyle(Color.ink.opacity(0.74))

                // Chat / Widgets (753:12496), 230 wide
                HStack(spacing: 9) {
                    ForEach(ChatTab.allCases) { t in
                        Button {
                            Haptics.tap()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { tab = t }
                        } label: {
                            Text(t.title)
                                .font(FigmaFont.walsheim(14.004))
                                .foregroundStyle(Color.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 41)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.black, lineWidth: tab == t ? 1 : 0))
                                .shadow(color: Color.black.opacity(tab == t ? 0.03 : 0), radius: 12, x: 0, y: 2.5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 230)
                .padding(.top, 10)
            }
        }
        .padding(.top, 15)   // 59 from the top of the frame, below the status bar
        .padding(.bottom, 0)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }

    // MARK: Input (717:11322 + mic 717:11326)

    private var inputBar: some View {
        HStack(alignment: .center, spacing: 9) {
            HStack(spacing: 0) {
                Image("PlusIcon")
                    .resizable()
                    .frame(width: 13.0239, height: 13.0156)
                    .padding(.leading, 14)
                TextField("", text: $draft, prompt: Text("Start typing").foregroundStyle(Color.black.opacity(0.67)))
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .focused($inputFocused)
                    .submitLabel(.send)
                    .onSubmit(send)
                    .padding(.leading, 12)
                    .padding(.trailing, 16)
            }
            .frame(width: 294, height: 53)
            .background(Color(hex: 0xF9F9F9))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(0.22), lineWidth: 0.7))
            .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)

            Button(action: send) {
                Image("MicButton")
                    .resizable()
                    .frame(width: 129, height: 129)
                    .frame(width: 53, height: 53)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 356)
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            LinearGradient(colors: [Color.white.opacity(0), Color.white], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
        )
    }

    // MARK: Sending

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Haptics.tap()
        draft = ""
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            messages.append(ChatMessage(text: text, fromAgent: false))
        }

        // The agent shows the typing dots for ~30s, then answers
        pendingReplies += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { agentTyping = true }
        }
        let reply = ChatMessage.agentReplies[replyIndex % ChatMessage.agentReplies.count]
        replyIndex += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Self.typingDuration) {
            pendingReplies -= 1
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                // Keep the dots if another reply is still on its way
                agentTyping = pendingReplies > 0
                messages.append(ChatMessage(text: reply, fromAgent: true))
            }
            Haptics.thresholdCrossed()
        }
    }
}

enum ChatTab: String, CaseIterable, Identifiable {
    case chat, widgets
    var id: String { rawValue }
    var title: String { self == .chat ? "Chat" : "Widgets" }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let fromAgent: Bool

    static let seed: [ChatMessage] = [
        ChatMessage(text: "Siddarth, For the next few weeks the number will move around a bit, up and down. That’s normal and it doesn’t mean anything yet. The part that matters is the 1st of every month, and that’s already handled.", fromAgent: true),
        ChatMessage(text: "Why do you think this happened with my fund? why did you not remind me?", fromAgent: false),
    ]

    /// How the agent opens a new conversation
    static let opening = "Morning Jojo. Markets opened a little shaky today, but your portfolio is holding steady. Want me to walk you through what moved?"

    /// Placeholder agent answers, cycled in order
    static let agentReplies: [String] = [
        "Good question. Most of the dip came from large tech stocks cooling off this month — your fund holds a lot of them, so it moved with them.",
        "I didn’t flag it because short swings like this are expected for this fund. I’ll ping you if it drops more than 8% in a week.",
        "Your SIP on the 1st buys more units when prices are lower, so a dip like this quietly works in your favour.",
        "Want me to show how this fund did in past dips and how long it took to recover?",
        "Got it. I’ll keep an eye on it and send you a short note every Friday.",
    ]
}

// MARK: - Bubbles

struct ChatBubble: View {
    let message: ChatMessage
    let showsRead: Bool
    /// When it was sent, shown under it on its own side
    var timestamp: String? = nil

    var body: some View {
        VStack(alignment: message.fromAgent ? .leading : .trailing, spacing: 7) {
            Text(message.text)
                .font(FigmaFont.walsheim(17))
                .lineSpacing(2)
                .foregroundStyle(message.fromAgent ? Color.black.opacity(0.71) : Color.white.opacity(0.87))
                .frame(maxWidth: 265, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(message.fromAgent ? 15 : 17)
                .padding(.bottom, message.fromAgent ? 6 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(message.fromAgent ? Color(hex: 0xEDECEC) : Color(hex: 0x212121))
                )
                .overlay(alignment: message.fromAgent ? .bottomLeading : .bottomTrailing) { tail }
                .shadow(color: Color.black.opacity(0.03), radius: 7.5, x: 0, y: 3)

            if let timestamp {
                Text(timestamp)
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(Color(hex: 0x89898D))
                    .frame(height: 19)
                    // 10pt under the bubble, just clear of its tail, as under every message in the chat
                    .padding(.top, 10 - 7)
                    .padding(message.fromAgent ? .leading : .trailing, 4)
            }
            if showsRead {
                HStack(spacing: 4) {
                    Text("Read").font(FigmaFont.walsheimMedium(13))
                    Text(Self.time).font(FigmaFont.walsheim(13))
                }
                .foregroundStyle(Color(hex: 0x89898D))
                .padding(.trailing, 23)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.fromAgent ? .leading : .trailing)
        .padding(.horizontal, 15)
    }

    @ViewBuilder private var tail: some View {
        if message.fromAgent {
            // 717:11331 + 717:11333
            ZStack(alignment: .topLeading) {
                Image("BubbleTail")
                    .resizable()
                    .frame(width: 24.3238, height: 14.976)
                    .rotationEffect(.degrees(7.22))
                    .offset(x: 1.97, y: 0)
                Image("Vector83Grey")
                    .resizable()
                    .frame(width: 15.4967, height: 8.07787)
                    .rotationEffect(.degrees(7.34))
                    .offset(x: 14.85, y: 0.08)
            }
            .frame(width: 30, height: 17, alignment: .topLeading)
            .offset(y: 8.45)
        } else {
            // 717:11336
            Image("UserBubbleTail")
                .resizable()
                .frame(width: 24, height: 14)
                .offset(y: 6)
        }
    }

    private static let time: String = {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: Date())
    }()
}

/// Three dots pulsing in an agent bubble
struct TypingBubble: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    let phase = (sin((t * 5) - Double(i) * 0.8) + 1) / 2
                    Circle()
                        .fill(Color.black.opacity(0.25 + 0.35 * phase))
                        .frame(width: 8, height: 8)
                        .offset(y: -3 * phase)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(RoundedRectangle(cornerRadius: 25, style: .continuous).fill(Color(hex: 0xEDECEC)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 15)
    }
}

/// White 49 × 42 pill with a hairline border (717:11401 / 717:11408)
private struct CircleChromeButton: View {
    let systemName: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            Image(systemName: systemName)
                .font(.system(size: 20.25, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.black)
                .frame(width: 49.056, height: 41.889)
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().stroke(Color.black.opacity(0.09), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.1), radius: 3.5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChatExperienceView()
}
