# iOS Voice Camera POC

Static prototype for the PRD in `docs/ios-voice-camera-prd.md`.

Open `index.html` in a browser to review the workflow. Camera and microphone permissions usually require HTTPS or `localhost`; if direct file access blocks device APIs, run any static file server from this folder.

Example:

```sh
python3 -m http.server 8080
```

Then open `http://localhost:8080`.

## What It Demonstrates

- Camera-first capture flow.
- Active job/session fields.
- Rapid photo capture into a local session.
- Voice recording state and elapsed timer.
- Photo-to-recording timestamp association.
- Transcript and caption editing.
- Report template draft generation.
- Estimate line item draft and total calculation.
- Email, SMS, browser share, and print-to-PDF handoff controls.

## Browser Notes

- Camera preview uses `navigator.mediaDevices.getUserMedia`.
- Audio capture uses `MediaRecorder`.
- Speech recognition uses browser-provided `SpeechRecognition` when available.
- All session data is stored locally in `localStorage`.
- A fallback placeholder photo path is included for environments without camera access.

## Manual POC Check

1. Open the capture screen and grant camera permission if prompted.
2. Capture several photos and confirm recent thumbnails update immediately.
3. Start recording, capture more photos, then stop recording.
4. Review the photos and confirm recording-relative timestamps appear.
5. Edit transcript text and use "Suggest captions".
6. Generate a report and confirm selected photos, captions, and transcript are included.
7. Add estimate lines and confirm totals update.
8. Try the email, SMS, share, and PDF buttons in the report or estimate views.
