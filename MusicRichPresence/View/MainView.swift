import SwiftUI
import AppKit

struct MainView: View {
    @ObservedObject var manager: DiscordRPCManager
    @ObservedObject var updateManager: AppUpdateManager
    @State private var showDiscordError = false
    @State private var albumImage: Image? = nil
    
    // For real-time playback timer
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    // Calculate playback progress
    private var playbackProgress: Double {
        guard let duration = manager.rpcData.totalTime, duration > 0 else { return 0 }
        if manager.rpcData.state == .playing {
            if let start = manager.trackStartDate {
                let elapsed = currentTime.timeIntervalSince(start)
                return min(1.0, max(0.0, elapsed / duration))
            }
        }
        return 0
    }
    
    // Helper to format track durations
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds >= 0 else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var body: some View {
        ZStack {
            // Liquid Gray Background + Glass Blur (stretching across safe areas)
            AnimatedLiquidBackground()
                .ignoresSafeArea()
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .ignoresSafeArea()

            
            // Subtle slate gray glass overlay tint
            Color(white: 0.12).opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Window Controls and Title
                HStack {
                    Text("MUSIC RICH PRESENCE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(2.5)

                    
                    Spacer()
                    
                    // Connected Status indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(manager.isDiscordConnected ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                            .shadow(color: (manager.isDiscordConnected ? Color.green : Color.orange).opacity(0.8), radius: 3)
                        
                        Text(manager.isDiscordConnected ? "ACTIVE" : "OFFLINE")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(manager.isDiscordConnected ? .green.opacity(0.8) : .orange.opacity(0.8))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.05))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.1), lineWidth: 0.5)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)
                
                // Content layout (No ScrollView, fits perfectly inside the window)
                VStack(spacing: 16) {
                    // Artwork Container
                    Group {
                        if let image = albumImage {
                            // Active album cover is displayed completely clean and sharp (no shimmers, overlays or gray sheen)
                            image
                                .renderingMode(.original)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 128, height: 128)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 5)

                        } else {
                            // Placeholders get the frosted glass look with specular shimmer
                            ZStack {
                                if let urlString = manager.artwork.url,
                                   let url = URL(string: urlString) {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(.white.opacity(0.08))
                                        .frame(width: 128, height: 128)
                                    ProgressView()
                                        .onAppear {
                                            loadAlbumImage(from: url)
                                        }
                                } else {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(.white.opacity(0.06))
                                        .frame(width: 128, height: 128)
                                    
                                    Image(systemName: "music.note")
                                        .font(.system(size: 38, weight: .light))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color(red: 0.7, green: 0.5, blue: 1.0), Color(red: 0.3, green: 0.7, blue: 1.0)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.4), radius: 8)
                                }
                                
                                // Glowing reflective glass outline (Placeholders only)
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(LinearGradient(
                                        colors: [.white.opacity(0.35), .clear, .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ), lineWidth: 1.5)
                                
                                // Specular shimmer sweep (Placeholders only)
                                ShimmerView()
                                    .frame(width: 128, height: 128)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .allowsHitTesting(false)
                            }
                            .frame(width: 128, height: 128)
                            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.top, 4)
                    
                    // Song details
                    VStack(spacing: 4) {
                        Text(manager.rpcData.name ?? "No song playing")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Text(manager.rpcData.artist ?? "Unknown artist")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        
                        Text(manager.rpcData.album ?? "No album")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 24)
                    
                    // Real-time playback progress bar
                    VStack(spacing: 5) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.12))
                                    .frame(height: 5)
                                    .overlay(
                                        Capsule()
                                            .stroke(.white.opacity(0.08), lineWidth: 0.5)
                                    )
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.6, green: 0.3, blue: 0.9), Color(red: 0.2, green: 0.6, blue: 0.9)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(playbackProgress), height: 5)
                                    .shadow(color: Color(red: 0.4, green: 0.4, blue: 0.9).opacity(0.6), radius: 5, x: 0, y: 0)
                            }
                        }
                        .frame(height: 5)
                        .padding(.horizontal, 24)
                        
                        HStack {
                            Text(formatTime(playbackProgress * (manager.rpcData.totalTime ?? 0)))
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Spacer()
                            
                            Text(formatTime(manager.rpcData.totalTime ?? 0))
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .padding(.horizontal, 26)
                    }
                    
                    // Settings Panel (Translucent Glass)
                    VStack(spacing: 12) {
                        LiquidGlassToggle(isOn: Binding(
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
                        ), label: "Discord Rich Presence")
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(LinearGradient(
                                colors: [.white.opacity(0.12), .clear, .white.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            ), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                }
                // Credit footer
                Text("© Georgio Nahra")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(width: 320, height: 380)
        .alert("Discord is not running", isPresented: $showDiscordError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please launch Discord and try again.")
        }
        .alert("Update", isPresented: $updateManager.showAlert) {
            switch updateManager.status {
            case .checking:
                Button("Cancel", role: .cancel) {
                    updateManager.status = .idle
                }
            case .updateAvailable(_, let url):
                Button("Download") {
                    NSWorkspace.shared.open(url)
                    updateManager.status = .idle
                }
                Button("Cancel", role: .cancel) {
                    updateManager.status = .idle
                }
            case .upToDate:
                Button("OK", role: .cancel) {
                    updateManager.status = .idle
                }
            case .error(_):
                Button("OK", role: .cancel) {
                    updateManager.status = .idle
                }
            case .idle:
                Button("OK", role: .cancel) { }
            }
        } message: {
            switch updateManager.status {
            case .checking:
                Text("Checking for updates...")
            case .updateAvailable(let version, _):
                Text("A new version (\(version)) is available. Would you like to download the update?")
            case .upToDate:
                Text("You are using the latest version of Music Rich Presence.")
            case .error(let error):
                Text("An error occurred while checking for updates:\n\(error)")
            case .idle:
                Text("")
            }
        }
        .onChange(of: manager.artwork.url) { _ in
            if let urlString = manager.artwork.url,
               let url = URL(string: urlString) {
                loadAlbumImage(from: url)
            } else {
                albumImage = nil
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        // Expose underlying window configuration for transparency & dragging
        .background(
            WindowAccessor { window in
                guard let window = window else { return }
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.backgroundColor = NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0)
                window.isMovableByWindowBackground = true
                window.hasShadow = true
                
                // Force window to be fully opaque and non-resizable
                window.isOpaque = true
                window.styleMask.remove(.resizable)
                
                // Lock window size exactly to 320x380
                window.minSize = NSSize(width: 320, height: 380)
                window.maxSize = NSSize(width: 320, height: 380)
                window.setContentSize(NSSize(width: 320, height: 380))
            }
        )

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

// MARK: - Native macOS Blur Wrapper
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffect = NSVisualEffectView()
        visualEffect.material = material
        visualEffect.blendingMode = blendingMode
        visualEffect.state = .active
        return visualEffect
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Window Accessor to access NSWindow directly
struct WindowAccessor: NSViewRepresentable {
    var onChange: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.onChange(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.onChange(nsView.window)
        }
    }
}

// MARK: - Iridescent Gray Fluid Background Animation
struct AnimatedLiquidBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Dark charcoal base color
            Color(red: 0.08, green: 0.08, blue: 0.09)
            
            // Dynamic liquid silver-gray blob 1
            Circle()
                .fill(Color(red: 0.28, green: 0.28, blue: 0.32).opacity(0.4))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: animate ? -50 : 50, y: animate ? 80 : -80)

            // Dynamic liquid slate-gray blob 2
            Circle()
                .fill(Color(red: 0.2, green: 0.2, blue: 0.22).opacity(0.45))
                .frame(width: 240, height: 240)
                .blur(radius: 45)
                .offset(x: animate ? 60 : -60, y: animate ? -70 : 70)

            // Dynamic liquid platinum-gray blob 3
            Circle()
                .fill(Color(red: 0.35, green: 0.35, blue: 0.38).opacity(0.25))
                .frame(width: 220, height: 220)
                .blur(radius: 45)
                .offset(x: animate ? -70 : 70, y: animate ? -40 : 40)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 12.0).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

// MARK: - Glossy Specular Shimmer Highlight
struct ShimmerView: View {
    @State private var phase: CGFloat = -1.2

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.12), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .offset(x: phase * geo.size.width)
            .onAppear {
                withAnimation(.linear(duration: 4.5).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
        }
    }
}

// MARK: - Premium Liquid Glass Custom Toggle
struct LiquidGlassToggle: View {
    @Binding var isOn: Bool
    var label: String
    @State private var isHovering = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
            
            Spacer()
            
            // Toggle Switch
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ?
                        AnyShapeStyle(LinearGradient(
                            colors: [Color(red: 0.55, green: 0.25, blue: 0.85), Color(red: 0.15, green: 0.55, blue: 0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )) :
                        AnyShapeStyle(Color.white.opacity(0.08))
                    )
                    .frame(width: 44, height: 24)
                    .overlay(
                        Capsule()
                            .stroke(LinearGradient(
                                colors: [.white.opacity(0.35), .white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            ), lineWidth: 1)
                    )
                    .shadow(color: isOn ? Color(red: 0.4, green: 0.4, blue: 0.95).opacity(0.45) : .clear, radius: 6, x: 0, y: 0)

                // Liquid glass ball
                Circle()
                    .fill(LinearGradient(
                        colors: [.white, .white.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: isHovering ? 20 : 18, height: isHovering ? 20 : 18)
                    .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 3)
                    .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isOn)
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    isOn.toggle()
                }
            }
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .padding(.vertical, 2)
    }
}


