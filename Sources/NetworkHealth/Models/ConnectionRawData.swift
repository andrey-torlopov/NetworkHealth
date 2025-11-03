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

// MARK: - ConnectionRawData Extensions

public extension ConnectionRawData {
    /// Returns true if the connection is a cellular connection (any type)
    var isCellular: Bool {
        if case .cellular = self {
            return true
        }
        return false
    }

    /// Human-readable description of the connection type
    var description: String {
        switch self {
        case .none:
            return "none"
        case .wifi:
            return "wifi"
        case .cellular(let type):
            return "cellular(\(type.rawValue))"
        case .wiredEthernet:
            return "ethernet"
        case .loopback:
            return "loopback"
        case .other:
            return "other"
        }
    }
}
