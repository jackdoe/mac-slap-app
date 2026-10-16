import AppKit

final class ScreenFlash: Effect {
    let title = "Screen Flash"
    @Stored("flash") var isOn = false
    @Stored("flashLevel") var level = 0.5

    static let minimumInterval = Duration.milliseconds(334)

    private var lastFlash: ContinuousClock.Instant?

    func play(_ strength: Double) {
        let now = ContinuousClock.now
        if let lastFlash, now - lastFlash < Self.minimumInterval { return }
        lastFlash = now

        let strength = min(strength, 2)
        for screen in NSScreen.screens {
            let panel = NSPanel.overlay(screen.frame)
            panel.backgroundColor = .white.withAlphaComponent(strength / 2)
            panel.orderFrontRegardless()
            Task {
                await NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.15 + 0.25 * strength
                    panel.animator().alphaValue = 0
                }
                panel.orderOut(nil)
            }
        }
    }
}
