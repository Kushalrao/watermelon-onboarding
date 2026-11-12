import SwiftUI

/// A black horse silhouette, puppeted like LoveFrom's bear: the barrel, neck + head, tail and four jointed
/// legs are separate shapes posed every frame. On `start` it walks in from the left with a four-beat walk
/// (left hind, left fore, right hind, right fore), shortening its stride as it slows, squares up, and then
/// stands with a tail swish, a breath in the neck and the odd ear flick.
///
/// The gait is built from the hooves up: a hoof in stance stays planted on the ground while the body passes
/// over it, then breaks over at the toe, folds and swings forward in an arc to land ahead. The knee, hock and
/// fetlock positions are solved from the hoof position (two-bone IK), so the joints bend the way a horse's do.
struct WalkingHorse: View {
    /// Flip to true to start the walk
    let start: Bool
    /// How far it walks (pt): it enters this far to the left of where it is placed
    var distance: CGFloat = 160
    var duration: Double = 5.6

    static let size = CGSize(width: 132, height: 104)
    /// Extra room around the 132 × 104 horse so a rear (front end up, head high) isn't clipped
    private static let margin = CGSize(width: 16, height: 60)

    @State private var startDate: Date?
    /// When the horse was last tapped (it rears up and comes back down)
    @State private var rearDate: Date?
    /// When the horse was swiped right (it bolts off the right edge, then walks back in from the left)
    @State private var dashDate: Date?
    /// Where it was when it bolted
    @State private var dashFrom: Double = 0

    var body: some View {
        TimelineView(.animation(paused: isStill)) { context in
            let t = startDate.map { context.date.timeIntervalSince($0) } ?? 0
            let rearTime = rearDate.map { context.date.timeIntervalSince($0) }
            let pose = dashDate.map { HorsePose(dashTime: context.date.timeIntervalSince($0), from: dashFrom) }
                ?? HorsePose(time: t, duration: duration, distance: Double(distance), started: startDate != nil, rearTime: rearTime)

            Canvas { ctx, _ in
                ctx.translateBy(x: Self.margin.width, y: Self.margin.height)
                HorseDrawing.draw(pose, in: &ctx)
            }
            .frame(width: Self.size.width + Self.margin.width * 2, height: Self.size.height + Self.margin.height)
            .contentShape(Rectangle().inset(by: 12))
            .onTapGesture(perform: rear)
            // Simultaneous, so a vertical drag on the horse still scrolls the page
            .simultaneousGesture(
                DragGesture(minimumDistance: 14).onEnded { drag in
                    let dx = drag.translation.width, dy = drag.translation.height
                    if dx > 36, dx > abs(dy) * 1.2 { dash(from: pose.x) }
                }
            )
            .offset(x: CGFloat(pose.x) - Self.margin.width, y: -Self.margin.height)
        }
        .frame(width: Self.size.width, height: Self.size.height, alignment: .topLeading)
        .onChange(of: start, initial: true) { _, go in
            if go, startDate == nil { startDate = Date() }
        }
    }

    /// Nothing moving any more: stop redrawing
    private var isStill: Bool {
        if dashDate != nil { return false }
        guard let startDate else { return true }
        let lastMove = max(startDate.addingTimeInterval(duration), rearDate?.addingTimeInterval(HorsePose.rearLength) ?? .distantPast)
        return Date().timeIntervalSince(lastMove) > 14
    }

    /// Tap: once it has stopped walking, the horse rears up with its head high and drops back down
    private func rear() {
        guard let startDate, Date().timeIntervalSince(startDate) > duration + 0.4 else { return }
        if let rearDate, Date().timeIntervalSince(rearDate) < HorsePose.rearLength { return }
        rearDate = Date()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { Haptics.collapse() }        // push off
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) { Haptics.thresholdCrossed() } // fore hooves land
    }

    /// Swipe right: it squats, bolts off the right edge at a gallop, and a moment later walks back in from the left
    private func dash(from x: Double) {
        guard startDate != nil, dashDate == nil else { return }
        dashFrom = x
        dashDate = Date()
        rearDate = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + HorsePose.dashCrouch) { Haptics.collapse() }   // launch
        DispatchQueue.main.asyncAfter(deadline: .now() + HorsePose.dashLength(from: x) + 0.5) {
            dashDate = nil
            startDate = Date()
        }
    }
}

// MARK: - Gait

/// Where one hoof is relative to its resting spot under the body, and how the pastern is tilted
struct HoofPose {
    var dx: Double          // + forward
    var lift: Double        // + up
    var pastern: Double     // degrees from vertical; + slopes forward (standing ≈ 35°), − folds back
}

private struct HorsePose {
    var x: Double
    var stride: Double      // 0…1 how much of a full walk the legs are doing
    var hooves: [HoofPose]  // LH, LF, RH, RF
    var bob: Double         // body drop, pt
    var pitch: Double       // body rock, degrees (+ = croup up)
    var nod: Double         // neck, degrees (+ = head lower)
    var tail: Double        // degrees (+ = swung back / out)
    var ear: Double         // degrees (+ = flicked back)
    var rear: Double = 0    // degrees the body tips back about the hind hooves (front end up)
    var hop: Double = 0     // pt the whole horse leaves the ground
    var tuck: Double = 0    // 0…1 how far the forelegs are folded up under the chest
    var bend: Double = 0    // degrees the spine curves, lifting the front half more than the back

    /// How long a rear takes, tap to settled
    static let rearLength = 2.1

    /// Footfall order of the walk: left hind, left fore, right hind, right fore, a quarter-cycle apart
    static let offsets: [Double] = [0, 0.25, 0.5, 0.75]
    static let isHind = [true, false, true, false]
    /// Share of the cycle each hoof is on the ground (a walk always has two or three feet down)
    static let stance = 0.64
    /// Ground covered per full cycle at walking speed
    static let fullStride = 44.0

    init(time t: Double, duration: Double, distance: Double, started: Bool, rearTime: Double?) {
        self.init(time: t, duration: duration, distance: distance, started: started)
        guard let r = rearTime, r < Self.rearLength else { return }

        // Every part follows its own smooth curve through these moments, so nothing starts or stops dead:
        //   0.00 still · 0.20 gathers (front dips, haunches sink, head down) · 0.48 pushing up, forelegs folding
        //   0.75 top · 1.00 still up, pawing · 1.25 coming down · 1.48 forehand lands · 1.70 rebound · 2.10 still
        let r0 = Self.rearTimes
        self.rear = Self.track(r0, [0, -2.5, 17, 25, 23.5, 13, 0.5, -1.2, 0], at: r)
        self.bend = Self.track(r0, [0, -1.5, 8, 13, 12, 6, -0.5, -1, 0], at: r)
        self.hop = Self.track(r0, [0, 0, 4.5, 1.5, 0, 0, 0, 0, 0], at: r)
        let paw = r > 0.75 && r < 1.15 ? 0.12 * sin((r - 0.75) / 0.4 * .pi * 2) : 0
        self.tuck = min(1, max(0, Self.track(r0, [0, 0, 0.75, 1, 0.92, 0.55, 0.05, 0, 0], at: r) + paw))
        // Haunches sink as they take the weight, then the forehand jolts on landing
        self.bob += Self.track(r0, [0, 2.2, 3.2, 2.6, 2.6, 1.6, 2.4, 0.4, 0], at: r)
        // The head trails the body: it drops to gather, then swings up a beat after the front end rises
        self.nod += Self.track(r0, [0, 7, -6, -19, -21, -12, 4, 3, 0], at: r)
        self.tail += Self.track(r0, [0, 3, 12, 20, 19, 11, 3, 1, 0], at: r)
        self.ear *= max(0, 1 - Self.track(r0, [0, 1, 1, 1, 1, 1, 1, 0.5, 0], at: r))   // pricked forward
    }

    /// Bolt: a squat, a few short driving strides that lengthen and quicken into a gallop, then off the right edge.
    /// Travel comes from the legs (each cycle carries the body one stride length), so planted hooves never slide.
    static let dashCrouch = 0.16
    /// Far enough right (from its resting spot) that the whole horse has left a 390pt-wide screen
    static let dashExit = 440.0
    /// Seconds of running it takes to build from a standstill to a full gallop
    static let dashBuild = 0.75

    /// 0 → 1 over the build-up, eased
    private static func build(_ run: Double) -> Double {
        let u = min(1, max(0, run / dashBuild))
        return u * u * (3 - 2 * u)
    }
    /// Strides per second and ground covered per stride, from first push-off to full gallop
    private static func dashRate(_ run: Double) -> Double { 1.5 + 2.6 * build(run) }
    private static func dashStride(_ run: Double) -> Double { 24 + 66 * build(run) }

    /// Gallop cycles run and distance covered after `run` seconds of running
    private static func dashProgress(_ run: Double) -> (cycle: Double, travelled: Double) {
        guard run > 0 else { return (0, 0) }
        let steps = 80, dt = run / Double(steps)
        var cycle = 0.0, travelled = 0.0
        for i in 0..<steps {
            let m = (Double(i) + 0.5) * dt
            cycle += dashRate(m) * dt
            travelled += dashRate(m) * dashStride(m) * dt
        }
        return (cycle, travelled)
    }

    /// Whole bolt, squat to gone, when it starts from `x0`
    static func dashLength(from x0: Double) -> Double {
        var run = 0.0
        while dashProgress(run).travelled < dashExit - x0, run < 6 { run += 0.02 }
        return dashCrouch + run
    }

    init(dashTime t: Double, from x0: Double) {
        let still = Array(repeating: HoofPose(dx: 0, lift: 0, pastern: 35), count: 4)
        if t < Self.dashCrouch {
            // Sits back on its haunches, head down, ears pinned, about to spring
            let c = sin(t / Self.dashCrouch * .pi / 2)
            self.init(x: x0, stride: 0, hooves: still, bob: 3 * c, pitch: -3.5 * c, nod: 7 * c, tail: 8 * c, ear: 26 * c)
            return
        }
        let run = t - Self.dashCrouch
        let (cycleRun, travelled) = Self.dashProgress(run)
        let into = Self.build(run)
        // Start each leg just ahead of lift-off so the very first thing is the hinds driving and the fores reaching
        let cycle = cycleRun + 0.3
        // Transverse gallop: hinds land together, then the fores; each foot down for a shorter share as it speeds up
        let gallopOffsets = [0.0, 0.42, 0.1, 0.52]   // LH, LF, RH, RF
        let stance = 0.55 - 0.17 * into
        let L = Self.dashStride(run)
        let hooves = (0..<4).map { leg -> HoofPose in
            let s = (cycle + gallopOffsets[leg]).truncatingRemainder(dividingBy: 1)
            return Self.hoof(at: s, strideLength: L, hind: Self.isHind[leg], lift: 0.9 + 0.7 * into, stance: stance)
        }
        let gait = 2 * .pi * cycle
        // Moment of suspension once galloping: all four feet off after the leading fore pushes away
        let s = cycle.truncatingRemainder(dividingBy: 1)
        let flight = s > 0.9 ? sin((s - 0.9) / 0.1 * .pi) : 0
        // The first push lifts the forehand a little, then it levels out and stretches
        let launch = max(0, 1 - run / 0.35)
        self.init(
            x: x0 + travelled,
            stride: 1,
            hooves: hooves,
            bob: 3 * launch + (0.8 + 1.8 * into) * sin(gait),
            pitch: (1.5 + 3 * into) * sin(gait + 0.9),
            nod: 7 * launch + (1 - launch) * (3 + (3 + 4 * into) * sin(gait + 1.6)),
            tail: 8 + 22 * into,
            ear: 26
        )
        self.rear = 6 * sin(min(1, run / 0.35) * .pi)
        self.hop = 3 * into * flight
    }

    static let rearTimes: [Double] = [0, 0.2, 0.48, 0.75, 1.0, 1.25, 1.48, 1.7, 2.1]

    /// Smooth curve (cubic Hermite, Catmull-Rom tangents) through `values` at `times`
    static func track(_ times: [Double], _ values: [Double], at x: Double) -> Double {
        guard x > times[0] else { return values[0] }
        guard x < times[times.count - 1] else { return values[values.count - 1] }
        var i = 0
        while times[i + 1] < x { i += 1 }
        let t0 = times[i], t1 = times[i + 1], v0 = values[i], v1 = values[i + 1]
        func slope(_ k: Int) -> Double {
            // Flat at the ends; elsewhere the average slope of the neighbours
            guard k > 0, k < times.count - 1 else { return 0 }
            return (values[k + 1] - values[k - 1]) / (times[k + 1] - times[k - 1])
        }
        let h = t1 - t0, u = (x - t0) / h
        let u2 = u * u, u3 = u2 * u
        return (2 * u3 - 3 * u2 + 1) * v0 + (u3 - 2 * u2 + u) * h * slope(i)
             + (-2 * u3 + 3 * u2) * v1 + (u3 - u2) * h * slope(i + 1)
    }

    init(time t: Double, duration: Double, distance: Double, started: Bool) {
        guard started else {
            self.init(x: -distance, stride: 0, hooves: Array(repeating: HoofPose(dx: 0, lift: 0, pastern: 35), count: 4),
                      bob: 0, pitch: 0, nod: 0, tail: 0, ear: 0)
            return
        }

        // Travel: arrives already walking and eases to a halt (quarter sine), so speed falls off as cos
        let u = min(max(t / duration, 0), 1)
        let travelled = distance * sin(u * .pi / 2)
        let topSpeed = distance * .pi / (2 * duration)
        func speed(_ time: Double) -> Double { time >= duration ? 0 : topSpeed * cos(time / duration * .pi / 2) }
        // Strides shorten as it slows (a horse doesn't keep reaching long when pulling up)
        func strideLength(_ time: Double) -> Double { Self.fullStride * (0.4 + 0.6 * min(1, speed(time) / topSpeed)) }

        // Gait cycles walked so far = ∫ speed / strideLength
        let steps = 90
        let end = min(t, duration)
        var cycle = 0.0
        if end > 0 {
            let dt = end / Double(steps)
            for i in 0..<steps {
                let m = (Double(i) + 0.5) * dt
                cycle += speed(m) / strideLength(m) * dt
            }
        }
        let L = strideLength(end)
        let stride = min(1, speed(end) / topSpeed * 1.3 + (t < duration ? 0.25 : 0))

        // After the halt, any hoof still off its spot steps back under the body
        let rest = max(0, t - duration)
        let square = min(1, rest / 0.55)
        let settle = square * square * (3 - 2 * square)

        var hooves: [HoofPose] = []
        var foreImpact = 0.0, hindImpact = 0.0
        for leg in 0..<4 {
            let hind = Self.isHind[leg]
            let s = (cycle + Self.offsets[leg]).truncatingRemainder(dividingBy: 1)
            var hoof = Self.hoof(at: s, strideLength: L, hind: hind, lift: max(stride, 0.45))
            hoof.dx *= 1 - settle
            hoof.lift *= 1 - settle
            hoof.pastern += (35 - hoof.pastern) * settle
            hooves.append(hoof)
            // Weight landing on this hoof: a quick jolt that fades through the first part of stance
            let impact = s < 0.06 ? s / 0.06 : max(0, 1 - (s - 0.06) / 0.28)
            if hind { hindImpact += impact } else { foreImpact += impact }
        }

        let gait = 2 * .pi * cycle
        let walking = (1 - settle)
        // Standing: slow tail swish, a breath in the neck, an ear flick every few seconds
        let restIn = min(1, rest / 1.0)
        let flickPhase = rest.truncatingRemainder(dividingBy: 3.6)
        let restFlick = rest > 0.9 && flickPhase < 0.3 ? sin(flickPhase / 0.3 * .pi) : 0
        // While walking the ear also flicks now and then, off the beat
        let walkFlickPhase = (cycle / 2.7).truncatingRemainder(dividingBy: 1)
        let walkFlick = walkFlickPhase > 0.6 && walkFlickPhase < 0.68 ? sin((walkFlickPhase - 0.6) / 0.08 * .pi) : 0

        self.init(
            x: travelled - distance,
            stride: stride,
            hooves: hooves,
            bob: walking * stride * (1.5 * hindImpact + 0.7 * foreImpact - 0.9),
            pitch: walking * stride * 1.1 * sin(gait + 0.4),
            nod: walking * stride * (7 * foreImpact - 2.5) + restIn * (2 + 1.4 * sin(rest * 1.6)),
            tail: walking * stride * 7 * sin(gait - 1.1) + restIn * 12 * sin(rest * 1.15),
            ear: 26 * max(restFlick, walking * walkFlick)
        )
    }

    init(x: Double, stride: Double, hooves: [HoofPose], bob: Double, pitch: Double, nod: Double, tail: Double, ear: Double) {
        self.x = x; self.stride = stride; self.hooves = hooves; self.bob = bob
        self.pitch = pitch; self.nod = nod; self.tail = tail; self.ear = ear
    }

    /// Hoof position for a moment `s` (0…1) of its cycle
    static func hoof(at s: Double, strideLength L: Double, hind: Bool, lift: Double, stance: Double = HorsePose.stance) -> HoofPose {
        if s < stance {
            // Planted: the body travels over it, so relative to the body it slides back exactly as far
            let dx = L * (stance / 2 - s)
            // Breakover: the heel rises and the pastern tips forward over the toe just before lift-off
            let breakover = max(0, (s - (stance - 0.12)) / 0.12)
            return HoofPose(dx: dx, lift: 0, pastern: 35 - 70 * breakover * breakover)
        }
        // Swing: snaps forward quickly, decelerates to land
        let p = (s - stance) / (1 - stance)
        let forward = 1 - pow(1 - p, 2.2)
        let dx = -L * stance / 2 + L * stance * forward
        // Lifted in an arc, highest early in the swing; fores lift higher than hinds
        let arc = sin(.pi * pow(p, 0.8))
        let height = (hind ? 7.5 : 10) * lift * arc
        // Pastern folds back under, then reaches forward to land heel-first
        let fold = hind ? -70.0 : -100
        let pastern = p < 0.4 ? -35 + (fold + 35) * sin(p / 0.4 * .pi / 2)
                              : fold + (38 - fold) * (1 - cos((p - 0.4) / 0.6 * .pi)) / 2
        return HoofPose(dx: dx, lift: height, pastern: pastern)
    }
}

// MARK: - Drawing

private enum HorseDrawing {
    static let ink = Color(hex: 0x0B0B0B)

    // Layout in a 132 × 104 box, facing right, hooves on y = 100
    static let ground: CGFloat = 100
    // Hind: stifle in the body, gaskin down to the hock, cannon down to the fetlock
    static let stifle = [CGPoint(x: 35, y: 57), CGPoint(x: 31, y: 55)]   // near, far
    static let gaskin: CGFloat = 21, hindCannon: CGFloat = 18.6
    // Fore: elbow at the bottom of the shoulder, forearm down to the knee, cannon to the fetlock
    static let elbow = [CGPoint(x: 81, y: 59), CGPoint(x: 77, y: 57)]
    static let forearm: CGFloat = 18.6, foreCannon: CGFloat = 17.4
    static let pasternLength: CGFloat = 6.5

    /// Fills a part and traces its edge with a hairline, so overlapping parts join without light seams
    private static func solid(_ path: Path, in ctx: inout GraphicsContext) {
        ctx.fill(path, with: .color(ink))
        ctx.stroke(path, with: .color(ink), lineWidth: 0.7)
    }

    /// Everything the legs need to place a hoof: the body's transform and how far it is tipped
    struct Frame {
        var body: CGAffineTransform
        var toBody: CGAffineTransform
        var tilt: Double          // degrees the body is rotated (front up), to keep planted hooves flat
        var hop: CGFloat
        var tuck: Double
    }

    static func draw(_ pose: HorsePose, in ctx: inout GraphicsContext) {
        // Body moves as one: a dip on each footfall, a gentle rock about the middle, and when rearing
        // a tip back about the hind hooves and a small hop
        let centre = CGPoint(x: 56, y: 46)
        let haunches = CGPoint(x: 33, y: ground)
        var t = CGAffineTransform(translationX: 0, y: CGFloat(pose.bob - pose.hop))
        t = t.translatedBy(x: haunches.x, y: haunches.y).rotated(by: CGFloat(-pose.rear * .pi / 180)).translatedBy(x: -haunches.x, y: -haunches.y)
        t = t.translatedBy(x: centre.x, y: centre.y).rotated(by: CGFloat(-pose.pitch * .pi / 180)).translatedBy(x: -centre.x, y: -centre.y)
        let frame = Frame(body: t, toBody: t.inverted(), tilt: pose.rear + pose.pitch, hop: CGFloat(pose.hop), tuck: pose.tuck)

        // The spine curves: the front half (shoulders, forelegs, neck) turns further than the haunches,
        // and the barrel between them bends smoothly
        let bend = CGFloat(-pose.bend * .pi / 180)
        let front = t.translatedBy(x: spineBend.x, y: spineBend.y).rotated(by: bend).translatedBy(x: -spineBend.x, y: -spineBend.y)
        let frontFrame = Frame(body: front, toBody: front.inverted(), tilt: pose.rear + pose.pitch + pose.bend, hop: CGFloat(pose.hop), tuck: pose.tuck)

        var c = ctx
        c.concatenate(t)
        var f = ctx
        f.concatenate(front)

        // Far side first (LH = 0, LF = 1, RH = 2, RF = 3; right side is the far side)
        drawHindLeg(pose.hooves[2], hip: stifle[1], frame: frame, in: &c)
        drawForeLeg(pose.hooves[3], elbow: elbow[1], frame: frontFrame, in: &f)

        drawTail(swing: pose.tail, in: &c)
        drawBarrel(bend: Double(bend), in: &c)

        drawHindLeg(pose.hooves[0], hip: stifle[0], frame: frame, in: &c)
        drawForeLeg(pose.hooves[1], elbow: elbow[0], frame: frontFrame, in: &f)

        drawNeckAndHead(nod: pose.nod, ear: pose.ear, in: &f)
    }

    /// Where the spine bends from: just ahead of the haunches
    static let spineBend = CGPoint(x: 42, y: 44)

    /// How much of the spine's bend a point at `x` takes: none at the haunches, all of it from the withers on
    private static func bendShare(_ x: CGFloat) -> CGFloat {
        let c = min(max((x - 30) / 48, 0), 1)
        return c * c * (3 - 2 * c)
    }

    // MARK: Body

    private static func drawBarrel(bend: Double, in ctx: inout GraphicsContext) {
        // Each outline point turns about the bend point by its share of the bend, so the back curves
        func b(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            let a = CGFloat(bend) * bendShare(x)
            let dx = x - spineBend.x, dy = y - spineBend.y
            return CGPoint(x: spineBend.x + dx * cos(a) - dy * sin(a), y: spineBend.y + dx * sin(a) + dy * cos(a))
        }
        var p = Path()
        p.move(to: b(23, 31))                                                         // croup
        p.addCurve(to: b(52, 36), control1: b(34, 29), control2: b(44, 36))           // loin into the back dip
        p.addCurve(to: b(73, 30), control1: b(60, 36), control2: b(67, 29))           // up to the withers
        p.addCurve(to: b(89, 46), control1: b(81, 31), control2: b(88, 37))           // shoulder
        p.addCurve(to: b(85, 58), control1: b(91, 51), control2: b(89, 56))           // point of chest
        p.addCurve(to: b(66, 60), control1: b(80, 61), control2: b(73, 60))           // girth
        p.addCurve(to: b(40, 59), control1: b(57, 62), control2: b(47, 62))           // belly
        p.addCurve(to: b(19, 49), control1: b(32, 60), control2: b(22, 57))           // flank, back of thigh
        p.addCurve(to: b(23, 31), control1: b(15, 42), control2: b(16, 33))           // buttock
        p.closeSubpath()
        solid(p, in: &ctx)
    }

    // MARK: Legs

    /// Two-bone IK: the joint between `a` (length r1) and `target` (r2 away), on the side given by `forward`
    private static func joint(from a: CGPoint, to target: CGPoint, _ r1: CGFloat, _ r2: CGFloat, forward: Bool) -> (CGPoint, CGPoint) {
        var dx = target.x - a.x, dy = target.y - a.y
        var d = hypot(dx, dy)
        let reach = (r1 + r2) * 0.998
        var end = target
        if d > reach {   // out of reach: straighten towards the target
            end = CGPoint(x: a.x + dx / d * reach, y: a.y + dy / d * reach)
            dx = end.x - a.x; dy = end.y - a.y; d = reach
        }
        let base = atan2(dy, dx)
        let cosA = max(-1, min(1, (r1 * r1 + d * d - r2 * r2) / (2 * r1 * d)))
        let off = acos(cosA)
        // Facing right with y down: subtracting the offset puts the joint in front of the line
        let angle = forward ? base - off : base + off
        return (CGPoint(x: a.x + cos(angle) * r1, y: a.y + sin(angle) * r1), end)
    }

    /// Where the hoof and fetlock are, in the body's own coordinates. The hoof is placed in the world (on the
    /// ground, or lifted), then carried into the body's frame, so planted hooves stay put however the body moves.
    private static func fetlock(for hoof: HoofPose, under x: CGFloat, frame: Frame) -> (fetlock: CGPoint, hoof: CGPoint, pastern: Double) {
        let hoofWorld = CGPoint(x: x + CGFloat(hoof.dx), y: ground - CGFloat(hoof.lift) - frame.hop)
        let r = hoof.pastern * .pi / 180
        let fetWorld = CGPoint(x: hoofWorld.x - CGFloat(sin(r)) * pasternLength, y: hoofWorld.y - CGFloat(cos(r)) * pasternLength)
        return (fetWorld.applying(frame.toBody), hoofWorld.applying(frame.toBody), hoof.pastern - frame.tilt)
    }

    private static func drawHindLeg(_ hoof: HoofPose, hip: CGPoint, frame: Frame, in ctx: inout GraphicsContext) {
        // Rests with the hoof a little behind the stifle, under the hock
        let (fet, hoofPoint, pastern) = fetlock(for: hoof, under: hip.x - 1, frame: frame)
        let (hock, fetReached) = joint(from: hip, to: fet, gaskin, hindCannon, forward: false)

        // Thigh / gaskin: a heavy muscle from the hip down to the hock
        taper(from: CGPoint(x: hip.x - 6, y: hip.y - 10), to: hip, 17, 12, in: &ctx)
        taper(from: hip, to: hock, 11, 5, in: &ctx)
        // Hock joint, with its point sticking out behind
        solid(Path(ellipseIn: CGRect(x: hock.x - 3, y: hock.y - 3, width: 6, height: 6)), in: &ctx)
        var point = Path()
        point.move(to: CGPoint(x: hock.x + 1, y: hock.y - 3))
        point.addLine(to: CGPoint(x: hock.x - 4.8, y: hock.y - 1.2))
        point.addLine(to: CGPoint(x: hock.x + 1, y: hock.y + 2.8))
        point.closeSubpath()
        solid(point, in: &ctx)

        taper(from: hock, to: fetReached, 4.6, 4.2, in: &ctx)
        drawPasternAndHoof(from: fetReached, hoofPoint: hoofPoint, pastern: pastern, in: &ctx)
    }

    private static func drawForeLeg(_ hoof: HoofPose, elbow: CGPoint, frame: Frame, in ctx: inout GraphicsContext) {
        var (fet, hoofPoint, pastern) = fetlock(for: hoof, under: elbow.x + 1, frame: frame)
        // Rearing: the foreleg folds up — knee forward and high, cannon and hoof hanging back under it
        if frame.tuck > 0 {
            let k = CGFloat(frame.tuck)
            let tuckFet = CGPoint(x: elbow.x + 13, y: elbow.y + 22)
            let tuckHoof = CGPoint(x: elbow.x + 9, y: elbow.y + 27)
            fet = CGPoint(x: fet.x + (tuckFet.x - fet.x) * k, y: fet.y + (tuckFet.y - fet.y) * k)
            hoofPoint = CGPoint(x: hoofPoint.x + (tuckHoof.x - hoofPoint.x) * k, y: hoofPoint.y + (tuckHoof.y - hoofPoint.y) * k)
            pastern += (-75 - pastern) * frame.tuck
        }
        let (knee, fetReached) = joint(from: elbow, to: fet, forearm, foreCannon, forward: true)

        // Shoulder muscle swings with the leg
        let shoulderTop = CGPoint(x: elbow.x + 2 + (knee.x - elbow.x) * 0.15, y: elbow.y - 15)
        taper(from: shoulderTop, to: elbow, 15, 10, in: &ctx)
        // Forearm tapering to a knobbly knee
        taper(from: elbow, to: knee, 9.5, 5, in: &ctx)
        solid(Path(ellipseIn: CGRect(x: knee.x - 3, y: knee.y - 2.8, width: 6, height: 5.6)), in: &ctx)
        taper(from: knee, to: fetReached, 4.3, 4, in: &ctx)
        drawPasternAndHoof(from: fetReached, hoofPoint: hoofPoint, pastern: pastern, in: &ctx)
    }

    private static func drawPasternAndHoof(from fet: CGPoint, hoofPoint: CGPoint, pastern: Double, in ctx: inout GraphicsContext) {
        // Fetlock bump
        solid(Path(ellipseIn: CGRect(x: fet.x - 2.8, y: fet.y - 2.6, width: 5.6, height: 5.2)), in: &ctx)

        // Hoof: drawn flat on the ground (heel behind, toe in front) and tipped with the pastern —
        // level when standing at 35°, toe-down at breakover, flipped up while folded in the swing
        var h = ctx
        h.translateBy(x: hoofPoint.x, y: hoofPoint.y)
        h.rotate(by: .degrees(35 - pastern))
        var hoof = Path()
        hoof.move(to: CGPoint(x: -2.6, y: 0.4))      // heel, on the ground
        hoof.addLine(to: CGPoint(x: 3.9, y: 0.4))    // toe
        hoof.addLine(to: CGPoint(x: 1.6, y: -4.6))   // front wall up to the coronet
        hoof.addLine(to: CGPoint(x: -2.4, y: -4.4))  // heel bulb
        hoof.closeSubpath()
        solid(hoof, in: &h)

        // Pastern from the fetlock down into the top of the hoof
        let r = (35 - pastern) * .pi / 180
        let top = CGPoint(x: -0.4, y: -4)
        let coronet = CGPoint(x: hoofPoint.x + top.x * CGFloat(cos(r)) - top.y * CGFloat(sin(r)),
                              y: hoofPoint.y + top.x * CGFloat(sin(r)) + top.y * CGFloat(cos(r)))
        taper(from: fet, to: coronet, 4, 3.6, in: &ctx)
    }

    /// A limb segment that narrows from `w0` to `w1`, with rounded ends
    private static func taper(from a: CGPoint, to b: CGPoint, _ w0: CGFloat, _ w1: CGFloat, in ctx: inout GraphicsContext) {
        let dx = b.x - a.x, dy = b.y - a.y
        let len = max(hypot(dx, dy), 0.001)
        let nx = -dy / len, ny = dx / len
        var p = Path()
        p.move(to: CGPoint(x: a.x + nx * w0 / 2, y: a.y + ny * w0 / 2))
        p.addLine(to: CGPoint(x: b.x + nx * w1 / 2, y: b.y + ny * w1 / 2))
        p.addLine(to: CGPoint(x: b.x - nx * w1 / 2, y: b.y - ny * w1 / 2))
        p.addLine(to: CGPoint(x: a.x - nx * w0 / 2, y: a.y - ny * w0 / 2))
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: a.x - w0 / 2, y: a.y - w0 / 2, width: w0, height: w0))
        p.addEllipse(in: CGRect(x: b.x - w1 / 2, y: b.y - w1 / 2, width: w1, height: w1))
        solid(p, in: &ctx)
    }

    // MARK: Tail

    private static func drawTail(swing: Double, in ctx: inout GraphicsContext) {
        // Dock first, then the hair, which lags behind the dock's swing
        var dock = ctx
        let root = CGPoint(x: 21, y: 35)
        dock.translateBy(x: root.x, y: root.y)
        dock.rotate(by: .degrees(swing * 0.6))

        var dockPath = Path()
        dockPath.move(to: CGPoint(x: 2, y: -3))
        dockPath.addQuadCurve(to: CGPoint(x: -7, y: 9), control: CGPoint(x: -5, y: -1))
        dockPath.addLine(to: CGPoint(x: -2, y: 11))
        dockPath.addQuadCurve(to: CGPoint(x: 3, y: 2), control: CGPoint(x: 0, y: 5))
        dockPath.closeSubpath()
        solid(dockPath, in: &dock)

        var hair = dock
        hair.translateBy(x: -4.5, y: 9)
        hair.rotate(by: .degrees(swing * 0.5))
        // Full at the top, falling to a ragged tip of a few strands
        var h = Path()
        h.move(to: CGPoint(x: -3, y: 0))
        h.addCurve(to: CGPoint(x: -8, y: 38), control1: CGPoint(x: -9, y: 10), control2: CGPoint(x: -10, y: 28))
        h.addLine(to: CGPoint(x: -6.5, y: 44))
        h.addLine(to: CGPoint(x: -4.5, y: 39))
        h.addLine(to: CGPoint(x: -2.5, y: 45))
        h.addLine(to: CGPoint(x: -1.5, y: 38))
        h.addCurve(to: CGPoint(x: 3, y: 1), control1: CGPoint(x: 1, y: 26), control2: CGPoint(x: 3, y: 12))
        h.closeSubpath()
        solid(h, in: &hair)
    }

    // MARK: Neck and head

    private static func drawNeckAndHead(nod: Double, ear: Double, in ctx: inout GraphicsContext) {
        var c = ctx
        // Neck and head pivot at the base of the neck
        let base = CGPoint(x: 76, y: 38)
        c.translateBy(x: base.x, y: base.y)
        c.rotate(by: .degrees(nod))
        c.translateBy(x: -base.x, y: -base.y)

        // Neck: arched crest up to the poll, throatlatch, then the underline back down to the chest
        var neck = Path()
        neck.move(to: CGPoint(x: 64, y: 35))
        neck.addCurve(to: CGPoint(x: 102, y: 11), control1: CGPoint(x: 77, y: 25), control2: CGPoint(x: 89, y: 11))
        neck.addLine(to: CGPoint(x: 109, y: 19))
        neck.addCurve(to: CGPoint(x: 89, y: 52), control1: CGPoint(x: 101, y: 30), control2: CGPoint(x: 95, y: 41))
        neck.addLine(to: CGPoint(x: 76, y: 44))
        neck.closeSubpath()
        solid(neck, in: &c)

        // Mane: hair standing off the crest in uneven tufts that lie back towards the withers
        let p0 = CGPoint(x: 64, y: 35), p1 = CGPoint(x: 77, y: 25), p2 = CGPoint(x: 89, y: 11), p3 = CGPoint(x: 102, y: 11)
        func crest(_ t: CGFloat) -> (point: CGPoint, tangent: CGPoint) {
            let m = 1 - t
            let pt = CGPoint(
                x: m * m * m * p0.x + 3 * m * m * t * p1.x + 3 * m * t * t * p2.x + t * t * t * p3.x,
                y: m * m * m * p0.y + 3 * m * m * t * p1.y + 3 * m * t * t * p2.y + t * t * t * p3.y)
            let d = CGPoint(
                x: 3 * m * m * (p1.x - p0.x) + 6 * m * t * (p2.x - p1.x) + 3 * t * t * (p3.x - p2.x),
                y: 3 * m * m * (p1.y - p0.y) + 6 * m * t * (p2.y - p1.y) + 3 * t * t * (p3.y - p2.y))
            let len = max(hypot(d.x, d.y), 0.001)
            return (pt, CGPoint(x: d.x / len, y: d.y / len))
        }
        let tufts: [CGFloat] = [2.2, 3.4, 2.6, 3.8, 2.9, 3.5, 2.4, 3.1, 2.0]
        var mane = Path()
        let first = crest(0.12)
        mane.move(to: CGPoint(x: first.point.x, y: first.point.y + 1))
        for (i, len) in tufts.enumerated() {
            let t0 = 0.12 + CGFloat(i) / CGFloat(tufts.count) * 0.84
            let t1 = 0.12 + (CGFloat(i) + 1) / CGFloat(tufts.count) * 0.84
            let a = crest(t0), b = crest(t1)
            // Out from the crest (up and back) and swept towards the withers
            let normal = CGPoint(x: a.tangent.y, y: -a.tangent.x)
            let tip = CGPoint(x: a.point.x + normal.x * len - a.tangent.x * 2.4, y: a.point.y + normal.y * len - a.tangent.y * 2.4)
            mane.addLine(to: tip)
            mane.addLine(to: CGPoint(x: b.point.x, y: b.point.y + 0.6))
        }
        mane.addLine(to: CGPoint(x: crest(0.96).point.x, y: crest(0.96).point.y + 3))
        mane.addLine(to: CGPoint(x: first.point.x + 2, y: first.point.y + 4))
        mane.closeSubpath()
        solid(mane, in: &c)

        // Head: forehead, long nasal line to the muzzle, chin, then the round cheek back up to the throat
        var head = Path()
        head.move(to: CGPoint(x: 100, y: 11))
        head.addCurve(to: CGPoint(x: 110, y: 9), control1: CGPoint(x: 103, y: 7), control2: CGPoint(x: 107, y: 6))
        head.addLine(to: CGPoint(x: 124, y: 27))
        head.addCurve(to: CGPoint(x: 119, y: 36), control1: CGPoint(x: 128, y: 31), control2: CGPoint(x: 125, y: 37))
        head.addCurve(to: CGPoint(x: 112, y: 33), control1: CGPoint(x: 116, y: 36), control2: CGPoint(x: 114, y: 34))
        head.addCurve(to: CGPoint(x: 101, y: 24), control1: CGPoint(x: 106, y: 33), control2: CGPoint(x: 101, y: 30))
        head.closeSubpath()
        solid(head, in: &c)

        // Forelock
        var forelock = Path()
        forelock.move(to: CGPoint(x: 106, y: 9))
        forelock.addQuadCurve(to: CGPoint(x: 112, y: 16), control: CGPoint(x: 112, y: 10))
        forelock.addLine(to: CGPoint(x: 109, y: 15))
        forelock.closeSubpath()
        solid(forelock, in: &c)

        // Ear, flicking back from its base
        var e = c
        e.translateBy(x: 104, y: 9)
        e.rotate(by: .degrees(-ear))
        var earPath = Path()
        earPath.move(to: CGPoint(x: -2.8, y: 1))
        earPath.addQuadCurve(to: CGPoint(x: 1, y: -9.5), control: CGPoint(x: -2.5, y: -5.5))
        earPath.addQuadCurve(to: CGPoint(x: 2.8, y: 0.5), control: CGPoint(x: 3, y: -4))
        earPath.closeSubpath()
        solid(earPath, in: &e)
    }
}

#Preview {
    WalkingHorse(start: true)
        .padding(.leading, 170)
        .frame(width: 390, height: 200, alignment: .leading)
}



