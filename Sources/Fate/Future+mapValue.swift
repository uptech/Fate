import Foundation

extension Fate.Future {
    public func mapValue<NextValue>(with closure: @escaping (V) -> NextValue) -> Future<NextValue, ER> {
        return chained { value in
            return Promise(value: closure(value))
        }
    }
}
