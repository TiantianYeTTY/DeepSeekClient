// Designed by TiantianYe
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ConversationStore
    @EnvironmentObject private var preferences: AppPreferences
    @State private var showSidebar = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            ChatView(showSidebar: $showSidebar, showSettings: $showSettings)
            SidebarView(isPresented: $showSidebar, showSettings: $showSettings)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
                .environmentObject(store)
                .environmentObject(preferences)
        }
    }
}
