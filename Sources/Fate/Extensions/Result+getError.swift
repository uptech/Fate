import Foundation

extension Result {
    public func getError() -> Failure? {
        switch self {
        case .success(_):
            return nil
        case .failure(let e):
            return e
        }
    }
}
