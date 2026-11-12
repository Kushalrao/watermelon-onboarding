import SwiftUI

/// A skeletonised tourbillon movement, drawn rather than pictured, after the photograph at the top of the analysis
/// (154:6842) without its maker's name: a black case and sunburst dial, two arched steel bridges over a train of
/// meshing gears, a broad ring round the tourbillon, and a steel bar across it. Everything that turns, turns: the
/// gears at speeds set by their teeth, the tourbillon's carriage and cage, and the balance swinging back and forth on
/// its hairspring. A glint travels over the steel, and fine particles drift up through the light around it.
struct MovementWatch: View {
    /// The case's diameter
    var diameter: CGFloat = 240
    /// Room around the case for the particles
    var halo: CGFloat = 60

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let s = diameter / 240
                Particles.draw(in: &ctx, size: size, centre: c, radius: diameter / 2, t: t, behind: true)
                var watch = ctx
                watch.translateBy(x: c.x, y: c.y)
                watch.scaleBy(x: s, y: s)
                Movement.draw(in: &watch, t: t)
                Particles.draw(in: &ctx, size: size, centre: c, radius: diameter / 2, t: t, behind: false)
            }
        }
        .frame(width: diameter + halo * 2, height: diameter + halo * 2)
        .allowsHitTesting(false)
    }
}

// MARK: - The movement, in a 240pt space centred on the case

private enum Movement {
    static let r: CGFloat = 120
    static let dial: CGFloat = 112

    /// Where the tourbillon sits, below centre
    static let tourbillon = CGPoint(x: 0, y: 44)

    static func draw(in ctx: inout GraphicsContext, t: Double) {
        caseAndDial(&ctx)

        var inside = ctx
        inside.clip(to: Path(ellipseIn: CGRect(x: -dial, y: -dial, width: dial * 2, height: dial * 2)))
        lowerRing(&inside)
        gearTrain(&inside, t: t)
        bridges(&inside, t: t)
        tourbillonAssembly(&inside, t: t)
        crossBar(&inside, t: t)
        screws(&inside)

        // A soft fall of light from the upper left, and the crystal's edge
        inside.fill(
            Path(ellipseIn: CGRect(x: -dial, y: -dial, width: dial * 2, height: dial * 2)),
            with: .radialGradient(Gradient(colors: [Color.white.opacity(0.07), .clear]),
                                  center: CGPoint(x: -50, y: -70), startRadius: 0, endRadius: 170)
        )
        ctx.stroke(Path(ellipseIn: CGRect(x: -dial, y: -dial, width: dial * 2, height: dial * 2)),
                   with: .color(.black), lineWidth: 2)
    }

    // MARK: Case

    static func caseAndDial(_ ctx: inout GraphicsContext) {
        let outer = Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2))
        ctx.fill(outer, with: .radialGradient(Gradient(colors: [Color(white: 0.16), Color(white: 0.05)]),
                                             center: CGPoint(x: -30, y: -40), startRadius: 0, endRadius: r * 1.3))
        // The polished rim catches the light at the top left and bottom right
        ctx.stroke(Path(ellipseIn: CGRect(x: -r + 0.75, y: -r + 0.75, width: r * 2 - 1.5, height: r * 2 - 1.5)),
                   with: .conicGradient(Gradient(colors: [
                       Color.white.opacity(0.55), Color.white.opacity(0.08), Color.white.opacity(0.35),
                       Color.white.opacity(0.06), Color.white.opacity(0.55),
                   ]), center: .zero, angle: .degrees(-135)),
                   lineWidth: 1.5)
        // The bezel's groove
        ctx.stroke(Path(ellipseIn: CGRect(x: -r + 5, y: -r + 5, width: r * 2 - 10, height: r * 2 - 10)),
                   with: .color(Color.black.opacity(0.9)), lineWidth: 2.5)

        let face = Path(ellipseIn: CGRect(x: -dial, y: -dial, width: dial * 2, height: dial * 2))
        ctx.fill(face, with: .color(Color(white: 0.045)))
        // Sunburst: fine rays from the centre, alternating in the light
        var rays = ctx
        rays.clip(to: face)
        for i in 0..<240 {
            let a = Double(i) / 240 * .pi * 2
            var ray = Path()
            ray.move(to: .zero)
            ray.addLine(to: CGPoint(x: cos(a) * Double(dial), y: sin(a) * Double(dial)))
            let lit = 0.5 + 0.5 * cos(a * 2 + 0.8)
            rays.stroke(ray, with: .color(Color.white.opacity(0.012 + 0.03 * lit * Double(i % 2))), lineWidth: 0.8)
        }
    }

    // MARK: The broad ring round the tourbillon

    static func lowerRing(_ ctx: inout GraphicsContext) {
        let c = tourbillon
        var ring = Path()
        ring.addEllipse(in: CGRect(x: c.x - 84, y: c.y - 84, width: 168, height: 168))
        ring.addEllipse(in: CGRect(x: c.x - 58, y: c.y - 58, width: 116, height: 116))
        ctx.fill(ring, with: .linearGradient(Gradient(colors: [Color(white: 0.13), Color(white: 0.07)]),
                                            startPoint: CGPoint(x: 0, y: c.y - 84), endPoint: CGPoint(x: 0, y: c.y + 84)),
                 style: FillStyle(eoFill: true))
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 84, y: c.y - 84, width: 168, height: 168)),
                   with: .color(Color.white.opacity(0.14)), lineWidth: 0.8)
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 58, y: c.y - 58, width: 116, height: 116)),
                   with: .color(Color.white.opacity(0.18)), lineWidth: 0.8)
        // A brushed band on its upper face
        var band = ctx
        band.clip(to: ring, style: FillStyle(eoFill: true))
        for k in 0..<14 {
            let rr = 60 + CGFloat(k) * 1.8
            band.stroke(Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2)),
                        with: .color(Color.white.opacity(k % 2 == 0 ? 0.025 : 0.01)), lineWidth: 0.6)
        }
        // Small openings and jewels set into it
        for a in stride(from: 200.0, through: 340.0, by: 28.0) {
            let p = point(c, 71, a)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 2.6, y: p.y - 2.6, width: 5.2, height: 5.2)), with: .color(.black))
            ctx.stroke(Path(ellipseIn: CGRect(x: p.x - 2.6, y: p.y - 2.6, width: 5.2, height: 5.2)),
                       with: .color(Color.white.opacity(0.25)), lineWidth: 0.5)
        }
        // The dark windows either side, where the ring meets the case
        for side: CGFloat in [-1, 1] {
            var w = Path()
            w.move(to: CGPoint(x: side * 96, y: 20))
            w.addLine(to: CGPoint(x: side * 82, y: 24))
            w.addLine(to: CGPoint(x: side * 80, y: 58))
            w.addLine(to: CGPoint(x: side * 92, y: 66))
            w.closeSubpath()
            ctx.fill(w, with: .color(.black))
            ctx.stroke(w, with: .color(Color.white.opacity(0.22)), lineWidth: 0.7)
        }
    }

    // MARK: Gears

    /// The going train under the bridges: centre, radius, teeth; each meshes with the next, so turns the other way
    static let train: [(c: CGPoint, r: CGFloat, teeth: Int)] = [
        (CGPoint(x: -64, y: -14), 17, 30),
        (CGPoint(x: -40, y: -42), 18, 32),
        (CGPoint(x: -9, y: -57), 13, 22),
        (CGPoint(x: 18, y: -40), 18, 32),
        (CGPoint(x: 48, y: -26), 20, 36),
        (CGPoint(x: 64, y: 4), 13, 22),
    ]

    static func gearTrain(_ ctx: inout GraphicsContext, t: Double) {
        // Surface speed is shared along the train
        let surface = 9.0
        for (i, g) in train.enumerated() {
            let dir: Double = i % 2 == 0 ? 1 : -1
            let angle = dir * surface * t / Double(g.r)
            gear(&ctx, centre: g.c, radius: g.r, teeth: g.teeth, angle: angle, shade: 0.62 - Double(i % 3) * 0.06)
        }
    }

    static func gear(_ ctx: inout GraphicsContext, centre c: CGPoint, radius r: CGFloat, teeth: Int, angle: Double,
                     shade: Double, spokes: Int = 4) {
        let depth = max(1.6, r * 0.12)
        var outline = Path()
        let n = teeth * 4
        for k in 0...n {
            let a = angle + Double(k) / Double(n) * .pi * 2
            let phase = k % 4
            let rr = (phase == 1 || phase == 2) ? r : r - depth
            let p = CGPoint(x: c.x + cos(a) * rr, y: c.y + sin(a) * rr)
            k == 0 ? outline.move(to: p) : outline.addLine(to: p)
        }
        outline.closeSubpath()
        ctx.fill(outline, with: .linearGradient(
            Gradient(colors: [Color(white: shade + 0.25), Color(white: shade - 0.2)]),
            startPoint: CGPoint(x: c.x - r, y: c.y - r), endPoint: CGPoint(x: c.x + r, y: c.y + r)))
        ctx.stroke(outline, with: .color(Color.black.opacity(0.55)), lineWidth: 0.5)

        // Windows between the spokes
        let rim = r - depth - max(1.5, r * 0.1)
        var windows = Path(ellipseIn: CGRect(x: c.x - rim, y: c.y - rim, width: rim * 2, height: rim * 2))
        windows.addEllipse(in: CGRect(x: c.x - rim * 0.32, y: c.y - rim * 0.32, width: rim * 0.64, height: rim * 0.64))
        var cut = ctx
        cut.clip(to: windows, style: FillStyle(eoFill: true))
        cut.fill(windows, with: .color(Color(white: 0.03)), style: FillStyle(eoFill: true))
        for k in 0..<spokes {
            let a = angle + Double(k) / Double(spokes) * .pi * 2
            var spoke = Path()
            spoke.move(to: c)
            spoke.addLine(to: CGPoint(x: c.x + cos(a) * rim, y: c.y + sin(a) * rim))
            cut.stroke(spoke, with: .color(Color(white: shade)), lineWidth: max(1.2, r * 0.13))
        }
        // Arbor
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 2, y: c.y - 2, width: 4, height: 4)), with: .color(Color(white: 0.85)))
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 0.9, y: c.y - 0.9, width: 1.8, height: 1.8)), with: .color(Color(white: 0.2)))
    }

    // MARK: Bridges

    /// The two arched steel bridges over the train: an arc's centre, radius and span, in degrees
    static let arches: [(c: CGPoint, r: CGFloat, from: Double, to: Double, width: CGFloat)] = [
        (CGPoint(x: 40, y: 62), 130, 201, 249, 17),
        (CGPoint(x: -26, y: 92), 150, 257, 318, 17),
    ]

    static func bridges(_ ctx: inout GraphicsContext, t: Double) {
        for (i, arch) in arches.enumerated() {
            var spine = Path()
            spine.addArc(center: arch.c, radius: arch.r, startAngle: .degrees(arch.from), endAngle: .degrees(arch.to),
                         clockwise: false)
            let band = spine.strokedPath(StrokeStyle(lineWidth: arch.width, lineCap: .round))

            // A shadow under it, then brushed steel
            var shadow = ctx
            shadow.translateBy(x: 1.5, y: 2.5)
            shadow.fill(band, with: .color(Color.black.opacity(0.7)))
            let mid = point(arch.c, arch.r, (arch.from + arch.to) / 2)
            ctx.fill(band, with: .linearGradient(
                Gradient(colors: [Color(white: 0.88), Color(white: 0.62), Color(white: 0.8), Color(white: 0.5)]),
                startPoint: CGPoint(x: mid.x - 60, y: mid.y - 40), endPoint: CGPoint(x: mid.x + 60, y: mid.y + 40)))
            var brushed = ctx
            brushed.clip(to: band)
            for k in -8...8 {
                var line = Path()
                line.addArc(center: arch.c, radius: arch.r + CGFloat(k) * 1.05, startAngle: .degrees(arch.from - 8),
                            endAngle: .degrees(arch.to + 8), clockwise: false)
                brushed.stroke(line, with: .color(Color(white: k % 2 == 0 ? 1 : 0).opacity(0.06)), lineWidth: 0.5)
            }
            glint(&brushed, around: mid, t: t, offset: Double(i) * 1.7)
            ctx.stroke(band, with: .color(Color.black.opacity(0.6)), lineWidth: 0.6)
            // Bevelled edge on the inner side
            var edge = Path()
            edge.addArc(center: arch.c, radius: arch.r - arch.width / 2 + 0.8, startAngle: .degrees(arch.from),
                        endAngle: .degrees(arch.to), clockwise: false)
            ctx.stroke(edge, with: .color(Color.white.opacity(0.55)), lineWidth: 0.6)

            // Holes, slots and screws along it
            let steps = 7
            for k in 0...steps {
                let a = arch.from + (arch.to - arch.from) * Double(k) / Double(steps)
                let p = point(arch.c, arch.r, a)
                if k == 0 || k == steps {
                    screw(&ctx, at: p, radius: 3.6, slot: a)
                } else if k % 2 == 1 {
                    hole(&ctx, at: p, radius: 2.4)
                } else {
                    var slot = Path()
                    slot.addArc(center: arch.c, radius: arch.r, startAngle: .degrees(a - 3.2),
                                endAngle: .degrees(a + 3.2), clockwise: false)
                    ctx.stroke(slot, with: .color(Color(white: 0.04)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    ctx.stroke(slot, with: .color(Color.white.opacity(0.2)),
                               style: StrokeStyle(lineWidth: 5.6, lineCap: .round, dash: [0.6, 40]))
                }
            }
        }
        // A thin steel lever reaching in from the left, as in the photograph
        var lever = Path()
        lever.move(to: CGPoint(x: -84, y: 18))
        lever.addQuadCurve(to: CGPoint(x: -36, y: -24), control: CGPoint(x: -66, y: -10))
        ctx.stroke(lever, with: .color(Color(white: 0.75)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        screw(&ctx, at: CGPoint(x: -84, y: 18), radius: 3, slot: 30)
    }

    // MARK: Tourbillon

    static func tourbillonAssembly(_ ctx: inout GraphicsContext, t: Double) {
        let c = tourbillon
        // The opening it turns in
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 56, y: c.y - 56, width: 112, height: 112)), with: .color(Color(white: 0.02)))

        // The fixed fourth wheel's teeth round the opening, and the carriage turning inside them, a turn a minute
        let carriage = t / 60 * .pi * 2
        gear(&ctx, centre: c, radius: 38, teeth: 72, angle: carriage, shade: 0.6, spokes: 3)

        // The cage, turning faster than any real one so the eye can follow it
        let cage = t / 9 * .pi * 2
        var frame = Path()
        for k in 0..<3 {
            let a = cage + Double(k) / 3 * .pi * 2
            frame.move(to: c)
            frame.addLine(to: CGPoint(x: c.x + cos(a) * 25, y: c.y + sin(a) * 25))
        }
        ctx.stroke(frame, with: .color(Color(white: 0.8)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        var triangle = Path()
        for k in 0...3 {
            let a = cage + Double(k % 3) / 3 * .pi * 2
            let p = CGPoint(x: c.x + cos(a) * 25, y: c.y + sin(a) * 25)
            k == 0 ? triangle.move(to: p) : triangle.addLine(to: p)
        }
        ctx.stroke(triangle, with: .color(Color(white: 0.55)), lineWidth: 1)
        for k in 0..<3 {
            let a = cage + Double(k) / 3 * .pi * 2
            screw(&ctx, at: CGPoint(x: c.x + cos(a) * 25, y: c.y + sin(a) * 25), radius: 2.6, slot: a * 180 / .pi)
        }
        // The escape wheel riding on the cage
        let escape = CGPoint(x: c.x + cos(cage + 1.05) * 16, y: c.y + sin(cage + 1.05) * 16)
        gear(&ctx, centre: escape, radius: 6, teeth: 15, angle: -t * 2.4, shade: 0.7, spokes: 3)

        // The balance, swinging on its hairspring
        let swing = sin(t * .pi * 2 * 1.25) * 2.2 + cage
        var spring = Path()
        for k in 0...90 {
            let u = Double(k) / 90
            let a = swing * 0.35 + u * .pi * 2 * 3.2
            let rr = 2.5 + u * 8.5
            let p = CGPoint(x: c.x + cos(a) * rr, y: c.y + sin(a) * rr)
            k == 0 ? spring.move(to: p) : spring.addLine(to: p)
        }
        ctx.stroke(spring, with: .color(Color.white.opacity(0.4)), lineWidth: 0.5)
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 15, y: c.y - 15, width: 30, height: 30)),
                   with: .linearGradient(Gradient(colors: [Color(white: 0.95), Color(white: 0.45)]),
                                         startPoint: CGPoint(x: c.x - 15, y: c.y - 15), endPoint: CGPoint(x: c.x + 15, y: c.y + 15)),
                   lineWidth: 2.6)
        for k in 0..<2 {
            let a = swing + Double(k) * .pi
            var arm = Path()
            arm.move(to: CGPoint(x: c.x - cos(a) * 14, y: c.y - sin(a) * 14))
            arm.addLine(to: CGPoint(x: c.x + cos(a) * 14, y: c.y + sin(a) * 14))
            ctx.stroke(arm, with: .color(Color(white: 0.8)), lineWidth: 1.4)
        }
        for k in 0..<6 {
            let a = swing + Double(k) / 6 * .pi * 2
            let p = CGPoint(x: c.x + cos(a) * 15, y: c.y + sin(a) * 15)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - 1.3, y: p.y - 1.3, width: 2.6, height: 2.6)), with: .color(Color(white: 0.95)))
        }
    }

    /// The steel bar across the tourbillon, with its windows, hub and screws
    static func crossBar(_ ctx: inout GraphicsContext, t: Double) {
        let c = tourbillon
        var bar = Path()
        bar.move(to: CGPoint(x: -112, y: 66))
        bar.addQuadCurve(to: CGPoint(x: 112, y: 30), control: CGPoint(x: 0, y: 38))
        let band = bar.strokedPath(StrokeStyle(lineWidth: 11, lineCap: .butt))
        var shadow = ctx
        shadow.translateBy(x: 1.5, y: 3)
        shadow.fill(band, with: .color(Color.black.opacity(0.75)))
        ctx.fill(band, with: .linearGradient(Gradient(colors: [Color(white: 0.9), Color(white: 0.55), Color(white: 0.82)]),
                                            startPoint: CGPoint(x: -100, y: 30), endPoint: CGPoint(x: 100, y: 70)))
        var lit = ctx
        lit.clip(to: band)
        glint(&lit, around: CGPoint(x: 0, y: 45), t: t, offset: 3.1)
        ctx.stroke(band, with: .color(Color.black.opacity(0.6)), lineWidth: 0.6)
        // Windows near each end
        for (x, w) in [(-86.0, 18.0), (-62.0, 12.0), (60.0, 12.0), (84.0, 18.0)] {
            let y = barY(x)
            let rect = CGRect(x: x - w / 2, y: y - 2.6, width: w, height: 5.2)
            var win = ctx
            win.translateBy(x: rect.midX, y: rect.midY)
            win.rotate(by: .radians(barSlope(x)))
            let local = Path(roundedRect: CGRect(x: -w / 2, y: -2.6, width: w, height: 5.2), cornerRadius: 1.2)
            win.fill(local, with: .color(Color(white: 0.05)))
            win.stroke(local, with: .color(Color.white.opacity(0.35)), lineWidth: 0.5)
        }
        for x in [-100.0, -40.0, 40.0, 100.0] { hole(&ctx, at: CGPoint(x: x, y: barY(x)), radius: 1.8) }
        // The hub over the cage's arbor
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 11, y: c.y - 11, width: 22, height: 22)),
                 with: .radialGradient(Gradient(colors: [Color(white: 0.95), Color(white: 0.5)]),
                                       center: CGPoint(x: c.x - 4, y: c.y - 4), startRadius: 0, endRadius: 14))
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 11, y: c.y - 11, width: 22, height: 22)),
                   with: .color(Color.black.opacity(0.5)), lineWidth: 0.6)
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - 6.5, y: c.y - 6.5, width: 13, height: 13)),
                   with: .color(Color.black.opacity(0.35)), lineWidth: 0.6)
        jewel(&ctx, at: c, radius: 2.4)
    }

    static func barY(_ x: Double) -> CGFloat {
        // The quad curve from (-112, 66) through control (0, 38) to (112, 30), by its x
        let u = (x + 112) / 224
        let y = (1 - u) * (1 - u) * 66 + 2 * (1 - u) * u * 38 + u * u * 30
        return CGFloat(y)
    }

    static func barSlope(_ x: Double) -> Double {
        let u = (x + 112) / 224
        let dy = 2 * (1 - u) * (38 - 66) + 2 * u * (30 - 38)
        return atan2(dy, 224)
    }

    static func screws(_ ctx: inout GraphicsContext) {
        for (a, rr) in [(158.0, 100.0), (22.0, 100.0), (-118.0, 96.0), (-30.0, 102.0)] {
            screw(&ctx, at: point(.zero, CGFloat(rr), a), radius: 4.2, slot: a + 40)
        }
    }

    // MARK: Parts

    static func screw(_ ctx: inout GraphicsContext, at p: CGPoint, radius: CGFloat, slot: Double) {
        let rect = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)
        ctx.fill(Path(ellipseIn: rect.offsetBy(dx: 0.5, dy: 0.8)), with: .color(Color.black.opacity(0.7)))
        ctx.fill(Path(ellipseIn: rect), with: .radialGradient(Gradient(colors: [Color(white: 0.98), Color(white: 0.45)]),
                                                             center: CGPoint(x: p.x - radius * 0.4, y: p.y - radius * 0.4),
                                                             startRadius: 0, endRadius: radius * 1.6))
        var line = Path()
        let a = slot * .pi / 180
        line.move(to: CGPoint(x: p.x - cos(a) * radius * 0.8, y: p.y - sin(a) * radius * 0.8))
        line.addLine(to: CGPoint(x: p.x + cos(a) * radius * 0.8, y: p.y + sin(a) * radius * 0.8))
        ctx.stroke(line, with: .color(Color(white: 0.15)), lineWidth: max(0.6, radius * 0.28))
    }

    static func hole(_ ctx: inout GraphicsContext, at p: CGPoint, radius: CGFloat) {
        let rect = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)
        ctx.fill(Path(ellipseIn: rect), with: .color(Color(white: 0.04)))
        ctx.stroke(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.45)), lineWidth: 0.5)
    }

    static func jewel(_ ctx: inout GraphicsContext, at p: CGPoint, radius: CGFloat) {
        let rect = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)
        ctx.fill(Path(ellipseIn: rect), with: .radialGradient(Gradient(colors: [Color(red: 0.75, green: 0.25, blue: 0.35),
                                                                               Color(red: 0.25, green: 0.03, blue: 0.08)]),
                                                             center: CGPoint(x: p.x - radius * 0.3, y: p.y - radius * 0.3),
                                                             startRadius: 0, endRadius: radius * 1.4))
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - radius * 0.45, y: p.y - radius * 0.55, width: radius * 0.5, height: radius * 0.4)),
                 with: .color(Color.white.opacity(0.7)))
    }

    /// A band of light sliding slowly across polished steel
    static func glint(_ ctx: inout GraphicsContext, around c: CGPoint, t: Double, offset: Double) {
        let travel = sin(t * 0.55 + offset) * 90
        let x = c.x + travel
        ctx.fill(Path(CGRect(x: c.x - 160, y: c.y - 160, width: 320, height: 320)),
                 with: .linearGradient(Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Color.white.opacity(0.5), location: 0.5),
                    .init(color: .clear, location: 1),
                 ]), startPoint: CGPoint(x: x - 18, y: c.y - 30), endPoint: CGPoint(x: x + 18, y: c.y + 30)))
    }

    static func point(_ c: CGPoint, _ r: CGFloat, _ degrees: Double) -> CGPoint {
        let a = degrees * .pi / 180
        return CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
    }
}

// MARK: - Particles

/// Fine motes of light drifting up past the watch, some behind it and some in front, each twinkling on its own beat
private enum Particles {
    struct Mote {
        let x: Double, y: Double, speed: Double, sway: Double, phase: Double, size: Double, front: Bool
    }

    static let motes: [Mote] = {
        var generator = SeededGenerator(seed: 7)
        return (0..<90).map { i in
            Mote(x: Double.random(in: 0...1, using: &generator),
                 y: Double.random(in: 0...1, using: &generator),
                 speed: Double.random(in: 0.012...0.04, using: &generator),
                 sway: Double.random(in: 4...14, using: &generator),
                 phase: Double.random(in: 0...(2 * .pi), using: &generator),
                 size: Double.random(in: 0.5...1.9, using: &generator),
                 front: i % 3 == 0)
        }
    }()

    static func draw(in ctx: inout GraphicsContext, size: CGSize, centre: CGPoint, radius: CGFloat, t: Double, behind: Bool) {
        for m in motes where m.front != behind {
            let y = (m.y - t * m.speed).truncatingRemainder(dividingBy: 1)
            let yy = (y < 0 ? y + 1 : y) * size.height
            let xx = m.x * size.width + sin(t * 0.6 + m.phase) * m.sway
            let p = CGPoint(x: xx, y: yy)
            // Brighter near the case's edge, where the light is
            let d = hypot(p.x - centre.x, p.y - centre.y)
            let nearEdge = max(0, 1 - abs(d - radius) / (radius * 0.6))
            // Those in front only show outside the case, so they never cover the movement's face
            if !behind && d < radius { continue }
            let twinkle = 0.5 + 0.5 * sin(t * (1.2 + m.speed * 40) + m.phase)
            let alpha = (0.12 + 0.55 * nearEdge) * twinkle
            let s = m.size * (behind ? 1 : 1.25)
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - s / 2, y: p.y - s / 2, width: s, height: s)),
                     with: .color(Color.white.opacity(alpha)))
            if m.size > 1.6 && twinkle > 0.85 {
                // A little star on the brightest
                var star = Path()
                star.move(to: CGPoint(x: p.x - s * 2.4, y: p.y)); star.addLine(to: CGPoint(x: p.x + s * 2.4, y: p.y))
                star.move(to: CGPoint(x: p.x, y: p.y - s * 2.4)); star.addLine(to: CGPoint(x: p.x, y: p.y + s * 2.4))
                ctx.stroke(star, with: .color(Color.white.opacity(alpha * 0.6)), lineWidth: 0.4)
            }
        }
    }
}

/// Repeatable randomness, so the particles sit the same way every time
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 | 1 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

#Preview {
    MovementWatch()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
