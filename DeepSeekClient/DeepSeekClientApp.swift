// Designed by TiantianYe
import SwiftUI

@main
struct DeepSeekClientApp: App {
    @StateObject private var store = ConversationStore()
    @StateObject private var preferences = AppPreferences()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(preferences)
        }
    }
}
