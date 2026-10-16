import CoreGraphics
import Foundation

private func symbol<Function>(_ framework: String, _ name: String, as type: Function.Type) -> Function? {
    let path = "/System/Library/PrivateFrameworks/\(framework).framework/\(framework)"
    guard let handle = dlopen(path, RTLD_LAZY), let address = dlsym(handle, name) else { return nil }
    return unsafeBitCast(address, to: type)
}

enum DisplayServices {
    static let brightness = symbol(
        "DisplayServices", "DisplayServicesGetBrightness",
        as: (@convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32).self
    )
    static let setBrightness = symbol(
        "DisplayServices", "DisplayServicesSetBrightness",
        as: (@convention(c) (CGDirectDisplayID, Float) -> Int32).self
    )
    static let canChangeBrightness = symbol(
        "DisplayServices", "DisplayServicesCanChangeBrightness",
        as: (@convention(c) (CGDirectDisplayID) -> Bool).self
    )
}

enum Multitouch {
    static let createActuator = symbol(
        "MultitouchSupport", "MTActuatorCreateFromDeviceID",
        as: (@convention(c) (UInt64) -> Unmanaged<CFTypeRef>?).self
    )
    static let openActuator = symbol(
        "MultitouchSupport", "MTActuatorOpen",
        as: (@convention(c) (CFTypeRef) -> Int32).self
    )
    static let closeActuator = symbol(
        "MultitouchSupport", "MTActuatorClose",
        as: (@convention(c) (CFTypeRef) -> Int32).self
    )
    static let actuate = symbol(
        "MultitouchSupport", "MTActuatorActuate",
        as: (@convention(c) (CFTypeRef, Int32, UInt32, Float, Float) -> Int32).self
    )
}
