public enum Sensitivity: String, CaseIterable, Sendable {
    case highest, high, medium, low, lowest

    public var title: String {
        switch self {
        case .highest: "Extremely Sensitive"
        case .high: "High"
        case .medium: "Medium"
        case .low: "Low"
        case .lowest: "Requires Significant Force"
        }
    }

    var threshold: (force: Double, jerk: Double, bigHit: Double) {
        switch self {
        case .highest: (0.15, 14, 0.45)
        case .high: (0.25, 20, 0.60)
        case .medium: (0.40, 30, 0.90)
        case .low: (0.70, 50, 1.50)
        case .lowest: (1.10, 90, 2.20)
        }
    }
}
