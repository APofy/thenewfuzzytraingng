import SwiftUI

@main
struct OsobnyStrazcaApp: App {
    @StateObject private var fallGuard = FallGuardManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fallGuard)
        }
    }
}
