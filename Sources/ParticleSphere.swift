import SwiftUI

/// A sphere of loose white particles on black (Figma 44:2367), turning steadily about its upright axis. Points sit
/// on and just under the surface; more of them gather towards the poles, so the top and bottom caps glow brighter,
/// and the far side shows through dimmer. Drawn to fill its frame: the sphere's diameter is the shorter side.
struct ParticleSphere: View {
    var ink: Color = .white
    /// Radians per second about the upright axis
    var spin: Double = 0.32

    struct Particle {
        let x, y, z: Double
        let size: Double
        /// 0…3, dim to bright
        let tone: Int
    }

    static let particles: [Particle] = {
        var random = SeededRandom(state: 0x5EED_5F4E)
        return (0..<12000).map { i in
            let u = 2 * .pi * random.next()
            // Under half spread evenly over the surface; the rest crowd into bands round the poles, which is what
            // gives the top and bottom their glow
            let y: Double
            if i % 20 < 7 {
                y = 1 - 2 * random.next()
            } else {
                let fromPole = 0.5 * pow(random.next(), 1.8)
                y = (random.next() < 0.5 ? 1 : -1) * (1 - fromPole)
            }
            let ring = (1 - y * y).squareRoot()
            // A little either side of the surface, so the rim reads soft
            let depth = 1 + 0.045 * (random.next() + random.next() - 1)
            let size = 0.5 + 0.8 * pow(random.next(), 2.5)
            // Brighter towards the poles, dimmer across the middle
            let lift = abs(y) * 1.6 + random.next() * 2.2
            let tone = min(3, Int(lift))
            return Particle(x: depth * ring * cos(u), y: depth * y, z: depth * ring * sin(u), size: size, tone: tone)
        }
    }()

    static let toneOpacity: [Double] = [0.3, 0.52, 0.76, 0.98]
    /// Seen from a touch above, so the top cap sits just inside the rim
    static let tilt = 0.22

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            Canvas(rendersAsynchronously: true) { ctx, size in
                let radius = min(size.width, size.height) / 2
                let centre = CGPoint(x: size.width / 2, y: size.height / 2)
                let (cs, ss) = (cos(t * spin), sin(t * spin))
                let (ct, st) = (cos(Self.tilt), sin(Self.tilt))
                var front = [Path](repeating: Path(), count: 4)
                var back = [Path](repeating: Path(), count: 4)
                for p in Self.particles {
                    let x1 = p.x * cs + p.z * ss, z1 = -p.x * ss + p.z * cs
                    let y2 = p.y * ct - z1 * st, z2 = p.y * st + z1 * ct
                    let s = p.size
                    let dot = CGRect(x: centre.x + radius * x1 - s / 2, y: centre.y - radius * y2 - s / 2, width: s, height: s)
                    if z2 >= 0 { front[p.tone].addEllipse(in: dot) } else { back[p.tone].addEllipse(in: dot) }
                }
                for tone in 0..<4 {
                    ctx.fill(back[tone], with: .color(ink.opacity(Self.toneOpacity[tone] * 0.6)))
                }
                for tone in 0..<4 {
                    ctx.fill(front[tone], with: .color(ink.opacity(Self.toneOpacity[tone])))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Sphere to card

/// The identity card's reveal, after Apple Card's: the particle sphere turns for a few seconds, then swells past the
/// card's edges and flattens into an even field of dots covering it, top rows first. Right behind that, a front runs
/// down the card: where it passes, each dot settles into the surface and the white card beneath shows through in
/// little growing squares, until the whole card is there. It's one wave from top to bottom, so nothing ever holds
/// still between the flattening and the reveal.
///
/// Times are seconds after `start`, when the sphere card landed. Drawn in the card's 364 × 255 space.
struct SphereToCardReveal: View {
    let start: Date
    private let card: AnyView

    init<Card: View>(start: Date, @ViewBuilder card: () -> Card) {
        self.start = start
        self.card = AnyView(card())
    }

    static var growAt: Double { 5.0 }
    private static let growFor = 1.0
    private static let flattenAt = 5.2
    private static let flattenFor = 1.0
    /// The bottom rows land this much later than the top ones
    private static let flattenStagger = 0.55
    /// Picks up just as the top rows land, so the flattening runs straight on into the reveal
    private static let revealAt = 6.05
    private static let revealFor = 2.4 / 1.7
    /// When the card is fully there
    static var endsAt: Double { revealAt + revealFor + 0.1 }

    private static let size = CGSize(width: 364, height: 255)
    static let backdrop = Color(hex: 0xFFC489)
    private static let sphereCentre = CGPoint(x: 179, y: 122)
    private static let sphereRadius = 93.0
    /// How ragged the reveal front is, in points
    private static let frontScatter = 30.0
    private static let frontSoftness = 18.0

    /// Each particle's place in the flat field: most on a fine grid, the rest scattered between
    private static let targets: [(point: CGPoint, lag: Double)] = {
        var random = SeededRandom(state: 0xCA4D_F1E1)
        let spacing = 3.5
        let cols = Int(size.width / spacing), rows = Int(size.height / spacing)
        let cells = cols * rows
        return ParticleSphere.particles.indices.map { i in
            let point: CGPoint
            if i < cells {
                let cell = (i &* 7919) % cells
                point = CGPoint(x: (Double(cell % cols) + 0.5) * spacing + (random.next() - 0.5) * 0.8,
                                y: (Double(cell / cols) + 0.5) * spacing + (random.next() - 0.5) * 0.8)
            } else {
                point = CGPoint(x: random.next() * size.width, y: random.next() * size.height)
            }
            return (point, random.next())
        }
    }()

    /// The same raggedness for the squares of card showing through
    private static let maskCell = 5.0
    private static let maskLag: [Double] = {
        var random = SeededRandom(state: 0x5AD_C0DE)
        let count = Int(size.width / maskCell + 1) * Int(size.height / maskCell + 1)
        return (0..<count).map { _ in random.next() }
    }()

    var body: some View {
        TimelineView(.animation) { context in
            let e = context.date.timeIntervalSince(start)
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            let front = Self.front(e)
            ZStack(alignment: .topLeading) {
                // Peach behind the sphere (243:13840)
                Self.backdrop
                if e > Self.revealAt {
                    card
                        .mask(Canvas { ctx, _ in Self.drawMask(in: &ctx, front: front) })
                }
                Canvas(rendersAsynchronously: true) { ctx, _ in
                    Self.drawParticles(in: &ctx, e: e, t: t, front: front)
                }
            }
            .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        }
        .task { await playSweepHaptics() }
    }

    /// A fine run of soft ticks while the front sweeps down, one for each band of the card it crosses, so they come
    /// quick at first and space out as it slows; then one firmer tap once the card is all there
    private func playSweepHaptics() async {
        let band = 9.0
        var lastBand = -1
        var random = SeededRandom(state: 0xB0B)
        Haptics.prepare()
        while !Task.isCancelled {
            let e = Date().timeIntervalSince(start)
            if e >= Self.endsAt - 0.1 {
                if lastBand >= 0 { Haptics.revealSettled() }
                return
            }
            let front = Self.front(e)
            if front >= 0, front <= Self.size.height {
                let current = Int(front / band)
                if current > lastBand {
                    lastBand = current
                    // A little uneven, like grain, and lighter towards the bottom as it slows
                    let fade = 1 - 0.4 * front / Self.size.height
                    Haptics.revealGrain(intensity: (0.32 + 0.18 * random.next()) * fade)
                }
            }
            try? await Task.sleep(for: .milliseconds(8))
        }
    }

    /// Where the swell under the reveal sits on the card, and how raised it is: it rises as the front sets off,
    /// rides along just behind the edge of what's revealed, and sinks back as it reaches the bottom
    static func bump(_ e: Double) -> (y: Double, strength: Double) {
        let p = (e - revealAt) / revealFor
        guard p > 0, p < 1 else { return (0, 0) }
        let rise = ease(p / 0.18)
        let sink = ease((1 - p) / 0.3)
        return (front(e) - frontScatter * 0.6, rise * sink)
    }

    /// The reveal front's height on the card: from above the top edge to past the bottom
    private static func front(_ e: Double) -> Double {
        let p = max(0, min(1, (e - revealAt) / revealFor))
        // Already moving when it starts (it picks up the flattening's motion), easing only into the bottom edge
        let eased = 1 - (1 - p) * (1 - p)
        return -frontScatter - frontSoftness + eased * (size.height + 2 * (frontScatter + frontSoftness))
    }

    /// How far past a point the front has gone, 0…1
    private static func passed(_ y: Double, lag: Double, front: Double) -> Double {
        max(0, min(1, (front - y - lag * frontScatter) / frontSoftness))
    }

    private static func ease(_ x: Double) -> Double {
        let p = max(0, min(1, x))
        return p * p * (3 - 2 * p)
    }

    private static func drawMask(in ctx: inout GraphicsContext, front: Double) {
        let cols = Int(size.width / maskCell + 1), rows = Int(size.height / maskCell + 1)
        var shown = Path()
        for row in 0..<rows {
            let y = Double(row) * maskCell
            // Rows well behind the front are simply there
            if y + maskCell < front - frontScatter - frontSoftness {
                shown.addRect(CGRect(x: 0, y: y, width: size.width, height: maskCell))
                continue
            }
            if y > front { break }
            for col in 0..<cols {
                let amount = passed(y + maskCell / 2, lag: maskLag[row * cols + col], front: front)
                guard amount > 0 else { continue }
                let side = maskCell * min(1.0, amount * 1.15)
                let x = Double(col) * maskCell
                shown.addRect(CGRect(x: x + (maskCell - side) / 2, y: y + (maskCell - side) / 2, width: side, height: side))
            }
        }
        ctx.fill(shown, with: .color(.black))
    }

    private static func drawParticles(in ctx: inout GraphicsContext, e: Double, t: Double, front: Double) {
        let grow = ease((e - growAt) / growFor)
        // Swells well past the card's edges as it flattens, spinning up a little as it goes
        let radius = sphereRadius * (1 + 0.6 * grow)
        let centre = CGPoint(x: sphereCentre.x + (size.width / 2 - sphereCentre.x) * grow,
                             y: sphereCentre.y + (size.height / 2 - sphereCentre.y) * grow)
        let angle = t * 0.32 + 1.4 * grow * grow
        let (cs, ss) = (cos(angle), sin(angle))
        let (ct, st) = (cos(ParticleSphere.tilt), sin(ParticleSphere.tilt))

        // Eight brightness levels, so each dot can fade on its own and still be drawn in a few batches
        let levels = 8
        var paths = [Path](repeating: Path(), count: levels)
        for (i, p) in ParticleSphere.particles.enumerated() {
            let target = targets[i]
            let gone = passed(target.point.y, lag: target.lag, front: front)
            if gone >= 1 { continue }

            let x1 = p.x * cs + p.z * ss, z1 = -p.x * ss + p.z * cs
            let y2 = p.y * ct - z1 * st, z2 = p.y * st + z1 * ct
            let sx = centre.x + radius * x1, sy = centre.y - radius * y2
            // Lands top rows first, as a wave the reveal follows down
            let flat = ease((e - flattenAt - flattenStagger * target.point.y / size.height) / flattenFor)
            let x = sx + (target.point.x - sx) * flat
            let y = sy + (target.point.y - sy) * flat

            // Dim far-side points brighten as the sphere flattens, so the field reads dense and even
            var alpha = ParticleSphere.toneOpacity[p.tone]
            if z2 < 0 { alpha *= 0.6 + 0.4 * flat }
            alpha += (0.62 + 0.12 * Double(p.tone) - alpha) * flat
            // Once flat, the field twinkles faintly
            alpha *= 1 - 0.3 * flat * (0.5 + 0.5 * sin(t * 3.1 + Double(i) * 1.7))
            alpha *= 1 - gone
            let level = Int(alpha * Double(levels))
            guard level > 0 else { continue }

            let s = p.size + (1.55 - p.size) * flat
            paths[min(levels - 1, level)].addEllipse(in: CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s))
        }
        for level in 1..<levels {
            ctx.fill(paths[level], with: .color(.white.opacity(Double(level) / Double(levels - 1))))
        }
    }
}

#Preview {
    ParticleSphere()
        .frame(width: 186, height: 186)
        .padding(60)
        .background(Color.black)
}
