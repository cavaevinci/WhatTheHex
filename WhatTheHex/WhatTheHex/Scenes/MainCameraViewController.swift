//
//  MainCameraViewController.swift
//  WhatTheHex
//
//  Created by Ivan Evačić on 12.08.2024..
//

import UIKit
import SnapKit
import AVFoundation

class MainCameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    lazy var colorHexLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        return label
    }()

    lazy var colorView: UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var horizontalLine: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    lazy var verticalLine: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    var isUsingFrontCamera = false
    
    var previousColor: UIColor?

    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureSession: AVCaptureSession!
    var lastUpdateTime: Date?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(copyHexToClipboard))
        colorHexLabel.addGestureRecognizer(tapGesture)
        checkCameraPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCameraSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCameraSession()
    }
    
    private func startCameraSession() {
        guard let captureSession = captureSession, !captureSession.isRunning else {
            return
        }
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
        }
    }

    private func stopCameraSession() {
        guard let captureSession = captureSession, captureSession.isRunning else {
            return
        }
        DispatchQueue.global(qos: .background).async {
            captureSession.stopRunning()
        }
    }
    
    @objc func copyHexToClipboard() {
        if let hexString = colorHexLabel.text {
            UIPasteboard.general.string = hexString
            ColorHistoryService.shared.saveColor(hexString: hexString)
            NotificationService.shared.showNotification(in: self.view, message: "Color \(hexString) copied to clipboard.")
        }
    }
    
    func getCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        return discoverySession.devices.first(where: { $0.position == position })
    }
    
    @objc func toggleCamera() {
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else {
            return
        }
        
        let newCameraPosition: AVCaptureDevice.Position = isUsingFrontCamera ? .back : .front
        isUsingFrontCamera = !isUsingFrontCamera
        
        guard let newCamera = getCamera(for: newCameraPosition) else {
            print("No camera available")
            return
        }
        
        captureSession.beginConfiguration()
        captureSession.removeInput(currentInput)
        guard let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
            print("Error creating new capture device input")
            captureSession.addInput(currentInput)
            captureSession.commitConfiguration()
            return
        }
        captureSession.addInput(newInput)
        captureSession.commitConfiguration()
    }
    
    func setupConstraints() {
        let lineThickness: CGFloat = 2.0
                
        horizontalLine.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(50)
            make.height.equalTo(lineThickness)
        }
        
        verticalLine.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalTo(lineThickness)
        }
        
        colorHexLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(horizontalLine.snp.bottom).offset(40)
        }
        
        colorView.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.width.equalTo(200)
            make.centerX.equalToSuperview()
            make.top.equalTo(colorHexLabel.snp.bottom).offset(40)
        }

    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:

            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCamera()
                    } else {
                        self.showCameraAccessDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showCameraAccessDeniedAlert()
        @unknown default:
            print("Unknown camera authorization status")
        }
    }

    func setupCamera() {
        captureSession = AVCaptureSession()

        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("No video device available")
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            print("Error creating capture device input")
            return
        }

        captureSession.addInput(input)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        view.addSubview(horizontalLine)
        view.addSubview(verticalLine)
        view.addSubview(colorHexLabel)
        view.addSubview(colorView)

        setupConstraints()

        captureSession.startRunning()
    }

    func showCameraAccessDeniedAlert() {
        let alert = UIAlertController(title: "Camera Access Denied",
                                      message: "Please go to Settings and enable camera access for this app.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = Date()
        if let lastTime = lastUpdateTime, currentTime.timeIntervalSince(lastTime) < 1 {
            return
        }
        lastUpdateTime = currentTime

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }

        DispatchQueue.main.async {
            // Calculate the center of the crosshair relative to the camera feed
            let viewSize = self.view.bounds.size
            let previewSize = self.previewLayer.bounds.size
            let center = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
            let previewCenter = CGPoint(x: previewSize.width / 2, y: previewSize.height / 2)

            let dotCenter = CGPoint(x: previewCenter.x + (center.x - previewCenter.x),
                                     y: previewCenter.y + (center.y - previewCenter.y))

            let scaleFactorX = CGFloat(cgImage.width) / previewSize.width
            let scaleFactorY = CGFloat(cgImage.height) / previewSize.height
            let scaledCenter = CGPoint(x: dotCenter.x * scaleFactorX,
                                       y: dotCenter.y * scaleFactorY)

            // Define the region around the center to average
            let regionSize: CGFloat = 10.0
            let minX = max(Int(scaledCenter.x - regionSize / 2), 0)
            let minY = max(Int(scaledCenter.y - regionSize / 2), 0)
            let maxX = min(Int(scaledCenter.x + regionSize / 2), cgImage.width)
            let maxY = min(Int(scaledCenter.y + regionSize / 2), cgImage.height)

            guard let pixelData = cgImage.dataProvider?.data else {
                return
            }
            let data = CFDataGetBytePtr(pixelData)
            let bytesPerPixel = 4
            let bytesPerRow = cgImage.bytesPerRow

            // Variables to store the sum of RGB values
            var rTotal: CGFloat = 0
            var gTotal: CGFloat = 0
            var bTotal: CGFloat = 0
            var pixelCount: Int = 0

            for x in minX..<maxX {
                for y in minY..<maxY {
                    let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                    rTotal += CGFloat(data?[pixelIndex] ?? 0)
                    gTotal += CGFloat(data?[pixelIndex + 1] ?? 0)
                    bTotal += CGFloat(data?[pixelIndex + 2] ?? 0)
                    pixelCount += 1
                }
            }

            // Calculate the average color
            let rAvg = rTotal / CGFloat(pixelCount)
            let gAvg = gTotal / CGFloat(pixelCount)
            let bAvg = bTotal / CGFloat(pixelCount)

            let newColor = UIColor(red: rAvg / 255.0, green: gAvg / 255.0, blue: bAvg / 255.0, alpha: 1.0)

            // Calculate the color difference
            let colorDifference = newColor.distance(to: self.previousColor ?? .clear) // Corrected: Use the `distance(to:)` method on `UIColor`

            // Set a threshold for significant color change
            let colorDifferenceThreshold: CGFloat = 0.1 // Adjust this value as needed

            if colorDifference > colorDifferenceThreshold {
                // Update the UI
                self.colorHexLabel.text = String(format: "#%02X%02X%02X", Int(rAvg), Int(gAvg), Int(bAvg)) // Corrected: Use the `format` string to create the hexString
                self.colorView.backgroundColor = newColor

                self.previousColor = newColor
            }
        }
    }
}
