import Foundation
import SwiftUI

/// Connection settings for E3DC RSCP access.
/// Stored in UserDefaults for persistence across app launches.
class ConnectionSettings: ObservableObject {
    private static let hostKey = "e3dc_host"
    private static let usernameKey = "e3dc_username"
    private static let rscpPasswordKey = "e3dc_rscp_password"

    @Published var host: String {
        didSet { UserDefaults.standard.set(host, forKey: Self.hostKey) }
    }

    @Published var username: String {
        didSet { UserDefaults.standard.set(username, forKey: Self.usernameKey) }
    }

    @Published var password: String = ""

    @Published var rscpPassword: String {
        didSet { UserDefaults.standard.set(rscpPassword, forKey: Self.rscpPasswordKey) }
    }

    /// Port is always 5033 for RSCP
    let port: UInt16 = 5033

    var isValid: Bool {
        return !host.isEmpty && !username.isEmpty && !password.isEmpty && !rscpPassword.isEmpty
    }

    init() {
        self.host = UserDefaults.standard.string(forKey: Self.hostKey) ?? ""
        self.username = UserDefaults.standard.string(forKey: Self.usernameKey) ?? ""
        self.rscpPassword = UserDefaults.standard.string(forKey: Self.rscpPasswordKey) ?? ""
    }
}
