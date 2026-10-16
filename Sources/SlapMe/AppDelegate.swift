import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menu: StatusMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard isOnlyInstance else { return NSApp.terminate(nil) }
        NSApp.setActivationPolicy(.accessory)

        if AppInfo.isInstalled && !Settings.enrolledLoginItem {
            Settings.enrolledLoginItem = true
            LoginItem.isEnabled = true
        }

        let controller = Controller()
        menu = StatusMenu(controller: controller)
        controller.apply()
    }

    private var isOnlyInstance: Bool {
        guard let identifier = Bundle.main.bundleIdentifier else { return true }
        return NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .allSatisfy { $0 == .current || $0.isTerminated }
    }
}
