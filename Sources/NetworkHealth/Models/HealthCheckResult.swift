/// Result of a network health check.
public struct HealthCheckResult: Sendable {
    /// Whether the check passed
    public let passed: Bool

    /// Optional reason for failure or warning message
    public let reason: String?

    public init(passed: Bool, reason: String?) {
        self.passed = passed
        self.reason = reason
    }
}
