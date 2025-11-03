import Foundation

/// Represents the quality of network connection based on type and performance measurements.
public enum NetworkQuality: Int, Equatable, Sendable, CaseIterable, Codable, Hashable, Comparable {
    /// No connection or unusable for data transmission
    case offline = 0

    /// Minimum quality: 2G/unstable 3G, high latency, suitable only for text-based content
    case poor = 1

    /// Average quality: stable 3G or weak LTE, can load images but video streaming is difficult
    case moderate = 2

    /// High quality: LTE, 5G or good Wi-Fi, suitable for video streaming and large data transfers
    case good = 3

    /// Maximum quality: wired Ethernet, Wi-Fi 6, fast 5G - can download without restrictions
    case excellent = 4

    /// Human-readable description of the network quality
    public var description: String {
        switch self {
        case .offline:
            "Offline"
        case .poor:
            "Poor Connection"
        case .moderate:
            "Moderate Connection"
        case .good:
            "Good Connection"
        case .excellent:
            "Excellent Connection"
        }
    }

    /// Comparable implementation based on raw values (lower values = worse quality)
    public static func < (lhs: NetworkQuality, rhs: NetworkQuality) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Connection Type Based Quality Mapping

public extension NetworkQuality {
    /// Determines network quality based on connection type and cellular technology
    /// - Parameters:
    ///   - connectionType: The type of network connection
    ///   - cellularType: The cellular technology type (if applicable)
    /// - Returns: NetworkQuality based on the connection type capabilities
    static func from(connectionType: ConnectionRawData) -> NetworkQuality {
        switch connectionType {
        case .none:
            return .offline
        case .wiredEthernet, .wifi:
            return .excellent
        case .cellular(let cellularType):
            return qualityFrom(cellularTechnology: cellularType)
        case .loopback:
            return .poor
        case .other:
            return .offline
        }
    }

    /// Maps cellular technology to network quality
    private static func qualityFrom(cellularTechnology: CellularType) -> NetworkQuality {
        switch cellularTechnology {
        case .fiveG:
            return .excellent
        case .lte:
            return .good
        case .threeG:
            return .moderate
        case .twoG:
            return .poor
        case .other, .unknown:
            return .offline
        }
    }
}

// MARK: - Performance-based Quality Mapping

public extension NetworkQuality {
    /// Determines network quality based on latency and/or download speed measurements
    /// - Parameters:
    ///   - latency: Round-trip time in milliseconds (optional)
    ///   - downloadSpeedMbps: Download speed in Mbps (optional)
    ///   - uploadSpeedMbps: Upload speed in Mbps (optional)
    /// - Returns: NetworkQuality based on the worst of the three measurements, or .offline if all are nil
    static func from(latency: Double? = nil, downloadSpeedMbps: Double? = nil, uploadSpeedMbps: Double? = nil) -> NetworkQuality {
        guard latency != nil || downloadSpeedMbps != nil || uploadSpeedMbps != nil else {
            return .offline
        }

        let qualityFromLatency = latency.map(qualityFrom(latency:))
        let qualityFromDownloadSpeed = downloadSpeedMbps.map(qualityFrom(downloadSpeedMbps:))
        let qualityFromUploadSpeed = uploadSpeedMbps.map(qualityFrom(uploadSpeedMbps:))

        // Take the worst quality from all measurements
        let qualities = [qualityFromLatency, qualityFromDownloadSpeed, qualityFromUploadSpeed].compactMap { $0 }
        guard !qualities.isEmpty else { return .offline }

        return qualities.min() ?? .offline
    }

    /// Maps latency (RTT) in milliseconds to network quality
    private static func qualityFrom(latency: Double) -> NetworkQuality {
        switch latency {
        case ..<50:         // < 50 ms: Excellent connection
            return .excellent
        case 50..<100:      // 50-100 ms: Good connection
            return .good
        case 100..<300:     // 100-300 ms: Moderate connection
            return .moderate
        case 300...:        // 300+ ms: Poor connection
            return .poor
        default:
            return .offline
        }
    }

    /// Maps download speed in Mbps to network quality
    private static func qualityFrom(downloadSpeedMbps: Double) -> NetworkQuality {
        switch downloadSpeedMbps {
        case 10...:         // 10+ Mbps: Excellent connection
            return .excellent
        case 5..<10:        // 5-10 Mbps: Good connection
            return .good
        case 1..<5:         // 1-5 Mbps: Moderate connection
            return .moderate
        case 0..<1:         // < 1 Mbps: Poor connection
            return .poor
        default:
            return .offline
        }
    }

    /// Maps upload speed in Mbps to network quality
    private static func qualityFrom(uploadSpeedMbps: Double) -> NetworkQuality {
        switch uploadSpeedMbps {
        case 10...:         // 10+ Mbps: Excellent connection
            return .excellent
        case 5..<10:        // 5-10 Mbps: Good connection
            return .good
        case 1..<5:         // 1-5 Mbps: Moderate connection
            return .moderate
        case 0..<1:         // < 1 Mbps: Poor connection
            return .poor
        default:
            return .offline
        }
    }
}
