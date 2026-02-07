//
//  VINCameraView.swift
//  MintCheck
//
//  Camera-based VIN scanner using AVFoundation and Vision framework
//

import SwiftUI
import AVFoundation
import Vision
import Combine

struct VINCameraView: View {
    let onVINScanned: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var cameraManager = VINCameraManager()
    @State private var detectedVIN: String?
    @State private var showPermissionAlert = false
    @State private var permissionDenied = false
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            // Scanning frame overlay
            VStack {
                Spacer()
                
                // Scanning frame with corner marks
                ZStack {
                    // Dimmed overlay with cutout
                    Color.black.opacity(0.5)
                        .mask(
                            VStack(spacing: 0) {
                                Spacer()
                                Rectangle()
                                    .frame(height: 120)
                                Spacer()
                            }
                        )
                    
                    // Corner brackets for scanning frame
                    VStack(spacing: 0) {
                        Spacer()
                        
                        HStack(spacing: 0) {
                            Spacer()
                            
                            // Scanning frame
                            VStack(spacing: 0) {
                                // Top corners
                                HStack(spacing: 0) {
                                    // Top left corner
                                    VStack(alignment: .leading, spacing: 0) {
                                        Rectangle()
                                            .fill(Color.mintGreen)
                                            .frame(width: 30, height: 3)
                                        Rectangle()
                                            .fill(Color.mintGreen)
                                            .frame(width: 3, height: 30)
                                    }
                                    
                                    Spacer()
                                    
                                    // Top right corner
                                    VStack(alignment: .trailing, spacing: 0) {
                                        Rectangle()
                                            .fill(Color.mintGreen)
                                            .frame(width: 30, height: 3)
                                        Rectangle()
                                            .fill(Color.mintGreen)
                                            .frame(width: 3, height: 30)
                                    }
                                }
                                
                                Spacer()
                                    .frame(height: 120)
                                
                                // Bottom corners
                                HStack(spacing: 0) {
                                    // Bottom left corner
                                    VStack(alignment: .leading, spacing: 0) {
                                        Rectangle()
                                            .fill(Color.mintGreen)
                                            .frame(width: 3, height: 30)
                                        Rectangle()
                                            .fill(Color.mintGreen)
                                            .frame(width: 30, height: 3)
                                    }
                                    
                                    Spacer()
                                    
                                    // Bottom right corner
                                    VStack(alignment: .trailing, spacing: 0) {
                                        Rectangle()
                                            .fill(Color.mintGreen)
                                            .frame(width: 3, height: 30)
                                        Rectangle()
                                            .fill(Color.mintGreen)
                                            .frame(width: 30, height: 3)
                                    }
                                }
                            }
                            .frame(width: UIScreen.main.bounds.width - 80, height: 120)
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Instructions and detected VIN
                VStack(spacing: 16) {
                    Text("Point camera at VIN")
                        .font(.system(size: FontSize.h5, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    
                    if let vin = detectedVIN {
                        VStack(spacing: 12) {
                            Text(vin)
                                .font(.system(size: FontSize.h4, weight: .bold).monospaced())
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.mintGreen)
                                .cornerRadius(LayoutConstants.borderRadius)
                            
                            PrimaryButton(
                                title: "Use This VIN",
                                action: {
                                    onVINScanned(vin)
                                    dismiss()
                                }
                            )
                            .padding(.horizontal, 24)
                        }
                    } else {
                        Text("Align the VIN in the frame above")
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.bottom, 60)
            }
            
            // Loading screen while camera initializes
            if !cameraManager.isCameraReady && !permissionDenied {
                ZStack {
                    Color.mintGreen
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        // Logo lockup
                        Image("lockup-white")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                        
                        // Progress indicator
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                            .padding(.top, 8)
                        
                        // Loading message
                        Text("Initializing camera...")
                            .font(.system(size: FontSize.bodyLarge, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Permission denied view
            if permissionDenied {
                VStack(spacing: 24) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.textSecondary)
                    
                    Text("Camera Access Required")
                        .font(.system(size: FontSize.h3, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("MintCheck needs camera access to scan your vehicle's VIN number. Please enable camera access in Settings.")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }) {
                        Text("Open Settings")
                            .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.mintGreen)
                            .cornerRadius(LayoutConstants.borderRadius)
                    }
                    .padding(.horizontal, 40)
                    
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.deepBackground)
            }
        }
        .onAppear {
            cameraManager.setupCamera { success in
                if !success {
                    permissionDenied = true
                }
            }
            cameraManager.onVINDetected = { vin in
                detectedVIN = vin
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: VINCameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        cameraManager.setupPreviewLayer(in: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view bounds change
        // Also ensure preview layer is set up if session is running
        DispatchQueue.main.async {
            cameraManager.updatePreviewLayerFrame(in: uiView)
        }
    }
}

// MARK: - Camera Manager
class VINCameraManager: NSObject, ObservableObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private lazy var textRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            if let vin = self?.extractVIN(from: observations) {
                DispatchQueue.main.async {
                    self?.onVINDetected?(vin)
                }
            }
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false // VINs don't need language correction
        return request
    }()
    
    var onVINDetected: ((String) -> Void)?
    @Published var isCameraReady = false
    private var lastProcessedTime: Date = Date()
    private let processingInterval: TimeInterval = 0.5 // Process every 0.5 seconds
    
    func setupCamera(completion: @escaping (Bool) -> Void) {
        // Check permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startSession(completion: completion)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.startSession(completion: completion)
                    } else {
                        completion(false)
                    }
                }
            }
        default:
            completion(false)
        }
    }
    
    private func startSession(completion: @escaping (Bool) -> Void) {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            completion(false)
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            videoOutput = output
        }
        
        captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            DispatchQueue.main.async {
                // Set up preview layer now that session is running
                if let view = self.previewView {
                    self.createPreviewLayer(in: view, session: session)
                }
                completion(true)
            }
        }
    }
    
    private var previewView: UIView?
    
    func setupPreviewLayer(in view: UIView) {
        previewView = view
        
        // If session is already running, set up layer immediately
        if let session = captureSession, session.isRunning {
            createPreviewLayer(in: view, session: session)
        }
    }
    
    private func createPreviewLayer(in view: UIView, session: AVCaptureSession) {
        // Remove existing layer if any
        previewLayer?.removeFromSuperlayer()
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
        
        // Update frame - use a small delay to ensure view has proper bounds
        DispatchQueue.main.async {
            layer.frame = view.bounds
            // Mark camera as ready once frame is set and view has bounds
            if !view.bounds.isEmpty {
                self.isCameraReady = true
            }
        }
    }
    
    func updatePreviewLayerFrame(in view: UIView) {
        guard let layer = previewLayer else {
            // Try to set up layer if session is now available
            if let session = captureSession, session.isRunning {
                createPreviewLayer(in: view, session: session)
            }
            return
        }
        
        // Use CATransaction to animate frame changes smoothly
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = view.bounds
        CATransaction.commit()
        
        // Mark camera as ready once frame is set and view has bounds
        if !view.bounds.isEmpty && !isCameraReady {
            isCameraReady = true
        }
    }
    
    func stopSession() {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
        isCameraReady = false
    }
    
    
    private func extractVIN(from observations: [VNRecognizedTextObservation]) -> String? {
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            let text = topCandidate.string.uppercased().replacingOccurrences(of: " ", with: "")
            
            // Check if this looks like a VIN (17 characters, matches pattern)
            if text.count == 17 && text.isValidVIN {
                return text
            }
            
            // Also check for VINs that might be split across lines or have spaces
            // Try to find 17-character sequences within longer text
            let cleaned = text.filter { $0.isLetter || $0.isNumber }
            if cleaned.count >= 17 {
                // Try sliding window to find valid VIN
                for i in 0...(cleaned.count - 17) {
                    let substring = String(cleaned.dropFirst(i).prefix(17))
                    if substring.isValidVIN {
                        return substring
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension VINCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Throttle processing to avoid performance issues
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= processingInterval else { return }
        lastProcessedTime = now
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Process text recognition
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try handler.perform([textRequest])
        } catch {
            return
        }
        
        // Handle results in textRequest's completion
    }
}

