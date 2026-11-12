import SwiftUI

/// Figma: "iPhone 14 Plus - 235" (792:13117) — a slider from SIMPLY → ANY → TERMS that rewrites the card
/// from plain language to shorthand. Simply = 792:13209, Any = 792:13236; Terms is the shortest form.
struct OnboardingComplexityView: View {
    let onContinue: () -> Void

    @State private var position: CGFloat = 0     // 0…1 along the track
    @State private var level: ComplexityLevel = .simply

    var body: some View {
        ZStack(alignment: .topLeading) {
            OnboardingBackground()

            Text("Adjust to what feels comfortable")
                .font(FigmaFont.walsheimMedium(31))
                .foregroundStyle(Color.ink)
                .frame(width: 344, alignment: .leading)
                .at(23, 81)

            DashedRule()
                .frame(width: 344, height: 2)
                .at(23, 188)

            ComplexityCard(level: level)
                .at(32, 211)

            ComplexitySlider(position: $position) { newLevel in
                guard newLevel != level else { return }
                Haptics.tap()
                level = newLevel
            }
            .at(33, 523)

            OnboardingButton(title: "Continue", action: onContinue)
                .at(23, 738)
        }
        .frame(width: MutualFundScreen.canvasWidth, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(OnboardingBackground())
        .onAppear {
            // `-complexity any|terms`: start at that level (for screenshots)
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-complexity"), i + 1 < args.count,
               let l = ComplexityLevel(rawValue: args[i + 1]) {
                level = l
                position = l.stop
            }
        }
    }
}

enum ComplexityLevel: String, CaseIterable {
    case simply, any, terms

    var stop: CGFloat {
        switch self {
        case .simply: 0
        case .any: 0.5
        case .terms: 1
        }
    }

    static func nearest(to position: CGFloat) -> ComplexityLevel {
        allCases.min { abs($0.stop - position) < abs($1.stop - position) }!
    }
}

// MARK: - Card

private struct ComplexityCard: View {
    let level: ComplexityLevel

    /// What the card shows on each side of the sweeping heat band
    @State private var fromLevel: ComplexityLevel = .simply
    @State private var toLevel: ComplexityLevel = .simply
    @State private var sweep: CGFloat = 1
    @State private var cardHeight: CGFloat = 269

    private static let width: CGFloat = 326

    private func height(_ level: ComplexityLevel) -> CGFloat {
        switch level {
        case .simply: 269
        case .any: 234
        case .terms: 192
        }
    }

    var body: some View {
        HeatSweep(
            sweep: sweep,
            forward: toLevel.stop >= fromLevel.stop,
            width: Self.width,
            height: cardHeight
        ) {
            content(fromLevel)
        } after: {
            content(toLevel)
        }
        .frame(width: Self.width, height: cardHeight, alignment: .topLeading)
        .background(Color(hex: 0xF2F2F2))
        .clipped()
        .overlay(Rectangle().stroke(Color.black.opacity(0.05), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 40, x: 0, y: 3)
        .onAppear { fromLevel = level; toLevel = level; cardHeight = height(level) }
        .onChange(of: level) { _, new in
            // Reset the sweep instantly (no animation), so the new content is only revealed by the band
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) {
                fromLevel = toLevel
                toLevel = new
                sweep = 0
            }
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 3.0)) { sweep = 1 }
                // The card resizes along with the sweep
                withAnimation(.easeInOut(duration: 3.0)) { cardHeight = height(new) }
            }
        }
    }

    @ViewBuilder
    private func content(_ level: ComplexityLevel) -> some View {
        ZStack(alignment: .topLeading) {
            Image("MetaIcon")
                .resizable()
                .frame(width: 36, height: 39)
                .frame(width: 37, height: 37)
                .clipped()
                .at(13, 17)

            switch level {
            case .simply: simply
            case .any: any
            case .terms: terms
            }
        }
        .frame(width: Self.width, height: 269, alignment: .topLeading)
    }

    // 792:13209 — plain language
    private var simply: some View {
        ZStack(alignment: .topLeading) {
            header("Mircosoft", "via New york stock exchange")
            label("Worth today").at(14, 77)
            amount("Rs1,42,300").at(128, 77)
            label("Growth").at(14, 116)
            amount("Rs49,300").at(128, 116)
            label("Yearly growth").at(14, 157)
            value("Grew 12.4% a year").at(128, 157)
            caption("Growth").at(128, 179)
            label("Fee by fund", strong: true).at(14, 212)
            value("0.63%").at(128, 212)
            caption("Applicable when you exit").at(128, 234)
        }
    }

    // 792:13236 — "any"
    private var any: some View {
        ZStack(alignment: .topLeading) {
            header("MSFT", "NYSE")
            label("Total worth").at(14, 77)
            amount("Rs1,42,300").at(128, 77)
            gain.at(251, 77)
            label("XIRR").at(14, 122)
            value("12.4%").at(128, 122)
            caption("Know more").at(128, 144)
            label("Expense ratio", strong: true).at(14, 177)
            value("0.63%").at(128, 177)
            caption("Applicable when you exit").at(128, 199)
        }
    }

    // Shortest form: terms only, no explanations
    private var terms: some View {
        ZStack(alignment: .topLeading) {
            header("MSFT", "NYSE")
            label("Total worth").at(14, 77)
            amount("Rs1,42,300").at(128, 77)
            gain.at(251, 77)
            label("XIRR").at(14, 117)
            value("12.4%").at(128, 117)
            label("Exp. ratio", strong: true).at(14, 152)
            value("0.63%").at(128, 152)
        }
    }

    private func header(_ title: String, _ subtitle: String) -> some View {
        ZStack(alignment: .topLeading) {
            Text(title)
                .font(FigmaFont.walsheimMedium(15))
                .foregroundStyle(Color.black.opacity(0.83))
                .at(59, 17)
            Text(subtitle)
                .font(FigmaFont.walsheim(14))
                .foregroundStyle(Color.black.opacity(0.56))
                .at(59, 37)
        }
    }

    private func label(_ s: String, strong: Bool = false) -> some View {
        Text(s)
            .font(FigmaFont.walsheim(15))
            .foregroundStyle(Color.ink.opacity(strong ? 1 : 0.8))
    }

    private func value(_ s: String) -> some View {
        Text(s)
            .font(FigmaFont.walsheim(15))
            .foregroundStyle(Color.ink)
    }

    private func caption(_ s: String) -> some View {
        Text(s)
            .font(FigmaFont.walsheim(13))
            .foregroundStyle(Color.black.opacity(0.5))
    }

    private func amount(_ whole: String) -> some View {
        HStack(alignment: .top, spacing: 1) {
            Text(whole)
                .font(FigmaFont.walsheimMedium(19.23))
                .foregroundStyle(Color.black)
            Text(".02")
                .font(FigmaFont.walsheimMedium(14.859))
                .foregroundStyle(Color.black.opacity(0.6))
                .padding(.top, 4.2)
        }
    }

    private var gain: some View {
        Text("+42.3%")
            .font(FigmaFont.walsheimMedium(19.23))
            .foregroundStyle(Color.gain)
    }
}

// MARK: - Heat sweep

/// A heat-map light band crosses the card; behind it the new content is revealed, ahead of it the old
/// content remains, and everything near the band is warped. `sweep` is animated 0 → 1.
struct HeatSweep<Before: View, After: View>: View, Animatable {
    var sweep: CGFloat
    let forward: Bool
    let width: CGFloat
    let height: CGFloat
    /// The tallest the content gets, which the band travels and the masks cover
    var contentHeight: CGFloat = 269
    @ViewBuilder let before: () -> Before
    @ViewBuilder let after: () -> After

    var animatableData: CGFloat {
        get { sweep }
        set { sweep = newValue }
    }

    /// Thickness of the band, which travels vertically
    private let bandHeight: CGFloat = 170

    var body: some View {
        let travel = height + bandHeight * 2
        // Forward (towards TERMS) sweeps top → bottom, backward bottom → top
        let p = forward ? sweep : 1 - sweep
        let bandY = -bandHeight + travel * p           // centre of the band
        let active = sweep > 0 && sweep < 1
        // Warp is strongest mid-sweep, zero at either end
        let strength = active ? sin(.pi * sweep) : 0

        ZStack(alignment: .topLeading) {
            // Old content ahead of the band, new content behind it
            before()
                .mask(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: width, height: max(0, forward ? contentHeight - bandY : bandY))
                        .offset(y: forward ? bandY : 0)
                }
            after()
                .mask(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: width, height: max(0, forward ? bandY : contentHeight - bandY))
                        .offset(y: forward ? 0 : bandY)
                }
        }
        .frame(width: width, height: contentHeight, alignment: .topLeading)
        .distortionEffect(
            ShaderLibrary.bandWarpY(.float(bandY), .float(60), .float(strength)),
            maxSampleOffset: CGSize(width: 16, height: 60),
            // Only while the band's crossing; at rest the content is drawn as it is
            isEnabled: active
        )
        .overlay(alignment: .topLeading) {
            // Glass light band, feathered smoothly above and below
            let feather = LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.15), location: 0.15),
                    .init(color: .black.opacity(0.5), location: 0.3),
                    .init(color: .black.opacity(0.85), location: 0.42),
                    .init(color: .black, location: 0.5),
                    .init(color: .black.opacity(0.85), location: 0.58),
                    .init(color: .black.opacity(0.5), location: 0.7),
                    .init(color: .black.opacity(0.15), location: 0.85),
                    .init(color: .clear, location: 1.0),
                ],
                startPoint: .top, endPoint: .bottom
            )
            ZStack {
                // Heat colours spread through the band's thickness, warm on top, cool below
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: 0xFF8A65), location: 0.0),
                        .init(color: Color(hex: 0xFFD54F), location: 0.3),
                        .init(color: Color(hex: 0x69F0AE), location: 0.6),
                        .init(color: Color(hex: 0x64B5F6), location: 1.0),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .opacity(0.16)
                .blendMode(.plusLighter)
                .blur(radius: 10)
                // Faint light at the core of the band
                Color.white.opacity(0.18)
                    .frame(height: bandHeight * 0.25)
                    .blur(radius: 12)
            }
            .mask(feather)
            .frame(width: width + 40, height: bandHeight)
            .offset(x: -20, y: bandY - bandHeight / 2)
            .opacity(active ? 1 : 0)
            .allowsHitTesting(false)
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }
}

// MARK: - Slider (792:13228), 325 × 61

private struct ComplexitySlider: View {
    @Binding var position: CGFloat
    let onLevel: (ComplexityLevel) -> Void

    // Knob centre travels between the track ends (knob 25pt, track x 2…324)
    private static let minX: CGFloat = 21.5
    private static let maxX: CGFloat = 304.5
    private static let stops: [(CGFloat, UInt32)] = [
        (0, 0x7F00ED), (0.34615, 0xD8B000), (0.65385, 0x00E1A9), (1, 0x0063D4),
    ]

    @State private var dragStart: CGFloat?

    var body: some View {
        let knobX = Self.minX + (Self.maxX - Self.minX) * position

        ZStack(alignment: .topLeading) {
            Text("SIMPLY").modifier(LabelStyle()).at(0, 0)
            Text("ANY").modifier(LabelStyle()).frame(width: 325).at(0, 0)
            Text("TERMS").modifier(LabelStyle()).frame(width: 325, alignment: .trailing).at(0, 0)

            LinearGradient(
                stops: Self.stops.map { .init(color: Color(hex: $0.1), location: $0.0) },
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: 322, height: 5)
            .at(2, 46)

            // Knob: 25pt ring in the track colour under it, white 19pt centre
            Circle()
                .fill(Self.color(at: (knobX - 2) / 322))
                .frame(width: 25, height: 25)
                .overlay(Circle().fill(Color.white).frame(width: 19, height: 19))
                .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
                .at(knobX - 12.5, 36)
        }
        .frame(width: 325, height: 61, alignment: .topLeading)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if dragStart == nil { dragStart = position; Haptics.prepare() }
                    let x = value.location.x
                    position = min(1, max(0, (x - Self.minX) / (Self.maxX - Self.minX)))
                    onLevel(.nearest(to: position))
                }
                .onEnded { _ in
                    dragStart = nil
                    let level = ComplexityLevel.nearest(to: position)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { position = level.stop }
                    onLevel(level)
                }
        )
    }

    /// Track gradient colour at `t` (0…1)
    private static func color(at t: CGFloat) -> Color {
        let t = min(1, max(0, t))
        var lower = stops[0], upper = stops[stops.count - 1]
        for i in 0..<(stops.count - 1) where t >= stops[i].0 && t <= stops[i + 1].0 {
            lower = stops[i]; upper = stops[i + 1]
        }
        let f = (t - lower.0) / max(0.0001, upper.0 - lower.0)
        func ch(_ c: UInt32, _ s: UInt32) -> Double { Double((c >> s) & 0xFF) / 255 }
        func mix(_ s: UInt32) -> Double { ch(lower.1, s) + (ch(upper.1, s) - ch(lower.1, s)) * Double(f) }
        return Color(red: mix(16), green: mix(8), blue: mix(0))
    }

    private struct LabelStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(FigmaFont.walsheim(14))
                .tracking(1.26)
                .foregroundStyle(Color.black.opacity(0.7))
        }
    }
}

#Preview {
    OnboardingComplexityView(onContinue: {})
}
