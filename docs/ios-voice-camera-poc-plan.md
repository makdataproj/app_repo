# iOS Voice Camera Native POC Plan

## POC Objective

Demonstrate the core product flow from `docs/ios-voice-camera-prd.md` as a native iOS app, not a browser prototype:

1. Open into a camera-first SwiftUI capture screen.
2. Capture photos into an active local job/session.
3. Toggle voice recording while photos continue to work.
4. Associate photos with recording timestamps and transcript text.
5. Review and edit captions.
6. Generate report and estimate drafts.
7. Produce native share-ready email, SMS, PDF, and text outputs.

The POC implementation lives in `ios/VoiceCamera/` and uses iOS frameworks that match the PRD target platform.

## Scope Mapping

### Milestone 1: Capture Foundation

- SwiftUI app shell with camera-first navigation.
- `AVCaptureSession`-backed preview and still photo capture.
- Rear/front camera switching.
- Flash mode support where the active camera supports flash.
- Active session model with job/contact fields.
- In-session photo list with timestamps and inclusion toggles.
- Local app sandbox storage for captured media and session state.

### Milestone 2: Voice Notes

- Microphone toggle with elapsed recording timer.
- `AVAudioRecorder` recording while the camera remains usable.
- Photo timestamps relative to the active recording.
- Audio playback on the review screen.
- Delete or replace audio notes during review.

### Milestone 3: Transcription and Review

- Speech transcription through Apple Speech framework where available.
- Manual transcript editing when transcription is unavailable or incorrect.
- Per-photo editable captions.
- Generated caption suggestions from transcript text and timestamp context.

### Milestone 4: Reports and Sharing

- Template selection for site documentation, estimate support, before/after, and client update.
- Editable report title and summary.
- Native PDF generation with `UIGraphicsPDFRenderer`.
- Email draft handoff through native iOS mail composer where available.
- SMS summary handoff through native iOS message composer where available.
- Fallback export through `UIActivityViewController`.

### Milestone 5: Estimate Drafts

- Estimate mode toggle.
- Editable estimate line items.
- Quantity, unit, unit cost, and total calculation.
- Assumptions field and PDF/plain-text estimate export.

## Native iOS Framework Mapping

- Camera preview/capture: `AVCaptureSession`, `AVCapturePhotoOutput`, and SwiftUI preview bridging.
- Voice recording: `AVAudioRecorder` with sandboxed file URLs.
- Speech recognition: Apple Speech framework.
- Local persistence: JSON/session persistence for POC, with a SwiftData/Core Data path for production.
- PDF export: `UIGraphicsPDFRenderer`.
- Sharing: `MFMailComposeViewController`, `MFMessageComposeViewController`, and `UIActivityViewController`.
- Permissions: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`, and photo-library usage strings.

## POC Acceptance Checklist

- User can open the iOS app and see a camera-first capture surface.
- User can create or rename a session without leaving capture.
- User can capture at least 10 photos in one session.
- User can toggle recording and continue capturing photos.
- Photos captured during recording show relative recording timestamps.
- User can edit captions and transcript text before generating outputs.
- User can generate a report draft from selected photos.
- User can generate an estimate draft with updating totals.
- User can use native share, email, SMS, and PDF export controls from the draft flow.

## Known POC Constraints

- Camera, microphone, speech, and photo-library access require real device permissions.
- Simulator camera behavior is limited; device testing is required for capture acceptance criteria.
- Speech transcription availability depends on device settings, supported language, and user permission.
- Mail and message composers depend on device account configuration.
- POC persistence is local-only and intended to validate workflow before production data modeling.
