import Foundation
import SlapCore

final class Sensor {
    enum Status: Equatable, CustomStringConvertible {
        case off, starting, live, missing
        case stalled(String)

        var description: String {
            switch self {
            case .off: "Paused"
            case .starting: "Starting…"
            case .live: "Live"
            case .missing: "No motion sensor (needs an Apple Silicon MacBook)"
            case .stalled(let reason): "Reconnecting (\(reason))"
            }
        }
    }

    static let watchdogInterval = Duration.seconds(1)
    static let stallTimeout = Duration.seconds(3)
    static let firstRetry = Duration.seconds(1)
    static let lastRetry = Duration.seconds(60)

    private(set) var status = Status.off {
        didSet { if status != oldValue { onStatusChange?() } }
    }

    var onStatusChange: (() -> Void)?
    var onSlap: ((Slap) -> Void)?
    var sensitivity = Sensitivity.medium {
        didSet { stream?.sensitivity = sensitivity }
    }

    var summary: String {
        guard status == .live, let rate = stream?.rate else { return status.description }
        return "\(status) (\(Int(rate.rounded())) Hz)"
    }

    private var stream: SensorStream?
    private var watchdog: Task<Void, Never>?
    private var retryDelay = Sensor.firstRetry
    private var retryAt = ContinuousClock.now

    func start() {
        guard watchdog == nil else { return }
        retryDelay = Self.firstRetry
        open()
        guard status != .missing else { return }
        watchdog = Task { [weak self] in
            while (try? await Task.sleep(for: Self.watchdogInterval)) != nil {
                self?.inspect()
            }
        }
    }

    func stop() {
        watchdog?.cancel()
        watchdog = nil
        close()
        status = .off
    }

    private func open() {
        do {
            stream = try SensorStream(sensitivity: sensitivity) { [weak self] slap in self?.onSlap?(slap) }
            status = .starting
        } catch .missing {
            status = .missing
        } catch {
            status = .stalled(error.description)
            scheduleRetry()
        }
    }

    private func close() {
        stream?.cancel()
        stream = nil
    }

    private func inspect() {
        guard let stream else {
            if ContinuousClock.now >= retryAt { open() }
            return
        }
        if stream.silence >= Self.stallTimeout {
            close()
            status = .stalled("no reports for \(Self.stallTimeout)")
            scheduleRetry()
        } else if stream.rate != nil {
            status = .live
            retryDelay = Self.firstRetry
        }
    }

    private func scheduleRetry() {
        retryAt = .now + retryDelay
        retryDelay = min(retryDelay * 2, Self.lastRetry)
    }
}
