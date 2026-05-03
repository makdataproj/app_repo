import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var store: SessionStore
    @EnvironmentObject private var audio: AudioRecorderController
    @StateObject private var playback = AudioPlaybackController()

    var body: some View {
        NavigationStack {
            List {
                Section("Job") {
                    TextField("Client", text: $store.session.clientName)
                    TextField("Address", text: $store.session.address, axis: .vertical)
                    TextField("Email", text: $store.session.clientEmail)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $store.session.clientPhone)
                        .keyboardType(.phonePad)
                    TextField("Notes", text: $store.session.notes, axis: .vertical)
                }

                Section {
                    TextField("Transcript", text: $store.session.transcript, axis: .vertical)
                        .lineLimit(4...10)
                    Button("Suggest captions from transcript") {
                        store.suggestCaptions()
                    }
                } header: {
                    Text("Transcript")
                }

                Section("Photos") {
                    if store.session.photos.isEmpty {
                        Label("Capture photos from the camera tab.", systemImage: "photo")
                            .foregroundStyle(.secondary)
                    }

                    ForEach($store.session.photos) { $photo in
                        VStack(alignment: .leading, spacing: 10) {
                            MediaThumbnail(url: store.mediaURL(for: photo.thumbnailFilename))
                                .frame(height: 190)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Toggle("Include in report", isOn: $photo.includedInReport)

                            TextField("Caption", text: $photo.caption, axis: .vertical)
                                .textFieldStyle(.roundedBorder)

                            if let offset = photo.recordingOffset {
                                Label("Captured \(timeString(offset)) into recording", systemImage: "waveform")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete { offsets in
                        store.session.photos.remove(atOffsets: offsets)
                    }
                }

                Section("Recordings") {
                    if store.session.recordings.isEmpty {
                        Text("No voice notes yet")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(store.session.recordings) { recording in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Button {
                                    playback.toggle(url: store.mediaURL(for: recording.audioFilename))
                                } label: {
                                    Label(
                                        playback.playingFilename == recording.audioFilename ? "Stop" : "Play",
                                        systemImage: playback.playingFilename == recording.audioFilename ? "stop.fill" : "play.fill"
                                    )
                                }
                                Spacer()
                                Text(recording.transcriptionStatus.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if !recording.transcript.isEmpty {
                                Text(recording.transcript)
                                    .font(.body)
                            }
                        }
                    }
                }
            }
            .navigationTitle(store.session.title)
        }
    }
}
