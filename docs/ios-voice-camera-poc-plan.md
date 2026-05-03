# iOS Voice Camera POC Plan

## POC Objective

Demonstrate the core product flow from `docs/ios-voice-camera-prd.md` without committing to a native iOS architecture yet:

1. Open into a camera-first capture screen.
2. Capture photos into an active local job/session.
3. Toggle voice recording while photos continue to work.
4. Associate photos with recording timestamps and transcript text.
5. Review and edit captions.
6. Generate report and estimate drafts.
7. Produce email/SMS/share-ready outputs.

The POC is implemented as a static browser prototype in `poc/ios-voice-camera/`. It is intentionally lightweight so product and workflow feedback can happen before a Swift/AVFoundation implementation.

## Scope Mapping

### Milestone 1: Capture Foundation

- Active session model with job/contact fields.
- Camera preview using `navigator.mediaDevices.getUserMedia` when available.
- Canvas-based still capture.
- In-session photo list with timestamps and inclusion toggles.
- Local persistence through `localStorage`.
- Placeholder capture fallback when camera access is denied or unavailable.

### Milestone 2: Voice Notes

- Microphone toggle with elapsed recording timer.
- `MediaRecorder` audio capture when supported.
- Photo timestamps relative to active recording.
- Audio playback on the review screen.
- Fallback voice-note mode when browser recording is unavailable.

### Milestone 3: Transcription and Review

- Browser speech recognition when available.
- Manual transcript editing.
- Per-photo editable captions.
- Generated caption suggestions from transcript text and timestamp context.

### Milestone 4: Reports and Sharing

- Template selection for site documentation, estimate support, before/after, and client update.
- Editable report title and summary.
- Print-to-PDF preview path through the browser print dialog.
- Email `mailto:` draft and SMS body draft.
- Share sheet path through `navigator.share` where available.

### Milestone 5: Estimate Drafts

- Estimate mode toggle.
- Editable estimate line items.
- Quantity, unit, unit cost, and total calculation.
- Assumptions field and plain-text estimate export.

## Native iOS Translation Path

The POC deliberately mirrors the PRD data model so the native app can replace browser APIs with iOS frameworks later:

- Camera preview/capture: replace `getUserMedia` and canvas capture with `AVCaptureSession` and `AVCapturePhotoOutput`.
- Voice recording: replace `MediaRecorder` with `AVAudioRecorder` or `AVAudioEngine`.
- Speech recognition: replace browser recognition with Apple Speech framework, ideally on-device where supported.
- Local persistence: replace `localStorage` with SwiftData/Core Data plus sandbox media file URLs.
- PDF export: replace browser print with `PDFKit`/`UIGraphicsPDFRenderer`.
- Sharing: replace link-based drafts with `MFMailComposeViewController`, `MFMessageComposeViewController`, and `UIActivityViewController`.

## POC Acceptance Checklist

- User can open the POC and see a camera-first capture surface.
- User can create or rename a session without leaving capture.
- User can capture at least 10 photos in one session.
- User can toggle recording and continue capturing photos.
- Photos captured during recording show relative recording timestamps.
- User can edit captions and transcript text before generating outputs.
- User can generate a report draft from selected photos.
- User can generate an estimate draft with updating totals.
- User can use email, SMS, share, or print/export controls from the draft.

## Known POC Constraints

- Browser camera and microphone permissions require HTTPS or localhost in most browsers.
- iOS Safari support for `MediaRecorder` and Web Speech APIs varies by version.
- PDF export uses browser print/save-as-PDF rather than native PDF generation.
- Email and SMS are draft handoffs through URI schemes, not native in-app composers.
- Captured images are stored as data URLs in `localStorage`, so this is not suitable for long-term or large-volume media storage.
