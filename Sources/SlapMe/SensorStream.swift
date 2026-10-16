import Foundation
import IOKit.hid
import SlapCore
import Synchronization

nonisolated final class SensorStream: @unchecked Sendable {
    enum Failure: Error, CustomStringConvertible {
        case missing
        case unopenable(IOReturn)

        var description: String {
            switch self {
            case .missing: "no accelerometer"
            case .unopenable(let code): "open failed: 0x\(String(UInt32(bitPattern: code), radix: 16))"
            }
        }
    }

    static let accelerometer = ["PrimaryUsagePage": 0xFF00, "PrimaryUsage": 3]
    static let wake = ["SensorPropertyReportingState": 1, "SensorPropertyPowerState": 1, "ReportInterval": 1000]
    static let reportCapacity = 64
    static let rateWindow = Duration.seconds(1)

    private struct State {
        var detector: SlapDetector
        var heard = ContinuousClock.now
        var rate: Double?
        var window: (start: ContinuousClock.Instant, samples: Int)?

        mutating func ingest(_ acceleration: SIMD3<Double>, at now: ContinuousClock.Instant) -> Slap? {
            heard = now
            measure(at: now)
            return rate.flatMap { detector.process(acceleration, period: 1 / $0) }
        }

        private mutating func measure(at now: ContinuousClock.Instant) {
            guard let current = window else {
                window = (now, 0)
                return
            }
            let elapsed = now - current.start
            if elapsed >= SensorStream.rateWindow {
                rate = Double(current.samples + 1) / (elapsed / .seconds(1))
                window = (now, 0)
            } else {
                window = (current.start, current.samples + 1)
            }
        }
    }

    private let device: IOHIDDevice
    private let buffer: UnsafeMutablePointer<UInt8>
    private let queue = DispatchQueue(label: "\(AppInfo.name).sensor", qos: .userInteractive)
    private let state: Mutex<State>
    private let deliver: @MainActor (Slap) -> Void

    init(sensitivity: Sensitivity, deliver: @escaping @MainActor (Slap) -> Void) throws(Failure) {
        guard let device = IORegistry.withService("AppleSPUHIDDevice", matching: Self.accelerometer, {
            IOHIDDeviceCreate(kCFAllocatorDefault, $0)
        }) else { throw .missing }

        let opened = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard opened == kIOReturnSuccess else { throw .unopenable(opened) }
        IORegistry.withService("AppleSPUHIDDriver", matching: Self.accelerometer) {
            IORegistry.set(Self.wake, on: $0)
        }

        self.device = device
        self.buffer = .allocate(capacity: Self.reportCapacity)
        self.state = Mutex(State(detector: SlapDetector(sensitivity: sensitivity)))
        self.deliver = deliver

        IOHIDDeviceRegisterInputReportCallback(device, buffer, Self.reportCapacity, { context, _, _, _, _, report, length in
            Unmanaged<SensorStream>.fromOpaque(context!).takeUnretainedValue()
                .receive(UnsafeRawBufferPointer(start: report, count: length))
        }, Unmanaged.passUnretained(self).toOpaque())
        IOHIDDeviceSetDispatchQueue(device, queue)
        IOHIDDeviceSetCancelHandler(device) { [self] in
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
            buffer.deallocate()
        }
        IOHIDDeviceActivate(device)
    }

    var sensitivity: Sensitivity {
        get { state.withLock { $0.detector.sensitivity } }
        set { state.withLock { $0.detector.sensitivity = newValue } }
    }

    var rate: Double? { state.withLock { $0.rate } }

    var silence: Duration { state.withLock { .now - $0.heard } }

    func cancel() {
        IOHIDDeviceCancel(device)
    }

    private func receive(_ report: UnsafeRawBufferPointer) {
        guard let acceleration = AccelerometerReport.decode(report),
              let slap = state.withLock({ $0.ingest(acceleration, at: .now) })
        else { return }
        Task { @MainActor [deliver] in deliver(slap) }
    }
}
