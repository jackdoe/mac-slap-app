import AppKit

private final class Handler: NSObject {
    private let body: () -> Void

    init(_ body: @escaping () -> Void) {
        self.body = body
    }

    @objc func fire() { body() }
}

extension NSMenuItem {
    static func action(_ title: String, key: String = "", checked: Bool? = nil, _ body: @escaping () -> Void) -> NSMenuItem {
        let handler = Handler(body)
        let item = NSMenuItem(title: title, action: #selector(Handler.fire), keyEquivalent: key)
        item.target = handler
        item.representedObject = handler
        if let checked { item.state = checked ? .on : .off }
        return item
    }

    static func slider(
        value: Double,
        indented: Bool = true,
        caption: @escaping (Double) -> String,
        _ body: @escaping (Double) -> Void
    ) -> NSMenuItem {
        let label = NSTextField(labelWithString: caption(value))
        label.font = .menuFont(ofSize: 0)
        label.textColor = .secondaryLabelColor
        label.frame = NSRect(x: indented ? 42 : 30, y: 5, width: 84, height: 16)

        let slider = NSSlider(value: value, minValue: 0, maxValue: 1, target: nil, action: #selector(Handler.fire))
        slider.controlSize = .small
        slider.frame = NSRect(x: 118, y: 4, width: 128, height: 18)
        let handler = Handler {
            label.stringValue = caption(slider.doubleValue)
            body(slider.doubleValue)
        }
        slider.target = handler

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 26))
        container.addSubview(label)
        container.addSubview(slider)
        let item = NSMenuItem()
        item.view = container
        item.representedObject = handler
        return item
    }

    static func info(_ title: String, indented: Bool = false) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.indentationLevel = indented ? 1 : 0
        return item
    }

    static func submenu(_ title: String, _ items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = NSMenu()
        item.submenu?.items = items
        return item
    }
}
