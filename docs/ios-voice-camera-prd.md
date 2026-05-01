# PRD: iOS Voice Camera for Reports, Estimates, and Documentation

## 1. Overview

Build a native iOS camera app that lets field users capture photos quickly while speaking notes in the moment. The app links each photo with optional voice narration, transcription, location/time metadata, and project context, then turns the captured material into shareable reports, estimates, and documentation that can be sent by email or SMS.

The core product promise is frictionless field capture: open the app, take photos without breaking flow, speak what matters, and leave with a professional deliverable instead of a disorganized camera roll.

## 2. Goals

- Enable fast photo capture with minimal taps.
- Allow voice notes to be recorded while photos are being taken.
- Automatically associate spoken notes with the correct photo or capture session.
- Generate structured reports, estimates, and documentation from photos, notes, and metadata.
- Support sending finished outputs through email and SMS from the app.
- Preserve user confidence with clear review, edit, and export controls.

## 3. Non-Goals

- Full CRM replacement.
- Invoicing, payments, or accounting integrations in the first release.
- Multi-user collaboration in real time.
- Desktop/web report editing.
- Fully automated price quoting without user review.
- Medical, legal, insurance-claim, or code-compliance certification decisions.

## 4. Target Users

- Contractors and tradespeople documenting job sites.
- Home service professionals creating estimates.
- Inspectors documenting conditions and deficiencies.
- Property managers collecting maintenance evidence.
- Insurance-adjacent field workers preparing visual documentation.
- Small business owners who need quick client-ready summaries.

## 5. Key Use Cases

### 5.1 Field Documentation

A user walks through a site, takes multiple photos, and verbally describes each issue. The app groups photos into a job report with timestamps, captions, and notes.

### 5.2 Estimate Preparation

A user photographs damaged or incomplete work, speaks measurements and repair needs, then creates an estimate draft with line items that can be reviewed before sending.

### 5.3 Before-and-After Records

A user captures photos before, during, and after a job. The app organizes them by phase and exports a clean proof-of-work report.

### 5.4 Client Communication

A user captures a few photos, dictates a plain-language summary, and sends a concise update to a client by SMS or email.

## 6. User Experience Principles

- Camera first: the app should open directly to a ready camera when permissions allow.
- Hands-light capture: voice and photo capture should work without forcing the user into forms.
- Review before send: generated content must be editable before it leaves the device.
- Progressive structure: users can capture freely first, then organize later.
- Visible state: recording, transcription, selected job, and pending exports must be obvious.
- Failure tolerant: capture should keep working when transcription, network, or sharing services are unavailable.

## 7. Product Requirements

### 7.1 Camera Capture

#### Requirements

- Open to a live camera preview by default.
- Support rear and front camera switching.
- Support flash controls where available.
- Capture high-resolution still photos.
- Show a recent capture thumbnail.
- Allow rapid consecutive photo capture.
- Store photos in an in-app job/session before export.
- Optionally save selected photos to the iOS Photos library.

#### Acceptance Criteria

- User can open the app and capture a photo within 2 seconds after the camera session is ready.
- User can take at least 10 photos in a row without leaving the camera screen.
- Captured photos appear in the active job/session immediately after processing.

### 7.2 Voice Capture During Photo Taking

#### Requirements

- Provide a prominent microphone control on the camera screen.
- Support start/stop voice recording while the camera remains usable.
- Allow photos to be taken while audio recording is active.
- Timestamp each photo relative to the active audio recording.
- Associate spoken segments with nearby photos automatically.
- Show clear recording state with elapsed time.
- Support audio playback during review.
- Support deleting or replacing audio notes.

#### Voice Association Rules

- If a photo is taken while recording, attach the nearest spoken segment to that photo.
- If several photos are taken during one continuous narration, attach the full session audio to the group and suggest per-photo captions from transcript timing.
- If a note is recorded immediately after a photo, suggest linking it to the most recent photo.

#### Acceptance Criteria

- User can record audio and take photos without interruption.
- Every photo captured during recording includes a reliable timestamp.
- User can review which audio note or transcript is attached to each photo.

### 7.3 Speech-to-Text and Note Generation

#### Requirements

- Transcribe recorded voice notes into editable text.
- Display transcription status per recording.
- Allow manual correction of transcripts.
- Generate concise photo captions from transcript segments.
- Generate a session summary from all notes and photos.
- Continue to save audio even if transcription fails.

#### Acceptance Criteria

- Transcription failures do not block photo capture or report creation.
- User can edit generated captions before export.
- Reports clearly distinguish user-entered text from generated draft text when still unreviewed.

### 7.4 Jobs and Sessions

#### Requirements

- Create a new job/session from the camera screen.
- Support job name, client/contact name, address, phone, email, and notes.
- Auto-name sessions using date/time when no name is provided.
- Allow photos, audio, transcripts, and report drafts to be grouped under one job.
- Support adding photos to an existing job.
- Provide a job/session gallery for review.

#### Acceptance Criteria

- User can capture without creating a formal job first.
- Anonymous sessions can be renamed later.
- No captured media is lost if the app is backgrounded during a session.

### 7.5 Report Builder

#### Requirements

- Generate a report draft from selected photos, captions, transcript notes, date/time, and optional location.
- Provide report templates:
  - Site documentation
  - Estimate support
  - Before-and-after summary
  - Client update
- Allow user to reorder photos.
- Allow user to include/exclude individual photos.
- Allow user to edit title, summary, sections, captions, and recommendations.
- Export as PDF.
- Support a lightweight plain-text summary for SMS.

#### Acceptance Criteria

- User can generate a report from a capture session in 3 taps or fewer after capture is complete.
- User can preview the final PDF before sending.
- Exported reports include selected photos and edited captions.

### 7.6 Estimate Drafting

#### Requirements

- Allow users to mark a session as estimate-related.
- Convert spoken notes into editable estimate line item suggestions.
- Support fields for line item description, quantity, unit, unit cost, and total.
- Allow adding, removing, and editing line items.
- Include optional disclaimers and assumptions.
- Export estimate summary as PDF and plain text.

#### Acceptance Criteria

- Generated estimate line items are always drafts requiring user review.
- User can send an estimate without generated pricing if they only want documentation.
- Totals update when quantity or unit cost changes.

### 7.7 Email and SMS Sharing

#### Requirements

- Send PDF reports by email using the native iOS mail composer where available.
- Send concise summaries and links/attachments through SMS using native iOS message composer where available.
- Support recipient selection from job contact fields.
- Allow editing subject/body before sending.
- Track local sent status for each export attempt.
- Provide fallback share sheet export when email or SMS composer is unavailable.

#### Acceptance Criteria

- User can send an email report without leaving the app flow.
- User can send an SMS summary with selected report details.
- User is warned when SMS content is too long or cannot include the full PDF.

### 7.8 Review and Editing

#### Requirements

- Provide a session review screen with photos, captions, transcripts, and audio playback.
- Support photo deletion from a job/session.
- Support caption editing per photo.
- Support bulk selection for report creation.
- Show unsent draft reports.
- Support regenerating draft text after edits.

#### Acceptance Criteria

- User can correct generated text before export.
- Deleting a photo from a report does not necessarily delete it from the session unless explicitly confirmed.

### 7.9 Permissions and Privacy

#### Requirements

- Request camera permission.
- Request microphone permission.
- Request speech recognition permission if using on-device or Apple speech transcription.
- Request photo library add-only permission only when saving to Photos.
- Request location permission only if the user enables location tagging.
- Explain permission value in plain language before or during prompts.
- Store captured media locally by default.
- Provide a delete job/session action that removes associated local media.

#### Acceptance Criteria

- App remains usable for photo capture when optional permissions such as location are denied.
- App clearly indicates when voice recording or transcription is unavailable due to permissions.

## 8. Suggested Information Architecture

- Camera
- Active Session
- Review
- Reports
- Estimates
- Share
- Settings

## 9. Core Screens

### Camera Screen

- Live camera preview.
- Shutter button.
- Microphone toggle with recording timer.
- Flash button.
- Camera switch button.
- Active job/session label.
- Recent thumbnail.
- Quick action to finish capture and review.

### Session Review Screen

- Photo grid/list.
- Per-photo caption.
- Linked transcript snippet.
- Audio playback controls.
- Include/exclude controls.
- Generate report and generate estimate actions.

### Report Editor

- Template selector.
- Editable title and summary.
- Ordered photo sections.
- Editable captions and notes.
- PDF preview.
- Send email, send SMS, and share actions.

### Estimate Editor

- Editable line items.
- Photo evidence section.
- Assumptions and notes.
- Total calculation.
- PDF preview.
- Send email, send SMS, and share actions.

### Settings

- Default report template.
- Business/contact identity.
- Default email subject/body.
- Photo save preferences.
- Transcription preferences.
- Data retention/delete controls.

## 10. Data Model

### JobSession

- `id`
- `title`
- `clientName`
- `clientEmail`
- `clientPhone`
- `address`
- `createdAt`
- `updatedAt`
- `location`
- `status`
- `notes`

### PhotoItem

- `id`
- `jobSessionId`
- `localFileURL`
- `thumbnailURL`
- `capturedAt`
- `recordingTimestamp`
- `caption`
- `generatedCaption`
- `userReviewed`
- `includedInReport`

### VoiceRecording

- `id`
- `jobSessionId`
- `localFileURL`
- `startedAt`
- `endedAt`
- `duration`
- `transcriptionStatus`
- `transcript`

### ReportDraft

- `id`
- `jobSessionId`
- `type`
- `title`
- `summary`
- `sections`
- `pdfFileURL`
- `createdAt`
- `updatedAt`
- `sentStatus`

### EstimateDraft

- `id`
- `jobSessionId`
- `title`
- `lineItems`
- `assumptions`
- `subtotal`
- `tax`
- `total`
- `pdfFileURL`
- `sentStatus`

## 11. Technical Considerations

- Use AVFoundation for camera capture.
- Use AVAudioRecorder or AVAudioEngine for voice recording.
- Use Speech framework for iOS-native transcription where feasible.
- Consider on-device transcription first for privacy and offline resilience.
- Use local persistence for sessions and metadata.
- Store media files in the app sandbox with stable references from persisted records.
- Generate PDFs locally when possible.
- Use MessageUI for native email and SMS composers.
- Provide UIActivityViewController as a fallback sharing path.
- Design capture pipeline so photo capture is never blocked by transcription or report generation.

## 12. Offline and Failure Behavior

- Photo and audio capture must work offline.
- Transcription can be queued for later if it requires network availability.
- Report creation should still work with manually entered captions if transcription is unavailable.
- Sharing failures should preserve the export draft and allow retry.
- App should recover active session state after backgrounding or termination where possible.

## 13. Analytics and Success Metrics

- Time from app open to first photo capture.
- Number of photos captured per session.
- Percentage of sessions with voice recording.
- Percentage of recordings successfully transcribed.
- Percentage of sessions converted into reports or estimates.
- Percentage of reports or estimates shared by email/SMS.
- Time from final capture to successful share.
- Manual edit rate for generated captions and summaries.

## 14. MVP Scope

### Must Have

- Camera capture.
- Session grouping.
- Voice recording during photo capture.
- Photo-to-audio timestamp association.
- Basic transcription.
- Editable captions.
- Simple report generation.
- PDF export.
- Email sharing.
- SMS summary sharing.
- Local session storage.

### Should Have

- Estimate draft line items.
- Template selection.
- Contact fields.
- Share sheet fallback.
- Audio playback in review.
- Location tagging.

### Later

- Cloud sync.
- Team accounts.
- CRM integrations.
- Advanced pricing catalogs.
- Custom branded report templates.
- Web editor.
- AI visual defect detection.

## 15. Open Questions

- Should transcription be fully on-device, cloud-based, or user-selectable?
- Should generated report language use a local model, server-side generation, or rules-based templates in MVP?
- Are estimates intended to include pricing, or only scope-of-work documentation?
- What industries should the first templates target?
- Should SMS send the full report through an attachment, a shortened summary, or a hosted link?
- Is Photos library saving required by default, or should app-local storage be the primary record?
- What minimum iOS version should be supported?

## 16. Release Milestones

### Milestone 1: Capture Foundation

- Camera capture.
- Session model.
- In-app photo gallery.
- Local media storage.

### Milestone 2: Voice Notes

- Microphone permission.
- Voice recording while capturing.
- Audio/photo timestamp association.
- Audio playback.

### Milestone 3: Transcription and Review

- Speech-to-text.
- Editable transcripts and captions.
- Session review workflow.

### Milestone 4: Reports and Sharing

- Report templates.
- PDF generation.
- Email composer.
- SMS summary composer.
- Share sheet fallback.

### Milestone 5: Estimate Drafts

- Estimate mode.
- Draft line items.
- Totals.
- Estimate PDF export and sharing.

