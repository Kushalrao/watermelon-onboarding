import SwiftUI

/// Figma "iPhone 14 Plus - 319" (99:1576): after the PAN card's Verify. The warm gradient comes up first on its own,
/// then the arch and the black "Wealth Advisory" card arrive together, the card landing from 1.1× to its size. A second
/// later (101:2223) the card lifts, the arch gives way to a long arcade, and a chat button forms below it.
struct OnboardingAdvisoryView: View {
    let onContinue: () -> Void

    @State private var shown = false
    /// The card has lifted for the chat button, and the arch has given way to the arcade
    @State private var raised = false
    @State private var chat = ChatStage.hidden

    private enum ChatStage { case hidden, dot, open }

    /// The suggestion has been sent: the card is the chat's heading and the chat is up (94:1435)
    @State private var research = OnboardingAdvisoryView.startsInResearch
    @State private var messages: [ChatMessage] = []
    @State private var agentTyping = false
    /// The research sheet is up over the chat (99:1750)
    @State private var sheetUp = false

    /// What the agent says before it goes off to research
    private static let startingResearch = "Great, starting the research now. I’ll go through fund disclosures, factsheets and the latest market coverage, so give me a moment."

    private static let suggestion = "Lets start with Research"
    /// `-advisoryResearch` opens on the chat, for working on it
    private static let startsInResearch = startsInSheet || ProcessInfo.processInfo.arguments.contains("-advisoryResearch")
    /// `-advisorySheet` opens with the research sheet up
    private static let startsInSheet = ProcessInfo.processInfo.arguments.contains("-advisorySheet")
    /// How far up the screen the colour has flowed, 0…1
    @State private var flow: CGFloat = 0

    /// How long the colour takes to flow up the screen
    static let flowDuration = 2.0
    /// The soft leading edge of the colour as it rises
    private static let flowEdge: CGFloat = 220

    private static let rows = ["Advisory Research", "Advisory Analysis", "Advisory Decisioning"]
    private static let ink = Color(hex: 0x151515)
    private static let hairline = Color(red: 194 / 255, green: 194 / 255, blue: 194 / 255).opacity(0.13)

    var body: some View {
        // Laid out from the bottom, as in Figma: the card's and images' distances from the bottom edge
        ZStack(alignment: .bottom) {
            // The arch stands behind the card, its base tucked under the card's top
            Image("AdvisoryArch")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 425, height: 448)
                .offset(x: 6.5)
                .scaleEffect(shown ? (raised ? 1.04 : 1) : 1.06, anchor: .bottom)
                .offset(y: shown ? 0 : 14)
                .opacity(shown && !raised ? 1 : 0)
                .padding(.bottom, 386)

            // Then the long arcade, close in on its middle, as the card rises (101:2226)
            Image("AdvisoryArcade")
                .resizable()
                .frame(width: 1212, height: 404)
                .frame(width: 438, height: 404)
                .clipped()
                .scaleEffect(raised ? (research ? 1.04 : 1) : 0.96, anchor: .bottom)
                .opacity(raised && !research ? 1 : 0)
                .padding(.bottom, 408)

            // And the gears, once the chat is up (94:1438)
            Image("ResearchGears")
                .resizable()
                .frame(width: 674, height: 379)
                .frame(width: MutualFundScreen.canvasWidth)
                .scaleEffect(research ? 1 : 0.96, anchor: .bottom)
                .opacity(research ? 1 : 0)
                .padding(.bottom, 461)

            card
                .scaleEffect(shown ? 1 : 1.1)
                .opacity(shown ? 1 : 0)
                .padding(.bottom, research ? 316 : raised ? 139 : 53)

            if research {
                chatCard
                    .padding(.bottom, 55)
                    // Lands from 1.3× over the card as it steps back, like the earlier cards; solid almost at once, so
                    // the black card doesn't show through it
                    .transition(.scale(scale: 1.3).combined(with: .opacity.animation(.easeOut(duration: 0.12))))
                    .zIndex(1)
            }

            // The research sheet rises over the chat (99:1750)
            if sheetUp {
                ResearchSheet()
                    .padding(.bottom, 47)
                    .transition(.move(edge: .bottom).combined(with: .opacity.animation(.easeOut(duration: 0.2))))
                    .zIndex(2)
            }

            // Gone once sent: the message carries on as the first bubble in the chat
            if !research {
                chatButton
                    .transition(.scale(scale: 0.9, anchor: .trailing).combined(with: .opacity))
                    .frame(width: MutualFundScreen.canvasWidth, alignment: .trailing)
                    .padding(.trailing, 18)
                    .padding(.bottom, 65)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background.mask(flowMask).ignoresSafeArea())
        .preferredColorScheme(.light)
        .task {
            guard !research else {
                // Opened straight on the chat
                (shown, raised, flow, agentTyping) = (true, true, 1, true)
                messages = [ChatMessage(text: Self.suggestion, fromAgent: false)]
                if Self.startsInSheet {
                    messages.append(ChatMessage(text: Self.startingResearch, fromAgent: true))
                    sheetUp = true
                }
                return
            }
            await play()
        }
    }

    private func play() async {
        // The colour flows up from the bottom first, over the previous screen
        withAnimation(.easeInOut(duration: Self.flowDuration)) { flow = 1 }
        // and the arch and card arrive as it nears the top
        try? await Task.sleep(for: .seconds(Self.flowDuration * 0.7))
        withAnimation(.spring(response: 0.62, dampingFraction: 0.86)) { shown = true }
        // A second after they've landed, the card lifts to make room and the chat button forms under it (101:2223)
        try? await Task.sleep(for: .seconds(0.6 + 1.0))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.88)) { raised = true }
        try? await Task.sleep(for: .seconds(0.25))
        // A dot with the chevron pops up first, then it stretches out to the left and the words come in
        Haptics.settle()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.7)) { chat = .dot }
        try? await Task.sleep(for: .seconds(0.22))
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) { chat = .open }
    }

    /// "Lets start with Research" (107:1549), 251 × 57: it suggests a message to send
    private var chatButton: some View {
        let shape = Capsule()
        return Button(action: send) {
            HStack(spacing: 7) {
                Text(Self.suggestion)
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color.black)
                    .fixedSize()
                    .opacity(chat == .open ? 1 : 0)
                    .offset(x: chat == .open ? 0 : 16)
                Image("ChatChevronUp")
                    .frame(width: 23, height: 23)
            }
            .padding(.trailing, 15)
            .frame(width: chat == .open ? 251 : 57, height: 57, alignment: .trailing)
            .background(Color.white)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .scaleEffect(chat == .hidden ? 0.3 : 1, anchor: .trailing)
        .opacity(chat == .hidden ? 0 : 1)
        .allowsHitTesting(chat == .open)
    }

    /// Opaque from the bottom up to the rising edge, which is feathered so the colour seeps rather than wipes
    private var flowMask: some View {
        GeometryReader { geo in
            let travel = geo.size.height + Self.flowEdge
            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: Self.flowEdge)
                Color.black
                    .frame(height: geo.size.height)
            }
            .offset(y: geo.size.height - flow * travel)
        }
        .ignoresSafeArea()
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 152 / 255, green: 153 / 255, blue: 169 / 255), location: 0.0067),
                .init(color: Color(red: 209 / 255, green: 208 / 255, blue: 204 / 255), location: 0.159),
                .init(color: Color(red: 252 / 255, green: 193 / 255, blue: 140 / 255), location: 0.952),
            ],
            // 167° in Figma: down, leaning a little to the right
            startPoint: UnitPoint(x: 0.39, y: 0), endPoint: UnitPoint(x: 0.61, y: 1)
        )
        .ignoresSafeArea()
    }

    /// "Flight card background" (99:1580), 364 × 483
    private var card: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Self.ink

            Group {
                // 57pt lines, tighter than the font's own, so each line is set on its own
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(["Wealth", "Advisory"], id: \.self) { line in
                        Text(line)
                            .font(.custom("RecklessStandardS-TRIAL-SemiBold", fixedSize: 59))
                            .frame(height: 57)
                    }
                }
                .foregroundStyle(Color.white)
                .frame(width: 318, alignment: .leading)
                .at(23, 27)

                Text("Decade worth of research is now in your hands. Lets do some test run.")
                    .font(FigmaFont.walsheim(19))
                    .lineSpacing(25 - 19 * 1.2)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .frame(width: 318, alignment: .leading)
                    .at(23, 154)

                list
                    .at(17, 249)
            }
            .opacity(research ? 0 : 1)

            // Once it has stepped back it is just the heading of the chat (99:1649)
            Text("Advisory Research")
                .font(FigmaFont.walsheim(23))
                .foregroundStyle(Color.white)
                .frame(height: 29)
                .at(19, 17)
                .opacity(research ? 1 : 0)
        }
        .frame(width: research ? 344 : 364, height: research ? 222 : 483, alignment: .topLeading)
        .clipShape(shape)
        // The tab on its top edge (99:1631)
        .overlay(alignment: .topLeading) {
            Self.ink
                .frame(width: 64, height: 11)
                .at(27, -9)
                .opacity(research ? 0 : 1)
        }
        .shadow(color: Color.black.opacity(0.16), radius: research ? 100 : 50, x: 0, y: 4)
    }

    /// The chat that comes in over the card once the suggestion is sent (94:1480), 368 × 420
    private var chatCard: some View {
        VStack(spacing: 23) {
            ForEach(messages) { message in
                ChatBubble(message: message, showsRead: false)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9, anchor: message.fromAgent ? .bottomLeading : .bottomTrailing)
                            .combined(with: .opacity)
                            .combined(with: .offset(y: 12)),
                        removal: .opacity
                    ))
            }
            if agentTyping {
                TypingBubble()
                    .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
            }
        }
        .padding(.top, 23)
        .frame(width: 368, height: 420, alignment: .top)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 100, x: 0, y: 4)
    }

    /// Sending the suggestion: the card steps back to become the heading, the chat lands over it from 1.3×, the
    /// message goes in, and the agent starts typing straight away. For now it stays thinking.
    private func send() {
        Haptics.tap()
        withAnimation(.spring(response: 0.62, dampingFraction: 0.86)) { research = true }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                messages.append(ChatMessage(text: Self.suggestion, fromAgent: false))
            }
            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { agentTyping = true }
            await research()
        }
    }

    /// The agent says it's starting, thinks again, and then the research sheet opens over the chat
    private func research() async {
        try? await Task.sleep(for: .seconds(1.8))
        // The message takes the dots' place
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            agentTyping = false
            messages.append(ChatMessage(text: Self.startingResearch, fromAgent: true))
        }
        Haptics.thresholdCrossed()
        try? await Task.sleep(for: .seconds(0.9))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { agentTyping = true }
        try? await Task.sleep(for: .seconds(2.0))
        Haptics.tap()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) { sheetUp = true }
    }

    /// The three steps (99:1614), 330 × 201
    private var list: some View {
        let shape = RoundedRectangle(cornerRadius: 29, style: .continuous)
        return ZStack(alignment: .topLeading) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { index, title in
                let top = 16 + 67 * CGFloat(index)
                Image("AdvisoryGlyph")
                    .frame(width: 33, height: 33)
                    .at(14, top)
                Text(title)
                    .font(FigmaFont.walsheim(23))
                    .foregroundStyle(Color.white)
                    .frame(height: 29)
                    .at(57, top + 2)
                if index > 0 {
                    Self.hairline
                        .frame(width: 330, height: 1)
                        .at(0, 66 + 67 * CGFloat(index - 1))
                }
            }
        }
        .frame(width: 330, height: 201, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Self.hairline, lineWidth: 1))
    }
}

#Preview {
    OnboardingAdvisoryView(onContinue: {})
}
