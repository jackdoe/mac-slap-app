import AppKit

final class Haptics: Effect {
    let title = "Trackpad Haptics"
    @Stored("haptics") var isOn = true
    @Stored("hapticsLevel") var level = 0.7

    static let pulseSpacing = Duration.milliseconds(45)
    static let trackpad = ["ActuationSupported": true, "MT Built-In": true]

    private enum Waveform: Int32 {
        case light = 3, medium = 4, strong = 6
    }

    private var actuator: CFTypeRef?

    func play(_ strength: Double) {
        for (index, waveform) in Self.pulses(strength).enumerated() {
            Task {
                try? await Task.sleep(for: Self.pulseSpacing * index)
                fire(waveform)
            }
        }
    }

    private static func pulses(_ strength: Double) -> [Waveform] {
        switch strength {
        case 0.8...: [.strong, .strong, .strong]
        case 0.5...: [.strong, .medium]
        case 0.2...: [.medium]
        default: [.light]
        }
    }

    private func fire(_ waveform: Waveform) {
        if let actuator = actuator ?? openActuator(), Multitouch.actuate?(actuator, waveform.rawValue, 0, 0, 2) == 0 {
            return
        }
        closeActuator()
        NSHapticFeedbackManager.defaultPerformer.perform(waveform == .light ? .alignment : .generic, performanceTime: .now)
    }

    private func openActuator() -> CFTypeRef? {
        guard let id: UInt64 = IORegistry.withService("AppleMultitouchDevice", matching: Self.trackpad, {
                  IORegistry.property("Multitouch ID", of: $0)
              }),
              let created = Multitouch.createActuator?(id)?.takeRetainedValue(),
              Multitouch.openActuator?(created) == 0
        else { return nil }
        actuator = created
        return created
    }

    private func closeActuator() {
        if let actuator { _ = Multitouch.closeActuator?(actuator) }
        actuator = nil
    }
}
