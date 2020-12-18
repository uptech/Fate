import Foundation

extension Fate.Future {
    public func mapValue<NextValue>(with closure: @escaping (V) -> NextValue) -> Future<NextValue, ER> {
        let promise = Promise<NextValue, ER>()

        self.observe { (result) in
            switch result {
            case .success(let v):
                try! promise.resolve(with: closure(v))
            case .failure(let error):
                try! promise.reject(with: error)
            }
        }

        return promise
    }
}
