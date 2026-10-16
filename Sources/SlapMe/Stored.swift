import Foundation

nonisolated protocol Storable: Sendable {
    init?(stored: Any)
    var stored: Any? { get }
}

nonisolated extension Storable {
    init?(stored: Any) {
        guard let value = stored as? Self else { return nil }
        self = value
    }

    var stored: Any? { self }
}

nonisolated extension Storable where Self: RawRepresentable, RawValue: Storable {
    init?(stored: Any) {
        guard let raw = RawValue(stored: stored) else { return nil }
        self.init(rawValue: raw)
    }

    var stored: Any? { rawValue.stored }
}

nonisolated extension Optional: Storable where Wrapped: Storable {
    init?(stored: Any) {
        guard let value = Wrapped(stored: stored) else { return nil }
        self = value
    }

    var stored: Any? { self?.stored }
}

extension Bool: Storable {}
extension Int: Storable {}
extension Double: Storable {}
extension String: Storable {}
extension Date: Storable {}

nonisolated extension URL: Storable {
    init?(stored: Any) {
        guard let path = stored as? String else { return nil }
        self.init(filePath: path, directoryHint: .isDirectory)
    }

    var stored: Any? { path(percentEncoded: false) }
}

@propertyWrapper
struct Stored<Value: Storable> {
    let key: String
    let fallback: Value

    init(wrappedValue: Value, _ key: String) {
        self.key = key
        fallback = wrappedValue
    }

    var wrappedValue: Value {
        get { UserDefaults.standard.object(forKey: key).flatMap(Value.init(stored:)) ?? fallback }
        nonmutating set { UserDefaults.standard.set(newValue.stored, forKey: key) }
    }
}
