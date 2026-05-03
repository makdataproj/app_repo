# Superseded Browser Prototype

This folder contains an earlier browser prototype and is not the implementation target for `docs/ios-voice-camera-prd.md`.

The PRD explicitly calls for a native iOS app. The active POC implementation is in:

```text
ios/VoiceCamera/
```

Open the native app in Xcode from:

```text
ios/VoiceCamera/VoiceCamera.xcodeproj
```

## Why This Folder Exists

The HTML/CSS/JavaScript prototype was created as a quick workflow mock, but that was the wrong implementation choice for this PRD because the product requirements depend on native iOS behavior:

- Camera capture through iOS camera APIs.
- Audio recording while capture remains usable.
- Speech transcription through Apple Speech framework where available.
- PDF generation and sharing through native iOS flows.
- Email and SMS handoff through native iOS composers where available.

Do not use this folder as the source of truth for the iOS POC. It remains only as a superseded reference unless it is explicitly removed later.
