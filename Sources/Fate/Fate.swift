import Foundation

public class Future<V, ER: Error>: Fate.Observable {
    public typealias T = V
    public typealias E = ER
    let dispatchQueue = DispatchQueue(label: "ch.upte.Fate.Future.callbacks", attributes: .concurrent)

    public var result: Result<V, ER>? { return self._result }
    fileprivate var _result: Result<V, ER>? {
        didSet { let _ = _result.map(report) } // report immediately when set to actual result
    }
    private lazy var callbacks = [(Result<V, ER>) -> Void]()

    public func observe(with callback: @escaping (Result<V, ER>) -> Void) {
        dispatchQueue.sync(flags: .barrier) {
            callbacks.append(callback)
        }

        let _ = self._result.map(callback) // call callback immediately if already has result
    }

    private func report(result: Result<V, ER>) {
        dispatchQueue.sync() {
            for callback in callbacks {
                callback(result)
            }
        }
    }
}

public class Promise<V, E: Error>: Fate.Future<V, E> {
    public init(value: V? = nil) {
        super.init()

        if let val = value {
            self._result = Result.success(val)
        }
    }

    func resolve(with value: V) throws {
        guard self.result == nil else { throw FateError.alreadyResolvedOrRejected }
        self._result = Result.success(value)
    }

    func reject(with error: E) throws {
        guard self.result == nil else { throw FateError.alreadyResolvedOrRejected }
        self._result = Result.failure(error)
    }
}

extension Fate.Future {
    static func all<T, EM>(_ futures: [Future<[T], EM>]) -> Future<[T], EM> {
        let promise = Promise<[T], EM>()

        guard !futures.isEmpty else {
            try! promise.resolve(with: [])
            return promise
        }

        var countdown = futures.count
        let dispatchQueue = DispatchQueue(label: "ch.upte.Fate.Future.all")

        futures.forEach { (future) in
            future.observe { result in
                dispatchQueue.sync() {
                    countdown -= 1
                    if countdown == 0 {
                        let errors: [EM] = futures.compactMap({ $0.result!.getError() })

                        if errors.isEmpty {
                            try! promise.resolve(with: futures.compactMap({ try? $0.result!.get() }).flatMap({ $0 }))
                        } else {
                            try! promise.reject(with: errors.first!)
                        }
                    } else if countdown < 0 {
                        fatalError("Fate.Future.all<T, EM>(_ futures: [Future<[T], EM>]) -> Future<[T], EM> - countdown went negative")
                    }
                }
            }
        }

        return promise
    }

    static func all<T, EM>(_ futures: [Future<T, EM>]) -> Future<Void, EM> {
        let promise = Promise<Void, EM>()

        guard !futures.isEmpty else {
            try! promise.resolve(with: ())
            return promise
        }

        var countdown = futures.count
        let dispatchQueue = DispatchQueue(label: "ch.upte.Fate.Future.all.void")

        futures.forEach { (future) in
            future.observe { result in
                dispatchQueue.sync() {
                    countdown -= 1
                    if countdown == 0 {
                        let errors: [EM] = futures.compactMap({ $0.result!.getError() })

                        if errors.isEmpty {
                            try! promise.resolve(with: ())
                        } else {
                            try! promise.reject(with: errors.first!)
                        }
                    } else if countdown < 0 {
                        fatalError("Fate.Future.all<T, EM>(_ futures: [Future<T, EM>]) -> Future<Void, EM> - countdown went negative")
                    }
                }
            }
        }

        return promise
    }

    static func all<T, EM>(_ futures: [Future<T, EM>]) -> Future<[T], EM> {
        let promise = Promise<[T], EM>()

        guard !futures.isEmpty else {
            try! promise.resolve(with: [])
            return promise
        }

        var countdown = futures.count
        let dispatchQueue = DispatchQueue(label: "ch.upte.Fate.Future.all")

        futures.forEach { (future) in
            future.observe { result in
                dispatchQueue.sync() {
                    countdown -= 1
                    if countdown == 0 {
                        let errors: [EM] = futures.compactMap({ $0.result!.getError() })

                        if errors.isEmpty {
                            try! promise.resolve(with: futures.compactMap() { try? $0.result!.get() })
                        } else {
                            try! promise.reject(with: errors.first!)
                        }
                    } else if countdown < 0 {
                        fatalError("Future.all<T, EM>(_ futures: [Future<T, EM>]) -> Future<[T], EM> - countdown went negative")
                    }
                }
            }
        }

        return promise
    }
}
