import SwiftUI

struct MainView: View {
    @ObservedObject var manager: DiscordRPCManager
    @State private var showDiscordError = false
    @State private var albumImage: Image? = nil

    var body: some View {
        VStack(spacing: 16) {
            // Album artwork
            if let image = albumImage {
                image
                    .resizable()
                    .frame(width: 128, height: 128)
                    .cornerRadius(10)
            } else if let urlString = manager.artwork.url,
                      let url = URL(string: urlString) {
                ProgressView()
                    .frame(width: 64, height: 64)
                    .onAppear {
                        loadAlbumImage(from: url)
                    }
            } else {
                Image(systemName: "music.note")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.gray)
            }

            // Track information
            Text(manager.rpcData.name ?? "No song playing")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)

            Text(manager.rpcData.album ?? "No album")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(manager.rpcData.artist ?? "Unknown artist")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider().padding(.top)

            // Discord Rich Presence toggle
            Toggle(isOn: Binding(
                get: { manager.isDiscordConnected },
                set: { newValue in
                    if newValue {
                        manager.connectToDiscord()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if !manager.isDiscordConnected {
                                showDiscordError = true
                            }
                        }
                    } else {
                        manager.disconnectFromDiscord()
                    }
                }
            )) {
                Text("Discord Rich Presence")
                    .font(.headline)
            }
            .toggleStyle(.switch)
            .padding(.top, 8)

            Spacer()

            // Credit footer
            Text("© Georgio Nahra")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .frame(minWidth: 300, minHeight: 380)
        .alert("Discord is not running", isPresented: $showDiscordError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please launch Discord and try again.")
        }
        .onChange(of: manager.artwork.url) { _ in
            if let urlString = manager.artwork.url,
               let url = URL(string: urlString) {
                loadAlbumImage(from: url)
            } else {
                albumImage = nil
            }
        }
    }

    private func loadAlbumImage(from url: URL) {
        DispatchQueue.global(qos: .background).async {
            if let data = try? Data(contentsOf: url),
               let nsImage = NSImage(data: data) {
                let image = Image(nsImage: nsImage)
                DispatchQueue.main.async {
                    self.albumImage = image
                }
            }
        }
    }
}
