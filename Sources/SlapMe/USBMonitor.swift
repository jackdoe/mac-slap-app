import Foundation
import IOKit
import IOKit.usb

final class USBMonitor {
    static let debounce = Duration.milliseconds(1500)

    var onChange: (() -> Void)?

    private var port: IONotificationPortRef?
    private var iterators: [io_iterator_t] = []
    private var lastChange: ContinuousClock.Instant?

    func start() {
        guard port == nil, let port = IONotificationPortCreate(kIOMainPortDefault) else { return }
        self.port = port
        IONotificationPortSetDispatchQueue(port, .main)
        let context = Unmanaged.passUnretained(self).toOpaque()
        for notification in [kIOFirstMatchNotification, kIOTerminatedNotification] {
            var iterator: io_iterator_t = 0
            let added = IOServiceAddMatchingNotification(port, notification, IOServiceMatching(kIOUSBHostDeviceClassName), { context, iterator in
                guard drain(iterator) else { return }
                MainActor.assumeIsolated { Unmanaged<USBMonitor>.fromOpaque(context!).takeUnretainedValue().changed() }
            }, context, &iterator)
            guard added == KERN_SUCCESS else { continue }
            drain(iterator)
            iterators.append(iterator)
        }
    }

    func stop() {
        guard let port else { return }
        iterators.forEach { IOObjectRelease($0) }
        iterators.removeAll()
        IONotificationPortDestroy(port)
        self.port = nil
    }

    private func changed() {
        let now = ContinuousClock.now
        if let lastChange, now - lastChange < Self.debounce { return }
        lastChange = now
        onChange?()
    }
}

@discardableResult
private nonisolated func drain(_ iterator: io_iterator_t) -> Bool {
    var drained = false
    while case let entry = IOIteratorNext(iterator), entry != IO_OBJECT_NULL {
        IOObjectRelease(entry)
        drained = true
    }
    return drained
}
