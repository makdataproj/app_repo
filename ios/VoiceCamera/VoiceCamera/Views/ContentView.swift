import SwiftUI

struct ContentView: View {
    @StateObject private var store = SessionStore()
    @StateObject private var camera = CameraController()
    @StateObject private var audio = AudioRecorderController()

    var body: some View {
        TabView {
            CaptureView()
                .environmentObject(store)
                .environmentObject(camera)
                .environmentObject(audio)
                .tabItem {
                    Label("Capture", systemImage: "camera.fill")
                }

            ReviewView()
                .environmentObject(store)
                .environmentObject(audio)
                .tabItem {
                    Label("Review", systemImage: "photo.on.rectangle")
                }

            ReportView()
                .environmentObject(store)
                .tabItem {
                    Label("Report", systemImage: "doc.text")
                }

            EstimateView()
                .environmentObject(store)
                .tabItem {
                    Label("Estimate", systemImage: "list.bullet.rectangle")
                }
        }
        .onAppear {
            camera.requestAccessAndStart()
            audio.requestPermissions()
        }
    }
}
