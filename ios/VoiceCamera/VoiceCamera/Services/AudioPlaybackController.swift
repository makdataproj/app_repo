import AVFoundation
import Combine

@MainActor
final class AudioPlaybackController: ObservableObject {
    @Published var playingFilename: String?

    private var player: AVAudioPlayer?

    func toggle(url: URL) {
        if playingFilename == url.lastPathComponent {
            player?.stop()
            player = nil
            playingFilename = nil
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            playingFilename = url.lastPathComponent
        } catch {
            playingFilename = nil
        }
    }
}
