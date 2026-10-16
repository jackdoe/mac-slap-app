import Foundation
import SlapCore

final class Controller {
    static let testSlap = Slap(force: 0.6)

    let sensor = Sensor()
    let voice = Voice()
    let effects: [any Effect] = [Haptics(), CursorBurst(), ScreenFlash(), BacklightFlash()]

    var onChange: (() -> Void)?
    var onSlap: (() -> Void)?

    private let usb = USBMonitor()
    private var streak = Streak()
    private var snoozeEnd: Task<Void, Never>?

    init() {
        sensor.onSlap = { [weak self] in self?.receive($0) }
        sensor.onStatusChange = { [weak self] in self?.onChange?() }
        usb.onChange = { [weak self] in self?.voice.moan() }
    }

    var isSnoozed: Bool { Settings.snoozedUntil > .now }
    var isActive: Bool { Settings.isEnabled && !isSnoozed }

    func apply() {
        sensor.sensitivity = Settings.sensitivity
        if isActive { sensor.start() } else { sensor.stop() }
        if isActive && Settings.usbMoaner { usb.start() } else { usb.stop() }
        voice.load()
        snoozeEnd?.cancel()
        if isSnoozed {
            snoozeEnd = Task { [weak self] in
                guard (try? await Task.sleep(for: .seconds(Settings.snoozedUntil.timeIntervalSinceNow))) != nil else { return }
                self?.apply()
            }
        }
        onChange?()
    }

    func test() {
        perform(Self.testSlap, at: .now)
    }

    private func receive(_ slap: Slap) {
        let now = ContinuousClock.now
        guard isActive, streak.last.map({ now - $0 >= Settings.cooldown.duration }) ?? true else { return }
        Stats.record(slap)
        perform(slap, at: now)
    }

    private func perform(_ slap: Slap, at now: ContinuousClock.Instant) {
        streak.hit(at: now)
        voice.react(to: slap, streak: streak)
        for effect in effects where effect.isOn {
            effect.play(slap.intensity * effect.level * 2)
        }
        onSlap?()
    }
}
