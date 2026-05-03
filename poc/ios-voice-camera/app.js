const storageKey = "iosVoiceCameraPoc.session";

const state = {
  session: createSession(),
  stream: null,
  facingMode: "environment",
  mediaRecorder: null,
  speechRecognition: null,
  recording: null,
  recordingTimer: null,
  recognitionSupported: false,
};

const els = {};

document.addEventListener("DOMContentLoaded", () => {
  bindElements();
  loadSession();
  bindEvents();
  initCamera();
  initSpeechRecognition();
  renderAll();
});

function bindElements() {
  document.querySelectorAll("[id]").forEach((el) => {
    els[el.id] = el;
  });
  els.tabs = Array.from(document.querySelectorAll(".tab"));
  els.tabPanels = Array.from(document.querySelectorAll(".tab-panel"));
}

function bindEvents() {
  els.tabs.forEach((tab) => {
    tab.addEventListener("click", () => activateTab(tab.dataset.tab));
  });

  [
    "sessionTitle",
    "clientName",
    "address",
    "clientEmail",
    "clientPhone",
    "sessionNotes",
    "estimateMode",
    "transcriptText",
    "reportTemplate",
    "reportTitle",
    "reportSummary",
    "estimateAssumptions",
  ].forEach((id) => {
    els[id].addEventListener("input", syncFormToState);
  });

  els.captureButton.addEventListener("click", capturePhoto);
  els.recordButton.addEventListener("click", toggleRecording);
  els.switchCameraButton.addEventListener("click", switchCamera);
  els.finishCaptureButton.addEventListener("click", () => activateTab("review"));
  els.newSessionButton.addEventListener("click", startNewSession);
  els.clearSessionButton.addEventListener("click", clearSession);
  els.suggestCaptionsButton.addEventListener("click", suggestCaptions);
  els.generateReportButton.addEventListener("click", generateReport);
  els.emailReportButton.addEventListener("click", () => openMail(buildReportText()));
  els.smsReportButton.addEventListener("click", () => openSms(buildSmsSummary()));
  els.shareReportButton.addEventListener("click", shareReport);
  els.printReportButton.addEventListener("click", () => {
    activateTab("report");
    window.print();
  });
  els.addLineItemButton.addEventListener("click", () => addLineItem());
  els.generateEstimateButton.addEventListener("click", generateEstimate);
  els.emailEstimateButton.addEventListener("click", () => openMail(buildEstimateText(), "Estimate draft"));
  els.smsEstimateButton.addEventListener("click", () => openSms(buildEstimateSms()));
}

function createSession() {
  const now = new Date();
  return {
    id: crypto.randomUUID ? crypto.randomUUID() : String(Date.now()),
    title: `Session ${formatDateTime(now)}`,
    clientName: "",
    clientEmail: "",
    clientPhone: "",
    address: "",
    notes: "",
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
    estimateMode: false,
    transcript: "",
    photos: [],
    recordings: [],
    report: {
      template: "Site documentation",
      title: "",
      summary: "",
    },
    estimate: {
      assumptions: "Draft estimate only. Pricing and scope require user review before sending.",
      lineItems: [],
    },
  };
}

function loadSession() {
  const stored = localStorage.getItem(storageKey);
  if (!stored) {
    addLineItem({ description: "Review documented work", quantity: 1, unit: "each", unitCost: 0 }, false);
    return;
  }

  try {
    state.session = { ...createSession(), ...JSON.parse(stored) };
    state.session.report = { template: "Site documentation", title: "", summary: "", ...state.session.report };
    state.session.estimate = { assumptions: "", lineItems: [], ...state.session.estimate };
  } catch {
    state.session = createSession();
  }
}

function saveSession() {
  state.session.updatedAt = new Date().toISOString();
  localStorage.setItem(storageKey, JSON.stringify(state.session));
}

async function initCamera() {
  if (!navigator.mediaDevices?.getUserMedia) {
    showCameraFallback("Camera API unavailable");
    return;
  }

  try {
    if (state.stream) {
      state.stream.getTracks().forEach((track) => track.stop());
    }

    state.stream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: state.facingMode },
      audio: false,
    });
    els.cameraPreview.srcObject = state.stream;
    els.cameraPreview.hidden = false;
    els.cameraFallback.hidden = true;
    els.permissionStatus.textContent = "Camera ready";
  } catch {
    showCameraFallback("Camera permission unavailable");
  }
}

function showCameraFallback(message) {
  els.permissionStatus.textContent = message;
  els.cameraPreview.hidden = true;
  els.cameraFallback.hidden = false;
}

function initSpeechRecognition() {
  const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  state.recognitionSupported = Boolean(Recognition);
  if (!Recognition) {
    els.transcriptionStatus.textContent = "Manual transcript";
    return;
  }

  const recognition = new Recognition();
  recognition.continuous = true;
  recognition.interimResults = true;
  recognition.lang = "en-US";
  recognition.onresult = (event) => {
    let finalText = "";
    let interimText = "";
    for (let i = event.resultIndex; i < event.results.length; i += 1) {
      const result = event.results[i];
      if (result.isFinal) finalText += result[0].transcript;
      else interimText += result[0].transcript;
    }
    if (finalText.trim()) {
      state.session.transcript = `${state.session.transcript} ${finalText.trim()}`.trim();
      els.transcriptText.value = state.session.transcript;
      saveSession();
    }
    els.transcriptionStatus.textContent = interimText ? "Listening..." : "Transcribing";
  };
  recognition.onerror = () => {
    els.transcriptionStatus.textContent = "Manual transcript";
  };
  recognition.onend = () => {
    if (state.recording) {
      try {
        recognition.start();
      } catch {
        els.transcriptionStatus.textContent = "Manual transcript";
      }
    }
  };
  state.speechRecognition = recognition;
}

function syncFormToState() {
  state.session.title = els.sessionTitle.value.trim() || state.session.title;
  state.session.clientName = els.clientName.value;
  state.session.address = els.address.value;
  state.session.clientEmail = els.clientEmail.value;
  state.session.clientPhone = els.clientPhone.value;
  state.session.notes = els.sessionNotes.value;
  state.session.estimateMode = els.estimateMode.checked;
  state.session.transcript = els.transcriptText.value;
  state.session.report.template = els.reportTemplate.value;
  state.session.report.title = els.reportTitle.value;
  state.session.report.summary = els.reportSummary.value;
  state.session.estimate.assumptions = els.estimateAssumptions.value;
  saveSession();
  renderStats();
  renderLabels();
}

function renderAll() {
  renderForms();
  renderLabels();
  renderStats();
  renderRecentCaptures();
  renderPhotoReview();
  renderRecordings();
  renderReportPreview();
  renderLineItems();
  renderEstimatePreview();
}

function renderForms() {
  els.sessionTitle.value = state.session.title;
  els.clientName.value = state.session.clientName;
  els.address.value = state.session.address;
  els.clientEmail.value = state.session.clientEmail;
  els.clientPhone.value = state.session.clientPhone;
  els.sessionNotes.value = state.session.notes;
  els.estimateMode.checked = state.session.estimateMode;
  els.transcriptText.value = state.session.transcript;
  els.reportTemplate.value = state.session.report.template;
  els.reportTitle.value = state.session.report.title;
  els.reportSummary.value = state.session.report.summary;
  els.estimateAssumptions.value = state.session.estimate.assumptions;
}

function renderLabels() {
  els.activeSessionLabel.textContent = state.session.title || "Untitled session";
}

function renderStats() {
  els.photoCount.textContent = state.session.photos.length;
  els.includedCount.textContent = state.session.photos.filter((photo) => photo.includedInReport).length;
  els.recordingCount.textContent = state.session.recordings.length;
}

function renderRecentCaptures() {
  els.recentCaptures.innerHTML = "";
  const recent = state.session.photos.slice(-10).reverse();
  if (!recent.length) {
    els.recentCaptures.innerHTML = '<div class="empty-state">No captures yet</div>';
    return;
  }
  recent.forEach((photo) => {
    const img = document.createElement("img");
    img.src = photo.localFileURL;
    img.alt = photo.caption || "Captured job site photo";
    els.recentCaptures.appendChild(img);
  });
}

function renderPhotoReview() {
  els.photoReviewList.innerHTML = "";
  if (!state.session.photos.length) {
    els.photoReviewList.innerHTML = '<div class="empty-state">Captured photos will appear here.</div>';
    return;
  }

  const template = document.getElementById("photoReviewTemplate");
  state.session.photos.forEach((photo) => {
    const node = template.content.firstElementChild.cloneNode(true);
    const img = node.querySelector("img");
    img.src = photo.localFileURL;
    img.alt = photo.caption || "Captured job site photo";
    node.querySelector(".photo-time").textContent = formatDateTime(new Date(photo.capturedAt));
    node.querySelector(".include-photo").checked = photo.includedInReport;
    node.querySelector(".photo-caption").value = photo.caption || photo.generatedCaption || "";
    node.querySelector(".photo-recording").textContent = photo.recordingTimestamp === null
      ? "No active voice timestamp"
      : `Captured ${formatDuration(photo.recordingTimestamp)} into recording`;

    node.querySelector(".include-photo").addEventListener("change", (event) => {
      photo.includedInReport = event.target.checked;
      saveSession();
      renderStats();
      renderReportPreview();
      renderEstimatePreview();
    });
    node.querySelector(".photo-caption").addEventListener("input", (event) => {
      photo.caption = event.target.value;
      photo.userReviewed = true;
      saveSession();
      renderRecentCaptures();
      renderReportPreview();
      renderEstimatePreview();
    });
    node.querySelector(".remove-photo").addEventListener("click", () => {
      state.session.photos = state.session.photos.filter((item) => item.id !== photo.id);
      saveSession();
      renderAll();
    });
    els.photoReviewList.appendChild(node);
  });
}

function renderRecordings() {
  els.recordingList.innerHTML = "";
  if (!state.session.recordings.length) {
    els.recordingList.innerHTML = '<div class="empty-state">Voice notes will appear here after recording.</div>';
    return;
  }
  state.session.recordings.forEach((recording) => {
    const item = document.createElement("div");
    item.className = "recording-item";
    item.innerHTML = `<span>${formatDateTime(new Date(recording.startedAt))} · ${formatDuration(recording.duration)}</span>`;
    if (recording.localFileURL) {
      const audio = document.createElement("audio");
      audio.controls = true;
      audio.src = recording.localFileURL;
      item.appendChild(audio);
    } else {
      const badge = document.createElement("span");
      badge.className = "status-pill";
      badge.textContent = "Timer only";
      item.appendChild(badge);
    }
    els.recordingList.appendChild(item);
  });
}

function renderReportPreview() {
  const selected = selectedPhotos();
  const title = state.session.report.title || `${state.session.title} Report`;
  const summary = state.session.report.summary || buildDefaultSummary();
  els.reportPreview.innerHTML = `
    <p class="eyebrow">${escapeHtml(state.session.report.template)}</p>
    <h2>${escapeHtml(title)}</h2>
    <p>${escapeHtml(summary)}</p>
    ${renderContactBlock()}
    <h3>Photo Documentation</h3>
    ${renderPreviewPhotos(selected)}
    <h3>Transcript Notes</h3>
    <p>${escapeHtml(state.session.transcript || "No transcript has been added yet.")}</p>
  `;
}

function renderLineItems() {
  els.lineItems.innerHTML = "";
  if (!state.session.estimate.lineItems.length) {
    addLineItem({ description: "Review documented work", quantity: 1, unit: "each", unitCost: 0 }, false);
  }

  const template = document.getElementById("lineItemTemplate");
  state.session.estimate.lineItems.forEach((line) => {
    const node = template.content.firstElementChild.cloneNode(true);
    node.dataset.id = line.id;
    node.querySelector(".line-description").value = line.description;
    node.querySelector(".line-quantity").value = line.quantity;
    node.querySelector(".line-unit").value = line.unit;
    node.querySelector(".line-cost").value = line.unitCost;
    node.querySelector(".line-total").textContent = currency(line.quantity * line.unitCost);

    node.querySelectorAll("input").forEach((input) => {
      input.addEventListener("input", () => updateLineItem(node));
    });
    node.querySelector(".remove-line").addEventListener("click", () => {
      state.session.estimate.lineItems = state.session.estimate.lineItems.filter((item) => item.id !== line.id);
      saveSession();
      renderLineItems();
      renderEstimatePreview();
    });
    els.lineItems.appendChild(node);
  });
  updateEstimateTotal();
}

function renderEstimatePreview() {
  const lines = state.session.estimate.lineItems;
  const rows = lines.map((line) => `
    <tr>
      <td>${escapeHtml(line.description || "Line item")}</td>
      <td>${escapeHtml(String(line.quantity))}</td>
      <td>${escapeHtml(line.unit || "")}</td>
      <td>${currency(line.unitCost)}</td>
      <td>${currency(line.quantity * line.unitCost)}</td>
    </tr>
  `).join("");
  els.estimatePreview.innerHTML = `
    <p class="eyebrow">Estimate draft</p>
    <h2>${escapeHtml(state.session.title)} Estimate</h2>
    ${renderContactBlock()}
    <table>
      <thead><tr><th>Description</th><th>Qty</th><th>Unit</th><th>Unit cost</th><th>Total</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>
    <h3>Total: ${currency(estimateTotal())}</h3>
    <p>${escapeHtml(state.session.estimate.assumptions || "")}</p>
    <h3>Photo Evidence</h3>
    ${renderPreviewPhotos(selectedPhotos())}
  `;
}

function renderContactBlock() {
  const lines = [
    state.session.clientName,
    state.session.address,
    state.session.clientEmail,
    state.session.clientPhone,
  ].filter(Boolean);
  return lines.length ? `<p>${lines.map(escapeHtml).join("<br>")}</p>` : "";
}

function renderPreviewPhotos(photos) {
  if (!photos.length) return '<div class="empty-state">No photos selected for this draft.</div>';
  return `<div class="preview-photo-grid">${photos.map((photo) => `
    <figure>
      <img src="${photo.localFileURL}" alt="${escapeHtml(photo.caption || "Documentation photo")}">
      <figcaption>${escapeHtml(photo.caption || photo.generatedCaption || "Uncaptioned photo")}</figcaption>
    </figure>
  `).join("")}</div>`;
}

function activateTab(name) {
  els.tabs.forEach((tab) => tab.classList.toggle("active", tab.dataset.tab === name));
  els.tabPanels.forEach((panel) => panel.classList.toggle("active", panel.id === name));
  if (name === "report") renderReportPreview();
  if (name === "estimate") renderEstimatePreview();
}

async function capturePhoto() {
  const dataUrl = els.cameraFallback.hidden ? captureFromVideo() : createPlaceholderImage();
  const now = new Date();
  const recordingTimestamp = state.recording ? Math.max(0, Math.round((now - state.recording.startedAtDate) / 1000)) : null;
  const photo = {
    id: crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`,
    jobSessionId: state.session.id,
    localFileURL: dataUrl,
    thumbnailURL: dataUrl,
    capturedAt: now.toISOString(),
    recordingTimestamp,
    caption: "",
    generatedCaption: recordingTimestamp === null ? "" : `Photo captured ${formatDuration(recordingTimestamp)} into narration.`,
    userReviewed: false,
    includedInReport: true,
  };
  state.session.photos.push(photo);
  saveSession();
  renderAll();
}

function captureFromVideo() {
  const video = els.cameraPreview;
  const canvas = els.captureCanvas;
  const width = video.videoWidth || 1280;
  const height = video.videoHeight || 720;
  canvas.width = width;
  canvas.height = height;
  const context = canvas.getContext("2d");
  context.drawImage(video, 0, 0, width, height);
  return canvas.toDataURL("image/jpeg", 0.88);
}

function createPlaceholderImage() {
  const canvas = els.captureCanvas;
  canvas.width = 1280;
  canvas.height = 880;
  const context = canvas.getContext("2d");
  const hue = (state.session.photos.length * 37) % 360;
  context.fillStyle = `hsl(${hue} 36% 30%)`;
  context.fillRect(0, 0, canvas.width, canvas.height);
  context.fillStyle = "rgba(255,255,255,0.12)";
  for (let i = 0; i < 10; i += 1) {
    context.fillRect(i * 142, 0, 70, canvas.height);
  }
  context.fillStyle = "#ffffff";
  context.font = "700 54px system-ui";
  context.fillText(state.session.title, 72, 120);
  context.font = "500 34px system-ui";
  context.fillText(formatDateTime(new Date()), 72, 180);
  context.fillText(`Capture ${state.session.photos.length + 1}`, 72, 240);
  return canvas.toDataURL("image/jpeg", 0.88);
}

async function toggleRecording() {
  if (state.recording) {
    stopRecording();
  } else {
    await startRecording();
  }
}

async function startRecording() {
  const recording = {
    id: crypto.randomUUID ? crypto.randomUUID() : String(Date.now()),
    jobSessionId: state.session.id,
    startedAt: new Date().toISOString(),
    startedAtDate: new Date(),
    chunks: [],
  };
  state.recording = recording;

  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    const mediaRecorder = new MediaRecorder(stream);
    mediaRecorder.ondataavailable = (event) => {
      if (event.data.size > 0) recording.chunks.push(event.data);
    };
    mediaRecorder.start();
    state.mediaRecorder = mediaRecorder;
  } catch {
    state.mediaRecorder = null;
  }

  if (state.speechRecognition) {
    try {
      state.speechRecognition.start();
      els.transcriptionStatus.textContent = "Listening...";
    } catch {
      els.transcriptionStatus.textContent = "Manual transcript";
    }
  }

  els.recordButton.classList.add("recording");
  els.recordLabel.textContent = "Stop";
  state.recordingTimer = window.setInterval(updateRecordingTimer, 250);
  updateRecordingTimer();
}

function stopRecording() {
  const recording = state.recording;
  const endedAt = new Date();
  const duration = Math.max(1, Math.round((endedAt - recording.startedAtDate) / 1000));

  const finalize = () => {
    let localFileURL = "";
    if (recording.chunks?.length) {
      const blob = new Blob(recording.chunks, { type: recording.chunks[0].type || "audio/webm" });
      localFileURL = URL.createObjectURL(blob);
    }
    state.session.recordings.push({
      id: recording.id,
      jobSessionId: state.session.id,
      localFileURL,
      startedAt: recording.startedAt,
      endedAt: endedAt.toISOString(),
      duration,
      transcriptionStatus: state.recognitionSupported ? "draft" : "manual",
      transcript: state.session.transcript,
    });
    saveSession();
    renderAll();
  };

  if (state.mediaRecorder && state.mediaRecorder.state !== "inactive") {
    state.mediaRecorder.onstop = finalize;
    state.mediaRecorder.stop();
    state.mediaRecorder.stream.getTracks().forEach((track) => track.stop());
  } else {
    finalize();
  }

  if (state.speechRecognition) {
    try {
      state.speechRecognition.stop();
    } catch {
      // Browser recognition may already be stopped.
    }
  }

  clearInterval(state.recordingTimer);
  state.recordingTimer = null;
  state.recording = null;
  state.mediaRecorder = null;
  els.recordButton.classList.remove("recording");
  els.recordLabel.textContent = "Record";
  els.recordTimer.textContent = "00:00";
  els.transcriptionStatus.textContent = state.recognitionSupported ? "Draft transcript" : "Manual transcript";
}

function updateRecordingTimer() {
  if (!state.recording) return;
  const seconds = Math.max(0, Math.round((new Date() - state.recording.startedAtDate) / 1000));
  els.recordTimer.textContent = formatDuration(seconds);
}

function switchCamera() {
  state.facingMode = state.facingMode === "environment" ? "user" : "environment";
  initCamera();
}

function suggestCaptions() {
  const sentences = splitSentences(state.session.transcript);
  state.session.photos.forEach((photo, index) => {
    if (photo.userReviewed && photo.caption) return;
    const sentence = sentences[index] || sentences[sentences.length - 1] || state.session.notes || photo.generatedCaption;
    photo.generatedCaption = sentence || "Photo documentation item.";
    photo.caption = photo.caption || photo.generatedCaption;
  });
  saveSession();
  renderAll();
}

function generateReport() {
  suggestCaptions();
  state.session.report.title = els.reportTitle.value || `${state.session.title} ${state.session.report.template}`;
  state.session.report.summary = els.reportSummary.value || buildDefaultSummary();
  renderForms();
  saveSession();
  renderReportPreview();
  activateTab("report");
}

function generateEstimate() {
  if (!state.session.estimate.lineItems.some((line) => line.description.trim())) {
    const firstCaption = selectedPhotos()[0]?.caption || "Documented repair or service scope";
    state.session.estimate.lineItems[0].description = firstCaption;
  }
  saveSession();
  renderLineItems();
  renderEstimatePreview();
  activateTab("estimate");
}

function addLineItem(line = {}, shouldRender = true) {
  state.session.estimate.lineItems.push({
    id: crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`,
    description: line.description || "",
    quantity: Number(line.quantity ?? 1),
    unit: line.unit || "each",
    unitCost: Number(line.unitCost ?? 0),
  });
  saveSession();
  if (shouldRender) {
    renderLineItems();
    renderEstimatePreview();
  }
}

function updateLineItem(node) {
  const line = state.session.estimate.lineItems.find((item) => item.id === node.dataset.id);
  if (!line) return;
  line.description = node.querySelector(".line-description").value;
  line.quantity = Number(node.querySelector(".line-quantity").value || 0);
  line.unit = node.querySelector(".line-unit").value;
  line.unitCost = Number(node.querySelector(".line-cost").value || 0);
  node.querySelector(".line-total").textContent = currency(line.quantity * line.unitCost);
  updateEstimateTotal();
  saveSession();
  renderEstimatePreview();
}

function updateEstimateTotal() {
  els.estimateTotal.textContent = currency(estimateTotal());
}

function estimateTotal() {
  return state.session.estimate.lineItems.reduce((sum, line) => sum + Number(line.quantity || 0) * Number(line.unitCost || 0), 0);
}

function selectedPhotos() {
  return state.session.photos.filter((photo) => photo.includedInReport);
}

function buildDefaultSummary() {
  const count = selectedPhotos().length;
  const parts = [
    `${count} selected photo${count === 1 ? "" : "s"} captured for ${state.session.title}.`,
    state.session.notes,
    state.session.transcript ? "Voice notes were transcribed into the draft below and should be reviewed before sending." : "",
  ].filter(Boolean);
  return parts.join(" ");
}

function buildReportText() {
  return [
    state.session.report.title || `${state.session.title} Report`,
    "",
    state.session.report.summary || buildDefaultSummary(),
    "",
    `Template: ${state.session.report.template}`,
    `Photos included: ${selectedPhotos().length}`,
    "",
    "Captions:",
    ...selectedPhotos().map((photo, index) => `${index + 1}. ${photo.caption || photo.generatedCaption || "Uncaptioned photo"}`),
    "",
    "Transcript:",
    state.session.transcript || "No transcript added.",
  ].join("\n");
}

function buildSmsSummary() {
  const summary = state.session.report.summary || buildDefaultSummary();
  return `${state.session.title}: ${summary}`.slice(0, 480);
}

function buildEstimateText() {
  return [
    `${state.session.title} Estimate`,
    "",
    ...state.session.estimate.lineItems.map((line) => `${line.description || "Line item"}: ${line.quantity} ${line.unit} x ${currency(line.unitCost)} = ${currency(line.quantity * line.unitCost)}`),
    "",
    `Total: ${currency(estimateTotal())}`,
    "",
    state.session.estimate.assumptions || "",
  ].join("\n");
}

function buildEstimateSms() {
  return `${state.session.title} estimate draft total: ${currency(estimateTotal())}. ${state.session.estimate.assumptions || ""}`.slice(0, 480);
}

function openMail(body, subject = state.session.report.title || `${state.session.title} Report`) {
  const recipient = encodeURIComponent(state.session.clientEmail || "");
  window.location.href = `mailto:${recipient}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;
}

function openSms(body) {
  const recipient = encodeURIComponent(state.session.clientPhone || "");
  window.location.href = `sms:${recipient}?&body=${encodeURIComponent(body)}`;
}

async function shareReport() {
  const text = buildReportText();
  if (navigator.share) {
    await navigator.share({ title: state.session.report.title || state.session.title, text });
  } else {
    await navigator.clipboard?.writeText(text);
    els.permissionStatus.textContent = "Report copied";
  }
}

function startNewSession() {
  if (state.recording) stopRecording();
  state.session = createSession();
  addLineItem({ description: "Review documented work", quantity: 1, unit: "each", unitCost: 0 }, false);
  saveSession();
  renderAll();
  activateTab("capture");
}

function clearSession() {
  if (!confirm("Delete the local POC session data?")) return;
  localStorage.removeItem(storageKey);
  startNewSession();
}

function splitSentences(text) {
  return text
    .split(/[.!?\n]+/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function formatDateTime(date) {
  return new Intl.DateTimeFormat(undefined, {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
  }).format(date);
}

function formatDuration(totalSeconds) {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

function currency(value) {
  return new Intl.NumberFormat(undefined, { style: "currency", currency: "USD" }).format(Number(value || 0));
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
