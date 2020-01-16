import Foundation

public enum FateError: Error {
    case alreadyResolvedOrRejected
    case unexpectedlyMissingResult
}
