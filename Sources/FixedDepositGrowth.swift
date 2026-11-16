import SwiftUI

/// Figma 733:3507: "How your money could grow?". What a one-time deposit in this bank comes to over a chosen
/// time, drawn against an SBI FD and an SBI savings account. The time is picked from the chips and the deposit
/// with the slider. The lines keep to the chart, well apart; the scale beside them scrolls to the new amounts,
/// and the lines stretch past their place and spring back each time.
struct FDGrowthWidget: View {
    let deposit: FixedDepositsView.Deposit

    private struct Span {
        let chip: String
        let label: String
        let years: Double
    }

    private static let spans = [
        Span(chip: "1M", label: "1 month", years: 1.0 / 12),
        Span(chip: "6M", label: "6 months", years: 0.5),
        Span(chip: "1Y", label: "1 year", years: 1),
        Span(chip: "3Y", label: "3 years", years: 3),
        Span(chip: "5Y", label: "5 years", years: 5),
    ]
    /// Where each chip's middle sits along the 316 row
    private static let chipCentres: [CGFloat] = [9.5, 71, 130.5, 188, 247]


    @State private var span = 3
    @State private var amount = 40_000
    /// Counts the changes that set the lines stretching, and which way the last one went
    @State private var kick = 0
    @State private var kickDirection: CGFloat = 1

    /// Compounded quarterly at the bank's best rate, as the plans' returns are
    private var maturity: Int {
        FDOffer(term: "", rate: String(deposit.best), years: Self.spans[span].years).maturity(of: amount)
    }

    var body: some View {
        Surface(surface: .surfaceWidget, radius: .radius27) {
            VStack(alignment: .leading, spacing: 0) {
                DsText("How your money could grow?", variant: .h5)
                    .padding(.top, 17) // Gap: 17 above the title, no spacing token
                    .padding(.leading, 17) // Gap: 17 beside the title, no spacing token
                summary
                    .padding(.top, 17) // Gap: 17 under the title, no spacing token
                    .padding(.leading, 17) // Gap: 17 beside the summary, no spacing token
                    .padding(.trailing, 15) // Gap: 15 beside the amount, no spacing token
                chart
                    .padding(.top, 11) // Gap: 11 under the summary, no spacing token
                    .padding(.horizontal, 13) // Gap: 13 beside the chart, no spacing token
                chips
                    .padding(.top, 13) // Gap: 13 under the chart, no spacing token
                amountSlider
                    .padding(.top, 43) // Gap: 43 under the chips, no spacing token
                    .padding(.horizontal, 15) // Gap: 15 beside the slider, no spacing token
                    .padding(.bottom, 33) // Gap: 33 under the slider, no spacing token
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: The time and what it comes to

    private var summary: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // Gap: Rg 23/35 in #212121 has no text style or content token
            GapText(Self.spans[span].label, family: .walsheim, medium: false, size: 23, lineHeight: 35, color: Color(hex: 0x212121)) // Gap: unbound #212121
                .padding(.bottom, 2) // Gap: the time sits 2 above the amount's foot
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 0) {
                // Gap: Rg 13/19 in black 40% has no text style or content token
                GapText("Maturity amount", family: .walsheim, medium: false, size: 13, lineHeight: 19, color: Color.black.opacity(0.4)) // Gap: unbound black 40%
                HStack(alignment: .top, spacing: 4) { // Gap: 4 between "Rs" and the number, no spacing token
                    // Gap: Md 26.323/38.71 and Md 35.613/48 in utility-green/500 have no text style or content token
                    GapText("Rs", family: .walsheim, medium: true, size: 26.323, lineHeight: 38.71,
                            color: ColorPrimitives.utilityGreen500) // ds-lint-ignore: no_tier1
                        .padding(.top, 7.74) // Gap: "Rs" sits 7.74 down beside the number
                    GapText(String(FixedDepositsView.rupees(maturity).dropFirst(2)), family: .walsheim, medium: true, size: 35.613, lineHeight: 48,
                            color: ColorPrimitives.utilityGreen500) // ds-lint-ignore: no_tier1
                        .contentTransition(.numericText())
                }
                .fixedSize()
            }
        }
        .frame(height: 67)
        .accessibilityElement(children: .combine)
    }

    // MARK: Chart

    // Gap: the frame names no rates for the two SBI lines; these stand in for an SBI FD and an SBI savings account
    private static let sbiFDRate = 6.75
    private static let sbiSavingsRate = 2.7

    private func maturity(at rate: Double) -> Int {
        FDOffer(term: "", rate: String(rate), years: Self.spans[span].years).maturity(of: amount)
    }

    /// Points per rupee. The view frames the deposit and what this bank makes of it, as the frame draws them: the
    /// lines leave 179.5 down the grid and this bank's arrives 28 down. So the three lines always fill the chart,
    /// well apart, and it is the scale that travels: its amounts scroll up or down as the deposit and the time change.
    private var pointsPerRupee: CGFloat { 151.5 / CGFloat(max(maturity - amount, 1)) }

    /// How far down the 201 grid a value sits
    private func y(_ value: Double) -> CGFloat { 179.5 - CGFloat(value - Double(amount)) * pointsPerRupee }

    /// The gap between the scale's amounts: a round figure that puts about five of them in view
    private var gridStep: Double {
        let raw = 201 / Double(pointsPerRupee) / 5
        let magnitude = pow(10, floor(log10(raw)))
        return ([1, 2, 2.5, 5, 10].first { $0 * magnitude >= raw } ?? 10) * magnitude
    }

    /// The scale's amounts in view, and two more off each edge so they scroll in rather than appear
    private var gridValues: [Double] {
        let step = gridStep
        let lowest = Double(amount) - Double((201 - 179.5) / pointsPerRupee)
        let highest = Double(amount) + Double(179.5 / pointsPerRupee)
        let first = (lowest / step).rounded(.down) - 2, last = (highest / step).rounded(.up) + 2
        return stride(from: first, through: last, by: 1).map { $0 * step }
    }

    /// "Rs45k", or as many decimals as the step between amounts needs ("Rs40.25k")
    private func scaleLabel(_ value: Double) -> String {
        let decimals = gridStep >= 1000 ? 0 : gridStep >= 100 ? 1 : gridStep >= 10 ? 2 : 3
        let needed = gridStep.truncatingRemainder(dividingBy: 1000) == 0 ? 0 : max(decimals, 1)
        return "Rs" + String(format: "%.\(needed)f", value / 1000) + "k"
    }

    private var chart: some View {
        let start = y(Double(amount))
        let bank = y(Double(maturity)), fd = y(Double(maturity(at: Self.sbiFDRate))), savings = y(Double(maturity(at: Self.sbiSavingsRate)))
        // Each pill sits at its line's end, kept 33 clear of the one below so the three never cover each other
        let savingsPill = min(savings + 8, 200)
        let fdPill = min(fd + 8, savingsPill - 33)
        let bankPill = min(bank + 8, fdPill - 33)
        let values = gridValues
        return ZStack(alignment: .topTrailing) {
            // The scale: its rules and amounts ride up and down together, in and out past the chart's edges
            ZStack(alignment: .topTrailing) {
                ForEach(values, id: \.self) { value in
                    Rectangle().fill(Color.black.opacity(0.05)) // Gap: 1pt black 5%, unbound
                        .frame(height: 1)
                        .padding(.trailing, 40) // Gap: the grid stops 40 short of the side, for the scale
                        .offset(y: 8 + y(value) - 0.5)
                    // Gap: Rg 12/17 at 7% tracking has no text style
                    GapText(scaleLabel(value), family: .walsheim, medium: false, size: 12, lineHeight: 17, trackingPercent: 7, color: ColorScale.contentDisabled)
                        .fixedSize()
                        .offset(y: y(value) - 0.5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 217, alignment: .top)
            .clipped()
            .accessibilityHidden(true)
            ZStack(alignment: .top) {
                FDGrowthUprights()
                    .stroke(Color.black.opacity(0.05), lineWidth: 1) // Gap: 1pt black 5%, unbound
                // The lines stretch past their place and spring back whenever the deposit or the time moves them
                ZStack {
                    // Gap: the lines' colours (#B6A97F, #E1D4AB, #3FD519) are unbound, and 3 is not a stroke token
                    FDGrowthCurve(start: start, end: savings)
                        .stroke(Color(hex: 0xB6A97F), style: StrokeStyle(lineWidth: 3, lineCap: .round)) // Gap: unbound #B6A97F
                    FDGrowthCurve(start: start, end: fd)
                        .stroke(Color(hex: 0xE1D4AB), style: StrokeStyle(lineWidth: 3, lineCap: .round)) // Gap: unbound #E1D4AB
                    FDGrowthCurve(start: start, end: bank)
                        .stroke(Color(hex: 0x3FD519), style: StrokeStyle(lineWidth: 3, lineCap: .round)) // Gap: unbound #3FD519
                }
                .keyframeAnimator(initialValue: CGFloat(1), trigger: kick) { lines, stretch in
                    lines.scaleEffect(x: 1, y: stretch, anchor: UnitPoint(x: 0, y: 179.5 / 201))
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(1 + 0.16 * kickDirection, duration: 0.14)
                        SpringKeyframe(1, duration: 0.7, spring: Spring(duration: 0.45, bounce: 0.6))
                    }
                }
            }
            .frame(height: 201, alignment: .top)
            .padding(.trailing, 40) // Gap: the grid stops 40 short of the side, for the scale
            .padding(.top, SpacingScale.spaceMd)
            .accessibilityHidden(true)
            pill(logo: deposit.logo, name: deposit.name, border: ColorScale.borderDefault)
                .padding(.trailing, 48.5) // Gap: the pill ends 48.5 from the side
                .offset(y: bankPill - 14.5)
            pill(logo: "FDGrowthSBI", name: "SBI FD", border: ColorScale.borderSubtle)
                .padding(.trailing, 50.5) // Gap: the pill ends 50.5 from the side
                .offset(y: fdPill - 14.5)
            pill(logo: "FDGrowthSBI", name: "SBI Savings", border: ColorScale.borderSubtle)
                .padding(.trailing, 49) // Gap: the pill ends 49 from the side
                .offset(y: savingsPill - 14.5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 217, alignment: .top)
        .onChange(of: amount) { old, new in nudge(up: new > old) }
        .onChange(of: span) { old, new in nudge(up: new > old) }
    }

    /// Sets the lines stretching: up for more money or time, down for less
    private func nudge(up: Bool) {
        kickDirection = up ? 1 : -1
        kick += 1
    }

    /// Whose curve it is
    private func pill(logo: String, name: String, border: Color) -> some View {
        HStack(spacing: 3) { // Gap: 3 between the logo and the name, no spacing token
            Image(logo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 27, height: 27)
                .clipShape(Circle())
                .accessibilityHidden(true)
            // Gap: P5's type in black 70%, which has no content token
            GapText(name, family: .walsheim, medium: false, size: 13, lineHeight: 21, color: Color.black.opacity(0.7)) // Gap: unbound black 70%
                .fixedSize()
        }
        .padding(.leading, 3) // Gap: 3 beside the logo, no spacing token
        .padding(.trailing, 3) // Gap: 3 beside the name, no spacing token
        .frame(height: 29)
        .background(Capsule().fill(ColorScale.surfaceWidget))
        .overlay(Capsule().strokeBorder(border, lineWidth: 1)) // Gap: 1pt, not the hairline
        .shadow(color: Color.black.opacity(0.07), radius: 30, x: 0, y: 4) // Gap: Shadow/2 and Shadow/3 with their spread, drawn without it. ds-lint-ignore: no_raw_shadow
    }

    // MARK: Time

    private var chips: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Self.spans.indices, id: \.self) { index in
                Button {
                    guard span != index else { return }
                    Haptics.tap()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) { span = index }
                } label: {
                    // Gap: Rg 15/21 at 7% tracking in black 60% has no text style or content token
                    GapText(Self.spans[index].chip, family: .walsheim, medium: false, size: 15, lineHeight: 21, trackingPercent: 7, color: Color.black.opacity(0.6)) // Gap: unbound black 60%
                        .fixedSize()
                        .frame(width: 40, height: 31)
                        .overlay {
                            if span == index {
                                Capsule().strokeBorder(Color.black.opacity(0.41), lineWidth: 1) // Gap: 1pt black 41%, unbound
                            }
                        }
                        .frame(width: 52, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Self.spans[index].label)
                .accessibilityAddTraits(span == index ? .isSelected : [])
                .offset(x: Self.chipCentres[index] - 26, y: -6.5)
            }
        }
        .frame(width: 316, height: 31, alignment: .topLeading)
        .frame(maxWidth: .infinity)
        .offset(x: 2) // The row sits 2 right of the card's middle
    }

    // MARK: Deposit

    private var amountSlider: some View {
        VStack(spacing: 17) { // Gap: 17 between the line and the track, no spacing token
            HStack(spacing: 0) {
                // Gap: Rg and Md 17/21 have no text style (P3 is 17/23)
                GapText("One time deposit", family: .walsheim, medium: false, size: 17, lineHeight: 21, color: ColorScale.contentSecondary)
                Spacer(minLength: 0)
                GapText("Rs " + String(FixedDepositsView.rupees(amount).dropFirst(2)), family: .walsheim, medium: true, size: 17, lineHeight: 21, color: ColorScale.contentPrimary)
                    .contentTransition(.numericText())
            }
            FDAmountSlider(amount: $amount)
        }
    }
}

/// The deposit's slider, Rs10,000 to Rs1,00,000 along a track. Pushed past the track's end, or dragged right fast
/// for a moment, it opens into a meter (Figma 777:3470): the thumb strains against the pull, moving less the
/// further it is dragged, while the meter's marks run under it and the amount climbs for as long as it is held,
/// past what the track could reach. Let go and it is the track again, now reaching as far as the amount chosen.
private struct FDAmountSlider: View {
    @Binding var amount: Int

    private static let lowest = 10_000
    private static let step = 5_000
    /// As far as the meter goes
    private static let most = 1_000_000
    /// The meter's marks: one every Rs1,000, 6 apart, a tall one with its amount every Rs10,000
    private static let markGap: CGFloat = 6

    /// The top of the track; the meter raises it to the amount let go on
    @State private var highest = 100_000
    @State private var metering = false
    /// Where the finger and the thumb were when the meter opened
    @State private var anchor: CGFloat = 0
    @State private var thumbRest: CGFloat = 0
    /// How far the finger has pulled from there, right or left
    @State private var pull: CGFloat = 0
    /// The amount under the thumb, running smoothly between the steps the amount lands on
    @State private var metered: Double = 0
    @State private var dragBegan: Date?
    @State private var runner: Task<Void, Never>?
    /// Counts the time the thumb is held at the top of the track
    @State private var dwell: Task<Void, Never>?
    @State private var lastFinger: CGFloat = 0
    @State private var lastThumb: CGFloat = 0

    private static let morph = Animation.spring(duration: 0.5, bounce: 0.3)

    var body: some View {
        GeometryReader { geo in
            let travel = geo.size.width - 30
            let fraction = CGFloat(min(amount, highest) - Self.lowest) / CGFloat(highest - Self.lowest)
            // In the meter the thumb gives less and less to the pull
            let strain = pull == 0 ? 0 : (pull > 0 ? 1 : -1) * (1 - 1 / (abs(pull) * 0.55 / 70 + 1)) * 70
            let x = metering ? min(max(thumbRest + strain, 0), travel) : travel * fraction
            ZStack(alignment: .leading) {
                meter(width: geo.size.width, thumbCentre: x + 15)
                    .opacity(metering ? 1 : 0)
                Group {
                    Capsule().fill(ColorPrimitives.blue200) // ds-lint-ignore: no_tier1
                        .frame(height: 5)
                    Capsule().fill(ColorPrimitives.blue800) // ds-lint-ignore: no_tier1
                        .frame(width: x + 15, height: 5)
                }
                .opacity(metering ? 0 : 1)
                Capsule().fill(ColorPrimitives.blue900) // ds-lint-ignore: no_tier1
                    .frame(width: 30, height: 25)
                    .overlay(Capsule().fill(ColorScale.surfaceWidget).frame(width: 24, height: 19))
                    .offset(x: x)
            }
            .frame(height: 25)
            .contentShape(Rectangle().inset(by: -12))
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if metering {
                            pull = drag.location.x - anchor
                            return
                        }
                        if dragBegan == nil { dragBegan = Date() }
                        let picked = min(max((drag.location.x - 15) / travel, 0), 1)
                        let raw = Double(Self.lowest) + Double(picked) * Double(highest - Self.lowest)
                        let snapped = Int((raw / Double(Self.step)).rounded()) * Self.step
                        if snapped != amount {
                            Haptics.tap()
                            withAnimation(.spring(duration: 0.5, bounce: 0.32)) { amount = snapped }
                        }
                        // Sliding right for a moment, sooner the faster it goes, or past the end of the track: the meter takes over
                        let pastEnd = drag.location.x > geo.size.width + 6
                        let spent = Date().timeIntervalSince(dragBegan ?? Date())
                        let fast = drag.velocity.width > 650 && drag.translation.width > 18
                        let sliding = drag.translation.width > 28 && spent > 0.18
                        lastFinger = drag.location.x
                        lastThumb = travel * picked
                        if pastEnd || fast || sliding {
                            openMeter(finger: drag.location.x, thumb: travel * picked)
                        } else if picked >= 0.94 {
                            // Held at the top of the track for a moment: the meter takes over too
                            if dwell == nil {
                                dwell = Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 400_000_000)
                                    if !Task.isCancelled, !metering { openMeter(finger: lastFinger, thumb: lastThumb) }
                                }
                            }
                        } else {
                            dwell?.cancel()
                            dwell = nil
                        }
                    }
                    .onEnded { _ in
                        dragBegan = nil
                        dwell?.cancel()
                        dwell = nil
                        if metering { closeMeter() }
                    }
            )
        }
        .frame(height: 25)
        .accessibilityElement()
        .accessibilityLabel("One time deposit")
        .accessibilityValue(FixedDepositsView.rupees(amount))
        .accessibilityAdjustableAction { direction in
            let next = amount + (direction == .increment ? Self.step : -Self.step)
            amount = min(max(next, Self.lowest), highest)
        }
        .onDisappear { runner?.cancel(); dwell?.cancel() }
    }

    private func openMeter(finger: CGFloat, thumb: CGFloat) {
        Haptics.expand()
        dwell = nil
        anchor = finger
        thumbRest = thumb
        pull = 0
        metered = Double(amount)
        withAnimation(Self.morph) { metering = true }
        runner?.cancel()
        runner = Task { @MainActor in
            var last = Date()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 16_000_000)
                let now = Date()
                let elapsed = now.timeIntervalSince(last)
                last = now
                // The further the pull, the faster the amount runs: Rs9,000 a second at 20, Rs70,000 at 100
                let reach = Double(abs(pull))
                let rate = (400 * reach + 3 * reach * reach) * (pull < 0 ? -1 : 1)
                metered = min(max(metered + rate * elapsed, Double(Self.lowest)), Double(Self.most))
                let snapped = Int((metered / Double(Self.step)).rounded()) * Self.step
                if snapped != amount {
                    Haptics.meterTick(intensity: min(1, 0.3 + reach / 200))
                    withAnimation(.spring(duration: 0.5, bounce: 0.32)) { amount = snapped }
                }
            }
        }
    }

    /// Back to the track, which now reaches the amount let go on
    private func closeMeter() {
        runner?.cancel()
        runner = nil
        Haptics.settle()
        withAnimation(Self.morph) {
            highest = max(100_000, amount)
            metering = false
            pull = 0
        }
    }

    /// The meter: 49 tall around the thumb, its marks and amounts running under it
    private func meter(width: CGFloat, thumbCentre: CGFloat) -> some View {
        // The amount at a point x across the meter, the thumb's own under its middle
        let first = Int(((metered - Double(thumbCentre / Self.markGap) * 1000) / 10_000).rounded(.down)) * 10_000
        let tens = Array(stride(from: first, through: first + Int(width / Self.markGap) * 1000 + 20_000, by: 10_000))
        func across(_ value: Int) -> CGFloat { thumbCentre + CGFloat(Double(value) - metered) / 1000 * Self.markGap }
        return Surface(surface: .surfaceWidget, radius: .radius23, border: .borderSubtle, shadow: .token(.shadow2)) {
            ZStack(alignment: .topLeading) {
                FDMeterMarks(offset: across(first), gap: Self.markGap)
                    .stroke(ColorScale.borderDefault, lineWidth: 1) // Gap: 1pt marks, not the hairline
                    .frame(height: 21)
                    .offset(y: 17)
                ForEach(tens, id: \.self) { value in
                    if value >= 0 {
                        // Gap: Rg 10/15 at 7% tracking in black 40% has no text style or content token
                        GapText("Rs\(value / 1000)k", family: .walsheim, medium: false, size: 10, lineHeight: 15, trackingPercent: 7, color: Color.black.opacity(0.4)) // Gap: unbound black 40%
                            .fixedSize()
                            .frame(width: 60)
                            .offset(x: across(value) - 30, y: 3)
                    }
                }
            }
            .frame(width: width, height: 49, alignment: .topLeading)
            .clipped()
        }
        .frame(width: width, height: 49)
        // The thumb sits 3 below the meter's middle
        .offset(y: -3)
        .frame(height: 25)
        .accessibilityHidden(true)
    }
}

/// The meter's marks from `offset` on: one every `gap`, 13 tall, and every tenth the full 21
private struct FDMeterMarks: Shape {
    let offset: CGFloat
    let gap: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var index = 0
        var x = offset
        while x < rect.width + gap {
            if x >= -gap {
                let tall = index % 10 == 0
                path.move(to: CGPoint(x: x, y: tall ? 0 : 4))
                path.addLine(to: CGPoint(x: x, y: tall ? 21 : 17))
            }
            x += gap
            index += 1
        }
        return path
    }
}

/// The chart's four uprights, as the frame draws them on 296 × 201
private struct FDGrowthUprights: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for x in [43.5, 122.5, 201.5, 280.5] {
            let at = rect.width * x / 296
            path.move(to: CGPoint(x: at, y: 1))
            path.addLine(to: CGPoint(x: at, y: 201))
        }
        return path
    }
}

/// One line of the chart, in the frame's own sweep: slow off the left edge, steep into its end. `start` and `end`
/// are how far down the grid it leaves and arrives, so it moves as the deposit and the time change.
private struct FDGrowthCurve: Shape {
    var start: CGFloat
    var end: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(start, end) }
        set { start = newValue.first; end = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let rise = start - end
        var path = Path()
        path.move(to: CGPoint(x: 0.5, y: start))
        path.addCurve(
            to: CGPoint(x: rect.width * 289.5 / 296, y: end),
            control1: CGPoint(x: rect.width * 72.17 / 296, y: start - rise * 0.0726),
            control2: CGPoint(x: rect.width * 235.1 / 296, y: start - rise * 0.4904)
        )
        return path
    }
}
