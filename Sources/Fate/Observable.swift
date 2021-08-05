import Foundation

public protocol Observable: AnyObject {
    associatedtype T
    associatedtype E: Error

    func observe(with callback: @escaping (Result<T, E>) -> Void)
}
