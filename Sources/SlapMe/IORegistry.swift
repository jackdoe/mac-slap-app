import Foundation
import IOKit

nonisolated enum IORegistry {
    static func withService<Result>(
        _ className: String,
        matching properties: [String: Any],
        _ body: (io_service_t) -> Result?
    ) -> Result? {
        let matching = IOServiceMatching(className) as NSMutableDictionary
        matching[kIOPropertyMatchKey] = properties
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != IO_OBJECT_NULL else { return nil }
        defer { IOObjectRelease(service) }
        return body(service)
    }

    static func property<Value>(_ key: String, of service: io_service_t) -> Value? {
        IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Value
    }

    static func set(_ properties: [String: Int], on service: io_service_t) {
        for (key, value) in properties {
            IORegistryEntrySetCFProperty(service, key as CFString, value as CFNumber)
        }
    }
}
