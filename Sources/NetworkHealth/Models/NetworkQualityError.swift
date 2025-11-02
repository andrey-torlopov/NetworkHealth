import Foundation

/// Errors that can occur during network quality checking operations
public enum NetworkQualityError: Error, Sendable {
    /// Network is offline or unavailable
    case offline

    /// Speed tester was not configured
    case speedTesterNotConfigured

    /// Speed measurement failed
    case measurementFailed(any Error)

    /// Measurement timed out
    case measurementTimeout

    /// Invalid configuration
    case invalidConfiguration(String)
}

// MARK: - LocalizedError

extension NetworkQualityError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .offline:
            return "Network is offline or unavailable"
        case .speedTesterNotConfigured:
            return "Speed tester was not configured. Please provide a SpeedTester in configuration."
        case .measurementFailed(let error):
            return "Speed measurement failed: \(error.localizedDescription)"
        case .measurementTimeout:
            return "Speed measurement timed out"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}
