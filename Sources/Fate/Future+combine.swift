import Foundation

extension Fate.Future {
    public static func combine<FA: Fate.Observable, FB: Fate.Observable>(_ fa: FA, _ fb: FB) -> Future<(Result<FA.T, FA.E>, Result<FB.T, FB.E>), FateError> {
        let promise = Promise<(Result<FA.T, FA.E>, Result<FB.T, FB.E>), FateError>()
        let dispatchGroup = DispatchGroup()

        var faResult: Result<FA.T, FA.E>?
        var fbResult: Result<FB.T, FB.E>?

        dispatchGroup.enter()
        dispatchGroup.enter()

        fa.observe { result in
            faResult = result
            dispatchGroup.leave()
        }

        fb.observe { result in
            fbResult = result
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: DispatchQueue.global()) {
            if let aResult = faResult, let bResult = fbResult {
                try! promise.resolve(with: (aResult, bResult))
            } else {
                try! promise.reject(with: .unexpectedlyMissingResult)
            }
        }

        return promise
    }
}
