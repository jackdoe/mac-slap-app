import AppKit
import SlapCore

final class StatusMenu: NSObject, NSMenuDelegate {
    static let idleIcon = "👋"
    static let slapIcon = "💥"
    static let pausedIcon = "💤"
    static let slapIconDuration = Duration.milliseconds(350)

    private let controller: Controller
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var iconReset: Task<Void, Never>?

    init(controller: Controller) {
        self.controller = controller
        super.init()
        statusItem.menu = NSMenu()
        statusItem.menu?.delegate = self
        statusItem.button?.setAccessibilityLabel(AppInfo.name)
        controller.onChange = { [weak self] in self?.refresh() }
        controller.onSlap = { [weak self] in self?.showSlap() }
        refresh()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        controller.voice.load()
        menu.items = items
    }

    private func refresh(icon: String? = nil) {
        let icon = icon ?? (controller.isActive ? Self.idleIcon : Self.pausedIcon)
        statusItem.button?.title = Settings.showsCount ? "\(icon) \(Stats.total.formatted())" : icon
    }

    private func showSlap() {
        iconReset?.cancel()
        refresh(icon: Self.slapIcon)
        iconReset = Task { [weak self] in
            guard (try? await Task.sleep(for: Self.slapIconDuration)) != nil else { return }
            self?.refresh()
        }
    }

    private var items: [NSMenuItem] {
        var items: [NSMenuItem] = [.info("Sensor: \(controller.sensor.summary)"), .info(statsLine), .separator()]
        items += [setting("Enabled", checked: Settings.isEnabled) { Settings.isEnabled.toggle() }, snoozeMenu, .separator()]
        items += soundSection + [.separator()]
        items += effectsSection + [.separator()]
        items += [.action("Test Slap", key: "t") { [controller] in controller.test() }, .separator()]
        items += [setting("Show Count in Menu Bar", checked: Settings.showsCount) { Settings.showsCount.toggle() }]
        if AppInfo.isBundled { items += [loginItem] }
        items += [.action("Reset Stats…") { [weak self] in self?.resetStats() }, .separator()]
        items += [
            .action("About \(AppInfo.name)", Self.showAbout),
            .action("Quit \(AppInfo.name)", key: "q") { NSApp.terminate(nil) },
        ]
        return items
    }

    private var statsLine: String {
        let hardest = Stats.hardest > 0 ? "\(Stats.hardest.formatted(.number.precision(.fractionLength(1)))) g" : "—"
        return "Slaps: \(Stats.total.formatted())  ·  Today: \(Stats.today.formatted())  ·  Hardest: \(hardest)"
    }

    private var snoozeMenu: NSMenuItem {
        let options = Snooze.allCases.map { option in setting(option.title) { Settings.snoozedUntil = option.end() } }
        guard controller.isSnoozed else { return .submenu("Snooze", options) }
        let until = Settings.snoozedUntil
        let style: Date.FormatStyle = Calendar.current.isDateInToday(until)
            ? .dateTime.hour().minute()
            : .dateTime.weekday(.abbreviated).hour().minute()
        let resume = setting("Resume Now") { Settings.snoozedUntil = .distantPast }
        return .submenu("Snoozed Until \(until.formatted(style))", [resume, .separator()] + options)
    }

    private var soundSection: [NSMenuItem] {
        let folder = Settings.soundsFolder
        let count = folder.map { Voice.sounds(in: $0).count } ?? 0
        let custom = Settings.usesSoundsFolder ? folder : nil

        var choices = [setting("Robot Voice", checked: custom == nil) { Settings.usesSoundsFolder = false }]
        if let folder {
            let item = setting(folder.lastPathComponent, checked: custom != nil) { Settings.usesSoundsFolder = true }
            item.badge = count > 0 ? NSMenuItemBadge(count: count) : NSMenuItemBadge(string: "Empty")
            choices += [item]
        }
        choices += [.separator(), .action("Choose Folder…") { [weak self] in self?.chooseSoundsFolder() }]
        if let folder {
            choices += [.action("Show in Finder") { NSWorkspace.shared.activateFileViewerSelecting([folder]) }]
        }

        var items: [NSMenuItem] = [
            .sectionHeader(title: "Sound"),
            .submenu("Sounds: \(custom?.lastPathComponent ?? "Robot Voice")", choices),
        ]
        if let custom, count == 0 {
            items += [.info("No sounds in \(custom.lastPathComponent), using Robot Voice", indented: true)]
        }
        items += [
            .slider(value: Settings.volume, indented: false, caption: { "Volume \(Int(($0 * 100).rounded()))%" }) {
                Settings.volume = $0
            },
            setting("Dynamic Volume", checked: Settings.dynamicVolume) { Settings.dynamicVolume.toggle() },
            .submenu("Sensitivity: \(Settings.sensitivity.title)", Sensitivity.allCases.map { level in
                setting(level.title, checked: Settings.sensitivity == level) { Settings.sensitivity = level }
            }),
            .submenu("Cooldown: \(Settings.cooldown.title)", Cooldown.allCases.map { cooldown in
                setting(cooldown.title, checked: Settings.cooldown == cooldown) { Settings.cooldown = cooldown }
            }),
        ]
        return items
    }

    private var effectsSection: [NSMenuItem] {
        [.sectionHeader(title: "Effects")]
            + controller.effects.flatMap(effectItems)
            + [setting("USB Moaner", checked: Settings.usbMoaner) { Settings.usbMoaner.toggle() }]
    }

    private func effectItems(_ effect: any Effect) -> [NSMenuItem] {
        if let reason = effect.unavailable {
            let item = NSMenuItem.info(effect.title)
            item.badge = NSMenuItemBadge(string: reason)
            return [item]
        }
        let toggle = setting(effect.title, checked: effect.isOn) { effect.isOn.toggle() }
        guard effect.isOn else { return [toggle] }
        return [toggle, .slider(value: effect.level, caption: { _ in "Intensity" }) { effect.level = $0 }]
    }

    private var loginItem: NSMenuItem {
        guard !LoginItem.needsApproval else {
            return .action("Launch at Login (Needs Approval)…", LoginItem.openSettings)
        }
        return .action("Launch at Login", checked: LoginItem.isEnabled) {
            LoginItem.isEnabled.toggle()
            if LoginItem.needsApproval { LoginItem.openSettings() }
        }
    }

    private func setting(_ title: String, checked: Bool? = nil, change: @escaping () -> Void) -> NSMenuItem {
        .action(title, checked: checked) { [controller] in
            change()
            controller.apply()
        }
    }

    private func chooseSoundsFolder() {
        NSApp.activate()
        let panel = NSOpenPanel()
        panel.message = "Choose a folder of sounds. Each slap plays a random one: \(Voice.extensions.sorted().joined(separator: ", "))."
        panel.prompt = "Use Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = Settings.soundsFolder
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Settings.soundsFolder = url
        Settings.usesSoundsFolder = true
        controller.apply()
    }

    private func resetStats() {
        let message = "Your total (\(Stats.total.formatted())), today's count and hardest slap will be cleared."
        guard showAlert("Reset slap stats?", message, buttons: ["Reset", "Cancel"], destructive: true) else { return }
        Stats.reset()
        refresh()
    }

    private static func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: AppInfo.name,
            .applicationVersion: AppInfo.version,
            .credits: NSAttributedString(
                string: "Slap your MacBook and it screams back.\nFree, open source, and fully offline.",
                attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]
            ),
        ])
    }
}
