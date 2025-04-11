import SwiftUI

@main
struct MusicRichPresenceApp: App {
    @StateObject private var discordRPCManager = DiscordRPCManager()

    var body: some Scene {
        WindowGroup {
            MainView(manager: discordRPCManager)
                .onAppear {
                    discordRPCManager.updateTrackManually()
                }
                .onDisappear {
                    NSApplication.shared.terminate(nil)
                }
        }
    }
}
