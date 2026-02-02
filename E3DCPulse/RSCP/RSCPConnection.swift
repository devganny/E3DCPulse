import Foundation
import Network

/// Errors that can occur during RSCP communication.
enum RSCPError: LocalizedError {
    case connectionFailed(String)
    case authenticationFailed
    case communicationError(String)
    case timeout
    case invalidResponse
    case disconnected

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let msg): return "Verbindung fehlgeschlagen: \(msg)"
        case .authenticationFailed: return "Authentifizierung fehlgeschlagen (Benutzername oder Passwort falsch)"
        case .communicationError(let msg): return "Kommunikationsfehler: \(msg)"
        case .timeout: return "Zeitüberschreitung bei der Verbindung"
        case .invalidResponse: return "Ungültige Antwort vom E3DC System"
        case .disconnected: return "Verbindung zum E3DC System getrennt"
        }
    }
}

/// Manages a TCP connection to the E3DC system using the RSCP protocol.
/// Uses NWConnection for iOS-compatible TCP networking.
actor RSCPConnection {

    private let host: String
    private let port: UInt16
    private let username: String
    private let password: String
    private let rscpPassword: String

    private var connection: NWConnection?
    private var encryption: RSCPEncryption?
    private var isAuthenticated = false

    static let defaultPort: UInt16 = 5033
    private static let bufferSize = 1024 * 32

    init(host: String, port: UInt16 = defaultPort, username: String, password: String, rscpPassword: String) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.rscpPassword = rscpPassword
    }

    // MARK: - Connection Management

    /// Connect to the E3DC system and authenticate.
    func connect() async throws {
        // Create encryption handler
        encryption = RSCPEncryption(password: rscpPassword)

        // Establish TCP connection
        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port)!
        let params = NWParameters.tcp
        let conn = NWConnection(host: nwHost, port: nwPort, using: params)

        self.connection = conn

        // Wait for connection
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    conn.stateUpdateHandler = nil
                    continuation.resume()
                case .failed(let error):
                    conn.stateUpdateHandler = nil
                    continuation.resume(throwing: RSCPError.connectionFailed(error.localizedDescription))
                case .cancelled:
                    conn.stateUpdateHandler = nil
                    continuation.resume(throwing: RSCPError.disconnected)
                default:
                    break
                }
            }
            conn.start(queue: .global(qos: .userInitiated))
        }

        // Authenticate
        try await authenticate()
    }

    /// Disconnect from the E3DC system.
    func disconnect() {
        connection?.cancel()
        connection = nil
        encryption = nil
        isAuthenticated = false
    }

    // MARK: - Authentication

    private func authenticate() async throws {
        let authRequest = RSCPValue.container(
            tag: .rscpReqAuthentication,
            children: [
                RSCPValue.string(tag: .rscpAuthenticationUser, value: username),
                RSCPValue.string(tag: .rscpAuthenticationPassword, value: password)
            ]
        )

        let responses = try await sendRequest(values: [authRequest])

        // Check for authentication response
        guard let authResponse = responses.first(tag: .rscpAuthentication) else {
            throw RSCPError.authenticationFailed
        }

        // Check for error response
        if authResponse.type == .error {
            throw RSCPError.authenticationFailed
        }

        // The response should contain the user level
        if let level = authResponse.data.intValue, level > 0 {
            isAuthenticated = true
        } else {
            throw RSCPError.authenticationFailed
        }
    }

    // MARK: - Send/Receive

    /// Send RSCP values and receive the response.
    func sendRequest(values: [RSCPValue]) async throws -> [RSCPValue] {
        guard let conn = connection, let enc = encryption else {
            throw RSCPError.disconnected
        }

        // Encode frame
        let frame = RSCPFrameCodec.encodeFrame(values: values)

        // Encrypt
        let encrypted = enc.encrypt(frame)

        // Send
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            conn.send(content: encrypted, completion: .contentProcessed { error in
                if let error = error {
                    continuation.resume(throwing: RSCPError.communicationError(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            })
        }

        // Receive response
        let responseData = try await receiveData(connection: conn)

        // Decrypt
        let decrypted = enc.decrypt(responseData)

        // Decode frame
        guard let responses = RSCPFrameCodec.decodeFrame(data: decrypted) else {
            throw RSCPError.invalidResponse
        }

        return responses
    }

    private func receiveData(connection: NWConnection) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: RSCPConnection.bufferSize) { content, _, _, error in
                if let error = error {
                    continuation.resume(throwing: RSCPError.communicationError(error.localizedDescription))
                } else if let data = content, !data.isEmpty {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: RSCPError.invalidResponse)
                }
            }
        }
    }

    // MARK: - Battery Queries

    /// Query the number of batteries and DCB (battery module) count for each battery.
    func queryBatteryInfo() async throws -> [BatteryInfo] {
        guard isAuthenticated else {
            throw RSCPError.authenticationFailed
        }

        var batteries: [BatteryInfo] = []

        // Try battery indices 0..7 (E3DC supports up to 8 battery slots)
        for batIndex in 0..<8 {
            // First: query DCB count for this battery index
            let dcbCountRequest = RSCPValue.container(
                tag: .batReqData,
                children: [
                    RSCPValue.uint16(tag: .batIndex, value: UInt16(batIndex)),
                    RSCPValue.request(tag: .batReqDcbCount),
                    RSCPValue.request(tag: .batReqDeviceName),
                    RSCPValue.request(tag: .batReqChargeCycles),
                    RSCPValue.request(tag: .batReqUsableCapacity),
                    RSCPValue.request(tag: .batReqUsableRemainingCapacity),
                    RSCPValue.request(tag: .batReqRsocReal),
                    RSCPValue.request(tag: .batReqTrainingMode),
                ]
            )

            do {
                let responses = try await sendRequest(values: [dcbCountRequest])

                // Find BAT_DATA container in response
                guard let batData = responses.first(tag: .batData) ?? responses.first(tag: .listType) else {
                    continue
                }

                // Check for error
                if batData.type == .error {
                    continue
                }

                // Extract DCB count
                guard let dcbCountValue = batData.find(tag: .batDcbCount),
                      let dcbCount = dcbCountValue.data.intValue, dcbCount > 0 else {
                    continue
                }

                let deviceName = batData.find(tag: .batDeviceName)?.data.stringValue ?? "Batterie \(batIndex)"
                let chargeCycles = batData.find(tag: .batChargeCycles)?.data.intValue
                let usableCapacity = batData.find(tag: .batUsableCapacity)?.data.floatValue
                let usableRemaining = batData.find(tag: .batUsableRemainingCapacity)?.data.floatValue
                let rsocReal = batData.find(tag: .batRsocReal)?.data.floatValue
                let trainingMode = batData.find(tag: .batTrainingMode)?.data.intValue

                // Now query DCB info for each module
                var dcbInfos: [DCBInfo] = []

                for dcbIndex in 0..<dcbCount {
                    let dcbRequest = RSCPValue.container(
                        tag: .batReqData,
                        children: [
                            RSCPValue.uint16(tag: .batIndex, value: UInt16(batIndex)),
                            RSCPValue.uint16(tag: .batReqDcbInfo, value: UInt16(dcbIndex)),
                        ]
                    )

                    do {
                        let dcbResponses = try await sendRequest(values: [dcbRequest])

                        // Find the DCB info container
                        let root = dcbResponses.first(tag: .batData) ?? dcbResponses.first(tag: .listType)

                        if let dcbInfoContainer = root?.find(tag: .batDcbInfo) {
                            let soh = dcbInfoContainer.find(tag: .batDcbSoh)?.data.floatValue
                            let soc = dcbInfoContainer.find(tag: .batDcbSoc)?.data.floatValue
                            let voltage = dcbInfoContainer.find(tag: .batDcbVoltage)?.data.floatValue
                            let current = dcbInfoContainer.find(tag: .batDcbCurrent)?.data.floatValue
                            let cycles = dcbInfoContainer.find(tag: .batDcbCycleCount)?.data.intValue
                            let designCapacity = dcbInfoContainer.find(tag: .batDcbDesignCapacity)?.data.floatValue
                            let fullChargeCapacity = dcbInfoContainer.find(tag: .batDcbFullChargeCapacity)?.data.floatValue
                            let remainingCapacity = dcbInfoContainer.find(tag: .batDcbRemainingCapacity)?.data.floatValue
                            let serialNo = dcbInfoContainer.find(tag: .batDcbSerialno)?.data.stringValue
                            let fwVersion = dcbInfoContainer.find(tag: .batDcbFwVersion)?.data.stringValue

                            let info = DCBInfo(
                                index: dcbIndex,
                                soh: soh,
                                soc: soc,
                                voltage: voltage,
                                current: current,
                                cycleCount: cycles,
                                designCapacity: designCapacity,
                                fullChargeCapacity: fullChargeCapacity,
                                remainingCapacity: remainingCapacity,
                                serialNumber: serialNo,
                                firmwareVersion: fwVersion
                            )
                            dcbInfos.append(info)
                        }
                    } catch {
                        // DCB query failed, continue with next
                        continue
                    }
                }

                let battery = BatteryInfo(
                    index: batIndex,
                    deviceName: deviceName,
                    dcbCount: dcbCount,
                    dcbInfos: dcbInfos,
                    chargeCycles: chargeCycles,
                    usableCapacity: usableCapacity,
                    usableRemainingCapacity: usableRemaining,
                    rsocReal: rsocReal,
                    trainingMode: trainingMode ?? 0
                )
                batteries.append(battery)

            } catch {
                // Battery at this index not available, stop scanning
                if batIndex > 0 {
                    break
                }
                throw error
            }
        }

        return batteries
    }
}
