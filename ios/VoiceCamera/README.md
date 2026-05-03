# Voice Camera iOS App

Native SwiftUI implementation for the voice camera workflow described in `docs/ios-voice-camera-prd.md`.

Open the app in Xcode from:

```text
ios/VoiceCamera/VoiceCamera.xcodeproj
```

Code layout:

- `VoiceCamera/VoiceCameraApp.swift` starts the app.
- `VoiceCamera/Views/CaptureView.swift` contains the camera-first capture screen.
- `VoiceCamera/Services/CameraController.swift` owns `AVCaptureSession` and photo capture.
- `VoiceCamera/Services/AudioRecorderController.swift` owns microphone recording and Speech transcription.
- `VoiceCamera/Services/SessionStore.swift` persists the active job, photos, recordings, transcript, report, and estimate data.
- `VoiceCamera/Views/ReviewView.swift` contains caption, transcript, and audio review.
- `VoiceCamera/Views/ReportView.swift` contains report preview and text/PDF sharing.
- `VoiceCamera/Views/EstimateView.swift` contains estimate draft line items and totals.
- `VoiceCamera/Resources/Info.plist` contains camera, microphone, speech, and photo-library permission strings.
