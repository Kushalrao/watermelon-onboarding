import SwiftUI

/// Figma: "iPhone 14 Plus - 292" (node 1080:31224) — the fifth home page: the pinned widgets are living data art,
/// each redrawn from its reference image and always moving the way that kind of chart does:
/// - a chord diagram whose movie threads keep sweeping round the circle into their genre hubs,
/// - a wind/solar Sankey whose bands sway as the flows shift, with light running along them,
/// - a web of threads tied from a ring of dots to one knot that keeps circling inside the ring,
/// - a sphere of fine dotted threads rippling like a sound wave.
/// - a 3D worm screw driving a spur gear, its threads running up as the gear turns,
/// - a globe of beaded threads that a twist wave runs down from the top, over and over.
/// The four patterns are drawn in white on black cards; the gear sits in its own grey studio.
struct HomeV5View: View {
    var onOpenFund: () -> Void = {}

    // Pull-down search: how far the page is pulled past the top, and whether search is open
    @State private var pull: CGFloat = 0
    @State private var pastThreshold = false
    @State private var searching = false
    // Opening and closing search is one eased move from wherever the page was let go. On release the scroll view
    // is held where it is (a top margin the size of the pull) and the content keeps its pulled-back scale; the
    // page then eases from there to its spot behind the search, and back again when search closes.
    @State private var hold: CGFloat = 0
    @State private var heldScale: CGFloat = 1
    @State private var pageScale: CGFloat = 1
    @State private var pageShift: CGFloat = 0
    @State private var pageCorner: CGFloat = 0
    @State private var scrollPosition = ScrollPosition(edge: .top)

    private static let settleScale: CGFloat = 0.9
    private static let settleTop: CGFloat = 96

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-widgetsOnly") { widgetsOnlyBody } else { page }
    }

    private var page: some View {
        GeometryReader { geo in
          ZStack(alignment: .top) {
            Color(hex: 0xE4E3DF).ignoresSafeArea()

            ZStack(alignment: .topLeading) {
                let cardWidth = (geo.size.width - 2 * Self.pagePadding - Self.columnGap) / 2
                let gridBottom = 175 + 2 * Self.tileHeight(cardWidth) + Self.rowGap
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

                        // Figma: U+10020A in SF Compact Display Medium 19 = "pencil"
                        Button(action: { Haptics.tap() }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 19, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.75))
                                .frame(width: 35, height: 35)
                                .background(Circle().fill(Color.white))
                                .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 0.5))
                                .shadow(color: Color.black.opacity(0.04), radius: 2.75, x: 0, y: 1)
                        }
                        .buttonStyle(PressScaleStyle())
                        .at(geo.size.width - Self.pagePadding - 35, 124)

                        // Shown for now: rotating dot sphere, ring stack, loop tunnel and line gear.
                        // Kept but not shown: chord diagram, Sankey, thread web, sound-wave sphere, smoke ring (see `hidden`).
                        // Two columns that fit the screen: 15pt page padding, 15pt between columns, 19pt between rows.
                        widgetGrid(cardWidth)
                        .at(Self.pagePadding, 175)

                        Text("Last week")
                            .font(FigmaFont.walsheimMedium(23))
                            .foregroundStyle(Color.black)
                            .frame(height: 29)
                            .at(15, gridBottom + 28)

                        VStack(spacing: 5) {
                            ForEach(ChatPreview.all) { chat in
                                ChatRow(chat: chat, action: onOpenFund)
                            }
                        }
                        .at(15, gridBottom + 74)
                    }
                    // Room below the last chat for the floating nav
                    .frame(width: geo.size.width, height: gridBottom + 530, alignment: .topLeading)
                    .clipped()
                    // While pulling, the content eases back a touch. Scaled inside the scroll view, so the drag
                    // under the finger isn't thrown off.
                    .scaleEffect(hold > 0 ? heldScale : Self.pullScale(pull), anchor: .top)
                    .frame(maxWidth: .infinity)
                }
                .contentMargins(.top, hold, for: .scrollContent)
                .scrollPosition($scrollPosition)
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, offset in
                    pull = max(0, -offset)
                    let past = pull > QuickSearchOverlay.threshold
                    if past != pastThreshold {
                        pastThreshold = past
                        if past { Haptics.thresholdCrossed() }
                    }
                }
                .onScrollPhaseChange { old, new in
                    // Letting go past the threshold opens search
                    if old == .interacting, new != .interacting, pastThreshold, !searching { openSearch() }
                }

                // Same spot as the other homes
                HomeNavBar(left: "HomeV3NavLeft", right: "HomeV3NavRight")
                    .at(17, geo.size.height - 94)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .background(Color.screenBackground)
            // Once search is open the page sits lower and further back
            .clipShape(RoundedRectangle(cornerRadius: pageCorner, style: .continuous))
            .scaleEffect(pageScale, anchor: .top)
            .offset(y: pageShift)
            .allowsHitTesting(!searching)

            if searching {
                QuickSearchOverlay(onClose: closeSearch)
            }
          }
        }
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard)
    }

    /// How far the content eases back while being pulled
    private static func pullScale(_ pull: CGFloat) -> CGFloat { 1 - 0.06 * min(1, pull / QuickSearchOverlay.threshold) }

    private func openSearch() {
        Haptics.lift()
        // Freeze the page exactly where it was let go, so nothing springs back first
        heldScale = Self.pullScale(pull)
        hold = pull
        searching = true
        // Then one eased move to its spot behind the search: content top at `settleTop`, overall scale `settleScale`
        withAnimation(.timingCurve(0.3, 0, 0.2, 1, duration: 0.6)) {
            pageScale = Self.settleScale / heldScale
            pageShift = Self.settleTop - hold * pageScale
            pageCorner = 44
        }
    }

    private func closeSearch() {
        // Ease back to exactly the resting layout (content at the top, full size)...
        withAnimation(.timingCurve(0.3, 0, 0.2, 1, duration: 0.5)) {
            pageScale = 1 / heldScale
            pageShift = -hold * pageScale
            pageCorner = 0
        } completion: {
            // ...then swap the held state for the real one, which looks identical
            var plain = Transaction()
            plain.disablesAnimations = true
            withTransaction(plain) {
                hold = 0
                heldScale = 1
                pageScale = 1
                pageShift = 0
                scrollPosition.scrollTo(edge: .top)
                searching = false
            }
        }
    }

    /// Pale paper card: warm off-white fading to white, top to bottom
    private static let paper = AnyShapeStyle(LinearGradient(
        colors: [Color(hex: 0xF0EEE9), Color.white], startPoint: .top, endPoint: .bottom
    ))
    /// Sage through lavender to sky blue, left to right (Figma 1179:34301; the last stop sits past the edge, so it
    /// ends on the colour it reaches there)
    private static let sky = AnyShapeStyle(LinearGradient(stops: [
        .init(color: Color(hex: 0xCBD2B3), location: 0.011286),
        .init(color: Color(hex: 0xB6B7CD), location: 0.45131),
        .init(color: Color(hex: 0x7EC1F6), location: 1),
    ], startPoint: .leading, endPoint: .trailing))
    /// Marigold warming to apricot, left to right (Figma 1179:34383)
    private static let marigold = AnyShapeStyle(LinearGradient(stops: [
        .init(color: Color(hex: 0xFFCB41), location: 0),
        .init(color: Color(hex: 0xFFC189), location: 0.91163),
        .init(color: Color(hex: 0xF9C08F), location: 1),
    ], startPoint: .leading, endPoint: .trailing))
    /// Sage fading to lime, left to right (Figma 1179:33933)
    private static let meadow = AnyShapeStyle(LinearGradient(stops: [
        .init(color: Color(hex: 0xCBD2B3), location: 0.011286),
        .init(color: Color(hex: 0xC0CDB6), location: 0.45131),
        .init(color: Color(hex: 0xD6F67F), location: 1),
    ], startPoint: .leading, endPoint: .trailing))

    /// The four pinned widgets in their two-column grid
    private func widgetGrid(_ cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Self.rowGap) {
            HStack(alignment: .top, spacing: Self.columnGap) {
                widget("Market effects", width: cardWidth) {
                    ArtCard(background: Self.paper) { GrowIn { DotSpherePattern(ink: Color.black) } }
                }
                widget("Portfolio performance", width: cardWidth) {
                    ArtCard(background: Self.sky) { RingStackPattern(ink: Color.black, paper: Color(hex: 0xB8B9CC)).offset(y: -12) }
                }
            }
            HStack(alignment: .top, spacing: Self.columnGap) {
                widget("Personal goals", width: cardWidth) {
                    ArtCard(background: Self.marigold) {
                        // Zoomed in so the loops fill more of the card
                        ThreadTunnelPattern(ink: Color.black).scaleEffect(1.25)
                    }
                }
                widget("Portfolio strength", width: cardWidth) {
                    ArtCard(background: Self.meadow) { LineGearPattern(ink: Color.black, paper: Color(hex: 0xCFD8B0)) }
                }
            }
        }
    }

    /// Just the widget grid on white, centred (launch with `-widgetsOnly`), for recordings
    private var widgetsOnlyBody: some View {
        GeometryReader { geo in
            let cardWidth = (geo.size.width - 2 * Self.pagePadding - Self.columnGap) / 2
            widgetGrid(cardWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white)
        .ignoresSafeArea()
        .statusBarHidden()
    }

    /// Warm sunrise card: yellow fading to peach
    private static let sunrise = AnyShapeStyle(LinearGradient(
        colors: [Color(hex: 0xF8D262), Color(hex: 0xF4C58F)], startPoint: .leading, endPoint: .trailing
    ))

    /// Widgets set aside for now; swap any of these back into the grid above to show it again
    @ViewBuilder private var hidden: some View {
        ArtCard { ChordPattern() }
        ArtCard { SankeyPattern() }
        ArtCard { WebPattern() }
        ArtCard(background: Self.paper) { WaveSpherePattern(ink: Color.black) }
        ArtCard { SmokeRingPattern() }
        ArtCard(background: Self.paper) { SwirlGlobePattern(ink: Color.black, threadStrength: 2.2, pace: 0.25) }
        ArtCard(background: Self.paper) { GearWormPattern(transparent: true, zoom: 0.72) }   // the 3D gear
    }

    private static let pagePadding: CGFloat = 15
    private static let columnGap: CGFloat = 15
    private static let rowGap: CGFloat = 19
    private static let captionGap: CGFloat = 8
    private static let captionHeight: CGFloat = 19

    /// A card plus its caption
    private static func tileHeight(_ width: CGFloat) -> CGFloat { width * 192 / 186 + captionGap + captionHeight }

    /// A pattern card scaled to the column width, with its caption underneath (Figma 1173:33884)
    private func widget<Content: View>(_ caption: String, width: CGFloat, badge: Bool = false, @ViewBuilder _ content: () -> Content) -> some View {
        let scale = width / 186
        return Button {
            Haptics.tap()
            onOpenFund()
        } label: {
            VStack(spacing: Self.captionGap) {
                // The patterns are drawn for a 186 × 192 card, so the whole card scales to fit the column
                content()
                    .scaleEffect(scale, anchor: .topLeading)
                    .frame(width: width, height: 192 * scale, alignment: .topLeading)
                    .overlay(alignment: .topLeading) { if badge { MoreBadge().at(width - 28, -4) } }

                Text(caption)
                    .font(FigmaFont.walsheim(15))
                    .foregroundStyle(Color(hex: 0x8C8C8C))
                    .multilineTextAlignment(.center)
                    .frame(width: width, height: Self.captionHeight)
            }
        }
        .buttonStyle(PressScaleStyle())
    }
}

/// 186 × 192 black card holding a white pattern, clipped to its 37pt corners, with the widgets' soft shadow
private struct ArtCard<Pattern: View>: View {
    var background = AnyShapeStyle(Color.black)
    @ViewBuilder let pattern: Pattern

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(background)
            pattern
        }
        .frame(width: 186, height: 192, alignment: .topLeading)
        .clipShape(RoundedRectangle(cornerRadius: 37, style: .continuous))
        .shadow(color: Color.black.opacity(0.11), radius: 21, x: 0, y: 2)
    }
}

/// Small deterministic random numbers, so each pattern lays out the same every launch
struct SeededRandom {
    var state: UInt64
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(1 << 53)
    }
}

// MARK: - Chord diagram ("365 movies in 2012", image 140)

/// Every movie sits on the rim of a circle and sends a thread to each of its genres, gathered at hubs on the
/// right. The threads keep sweeping round the rim, so the weave is always shifting. Drawn in the reference image's
/// own 1200 × 1469 space, placed exactly as Figma crops it into the card.
private struct ChordPattern: View {
    private struct Thread {
        let start: Double   // 0…1 along the rim
        let speed: Double   // rim lengths per second
        let hub: Int
        let shimmer: Double
    }

    private static let centre = CGPoint(x: 555, y: 590)
    private static let rim = 440.0
    private static let hubRadius = 490.0
    /// Genre hubs (Action … Western) fan from up-right to down-right; movies fill the rest of the rim
    private static let hubAngles = (-37.0, 41.0)
    private static let rimAngles = (46.0, 323.0)

    /// How many movies fall in each genre (Action … Western); Drama is by far the biggest
    private static let genreWeights: [Double] = [30, 12, 8, 10, 40, 4, 25, 6, 70, 10, 8, 14, 5, 12, 18, 12, 5, 25, 4, 3]

    private static let threads: [Thread] = {
        var rng = SeededRandom(state: 2012)
        let total = genreWeights.reduce(0, +)
        func pickGenre() -> Int {
            var r = rng.next() * total
            for (i, weight) in genreWeights.enumerated() {
                r -= weight
                if r <= 0 { return i }
            }
            return genreWeights.count - 1
        }
        var threads: [Thread] = []
        for movie in 0..<365 {
            let start = (Double(movie) + rng.next() * 0.6) / 365
            let speed = 0.012 + rng.next() * 0.01
            for _ in 0..<(1 + Int(rng.next() * 2.6)) {
                threads.append(Thread(start: start, speed: speed, hub: pickGenre(), shimmer: rng.next() * 6.28))
            }
        }
        return threads
    }()

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, _ in
                // Figma: the image is 336 × 411 at (-75, -73.2) in the card
                ctx.translateBy(x: -75, y: -73.2)
                ctx.scaleBy(x: 0.28, y: 0.28)

                let hubs = (0..<Self.genreWeights.count).map { i -> CGPoint in
                    let a = (Self.hubAngles.0 + (Self.hubAngles.1 - Self.hubAngles.0) * Double(i) / Double(Self.genreWeights.count - 1)) * .pi / 180
                    return CGPoint(x: Self.centre.x + Self.hubRadius * cos(a), y: Self.centre.y + Self.hubRadius * sin(a))
                }
                for thread in Self.threads {
                    let u = (thread.start + thread.speed * t).truncatingRemainder(dividingBy: 1)
                    // Threads fade out as they reach the hubs' end of the rim and fade back in at the other
                    let fade = min(1, min(u, 1 - u) / 0.05)
                    let a = (Self.rimAngles.0 + (Self.rimAngles.1 - Self.rimAngles.0) * u) * .pi / 180
                    var path = Path()
                    path.move(to: CGPoint(x: Self.centre.x + Self.rim * cos(a), y: Self.centre.y + Self.rim * sin(a)))
                    path.addLine(to: hubs[thread.hub])
                    let glint = 0.45 + 0.2 * sin(t * 1.3 + thread.shimmer)
                    ctx.stroke(path, with: .color(Color.white.opacity(0.5 * glint * fade)), lineWidth: 1.3)
                }
            }
        }
    }
}

// MARK: - Sankey ("Net generation from wind and solar", image 141)

/// Wind and solar each split into a band per state, stacked at the source and fanned out to the states on the
/// right. The states' shares keep drifting, so the bands sway and re-stack, and light runs along each band from
/// source to state. Drawn in the reference image's 772 × 665 space, placed as Figma crops it.
private struct SankeyPattern: View {
    private static let sourceX = 72.0
    private static let targetX = 655.0
    private static let wind = (top: 275.0, height: 103.0)
    private static let solar = (top: 386.0, height: 9.0)

    /// Band centres down the right-hand list (Texas … Alabama)
    private static let targetCentres: [Double] = {
        let leaders: [Double] = [45, 72, 93, 111, 128, 144]
        let rest: [Double] = (0..<44).map { (k: Int) -> Double in 160 + Double(k) * 475 / 43 }
        return leaders + rest
    }()
    /// Size of each state's flow, largest first
    private static let shares: [Double] = (0..<50).map { (i: Int) -> Double in 0.25 + 22 * exp(-Double(i) * 0.28) }
    /// How much of each state's flow is solar (California, Arizona, Nevada, New Jersey, North Carolina lead)
    private static let solarShare: [Double] = {
        let leaders: [Int: Double] = [1: 0.35, 16: 0.6, 27: 0.5, 30: 0.55, 33: 0.6]
        return (0..<50).map { (i: Int) -> Double in leaders[i] ?? 0.06 }
    }()

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, _ in
                // Figma: the image is 393.7 × 339 at (-73, -73) in the card
                ctx.translateBy(x: -73, y: -73)
                ctx.scaleBy(x: 0.51, y: 0.51)

                // Each state's flow breathes on its own slow cycle
                var windRaw = [Double](repeating: 0, count: 50), solarRaw = windRaw
                for i in 0..<50 {
                    let breath: Double = 1 + 0.24 * sin(t * 0.55 + Double(i) * 1.3)
                    let flow: Double = Self.shares[i] * breath
                    windRaw[i] = flow * (1 - Self.solarShare[i])
                    solarRaw[i] = flow * Self.solarShare[i]
                }
                let windScale = Self.wind.height / windRaw.reduce(0, +)
                let solarScale = Self.solar.height / solarRaw.reduce(0, +)

                var windY = Self.wind.top, solarY = Self.solar.top
                var windBands: [(Path, Path, Double)] = [], solarBands: [(Path, Path, Double)] = []
                for i in 0..<50 {
                    let w = windRaw[i] * windScale, s = solarRaw[i] * solarScale
                    let top = Self.targetCentres[i] - (w + s) / 2
                    windBands.append(Self.band(from: windY, to: top, height: w, index: i))
                    solarBands.append(Self.band(from: solarY, to: top + w, height: s, index: i))
                    windY += w
                    solarY += s
                }

                let span = (CGPoint(x: Self.sourceX, y: 0), CGPoint(x: Self.targetX, y: 0))
                let windFill = Gradient(stops: [
                    .init(color: Color.white.opacity(0.62), location: 0),
                    .init(color: Color.white.opacity(0.34), location: 0.45),
                    .init(color: Color.white.opacity(0.22), location: 1),
                ])
                let solarFill = Gradient(stops: [
                    .init(color: Color.white.opacity(0.95), location: 0),
                    .init(color: Color.white.opacity(0.7), location: 0.45),
                    .init(color: Color.white.opacity(0.45), location: 1),
                ])
                // Wrapped to one dash period: the raw clock is far too large for Core Graphics' dash maths
                let flowPhase = 66 - (t * 70).truncatingRemainder(dividingBy: 66)
                for (bands, fill) in [(windBands, windFill), (solarBands, solarFill)] {
                    for (index, (shape, centre, height)) in bands.enumerated() {
                        ctx.fill(shape, with: .linearGradient(fill, startPoint: span.0, endPoint: span.1))
                        // Dark hairline on each band's edge gives the strand texture of the original
                        ctx.stroke(shape, with: .color(Color.black.opacity(0.45)), lineWidth: 0.4)
                        // Light running along the band, source to state
                        ctx.stroke(
                            centre,
                            with: .color(Color.white.opacity(0.55)),
                            style: StrokeStyle(lineWidth: min(2.2, max(0.6, height * 0.5)), lineCap: .round, dash: [14, 52], dashPhase: flowPhase + Self.scatter(index) * 66)
                        )
                    }
                }
            }
        }
    }

    /// 0…1, scattered per band so the running light never lines up across neighbouring bands
    private static func scatter(_ index: Int) -> Double {
        let x = sin(Double(index) * 12.9898) * 43758.5453
        return x - x.rounded(.down)
    }

    /// A band from the source stack to a state: an S-curve with flat ends, plus its centre line for the light
    private static func band(from sourceTop: Double, to targetTop: Double, height h: Double, index: Int) -> (Path, Path, Double) {
        let midX = (sourceX + targetX) / 2
        var shape = Path()
        shape.move(to: CGPoint(x: sourceX, y: sourceTop))
        shape.addCurve(to: CGPoint(x: targetX, y: targetTop), control1: CGPoint(x: midX, y: sourceTop), control2: CGPoint(x: midX, y: targetTop))
        shape.addLine(to: CGPoint(x: targetX, y: targetTop + h))
        shape.addCurve(to: CGPoint(x: sourceX, y: sourceTop + h), control1: CGPoint(x: midX, y: targetTop + h), control2: CGPoint(x: midX, y: sourceTop + h))
        shape.closeSubpath()

        var centre = Path()
        centre.move(to: CGPoint(x: sourceX, y: sourceTop + h / 2))
        centre.addCurve(to: CGPoint(x: targetX, y: targetTop + h / 2), control1: CGPoint(x: midX, y: sourceTop + h / 2), control2: CGPoint(x: midX, y: targetTop + h / 2))
        return (shape, centre, h)
    }
}

// MARK: - Thread web (reference screenshot)

/// Dots ring a full circle, and every dot is tied by a curved thread to one
/// knot inside. The knot keeps circling inside the ring, so the fans of thread bend, cross and loop into new
/// shapes as it goes. A few threads overshoot the knot and swing back, drawing the loops of the original.
private struct WebPattern: View {
    private struct Thread {
        let angle: Double     // where its dot sits on the ring, radians
        let bend: Double      // how far the thread bows sideways (−1…1)
        let loop: Double      // 0 = straight fan, up to 1 = overshoots the knot and loops back
        let weight: Double
    }

    /// The whole ring sits inside the card
    private static let centre = CGPoint(x: 93, y: 96)
    private static let radius = 76.0

    private static let threads: [Thread] = {
        var rng = SeededRandom(state: 7)
        var threads: [Thread] = []
        // Dots all the way round the ring
        let count = 150
        for i in 0..<count {
            let a = 2 * .pi * Double(i) / Double(count)
            let loops = rng.next() < 0.18
            threads.append(Thread(angle: a, bend: rng.next() * 2 - 1,
                                  loop: loops ? 0.5 + rng.next() * 0.5 : 0, weight: rng.next() < 0.08 ? 0.8 : 0.35))
        }
        return threads
    }()

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            Canvas { ctx, _ in
                let c = Self.centre, r = Self.radius
                // The knot circles inside the ring, with a slower wobble so its path never quite repeats
                let orbit = t * 0.45
                let knot = CGPoint(
                    x: c.x + r * (0.42 * cos(orbit) + 0.12 * cos(orbit * 2.3 + 1)),
                    y: c.y + r * (0.42 * sin(orbit) + 0.12 * sin(orbit * 1.7))
                )
                // Direction from the centre out to the knot, for the loops to overshoot along
                let out = CGPoint(x: knot.x - c.x, y: knot.y - c.y)

                for (i, thread) in Self.threads.enumerated() {
                    let dot = CGPoint(x: c.x + r * cos(thread.angle), y: c.y + r * sin(thread.angle))
                    // Bow each thread sideways, breathing a little so the fans keep shifting
                    let sway = thread.bend * (0.35 + 0.15 * sin(t * 0.7 + Double(i) * 0.4))
                    let mid = CGPoint(x: (dot.x + knot.x) / 2, y: (dot.y + knot.y) / 2)
                    let span = CGPoint(x: knot.x - dot.x, y: knot.y - dot.y)
                    let c1 = CGPoint(x: mid.x - span.y * sway + (c.x - mid.x) * 0.35, y: mid.y + span.x * sway + (c.y - mid.y) * 0.35)
                    // Looping threads swing out past the knot and come back into it
                    let c2 = CGPoint(
                        x: knot.x + out.x * 0.8 * thread.loop - span.y * 0.35 * thread.loop * thread.bend,
                        y: knot.y + out.y * 0.8 * thread.loop + span.x * 0.35 * thread.loop * thread.bend
                    )
                    var path = Path()
                    path.move(to: dot)
                    path.addCurve(to: knot, control1: c1, control2: thread.loop > 0 ? c2 : knot)
                    ctx.stroke(path, with: .color(Color.white.opacity(thread.weight > 0.5 ? 0.75 : 0.5)), lineWidth: thread.weight)
                    ctx.fill(Path(ellipseIn: CGRect(x: dot.x - 1, y: dot.y - 1, width: 2, height: 2)), with: .color(Color.white.opacity(0.9)))
                }
            }
        }
    }
}

// MARK: - Swirl globe (reference screenshot)

/// A globe strung with faint threads from pole to pole, beaded with bright dots of different sizes, with a little
/// ring of beads round each pole. Everything is connected: a twist starts at the top and travels slowly down the
/// globe, bending each thread into an S as it passes, then the next one follows. The beads slide down their
/// threads with the motion and the globe turns gently.
private struct SwirlGlobePattern: View {
    /// Colour of the threads and beads
    var ink: Color = .white
    /// Multiplies how strongly the threads show (white on black needs little; a dark tone on a light card needs more)
    var threadStrength: Double = 1
    /// How fast everything moves; below 1 slows the twist, the turning and the drifting beads alike
    var pace: Double = 1

    private struct Bead { let thread: Int; let start: Double; let size: Double; let speed: Double }

    private static let centre = CGPoint(x: 93, y: 96)
    private static let radius = 76.0
    private static let threads = 44
    /// How far the globe leans towards us, so the top pole shows inside the disc as in the original
    private static let lean = 0.32

    private static let beads: [Bead] = {
        var rng = SeededRandom(state: 91)
        var beads: [Bead] = []
        for thread in 0..<threads {
            for _ in 0..<9 {
                let big = rng.next() < 0.12
                beads.append(Bead(thread: thread, start: rng.next(), size: big ? 1.6 + rng.next() * 0.8 : 0.6 + rng.next() * 0.6,
                                  speed: 0.018 + rng.next() * 0.012))
            }
        }
        return beads
    }()

    /// The twist at a latitude (0 = top pole, π = bottom): a wave set off at the top that rolls down the globe
    private static func twist(_ v: Double, _ t: Double) -> Double {
        let travel = 1.6 * v - 0.55 * t
        return 1.5 * sin(travel) * pow(sin(v), 0.6) + 0.35 * sin(2 * travel + 1)
    }

    /// Where a point of the globe lands on the card, and whether it faces us
    private static func project(v: Double, longitude: Double, spin: Double) -> (CGPoint, Bool) {
        let a = longitude + spin
        let x = sin(v) * cos(a), y = cos(v), z = sin(v) * sin(a)
        let y2 = y * cos(lean) - z * sin(lean), z2 = y * sin(lean) + z * cos(lean)
        return (CGPoint(x: centre.x + radius * x, y: centre.y - radius * y2), z2 >= 0)
    }

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600) * pace
            Canvas { ctx, _ in
                let spin = t * 0.08
                var front = Path(), back = Path()

                // Threads, pole to pole, each bent by the twist where the wave is passing
                for thread in 0..<Self.threads {
                    let base = 2 * .pi * Double(thread) / Double(Self.threads)
                    var previous: (CGPoint, Bool)?
                    for step in 0...48 {
                        let v = .pi * Double(step) / 48
                        let point = Self.project(v: v, longitude: base + Self.twist(v, t), spin: spin)
                        if let previous {
                            var segment = Path()
                            segment.move(to: previous.0)
                            segment.addLine(to: point.0)
                            if point.1 { front.addPath(segment) } else { back.addPath(segment) }
                        }
                        previous = point
                    }
                }
                ctx.stroke(back, with: .color(ink.opacity(min(1, 0.07 * threadStrength))), lineWidth: 0.35 * (1 + (threadStrength - 1) * 0.25))
                ctx.stroke(front, with: .color(ink.opacity(min(1, 0.2 * threadStrength))), lineWidth: 0.4 * (1 + (threadStrength - 1) * 0.25))

                // Beads drifting down their threads
                var nearBeads = Path(), farBeads = Path()
                for bead in Self.beads {
                    let base = 2 * .pi * Double(bead.thread) / Double(Self.threads)
                    let along = (bead.start + bead.speed * t).truncatingRemainder(dividingBy: 1)
                    let v = 0.08 + along * (.pi - 0.16)
                    let (p, near) = Self.project(v: v, longitude: base + Self.twist(v, t), spin: spin)
                    let r = bead.size / 2 * (near ? 1 : 0.7)
                    let dot = Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r))
                    if near { nearBeads.addPath(dot) } else { farBeads.addPath(dot) }
                }

                // A ring of fine beads round each pole, turning with the twist there
                for pole in [0.2, Double.pi - 0.2] {
                    for k in 0..<26 {
                        let longitude = 2 * .pi * Double(k) / 26 + Self.twist(pole, t) * 1.4
                        let (p, near) = Self.project(v: pole, longitude: longitude, spin: spin)
                        let dot = Path(ellipseIn: CGRect(x: p.x - 0.45, y: p.y - 0.45, width: 0.9, height: 0.9))
                        if near { nearBeads.addPath(dot) } else { farBeads.addPath(dot) }
                    }
                }
                ctx.fill(farBeads, with: .color(ink.opacity(0.32)))
                ctx.fill(nearBeads, with: .color(ink.opacity(0.95)))
            }
        }
    }
}

// MARK: - Ring stack (reference screenshot)

/// A tower of flat dials seen from above at an angle, like a HUD gauge: on top, a thick band with a bright arc
/// filled to 58% and numbers round its edge, with a segmented inner band; below it a thin ring, a dashed ring, a
/// fine ring and a dark segmented disc at the base. Every layer turns on its own, some one way and some the other,
/// so the stack is always quietly in motion.
private struct RingStackPattern: View {
    /// Colour of the rings, and of the card behind them (used for the cuts between the base's segments)
    var ink: Color = .white
    var paper: Color = .black

    private static let value = 0.58
    /// How flat the rings look (vertical squash of each circle)
    private static let tilt = 0.3
    private static let cx = 93.0
    /// When the widget first appeared: the layers rise into place from the bottom, then start turning
    @State private var start = Date.now

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(start)
            // Turning starts once the stack has risen, easing up to speed
            let spinFrom = 6.2, ramp = 1.6
            let since = max(0, elapsed - spinFrom)
            let t = since < ramp ? since * since / (2 * ramp) : since - ramp / 2
            Canvas { ctx, _ in
                /// Each layer rises from below the card, the base first and the top dial last
                func rise(_ layer: Int) -> Double {
                    let u = min(1, max(0, (elapsed - 2.4 - Double(layer) * 0.55) / 1.4))
                    return 1 - pow(1 - u, 3)
                }
                var layer = 0
                func point(_ cy: Double, _ r: Double, _ a: Double) -> CGPoint {
                    CGPoint(x: Self.cx + r * cos(a), y: cy + (1 - rise(layer)) * 150 + r * sin(a) * Self.tilt)
                }
                /// A flat band between two radii, from angle a0 to a1
                func band(_ cy: Double, _ inner: Double, _ outer: Double, _ a0: Double, _ a1: Double) -> Path {
                    var p = Path()
                    let steps = max(6, Int(abs(a1 - a0) / (2 * .pi) * 120))
                    for k in 0...steps { let a = a0 + (a1 - a0) * Double(k) / Double(steps); k == 0 ? p.move(to: point(cy, outer, a)) : p.addLine(to: point(cy, outer, a)) }
                    for k in (0...steps).reversed() { p.addLine(to: point(cy, inner, a0 + (a1 - a0) * Double(k) / Double(steps))) }
                    p.closeSubpath()
                    return p
                }
                func ring(_ cy: Double, _ r: Double, _ a0: Double = 0, _ a1: Double = 2 * .pi) -> Path {
                    var p = Path()
                    for k in 0...120 { let a = a0 + (a1 - a0) * Double(k) / 120; k == 0 ? p.move(to: point(cy, r, a)) : p.addLine(to: point(cy, r, a)) }
                    return p
                }
                let full = 2 * Double.pi

                // Base: a dark disc split into segments, slowly turning
                let base = t * 0.18
                ctx.fill(band(170, 24, 44, 0, full), with: .color(ink.opacity(0.13)))
                for k in 0..<8 {
                    let a = base + full * Double(k) / 8
                    var spoke = Path(); spoke.move(to: point(170, 24, a)); spoke.addLine(to: point(170, 44, a))
                    ctx.stroke(spoke, with: .color(paper), lineWidth: HomeLines.width)
                }

                layer = 1
                // Fine ring, turning the other way, with a short bright stretch
                let fine = -t * 0.32
                ctx.stroke(ring(150, 38), with: .color(ink.opacity(0.45)), lineWidth: HomeLines.width)
                ctx.stroke(ring(150, 38, fine, fine + 1.1), with: .color(ink.opacity(0.9)), lineWidth: HomeLines.width)

                layer = 2
                // Dashed ring
                let dash = t * 0.55
                for k in 0..<28 {
                    let a = dash + full * Double(k) / 28
                    ctx.stroke(ring(128, 52, a, a + full / 28 * 0.6), with: .color(ink.opacity(0.5)), lineWidth: HomeLines.width)
                }

                layer = 3
                // Thin ring with a few gaps, turning back
                let thin = -t * 0.24
                for k in 0..<3 {
                    let a = thin + full * Double(k) / 3
                    ctx.stroke(ring(104, 66, a + 0.08, a + full / 3 - 0.08), with: .color(ink.opacity(0.6)), lineWidth: HomeLines.width)
                }

                layer = 4
                // Top dial
                let top = t * 0.2
                let cy = 72.0
                ctx.stroke(ring(cy, 81), with: .color(ink.opacity(0.3)), lineWidth: HomeLines.width)
                ctx.fill(band(cy, 66, 78, 0, full), with: .color(ink.opacity(0.14)))
                // The bright arc, split into segments, filled to the value
                let segments = 5
                let span = full * Self.value
                for k in 0..<segments {
                    let a0 = top + span * Double(k) / Double(segments) + 0.02
                    let a1 = top + span * Double(k + 1) / Double(segments) - 0.02
                    ctx.fill(band(cy, 66, 78, a0, a1), with: .color(ink.opacity(0.95)))
                }
                // Segmented inner band, turning the other way
                let inner = -t * 0.35
                for k in 0..<10 {
                    let a = inner + full * Double(k) / 10
                    ctx.fill(band(cy, 54, 61, a + 0.03, a + full / 10 - 0.03), with: .color(ink.opacity(k % 3 == 0 ? 0.42 : 0.2)))
                }
                // Numbers round the dial, riding with it
                for k in 0..<6 {
                    let a = top + full * Double(k) / 6
                    let p = point(cy, 84, a)
                    let text = Text("\(k * 10)").font(.system(size: 6.5, weight: .semibold)).foregroundStyle(ink.opacity(0.75))
                    ctx.draw(text, at: p)
                }

            }
        }
    }
}

// MARK: - Smoke ring (reference screenshot)

/// A ring of smoke made of thousands of fine particles in depth, like Siri's glow. The particles lie along dozens
/// of strands that wind round the ring; in some places the strands bunch into a bright, dense band and elsewhere
/// they fan apart and curl through the ring's depth into wisps. The whole ring turns while the strands keep
/// swirling and warping, so the bright knots and smoky curls drift round and reshape.
private struct SmokeRingPattern: View {
    private static let strands = 110
    private static let segments = 160
    private static let centre = CGPoint(x: 93, y: 96)
    private static let radius = 66.0

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            Canvas { ctx, _ in
                let spin = t * 0.22
                // Nearly face-on, like the reference, with enough tip to show the wisps' depth
                let tilt = 0.22 + 0.08 * sin(t * 0.17)
                let (ct, st) = (cos(tilt), sin(tilt))
                var near = Path(), far = Path()

                for s in 0..<Self.strands {
                    let phase = Double(s) * 2.39996   // golden angle, so strands spread evenly
                    let lane = Double(s) / Double(Self.strands - 1) - 0.5
                    var previous: (CGPoint, Bool)?
                    for k in 0...Self.segments {
                        let a = 2 * .pi * Double(k) / Double(Self.segments)
                        // How far the strands fan apart here: a tight bright band in places, smoky wisps elsewhere
                        let fan = 0.5 + 0.5 * sin(2 * a - t * 0.45 + 0.8 * sin(3 * a + t * 0.3))
                        let spread = 0.12 + 0.88 * fan * fan
                        // Each strand weaves on its own, warping over time
                        let swirl = sin(3 * a + t * 0.9 + phase) * 0.6 + sin(5 * a - t * 1.3 + phase * 1.7) * 0.4
                        // Curls: here and there a few strands peel off inward and back, like smoke folding over
                        let curl = pow(max(0, sin(3 * a + t * 0.5 + phase * 0.3)), 6) * sin(phase * 3 + t)
                        let radial = Self.radius * (1 + 0.04 * sin(4 * a + t * 0.6)
                                                    + spread * (0.26 * lane + 0.1 * swirl) - 0.22 * curl * spread)
                        let height = Self.radius * spread * (0.45 * lane + 0.25 * sin(2 * a + t * 1.1 + phase))
                        let angle = a + spin + 0.08 * spread * swirl
                        let x = radial * cos(angle), y = radial * sin(angle), z = height
                        let y2 = y * ct - z * st, z2 = y * st + z * ct
                        let p = CGPoint(x: Self.centre.x + x, y: Self.centre.y + y2)
                        let isNear = z2 > -4
                        if let previous {
                            var segment = Path()
                            segment.move(to: previous.0)
                            segment.addLine(to: p)
                            if isNear { near.addPath(segment) } else { far.addPath(segment) }
                        }
                        previous = (p, isNear)
                    }
                }

                ctx.blendMode = .plusLighter
                // A soft glow under the filaments, so dense bands bloom like smoke
                ctx.drawLayer { glow in
                    glow.addFilter(.blur(radius: 5))
                    glow.stroke(near, with: .color(Color.white.opacity(0.22)), lineWidth: 2.2)
                }
                ctx.stroke(far, with: .color(Color.white.opacity(0.12)), lineWidth: 0.4)
                ctx.stroke(near, with: .color(Color.white.opacity(0.34)), lineWidth: 0.45)
            }
        }
    }
}

/// Grows its content from a small dot to full size when it first appears, with a soft spring
private struct GrowIn<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var grown = false

    var body: some View {
        content
            .scaleEffect(grown ? 1 : 0.12)
            .opacity(grown ? 1 : 0.4)
            .onAppear {
                withAnimation(.spring(response: 2.4, dampingFraction: 0.85).delay(0.4)) { grown = true }
            }
    }
}

/// One line weight shared by the ring stack, the loops and the line gear, so their outlines match
enum HomeLines {
    static let width: CGFloat = 0.9
}

// MARK: - Gear and screw in lines

/// The 3D gear-and-worm widget redrawn in the home widgets' fine-line style: the same 20-tooth gear with its keyed
/// bore, meshed with a worm screw running up to the right. Same layout and the same motion as the 3D one: the
/// screw's threads run up its length one pitch every 0.55 s and the gear turns one tooth with each thread. Every
/// edge is traced with a few hair-thin parallel lines instead of being shaded.
private struct LineGearPattern: View {
    var ink: Color = .black
    /// The card colour, used to hide the gear behind the screw's threads
    var paper: Color = .white

    private static let teeth = 20
    /// Gear centre and tip radius in the card; the 3D model's units map to `unit` points
    private static let centre = CGPoint(x: 74, y: 80)
    private static let unit = 52.0
    private static let tip = 1.0, root = 0.82, pitchRadius = 0.91
    private static let threadPeriod = 0.55
    /// Where the screw touches the gear (lower right), and the direction it runs (up to the right)
    private static let contact = 0.72
    /// The gear is seen turned a little, so it reads slightly narrower than tall
    private static let squash = 0.9

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            let cycle = t / Self.threadPeriod
            Canvas { ctx, _ in
                drawGear(&ctx, turn: -cycle * 2 * .pi / Double(Self.teeth))
                drawWorm(&ctx, advance: cycle.truncatingRemainder(dividingBy: 1))
            }
        }
    }

    // MARK: Gear

    private func gearPoint(_ r: Double, _ a: Double, shift: CGPoint = .zero) -> CGPoint {
        CGPoint(x: Self.centre.x + shift.x + r * Self.unit * cos(a) * Self.squash, y: Self.centre.y + shift.y + r * Self.unit * sin(a))
    }

    /// The tooth outline at a scale, turned by `turn`
    private func toothOutline(scale k: Double, turn: Double, shift: CGPoint = .zero) -> Path {
        var path = Path()
        let step = 2 * Double.pi / Double(Self.teeth)
        for i in 0..<Self.teeth {
            let a0 = Double(i) * step + turn
            let corners: [(Double, Double)] = [
                (Self.root, a0), (Self.tip, a0 + step * 0.18), (Self.tip, a0 + step * 0.42),
                (Self.root, a0 + step * 0.6), (Self.root, a0 + step),
            ]
            for (n, c) in corners.enumerated() {
                let p = gearPoint(c.0 * k, c.1, shift: shift)
                if i == 0 && n == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
        }
        path.closeSubpath()
        return path
    }

    /// The bore with its key notch
    private func bore(scale k: Double, turn: Double, shift: CGPoint = .zero) -> Path {
        var path = Path()
        let r = 0.42 * k, keyAngle = -0.5 + turn, half = asin(0.1 / 0.42)
        let steps = 60
        for n in 0...steps {
            let a = keyAngle + half + (2 * .pi - 2 * half) * Double(n) / Double(steps)
            let p = gearPoint(r, a, shift: shift)
            if n == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.addLine(to: gearPoint(0.54 * k, keyAngle - half * 0.75, shift: shift))
        path.addLine(to: gearPoint(0.54 * k, keyAngle + half * 0.75, shift: shift))
        path.closeSubpath()
        return path
    }

    private func drawGear(_ ctx: inout GraphicsContext, turn: Double) {
        // Its thickness: the back face traced faintly, a little up and to the left
        let back = CGPoint(x: -7, y: -3)
        ctx.stroke(toothOutline(scale: 1, turn: turn, shift: back), with: .color(ink.opacity(0.3)), lineWidth: HomeLines.width)
        ctx.stroke(bore(scale: 1, turn: turn, shift: back), with: .color(ink.opacity(0.3)), lineWidth: HomeLines.width)
        // Front face, so it hides the back one, then traced with a few close parallel lines
        ctx.fill(toothOutline(scale: 1, turn: turn), with: .color(paper))
        for (k, alpha) in [(1.0, 0.95), (0.965, 0.45), (0.93, 0.25)] {
            ctx.stroke(toothOutline(scale: k, turn: turn), with: .color(ink.opacity(alpha)), lineWidth: HomeLines.width)
        }
        ctx.fill(bore(scale: 1, turn: turn), with: .color(paper))
        for (k, alpha) in [(1.0, 0.95), (1.08, 0.4), (1.16, 0.2)] {
            ctx.stroke(bore(scale: k, turn: turn), with: .color(ink.opacity(alpha)), lineWidth: HomeLines.width)
        }
        // Fine rings on the face between the bore and the teeth
        for r in stride(from: 0.58, through: 0.76, by: 0.06) {
            var ring = Path()
            ring.addEllipse(in: CGRect(x: Self.centre.x - r * Self.unit * Self.squash, y: Self.centre.y - r * Self.unit,
                                       width: 2 * r * Self.unit * Self.squash, height: 2 * r * Self.unit))
            ctx.stroke(ring, with: .color(ink.opacity(0.18)), lineWidth: HomeLines.width)
        }
    }

    // MARK: Worm

    private func drawWorm(_ ctx: inout GraphicsContext, advance: Double) {
        let u = Self.unit
        let radial = CGPoint(x: cos(Self.contact), y: sin(Self.contact))
        let mid = CGPoint(x: Self.centre.x + radial.x * (Self.pitchRadius + 0.3) * u * Self.squash,
                          y: Self.centre.y + radial.y * (Self.pitchRadius + 0.3) * u)
        // Runs up to the right; `across` is perpendicular to it
        let along = CGPoint(x: radial.y, y: -radial.x)
        let across = CGPoint(x: radial.x, y: radial.y)
        let pitch = 2 * Double.pi * Self.pitchRadius / Double(Self.teeth) * u
        let core = 0.21 * u, crest = 0.4 * u
        let half = 160.0

        // Core rod: two long edges
        for side in [-1.0, 1.0] {
            var edge = Path()
            edge.move(to: CGPoint(x: mid.x - along.x * half + across.x * core * side, y: mid.y - along.y * half + across.y * core * side))
            edge.addLine(to: CGPoint(x: mid.x + along.x * half + across.x * core * side, y: mid.y + along.y * half + across.y * core * side))
            ctx.stroke(edge, with: .color(ink.opacity(0.8)), lineWidth: HomeLines.width)
        }

        // Thread crests: flat discs seen nearly edge-on, leaning with the thread, sliding up the rod
        let count = Int(2 * half / pitch) + 2
        for n in 0..<count {
            let offset = -half + (Double(n) + advance) * pitch
            let c = CGPoint(x: mid.x + along.x * offset, y: mid.y + along.y * offset)
            let lean = 0.32
            let disc = Path(ellipseIn: CGRect(x: -crest, y: -crest * lean, width: 2 * crest, height: 2 * crest * lean))
            let angle = atan2(across.y, across.x) + 0.12
            let placed = disc.applying(CGAffineTransform(rotationAngle: angle).concatenating(CGAffineTransform(translationX: c.x, y: c.y)))
            ctx.fill(placed, with: .color(paper))
            for (k, alpha) in [(1.0, 0.95), (0.82, 0.45), (0.64, 0.25)] {
                let inner = Path(ellipseIn: CGRect(x: -crest * k, y: -crest * lean * k, width: 2 * crest * k, height: 2 * crest * lean * k))
                ctx.stroke(inner.applying(CGAffineTransform(rotationAngle: angle).concatenating(CGAffineTransform(translationX: c.x, y: c.y))),
                           with: .color(ink.opacity(alpha)), lineWidth: HomeLines.width)
            }
        }
    }
}

// MARK: - Thread tunnel (reference screenshot)

/// A bundle of loose, hand-drawn loops round an oval opening, like a light-painting traced in one long swirl
/// (reference screenshot): each loop is a slightly tilted, wobbly ellipse, a little off-centre from the others,
/// so they cross and stack into a thick, layered ring. The innermost loops are the strongest and the outer ones
/// thinner and fainter. It keeps zooming in slowly: loops widen outward and fade while new ones form at the
/// opening, and every loop keeps gently wavering.
private struct ThreadTunnelPattern: View {
    var ink: Color = .white

    private static let count = 17
    private static let centre = CGPoint(x: 93, y: 98)
    /// The opening: an oval a little wider than tall, tipped down to the left
    private static let opening = (rx: 40.0, ry: 34.0)
    private static let tilt = -0.42
    /// Loops grow from the opening to this many times its size before fading
    private static let largest = 2.25
    private static let life = 22.0
    /// When the widget first appeared: it starts with a few loops and fills in to full intensity
    @State private var start = Date.now

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            // Starts once the rings are up, then loops join one by one, about one every 0.4 s
            let intro = min(1, max(0, (context.date.timeIntervalSince(start) - 6.0) / 5.5))
            let shown = 3 + (Double(Self.count) - 3) * intro
            Canvas { ctx, _ in
                var loops: [(path: Path, strength: Double)] = []
                for i in 0..<Self.count {
                    let seed = Double(i)
                    // Loops join in a scattered order, each fading in as it arrives
                    let order = Double((i * 7) % Self.count)
                    let arrive = min(1, max(0, shown - order))
                    guard arrive > 0 else { continue }
                    let age = (seed / Double(Self.count) + t / Self.life).truncatingRemainder(dividingBy: 1)
                    let grow = 1 + (Self.largest - 1) * age
                    // Each loop is a touch off-centre and tipped its own way, so the loops cross and stack
                    let drift = 5 + 9 * age
                    let off = CGPoint(x: drift * cos(seed * 2.4 + t * 0.2), y: drift * sin(seed * 2.4 + t * 0.2))
                    let tip = Self.tilt + 0.18 * sin(seed * 1.7)
                    var path = Path()
                    let steps = 96
                    for k in 0...steps {
                        let a = 2 * .pi * Double(k) / Double(steps)
                        // Hand-drawn waver along the loop
                        let waver = 1 + 0.025 * sin(3 * a + seed * 1.3 + t * 0.7) + 0.008 * sin(7 * a - seed + t * 1.1)
                        let x = Self.opening.rx * grow * waver * cos(a)
                        let y = Self.opening.ry * grow * waver * sin(a)
                        let p = CGPoint(x: Self.centre.x + off.x + x * cos(tip) - y * sin(tip),
                                        y: Self.centre.y + off.y + x * sin(tip) + y * cos(tip))
                        if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
                    }
                    // Strongest at the opening, fading as the loops widen
                    let strength = min(1, age / 0.05) * pow(1 - age, 1.4)
                    loops.append((path, strength * arrive))
                }
                for loop in loops {
                    ctx.stroke(loop.path, with: .color(ink.opacity(0.85 * loop.strength)), lineWidth: HomeLines.width)
                }
            }
        }
    }
}

// MARK: - Rotating dot sphere

/// A ball of fine dots laid along stacked rings, pole to pole, slowly turning. Soft waves run round it like sound
/// along a string and swell and fade like a voice, so the surface keeps gently rippling; the near side of the ball
/// is drawn stronger than the far side, so it reads in depth.
private struct DotSpherePattern: View {
    var ink: Color = .white

    private static let rings = 64
    private static let dotsPerRing = 150
    private static let centre = CGPoint(x: 93, y: 96)
    private static let radius = 68.0

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            Canvas(rendersAsynchronously: true) { ctx, _ in
                var front = Path(), back = Path()
                // Loudness: a slow swell with a quicker flutter on top
                let loud = 0.75 + 0.25 * sin(t * 0.9) * sin(t * 0.37 + 1)
                // Seen from a little above the equator, turning slowly about the vertical
                let tilt = 0.45 + 0.08 * sin(t * 0.21)
                let spin = t * 0.16
                let (ct, st) = (cos(tilt), sin(tilt))
                let (cs, ss) = (cos(spin), sin(spin))
                for ring in 0..<Self.rings {
                    let v = .pi * (Double(ring) + 0.5) / Double(Self.rings)
                    let sv = sin(v), cv = cos(v)
                    for k in 0..<Self.dotsPerRing {
                        let u = 2 * .pi * Double(k) / Double(Self.dotsPerRing)
                        let wave = loud * sv * (0.06 * sin(3 * u - t * 1.9 + v * 2.2)
                                              + 0.035 * sin(5 * u + t * 1.3 - v * 3.1)
                                              + 0.025 * sin(6 * v - t * 2.4 + u))
                        let r = Self.radius * (1 + wave)
                        let x0 = sv * cos(u), y0 = cv, z0 = sv * sin(u)
                        let x1 = x0 * cs + z0 * ss, z1 = -x0 * ss + z0 * cs
                        let y2 = y0 * ct - z1 * st, z2 = y0 * st + z1 * ct
                        let p = CGPoint(x: Self.centre.x + r * x1, y: Self.centre.y + r * y2)
                        let dot = CGRect(x: p.x - 0.35, y: p.y - 0.35, width: 0.7, height: 0.7)
                        if z2 >= 0 { front.addEllipse(in: dot) } else { back.addEllipse(in: dot) }
                    }
                }
                ctx.fill(back, with: .color(ink.opacity(0.22)))
                ctx.fill(front, with: .color(ink.opacity(0.75)))
            }
        }
    }
}

// MARK: - Sound-wave sphere (reference image)

/// A glowing sphere spun from thread, on black. Inside, a fine dot lattice wraps the face of the sphere, thinning
/// towards the middle and crowding at the edge, with a slow swirl running through it. Round the rim, ribbons of
/// hair-thin threads ripple like a sound wave: each ribbon pinches and swells as it twists, and the ribbons cross
/// over each other as their waves drift. The waves swell and fade like a voice, so it never quite settles.
private struct WaveSpherePattern: View {
    /// Colour of the dots and threads
    var ink: Color = .white

    private static let centre = CGPoint(x: 93, y: 96)
    private static let radius = 70.0
    private static let ribbons = 4
    private static let threadsPerRibbon = 14
    private static let ribbonWidth = 9.0
    private static let segments = 160

    /// Lattice points across the unit disc: position, distance from the middle and angle
    private static let lattice: [(x: Double, y: Double, r: Double, a: Double)] = {
        let n = 56
        var points: [(Double, Double, Double, Double)] = []
        for i in 0..<n {
            for j in 0..<n {
                let x = -1 + 2 * Double(i) / Double(n - 1), y = -1 + 2 * Double(j) / Double(n - 1)
                let r = (x * x + y * y).squareRoot()
                if r < 0.997 { points.append((x, y, r, atan2(y, x))) }
            }
        }
        return points
    }()

    /// The ripple round the sphere for a given angle; `phase` gives each ribbon its own
    private static func ripple(_ a: Double, _ t: Double, _ phase: Double, _ loud: Double) -> Double {
        loud * (0.045 * sin(3 * a + t * 1.2 + phase) + 0.03 * sin(5 * a - t * 0.9 + 2 * phase) + 0.02 * sin(2 * a + t * 0.6 - phase))
    }

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            Canvas(rendersAsynchronously: true) { ctx, _ in
                let c = Self.centre, R = Self.radius
                // Loudness: a slow swell with a quicker flutter on top, like a voice
                let loud = 0.85 + 0.3 * sin(t * 0.9) * sin(t * 0.37 + 1)

                // Lattice: wrapped onto the sphere's face (so it crowds at the edge), swirled, and rippled at the rim
                var dim = Path(), mid = Path(), bright = Path()
                for p in Self.lattice {
                    let swirl = 0.35 * sin(p.r * 3.2 - t * 0.8) * p.r * p.r
                    let (cw, sw) = (cos(swirl), sin(swirl))
                    let x = p.x * cw - p.y * sw, y = p.x * sw + p.y * cw
                    let wrap = sin(p.r * .pi / 2) / max(p.r, 1e-6)
                    let k = (1 + pow(p.r, 4) * Self.ripple(p.a, t, 0, loud)) * wrap
                    let dot = CGRect(x: c.x + R * x * k - 0.3, y: c.y + R * y * k - 0.3, width: 0.6, height: 0.6)
                    if p.r < 0.6 { dim.addRect(dot) } else if p.r < 0.85 { mid.addRect(dot) } else { bright.addRect(dot) }
                }
                ctx.fill(dim, with: .color(ink.opacity(0.42)))
                ctx.fill(mid, with: .color(ink.opacity(0.55)))
                ctx.fill(bright, with: .color(ink.opacity(0.72)))

                // Rim: ribbons of fine threads, each twisting as its width pinches and swells round the circle
                for ribbon in 0..<Self.ribbons {
                    let phase = Double(ribbon) * 1.7
                    for thread in 0..<Self.threadsPerRibbon {
                        let f = Double(thread) / Double(Self.threadsPerRibbon - 1)
                        var path = Path()
                        for k in 0...Self.segments {
                            let a = 2 * .pi * Double(k) / Double(Self.segments)
                            let width = Self.ribbonWidth * (0.15 + 0.85 * abs(sin(1.5 * a + t * 0.5 + phase)))
                            let r = R * (1 + Self.ripple(a, t, phase, loud)) - width * f
                            let point = CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
                            if k == 0 { path.move(to: point) } else { path.addLine(to: point) }
                        }
                        ctx.stroke(path, with: .color(ink.opacity(0.22 * (1 - 0.5 * f))), lineWidth: 0.35)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeV5View()
}




