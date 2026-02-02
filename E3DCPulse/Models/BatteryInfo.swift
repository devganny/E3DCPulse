import Foundation

/// Information about a single DCB (Battery Cell Block / Module).
struct DCBInfo: Identifiable {
    var id: Int { index }

    let index: Int
    let soh: Float?             // State of Health in %
    let soc: Float?             // State of Charge in %
    let voltage: Float?         // Current voltage in V
    let current: Float?         // Current in A
    let cycleCount: Int?        // Number of charge cycles
    let designCapacity: Float?  // Design capacity in Ah
    let fullChargeCapacity: Float?  // Current full charge capacity in Ah
    let remainingCapacity: Float?   // Remaining capacity in Ah
    let serialNumber: String?
    let firmwareVersion: String?

    /// SOH as a formatted string
    var sohFormatted: String {
        guard let soh = soh else { return "N/A" }
        return String(format: "%.1f%%", soh)
    }

    /// SOC as a formatted string
    var socFormatted: String {
        guard let soc = soc else { return "N/A" }
        return String(format: "%.1f%%", soc)
    }
}

/// Information about a battery unit (may contain multiple DCB modules).
struct BatteryInfo: Identifiable {
    var id: Int { index }

    let index: Int
    let deviceName: String
    let dcbCount: Int
    let dcbInfos: [DCBInfo]
    let chargeCycles: Int?
    let usableCapacity: Float?          // in Ah
    let usableRemainingCapacity: Float?  // in Ah
    let rsocReal: Float?                // Real SOC in %
    let trainingMode: Int

    /// Average SOH across all DCB modules
    var averageSoh: Float? {
        let sohs = dcbInfos.compactMap { $0.soh }
        guard !sohs.isEmpty else { return nil }
        return sohs.reduce(0, +) / Float(sohs.count)
    }

    /// Average SOH as a formatted string
    var averageSohFormatted: String {
        guard let avg = averageSoh else { return "N/A" }
        return String(format: "%.1f%%", avg)
    }

    /// Whether the battery is in training mode
    var isTraining: Bool {
        return trainingMode != 0
    }
}
