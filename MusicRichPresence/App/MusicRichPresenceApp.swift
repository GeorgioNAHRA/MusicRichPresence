import SwiftUI

@main
struct MusicRichPresenceApp: App {
    @StateObject private var discordRPCManager = DiscordRPCManager()
    @StateObject private var updateManager = AppUpdateManager()

    var body: some Scene {
        WindowGroup {
            MainView(manager: discordRPCManager, updateManager: updateManager)
                .onAppear {
                    discordRPCManager.updateTrackManually()
                    updateManager.checkForUpdates(manually: false)
                }
                .onDisappear {
                    NSApplication.shared.terminate(nil)
                }
                .frame(width: 320, height: 380)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .help) {
                Button("Check for Updates...") {
                    updateManager.checkForUpdates(manually: true)
                }
            }
        }

    }
}

