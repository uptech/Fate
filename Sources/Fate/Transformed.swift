import Foundation

extension Fate.Future {
    func transformed<NextValue, EM: Error>(with closure: @escaping (V) throws -> NextValue) -> Future<NextValue, EM> {
        return chained { value in
            return try Promise(value: closure(value))
        }
    }
}
