import CoreMotion
import SwiftUI

/// The silver hologram sticker on the identity card (Figma 44:3363), drawn live rather than as a picture: a brushed
/// silver foil printed with rows of small "भारत सरकार", the words again large and embossed in the middle, and a
/// rainbow sheen with bright streaks that slide across it as the phone tilts. When the phone is still it drifts on
/// its own, slowly, so it never looks flat.
struct HologramSticker: View {
    @State private var motion = TiltReader()

    private static let phrase = "भारत सरकार"

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            // Where the light sits: the phone's tilt plus a slow drift of its own
            let lx = motion.roll * 1.6 + 0.55 * sin(t * 0.7)
            let ly = motion.pitch * 1.6 + 0.35 * cos(t * 0.53)
            sticker(lx: lx, ly: ly)
        }
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }

    private func sticker(lx: Double, ly: Double) -> some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        return GeometryReader { geo in
            let size = geo.size
            ZStack {
                // Foil
                LinearGradient(
                    colors: [Color(hex: 0xAFB6C6), Color(hex: 0xDCE0E8), Color(hex: 0xA3AABB), Color(hex: 0xD2D7E1)],
                    startPoint: UnitPoint(x: 0.0 + lx * 0.2, y: 0), endPoint: UnitPoint(x: 1, y: 1 + ly * 0.2)
                )

                // Rainbow diffraction, banded diagonally, sliding with the light
                LinearGradient(
                    stops: Self.rainbow,
                    startPoint: UnitPoint(x: -0.6 + lx * 0.9, y: -0.4 + ly * 0.6),
                    endPoint: UnitPoint(x: 1.2 + lx * 0.9, y: 1.4 + ly * 0.6)
                )
                .blendMode(.hardLight)
                .opacity(0.85)

                // A second, finer rainbow at an angle, so colours cross over as it tilts
                LinearGradient(
                    stops: Self.rainbow,
                    startPoint: UnitPoint(x: 1.3 - lx * 0.7, y: -0.2 + ly * 0.5),
                    endPoint: UnitPoint(x: -0.1 - lx * 0.7, y: 0.7 + ly * 0.5)
                )
                .blendMode(.colorDodge)
                .opacity(0.4)

                // Rows of the small print, alternate rows shifted
                microprint(size: size)

                // The big embossed words, catching the same light
                embossed(lx: lx, ly: ly)

                // Bright streaks of reflected light
                LinearGradient(
                    stops: [
                        .init(color: .white.opacity(0), location: 0.30),
                        .init(color: .white.opacity(0.85), location: 0.40),
                        .init(color: .white.opacity(0), location: 0.47),
                        .init(color: .white.opacity(0), location: 0.62),
                        .init(color: .white.opacity(0.5), location: 0.68),
                        .init(color: .white.opacity(0), location: 0.73),
                    ],
                    startPoint: UnitPoint(x: -0.5 + lx * 1.2, y: 0 + ly * 0.8),
                    endPoint: UnitPoint(x: 1.5 + lx * 1.2, y: 1 + ly * 0.8)
                )
                .blendMode(.screen)
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.white.opacity(0.7), lineWidth: 0.6))
            .overlay(shape.strokeBorder(Color.black.opacity(0.08), lineWidth: 0.3))
        }
        .shadow(color: Color.black.opacity(0.12), radius: 1.5, x: 0, y: 0.5)
    }

    private static let rainbow: [Gradient.Stop] = [
        .init(color: Color(hex: 0xFF8FB1).opacity(0), location: 0.00),
        .init(color: Color(hex: 0xFF8FB1), location: 0.12),
        .init(color: Color(hex: 0xFFD27A), location: 0.22),
        .init(color: Color(hex: 0x9CF2A5), location: 0.32),
        .init(color: Color(hex: 0x7FD8FF), location: 0.42),
        .init(color: Color(hex: 0xB59BFF), location: 0.52),
        .init(color: Color(hex: 0xB59BFF).opacity(0), location: 0.60),
        .init(color: Color(hex: 0xFF8FB1).opacity(0), location: 0.70),
        .init(color: Color(hex: 0xFFB0C8), location: 0.80),
        .init(color: Color(hex: 0x8EE6FF), location: 0.90),
        .init(color: Color(hex: 0x8EE6FF).opacity(0), location: 1.00),
    ]

    private func microprint(size: CGSize) -> some View {
        let rows = 8
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { _ in
                        Text(Self.phrase)
                            .font(.system(size: 4.6, weight: .medium))
                            .fixedSize()
                    }
                }
                .offset(x: row.isMultiple(of: 2) ? -2 : 9)
                .frame(height: size.height / Double(rows))
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .foregroundStyle(Color(hex: 0x566073).opacity(0.6))
        .blendMode(.multiply)
    }

    private func embossed(lx: Double, ly: Double) -> some View {
        let words = Text("भारत\nसरकार")
            .font(.system(size: 17, weight: .heavy))
            .multilineTextAlignment(.center)
            .lineSpacing(-6)
        return ZStack {
            // Pressed edge: dark below and to the right, bright above and to the left
            words.foregroundStyle(Color(hex: 0x3A4152).opacity(0.45)).offset(x: 0.6, y: 0.8).blur(radius: 0.35)
            words.foregroundStyle(Color.white).offset(x: -0.4, y: -0.5)
            // Face: silver with its own sliding rainbow
            words.foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: 0xF4F5F8), Color(hex: 0xC9DDF7), Color(hex: 0xFBE6F0), Color(hex: 0xE0F3E4), Color(hex: 0xF2F3F6)],
                    startPoint: UnitPoint(x: -0.2 + lx, y: 0 + ly * 0.6),
                    endPoint: UnitPoint(x: 1.2 + lx, y: 1 + ly * 0.6)
                )
            )
        }
    }
}

/// Reads how far the phone is tipped, smoothed, in radians: roll left/right, pitch towards/away
@Observable private final class TiltReader {
    var roll: Double = 0
    var pitch: Double = 0
    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var rest: (roll: Double, pitch: Double)?

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1 / 60
        manager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let a = data?.attitude else { return }
            // Measured from however the phone was held when the card appeared
            let rest = self.rest ?? (a.roll, a.pitch)
            self.rest = rest
            self.roll += (max(-0.6, min(0.6, a.roll - rest.roll)) - self.roll) * 0.2
            self.pitch += (max(-0.6, min(0.6, a.pitch - rest.pitch)) - self.pitch) * 0.2
        }
    }

    func stop() { manager.stopDeviceMotionUpdates() }
}

#Preview {
    HologramSticker()
        .frame(width: 80, height: 78)
        .scaleEffect(3)
        .frame(width: 400, height: 400)
}
