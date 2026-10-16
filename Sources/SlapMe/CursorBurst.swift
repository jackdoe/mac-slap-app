import AppKit

final class CursorBurst: Effect {
    let title = "Cursor Burst"
    @Stored("burst") var isOn = true
    @Stored("burstLevel") var level = 0.6

    static let duration = 0.45
    static let rays = 12
    static let ringRadius = 0.55
    static let ringGrowth = 0.4...1.0
    static let rayGrowth = 0.6...1.15

    func play(_ strength: Double) {
        let reach = 50 + 70 * min(strength, 2)
        let side = 2.5 * reach
        let pointer = NSEvent.mouseLocation
        let panel = NSPanel.overlay(NSRect(x: pointer.x - side / 2, y: pointer.y - side / 2, width: side, height: side))
        let view = NSView(frame: NSRect(x: 0, y: 0, width: side, height: side))
        view.wantsLayer = true

        let center = CGPoint(x: side / 2, y: side / 2)
        func point(_ angle: Double, _ distance: Double) -> CGPoint {
            CGPoint(x: center.x + cos(angle) * reach * distance, y: center.y + sin(angle) * reach * distance)
        }
        let radius = Self.ringRadius * reach
        let ring = CGPath(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: 2 * radius, height: 2 * radius), transform: nil)
        let rays = CGMutablePath()
        for index in 0..<Self.rays {
            let angle = 2 * .pi * Double(index) / Double(Self.rays)
            rays.move(to: point(angle, 0.72))
            rays.addLine(to: point(angle, index.isMultiple(of: 2) ? 1.0 : 0.86))
        }

        for (path, width, growth) in [(ring, 6.0, Self.ringGrowth), (rays as CGPath, 7.0, Self.rayGrowth)] {
            let layer = CAShapeLayer()
            layer.frame = view.bounds
            layer.path = path
            layer.fillColor = nil
            layer.strokeColor = NSColor.systemPink.cgColor
            layer.lineWidth = width
            layer.lineCap = .round
            layer.shadowColor = .black
            layer.shadowOpacity = 0.35
            layer.shadowRadius = 3
            layer.shadowOffset = .zero
            layer.opacity = 0
            layer.add(Self.burst(growth), forKey: "burst")
            view.layer?.addSublayer(layer)
        }

        panel.contentView = view
        panel.orderFrontRegardless()
        Task {
            try? await Task.sleep(for: .seconds(Self.duration))
            panel.orderOut(nil)
        }
    }

    private static func burst(_ growth: ClosedRange<Double>) -> CAAnimation {
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = growth.lowerBound
        scale.toValue = growth.upperBound
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = duration
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        return group
    }
}
