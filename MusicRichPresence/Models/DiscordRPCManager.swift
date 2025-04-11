import SwiftUI
import ScriptingBridge
import SwordRPC
import os

class DiscordRPCManager: ObservableObject {
    
    enum PlayerState: String {
        case playing, paused, stopped
    }

    struct TrackData {
        var name: String?
        var artist: String?
        var album: String?
        var totalTime: Double?
        var state: PlayerState
    }

    struct AlbumArtwork {
        var album: String?
        var artist: String?
        var name: String?
        var url: String?
    }

    private struct iTunesSearchResult: Decodable {
        let artworkUrl100: String
    }

    private struct iTunesResponse: Decodable {
        let resultCount: Int
        let results: [iTunesSearchResult]
    }

    @Published var rpcData: TrackData = TrackData(state: .stopped)
    @Published var artwork: AlbumArtwork = AlbumArtwork()
    @Published var isDiscordConnected = false
    @Published var isChangingConnectionStatus = true

    @AppStorage("showAlbumArt") var showAlbumArt = true
    @AppStorage("showPlaybackIndicator") var showPlaybackIndicator = true

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "AMRPC", category: "Discord")
    private let decoder = JSONDecoder()
    private let musicApp = SBApplication(bundleIdentifier: "com.apple.Music") as? MusicApplication
    private let notificationCenter = DistributedNotificationCenter.default()
    private var notificationObserver: NSObjectProtocol?
    private var rpc: SwordRPC!
    private var trackStartDate: Date?

    init() {
        logger.info("Initializing DiscordRPCManager")
        createRPCInstance()
        isDiscordConnected = rpc.connect()

        // Update presence every 15s only when Rich Presence is on
        Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            if self.isDiscordConnected {
                self.setDiscordPresence()
            }
        }

        // Update song info every 5s when Discord is off or Rich Presence is off
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            if !self.isDiscordConnected {
                self.updateTrackManually()
            }
        }
    }

    private func createRPCInstance() {
        rpc = SwordRPC(appId: "919349769682427985")

        rpc.onConnect { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isDiscordConnected = true
                self.isChangingConnectionStatus = false
                self.updateTrackManually()
                self.setupAppleMusicNotifications()
                self.logger.info("Connected to Discord")
            }
        }

        rpc.onDisconnect { [weak self] _, _, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.teardownRPC()
                self.logger.warning("Disconnected from Discord")
            }
        }
    }

    private func teardownRPC() {
        unsubscribeFromMusicNotifications()
        isDiscordConnected = false
        isChangingConnectionStatus = false
        rpcData = TrackData(state: .stopped)
        artwork = AlbumArtwork()
        trackStartDate = nil
    }

    func connectToDiscord() {
        guard !isDiscordConnected else { return }
        isChangingConnectionStatus = true
        createRPCInstance()
        isDiscordConnected = rpc.connect()
    }

    func disconnectFromDiscord() {
        guard isDiscordConnected else { return }
        isChangingConnectionStatus = true
        rpc.disconnect()
    }

    private func setupAppleMusicNotifications() {
        notificationObserver = notificationCenter.addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let self else { return }

            let newName = notification.userInfo?[AnyHashable("Name")] as? String
            let newArtist = notification.userInfo?[AnyHashable("Artist")] as? String
            let newAlbum = notification.userInfo?[AnyHashable("Album")] as? String

            if newName != self.rpcData.name {
                self.trackStartDate = Date().addingTimeInterval(-(self.musicApp?.playerPosition ?? 0))
            }

            self.rpcData.name = newName
            self.rpcData.artist = newArtist
            self.rpcData.album = newAlbum
            self.rpcData.state = PlayerState(rawValue: (notification.userInfo?[AnyHashable("Player State")] as? String)?.lowercased() ?? "stopped") ?? .stopped
            self.rpcData.totalTime = self.musicApp?.currentTrack?.finish

            self.updateArtworkAndPresence()
        }

        logger.info("Started listening to Apple Music notifications")
    }

    private func unsubscribeFromMusicNotifications() {
        if let observer = notificationObserver {
            notificationCenter.removeObserver(observer)
            logger.info("Stopped listening to Apple Music notifications")
        }
    }

    func updateTrackManually() {
        guard let track = musicApp?.currentTrack else { return }

        if track.name != rpcData.name {
            trackStartDate = Date().addingTimeInterval(-(musicApp?.playerPosition ?? 0))
        }

        rpcData.name = track.name?.nonEmpty
        rpcData.artist = track.artist?.nonEmpty
        rpcData.album = track.album?.nonEmpty
        rpcData.totalTime = track.finish
        rpcData.state = convert(playerState: musicApp?.playerState)

        updateArtworkAndPresence()
    }

    private func updateArtworkAndPresence() {
        guard showAlbumArt,
              let album = rpcData.album,
              let artist = rpcData.artist,
              let name = rpcData.name else {
            artwork = AlbumArtwork()
            setDiscordPresence()
            return
        }

        // If any core identity info changes, fetch new artwork
        if artwork.album != album || artwork.artist != artist || artwork.name != name {
            fetchArtwork(album: album, artist: artist) { url in
                DispatchQueue.main.async {
                    self.artwork = AlbumArtwork(album: album, artist: artist, name: name, url: url)
                    self.setDiscordPresence()
                }
            }
        } else {
            // No change, just refresh presence
            setDiscordPresence()
        }
    }

    private func convert(playerState: MusicEPlS?) -> PlayerState {
        switch playerState {
        case .playing?, .fastForwarding?, .rewinding?:
            return .playing
        case .paused?:
            return .paused
        default:
            return .stopped
        }
    }

    private func setDiscordPresence() {
        guard isDiscordConnected else { return }

        var presence = RichPresence()
        presence.details = rpcData.name
        presence.state = rpcData.artist
        presence.assets.largeText = rpcData.album

        if rpcData.state == .playing,
           let duration = rpcData.totalTime,
           let _ = musicApp?.playerPosition,
           let start = trackStartDate {
            presence.timestamps.start = start
            presence.timestamps.end = start.addingTimeInterval(duration)
        }

        if showPlaybackIndicator {
            presence.assets.smallText = rpcData.state.rawValue.capitalized
            presence.assets.smallImage = rpcData.state.rawValue
        }

        presence.assets.largeImage = artwork.url ?? "applemusic_large"
        rpc.setPresence(presence)
    }

    private func fetchArtwork(album: String, artist: String, completion: @escaping (String?) -> Void) {
        logger.info("Fetching artwork for: \(album)")
        let query = "\(album) \(artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let region = Locale.current.language.region?.identifier ?? "us"
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(query)&media=music&entity=album&country=\(region)&limit=1") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 2

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                self.logger.error("Artwork fetch failed: \(error.localizedDescription, privacy: .public)")
                completion(nil)
                return
            }

            guard let data = data,
                  let response = try? self.decoder.decode(iTunesResponse.self, from: data),
                  response.resultCount > 0 else {
                completion(nil)
                return
            }

            let rawURL = response.results[0].artworkUrl100
            let highResURL = rawURL.replacingOccurrences(of: "100x100bb", with: "128x128")
            completion(highResURL)
        }.resume()
    }
}

fileprivate extension String {
    var nonEmpty: String? {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
