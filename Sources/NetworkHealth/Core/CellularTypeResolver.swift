import Foundation
#if canImport(CoreTelephony)
import CoreTelephony
#endif

// MARK: - Cellular Type Resolution

internal struct CellularTypeResolver {

    /// Resolves the current cellular technology type
    static func resolveCellularType() -> CellularType {
        #if canImport(CoreTelephony) && os(iOS)
        let technologies = currentRadioAccessTechnologies()
        guard let technology = technologies.first else { return .unknown }
        return mapRadioTechnology(technology)
        #else
        return .unknown
        #endif
    }

    // MARK: - Private Helpers

    #if canImport(CoreTelephony) && os(iOS)
    private static func currentRadioAccessTechnologies() -> [String] {
        let info = CTTelephonyNetworkInfo()
        if #available(iOS 12.0, *) {
            guard let technologies = info.serviceCurrentRadioAccessTechnology else { return [] }
            return Array(technologies.values)
        }
        if let single = info.currentRadioAccessTechnology {
            return [single]
        }
        return []
    }

    private static func mapRadioTechnology(_ technology: String) -> CellularType {
        if fiveGTechnologies.contains(technology) {
            return .fiveG
        }
        if lteTechnologies.contains(technology) {
            return .lte
        }
        if threeGTechnologies.contains(technology) {
            return .threeG
        }
        if twoGTechnologies.contains(technology) {
            return .twoG
        }
        return .other
    }

    // MARK: - Technology Constants

    private static let fiveGTechnologies: Set<String> = [
        "CTRadioAccessTechnologyNR",
        "CTRadioAccessTechnologyNRNSA"
    ]

    private static let lteTechnologies: Set<String> = [
        "CTRadioAccessTechnologyLTE"
    ]

    private static let threeGTechnologies: Set<String> = [
        "CTRadioAccessTechnologyWCDMA",
        "CTRadioAccessTechnologyHSDPA",
        "CTRadioAccessTechnologyHSUPA",
        "CTRadioAccessTechnologyCDMAEVDORev0",
        "CTRadioAccessTechnologyCDMAEVDORevA",
        "CTRadioAccessTechnologyCDMAEVDORevB",
        "CTRadioAccessTechnologyeHRPD"
    ]

    private static let twoGTechnologies: Set<String> = [
        "CTRadioAccessTechnologyEdge",
        "CTRadioAccessTechnologyGPRS",
        "CTRadioAccessTechnologyCDMA1x"
    ]
    #endif
}
