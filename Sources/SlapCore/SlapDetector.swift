import Foundation

public struct Slap: Sendable, Equatable {
    public static let forceRange = 0.15...1.8

    public let force: Double

    public init(force: Double) {
        self.force = force
    }

    public var intensity: Double {
        let span = Self.forceRange.upperBound - Self.forceRange.lowerBound
        let position = min(max((force - Self.forceRange.lowerBound) / span, 0), 1)
        return log1p(99 * position) / log(100)
    }
}

public struct SlapDetector: Sendable {
    static let settling = 0.3
    static let impactWindow = 0.05
    static let refractory = 0.14

    public var sensitivity: Sensitivity
    private var motion = Motion()
    private var noise = NoiseFloor()
    private var quiet = SlapDetector.settling
    private var impact: (peak: Double, age: Double)?

    public init(sensitivity: Sensitivity) {
        self.sensitivity = sensitivity
    }

    public mutating func process(_ acceleration: SIMD3<Double>, period: Double) -> Slap? {
        let (force, jerk) = motion.update(acceleration, period: period)
        noise.track(force, period: period)
        guard quiet <= 0 else {
            quiet -= period
            return nil
        }

        let limit = sensitivity.threshold
        let threshold = max(limit.force, noise.ceiling)
        guard var current = impact else {
            if (force >= threshold && jerk >= limit.jerk) || force >= limit.bigHit {
                impact = (force, 0)
            }
            return nil
        }

        current.peak = max(current.peak, force)
        current.age += period
        guard force < threshold / 2 || current.age >= Self.impactWindow else {
            impact = current
            return nil
        }
        impact = nil
        quiet = Self.refractory
        return Slap(force: current.peak)
    }
}
