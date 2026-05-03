import SwiftUI

struct CaptureView: View {
    @EnvironmentObject private var store: SessionStore
    @EnvironmentObject private var camera: CameraController
    @EnvironmentObject private var audio: AudioRecorderController
    @State private var captureMessage = ""

    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            if camera.authorizationStatus != .authorized {
                VStack(spacing: 10) {
                    Image(systemName: "camera")
                        .font(.largeTitle)
                    Text("Camera Permission Needed")
                        .font(.headline)
                    Text("Enable camera access to capture job photos.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }

            VStack {
                sessionHeader
                Spacer()
                recentStrip
                controls
            }
            .padding()
        }
    }

    private var sessionHeader: some View {
        VStack(spacing: 10) {
            TextField("Session title", text: $store.session.title)
                .textFieldStyle(.roundedBorder)

            HStack {
                Label("\(store.session.photos.count)", systemImage: "photo")
                Label(audio.isRecording ? timeString(audio.elapsed) : "Ready", systemImage: audio.isRecording ? "mic.fill" : "mic")
                Spacer()
                if !captureMessage.isEmpty {
                    Text(captureMessage)
                        .font(.caption)
                }
            }
            .font(.subheadline)
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var recentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.session.photos.suffix(8).reversed()) { photo in
                    MediaThumbnail(url: store.mediaURL(for: photo.thumbnailFilename))
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .frame(height: 66)
    }

    private var controls: some View {
        HStack(spacing: 22) {
            Button {
                camera.switchCamera()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
            }
            .buttonStyle(CaptureIconButtonStyle())

            Button {
                audio.toggleRecording(mediaDirectory: store.mediaDirectoryURL) { recording in
                    store.addRecording(recording)
                    audio.transcribe(recording, mediaURL: store.mediaURL(for: recording.audioFilename)) { updated in
                        store.updateRecording(updated)
                    }
                }
            } label: {
                Image(systemName: audio.isRecording ? "stop.fill" : "mic.fill")
                    .foregroundStyle(audio.isRecording ? .red : .primary)
            }
            .buttonStyle(CaptureIconButtonStyle())

            Button {
                capturePhoto()
            } label: {
                ZStack {
                    Circle().stroke(.white, lineWidth: 5)
                    Circle().fill(.white).padding(8)
                }
            }
            .frame(width: 78, height: 78)
            .accessibilityLabel("Capture photo")

            Button {
                camera.cycleFlash()
            } label: {
                Image(systemName: flashIcon)
            }
            .buttonStyle(CaptureIconButtonStyle())

            Button {
                store.startNewSession()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(CaptureIconButtonStyle())
        }
        .padding(.bottom, 12)
    }

    private var flashIcon: String {
        switch camera.flashMode {
        case .auto:
            "bolt.badge.automatic"
        case .on:
            "bolt.fill"
        default:
            "bolt.slash"
        }
    }

    private func capturePhoto() {
        camera.capturePhoto { result in
            switch result {
            case .success(let image):
                do {
                    try store.saveCapturedImage(image, recording: audio.activeRecording)
                    captureMessage = "Saved"
                } catch {
                    captureMessage = error.localizedDescription
                }
            case .failure(let error):
                captureMessage = error.localizedDescription
            }
        }
    }
}

struct CaptureIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial, in: Circle())
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}

func timeString(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    return "\(total / 60):\(String(format: "%02d", total % 60))"
}
