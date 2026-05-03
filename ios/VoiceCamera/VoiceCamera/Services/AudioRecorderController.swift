import AVFoundation
import Combine
import Speech

@MainActor
final class AudioRecorderController: NSObject, ObservableObject {
    @Published var activeRecording: ActiveRecording?
    @Published var elapsed: TimeInterval = 0
    @Published var authorizationMessage: String = "Microphone ready"

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var currentURL: URL?

    var isRecording: Bool {
        activeRecording != nil
    }

    func requestPermissions() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                self?.authorizationMessage = granted ? "Microphone ready" : "Microphone permission is required."
            }
        }

        SFSpeechRecognizer.requestAuthorization { _ in }
    }

    func toggleRecording(mediaDirectory: URL, completion: @escaping (VoiceRecording) -> Void) {
        if isRecording {
            stopRecording(completion: completion)
        } else {
            startRecording(mediaDirectory: mediaDirectory)
        }
    }

    private func startRecording(mediaDirectory: URL) {
        do {
            try FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
            let id = UUID()
            let url = mediaDirectory.appendingPathComponent("\(id.uuidString).m4a")

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.record()

            self.recorder = recorder
            currentURL = url
            activeRecording = ActiveRecording(id: id, startedAt: Date())
            elapsed = 0
            startTimer()
        } catch {
            authorizationMessage = error.localizedDescription
        }
    }

    private func stopRecording(completion: @escaping (VoiceRecording) -> Void) {
        guard let activeRecording, let url = currentURL else { return }

        recorder?.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
        self.activeRecording = nil

        let recording = VoiceRecording(
            id: activeRecording.id,
            audioFilename: url.lastPathComponent,
            startedAt: activeRecording.startedAt,
            endedAt: Date(),
            transcriptionStatus: .notStarted
        )
        completion(recording)
    }

    func transcribe(_ recording: VoiceRecording, mediaURL: URL, completion: @escaping (VoiceRecording) -> Void) {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized,
              let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.isAvailable else {
            var unavailable = recording
            unavailable.transcriptionStatus = .unavailable
            completion(unavailable)
            return
        }

        var inProgress = recording
        inProgress.transcriptionStatus = .transcribing
        completion(inProgress)

        let request = SFSpeechURLRecognitionRequest(url: mediaURL)
        recognizer.recognitionTask(with: request) { result, error in
            Task { @MainActor in
                var updated = recording
                if let result {
                    updated.transcript = result.bestTranscription.formattedString
                    updated.transcriptionStatus = result.isFinal ? .completed : .transcribing
                    completion(updated)
                } else if error != nil {
                    updated.transcriptionStatus = .failed
                    completion(updated)
                }
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let activeRecording = self.activeRecording else { return }
                self.elapsed = Date().timeIntervalSince(activeRecording.startedAt)
            }
        }
    }
}
