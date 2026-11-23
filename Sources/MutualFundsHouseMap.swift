import SwiftUI

/// Figma "Frame 2147225407" (15:6337, file `sub7vIn6sMBlHb4SIWHyek`): the fund houses as a map, edge to edge and
/// 463 tall. Four columns, each narrower than the last and cut into more cells, so a house's cell says how big it
/// is; inside it sit the logo, the name where there is room, and what the house has returned, in green or red.
///
/// It arrives when the page opens: the cells settle into place one after another, from the top of the widest
/// column to the foot of the narrowest, each logo landing just after its cell, and the seams ink in last. With
/// Reduce Motion on it is simply there.
///
/// Its figures move like a market board's. As a cell arrives its figure rolls up from 0.0%, and after that a few
/// figures at a time tick a tenth or so up or down, the digits rolling the way the figure went. A figure never
/// strays more than 0.6 from the one the frame draws, and keeps the colour it is drawn in. The ticking stops while
/// the map is scrolled out of sight, and with Reduce Motion on the figures stand still.
///
/// It is handled like a map. A pinch opens it up to four times over, about the point pinched; once it is open, a
/// drag moves it under the finger, to the houses on the right or anywhere else, and a flick carries it on. Opening
/// it makes the cells bigger, not what is in them: a cell that has grown wide and tall enough takes the fuller
/// layout of a bigger column, so the narrowest cells gain room around their logos, then the names. Closed, at its
/// first size, it is the frame exactly, and a drag on it scrolls the page.
struct MutualFundsHouseMap: View {
    /// One fund house's cell
    struct House: Identifiable {
        let id: Int
        let name: String
        /// The logo, an image set's name
        let logo: String
        /// What it has returned, in percent, as the frame draws it
        let returned: Double
        /// Green if it is up, red if it is down
        var up = true
        /// Drawn on the sunken surface, not the white one
        var sunken = false
    }

    /// How a cell is laid out: by the column it is in, or a fuller one once the map is opened up
    enum Size: Int, Comparable {
        static func < (a: Size, b: Size) -> Bool { a.rawValue < b.rawValue }

        /// 44 wide (15:6432): logo and return side by side
        case tiny
        /// 81 wide (15:6401): logo and return
        case small
        /// 96 wide (15:6364): logo, name, return
        case medium
        /// 165 wide (15:6339): the same, larger
        case large
    }

    struct Column: Identifiable {
        let id: Int
        let size: Size
        /// Its width in the 390 pt frame
        let width: CGFloat
        let houses: [House]
    }

    /// The frame's four columns, with every cell's surface and colour as drawn
    static let columns: [Column] = [
        Column(id: 0, size: .large, width: 165, houses: [
            House(id: 0, name: "SBI", logo: "MFHomeSBI", returned: 22.8),
            House(id: 1, name: "ICICI Prudential", logo: "MFHomeICICI", returned: 26.4, up: false, sunken: true),
            House(id: 2, name: "HDFC", logo: "MFHomeHDFC", returned: 24.6),
            House(id: 3, name: "Nippon India", logo: "MFHomeNippon", returned: 27.1),
        ]),
        Column(id: 1, size: .medium, width: 96, houses: [
            House(id: 4, name: "Kotak", logo: "MFHomeKotak", returned: 21.3),
            House(id: 5, name: "Aditya Birla", logo: "MFHomeAdityaBirla", returned: 18.9, up: false, sunken: true),
            House(id: 6, name: "UTI", logo: "MFHomeUTI", returned: 17.4),
            House(id: 7, name: "Axis", logo: "MFHomeAxis", returned: 15.2, up: false, sunken: true),
            House(id: 8, name: "Mirae Asset", logo: "MFHomeMirae", returned: 19.7, up: false, sunken: true),
            House(id: 9, name: "DSP", logo: "MFHomeDSP", returned: 23.5, up: false, sunken: true),
        ]),
        Column(id: 2, size: .small, width: 81, houses: [
            House(id: 10, name: "Tata", logo: "MFHomeTata", returned: 20.6, sunken: true),
            House(id: 11, name: "Bandhan", logo: "MFHomeBandhan", returned: 28.3),
            House(id: 12, name: "Franklin Templeton", logo: "MFHomeFranklin", returned: 22.1, up: false, sunken: true),
            House(id: 13, name: "HSBC", logo: "MFHomeHSBC", returned: 16.8),
            House(id: 14, name: "Canara Robeco", logo: "MFHomeCanara", returned: 14.9),
            House(id: 15, name: "Invesco", logo: "MFHomeInvesco", returned: 25.2),
        ]),
        Column(id: 3, size: .tiny, width: 44, houses: [
            House(id: 16, name: "PPFAS", logo: "MFHomePPFAS", returned: 8.4),
            House(id: 17, name: "Motilal Oswal", logo: "MFHomeMotilal", returned: 9.6),
            House(id: 18, name: "Edelweiss", logo: "MFHomeEdelweiss", returned: 7.1),
            House(id: 19, name: "Sundaram", logo: "MFHomeSundaram", returned: 5.3),
            House(id: 20, name: "quant", logo: "MFHomeQuant", returned: 3.9, up: false, sunken: true),
            House(id: 21, name: "Baroda BNP Paribas", logo: "MFHomeBaroda", returned: 6.2, up: false, sunken: true),
            House(id: 22, name: "LIC", logo: "MFHomeLIC", returned: 4.4, up: false, sunken: true),
            House(id: 23, name: "Mahindra Manulife", logo: "MFHomeMahindra", returned: 7.8, up: false, sunken: true),
            House(id: 24, name: "PGIM India", logo: "MFHomePGIM", returned: 2.7, sunken: true),
            House(id: 25, name: "Union", logo: "MFHomeUnion", returned: 5.9),
            House(id: 26, name: "360 ONE", logo: "MFHomeThreeSixtyOne", returned: 6.6),
            House(id: 27, name: "Bajaj Finserv", logo: "MFHomeBajaj", returned: 8.1),
            House(id: 28, name: "WhiteOak Capital", logo: "MFHomeWhiteOak", returned: 9.2),
            House(id: 29, name: "JM Financial", logo: "MFHomeJM", returned: 4.8),
            House(id: 30, name: "Navi", logo: "MFHomeNavi", returned: 3.1),
            House(id: 31, name: "Groww", logo: "MFHomeGroww", returned: 5.5),
        ]),
    ]

    private static let seam: CGFloat = 1 // Gap: the map's seams are 1 pt, not the hairline
    private static let seamInk = Color(hex: 0x8C8886) // Gap: ivory/500, the seams' colour, has no semantic token
    private static let upInk = Color(hex: 0x00A800) // Gap: utility-green/500 has no semantic token
    private static let downInk = Color(hex: 0xF0453A) // Gap: utility-red/500 has no semantic token

    /// The cells have been let in
    @State private var shown = false
    /// Every cell has arrived, so a figure that changes now rolls at once
    @State private var ticking = false
    /// Where each figure has ticked to, by house; one that has not moved yet is as drawn
    @State private var ticks: [Int: Double] = [:]
    /// Some of the map is on screen
    @State private var visible = true
    /// How far the map is opened up: 1 is the frame, `mostOpen` the limit
    @State private var zoom: CGFloat = 1
    /// The point of the opened map at the window's top-leading corner
    @State private var pan: CGPoint = .zero
    /// Where a pinch began, and where a drag did
    @State private var pinchStart: (zoom: CGFloat, pan: CGPoint)?
    @State private var dragStart: CGPoint?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The map's height in the frame
    private static let height: CGFloat = 463
    private static let mostOpen: CGFloat = 4
    private static let rest = Animation.spring(response: 0.42, dampingFraction: 0.86)

    var body: some View {
        GeometryReader { geo in
            let window = CGSize(width: geo.size.width, height: Self.height)
            let sheet = CGSize(width: window.width * zoom, height: window.height * zoom)
            let corner = Self.held(pan, zoom: zoom, window: window)
            board(sheet)
                .frame(width: sheet.width, height: sheet.height, alignment: .topLeading)
                .background {
                    // The seams are the ground showing between the cells; they come in once the cells have settled
                    Self.seamInk
                        .opacity(shown ? 1 : 0)
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.45).delay(0.6), value: shown)
                }
                .offset(x: -corner.x, y: -corner.y)
                .frame(width: window.width, height: window.height, alignment: .topLeading)
                .clipped()
                .contentShape(Rectangle())
                // Closed, a drag is the page's; opened, it moves the map
                .gesture(drag(in: window), isEnabled: zoom > 1)
                .simultaneousGesture(pinch(in: window))
                .accessibilityZoomAction { action in
                    let next = action.direction == .zoomIn ? min(zoom * 2, Self.mostOpen) : max(zoom / 2, 1)
                    open(to: next, about: CGPoint(x: window.width / 2, y: window.height / 2), in: window)
                }
        }
        .frame(height: Self.height)
        .onScrollVisibilityChange(threshold: 0.05) { visible = $0 }
        .task(id: visible) {
            guard visible else { return }
            if !shown {
                // A beat after the page is up, so the first cells are seen arriving
                try? await Task.sleep(for: .milliseconds(180))
                shown = true
                // and the last figure has rolled up before any of them ticks
                try? await Task.sleep(for: .milliseconds(1400))
                ticking = true
            }
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(Int.random(in: 350...900)))
                if Task.isCancelled { break }
                tick()
            }
        }
    }

    // MARK: The board

    /// The four columns laid out on a sheet of the given size. The frame is 390 across: 386 of cells and four seams,
    /// none at the trailing edge; a wider sheet widens the columns in proportion, and the seams stay 1 pt.
    private func board(_ sheet: CGSize) -> some View {
        let widen = (sheet.width - 4 * Self.seam) / 386
        return HStack(alignment: .top, spacing: Self.seam) {
            ForEach(Self.columns) { column in
                VStack(spacing: Self.seam) {
                    ForEach(Array(column.houses.enumerated()), id: \.element.id) { row, house in
                        let size = CGSize(width: column.width * widen, height: cellHeight(column, row: row, sheet: sheet.height))
                        cell(house, layout(column, row: row), size: size, delay: delay(column: column.id, row: row, size: column.size))
                            .frame(width: size.width, height: size.height)
                    }
                }
            }
        }
        .padding(.leading, Self.seam)
        .padding(.vertical, Self.seam)
    }

    /// A cell's height in the 463 pt frame. 15:6339: the first of the widest column is 140 tall and the rest of
    /// that column share what is left; the other columns are cut evenly.
    private static func drawnHeight(_ column: Column, row: Int) -> CGFloat {
        let inside = height - 2 * seam - CGFloat(column.houses.count - 1) * seam
        guard column.size == .large else { return inside / CGFloat(column.houses.count) }
        return row == 0 ? 140 : (inside - 140) / CGFloat(column.houses.count - 1)
    }

    /// The same on a sheet of another height: the seams stay 1 pt and the cells take the rest in proportion
    private func cellHeight(_ column: Column, row: Int, sheet: CGFloat) -> CGFloat {
        let seams = 2 * Self.seam + CGFloat(column.houses.count - 1) * Self.seam
        return Self.drawnHeight(column, row: row) * (sheet - seams) / (Self.height - seams)
    }

    /// The layout a cell takes: its column's own, or a fuller one once opening the map has made room for it.
    /// Measured in the frame's points, so it is the same on every screen.
    private func layout(_ column: Column, row: Int) -> Size {
        let width = column.width * zoom
        let height = Self.drawnHeight(column, row: row) * zoom
        let fits: Size = if width >= 150, height >= 100 { .large }
            else if width >= 90, height >= 72 { .medium }
            else if width >= 60, height >= 52 { .small }
            else { .tiny }
        return max(column.size, fits)
    }

    // MARK: Opening and moving

    /// Keeps the window inside the sheet. A sheet pinched smaller than the window sits in its middle.
    private static func held(_ pan: CGPoint, zoom: CGFloat, window: CGSize) -> CGPoint {
        let spare = CGSize(width: window.width * (zoom - 1), height: window.height * (zoom - 1))
        return CGPoint(
            x: spare.width < 0 ? spare.width / 2 : min(max(pan.x, 0), spare.width),
            y: spare.height < 0 ? spare.height / 2 : min(max(pan.y, 0), spare.height)
        )
    }

    /// Past either limit a pinch still gives a little, then the map springs back
    private static func giving(_ zoom: CGFloat) -> CGFloat {
        if zoom < 1 { return 1 - (1 - zoom) * 0.35 }
        if zoom > mostOpen { return mostOpen + (zoom - mostOpen) * 0.25 }
        return zoom
    }

    /// The pan that keeps the sheet's point under `anchor` where it is as the map goes from one zoom to another
    private static func pan(from start: (zoom: CGFloat, pan: CGPoint), to zoom: CGFloat, about anchor: CGPoint) -> CGPoint {
        CGPoint(
            x: (start.pan.x + anchor.x) / start.zoom * zoom - anchor.x,
            y: (start.pan.y + anchor.y) / start.zoom * zoom - anchor.y
        )
    }

    private func pinch(in window: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = pinchStart ?? (zoom, Self.held(pan, zoom: zoom, window: window))
                pinchStart = start
                dragStart = nil
                let next = Self.giving(start.zoom * value.magnification)
                zoom = next
                pan = Self.held(Self.pan(from: start, to: next, about: value.startLocation), zoom: next, window: window)
            }
            .onEnded { value in
                pinchStart = nil
                let settled = min(max(zoom, 1), Self.mostOpen)
                guard settled != zoom else { return }
                open(to: settled, about: value.startLocation, in: window)
            }
    }

    private func drag(in window: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                // Two fingers moving together are the pinch's
                guard pinchStart == nil else { return }
                let start = dragStart ?? Self.held(pan, zoom: zoom, window: window)
                dragStart = start
                pan = Self.held(CGPoint(x: start.x - value.translation.width, y: start.y - value.translation.height), zoom: zoom, window: window)
            }
            .onEnded { value in
                guard let start = dragStart else { return }
                dragStart = nil
                // A flick carries the map on to where it would have come to rest
                let thrown = CGPoint(x: start.x - value.predictedEndTranslation.width, y: start.y - value.predictedEndTranslation.height)
                withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.92)) {
                    pan = Self.held(thrown, zoom: zoom, window: window)
                }
            }
    }

    /// Brings the map to a zoom, keeping the point under `anchor` where it is
    private func open(to next: CGFloat, about anchor: CGPoint, in window: CGSize) {
        let start = (zoom, Self.held(pan, zoom: zoom, window: window))
        withAnimation(reduceMotion ? nil : Self.rest) {
            zoom = next
            pan = Self.held(Self.pan(from: start, to: next, about: anchor), zoom: next, window: window)
        }
    }

    // MARK: Ticking

    /// Moves one to three figures a tenth or so, each staying within 0.6 of the figure the frame draws
    private func tick() {
        let houses = Self.columns.flatMap(\.houses)
        for house in houses.shuffled().prefix(Int.random(in: 1...3)) {
            let now = ticks[house.id] ?? house.returned
            let step = Double(Int.random(in: 1...3)) / 10 * (Bool.random() ? 1 : -1)
            let next = abs(now + step - house.returned) > 0.6 ? now - step : now + step
            ticks[house.id] = max(0.1, (next * 10).rounded() / 10)
        }
    }

    static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    /// A house's figure: 0.0% until its cell is let in, then as drawn, then wherever it has ticked to. The digits
    /// roll up or down with the figure.
    private func figure(_ house: House, size: CGFloat, lineHeight: CGFloat, delay: Double) -> some View {
        let value = shown ? ticks[house.id] ?? house.returned : 0
        return GapText(Self.percent(value), family: .walsheim, medium: false, size: size, lineHeight: lineHeight, color: house.up ? Self.upInk : Self.downInk)
            .fixedSize()
            .contentTransition(.numericText(value: value))
            .animation(reduceMotion ? nil : ticking ? .snappy(duration: 0.4) : .snappy(duration: 0.55).delay(delay + 0.18), value: value)
    }

    // MARK: Arriving

    /// When a cell starts: the columns follow one another, and the cells go down each of them
    private func delay(column: Int, row: Int, size: Size) -> Double {
        Double(column) * 0.09 + Double(row) * (size == .tiny ? 0.012 : 0.035)
    }

    private func settle(_ delay: Double) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.82).delay(delay)
    }

    /// The logo lands just after its cell, with a little give
    private func land(_ delay: Double) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.62).delay(delay + 0.12)
    }

    private func write(_ delay: Double) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.3).delay(delay + 0.18)
    }

    // MARK: Cells

    /// How far above its cell's foot a layout's stack ends in the frame
    private static func drawnFoot(_ layout: Size) -> CGFloat {
        switch layout {
        case .large: 23 // Gap: the stack ends 23 above the cell's foot, no spacing token
        case .medium: SpacingScale.spaceXs
        case .small: 11 // Gap: the stack ends 11 above the cell's foot, no spacing token
        case .tiny: 0
        }
    }

    /// How tall a layout's stack is: the logo, then its lines
    private static func stackHeight(_ layout: Size) -> CGFloat {
        switch layout {
        case .large: 69
        case .medium: 64
        case .small: 37
        case .tiny: 13
        }
    }

    /// Closed, a stack sits where the frame puts it, a fixed way above its cell's foot (in the frame the fourth
    /// wide cell's stack sits 23 higher, its logo cut off by the cell's top edge; here it sits where the other
    /// three do). As the map opens the stack moves to the middle of its growing cell, and is there by one and a half.
    private func foot(_ layout: Size, cell: CGSize) -> CGFloat {
        let opened = min(max((zoom - 1) / 0.5, 0), 1)
        let middle = (cell.height - Self.stackHeight(layout)) / 2
        return Self.drawnFoot(layout) + (middle - Self.drawnFoot(layout)) * opened
    }

    private func cell(_ house: House, _ layout: Size, size: CGSize, delay: Double) -> some View {
        (house.sunken ? ColorScale.surfaceSunken1 : ColorScale.surfaceWidget)
            .overlay(alignment: layout == .tiny ? .center : .bottom) {
                contents(house, layout, delay: delay)
                    .padding(.bottom, layout == .tiny ? 0 : foot(layout, cell: size))
                    // A cell that takes a fuller layout changes over, it does not jump
                    .transition(.opacity)
                    .id(layout)
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: layout)
            .clipped()
            .opacity(shown ? 1 : 0)
            .scaleEffect(shown ? 1 : 0.86)
            .animation(settle(delay), value: shown)
            .accessibilityElement(children: .ignore)
            // The figure as drawn: a ticking one would have VoiceOver reading it over and over
            .accessibilityLabel("\(house.name), \(house.up ? "up" : "down") \(Self.percent(house.returned))")
    }

    @ViewBuilder private func contents(_ house: House, _ size: Size, delay: Double) -> some View {
        switch size {
        case .large:
            VStack(spacing: 0) {
                logo(house, side: 33, delay: delay)
                // Lb2 on the 17 pt line the frame gives it (the token's line is 19)
                DsText(house.name, variant: .lb2)
                    .lineLimit(1)
                    .frame(height: 17)
                    .modifier(Written(shown: shown, animation: write(delay)))
                // Gap: P5 on its 19 pt line here, in a utility colour with no content token
                figure(house, size: 13, lineHeight: 19, delay: delay)
                    .modifier(Written(shown: shown, animation: write(delay)))
            }
        case .medium:
            VStack(spacing: 0) {
                logo(house, side: 25, delay: delay)
                // Gap: Rg 11/15 has no text style
                GapText(house.name, family: .walsheim, medium: false, size: 11, lineHeight: 15, color: ColorScale.contentPrimary)
                    .lineLimit(1)
                    .padding(.top, 3) // Gap: 3 under the logo, no spacing token
                    .modifier(Written(shown: shown, animation: write(delay)))
                // Gap: P5 on its 19 pt line here, in a utility colour with no content token
                figure(house, size: 13, lineHeight: 19, delay: delay)
                    .padding(.top, SpacingScale.space2xs)
                    .modifier(Written(shown: shown, animation: write(delay)))
            }
        case .small:
            VStack(spacing: 3) { // Gap: 3 under the logo, no spacing token
                logo(house, side: 19, delay: delay)
                // Gap: Rg 11/15 has no text style
                figure(house, size: 11, lineHeight: 15, delay: delay)
                    .modifier(Written(shown: shown, animation: write(delay)))
            }
        case .tiny:
            HStack(spacing: 0) {
                logo(house, side: 13, delay: delay)
                // Gap: Rg 10/13 has no text style
                figure(house, size: 10, lineHeight: 13, delay: delay)
                    .frame(maxWidth: .infinity)
                    .modifier(Written(shown: shown, animation: write(delay)))
            }
            .padding(.horizontal, 3) // Gap: 3 inside the narrowest cells, no spacing token
        }
    }

    private func logo(_ house: House, side: CGFloat, delay: Double) -> some View {
        FundHouseLogo(name: house.logo, side: side, bordered: false)
            .scaleEffect(shown ? 1 : 0.4)
            .animation(land(delay), value: shown)
    }
}

/// A cell's words come up into place as they fade in
private struct Written: ViewModifier {
    let shown: Bool
    let animation: Animation?

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 4)
            .animation(animation, value: shown)
    }
}

/// Figma "Logo" on its white tile (13:5780): one component, drawn 41 across in a row, 23 on a card and 33 down to
/// 13 in the map. Its radii and stroke are scaled with it, so none of them is a token. In the map the tile has no
/// stroke.
struct FundHouseLogo: View {
    /// The logo, an image set's name
    let name: String
    /// How wide the tile is
    let side: CGFloat
    /// Draws the tile's outline, as in the rows and cards
    var bordered = true

    var body: some View {
        let scale = side / 41
        let tile = RoundedRectangle(cornerRadius: 8.843 * scale, style: .continuous) // Gap: 8.843 at 41, the tile's radius, has no token
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 32.961 * scale, height: 32.961 * scale)
            .clipShape(RoundedRectangle(cornerRadius: 5.627 * scale, style: .continuous)) // Gap: 5.627 at 41, the logo's radius, has no token
            .frame(width: side, height: side)
            .background(tile.fill(ColorScale.surfaceWidget))
            .overlay {
                if bordered {
                    tile.strokeBorder(ColorScale.borderSubtle, lineWidth: 0.563 * scale) // Gap: the tile's 0.563 stroke at 41 is not the hairline
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    MutualFundsHouseMap()
}
