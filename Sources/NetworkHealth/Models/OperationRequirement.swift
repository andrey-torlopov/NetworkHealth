// MARK: - OperationRequirement

/// Predefined requirements for common operations.
public enum OperationRequirement {
    /// Web browsing, text messaging (Poor or better, any connection)
    case basicBrowsing

    /// Image loading, social media (Moderate or better, any connection)
    case imageLoading

    /// Video streaming, video calls (Good or better, any connection)
    case videoStreaming

    /// Large file downloads (Good or better, preferably WiFi)
    case largeDownload

    /// Large file uploads (Good or better, WiFi required)
    case largeUpload

    /// Custom requirements
    case custom(minimumQuality: NetworkQuality, requireWiFi: Bool, allowExpensive: Bool)

    internal func evaluate(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        switch self {
        case .basicBrowsing:
            return evaluateBasicBrowsing(state: state)
        case .imageLoading:
            return evaluateImageLoading(state: state)
        case .videoStreaming:
            return evaluateVideoStreaming(state: state)
        case .largeDownload:
            return evaluateLargeDownload(state: state)
        case .largeUpload:
            return evaluateLargeUpload(state: state)
        case .custom(let minQuality, let requireWiFi, let allowExpensive):
            return evaluateCustom(
                state: state,
                minimumQuality: minQuality,
                requireWiFi: requireWiFi,
                allowExpensive: allowExpensive
            )
        }
    }

    private func evaluateBasicBrowsing(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        if state.quality < .poor {
            return HealthCheckResult(passed: false, reason: "Network is offline")
        }
        return HealthCheckResult(passed: true, reason: nil)
    }

    private func evaluateImageLoading(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        if state.quality < .moderate {
            return HealthCheckResult(passed: false, reason: "Network quality too low for image loading")
        }
        return HealthCheckResult(passed: true, reason: nil)
    }

    private func evaluateVideoStreaming(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        if state.quality < .good {
            return HealthCheckResult(passed: false, reason: "Network quality too low for video streaming")
        }
        return HealthCheckResult(passed: true, reason: nil)
    }

    private func evaluateLargeDownload(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        if state.quality < .good {
            return HealthCheckResult(passed: false, reason: "Network quality too low for large downloads")
        }

        if state.isExpensive && state.connectionType.isCellular {
            return HealthCheckResult(
                passed: true,
                reason: "Warning: Using cellular data for large download"
            )
        }

        return HealthCheckResult(passed: true, reason: nil)
    }

    private func evaluateLargeUpload(state: NetworkHealthCoordinator.State) -> HealthCheckResult {
        if state.quality < .good {
            return HealthCheckResult(passed: false, reason: "Network quality too low for large uploads")
        }

        if state.connectionType.isCellular {
            return HealthCheckResult(passed: false, reason: "WiFi required for large uploads")
        }

        return HealthCheckResult(passed: true, reason: nil)
    }

    private func evaluateCustom(
        state: NetworkHealthCoordinator.State,
        minimumQuality: NetworkQuality,
        requireWiFi: Bool,
        allowExpensive: Bool
    ) -> HealthCheckResult {
        if state.quality < minimumQuality {
            return HealthCheckResult(
                passed: false,
                reason: "Network quality below minimum (\(minimumQuality.description))"
            )
        }

        if requireWiFi && state.connectionType.isCellular {
            return HealthCheckResult(passed: false, reason: "WiFi required")
        }

        if !allowExpensive && state.isExpensive {
            return HealthCheckResult(passed: false, reason: "Expensive connection not allowed")
        }

        return HealthCheckResult(passed: true, reason: nil)
    }
}
