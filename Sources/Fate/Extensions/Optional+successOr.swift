import Foundation

extension Optional {
    public func successOr<E: Error>(_ error: E) -> Future<Wrapped, E> {
        if let v = self {
            return Promise<Wrapped, E>(value: v)
        } else {
            return Promise<Wrapped, E>(error: error)
        }
    }
}
