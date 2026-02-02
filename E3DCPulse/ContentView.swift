import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: ConnectionSettings

    var body: some View {
        NavigationStack {
            ConnectionView()
                .navigationTitle("E3DC Pulse")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ConnectionSettings())
}
