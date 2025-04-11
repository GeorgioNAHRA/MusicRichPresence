import ScriptingBridge

// MARK: - Base ScriptingBridge Protocols

@objc public protocol SBObjectProtocol: NSObjectProtocol {
    func get() -> Any!
}

@objc public protocol SBApplicationProtocol: SBObjectProtocol {
    func activate()
    var delegate: SBApplicationDelegate! { get set }
    var isRunning: Bool { get }
}

// MARK: - Apple Music Player States (kPSS, kPSP...)

@objc public enum MusicEPlS: AEKeyword {
    case stopped = 0x6b505353           // 'kPSS'
    case playing = 0x6b505350           // 'kPSP'
    case paused = 0x6b505370            // 'kPSp'
    case fastForwarding = 0x6b505346    // 'kPSF'
    case rewinding = 0x6b505352         // 'kPSR'
}

// MARK: - Music Item Protocol

@objc public protocol MusicItem: SBObjectProtocol {
    @objc optional var name: String { get }
}
extension SBObject: MusicItem {}

// MARK: - Music Track Protocol

@objc public protocol MusicTrack: MusicItem {
    @objc optional var album: String { get }
    @objc optional var artist: String { get }
    @objc optional var finish: Double { get } // duration in seconds
}
extension SBObject: MusicTrack {}

// MARK: - Music Application Protocol

@objc public protocol MusicApplication: SBApplicationProtocol {
    @objc optional var currentTrack: MusicTrack { get }
    @objc optional var playerState: MusicEPlS { get }
    @objc optional var playerPosition: Double { get } // in seconds
}
extension SBApplication: MusicApplication {}
