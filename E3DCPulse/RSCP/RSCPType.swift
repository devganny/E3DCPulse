import Foundation

/// RSCP data types matching the E3DC protocol specification.
enum RSCPType: UInt8 {
    case none       = 0x00
    case bool       = 0x01
    case char8      = 0x02
    case uchar8     = 0x03
    case int16      = 0x04
    case uint16     = 0x05
    case int32      = 0x06
    case uint32     = 0x07
    case int64      = 0x08
    case uint64     = 0x09
    case float32    = 0x0A
    case double64   = 0x0B
    case bitfield   = 0x0C
    case cstring    = 0x0D
    case container  = 0x0E
    case timestamp  = 0x0F
    case byteArray  = 0x10
    case error      = 0xFF

    /// Size in bytes for fixed-size types, nil for variable-length types.
    var fixedSize: Int? {
        switch self {
        case .none:      return 0
        case .bool:      return 1
        case .char8:     return 1
        case .uchar8:    return 1
        case .int16:     return 2
        case .uint16:    return 2
        case .int32:     return 4
        case .uint32:    return 4
        case .int64:     return 8
        case .uint64:    return 8
        case .float32:   return 4
        case .double64:  return 8
        case .timestamp: return 12
        case .error:     return 4
        default:         return nil
        }
    }
}
