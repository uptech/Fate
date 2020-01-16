extension Fate.Future {
    func chained<NextValue, EM: Error>(with closure: @escaping (V) throws -> Future<NextValue, EM>) -> Future<NextValue, EM> {
        let promise = Promise<NextValue, EM>()

        self.observe { result in
            switch result {
            case .success(let value):
                do {
                    let future = try closure(value)

                    future.observe { result in
                        switch result {
                        case .success(let value):
                            try! promise.resolve(with: value)
                        case .failure(let error):
                            try! promise.reject(with: error)
                        }
                    }
                } catch {
                    try! promise.reject(with: error as! EM)
                }
            case .failure(let err):
                try! promise.reject(with: err as! EM)
            }
        }

        return promise
    }
}
