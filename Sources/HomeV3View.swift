import SwiftUI

/// Figma: "iPhone 14 Plus - 287" (node 1050:28186) — the third home page: pinned widgets above last week's chats.
/// On launch the Portfolio strength meter sweeps from 0 up to its value like a clock hand, and its score counts up
/// alongside. Tapping a chat or the meter opens the fund page.
struct HomeV3View: View {
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

                        Text("Pinned")
                            .font(FigmaFont.walsheimMedium(23))
                            .foregroundStyle(Color.black)
                            .frame(height: 29)
                            .at(15, 127)

                        IPOWidget()
                            .at(15, 175)

                        Button {
                            Haptics.tap()
                            onOpenFund()
                        } label: {
                            PortfolioStrengthWidget()
                        }
                        .buttonStyle(PressScaleStyle())
                        .at(216, 175)

                        QuickReadWidget()
                            .at(15, 388)

                        Text("Last week")
                            .font(FigmaFont.walsheimMedium(23))
                            .foregroundStyle(Color.black)
                            .frame(height: 29)
                            .at(15, 630)

                        VStack(spacing: 5) {
                            ForEach(ChatPreview.all) { chat in
                                ChatRow(chat: chat, action: onOpenFund)
                            }
                        }
                        .at(15, 676)
                    }
                    // Room below the last chat for the floating nav
                    .frame(width: 390, height: 1130, alignment: .topLeading)
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
}

// MARK: - Background (1050:28264–28268)

struct HomeV3Blobs: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Ellipse()
                .fill(Color(hex: 0xF6F5DF))
                .frame(width: 165, height: 378)
                .at(97, 118)

            Ellipse()
                .fill(Color(hex: 0xBBC5B0))
                .frame(width: 119.377, height: 273.036)
                .rotationEffect(.degrees(-86.94))
                .frame(width: 279.025, height: 133.796)
                .at(7, 559)

            ForEach([CGPoint(x: 171, y: -19), CGPoint(x: 75, y: 281)], id: \.y) { origin in
                Ellipse()
                    .fill(Color(hex: 0xF0F0F0))
                    .frame(width: 359.537, height: 446)
                    .rotationEffect(.degrees(-3.73))
                    .frame(width: 387.814, height: 468.464)
                    .at(origin.x, origin.y)
            }
        }
        .blur(radius: 145)
        .overlay(Color.white.opacity(0.64))
    }
}

// MARK: - Widgets

/// 186 × 192 widget shell: a gradient rim around its content, a soft shadow and the "+3" badge on the corner
private struct PinnedWidget<Content: View>: View {
    let rim: LinearGradient
    /// Opacity of the rim gradient; below 1 the page shows through it (no white backing)
    var rimOpacity: Double = 1
    /// Shadow blur radius (Figma blur ÷ 2)
    var shadowRadius: CGFloat = 21
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            if rimOpacity == 1 { Color.white }
            rim.opacity(rimOpacity)
            content
        }
        .frame(width: 186, height: 192, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 37, style: .continuous))
        .shadow(color: Color.black.opacity(0.11), radius: shadowRadius, x: 0, y: 2)
        .overlay(alignment: .topLeading) { MoreBadge().at(158, -4) }
    }
}

/// "+3" bubble with its little tail dot (1050:28556)
struct MoreBadge: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Text("+3")
                .font(FigmaFont.walsheimMedium(17))
                .foregroundStyle(Color.black.opacity(0.58))
                .frame(height: 23)
                .fixedSize()
                .at(5, 3)
                .frame(width: 32, height: 27, alignment: .topLeading)
                .background(Color.white)
                .clipShape(Capsule())
                .at(2, 0)

            Capsule()
                .fill(Color.white.opacity(0.77))
                .frame(width: 6, height: 5)
                .at(2, 27)
        }
        .frame(width: 34, height: 30, alignment: .topLeading)
    }
}

/// The light inner card each widget's text sits on: #F0EEE9 fading to white, tighter corners on top
private struct WidgetCard<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    var corners = RectangleCornerRadii(topLeading: 25, bottomLeading: 35, bottomTrailing: 35, topTrailing: 25)
    @ViewBuilder let content: Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(hex: 0xF0EEE9), .white], startPoint: .top, endPoint: .bottom)
            content
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .clipShape(UnevenRoundedRectangle(cornerRadii: corners, style: .continuous))
    }
}

/// Figma's 90° rims; stops past 100% are cut at the right edge with the colour they reach there
private enum WidgetRim {
    static let ipo = LinearGradient(stops: [
        .init(color: Color(hex: 0xFFCB41), location: 0),
        .init(color: Color(hex: 0xFFC189), location: 0.91163),
        .init(color: Color(hex: 0xF9C08F), location: 1),
    ], startPoint: .leading, endPoint: .trailing)

    static let cool = LinearGradient(stops: [
        .init(color: Color(hex: 0xCBD2B3), location: 0.011286),
        .init(color: Color(hex: 0xB6B7CD), location: 0.45131),
        .init(color: Color(hex: 0x7FC1F6), location: 1),
    ], startPoint: .leading, endPoint: .trailing)
}

// MARK: IPO (1050:28503)

private struct IPOWidget: View {
    var body: some View {
        PinnedWidget(rim: WidgetRim.ipo) {
            Image("IPODial")
                .resizable()
                .frame(width: 95, height: 179)
                .at(90, 6)

            WidgetCard(width: 131, height: 92) {
                Text("IPO")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color(hex: 0xB48D25))
                    .frame(height: 23)
                    .at(13, 13)

                Text("Anthropic")
                    .font(FigmaFont.walsheim(25))
                    .foregroundStyle(Color.black.opacity(0.93))
                    .fixedSize()
                    .at(13, 37)
            }
            .at(3, 97)
        }
    }
}

// MARK: Portfolio strength (1050:28560)

private struct PortfolioStrengthWidget: View {
    /// 0 → 1 as the meter sweeps up to its value
    @State private var sweep: CGFloat = 0
    @State private var shownScore = 0.0

    static let score = 8.9
    /// Meter dial centre in the widget, and where its needle ends up (degrees clockwise from 12 o'clock)
    private static let dialCentre = CGPoint(x: 93.5, y: 97.5)
    private static let needleAngle = 56.99
    /// The needle starts flat at 9 o'clock, so it turns this far
    private static let needleTravel = 90 + needleAngle

    /// Like a clock hand: eases off the mark, glides, and settles onto the value
    private static let sweepDuration = 1.6
    private static let sweepCurve = UnitCurve.bezier(startControlPoint: UnitPoint(x: 0.45, y: 0), endControlPoint: UnitPoint(x: 0.25, y: 1))
    private static let startDelay = 0.45

    var body: some View {
        // Figma 1050:28560: the rim gradient at 38%, straight over the page, with an 85pt-blur shadow
        PinnedWidget(rim: WidgetRim.cool, rimOpacity: 0.38, shadowRadius: 42.5) {
            // Ticks light up behind the needle as it passes
            Image("PortfolioGauge")
                .resizable()
                .frame(width: 173, height: 86.5)
                .modifier(GaugeReveal(angle: Self.needleTravel * sweep))
                .at(7, 11)

            needle
                .frame(width: 186, height: 192, alignment: .topLeading)
                .rotationEffect(
                    .degrees(Self.needleTravel * (sweep - 1)),
                    anchor: UnitPoint(x: Self.dialCentre.x / 186, y: Self.dialCentre.y / 192)
                )

            WidgetCard(width: 180, height: 113) {
                Text("Portfolio Strength")
                    .font(FigmaFont.walsheimMedium(17))
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: 0x5177A3))
                    .fixedSize()
                    .frame(height: 23)
                    .at(15, 17)

                Text(String(format: "%.1f", shownScore))
                    .font(FigmaFont.walsheimMedium(25))
                    .foregroundStyle(Color.black.opacity(0.93))
                    // iOS rolling digits as it counts up with the needle
                    .contentTransition(.numericText(value: shownScore))
                    .fixedSize()
                    .at(15, 45)

                Text("Do not be worried")
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(Color.black.opacity(0.54))
                    .frame(width: 154, height: 21, alignment: .leading)
                    .at(15, 75)
            }
            .at(3, 76)
        }
        .onAppear(perform: run)
    }

    /// White hand with a grey edge (1074:29320), at its Figma pose
    private var needle: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 40, style: .continuous).stroke(Color(hex: 0xB6C0CC), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.13), radius: 2, x: 0, y: 4)
                .frame(width: 6, height: 108.315)
                .rotationEffect(.degrees(Self.needleAngle))
                .frame(width: 94.1, height: 64.039)
                .at(64, 41.94)
        }
    }

    private func run() {
        guard sweep == 0 else { return }
        withAnimation(.timingCurve(Self.sweepCurve, duration: Self.sweepDuration).delay(Self.startDelay)) {
            sweep = 1
        }
        // The score ticks up in step with the needle, following the same curve, reaching 8.9 as it lands
        let steps = 20
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let value = (Self.score * Self.sweepCurve.value(at: t) * 10).rounded() / 10
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.startDelay + Self.sweepDuration * t) {
                withAnimation(.snappy(duration: Self.sweepDuration / Double(steps))) { shownScore = value }
            }
        }
    }
}

/// Shows the dial's ticks from 9 o'clock round to `angle` degrees clockwise, with a soft trailing edge so the
/// ticks just ahead of the needle glow in (at the end that edge reaches the dial's far side, showing it whole)
struct GaugeReveal: ViewModifier, Animatable {
    var angle: Double
    /// The dial's hub, in the masked view's own unit space
    var center: UnitPoint = .bottom
    var feather = 36.0

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func body(content: Content) -> some View {
        let swept = max(0, angle)
        let lit = swept / 360
        // The soft edge grows in with the sweep, so nothing shows before it starts
        let fade = (swept + min(feather, swept)) / 360
        content.mask {
            // Centred on the dial's hub (bottom middle of the half-circle image); 180° is 9 o'clock
            AngularGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: lit),
                    .init(color: .clear, location: min(fade, 0.999)),
                    .init(color: .clear, location: 1),
                ],
                center: center,
                startAngle: .degrees(180),
                endAngle: .degrees(540)
            )
        }
    }
}

// MARK: Quick read (1050:28570)

private struct QuickReadWidget: View {
    var body: some View {
        PinnedWidget(rim: WidgetRim.cool) {
            WidgetCard(width: 180, height: 186, corners: RectangleCornerRadii(topLeading: 35, bottomLeading: 35, bottomTrailing: 35, topTrailing: 35)) {
                Text("Quick read")
                    .font(FigmaFont.walsheim(17))
                    .foregroundStyle(Color.black)
                    .frame(height: 19)
                    .at(15, 18)

                Text("Nift is underperfoming due to persistent foreign investor (FII/FPI) selling roughly ₹52,000 crore pulled out in October alone driven by high crude oil prices, rising domestic inflation and weak global cues.")
                    .font(FigmaFont.walsheim(13.859))
                    .lineSpacing(3.9)
                    .foregroundStyle(LinearGradient(
                        colors: [Color.black.opacity(0.93), Color(white: 0.4, opacity: 0.25)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 154, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .at(15, 54)
            }
            .at(3, 3)
        }
    }
}

#Preview {
    HomeV3View()
}
