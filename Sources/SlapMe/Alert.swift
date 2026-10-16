import AppKit

@discardableResult
func showAlert(_ title: String, _ message: String, buttons: [String] = ["OK"], destructive: Bool = false) -> Bool {
    NSApp.activate()
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    buttons.forEach { alert.addButton(withTitle: $0) }
    alert.buttons.first?.hasDestructiveAction = destructive
    return alert.runModal() == .alertFirstButtonReturn
}
