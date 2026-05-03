import AVFoundation
import Combine
import UIKit

final class CameraController: NSObject, ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var isSessionRunning = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var lastError: String?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "voice-camera.capture-session")
    private let photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var cameraPosition: AVCaptureDevice.Position = .back
    private var delegates: [PhotoCaptureDelegate] = []

    func requestAccessAndStart() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        self?.configureAndStart()
                    }
                }
            }
        default:
            authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            lastError = "Camera permission is required."
        }
    }

    func capturePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
        let settings = AVCapturePhotoSettings()
        if photoOutput.supportedFlashModes.contains(flashMode) {
            settings.flashMode = flashMode
        }

        let delegate = PhotoCaptureDelegate { [weak self] id, result in
            Task { @MainActor in
                self?.delegates.removeAll { $0.id == id }
                completion(result)
            }
        }
        delegates.append(delegate)
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    func switchCamera() {
        cameraPosition = cameraPosition == .back ? .front : .back
        configureAndStart()
    }

    func cycleFlash() {
        switch flashMode {
        case .off:
            flashMode = .auto
        case .auto:
            flashMode = .on
        default:
            flashMode = .off
        }
    }

    private func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            if let currentInput = self.currentInput {
                self.session.removeInput(currentInput)
            }

            do {
                guard let device = Self.camera(position: self.cameraPosition) else {
                    throw CameraError.deviceUnavailable
                }

                let input = try AVCaptureDeviceInput(device: device)
                guard self.session.canAddInput(input) else {
                    throw CameraError.cannotAddInput
                }
                self.session.addInput(input)
                self.currentInput = input

                if !self.session.outputs.contains(where: { $0 === self.photoOutput }), self.session.canAddOutput(self.photoOutput) {
                    self.session.addOutput(self.photoOutput)
                    self.photoOutput.maxPhotoQualityPrioritization = .quality
                }

                self.session.commitConfiguration()

                if !self.session.isRunning {
                    self.session.startRunning()
                }

                Task { @MainActor in
                    self.isSessionRunning = self.session.isRunning
                    self.lastError = nil
                }
            } catch {
                self.session.commitConfiguration()
                Task { @MainActor in
                    self.lastError = error.localizedDescription
                    self.isSessionRunning = false
                }
            }
        }
    }

    private static func camera(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let id = UUID()
    private let completion: (UUID, Result<UIImage, Error>) -> Void

    init(completion: @escaping (UUID, Result<UIImage, Error>) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            completion(id, .failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            completion(id, .failure(CameraError.imageDataUnavailable))
            return
        }

        completion(id, .success(image))
    }
}

enum CameraError: LocalizedError {
    case deviceUnavailable
    case cannotAddInput
    case imageDataUnavailable

    var errorDescription: String? {
        switch self {
        case .deviceUnavailable:
            "Camera device unavailable."
        case .cannotAddInput:
            "Camera input could not be added."
        case .imageDataUnavailable:
            "Captured image data unavailable."
        }
    }
}
