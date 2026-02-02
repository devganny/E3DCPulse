import Foundation

/// Represents a single RSCP data element (tag + type + value).
struct RSCPValue {
    let tag: RSCPTag
    let type: RSCPType
    let data: RSCPData

    /// Convenience initializer for container requests
    static func container(tag: RSCPTag, children: [RSCPValue]) -> RSCPValue {
        return RSCPValue(tag: tag, type: .container, data: .container(children))
    }

    /// Convenience initializer for tags that need no data
    static func request(tag: RSCPTag) -> RSCPValue {
        return RSCPValue(tag: tag, type: .none, data: .none)
    }

    /// Convenience initializer for uint16 values (e.g., index)
    static func uint16(tag: RSCPTag, value: UInt16) -> RSCPValue {
        return RSCPValue(tag: tag, type: .uint16, data: .uint16(value))
    }

    /// Convenience initializer for string values
    static func string(tag: RSCPTag, value: String) -> RSCPValue {
        return RSCPValue(tag: tag, type: .cstring, data: .string(value))
    }
}

/// Union type for RSCP data values.
enum RSCPData {
    case none
    case bool(Bool)
    case int8(Int8)
    case uint8(UInt8)
    case int16(Int16)
    case uint16(UInt16)
    case int32(Int32)
    case uint32(UInt32)
    case int64(Int64)
    case uint64(UInt64)
    case float32(Float)
    case double64(Double)
    case string(String)
    case bytes(Data)
    case container([RSCPValue])
    case timestamp(seconds: Int64, nanoseconds: Int32)
    case error(Int32)

    /// Extract as Float for display
    var floatValue: Float? {
        switch self {
        case .float32(let v): return v
        case .double64(let v): return Float(v)
        case .uint8(let v): return Float(v)
        case .uint16(let v): return Float(v)
        case .uint32(let v): return Float(v)
        case .int32(let v): return Float(v)
        case .int16(let v): return Float(v)
        default: return nil
        }
    }

    /// Extract as Int
    var intValue: Int? {
        switch self {
        case .int8(let v): return Int(v)
        case .uint8(let v): return Int(v)
        case .int16(let v): return Int(v)
        case .uint16(let v): return Int(v)
        case .int32(let v): return Int(v)
        case .uint32(let v): return Int(v)
        case .int64(let v): return Int(v)
        case .uint64(let v): return Int(v)
        case .float32(let v): return Int(v)
        case .double64(let v): return Int(v)
        case .bool(let v): return v ? 1 : 0
        default: return nil
        }
    }

    /// Extract as String
    var stringValue: String? {
        switch self {
        case .string(let v): return v
        default: return nil
        }
    }

    /// Extract container children
    var children: [RSCPValue]? {
        switch self {
        case .container(let v): return v
        default: return nil
        }
    }
}

// MARK: - RSCP Frame Encoder/Decoder

/// Handles encoding and decoding of RSCP protocol frames.
/// Frame format: [magic:2][ctrl:2][seconds:8][nanoseconds:4][length:2][data:N][crc:4]
struct RSCPFrameCodec {

    static let magic: UInt16 = 0xe3dc
    static let frameHeaderSize = 18 // 2+2+8+4+2
    static let crcSize = 4

    // MARK: - Frame Encoding

    /// Encode multiple RSCP values into a complete frame with header and CRC.
    static func encodeFrame(values: [RSCPValue]) -> Data {
        var payload = Data()
        for value in values {
            payload.append(encodeValue(value))
        }
        return wrapInFrame(payload: payload)
    }

    /// Wrap raw payload bytes in an RSCP frame.
    static func wrapInFrame(payload: Data) -> Data {
        var frame = Data()

        // Magic (little-endian representation of big-endian 0xe3dc)
        let magicSwapped = CFSwapInt16HostToBig(magic)
        let magicLE = CFSwapInt16(magicSwapped)
        frame.appendLE(magicLE)

        // Control byte: 0x11 = CRC enabled + version 1
        let ctrlSwapped = CFSwapInt16HostToBig(0x0011)
        let ctrlLE = CFSwapInt16(ctrlSwapped)
        frame.appendLE(ctrlLE)

        // Timestamp
        let now = Date().timeIntervalSince1970
        let seconds = UInt64(ceil(now))
        let nanoseconds = UInt32((now - Double(Int(now))) * 1000)
        frame.appendLE(seconds)
        frame.appendLE(nanoseconds)

        // Length
        let length = UInt16(payload.count)
        frame.appendLE(length)

        // Payload
        frame.append(payload)

        // CRC32
        let crc = frame.crc32()
        frame.appendLE(crc)

        return frame
    }

    // MARK: - Value Encoding

    /// Encode a single RSCP value (tag + type + length + data).
    static func encodeValue(_ value: RSCPValue) -> Data {
        var data = Data()

        // Tag (4 bytes, little-endian)
        data.appendLE(value.tag.rawValue)

        // Type (1 byte)
        data.append(value.type.rawValue)

        // Encode the data portion
        let encodedData = encodeData(value)

        // Length (2 bytes, little-endian)
        data.appendLE(UInt16(encodedData.count))

        // Data
        data.append(encodedData)

        return data
    }

    private static func encodeData(_ value: RSCPValue) -> Data {
        var result = Data()
        switch value.data {
        case .none:
            break
        case .bool(let v):
            result.append(v ? 1 : 0)
        case .int8(let v):
            result.appendLE(v)
        case .uint8(let v):
            result.append(v)
        case .int16(let v):
            result.appendLE(v)
        case .uint16(let v):
            result.appendLE(v)
        case .int32(let v):
            result.appendLE(v)
        case .uint32(let v):
            result.appendLE(v)
        case .int64(let v):
            result.appendLE(v)
        case .uint64(let v):
            result.appendLE(v)
        case .float32(let v):
            result.appendLE(v)
        case .double64(let v):
            result.appendLE(v)
        case .string(let v):
            if let bytes = v.data(using: .isoLatin1) {
                result.append(bytes)
            } else {
                result.append(Data(v.utf8))
            }
        case .bytes(let v):
            result.append(v)
        case .container(let children):
            for child in children {
                result.append(encodeValue(child))
            }
        case .timestamp(let seconds, let nanoseconds):
            let high = Int32(seconds >> 32)
            let low = Int32(seconds & 0xFFFFFFFF)
            result.appendLE(high)
            result.appendLE(low)
            result.appendLE(nanoseconds)
        case .error(let v):
            result.appendLE(v)
        }
        return result
    }

    // MARK: - Frame Decoding

    /// Decode a complete RSCP frame from decrypted data, returns the contained values.
    static func decodeFrame(data: Data) -> [RSCPValue]? {
        guard data.count >= frameHeaderSize else { return nil }

        // Check magic
        let magicRaw: UInt16 = data.readLE(at: 0)
        let magicBE = CFSwapInt16(magicRaw)
        guard magicBE == magic else {
            // Maybe we received just data without frame header (already unwrapped)
            return decodeValues(from: data, offset: 0, length: data.count)
        }

        let ctrl: UInt16 = data.readLE(at: 2)
        let hasCRC = (CFSwapInt16(ctrl) & 0x10) != 0
        let payloadLength: UInt16 = data.readLE(at: 16)

        let headerEnd = frameHeaderSize
        let payloadEnd = headerEnd + Int(payloadLength)

        guard data.count >= payloadEnd + (hasCRC ? crcSize : 0) else { return nil }

        let payload = data.subdata(in: headerEnd..<payloadEnd)

        return decodeValues(from: payload, offset: 0, length: payload.count)
    }

    // MARK: - Value Decoding

    /// Decode multiple RSCP values from a data block.
    static func decodeValues(from data: Data, offset: Int, length: Int) -> [RSCPValue] {
        var values: [RSCPValue] = []
        var pos = offset

        while pos < offset + length {
            guard pos + 7 <= data.count else { break }

            let tagRaw: UInt32 = data.readLE(at: pos)
            let typeRaw: UInt8 = data[pos + 4]
            let dataLength: UInt16 = data.readLE(at: pos + 5)

            let headerSize = 7 // 4 (tag) + 1 (type) + 2 (length)
            let dataStart = pos + headerSize
            let dataEnd = dataStart + Int(dataLength)

            guard dataEnd <= data.count else { break }

            let tag = RSCPTag(rawValue: tagRaw)
            let type = RSCPType(rawValue: typeRaw)

            let rscpData: RSCPData
            if let type = type {
                let subdata = data.subdata(in: dataStart..<dataEnd)
                rscpData = decodeData(type: type, data: subdata)
            } else {
                rscpData = .bytes(data.subdata(in: dataStart..<dataEnd))
            }

            if let tag = tag, let type = type {
                values.append(RSCPValue(tag: tag, type: type, data: rscpData))
            }

            pos = dataEnd
        }

        return values
    }

    private static func decodeData(type: RSCPType, data: Data) -> RSCPData {
        switch type {
        case .none:
            return .none
        case .bool:
            return .bool(data.count > 0 && data[0] != 0)
        case .char8:
            return .int8(data.count > 0 ? Int8(bitPattern: data[0]) : 0)
        case .uchar8:
            return .uint8(data.count > 0 ? data[0] : 0)
        case .int16:
            return .int16(data.readLE(at: 0))
        case .uint16:
            return .uint16(data.readLE(at: 0))
        case .int32:
            return .int32(data.readLE(at: 0))
        case .uint32:
            return .uint32(data.readLE(at: 0))
        case .int64:
            return .int64(data.readLE(at: 0))
        case .uint64:
            return .uint64(data.readLE(at: 0))
        case .float32:
            let val: Float = data.readLE(at: 0)
            return .float32(val)
        case .double64:
            let val: Double = data.readLE(at: 0)
            return .double64(val)
        case .cstring:
            let str = String(data: data, encoding: .isoLatin1) ?? String(data: data, encoding: .utf8) ?? ""
            return .string(str)
        case .container:
            let children = decodeValues(from: data, offset: 0, length: data.count)
            return .container(children)
        case .timestamp:
            guard data.count >= 12 else { return .timestamp(seconds: 0, nanoseconds: 0) }
            let high: UInt32 = data.readLE(at: 0)
            let low: UInt32 = data.readLE(at: 4)
            let ns: Int32 = data.readLE(at: 8)
            let seconds = Int64(high) + Int64(low)
            return .timestamp(seconds: seconds, nanoseconds: ns)
        case .bitfield, .byteArray:
            return .bytes(data)
        case .error:
            return .error(data.readLE(at: 0))
        }
    }
}

// MARK: - Data Extension Helpers

extension Data {
    /// Append a value in little-endian byte order.
    mutating func appendLE<T>(_ value: T) {
        var v = value
        withUnsafeBytes(of: &v) { ptr in
            self.append(contentsOf: ptr)
        }
    }

    /// Read a little-endian value at the given byte offset.
    func readLE<T>(at offset: Int) -> T {
        return self.subdata(in: offset..<offset + MemoryLayout<T>.size)
            .withUnsafeBytes { $0.load(as: T.self) }
    }

    /// CRC32 matching the E3DC implementation (standard CRC32).
    func crc32() -> UInt32 {
        let bytes = [UInt8](self)
        var crc: UInt32 = 0xFFFFFFFF

        for byte in bytes {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = crc32Table[index] ^ (crc >> 8)
        }

        return crc ^ 0xFFFFFFFF
    }
}

// CRC32 lookup table (standard polynomial 0xEDB88320)
private let crc32Table: [UInt32] = {
    var table = [UInt32](repeating: 0, count: 256)
    for i in 0..<256 {
        var crc = UInt32(i)
        for _ in 0..<8 {
            if crc & 1 != 0 {
                crc = 0xEDB88320 ^ (crc >> 1)
            } else {
                crc >>= 1
            }
        }
        table[i] = crc
    }
    return table
}()

// MARK: - RSCPValue Search Extensions

extension Array where Element == RSCPValue {
    /// Find the first value with a given tag.
    func first(tag: RSCPTag) -> RSCPValue? {
        return first { $0.tag == tag }
    }

    /// Find all values with a given tag.
    func filter(tag: RSCPTag) -> [RSCPValue] {
        return filter { $0.tag == tag }
    }
}

extension RSCPValue {
    /// Search recursively for a child with the given tag.
    func find(tag: RSCPTag) -> RSCPValue? {
        if self.tag == tag { return self }
        if let children = data.children {
            for child in children {
                if let found = child.find(tag: tag) {
                    return found
                }
            }
        }
        return nil
    }

    /// Get all children with a given tag.
    func findAll(tag: RSCPTag) -> [RSCPValue] {
        var results: [RSCPValue] = []
        if self.tag == tag { results.append(self) }
        if let children = data.children {
            for child in children {
                results.append(contentsOf: child.findAll(tag: tag))
            }
        }
        return results
    }
}
