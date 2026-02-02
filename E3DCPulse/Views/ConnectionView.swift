import SwiftUI

/// Main view for configuring the E3DC connection and triggering battery queries.
struct ConnectionView: View {
    @EnvironmentObject var settings: ConnectionSettings
    @State private var isConnecting = false
    @State private var batteries: [BatteryInfo] = []
    @State private var errorMessage: String?
    @State private var isConnected = false

    var body: some View {
        List {
            connectionSection
            if let error = errorMessage {
                errorSection(error)
            }
            if isConnected && !batteries.isEmpty {
                batteryOverviewSection
                batteryDetailSections
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        Section {
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.secondary)
                TextField("IP-Adresse (z.B. 192.168.178.xx)", text: $settings.host)
                    .keyboardType(.decimalPad)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            HStack {
                Image(systemName: "person")
                    .foregroundColor(.secondary)
                TextField("E3DC Portal Benutzername", text: $settings.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.secondary)
                SecureField("E3DC Portal Passwort", text: $settings.password)
            }

            HStack {
                Image(systemName: "key")
                    .foregroundColor(.secondary)
                SecureField("RSCP Passwort", text: $settings.rscpPassword)
            }

            Button(action: connectAndQuery) {
                HStack {
                    if isConnecting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isConnected ? "arrow.clockwise" : "bolt.fill")
                    }
                    Text(isConnected ? "Aktualisieren" : "Verbinden")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(!settings.isValid || isConnecting)
            .buttonStyle(.borderedProminent)
            .tint(isConnected ? .green : .blue)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        } header: {
            Text("Verbindung")
        } footer: {
            Text("Gib die lokale IP-Adresse deines E3DC S10e Systems, deine E3DC Portal-Zugangsdaten und das RSCP-Passwort ein.")
        }
    }

    // MARK: - Error Section

    private func errorSection(_ error: String) -> some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(error)
                    .foregroundColor(.red)
                    .font(.callout)
            }
        }
    }

    // MARK: - Battery Overview

    private var batteryOverviewSection: some View {
        Section {
            HStack {
                Label("Batterien erkannt", systemImage: "battery.100percent")
                Spacer()
                Text("\(batteries.count)")
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            ForEach(batteries) { battery in
                HStack {
                    Text(battery.deviceName)
                    Spacer()
                    Text("\(battery.dcbCount) Module")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Übersicht")
        }
    }

    // MARK: - Battery Detail Sections

    private var batteryDetailSections: some View {
        ForEach(batteries) { battery in
            Section {
                // Battery summary
                if let rsoc = battery.rsocReal {
                    InfoRow(label: "SOC (Real)", value: String(format: "%.1f%%", rsoc), icon: "battery.75percent")
                }
                InfoRow(label: "Durchschnitt SOH", value: battery.averageSohFormatted, icon: "heart.fill")
                if let cycles = battery.chargeCycles {
                    InfoRow(label: "Ladezyklen", value: "\(cycles)", icon: "arrow.triangle.2.circlepath")
                }
                if let cap = battery.usableCapacity {
                    InfoRow(label: "Nutzbare Kapazität", value: String(format: "%.1f Ah", cap), icon: "gauge.open.with.lines.needle.33percent")
                }
                if battery.isTraining {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Batterie im Trainingsmodus")
                            .foregroundColor(.orange)
                    }
                }

                // DCB module details
                ForEach(battery.dcbInfos) { dcb in
                    DCBDetailView(dcb: dcb)
                }
            } header: {
                Text("Batterie \(battery.index): \(battery.deviceName)")
            }
        }
    }

    // MARK: - Connection Logic

    private func connectAndQuery() {
        guard settings.isValid else { return }

        isConnecting = true
        errorMessage = nil

        Task {
            do {
                let connection = RSCPConnection(
                    host: settings.host,
                    port: settings.port,
                    username: settings.username,
                    password: settings.password,
                    rscpPassword: settings.rscpPassword
                )

                try await connection.connect()
                let batteryInfos = try await connection.queryBatteryInfo()
                await connection.disconnect()

                await MainActor.run {
                    self.batteries = batteryInfos
                    self.isConnected = true
                    self.isConnecting = false
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isConnecting = false
                    self.isConnected = false
                }
            }
        }
    }
}

// MARK: - Info Row View

struct InfoRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - DCB Detail View

struct DCBDetailView: View {
    let dcb: DCBInfo

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 6) {
                if let soc = dcb.soc {
                    DCBInfoRow(label: "SOC", value: String(format: "%.1f%%", soc))
                }
                if let voltage = dcb.voltage {
                    DCBInfoRow(label: "Spannung", value: String(format: "%.2f V", voltage))
                }
                if let current = dcb.current {
                    DCBInfoRow(label: "Strom", value: String(format: "%.2f A", current))
                }
                if let cycles = dcb.cycleCount {
                    DCBInfoRow(label: "Zyklen", value: "\(cycles)")
                }
                if let designCap = dcb.designCapacity {
                    DCBInfoRow(label: "Design Kapazität", value: String(format: "%.1f Ah", designCap))
                }
                if let fullCap = dcb.fullChargeCapacity {
                    DCBInfoRow(label: "Volllade Kapazität", value: String(format: "%.1f Ah", fullCap))
                }
                if let serial = dcb.serialNumber {
                    DCBInfoRow(label: "Seriennummer", value: serial)
                }
                if let fw = dcb.firmwareVersion {
                    DCBInfoRow(label: "Firmware", value: fw)
                }
            }
            .padding(.vertical, 4)
        } label: {
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .foregroundColor(.blue)
                Text("Modul \(dcb.index)")
                Spacer()
                SOHBadge(soh: dcb.soh)
            }
        }
    }
}

struct DCBInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

/// Colored badge showing the SOH value.
struct SOHBadge: View {
    let soh: Float?

    var body: some View {
        if let soh = soh {
            Text(String(format: "SOH %.1f%%", soh))
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(sohColor(soh))
                .foregroundColor(.white)
                .clipShape(Capsule())
        } else {
            Text("SOH N/A")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func sohColor(_ value: Float) -> Color {
        if value >= 95 { return .green }
        if value >= 85 { return .blue }
        if value >= 70 { return .orange }
        return .red
    }
}

#Preview {
    NavigationStack {
        ConnectionView()
            .environmentObject(ConnectionSettings())
    }
}
