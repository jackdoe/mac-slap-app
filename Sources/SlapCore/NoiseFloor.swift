import Foundation

struct NoiseFloor: Sendable {
    static let timeConstant = 1.25
    static let ceilingSpreads = 7.0
    static let frozenAboveSpreads = 4.0
    static let frozenAboveMargin = 0.02

    private var level = 0.0
    private var spread = 0.01

    var ceiling: Double { level + Self.ceilingSpreads * spread }

    mutating func track(_ force: Double, period: Double) {
        guard force <= level + Self.frozenAboveSpreads * spread + Self.frozenAboveMargin else { return }
        let alpha = exp(-period / Self.timeConstant)
        level = alpha * level + (1 - alpha) * force
        spread = alpha * spread + (1 - alpha) * abs(force - level)
    }
}
