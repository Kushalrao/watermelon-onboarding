import SwiftUI

/// The analysis, kept in the chat once it's done (148:5911), 299 × 275: a wash of colour with "Analysed" over the
/// Decade wordmark, a line from the agent, and a way back into it
struct AnalysedCard: View {
    var name = AppUser.name
    let onView: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 29, style: .continuous)
        ZStack(alignment: .topLeading) {
            Color.white

            ZStack(alignment: .topLeading) {
                LinearGradient(stops: [
                    .init(color: Color(red: 1, green: 203 / 255, blue: 65 / 255), location: 0),
                    .init(color: Color(red: 1, green: 193 / 255, blue: 137 / 255), location: 0.91),
                    .init(color: Color(red: 248 / 255, green: 192 / 255, blue: 143 / 255), location: 1),
                ], startPoint: .leading, endPoint: .trailing)
                Text("Analysed")
                    .font(.custom("RecklessStandardS-TRIAL-SemiBold", fixedSize: 39))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFF8ED), .white], startPoint: .leading, endPoint: .trailing))
                    .shadow(color: Color.black.opacity(0.25), radius: 22, x: 0, y: 2)
                    .frame(height: 51)
                    .at(17, 13)
                Image("DecadeWordmarkBrown")
                    .frame(width: 129, height: 25)
                    .at(17, 107)
            }
            .frame(width: 299, height: 149, alignment: .topLeading)
            .clipped()

            Text("\(name), I have analyzed the requested fund for you.")
                .font(FigmaFont.walsheim(15))
                .lineSpacing(21 - 15 * 1.2)
                .foregroundStyle(Color.black.opacity(0.6))
                .frame(width: 265, alignment: .leading)
                .at(15, 165)

            Button(action: onView) {
                Text("View analysis")
                    .font(FigmaFont.walsheimMedium(13))
                    .foregroundStyle(Color.white)
                    .frame(width: 105, height: 37)
                    .background(Color.black)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .at(17, 221)
        }
        .frame(width: 299, height: 275, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.black.opacity(0.11), lineWidth: 2))
    }
}

/// "Connect your Mutual funds safely" (148:6099), 364 × 636: advice needs the funds, so it asks for them
struct ConnectFundsSheet: View {
    let onContinue: () -> Void
    let onUpload: () -> Void

    /// Its parts that have come in: the photo, the heading, MFCentral, the buttons
    @State private var shown = 0

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        ZStack(alignment: .topLeading) {
            Color(hex: 0x151515)

            // 148:6129: the photo, over the brown it was shot against
            LinearGradient(colors: [Color(hex: 0xAD898E), Color(hex: 0x70523A)], startPoint: .top, endPoint: .bottom)
                .overlay {
                    Image("ConnectPhone")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 440, height: 597)
                        .offset(x: 15, y: 11)
                }
                .frame(width: 364, height: 199)
                .clipped()
                // Taller than its frame, and clipping doesn't stop it catching taps above the sheet
                .allowsHitTesting(false)
                .scaleEffect(shown > 0 ? 1 : 1.08)
                .opacity(shown > 0 ? 1 : 0)

            Group {
                Text("Required for Wealth Advisory")
                    .font(FigmaFont.walsheimMedium(23))
                    .foregroundStyle(Color.white)
                    .frame(width: 364, height: 29)
                    .at(0, 216)
                Text("Connect your Mutual funds safely")
                    .font(FigmaFont.reckless(44))
                    .lineSpacing(45 - 44 * 1.2)
                    .foregroundStyle(Color.white.opacity(0.93))
                    .multilineTextAlignment(.center)
                    .frame(width: 334)
                    .at(15, 260)
            }
            .rising(shown > 1)

            mfCentral
                .at(17, 418)
                .rising(shown > 2)

            Group {
                Button {
                    Haptics.tap()
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(FigmaFont.walsheimMedium(17))
                        .foregroundStyle(Color.black)
                        .frame(width: 334, height: 45)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
                        .shadow(color: Color.black.opacity(0.03), radius: 30, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .at(15, 522)

                Button {
                    Haptics.tap()
                    onUpload()
                } label: {
                    HStack(spacing: 1) {
                        Text("Upload your portfolio yourself")
                            .font(FigmaFont.walsheim(15))
                            .foregroundStyle(Color.white.opacity(0.7))
                        Image("UploadChevron")
                            .frame(width: 21, height: 21)
                            .opacity(0.7)
                    }
                    .frame(width: 364, height: 21)
                }
                .buttonStyle(.plain)
                .at(0, 584)
            }
            .rising(shown > 3)
        }
        .frame(width: 364, height: 636, alignment: .topLeading)
        .clipShape(shape)
        .contentShape(shape)
        .shadow(color: Color.black.opacity(OnboardingDecadeWelcomeView.cardShadow), radius: OnboardingDecadeWelcomeView.cardShadowRadius, x: 0, y: 4)
        .task {
            for beat in [0.1, 0.25, 0.2, 0.2] {
                try? await Task.sleep(for: .seconds(beat))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) { shown += 1 }
            }
        }
    }

    /// "We use MFCentral for mutual funds" (154:7184), 330 × 63
    private var mfCentral: some View {
        let shape = RoundedRectangle(cornerRadius: 17, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Image("MFCentralMark")
                .resizable()
                .frame(width: 26, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .at(12, 12)
            Text("We use MFCentral for mutual funds")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(Color.white.opacity(0.85))
                .fixedSize()
                .frame(height: 23)
                .at(47, 8)
            Text("SEBI and AMFI-regulated platform")
                .font(FigmaFont.walsheim(13))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(height: 19)
                .at(47, 34)
        }
        .frame(width: 330, height: 63, alignment: .topLeading)
        .overlay(shape.strokeBorder(Color(red: 194 / 255, green: 194 / 255, blue: 194 / 255).opacity(0.17), lineWidth: 1))
    }
}

/// "Connect your mutual funds portfolio for personal advise" (802:6216), 368 × 719: "Personal Advisory" over a rule,
/// fund houses' marks turning slowly under it, the heading, the prompt that was tapped and the others in a rail,
/// and Continue.
struct PersonalAdviceSheet: View {
    let prompt: String
    let chart: Int
    /// Without its own shadow, for when it's one page of a larger sheet
    var framed = true
    let onContinue: () -> Void

    /// The tapped prompt first, then the rest
    private var prompts: [String] {
        [prompt] + OnboardingDecadeWelcomeView.advicePrompts.filter { $0 != prompt }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        ZStack(alignment: .topLeading) {
            Color.white

            FundHouseOrbit(centre: 90)
                .frame(width: 368, height: 227)
                .at(0, 54)

            // 802:6285: a key and "Personal Advisory", centred
            HStack(spacing: 11) {
                Image(systemName: "key.horizontal")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black)
                Text("Personal Advisory")
                    .font(FigmaFont.walsheimMedium(19))
                    .foregroundStyle(Color.black)
                    .fixedSize()
            }
            .frame(width: 368, height: 29)
            .at(0.5, 13)

            Color.black.opacity(0.57)
                .frame(width: 328, height: 1)
                .at(18, 52)

            Text("Connect your mutual funds portfolio for personal advise")
                .font(FigmaFont.walsheimMedium(33))
                .lineSpacing(39 - 33 * 1.2)
                .foregroundStyle(Color.black.opacity(0.93))
                .multilineTextAlignment(.center)
                .frame(width: 342)
                .at(13, 281)

            // 802:6423 onwards: the prompts, running off the sheet's right edge
            SidewaysRail(width: 368) {
                HStack(alignment: .top, spacing: 17) {
                    ForEach(Array(prompts.enumerated()), id: \.offset) { index, title in
                        OnboardingDecadeWelcomeView.tintedPromptCard(title, washed: index == 0)
                    }
                }
                .padding(.horizontal, 18)
            }
            .frame(width: 368, height: 192, alignment: .topLeading)
            .at(0, 412)

            Button {
                Haptics.tap()
                onContinue()
            } label: {
                Text("Continue")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .frame(width: 334, height: 45)
                    .background(Color.black)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
            }
            .buttonStyle(.plain)
            .at(15, 647)
        }
        .frame(width: 368, height: 719, alignment: .topLeading)
        .clipShape(shape)
        .contentShape(shape)
        .shadow(color: Color.black.opacity(framed ? OnboardingDecadeWelcomeView.cardShadow : 0), radius: OnboardingDecadeWelcomeView.cardShadowRadius, x: 0, y: 4)
    }
}

/// Fund houses' marks as tiles (832:14413 onwards, 51 × 51), turning slowly about their middle the way the app icons
/// do on the Apple Account sign-in sheet: the whole cluster rotates as one, as a disc seen at a tilt, each tile
/// staying upright, a little larger as it comes to the front and smaller as it goes round the back, and each
/// breathing slightly on its own beat.
struct FundHouseOrbit: View {
    /// How far down its own frame the cluster's middle sits
    let centre: CGFloat

    /// Where each tile's middle sits at rest, from the frame, about the cluster's middle (184, 144 in the sheet)
    private static let tiles: [(asset: String, at: CGPoint)] = [
        ("FundHDFC", CGPoint(x: -33.5, y: -3.5)),
        ("FundAxis", CGPoint(x: 102.5, y: 2.5)),
        ("FundPPFAS", CGPoint(x: 62.5, y: 68.5)),
        ("FundNippon", CGPoint(x: -25.5, y: 68.5)),
        ("FDGrowthSBI", CGPoint(x: -103.5, y: 20.5)),
        ("FundQuant", CGPoint(x: -103.5, y: -61.5)),
        ("HSBCLogo", CGPoint(x: 38.5, y: -68.5)),
    ]
    /// How flat the disc looks: its depth drawn at this much of its width
    private static let tilt = 0.62
    /// Seconds for one turn
    private static let period = 46.0

    @State private var began = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
        TimelineView(.animation(paused: reduceMotion)) { context in
            let elapsed = reduceMotion ? 0 : context.date.timeIntervalSince(began)
            let turn = elapsed / Self.period * 2 * .pi
            ZStack {
                ForEach(Array(Self.tiles.enumerated()), id: \.offset) { index, tile in
                    // On the disc: the frame's place, its depth stretched back out
                    let px = Double(tile.at.x), py = Double(tile.at.y) / Self.tilt
                    let x = px * cos(turn) - py * sin(turn)
                    let depth = px * sin(turn) + py * cos(turn)
                    // -1 at the back, 1 at the front
                    let near = max(-1, min(1, depth / 140))
                    let breath = 1 + 0.03 * sin(elapsed * 0.9 + Double(index) * 1.7)
                    Self.tile(tile.asset)
                        .scaleEffect((1 + 0.09 * near) * breath)
                        .offset(x: x, y: depth * Self.tilt + centre - geo.size.height / 2)
                        .zIndex(depth)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        }
        // Tiles going round the back slip away under the rule; those at the front fade before the heading
        .mask(
            LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.1),
                                   .init(color: .black, location: 0.92), .init(color: .clear, location: 1)],
                           startPoint: .top, endPoint: .bottom)
        )
        .accessibilityHidden(true)
    }

    private static func tile(_ asset: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 15, style: .continuous)
        return Image(asset)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 37, height: 37)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .frame(width: 51, height: 51)
            .background(shape.fill(Color.white))
            .overlay(shape.strokeBorder(ColorScale.borderSubtle, lineWidth: 0.7))
    }
}

/// "We will import mutual funds via MFCentral" (952:13599), 368 × 740: "Personal Advisory" and a close over a rule,
/// the fund houses' tiles, the heading, two reassurances in a box, "Lets connect", and the way round it
struct MFCentralImportSheet: View {
    static let height: CGFloat = 740
    let onContinue: () -> Void
    let onUpload: () -> Void
    var onClose: () -> Void = {}

    private static let points = [
        "MFCentral is SEBI and AMFI-regulated platform",
        "Secure import with one time password sent on your registered mobile number",
    ]

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 27, style: .continuous)
        ZStack(alignment: .topLeading) {
            Color.white

            HStack(spacing: 11) {
                Image(systemName: "key.horizontal")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black)
                    .accessibilityHidden(true)
                Text("Personal Advisory")
                    .font(FigmaFont.walsheimMedium(19))
                    .foregroundStyle(Color.black)
                    .fixedSize()
            }
            .frame(height: 29)
            .at(20, 11)

            Button {
                Haptics.tap()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.black)
                    .frame(width: 27, height: 27)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            .at(322 - 8, 12 - 8)

            Color.black.opacity(0.57)
                .frame(width: 350, height: 1)
                .at(9, 48)

            // The same tiles the import shows next, 50 lower here
            MFHouseTiles()
                .at(0, 50)

            Text("We will import mutual\nfunds via MFCentral")
                .font(FigmaFont.walsheimMedium(33))
                .lineSpacing(41 - UIFont(name: "GTWalsheimTrial-Md", size: 33)!.lineHeight)
                .foregroundStyle(Color.black.opacity(0.93))
                .multilineTextAlignment(.center)
                .frame(width: 342)
                .at(13, 283)
                .accessibilityLabel("We will import mutual funds via MFCentral")

            points
                .at(19, 404)

            Button {
                Haptics.tap()
                onContinue()
            } label: {
                Text("Lets connect")
                    .font(FigmaFont.walsheimMedium(17))
                    .foregroundStyle(Color.white)
                    .frame(width: 322, height: 49)
                    .background(Capsule().fill(Color(hex: 0x1F1513)))
                    .shadow(color: Color.black.opacity(0.05), radius: 50, x: 0, y: 4)
            }
            .buttonStyle(PressScaleStyle())
            .at(23, 616)

            Button {
                Haptics.tap()
                onUpload()
            } label: {
                HStack(spacing: 1) {
                    Text("I will upload myself")
                        .font(FigmaFont.walsheim(15))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .frame(width: 21, height: 21)
                }
                .foregroundStyle(Color.black.opacity(0.7))
                .frame(height: 21)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(width: 368)
            .at(0.5, 682)
        }
        .frame(width: 368, height: Self.height, alignment: .topLeading)
        .clipShape(shape)
        .contentShape(shape)
        // 0 4 130 +15 at 9%; SwiftUI can't draw the spread
        .shadow(color: Color.black.opacity(0.09), radius: 65, x: 0, y: 4)
    }

    /// 952:13741: 330 × 175, the regulator's line over the one-time password's, a rule between
    private var points: some View {
        let shape = RoundedRectangle(cornerRadius: 15, style: .continuous)
        return ZStack(alignment: .topLeading) {
            Image(systemName: "checkerboard.shield")
                .font(.system(size: 19, weight: .regular))
                .foregroundStyle(Color(hex: 0x2F80ED))
                .frame(width: 25, height: 25)
                .at(14, 17)
                .accessibilityHidden(true)
            point(Self.points[0]).at(50, 14)

            Color(hex: 0xEBEBEB)
                .frame(width: 329, height: 1)
                .at(0, 74)

            // 952:13755: five green dots, the shape of a code being keyed in
            ZStack(alignment: .topLeading) {
                ForEach(Array([(3.0, 2.0), (3, 10), (10, 18), (17, 2), (17, 10)].enumerated()), id: \.offset) { _, dot in
                    Circle().fill(Color(hex: 0x19D522)).frame(width: 5, height: 5).at(dot.0, dot.1)
                }
            }
            .frame(width: 25, height: 25, alignment: .topLeading)
            .at(14, 93)
            .accessibilityHidden(true)
            point(Self.points[1]).at(50, 90)
        }
        .frame(width: 330, height: 175, alignment: .topLeading)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color(hex: 0xC2C2C2).opacity(0.33), lineWidth: 1))
    }

    private func point(_ text: String) -> some View {
        Text(text)
            .font(FigmaFont.walsheim(17))
            .lineSpacing(23 - UIFont(name: "GTWalsheimTrial-Rg", size: 17)!.lineHeight)
            .foregroundStyle(Color.black.opacity(0.61))
            .frame(width: 258, alignment: .leading)
    }
}

/// "Action required" (1012:10877), 301.6 × 202.6: the agent's own card in the chat asking for the funds, instead of
/// a sheet. What's wanted and from where on a raised tile, and "Connect securely", which opens the MFCentral sheet.
/// Once the funds are in it becomes "Connected successfully" (1012:11077), 299 × 212: the account that's connected,
/// and "View portfolio".
struct ConnectActionCard: View {
    var connected = false
    let onConnect: () -> Void
    var onView: () -> Void = {}

    /// The taller of its two states
    static let size = CGSize(width: 301.6, height: 212)
    private var width: CGFloat { connected ? 299 : 301.6 }
    private var height: CGFloat { connected ? 212 : 202.6 }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 23, style: .continuous)
        ZStack(alignment: .topLeading) {
            Text(connected ? "Connected successfully" : "Action required")
                .font(FigmaFont.walsheim(17))
                .foregroundStyle(connected ? ColorPrimitives.utilityGreen500 : ColorPrimitives.accentYellow400)
                .fixedSize()
                .frame(height: 22)
                .contentTransition(.opacity)
                .at(16.3, 16.3)

            // 1012:10882: 265 × 83
            ZStack(alignment: .topLeading) {
                ColorScale.surfaceBase
                Image("MFCentralIcon")
                    .resizable()
                    .frame(width: 38, height: 38)
                    .offset(x: 0.5, y: 0.5)
                    .frame(width: 33, height: 33)
                    .background(ColorScale.surfaceSunken2)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .at(16, 17)
                    .accessibilityHidden(true)
                DsText(connected ? "MFCentral Account" : "Import your mutual funds", variant: .p4)
                    .fixedSize()
                    .contentTransition(.opacity)
                    .at(60, 14)
                Text(connected ? "NSE" : "From MFCentral")
                    .font(FigmaFont.walsheim(13))
                    .foregroundStyle(ColorScale.contentTertiary)
                    .fixedSize()
                    .frame(height: 21)
                    .at(60, 36)
            }
            .frame(width: 265, height: 83, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).strokeBorder(Color.black.opacity(0.05), lineWidth: 1))
            // Shadow/2 (0 4 97 +7 at 7%); SwiftUI can't draw the spread
            .shadow(color: Color.black.opacity(0.07), radius: 48.5, x: 0, y: 4)
            .at(connected ? 17 : 18.3, 53.3)

            if connected {
                // 1012:11086: outlined, 257 × 45
                Button {
                    Haptics.tap()
                    onView()
                } label: {
                    DsText("View portfolio", variant: .h6)
                        .frame(width: 257, height: 45)
                        .background(Capsule().fill(Color.white))
                        .overlay(Capsule().strokeBorder(ColorScale.borderSubtle, lineWidth: 0.7))
                        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
                        .contentShape(Capsule())
                }
                .buttonStyle(PressScaleStyle())
                .at(20.3, 149.3)
                .transition(.opacity)
            } else {
            Button {
                Haptics.tap()
                onConnect()
            } label: {
                Text("Connect securely")
                    .font(FigmaFont.walsheimMedium(13))
                    .foregroundStyle(Color.white)
                    .frame(width: 261, height: 37)
                    .background(Capsule().fill(Color.black))
                    .overlay(Capsule().strokeBorder(Color.black.opacity(0.05), lineWidth: 2))
                    .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 3)
            }
            .buttonStyle(PressScaleStyle())
            .at(20.3, 149.3)
            .transition(.opacity)
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .background(Color.white)
        .clipShape(shape)
        .overlay(shape.strokeBorder(ColorScale.borderSubtle, lineWidth: 0.7))
        // 1012:10879: the bubble's tail, at its lower left
        .overlay(alignment: .bottomLeading) {
            ZStack(alignment: .topLeading) {
                Image("BubbleTail")
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.white)
                    .frame(width: 24, height: 14)
                    .rotationEffect(.degrees(-1.3))
                    .offset(x: 3.14, y: 0)
                Image("Vector83Grey")
                    .resizable()
                    .frame(width: 14, height: 4.5)
                    .rotationEffect(.degrees(7.34))
                    .offset(x: 11.57, y: 2.4)
            }
            .frame(width: 30, height: 15, alignment: .topLeading)
            .offset(y: 9.97)
            .accessibilityHidden(true)
        }
    }
}

private extension View {
    func rising(_ shown: Bool) -> some View {
        opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
    }
}

#Preview {
    VStack {
        AnalysedCard(onView: {})
        ConnectFundsSheet(onContinue: {}, onUpload: {})
        PersonalAdviceSheet(prompt: OnboardingDecadeWelcomeView.advicePrompts[0], chart: 0, onContinue: {})
        MFCentralImportSheet(onContinue: {}, onUpload: {})
        ConnectActionCard(onConnect: {})
    }
}
