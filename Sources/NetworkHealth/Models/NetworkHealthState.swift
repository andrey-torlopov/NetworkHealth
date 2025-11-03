// MARK: - NetworkHealthState

/// Simplified state representation for NetworkHealth facade.
/// Combines connection info, quality, and optional measurements.
public struct NetworkHealthState: Sendable, Equatable {
    /// Type of network connection (WiFi, LTE, 5G, etc.)
    public let connectionType: ConnectionRawData

    /// Overall network quality assessment
    public let quality: NetworkQuality

    /// Whether the connection is expensive (e.g., cellular with limited data)
    public let isExpensive: Bool

    /// Round-trip time (latency) in milliseconds (if available)
    public let latency: Double?

    /// Download speed in megabits per second (if available)
    public let downloadSpeedMbps: Double?

    /// Upload speed in megabits per second (if available)
    public let uploadSpeedMbps: Double?

    /// Whether the device is currently online
    public var isOnline: Bool {
        quality != .offline
    }

    /// Whether the connection quality is good enough for heavy operations
    public var isGoodQuality: Bool {
        quality >= .good
    }

    /// Whether the connection is degraded (poor or moderate)
    public var isDegradedQuality: Bool {
        quality == .poor || quality == .moderate
    }

    internal init(from state: NetworkHealthCoordinator.State, checker: NetworkHealthCoordinator?) {
        self.connectionType = state.connectionType
        self.quality = state.quality
        self.isExpensive = state.isExpensive

        // These would need to be exposed from checker if we want them
        // For now, they're nil in basic streaming mode
        self.latency = nil
        self.downloadSpeedMbps = nil
        self.uploadSpeedMbps = nil
    }

    public init(
        connectionType: ConnectionRawData,
        quality: NetworkQuality,
        isExpensive: Bool,
        latency: Double? = nil,
        downloadSpeedMbps: Double? = nil,
        uploadSpeedMbps: Double? = nil
    ) {
        self.connectionType = connectionType
        self.quality = quality
        self.isExpensive = isExpensive
        self.latency = latency
        self.downloadSpeedMbps = downloadSpeedMbps
        self.uploadSpeedMbps = uploadSpeedMbps
    }
}
