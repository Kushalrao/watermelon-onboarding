import UIKit

/// Haptics for the page ↔ chat transition. (No-ops in the simulator — test on a device.)
enum Haptics {
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let selection = UISelectionFeedbackGenerator()

    /// Call when a gesture starts so the first tap has no latency.
    static func prepare() {
        medium.prepare(); light.prepare(); soft.prepare(); heavy.prepare(); selection.prepare()
    }

    /// The page snapping into the top card.
    static func collapse() { medium.impactOccurred() }

    /// A widget lifting out of the page on long press.
    static func lift() { medium.impactOccurred(intensity: 0.9) }

    /// Pull crossed (or un-crossed) the release-to-expand threshold.
    static func thresholdCrossed() { light.impactOccurred() }

    /// The card expanding back into the page.
    static func expand() { soft.impactOccurred(intensity: 0.8) }

    /// Pull released short of the threshold — card settles back.
    static func settle() { soft.impactOccurred(intensity: 0.5) }

    /// One bar of the score meter lighting up.
    static func meterTick(intensity: Double) { soft.impactOccurred(intensity: max(0.15, intensity)) }

    /// One grain of the identity card settling as the reveal sweeps down it.
    static func revealGrain(intensity: Double) { soft.impactOccurred(intensity: intensity) }

    /// The identity card fully revealed.
    static func revealSettled() { medium.impactOccurred(intensity: 0.75) }

    /// One beat of a gesture under way (a hold building, a swipe travelling): a light tick, `strength` 0 … 1.
    /// The beats come closer together as the gesture nears landing; the callers space them.
    static func beat(strength: Double) { light.impactOccurred(intensity: 0.3 + 0.3 * min(1, max(0, strength))) }

    /// A gesture landing: two strong knocks of the same strength, the second after a 200 ms break (a knock itself
    /// lasts about 20 ms).
    static func landed() {
        heavy.impactOccurred(intensity: 1)
        heavy.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { heavy.impactOccurred(intensity: 1) }
    }

    /// Picker / chip / button taps.
    static func tap() { selection.selectionChanged() }
}
