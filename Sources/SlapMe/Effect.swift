import AppKit

protocol Effect: AnyObject {
    var title: String { get }
    var isOn: Bool { get set }
    var level: Double { get set }
    var unavailable: String? { get }
    func play(_ strength: Double)
}

extension Effect {
    var unavailable: String? { nil }
}

extension NSPanel {
    static func overlay(_ frame: NSRect) -> NSPanel {
        let panel = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .screenSaver
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.sharingType = .none
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        return panel
    }
}
