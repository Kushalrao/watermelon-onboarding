import SwiftUI

/// The + button's question: how do you feel about the market right now? A black half-circle rises from the bottom
/// and fans open from left to right, drawn like the home widgets: a ring of fine dots on its rim, every dot tied by a
/// thread to a glowing knob, and faint ripples inside. Drag the knob round the arc from Scary, through Confused, to
/// In control; the threads re-fan after it as it goes, and a tick lands each time the feeling changes.
struct MoodDialSheet: View {
    let onClose: () -> Void

    /// 0 = down out of sight, 1 = risen
    @State private var risen: CGFloat = 0
    /// How much of the arc has fanned open, left to right
    @State private var reveal: CGFloat = 0
    /// Where the knob sits: 0 = Scary (left end), 0.5 = Confused (top), 1 = In control (right end)
    @State private var feeling: Double = 0.5
    @State private var lastTick = 12

    enum Mood: String, CaseIterable {
        case scary = "Scary", confused = "Confused", inControl = "In control"
        init(_ feeling: Double) { self = feeling < 1 / 3 ? .scary : feeling < 2 / 3 ? .confused : .inControl }
    }

    private static let dots = 84

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let radius = min(size.width / 2 - 10, 200)
            let hub = CGPoint(x: size.width / 2, y: size.height - 120)
            let knobRadius = radius - 30
            let mood = Mood(feeling)

            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.32 * risen)
                    .ignoresSafeArea()
                    .onTapGesture(perform: close)

                ZStack(alignment: .topLeading) {
                    DomeShape(hub: hub, radius: radius)
                        .fill(Color.black)
                        .shadow(color: Color.black.opacity(0.35), radius: 30, x: 0, y: -6)

                    threads(hub: hub, radius: radius, knobRadius: knobRadius)

                    // Ends and middle of the scale
                    // Ends of the scale sit just under the arc's ends, inside the dome; the middle sits under the
                    // knob's track so the knob never covers it
                    label("Scary", active: mood == .scary)
                        .frame(width: 120, alignment: .leading)
                        .position(x: hub.x - radius + 18 + 60, y: hub.y + 22)
                    label("Confused", active: mood == .confused)
                        .position(x: hub.x, y: hub.y - knobRadius + 34)
                    label("In control", active: mood == .inControl)
                        .frame(width: 120, alignment: .trailing)
                        .position(x: hub.x + radius - 18 - 60, y: hub.y + 22)

                    VStack(spacing: 6) {
                        Text("How do you feel about the market right now?")
                            .font(FigmaFont.walsheim(14))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .frame(width: radius * 1.1)
                        Text(mood.rawValue)
                            .font(FigmaFont.walsheimMedium(30))
                            .foregroundStyle(Color.white)
                            .contentTransition(.interpolate)
                            .animation(.snappy(duration: 0.25), value: mood)
                    }
                    .position(x: hub.x, y: hub.y - radius * 0.3)

                    knob
                        .position(knobPoint(hub: hub, radius: knobRadius))
                        .opacity(Double(min(1, max(0, (reveal - 0.6) / 0.4))))

                    Button(action: close) {
                        Text("Done")
                            .font(FigmaFont.walsheimMedium(16))
                            .foregroundStyle(Color.black)
                            .frame(width: 112, height: 42)
                            .background(Capsule().fill(Color.white))
                    }
                    .buttonStyle(PressScaleStyle())
                    .position(x: hub.x, y: hub.y + 66)
                }
                .contentShape(DomeShape(hub: hub, radius: radius))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in steer(to: drag.location, hub: hub) }
                )
                .offset(y: (1 - risen) * (radius + 220))
            }
        }
        .ignoresSafeArea()
        .onAppear {
            Haptics.lift()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.84)) { risen = 1 }
            withAnimation(.easeOut(duration: 0.9).delay(0.15)) { reveal = 1 }
        }
    }

    // MARK: Pieces

    private func label(_ text: String, active: Bool) -> some View {
        Text(text.uppercased())
            .font(FigmaFont.walsheimMedium(11))
            .tracking(1.2)
            .foregroundStyle(Color.white.opacity(active ? 0.95 : 0.4))
            .fixedSize()
            .animation(.easeOut(duration: 0.2), value: active)
    }

    private var knob: some View {
        ZStack {
            Circle().fill(Color.white).frame(width: 26, height: 26)
            Circle().fill(Color.black).frame(width: 7, height: 7)
        }
        .shadow(color: Color.white.opacity(0.55), radius: 10)
        .shadow(color: Color.white.opacity(0.25), radius: 22)
    }

    private func knobPoint(hub: CGPoint, radius: CGFloat) -> CGPoint {
        let a = Double.pi + feeling * .pi
        return CGPoint(x: hub.x + radius * cos(a), y: hub.y + radius * sin(a))
    }

    /// Rim dots, each tied by a thread to the knob, plus faint ripples inside; it all sways gently
    private func threads(hub: CGPoint, radius: CGFloat, knobRadius: CGFloat) -> some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            Canvas { ctx, _ in
                let open = Double(reveal)
                let knob = knobPoint(hub: hub, radius: knobRadius)
                let rimRadius = radius - 12
                let knobAngle = Double.pi + feeling * .pi

                // Ripples inside the dome, like the sound-wave sphere
                for ring in 0..<5 {
                    let r = Double(radius) * (0.32 + 0.11 * Double(ring))
                    var arc = Path()
                    let steps = 90
                    for k in 0...Int(Double(steps) * open) {
                        let a = Double.pi + Double.pi * Double(k) / Double(steps)
                        let wobble = 2.2 * sin(a * 5 + t * 1.3 + Double(ring)) * sin(a)
                        let p = CGPoint(x: hub.x + (r + wobble) * cos(a), y: hub.y + (r + wobble) * sin(a))
                        if k == 0 { arc.move(to: p) } else { arc.addLine(to: p) }
                    }
                    ctx.stroke(arc, with: .color(Color.white.opacity(0.07)), lineWidth: 0.6)
                }

                var near = Path(), far = Path(), rimDots = Path()
                let shown = Int(Double(Self.dots) * open)
                for i in 0..<max(0, shown) {
                    let a = Double.pi + Double.pi * Double(i) / Double(Self.dots - 1)
                    let dot = CGPoint(x: hub.x + rimRadius * cos(a), y: hub.y + rimRadius * sin(a))
                    rimDots.addEllipse(in: CGRect(x: dot.x - 1.1, y: dot.y - 1.1, width: 2.2, height: 2.2))

                    // Threads bow in towards the hub, swaying a little, and gather at the knob
                    let sway = 0.18 * sin(t * 0.8 + Double(i) * 0.37)
                    let mid = CGPoint(x: (dot.x + knob.x) / 2, y: (dot.y + knob.y) / 2)
                    let pull = 0.42 + sway * 0.3
                    let control = CGPoint(x: mid.x + (hub.x - mid.x) * pull, y: mid.y + (hub.y - mid.y) * pull)
                    var thread = Path()
                    thread.move(to: dot)
                    thread.addQuadCurve(to: knob, control: control)
                    // Threads from dots close to the knob read brighter
                    if abs(a - knobAngle) < 0.6 { near.addPath(thread) } else { far.addPath(thread) }
                }
                ctx.stroke(far, with: .color(Color.white.opacity(0.22)), lineWidth: 0.4)
                ctx.stroke(near, with: .color(Color.white.opacity(0.55)), lineWidth: 0.5)
                ctx.fill(rimDots, with: .color(Color.white.opacity(0.9)))
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: Interaction

    /// Moves the knob to the point on the arc nearest the finger; below the arc it pins to the closer end
    private func steer(to point: CGPoint, hub: CGPoint) {
        let angle = atan2(point.y - hub.y, point.x - hub.x)   // −π…0 across the top
        let value: Double
        if angle <= 0 { value = (Double(angle) + .pi) / .pi } else { value = point.x < hub.x ? 0 : 1 }
        let previous = Mood(feeling)
        feeling = min(1, max(0, value))
        // Light ticks along the scale, a firmer one when the feeling changes
        let tick = Int((feeling * 24).rounded())
        if Mood(feeling) != previous { Haptics.thresholdCrossed() } else if tick != lastTick { Haptics.meterTick(intensity: 0.35) }
        lastTick = tick
    }

    private func close() {
        Haptics.tap()
        withAnimation(.easeIn(duration: 0.22)) { reveal = 0 }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) { risen = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: onClose)
    }
}

/// A half circle standing on its flat edge, with the area below the edge filled down to the bottom of the screen
private struct DomeShape: Shape {
    let hub: CGPoint
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: hub.x - radius, y: rect.maxY + 40))
        path.addLine(to: CGPoint(x: hub.x - radius, y: hub.y))
        path.addArc(center: hub, radius: radius, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        path.addLine(to: CGPoint(x: hub.x + radius, y: rect.maxY + 40))
        path.closeSubpath()
        return path
    }
}
