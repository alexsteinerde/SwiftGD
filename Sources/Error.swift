import Foundation

/// Represents errors that can be thrown within the module.
// TODO: Add a distinct error cases
// TODO: Describe errors
public enum Error: Swift.Error {
    case invalidFormat
    case errorReadingFile(reason: String)
    case errorWritingFile(reason: String)
    case invalidImage(reason: String) // The reason this error was thrown
    case invalidColor(reason: String) // The reason this error was thrown.
    case resizingFailed(reason: String)
    case croppingFailed(reason: String)
    case manipulationFailed(reason: String)
}

// MARK: - Convenience

// Reference: http://appventure.me/2018/01/10/optional-extensions/
extension Optional {

    /// Returns the unwrapped value of the optional if it is not empty, throws given error otherwise.
    ///
    /// - Parameter exception: The exception to throw if the wrapped value is `nil`.
    /// - Returns: The unwrapped value of the optional if it is not empty
    /// - Throws: Given error if the wrapped value is `nil`
    internal func or(throw exception: Error) throws -> Wrapped {
        guard let unwrapped = self else { throw exception }
        return unwrapped
    }
}
