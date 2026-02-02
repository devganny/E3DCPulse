import Foundation

/// Pure Swift implementation of Rijndael with 256-bit (32-byte) block size.
/// E3DC uses Rijndael-256-256 (32-byte key, 32-byte block) which differs from
/// standard AES (which uses 16-byte blocks). CommonCrypto does not support this.
final class Rijndael256 {

    // MARK: - Constants

    private static let blockSize = 32 // 256-bit block
    private static let keySize = 32   // 256-bit key
    private static let rounds = 14    // Nk=8, Nb=8 -> Nr=14
    private static let nb = 8         // block size in 32-bit words
    private static let nk = 8         // key size in 32-bit words

    // S-Box
    private static let sBox: [UInt8] = [
        0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
        0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
        0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
        0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
        0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
        0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
        0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
        0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
        0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
        0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
        0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
        0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
        0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
        0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
        0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
        0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
    ]

    // Inverse S-Box
    private static let invSBox: [UInt8] = [
        0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
        0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
        0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
        0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
        0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
        0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
        0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
        0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
        0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
        0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
        0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
        0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
        0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
        0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
        0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
        0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d
    ]

    // Round constants for key expansion
    private static let rcon: [UInt8] = [
        0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36,
        0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6,
        0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91
    ]

    // Shift row offsets for Nb=8 (256-bit block)
    // For encryption: C1=1, C2=3, C3=4
    private static let shiftOffsets: [Int] = [0, 1, 3, 4]

    // MARK: - GF(2^8) Arithmetic

    private static func gmul(_ a: UInt8, _ b: UInt8) -> UInt8 {
        var a = a
        var b = b
        var p: UInt8 = 0
        for _ in 0..<8 {
            if b & 1 != 0 {
                p ^= a
            }
            let hiBit = a & 0x80
            a <<= 1
            if hiBit != 0 {
                a ^= 0x1b
            }
            b >>= 1
        }
        return p
    }

    // MARK: - Key Expansion

    private var roundKeys: [[UInt8]] = []

    init(key: [UInt8]) {
        precondition(key.count == Rijndael256.keySize, "Key must be \(Rijndael256.keySize) bytes")
        self.roundKeys = Rijndael256.expandKey(key)
    }

    private static func expandKey(_ key: [UInt8]) -> [[UInt8]] {
        let totalWords = nb * (rounds + 1) // 8 * 15 = 120 words
        var w = [[UInt8]](repeating: [UInt8](repeating: 0, count: 4), count: totalWords)

        // Copy key into first Nk words
        for i in 0..<nk {
            w[i] = [key[4*i], key[4*i+1], key[4*i+2], key[4*i+3]]
        }

        for i in nk..<totalWords {
            var temp = w[i - 1]
            if i % nk == 0 {
                // RotWord
                let t = temp[0]
                temp[0] = temp[1]
                temp[1] = temp[2]
                temp[2] = temp[3]
                temp[3] = t
                // SubWord
                for j in 0..<4 {
                    temp[j] = sBox[Int(temp[j])]
                }
                // XOR with Rcon
                temp[0] ^= rcon[i / nk - 1]
            } else if nk > 6 && i % nk == 4 {
                // SubWord only for Nk > 6
                for j in 0..<4 {
                    temp[j] = sBox[Int(temp[j])]
                }
            }
            for j in 0..<4 {
                w[i][j] = w[i - nk][j] ^ temp[j]
            }
        }

        // Convert to round key blocks (each round key is Nb*4 = 32 bytes)
        var roundKeys = [[UInt8]]()
        for r in 0...rounds {
            var roundKey = [UInt8](repeating: 0, count: nb * 4)
            for col in 0..<nb {
                let word = w[r * nb + col]
                roundKey[col * 4] = word[0]
                roundKey[col * 4 + 1] = word[1]
                roundKey[col * 4 + 2] = word[2]
                roundKey[col * 4 + 3] = word[3]
            }
            roundKeys.append(roundKey)
        }

        return roundKeys
    }

    // MARK: - Encrypt Block

    func encryptBlock(_ input: [UInt8]) -> [UInt8] {
        precondition(input.count == Rijndael256.blockSize)

        // State is a 4 x Nb matrix (column-major)
        var state = [[UInt8]](repeating: [UInt8](repeating: 0, count: Rijndael256.nb), count: 4)

        // Load state column-major
        for col in 0..<Rijndael256.nb {
            for row in 0..<4 {
                state[row][col] = input[col * 4 + row]
            }
        }

        // AddRoundKey (round 0)
        addRoundKey(&state, round: 0)

        // Rounds 1 to Nr-1
        for round in 1..<Rijndael256.rounds {
            subBytes(&state)
            shiftRows(&state)
            mixColumns(&state)
            addRoundKey(&state, round: round)
        }

        // Final round (no MixColumns)
        subBytes(&state)
        shiftRows(&state)
        addRoundKey(&state, round: Rijndael256.rounds)

        // Output
        var output = [UInt8](repeating: 0, count: Rijndael256.blockSize)
        for col in 0..<Rijndael256.nb {
            for row in 0..<4 {
                output[col * 4 + row] = state[row][col]
            }
        }

        return output
    }

    // MARK: - Decrypt Block

    func decryptBlock(_ input: [UInt8]) -> [UInt8] {
        precondition(input.count == Rijndael256.blockSize)

        var state = [[UInt8]](repeating: [UInt8](repeating: 0, count: Rijndael256.nb), count: 4)

        for col in 0..<Rijndael256.nb {
            for row in 0..<4 {
                state[row][col] = input[col * 4 + row]
            }
        }

        addRoundKey(&state, round: Rijndael256.rounds)

        for round in stride(from: Rijndael256.rounds - 1, through: 1, by: -1) {
            invShiftRows(&state)
            invSubBytes(&state)
            addRoundKey(&state, round: round)
            invMixColumns(&state)
        }

        invShiftRows(&state)
        invSubBytes(&state)
        addRoundKey(&state, round: 0)

        var output = [UInt8](repeating: 0, count: Rijndael256.blockSize)
        for col in 0..<Rijndael256.nb {
            for row in 0..<4 {
                output[col * 4 + row] = state[row][col]
            }
        }

        return output
    }

    // MARK: - Round Operations

    private func addRoundKey(_ state: inout [[UInt8]], round: Int) {
        let rk = roundKeys[round]
        for col in 0..<Rijndael256.nb {
            for row in 0..<4 {
                state[row][col] ^= rk[col * 4 + row]
            }
        }
    }

    private func subBytes(_ state: inout [[UInt8]]) {
        for row in 0..<4 {
            for col in 0..<Rijndael256.nb {
                state[row][col] = Rijndael256.sBox[Int(state[row][col])]
            }
        }
    }

    private func invSubBytes(_ state: inout [[UInt8]]) {
        for row in 0..<4 {
            for col in 0..<Rijndael256.nb {
                state[row][col] = Rijndael256.invSBox[Int(state[row][col])]
            }
        }
    }

    private func shiftRows(_ state: inout [[UInt8]]) {
        for row in 1..<4 {
            let shift = Rijndael256.shiftOffsets[row]
            var newRow = [UInt8](repeating: 0, count: Rijndael256.nb)
            for col in 0..<Rijndael256.nb {
                newRow[col] = state[row][(col + shift) % Rijndael256.nb]
            }
            state[row] = newRow
        }
    }

    private func invShiftRows(_ state: inout [[UInt8]]) {
        for row in 1..<4 {
            let shift = Rijndael256.shiftOffsets[row]
            var newRow = [UInt8](repeating: 0, count: Rijndael256.nb)
            for col in 0..<Rijndael256.nb {
                newRow[(col + shift) % Rijndael256.nb] = state[row][col]
            }
            state[row] = newRow
        }
    }

    private func mixColumns(_ state: inout [[UInt8]]) {
        for col in 0..<Rijndael256.nb {
            let s0 = state[0][col]
            let s1 = state[1][col]
            let s2 = state[2][col]
            let s3 = state[3][col]

            state[0][col] = Rijndael256.gmul(2, s0) ^ Rijndael256.gmul(3, s1) ^ s2 ^ s3
            state[1][col] = s0 ^ Rijndael256.gmul(2, s1) ^ Rijndael256.gmul(3, s2) ^ s3
            state[2][col] = s0 ^ s1 ^ Rijndael256.gmul(2, s2) ^ Rijndael256.gmul(3, s3)
            state[3][col] = Rijndael256.gmul(3, s0) ^ s1 ^ s2 ^ Rijndael256.gmul(2, s3)
        }
    }

    private func invMixColumns(_ state: inout [[UInt8]]) {
        for col in 0..<Rijndael256.nb {
            let s0 = state[0][col]
            let s1 = state[1][col]
            let s2 = state[2][col]
            let s3 = state[3][col]

            state[0][col] = Rijndael256.gmul(0x0e, s0) ^ Rijndael256.gmul(0x0b, s1) ^ Rijndael256.gmul(0x0d, s2) ^ Rijndael256.gmul(0x09, s3)
            state[1][col] = Rijndael256.gmul(0x09, s0) ^ Rijndael256.gmul(0x0e, s1) ^ Rijndael256.gmul(0x0b, s2) ^ Rijndael256.gmul(0x0d, s3)
            state[2][col] = Rijndael256.gmul(0x0d, s0) ^ Rijndael256.gmul(0x09, s1) ^ Rijndael256.gmul(0x0e, s2) ^ Rijndael256.gmul(0x0b, s3)
            state[3][col] = Rijndael256.gmul(0x0b, s0) ^ Rijndael256.gmul(0x0d, s1) ^ Rijndael256.gmul(0x09, s2) ^ Rijndael256.gmul(0x0e, s3)
        }
    }
}

// MARK: - CBC Mode for RSCP

/// Rijndael-256-CBC encryption/decryption with zero-padding, matching E3DC's RSCP protocol.
/// The IV is chained: after encryption, the last ciphertext block becomes the next IV.
/// After decryption, the last ciphertext block (before decryption) becomes the next IV.
final class RSCPEncryption {

    static let blockSize = 32

    private let cipher: Rijndael256
    private var encryptIV: [UInt8]
    private var decryptIV: [UInt8]

    /// Initialize with the RSCP encryption password.
    /// The password is padded/truncated to 32 bytes using 0xFF fill (matching E3DC behavior).
    init(password: String) {
        var keyBytes = [UInt8](password.data(using: .isoLatin1) ?? Data(password.utf8))
        if keyBytes.count > 32 {
            keyBytes = Array(keyBytes.prefix(32))
        }
        while keyBytes.count < 32 {
            keyBytes.append(0xFF)
        }

        self.cipher = Rijndael256(key: keyBytes)
        self.encryptIV = [UInt8](repeating: 0xFF, count: RSCPEncryption.blockSize)
        self.decryptIV = [UInt8](repeating: 0xFF, count: RSCPEncryption.blockSize)
    }

    /// Encrypt data using CBC mode with zero-padding.
    func encrypt(_ plainData: Data) -> Data {
        var padded = [UInt8](plainData)

        // Zero-pad to block boundary
        let remainder = padded.count % RSCPEncryption.blockSize
        if remainder != 0 {
            padded.append(contentsOf: [UInt8](repeating: 0, count: RSCPEncryption.blockSize - remainder))
        }

        var encrypted = Data()
        var iv = encryptIV

        for blockStart in stride(from: 0, to: padded.count, by: RSCPEncryption.blockSize) {
            let blockEnd = blockStart + RSCPEncryption.blockSize
            var block = Array(padded[blockStart..<blockEnd])

            // XOR with IV (CBC)
            for i in 0..<RSCPEncryption.blockSize {
                block[i] ^= iv[i]
            }

            let encryptedBlock = cipher.encryptBlock(block)
            encrypted.append(contentsOf: encryptedBlock)
            iv = encryptedBlock
        }

        // Chain IV for next encryption call
        encryptIV = iv

        return encrypted
    }

    /// Decrypt data using CBC mode.
    func decrypt(_ encryptedData: Data) -> Data {
        let bytes = [UInt8](encryptedData)
        guard bytes.count % RSCPEncryption.blockSize == 0, bytes.count > 0 else {
            return Data()
        }

        var decrypted = Data()
        var iv = decryptIV

        for blockStart in stride(from: 0, to: bytes.count, by: RSCPEncryption.blockSize) {
            let blockEnd = blockStart + RSCPEncryption.blockSize
            let cipherBlock = Array(bytes[blockStart..<blockEnd])

            var plainBlock = cipher.decryptBlock(cipherBlock)

            // XOR with IV (CBC)
            for i in 0..<RSCPEncryption.blockSize {
                plainBlock[i] ^= iv[i]
            }

            decrypted.append(contentsOf: plainBlock)
            iv = cipherBlock
        }

        // Chain IV for next decryption call
        decryptIV = iv

        return decrypted
    }
}
