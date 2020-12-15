import Foundation

extension Fate.Future {
    public func mapError<NextError>(with closure: @escaping (E) -> NextError) -> Future<V, NextError> {
        let promise = Promise<V, NextError>()

        self.observe { result in
            switch result {
            case .success(let v):
                try! promise.resolve(with: v)
            case .failure(let err):
                try! promise.reject(with: closure(err))
            }
        }

        return promise
    }
}
