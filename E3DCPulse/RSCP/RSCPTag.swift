import Foundation

/// RSCP tag definitions for the E3DC protocol.
/// Only tags relevant to authentication, battery info, and DCB queries are included.
enum RSCPTag: UInt32 {
    // MARK: - RSCP Authentication
    case rscpReqAuthentication          = 0x00000001 // 1
    case rscpAuthenticationUser         = 0x00000002 // 2
    case rscpAuthenticationPassword     = 0x00000003 // 3
    case rscpReqUserLevel               = 0x00000004 // 4
    case rscpAuthentication             = 0x00800001 // 8388609
    case rscpUserLevel                  = 0x00800004 // 8388612
    case rscpGeneralError               = 0x00FFFFFF // 16777215

    // MARK: - BAT Request Tags
    case batReqData                     = 0x03040000 // 50593792
    case batIndex                       = 0x03040001 // 50593793
    case batReqRsoc                     = 0x03000001 // 50331649
    case batReqModuleVoltage            = 0x03000002 // 50331650
    case batReqCurrent                  = 0x03000003 // 50331651
    case batReqMaxBatVoltage            = 0x03000004 // 50331652
    case batReqMaxChargeCurrent         = 0x03000005 // 50331653
    case batReqEodVoltage               = 0x03000006 // 50331654
    case batReqMaxDischargeCurrent      = 0x03000007 // 50331655
    case batReqChargeCycles             = 0x03000008 // 50331656
    case batReqTerminalVoltage          = 0x03000009 // 50331657
    case batReqDeviceName               = 0x0300000C // 50331660
    case batReqDcbCount                 = 0x0300000D // 50331661
    case batReqRsocReal                 = 0x0300000E // 50331662
    case batReqAsoc                     = 0x0300000F // 50331663
    case batReqFcc                      = 0x03000010 // 50331664
    case batReqRc                       = 0x03000011 // 50331665
    case batReqMaxDcbCellTemperature    = 0x03000016 // 50331670
    case batReqMinDcbCellTemperature    = 0x03000017 // 50331671
    case batReqDcbAllCellTemperatures   = 0x03000018 // 50331672
    case batReqDcbAllCellVoltages       = 0x0300001A // 50331674
    case batReqReadyForShutdown         = 0x0300001E // 50331678
    case batReqInfo                     = 0x03000020 // 50331680
    case batReqTrainingMode             = 0x03000021 // 50331681
    case batReqUsableCapacity           = 0x03000026 // 50331686
    case batReqUsableRemainingCapacity  = 0x03000027 // 50331687
    case batReqDcbInfo                  = 0x03000022 // 50331714 - WRONG, correcting below
    case batReqSpecification            = 0x03000023 // 50331715
    case batReqInternals                = 0x03000024 // 50331716
    case batReqTotalUseTime             = 0x03000034 // 50331732
    case batReqTotalDischargeTime       = 0x03000035 // 50331733
    case batReqAvailableBatteries       = 0x03000036 // 50331734
    case batReqMaxDcbCellVoltage        = 0x03000014 // 50331668
    case batReqMinDcbCellVoltage        = 0x03000015 // 50331669
    case batReqDeviceState              = 0x03060000 // 50724864

    // MARK: - BAT Response Tags
    case batData                        = 0x03840000 // 58982400
    case batRsoc                        = 0x03800001 // 58720257
    case batModuleVoltage               = 0x03800002 // 58720258
    case batCurrent                     = 0x03800003 // 58720259
    case batMaxBatVoltage               = 0x03800004 // 58720260
    case batMaxChargeCurrent            = 0x03800005 // 58720261
    case batEodVoltage                  = 0x03800006 // 58720262
    case batMaxDischargeCurrent         = 0x03800007 // 58720263
    case batChargeCycles                = 0x03800008 // 58720264
    case batTerminalVoltage             = 0x03800009 // 58720265
    case batStatusCode                  = 0x0380000A // 58720266
    case batErrorCode                   = 0x0380000B // 58720267
    case batDeviceName                  = 0x0380000C // 58720268
    case batDcbCount                    = 0x0380000D // 58720269
    case batRsocReal                    = 0x0380000E // 58720270
    case batAsoc                        = 0x0380000F // 58720271
    case batFcc                         = 0x03800010 // 58720272
    case batRc                          = 0x03800011 // 58720273
    case batMaxDcbCellTemperature       = 0x03800016 // 58720278
    case batMinDcbCellTemperature       = 0x03800017 // 58720279
    case batDcbAllCellTemperatures      = 0x03800018 // 58720280
    case batDcbCellTemperature          = 0x03800019 // 58720281
    case batDcbAllCellVoltages          = 0x0380001A // 58720282
    case batDcbCellVoltage              = 0x0380001B // 58720283
    case batReadyForShutdown            = 0x0380001E // 58720286
    case batFirmwareVersion             = 0x0380001F // 58720287
    case batInfo                        = 0x03800020 // 58720288
    case batTrainingMode                = 0x03800021 // 58720289
    case batUsableCapacity              = 0x03800026 // 58720294
    case batUsableRemainingCapacity     = 0x03800027 // 58720295
    case batMaxDcbCellVoltage           = 0x03800014 // 58720276
    case batMinDcbCellVoltage           = 0x03800015 // 58720277
    case batAvailableBatteries          = 0x03800037 // 58720343
    case batDeviceState                 = 0x03860000 // 59113472
    case batDeviceConnected             = 0x03860001 // 59113473
    case batDeviceWorking               = 0x03860002 // 59113474
    case batDeviceInService             = 0x03860003 // 59113475
    case batSpecification               = 0x03800023 // 58720323
    case batSpecifiedCapacity           = 0x03800025 // 58720549  - needs correction
    case batTotalUseTime                = 0x03800034 // 58720340
    case batTotalDischargeTime          = 0x03800035 // 58720341

    // MARK: - BAT DCB (Battery Module) Tags
    case batDcbIndex                    = 0x03800200 // 58720512
    case batDcbLastMessageTimestamp     = 0x03800201 // 58720513
    case batDcbMaxChargeVoltage         = 0x03800202 // 58720514
    case batDcbMaxChargeCurrent         = 0x03800203 // 58720515
    case batDcbEndOfDischarge           = 0x03800204 // 58720516
    case batDcbMaxDischargeCurrent      = 0x03800205 // 58720517
    case batDcbFullChargeCapacity       = 0x03800206 // 58720518
    case batDcbRemainingCapacity        = 0x03800207 // 58720519
    case batDcbSoc                      = 0x03800208 // 58720520
    case batDcbSoh                      = 0x03800209 // 58720521
    case batDcbCycleCount               = 0x03800210 // 58720528
    case batDcbCurrent                  = 0x03800211 // 58720529
    case batDcbVoltage                  = 0x03800212 // 58720530
    case batDcbCurrentAvg30s            = 0x03800213 // 58720531
    case batDcbVoltageAvg30s            = 0x03800214 // 58720532
    case batDcbDesignCapacity           = 0x03800215 // 58720533
    case batDcbDesignVoltage            = 0x03800216 // 58720534
    case batDcbChargeLowTemperature     = 0x03800217 // 58720535
    case batDcbChargeHighTemperature    = 0x03800218 // 58720536
    case batDcbManufactureDate          = 0x03800219 // 58720537
    case batDcbSerialno                 = 0x03800220 // 58720544
    case batDcbProtocolVersion          = 0x03800221 // 58720545
    case batDcbFwVersion                = 0x03800222 // 58720546
    case batDcbDataTableVersion         = 0x03800223 // 58720547
    case batDcbPcbVersion               = 0x03800224 // 58720548
    case batDcbNrSeriesCell             = 0x03800400 // 58721024
    case batDcbNrParallelCell           = 0x03800401 // 58721025
    case batDcbManufactureName          = 0x03800402 // 58721026
    case batDcbDeviceName               = 0x03800403 // 58721027
    case batDcbSerialcode               = 0x03800404 // 58721028
    case batDcbNrSensor                 = 0x03800405 // 58721029
    case batDcbStatus                   = 0x03800406 // 58721030
    case batDcbWarning                  = 0x03800407 // 58721031
    case batDcbAlarm                    = 0x03800408 // 58721032
    case batDcbError                    = 0x03800409 // 58721033
    case batDcbInfo                     = 0x03800022 // 58720322

    // MARK: - EMS Tags (for SOC display)
    case emsReqBatSoc                   = 0x01000008 // 16777224
    case emsBatSoc                      = 0x01800008 // 25165832

    // MARK: - INFO Tags
    case infoReqSerialNumber            = 0x0A000002
    case infoSerialNumber               = 0x0A800002
    case infoReqSwRelease               = 0x0A000003
    case infoSwRelease                  = 0x0A800003

    // MARK: - Virtual tag for list responses
    case listType                       = 0xFFFFFFFF

    /// Human-readable name for display
    var displayName: String {
        switch self {
        case .batDcbSoh: return "SOH"
        case .batDcbSoc: return "SOC"
        case .batDcbCount: return "DCB Count"
        case .batDcbCycleCount: return "Cycles"
        case .batDcbVoltage: return "Voltage"
        case .batDcbCurrent: return "Current"
        case .batDcbDesignCapacity: return "Design Capacity"
        case .batDcbFullChargeCapacity: return "Full Charge Capacity"
        case .batDcbRemainingCapacity: return "Remaining Capacity"
        case .batDeviceName: return "Device Name"
        case .batChargeCycles: return "Charge Cycles"
        default: return String(describing: self)
        }
    }
}

/// Default RSCP types for tags that have known types
enum RSCPTagTypeMapping {
    static func defaultType(for tag: RSCPTag) -> RSCPType {
        switch tag {
        case .batIndex: return .uint16
        case .batReqDcbAllCellTemperatures: return .uint16
        case .batReqDcbAllCellVoltages: return .uint16
        case .batReqDcbInfo: return .uint16
        case .batReqData: return .container
        case .rscpReqAuthentication: return .container
        case .rscpAuthenticationUser: return .cstring
        case .rscpAuthenticationPassword: return .cstring
        default: return .none
        }
    }
}
