import CoreGraphics

final class BacklightFlash: Effect {
    let title = "Brightness Flash"
    @Stored("backlight") var isOn = false
    @Stored("backlightLevel") var level = 0.5

    static let hold = Duration.milliseconds(60)
    static let fadeSteps = 12
    static let fadeStep = Duration.milliseconds(22)

    private var flashing = false

    var unavailable: String? { Self.display == nil ? "No built-in display" : nil }

    func play(_ strength: Double) {
        guard !flashing,
              let display = Self.display,
              let read = DisplayServices.brightness,
              let write = DisplayServices.setBrightness
        else { return }

        var original: Float = 0
        guard read(display, &original) == 0 else { return }
        let strength = Float(strength)
        let peak = original > 0.5 ? max(original * (0.7 - 0.4 * strength), 0.05) : min(original + 0.2 + 0.5 * strength, 1)

        flashing = true
        Task {
            _ = write(display, peak)
            try? await Task.sleep(for: Self.hold)
            for step in 1...Self.fadeSteps {
                let progress = 1 - pow(1 - Float(step) / Float(Self.fadeSteps), 2.5)
                _ = write(display, peak + (original - peak) * progress)
                try? await Task.sleep(for: Self.fadeStep)
            }
            flashing = false
        }
    }

    private static var display: CGDirectDisplayID? {
        var displays = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(UInt32(displays.count), &displays, &count) == .success else { return nil }
        let candidate = displays.prefix(Int(count)).first { CGDisplayIsBuiltin($0) != 0 } ?? CGMainDisplayID()
        return DisplayServices.canChangeBrightness?(candidate) == true ? candidate : nil
    }
}
