public struct Streak: Sendable {
    public static let gap = Duration.seconds(3)

    public private(set) var count = 0
    public private(set) var last: ContinuousClock.Instant?

    public init() {}

    public mutating func hit(at now: ContinuousClock.Instant) {
        let continues = last.map { now - $0 <= Self.gap } ?? false
        count = continues ? count + 1 : 1
        last = now
    }
}
