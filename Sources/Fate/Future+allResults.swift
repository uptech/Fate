import Foundation

extension Fate.Future {
    public static func allResults<T, EM>(_ futures: [Future<T, EM>]) -> Future<[Result<T, EM>], FateError> {
        let promise = Promise<[Result<T, EM>], FateError>()

        guard !futures.isEmpty else {
            try! promise.resolve(with: [])
            return promise
        }

        var countdown = futures.count
        let dispatchQueue = DispatchQueue(label: "ch.upte.Fate.Future.allResults")

        futures.forEach { (future) in
            future.observe { _ in
                dispatchQueue.sync() {
                    countdown -= 1
                    if countdown == 0 {
                        try! promise.resolve(with: futures.map({ $0.result! }))
                    } else if countdown < 0 {
                        fatalError("Fate.Future.allResults<T, EM>(_ futures: [Future<T, EM>]) -> Future<[Result<T, EM>]> - countdown went negative")
                    }
                }
            }
        }

        return promise
    }
}
