import SwiftUI

/// Figma: "iPhone 14 Plus - 291" (node 1079:30481) — the fourth home page: a swipeable row of chunky, plastic-looking
/// widgets above last week's chats. On launch each widget's graph fills up to its value: the gauge's raised arc
/// sweeps round like a clock hand while the score counts up, and the strength bar fills left to right with its
/// marker gliding along. Tapping a widget or a chat opens the fund page.
struct HomeV4View: View {
    var onOpenFund: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        HomeV3Blobs()

                        Text("Hello Jojo")
                            .font(FigmaFont.reckless(31))
                            .foregroundStyle(Color.ink)
                            .frame(height: 39)
                            .at(17, 67)

                        // Widgets run off the right edge and scroll sideways (21pt apart)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 21) {
                                widget { StrengthGaugeWidget() }
                                widget { StrengthBarWidget() }
                            }
                            .padding(.horizontal, 15)
                            // Room for the shadows and the "+3" badges poking above
                            .padding(.vertical, 24)
                        }
                        .scrollClipDisabled()
                        .frame(width: 390, height: 224 + 48)
                        .at(0, 138 - 24)

                        Text("Last week")
                            .font(FigmaFont.walsheimMedium(23))
                            .foregroundStyle(Color.black)
                            .frame(height: 29)
                            .at(15, 395)

                        VStack(spacing: 5) {
                            ForEach(ChatPreview.all) { chat in
                                ChatRow(chat: chat, action: onOpenFund)
                            }
                        }
                        .at(15, 441)
                    }
                    // Room below the last chat for the floating nav
                    .frame(width: 390, height: 900, alignment: .topLeading)
                    .clipped()
                    .frame(maxWidth: .infinity)
                }

                // Same spot as the other homes
                HomeNavBar(left: "HomeV3NavLeft", right: "HomeV3NavRight")
                    .at(17, geo.size.height - 94)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .background(Color.screenBackground)
        }
        .ignoresSafeArea()
    }

    private func widget<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        Button {
            Haptics.tap()
            onOpenFund()
        } label: {
            content()
        }
        .buttonStyle(PressScaleStyle())
    }
}

// MARK: - Shared

/// 231 × 224 card (1079:31006): #F0EEE9 fading to white, soft shadow, "+3" badge on the corner
private struct PlasticWidget<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(hex: 0xF0EEE9), .white], startPoint: .top, endPoint: .bottom)
            content
        }
        .frame(width: 231, height: 224, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 37, style: .continuous))
        .shadow(color: Color.black.opacity(0.11), radius: 21, x: 0, y: 2)
        .overlay(alignment: .topLeading) { MoreBadge().at(203, -4) }
    }
}

/// Title and caption along the bottom of both widgets
private struct WidgetCaption: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Text("Portfolio strength")
                .font(FigmaFont.walsheim(19))
                .foregroundStyle(Color.black.opacity(0.93))
                .fixedSize()
                .at(19, 146)

            Text("Your strength is matching goals, do not be worried")
                .font(FigmaFont.walsheim(13))
                .lineSpacing(1.5)
                .foregroundStyle(Color.black.opacity(0.54))
                .frame(width: 193, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .at(19, 171)
        }
    }
}

/// How every graph here fills on launch: eases off the mark, glides, and settles onto the value, like a clock hand
private enum FillTiming {
    static let delay = 0.45
    static let duration = 1.5
    static let curve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.45, y: 0), endControlPoint: UnitPoint(x: 0.25, y: 1))
    static var animation: Animation { .timingCurve(curve, duration: duration).delay(delay) }
}

// MARK: - Gauge (1079:31006)

private struct StrengthGaugeWidget: View {
    /// 0 → 1 as the arc fills; the score counts up on the same curve over the same time, so both land together
    @State private var fill = 0.0
    @State private var shownScore = 0.0

    private static let score = 8.9
    /// Where the raised value arc ends, in degrees clockwise from 9 o'clock
    private static let arcEnd = 130.0
    /// Soft leading edge of the arc's reveal; the reveal stops this short so the edge itself lands on the arc's end
    /// exactly as the fill (and the number) finish, rather than completing the arc early
    private static let arcFeather = 4.0
    private static let trackFeather = 25.0

    var body: some View {
        PlasticWidget {
            // Empty dial: the cream the track fades to, as one half ring (hub at 116, 124.5; radii 97 and 57.25)
            HalfRing(outer: 97, inner: 57.25)
                .fill(Color(hex: 0xFBEFD6))
                .frame(width: 194, height: 100.5)
                .at(19, 24)

            // The track (1079:31093) carries the coloured run up to the value and fades out to cream after it
            Image("StrengthTrack")
                .resizable()
                .frame(width: 194, height: 100.5)
                // Its fade to cream runs just past the arc's end; beyond that the cream ring underneath matches it
                .modifier(GaugeReveal(angle: (Self.arcEnd - Self.arcFeather) * fill, feather: Self.trackFeather))
                .at(19, 24)

            // Raised value arc (1079:31147); its hub sits at (103, 103.5) in its own 172.6 × 114 frame
            Image("StrengthArc")
                .resizable()
                .frame(width: 172.557, height: 114.016)
                .modifier(GaugeReveal(angle: (Self.arcEnd - Self.arcFeather) * fill, center: UnitPoint(x: 103 / 172.557, y: 103.5 / 114.016), feather: Self.arcFeather))
                .at(13, 21)

            Text(String(format: "%.1f", shownScore))
                .font(FigmaFont.walsheimMedium(37.931))
                .foregroundStyle(Color.black.opacity(0.93))
                // iOS rolling digits as it counts up with the sweep
                .contentTransition(.numericText(value: shownScore))
                .fixedSize()
                .at(88.95, 87)

            WidgetCaption()
        }
        .onAppear(perform: run)
    }

    private func run() {
        guard fill == 0 else { return }
        withAnimation(FillTiming.animation) { fill = 1 }
        // The score ticks up in step with the arc, on the same curve, reaching 8.9 as the arc lands
        let steps = 20
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let value = (Self.score * FillTiming.curve.value(at: t) * 10).rounded() / 10
            DispatchQueue.main.asyncAfter(deadline: .now() + FillTiming.delay + FillTiming.duration * t) {
                withAnimation(.snappy(duration: FillTiming.duration / Double(steps))) { shownScore = value }
            }
        }
    }
}

/// Top half of a ring, its hub at the bottom middle of the frame
private struct HalfRing: Shape {
    let outer: CGFloat
    let inner: CGFloat

    func path(in rect: CGRect) -> Path {
        let hub = CGPoint(x: rect.midX, y: rect.maxY)
        var path = Path()
        path.addArc(center: hub, radius: outer, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        path.addArc(center: hub, radius: inner, startAngle: .degrees(360), endAngle: .degrees(180), clockwise: true)
        path.closeSubpath()
        return path
    }
}

// MARK: - Bar (1080:31205)

private struct StrengthBarWidget: View {
    /// 0 → 1 as the bar fills left to right
    @State private var fill: CGFloat = 0

    private static let bar = CGRect(x: 19, y: 50, width: 193, height: 45)
    /// Marker's resting spot (its top-left), and the tick marks' x positions
    private static let marker = CGPoint(x: 181, y: 46)
    private static let ticks: [CGFloat] = [38, 74, 110, 146, 182, 218]

    var body: some View {
        PlasticWidget {
            ZStack(alignment: .topLeading) {
                LinearGradient(stops: [
                    .init(color: Color(hex: 0xC4E5AF), location: 0),
                    .init(color: Color(hex: 0xB6CDC4), location: 0.61402),
                    .init(color: Color(hex: 0xE5E882), location: 1),
                ], startPoint: .leading, endPoint: .trailing)
                .frame(width: Self.bar.width, height: Self.bar.height)

                ForEach(Self.ticks, id: \.self) { x in
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 1, height: 23)
                        .at(x - Self.bar.minX - 0.5, 61 - Self.bar.minY)
                }
            }
            // Fills from the left; the last tick sits just past the bar's end, so the reveal runs a touch longer
            .frame(width: 200, height: Self.bar.height, alignment: .topLeading)
            .mask(alignment: .leading) {
                Rectangle().frame(width: max(0, 200 * fill))
            }
            .at(Self.bar.minX, Self.bar.minY)

            // The white marker rides along with the fill and comes to rest on the value
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(Color(hex: 0xB6C0CC), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 4)
                .frame(width: 8, height: 54)
                .at(Self.bar.minX + (Self.marker.x - Self.bar.minX) * fill, Self.marker.y)

            ForEach([19.0, 135.0, 191.0], id: \.self) { x in
                Text("203")
                    .font(FigmaFont.walsheim(12))
                    .foregroundStyle(Color.black.opacity(0.54))
                    .frame(height: 19)
                    .fixedSize()
                    .at(x, 101)
            }

            WidgetCaption()
        }
        .onAppear {
            guard fill == 0 else { return }
            withAnimation(FillTiming.animation) { fill = 1 }
        }
    }
}

#Preview {
    HomeV4View()
}
