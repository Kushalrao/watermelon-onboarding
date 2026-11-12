import SwiftUI

/// Figma: "iPhone 14 Plus - 262" (node 928:18365) — the Chats home page.
/// Tapping "Investments portfolio" or a chat opens the fund page.
struct HomeView: View {
    var onOpenFund: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        BackgroundBlobs()

                        Text("Chats")
                            // Figma: Reckless Standard S SemiBold 39 — only Medium is bundled
                            .font(FigmaFont.reckless(39))
                            .foregroundStyle(Color.ink)
                            .at(15, 63)

                        // White container behind the quick-access circles (938:19814)
                        RoundedRectangle(cornerRadius: 37, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 21.25, x: 0, y: 2)
                            .frame(width: 360, height: 327 + HomeCategory.growth * 2)
                            .at(15, 125)

                        ForEach(HomeCategory.all) { category in
                            CategoryButton(category: category) {
                                if category.opensFund { onOpenFund() }
                            }
                            .at(category.center.x - 62, category.center.y - HomeCategory.diameter / 2)
                        }

                        Text("Last week")
                            .font(FigmaFont.walsheimMedium(23))
                            .foregroundStyle(Color.black)
                            .at(15, 482 + HomeCategory.growth * 2)

                        VStack(spacing: 5) {
                            ForEach(ChatPreview.all) { chat in
                                ChatRow(chat: chat, action: onOpenFund)
                            }
                        }
                        .at(15, 528 + HomeCategory.growth * 2)
                    }
                    // Room below the last chat for the floating nav
                    .frame(width: 390, height: 1040, alignment: .topLeading)
                    .clipped()
                    .frame(maxWidth: .infinity)
                }

                HomeNavBar()
                    // Figma has it 114pt above the bottom; pulled 20pt lower
                    .at(17, geo.size.height - 94)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .background(Color.screenBackground)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Categories (938:19011…19015)

private struct HomeCategory: Identifiable {
    let id: String
    let title: String
    /// Label width in Figma (titles wider than this wrap onto two lines)
    let labelWidth: CGFloat?
    /// Centre of the 90pt circle
    let center: CGPoint
    let gradient: Gradient
    let horizontal: Bool
    let image: String
    let imageSize: CGSize
    let imageOffset: CGSize
    let clipsImage: Bool
    var opensFund = false

    /// Circles are 1.1× the Figma 90pt
    static let scale: CGFloat = 1.1
    static let diameter: CGFloat = 90 * scale
    /// How much taller each row gets; rows keep their Figma tops (142 / 300) plus the growth of the rows above
    static let growth: CGFloat = diameter - 90

    static let all: [HomeCategory] = [
        HomeCategory(
            id: "bank", title: "Bank accounts", labelWidth: 62, center: CGPoint(x: 72, y: 142 + diameter / 2),
            gradient: Gradient(stops: [.init(color: Color(hex: 0x4C3F43), location: 0), .init(color: Color(hex: 0x9A595D), location: 0.53809), .init(color: Color(hex: 0xEB4618), location: 1)]),
            horizontal: false, image: "HomeBank", imageSize: CGSize(width: 123, height: 82), imageOffset: CGSize(width: 0.5, height: -1), clipsImage: false
        ),
        HomeCategory(
            // The 90° gradient's stops run past 100%; this is its visible 0…100% stretch
            id: "insurance", title: "Insurance", labelWidth: nil, center: CGPoint(x: 195, y: 142 + diameter / 2),
            gradient: Gradient(stops: [.init(color: Color(hex: 0xFFCB41), location: 0), .init(color: Color(hex: 0xFFC189), location: 0.91163), .init(color: Color(hex: 0xF9C08F), location: 1)]),
            horizontal: true, image: "HomeUmbrella", imageSize: CGSize(width: 76, height: 76), imageOffset: .zero, clipsImage: true
        ),
        HomeCategory(
            id: "loans", title: "Loans", labelWidth: nil, center: CGPoint(x: 318, y: 142 + diameter / 2),
            gradient: Gradient(stops: [.init(color: Color(hex: 0xFFC189), location: 0.087568), .init(color: Color(hex: 0xBBCDB6), location: 0.57611), .init(color: Color(hex: 0xB0CBC3), location: 1)]),
            horizontal: true, image: "HomeHourglass", imageSize: CGSize(width: 58, height: 67), imageOffset: CGSize(width: 0, height: 0.5), clipsImage: true
        ),
        HomeCategory(
            id: "investments", title: "Investments portfolio", labelWidth: 84, center: CGPoint(x: 72, y: 300 + growth + diameter / 2),
            gradient: Gradient(stops: [.init(color: Color(hex: 0xFFCB41), location: 0), .init(color: Color(hex: 0xB6B7CD), location: 0.93026)]),
            horizontal: true, image: "HomePlant", imageSize: CGSize(width: 79, height: 79), imageOffset: CGSize(width: 0.5, height: 0.5), clipsImage: true,
            opensFund: true
        ),
        HomeCategory(
            id: "cards", title: "Credit cards", labelWidth: nil, center: CGPoint(x: 195, y: 300 + growth + diameter / 2),
            gradient: Gradient(stops: [.init(color: Color(hex: 0x3F4C48), location: 0), .init(color: Color(hex: 0x9A9259), location: 0.53809), .init(color: Color(hex: 0x988A2F), location: 1)]),
            horizontal: false, image: "HomeCards", imageSize: CGSize(width: 78, height: 65), imageOffset: CGSize(width: 0, height: 0.5), clipsImage: true
        ),
    ]
}

private struct CategoryButton: View {
    let category: HomeCategory
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            VStack(spacing: 7) {
                circle
                Text(category.title)
                    .font(FigmaFont.walsheim(15))
                    .foregroundStyle(Color(hex: 0x8C8C8C))
                    .multilineTextAlignment(.center)
                    .lineSpacing(1)
                    .frame(width: category.labelWidth)
                    .fixedSize(horizontal: category.labelWidth == nil, vertical: true)
            }
            .frame(width: 124)
        }
        .buttonStyle(PressScaleStyle())
    }

    private var circle: some View {
        let gradient = LinearGradient(
            gradient: category.gradient,
            startPoint: category.horizontal ? .leading : .top,
            endPoint: category.horizontal ? .trailing : .bottom
        )
        return ZStack {
            Circle().fill(gradient)
            artwork.scaleEffect(HomeCategory.scale)
        }
        .frame(width: HomeCategory.diameter, height: HomeCategory.diameter)
        .clipShape(category.clipsImage ? AnyShape(Circle()) : AnyShape(Rectangle().inset(by: -40)))
        .shadow(color: Color.black.opacity(0.13), radius: (category.clipsImage ? 18.5 : 9.25) * HomeCategory.scale, x: 0, y: 5 * HomeCategory.scale)
    }

    @ViewBuilder private var artwork: some View {
        if category.id == "loans" {
            // image 134 is cropped inside its 58 × 67 slot
            Image(category.image)
                .resizable()
                .frame(width: 58 * 3.6571, height: 67 * 2.1027)
                .offset(x: 58 * -0.1952, y: 67 * -0.9733)
                .frame(width: 58, height: 67, alignment: .topLeading)
                .clipped()
                .offset(category.imageOffset)
        } else {
            Image(category.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: category.imageSize.width, height: category.imageSize.height)
                .offset(category.imageOffset)
        }
    }
}

/// Shrinks slightly while pressed
struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Chats (928:18464 / 18538 / 18610)

struct ChatPreview: Identifiable {
    let id: String
    let time: String
    let period: String
    let preview: String

    static let all: [ChatPreview] = [
        ChatPreview(id: "SBI Mutual fund discussion", time: "9:14", period: "AM", preview: "Have you heard of Calathea? It’s a patterned tropical houseplant…"),
        ChatPreview(id: "Term insurance", time: "11:05", period: "AM", preview: "I just got a Monstera deliciosa, also known as the Swiss cheese plant. It’s amazing!"),
        ChatPreview(id: "Leela", time: "2:45", period: "PM", preview: "Did you know snake plants can improve indoor air quality significantly?"),
    ]
}

struct ChatRow: View {
    let chat: ChatPreview
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                AdvisorBadgeAvatar()

                VStack(alignment: .leading, spacing: 2) {
                    // Long titles run under the time, as in Figma, rather than truncating
                    ZStack(alignment: .leading) {
                        Text(chat.id)
                            .font(FigmaFont.walsheim(17))
                            .foregroundStyle(Color.black)
                            .fixedSize()
                        HStack(spacing: 1) {
                            Text(chat.time)
                            Text(chat.period)
                        }
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: 0xE0E0E2))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .frame(height: 19)

                    Text(chat.preview)
                        .font(FigmaFont.walsheim(15))
                        .foregroundStyle(Color(hex: 0x8C8C8C))
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(width: 360)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .buttonStyle(PressScaleStyle())
    }
}

/// Advisor avatar with the HSBC badge (928:18465), 50 × 50
struct AdvisorBadgeAvatar: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("AdvisorAvatar")
                .resizable()
                .frame(width: 47, height: 47)

            HSBCLogoCrop(slot: CGSize(width: 18, height: 18), scaleW: 3.4151, scaleH: 1.9428, leftPct: -0.4348, topPct: -0.4714)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 5.625))
                .at(31, 31)
        }
        .frame(width: 50, height: 50, alignment: .topLeading)
    }
}

// MARK: - Floating nav (928:18827): chats / files / settings, then the advisor + new chat

struct HomeNavBar: View {
    /// Artwork for the two pills; each SVG carries its own shadow around the 214 × 63 and 120 × 63 pills
    var left = "HomeNavLeft"
    var right = "HomeNavRight"
    /// Each SVG's size and where the pill sits inside it
    var leftArt = CGRect(x: -38, y: -35, width: 290, height: 139)
    var rightArt = CGRect(x: -38, y: -35, width: 196, height: 139)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(left)
                .resizable()
                .frame(width: leftArt.width, height: leftArt.height)
                .allowsHitTesting(false)
                .at(leftArt.minX, leftArt.minY)

            Image(right)
                .resizable()
                .frame(width: rightArt.width, height: rightArt.height)
                .allowsHitTesting(false)
                .at(236 + rightArt.minX, rightArt.minY)

            HStack(spacing: 0) {
                // The first (chat) tab opens the chat, growing out of its black bubble
                tapArea(width: 214 / 3, does: .chat(fill: .black, fresh: false))
                tapArea(width: 214 / 3)
                tapArea(width: 214 / 3)
            }
            .at(0, 0)

            HStack(spacing: 0) {
                // The agent's avatar starts a new conversation, which the agent opens
                tapArea(width: 60, does: .chat(fill: Color(hex: 0x8CCFD0), fresh: true))
                // + asks how you feel about the market, on a half-circle dial
                tapArea(width: 60, does: .moodDial)
            }
            .at(236, 0)
        }
        .frame(width: 356, height: 63, alignment: .topLeading)
    }

    private func tapArea(width: CGFloat, does action: NavTapArea.Action? = nil) -> some View {
        NavTapArea(width: width, action: action)
    }
}

/// One button in the nav pills. A chat button reports where its icon sits on screen so the chat can grow out of it.
private struct NavTapArea: View {
    enum Action {
        /// Open a chat out of this icon; `fill` is the icon's colour, faded out as the page grows
        case chat(fill: Color, fresh: Bool)
        case moodDial
    }

    let width: CGFloat
    let action: Action?
    @Environment(\.openChat) private var openChat
    @Environment(\.openMoodDial) private var openMoodDial
    @State private var frame: CGRect = .zero

    var body: some View {
        Button {
            Haptics.tap()
            switch action {
            case let .chat(fill, fresh):
                // The visible icon is a little inside the tap area
                openChat(ChatSource(frame: frame.insetBy(dx: 6, dy: 6), fill: fill, fresh: fresh))
            case .moodDial:
                openMoodDial()
            case nil:
                break
            }
        } label: {
            Color.clear
                .frame(width: width, height: 63)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
    }
}

#Preview {
    HomeView()
}
