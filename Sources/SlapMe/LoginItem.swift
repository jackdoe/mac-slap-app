import ServiceManagement

enum LoginItem {
    static var needsApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    static var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set { try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister() }
    }

    static func openSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
