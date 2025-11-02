/// Represents the currently active connection type.
public enum ConnectionRawData: Equatable, Sendable, Codable, Hashable {
    case none
    case wifi
    case cellular(CellularType)
    case wiredEthernet
    case loopback
    case other

    /// Whether the connection is backed by a real network path and can be measured.
    public var supportsActiveMeasurements: Bool {
        switch self {
        case .wifi, .cellular, .wiredEthernet, .other:
            true
        case .none, .loopback:
            false
        }
    }
}

/// Describes the currently active radio technology for cellular networks.
public enum CellularType: String, Equatable, Sendable, Codable, Hashable {
    case fiveG
    case lte
    case threeG
    case twoG
    case other
    case unknown
}

