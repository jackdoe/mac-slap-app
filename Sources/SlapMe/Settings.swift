import Foundation
import SlapCore

extension Sensitivity: Storable {}

enum Settings {
    @Stored("enabled") static var isEnabled = true
    @Stored("snoozedUntil") static var snoozedUntil = Date.distantPast
    @Stored("soundsFolder") static var soundsFolder: URL? = nil
    @Stored("usesSoundsFolder") static var usesSoundsFolder = false
    @Stored("volume") static var volume = 0.8
    @Stored("dynamicVolume") static var dynamicVolume = true
    @Stored("sensitivity") static var sensitivity = Sensitivity.medium
    @Stored("cooldown") static var cooldown = Cooldown.medium
    @Stored("usbMoaner") static var usbMoaner = false
    @Stored("showsCount") static var showsCount = true
    @Stored("enrolledLoginItem") static var enrolledLoginItem = false
}

enum Stats {
    @Stored("slaps") private(set) static var total = 0
    @Stored("hardest") private(set) static var hardest = 0.0
    @Stored("lastSlapDayCount") private static var lastSlapDayCount = 0
    @Stored("lastSlap") private static var lastSlap = Date.distantPast

    static var today: Int { Calendar.current.isDateInToday(lastSlap) ? lastSlapDayCount : 0 }

    static func record(_ slap: Slap) {
        lastSlapDayCount = today + 1
        lastSlap = .now
        total += 1
        hardest = max(hardest, slap.force)
    }

    static func reset() {
        total = 0
        hardest = 0
        lastSlapDayCount = 0
    }
}

enum Cooldown: Double, CaseIterable, Storable {
    case none = 0, fast = 0.35, medium = 0.75, slow = 1, verySlow = 2

    var duration: Duration { .seconds(rawValue) }

    var title: String {
        let name = switch self {
        case .none: "None"
        case .fast: "Fast"
        case .medium: "Medium"
        case .slow: "Slow"
        case .verySlow: "Very Slow"
        }
        return self == .none ? name : "\(name) (\(rawValue.formatted())s)"
    }
}

enum Snooze: CaseIterable {
    case quarterHour, hour, tomorrow

    var title: String {
        switch self {
        case .quarterHour: "For 15 Minutes"
        case .hour: "For 1 Hour"
        case .tomorrow: "Until Tomorrow"
        }
    }

    func end(from now: Date = .now) -> Date {
        switch self {
        case .quarterHour: now.addingTimeInterval(15 * 60)
        case .hour: now.addingTimeInterval(60 * 60)
        case .tomorrow:
            Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: now.addingTimeInterval(24 * 60 * 60))
                ?? now.addingTimeInterval(24 * 60 * 60)
        }
    }
}
