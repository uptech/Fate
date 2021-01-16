extension Fate.Future {
    public func chained<NextValue>(with closure: @escaping (V) -> Future<NextValue, ER>) -> Future<NextValue, ER> {
        let promise = Promise<NextValue, ER>()

        self.observe { result in
            switch result {
            case .success(let value):
                let future = closure(value)

                future.observe { result in
                    switch result {
                    case .success(let value):
                        try! promise.resolve(with: value)
                    case .failure(let error):
                        try! promise.reject(with: error)
                    }
                }
            case .failure(let err):
                try! promise.reject(with: err)
            }
        }

        return promise
    }
}
