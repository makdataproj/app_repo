import Foundation
import Combine
import UIKit

@MainActor
final class SessionStore: ObservableObject {
    @Published var session: JobSession {
        didSet {
            session.updatedAt = Date()
            save()
        }
    }

    private let fileManager = FileManager.default
    private let sessionFilename = "active-session.json"

    init() {
        let loaded = Self.loadSession()
        session = loaded ?? JobSession.fresh()
    }

    var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    var mediaDirectoryURL: URL {
        documentsURL.appendingPathComponent("VoiceCameraMedia", isDirectory: true)
    }

    func startNewSession() {
        session = JobSession.fresh()
    }

    func saveCapturedImage(_ image: UIImage, recording: ActiveRecording?) throws {
        try ensureMediaDirectory()

        let id = UUID()
        let imageFilename = "\(id.uuidString).jpg"
        let thumbnailFilename = "\(id.uuidString)-thumb.jpg"

        guard let fullData = image.jpegData(compressionQuality: 0.9),
              let thumbData = image.resized(maxDimension: 420).jpegData(compressionQuality: 0.78) else {
            throw SessionStoreError.imageEncodingFailed
        }

        try fullData.write(to: mediaDirectoryURL.appendingPathComponent(imageFilename), options: .atomic)
        try thumbData.write(to: mediaDirectoryURL.appendingPathComponent(thumbnailFilename), options: .atomic)

        let photo = CapturedPhoto(
            imageFilename: imageFilename,
            thumbnailFilename: thumbnailFilename,
            recordingID: recording?.id,
            recordingOffset: recording.map { Date().timeIntervalSince($0.startedAt) },
            caption: suggestedCaption()
        )

        session.photos.append(photo)
    }

    func mediaURL(for filename: String) -> URL {
        mediaDirectoryURL.appendingPathComponent(filename)
    }

    func addRecording(_ recording: VoiceRecording) {
        session.recordings.append(recording)
    }

    func updateRecording(_ recording: VoiceRecording) {
        guard let index = session.recordings.firstIndex(where: { $0.id == recording.id }) else { return }
        session.recordings[index] = recording
        if !recording.transcript.isEmpty {
            session.transcript = [session.transcript, recording.transcript]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: " ")
        }
    }

    func suggestCaptions() {
        let transcript = session.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else { return }
        let chunks = transcript
            .split(separator: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for index in session.photos.indices where session.photos[index].caption.isEmpty {
            session.photos[index].caption = chunks.indices.contains(index) ? chunks[index] : transcript
        }
    }

    func reportText() -> String {
        let title = session.report.title.isEmpty ? session.title : session.report.title
        let summary = session.report.summary.isEmpty ? generatedSummary() : session.report.summary
        let photos = session.photos.filter(\.includedInReport)

        var lines = [
            title,
            session.report.template.rawValue,
            "",
            "Client: \(session.clientName.isEmpty ? "Not set" : session.clientName)",
            "Address: \(session.address.isEmpty ? "Not set" : session.address)",
            "",
            summary,
            ""
        ]

        for (index, photo) in photos.enumerated() {
            lines.append("Photo \(index + 1): \(photo.caption.isEmpty ? "No caption" : photo.caption)")
        }

        if !session.transcript.isEmpty {
            lines.append("")
            lines.append("Transcript")
            lines.append(session.transcript)
        }

        return lines.joined(separator: "\n")
    }

    func smsSummary() -> String {
        let title = session.report.title.isEmpty ? session.title : session.report.title
        let summary = session.report.summary.isEmpty ? generatedSummary() : session.report.summary
        return "\(title)\n\(summary)"
    }

    func generatedSummary() -> String {
        let count = session.photos.filter(\.includedInReport).count
        if session.transcript.isEmpty {
            return "Documented \(count) photo\(count == 1 ? "" : "s") for review."
        }
        return session.transcript
    }

    func save() {
        do {
            let data = try JSONEncoder.voiceCamera.encode(session)
            try data.write(to: documentsURL.appendingPathComponent(sessionFilename), options: .atomic)
        } catch {
            assertionFailure("Failed to save session: \(error)")
        }
    }

    private func suggestedCaption() -> String {
        guard !session.transcript.isEmpty else { return "" }
        return session.transcript
    }

    private func ensureMediaDirectory() throws {
        if !fileManager.fileExists(atPath: mediaDirectoryURL.path) {
            try fileManager.createDirectory(at: mediaDirectoryURL, withIntermediateDirectories: true)
        }
    }

    private static func loadSession() -> JobSession? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent("active-session.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.voiceCamera.decode(JobSession.self, from: data)
    }
}

struct ActiveRecording: Equatable {
    let id: UUID
    let startedAt: Date
}

enum SessionStoreError: Error {
    case imageEncodingFailed
}

private extension JSONEncoder {
    static var voiceCamera: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var voiceCamera: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
