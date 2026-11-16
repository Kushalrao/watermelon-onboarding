import SwiftUI

/// Figma "iPhone 14 Plus - 469" (777:3307): the FD page's "Your deposits" side. "Total deposits" over a chart whose
/// lines grow out from nothing when the side loads, with the span to look over under it; then the active deposits
/// in one card, a row each, and the advisor's questions.
struct FDYourDepositsView: View {
    /// Opens a deposit's own page
    var onOpen: (FDHeldDeposit, CGRect) -> Void = { _, _ in }

    private static let held = FDHeldDeposit.all
    @State private var span = "3Y"
    /// Where each row sits on screen, for the page that grows out of it
    @State private var rows = FDRowFrames()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            chartCard
                .padding(.horizontal, 11) // Gap: the card sits 11 from the screen edge, no spacing token
            activeCard
                .padding(.top, 27) // Gap: 27 under the chart, no spacing token
                .padding(.horizontal, 11) // Gap: the card sits 11 from the screen edge, no spacing token
            FDQuestionTiles()
                .padding(.top, 37) // Gap: 37 under the deposits, no spacing token
                .padding(.horizontal, SpacingScale.spaceSm)
        }
    }

    // MARK: Chart

    private var chartCard: some View {
        Surface(surface: .surfaceWidget, radius: .radius23, border: .borderSubtle, shadow: .token(.shadow2)) {
            VStack(alignment: .leading, spacing: 0) {
                // Gap: Md 23/35 in #212121 has no text style or content token
                GapText("Total deposits", family: .walsheim, medium: true, size: 23, lineHeight: 35, color: Color(hex: 0x212121)) // Gap: unbound #212121
                    .fixedSize()
                    .padding(.top, 14) // Gap: 14 above the title, no spacing token
                    .padding(.leading, SpacingScale.spaceLg)
                worth
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 22) // Gap: 22 under the title, no spacing token
                    .padding(.trailing, 18) // Gap: 18 beside the amount, no spacing token
                FDProjectionChart()
                    .padding(.top, 3) // Gap: 3 under the amount, no spacing token
                    .padding(.horizontal, SpacingScale.spaceLg)
                FDSpanRow(span: $span)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 19) // Gap: 19 under the chart, no spacing token
                    .padding(.bottom, SpacingScale.space2xl)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// "₹1,292.03" over "Last 3 months"
    private var worth: some View {
        let ink = Color(hex: 0x212121) // Gap: unbound #212121
        return ZStack(alignment: .topLeading) {
            // Gap: Md 35/38.71, Md 35.613/48 and Md 26.323/40.258 have no text style; #212121 and its 43% are unbound
            GapText("₹", family: .walsheim, medium: true, size: 35, lineHeight: 38.71, color: ink)
                .fixedSize()
                .offset(y: 4)
            GapText("1,292", family: .walsheim, medium: true, size: 35.613, lineHeight: 48, color: ink)
                .fixedSize()
                .offset(x: 23.13)
            GapText(".03", family: .walsheim, medium: true, size: 26.323, lineHeight: 40.258, color: ink.opacity(0.43))
                .fixedSize()
                .offset(x: 111.38, y: 6.19)
            // Gap: Rg 15/23 in black 43% has no text style or content token
            GapText("Last 3 months", family: .walsheim, medium: false, size: 15, lineHeight: 23, color: Color.black.opacity(0.43)) // Gap: unbound black 43%
                .fixedSize()
                .offset(x: 55, y: 46)
        }
        .frame(width: 150, height: 69, alignment: .topLeading)
        .accessibilityElement()
        .accessibilityLabel("₹1,292.03, last 3 months")
    }

    // MARK: Active fixed deposit

    /// The deposits in one card (777:3349): the title, then a 95 row each with a rule between
    private var activeCard: some View {
        let shape = RoundedRectangle(cornerRadius: RadiusToken.radius23.value, style: .continuous)
        return VStack(alignment: .leading, spacing: 0) {
            // Gap: Md 23/35 in #212121 has no text style or content token
            GapText("Active fixed deposit", family: .walsheim, medium: true, size: 23, lineHeight: 35, color: Color(hex: 0x212121)) // Gap: unbound #212121
                .fixedSize()
                .padding(.leading, 17) // Gap: 17 beside the title, no spacing token
                .padding(.top, 15) // Gap: 15 above the title, no spacing token
                .frame(height: 63, alignment: .top)
            ForEach(Self.held) { held in
                row(held)
                if held.id != Self.held.count - 1 {
                    Rectangle().fill(Color.black.opacity(0.09)).frame(height: 1) // Gap: black 9% rule, unbound
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorScale.surfaceWidget)
        .clipShape(shape)
        .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4) // Gap: 0 4 100 +12 at 5%, not a Shadow style; the spread is not drawn. ds-lint-ignore: no_raw_shadow
    }

    private func row(_ held: FDHeldDeposit) -> some View {
        Button {
            Haptics.tap()
            onOpen(held, rows.frames[held.id] ?? .zero)
        } label: {
        HStack(alignment: .top, spacing: 0) {
            Image(held.logo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 37, height: 37)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous)) // Gap: 5 is not a Radius variable
                .frame(width: 51, height: 51)
                .background(ColorScale.surfaceSunken1)
                .clipShape(RoundedRectangle(cornerRadius: RadiusToken.radius15.value, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) { // Gap: 5 between the lines, no spacing token
                // Gap: Rg 19/25 in black 83% has no text style or content token
                GapText(held.name, family: .walsheim, medium: false, size: 19, lineHeight: 25, color: Color.black.opacity(0.83)) // Gap: unbound black 83%
                DsText("Matures in 13 months", variant: .p4, color: .contentTertiary)
            }
            .padding(.leading, 17) // Gap: 17 beside the logo, no spacing token
            Spacer(minLength: 0)
            Image("FDYoursChevron")
                .rotationEffect(.degrees(180))
                .padding(.top, 4) // Gap: the chevron sits 4 below the name's top, no spacing token
                .accessibilityHidden(true)
        }
        .padding(.leading, 17) // Gap: 17 beside the logo, no spacing token
        .padding(.trailing, 21) // Gap: 21 beside the chevron, no spacing token
        .padding(.top, 19) // Gap: 19 above the name, no spacing token
        .frame(height: 94, alignment: .top)
        .contentShape(Rectangle())
        // Kept outside the view's state: it's only read when the row is tapped
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { rows.frames[held.id] = $0 }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// Where the rows are on screen. A plain box, so writing a frame redraws nothing.
final class FDRowFrames {
    var frames: [Int: CGRect] = [:]
}

/// The deposits chart, 336 × 281 as the frame draws it (x stretches with the card): three rules, the scale on the
/// right, the days along the foot, and the lines, which grow out from the chart's corner each time it appears
struct FDProjectionChart: View {
    /// 0 = the lines have not left the chart's corner, 1 = drawn
    @State private var grown: CGFloat = 0
    @State private var dotShown = false
    /// Held back a moment, for a page that's still arriving
    var delay: Double = 0

    var body: some View {
        chart
            .onAppear {
                grown = 0
                dotShown = false
                withAnimation(.easeInOut(duration: 1.3).delay(0.15 + delay)) { grown = 1 }
                withAnimation(.spring(duration: 0.45, bounce: 0.45).delay(1.25 + delay)) { dotShown = true }
            }
    }

    /// The frame's 336 × 281 chart: three rules, the scale on the right, the days along the foot, and the lines
    private var chart: some View {
        ZStack(alignment: .topLeading) {
            // Gap: rules in black 13% and 33%, unbound
            rule(0.13).offset(y: 8)
            rule(0.13).offset(y: 128)
            rule(0.33).offset(y: 248)
            ZStack(alignment: .topLeading) {
                // What it could come to, dashed; what it has been so far, in lavender; and this stretch of it, to the dot
                FDYoursLine(points: FDYoursLine.projection)
                    .trim(from: 0, to: grown)
                    .stroke(Color(hex: 0xCEED79), style: StrokeStyle(lineWidth: 4, dash: [7.8, 7.8])) // Gap: unbound #CEED79, 4 is not a stroke token
                FDYoursCurve(end: CGPoint(x: 300.5, y: 99.0925), control1: CGPoint(x: 82, y: 221.259), control2: CGPoint(x: 183, y: 234.592))
                    .trim(from: 0, to: grown)
                    .stroke(Color(hex: 0xCC97D7), lineWidth: 4) // Gap: unbound #CC97D7, 4 is not a stroke token
                GeometryReader { geo in
                    let scale = geo.size.width / 336
                    FDYoursCurve(end: CGPoint(x: 107, y: 200.9), control1: CGPoint(x: 30.3098, y: 232.343), control2: CGPoint(x: 67.6288, y: 220.269))
                        .trim(from: 0, to: grown)
                        .stroke(
                            // Gap: the frame's own gradient, lavender into green; unbound
                            LinearGradient(
                                stops: [.init(color: Color(hex: 0xCC97D7), location: 0), .init(color: Color(hex: 0xD5BD64), location: 0.488593), .init(color: Color(hex: 0x3FD519), location: 1)], // Gap: unbound
                                startPoint: UnitPoint(x: 2.5 * scale / geo.size.width, y: 240.092 / 244.092),
                                endPoint: UnitPoint(x: 109.5 * scale / geo.size.width, y: 201.092 / 244.092)
                            ),
                            lineWidth: 4 // Gap: 4 is not a stroke token
                        )
                    Circle()
                        .fill(ColorScale.surfaceWidget)
                        .overlay(Circle().strokeBorder(Color(hex: 0x3FD519), lineWidth: 3).padding(-1.5)) // Gap: unbound #3FD519, 3 is not a stroke token
                        .frame(width: 14, height: 14)
                        .scaleEffect(dotShown ? 1 : 0)
                        .position(x: 109.5 * scale, y: 200.592)
                }
            }
            .frame(height: 244.092)
            .offset(y: 4.9) // The lines' frame sits 8 down the chart, drawn 3.1 above itself
            .accessibilityHidden(true)

            // Gap: Rg 12/17 at 7% tracking in black 40% and 60% has no text style or content token
            Group {
                scaleLabel("¢1800").offset(y: 0)
                scaleLabel("¢1255").offset(y: 42)
                scaleLabel("¢900").offset(y: 120)
                scaleLabel("¢100").offset(y: 240)
            }
            .accessibilityHidden(true)
            HStack(spacing: 0) {
                ForEach(["12", "13", "15", "19"], id: \.self) { day in
                    GapText(day, family: .walsheim, medium: false, size: 12, lineHeight: 17, trackingPercent: 7, color: Color.black.opacity(0.6)) // Gap: unbound black 60%
                        .fixedSize()
                    if day != "19" { Spacer(minLength: 0) }
                }
            }
            .padding(.leading, 33) // Gap: the days run from 33 in to 49 short of the side
            .padding(.trailing, 49) // Gap: as above
            .offset(y: 264)
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 281, alignment: .topLeading)
    }

    private func rule(_ opacity: Double) -> some View {
        Rectangle().fill(Color.black.opacity(opacity)).frame(height: 1) // Gap: unbound black, at the opacity the rule is drawn in
    }

    private func scaleLabel(_ text: String) -> some View {
        GapText(text, family: .walsheim, medium: false, size: 12, lineHeight: 17, trackingPercent: 7, color: Color.black.opacity(0.4)) // Gap: unbound black 40%
            .fixedSize()
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

/// A deposit that's held: its row under "Your deposits" and its own page
struct FDHeldDeposit: Identifiable, Equatable {
    let id: Int
    let name: String, logo: String
    /// The page's title, over two lines, and the line above it
    let title: String, licence: String

    /// The frame's three rows
    static let all = [
        FDHeldDeposit(id: 0, name: "Suryoday SFB", logo: "FDSuryoday", title: "Suryoday Small Finance\nBank Fixed deposit", licence: "RBI Licensed Small finance bank"),
        FDHeldDeposit(id: 1, name: "Bajaj Finance", logo: "FDBajaj", title: "Bajaj Finance\nFixed deposit", licence: "RBI Registered finance company"),
        FDHeldDeposit(id: 2, name: "Suryoday SFB", logo: "FDSuryoday", title: "Suryoday Small Finance\nBank Fixed deposit", licence: "RBI Licensed Small finance bank"),
    ]
}

/// The spans under a deposits chart (1M · 6M · 1Y · 3Y · 5Y, and All where the frame has it), the chosen one ringed
struct FDSpanRow: View {
    /// Each span and where its centre sits along the 316 row
    static let spans: [(name: String, centre: CGFloat)] = [("1M", 9.5), ("6M", 71), ("1Y", 130.5), ("3Y", 188), ("5Y", 247), ("All", 306.5)]

    @Binding var span: String
    var showsAll = false

    var body: some View {
        let spans = showsAll ? Self.spans : Array(Self.spans.dropLast())
        let chosen = spans.first { $0.name == span }?.centre ?? 188
        ZStack(alignment: .topLeading) {
            Capsule()
                .strokeBorder(Color.black.opacity(0.41), lineWidth: 1) // Gap: 1pt black 41%, unbound
                .frame(width: 40, height: 31)
                .offset(x: chosen - 20)
            ForEach(spans, id: \.name) { item in
                Button {
                    guard span != item.name else { return }
                    Haptics.tap()
                    withAnimation(.snappy(duration: 0.25)) { span = item.name }
                } label: {
                    // Gap: Rg 15/21 at 7% tracking in black 60% has no text style or content token
                    GapText(item.name, family: .walsheim, medium: false, size: 15, lineHeight: 21, trackingPercent: 7, color: Color.black.opacity(0.6)) // Gap: unbound black 60%
                        .fixedSize()
                        .frame(width: 44, height: 31)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(span == item.name ? .isSelected : [])
                .position(x: item.centre, y: 15.5)
            }
        }
        .frame(width: 316, height: 31)
    }
}

/// A line of the chart from its corner (3.5, 238.092), as the frame draws it on 336 × 244; x stretches with the card
private struct FDYoursCurve: Shape {
    let end: CGPoint
    let control1: CGPoint
    let control2: CGPoint

    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 336
        func at(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x * scale, y: point.y) }
        var path = Path()
        path.move(to: at(CGPoint(x: 3.5, y: 238.092)))
        path.addCurve(to: at(end), control1: at(control1), control2: at(control2))
        return path
    }
}

/// The dashed line, through the ends of the frame's own dashes
private struct FDYoursLine: Shape {
    let points: [(CGFloat, CGFloat)]

    static let projection: [(CGFloat, CGFloat)] = [
        (3.5, 238.092), (7.27857, 237.256), (14.9446, 235.408), (22.5694, 233.386), (30.1584, 231.208), (37.7165, 228.884),
        (45.2104, 226.433), (52.6346, 223.865), (60.0384, 221.169), (67.4211, 218.347), (74.7446, 215.415), (81.9964, 212.382),
        (89.2295, 209.225), (96.4239, 205.954), (103.526, 202.593), (110.606, 199.109), (117.635, 195.513), (124.58, 191.822),
        (131.492, 188.008), (138.33, 184.091), (145.099, 180.064), (151.821, 175.914), (158.445, 171.668), (165.009, 167.298),
        (171.496, 162.813), (177.893, 158.218), (184.217, 153.495), (190.436, 148.666), (196.569, 143.71), (202.601, 138.634),
        (208.525, 133.44), (214.348, 128.115), (220.043, 122.677), (225.626, 117.108), (231.078, 111.418), (236.397, 105.602),
        (241.579, 99.6583), (246.61, 93.5969), (251.496, 87.4026), (256.213, 81.0974), (260.77, 74.6628), (265.152, 68.1135),
        (269.354, 61.4475), (273.374, 54.6619), (277.195, 47.7777), (280.828, 40.767), (284.243, 33.6822), (287.461, 26.4749),
        (290.456, 19.1976), (293.239, 11.8182), (295.798, 4.36799), (297, 0.592477),
    ]

    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 336
        var path = Path()
        for (index, point) in points.enumerated() {
            let at = CGPoint(x: point.0 * scale, y: point.1)
            if index == 0 { path.move(to: at) } else { path.addLine(to: at) }
        }
        return path
    }
}
