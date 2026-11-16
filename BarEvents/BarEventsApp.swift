import SwiftUI

@main
struct BarEventsApp: App {
    @StateObject private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .task { await app.loadSettings() }
        }
    }
}
