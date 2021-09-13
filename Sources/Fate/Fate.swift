import Foundation
import os.log

public class Future<V, ER: Error>: Fate.Observable {
    let callbacksSemaphore = DispatchSemaphore(value: 1)

    public var result: Result<V, ER>? { return self._result }
    fileprivate var _result: Result<V, ER>? {
        didSet {
            { [weak self] in
                let _ = self?._result.map(report) // report immediately when set to actual result
            }()
        }
    }
    private lazy var callbacks = [(Result<V, ER>) -> Void]()

    public func observe(with callback: @escaping (Result<V, ER>) -> Void) {
        let callbackWrapper = { (result: Result<V, ER>) in
            // Note: Here we explicitly create a retain cycle between the
            // callbackWrapper & self (a.k.a. Future)
            // and self & callbackWrapper. This prevents the Future from
            // being deallocated prior to the callbacks being executed.
            let _ = self
            callback(result)
        }

        callbacksSemaphore.wait()
        callbacks.append(callbackWrapper)
        callbacksSemaphore.signal()

        let _ = self._result.map(callback) // call callback immediately if already has result
    }

    public func cancel() {
        callbacksSemaphore.wait()
        self.callbacks = []
        callbacksSemaphore.signal()
    }

    public func wait() -> Result<V, ER> {
        let semaphore = DispatchSemaphore(value: 0)
        self.observe { (_) in
            semaphore.signal()
        }
        semaphore.wait()
        return self.result!
    }

    private func report(result: Result<V, ER>) {
        callbacksSemaphore.wait()
        for callback in callbacks {
            callback(result)
        }
        // Note: Here we explicitly clear the callbacks (and their
        // callbackWrappers) so that the explicit retain cycle made in the
        // observe(with:) call are broken. In turn allowing the Future to
        // be deallocated.
        self.callbacks = []
        callbacksSemaphore.signal()
    }

    deinit {
        self.callbacksSemaphore.signal()
        if #available(iOS 12.0, macOS 11.0, *) {
            os_log(.debug, log: .default, "Fate.Future(%{public}@).deinit", ObjectIdentifier(self).debugDescription)
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

    public init(error: E) {
        super.init()
        self._result = Result.failure(error)
    }

    public init(result: Result<V, E>) {
        super.init()
        self._result = result
    }

    public func resolve(with value: V) throws {
        guard self.result == nil else { throw FateError.alreadyResolvedOrRejected }
        self._result = Result.success(value)
    }

    public func reject(with error: E) throws {
        guard self.result == nil else { throw FateError.alreadyResolvedOrRejected }
        self._result = Result.failure(error)
    }
}

extension Fate.Future {
    public static func all<T, EM>(_ futures: [Future<[T], EM>]) -> Future<[T], EM> {
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

    public static func all<T, EM>(_ futures: [Future<T, EM>]) -> Future<Void, EM> {
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

    public static func all<T, EM>(_ futures: [Future<T, EM>]) -> Future<[T], EM> {
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
