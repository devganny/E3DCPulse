import SwiftUI

@main
struct E3DCPulseApp: App {
    @StateObject private var settings = ConnectionSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
