import AVFoundation

/// Gentle, low-volume sound effects. Each game supplies its own `win.wav`
/// (and optionally `found.wav`) as a resource in its app bundle; if absent, a
/// soft system sound is used as a fallback.
public enum Sound {
    public static func found() { SoundPlayer.shared.playFound() }
    public static func win() { SoundPlayer.shared.playWin() }
}

private final class SoundPlayer {
    static let shared = SoundPlayer()

    private var winPlayer: AVAudioPlayer?
    private var foundPlayer: AVAudioPlayer?
    private let winVolume: Float = 0.35
    private let foundVolume: Float = 0.25

    private init() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        if let url = Bundle.main.url(forResource: "win", withExtension: "wav") {
            winPlayer = try? AVAudioPlayer(contentsOf: url)
            winPlayer?.volume = winVolume
            winPlayer?.prepareToPlay()
        }
        if let url = Bundle.main.url(forResource: "found", withExtension: "wav") {
            foundPlayer = try? AVAudioPlayer(contentsOf: url)
            foundPlayer?.volume = foundVolume
            foundPlayer?.prepareToPlay()
        }
    }

    func playWin() {
        if let player = winPlayer {
            player.currentTime = 0
            player.play()
        } else {
            AudioServicesPlaySystemSound(1103)
        }
    }

    func playFound() {
        if let player = foundPlayer {
            player.currentTime = 0
            player.play()
        } else {
            AudioServicesPlaySystemSound(1104)
        }
    }
}
