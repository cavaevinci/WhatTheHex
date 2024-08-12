//
//  ViewController.swift
//  WhatTheHex
//
//  Created by Ivan Evačić on 12.08.2024..
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    var colorLabel: UILabel!
    var dotView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create and configure the colorLabel
        colorLabel = UILabel()
        colorLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 50) // Adjust the frame as needed
        colorLabel.center = view.center // Center the label in the view
        colorLabel.textAlignment = .center
        colorLabel.textColor = .white // Set text color for better visibility
        colorLabel.backgroundColor = .black // Add a background for contrast
        view.addSubview(colorLabel)
        
        // Add constraints to the colorLabel
        NSLayoutConstraint.activate([
            colorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colorLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20), // 20 points from the bottom
            colorLabel.widthAnchor.constraint(equalToConstant: 200),
            colorLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        dotView = UIView()
        dotView.frame = CGRect(x: 0, y: 0, width: 50, height: 50) // Adjust size as needed
        dotView.center = view.center // Initially center the dot
        dotView.layer.cornerRadius = dotView.frame.width / 2 // Make it circular
        dotView.backgroundColor = .white // Or any color you prefer
        view.addSubview(dotView)
        
        NSLayoutConstraint.activate([
            dotView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dotView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dotView.widthAnchor.constraint(equalToConstant: 50),
            dotView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        dotView.addGestureRecognizer(panGesture)
        
        checkCameraPermission()
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        gesture.setTranslation(.zero, in: view) // Reset translation so it's cumulative

        // Update the dot's center based on the gesture's translation
        dotView.center = CGPoint(x: dotView.center.x + translation.x, y: dotView.center.y + translation.y)

        // Constrain the dot within the view's bounds (optional)
        dotView.center.x = max(dotView.frame.width / 2, dotView.center.x)
        dotView.center.x = min(view.bounds.width - dotView.frame.width / 2, dotView.center.x)
        dotView.center.y = max(dotView.frame.height / 2, dotView.center.y)
        dotView.center.y = min(view.bounds.height - dotView.frame.height / 2, dotView.center.y)
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:

            // Camera access is granted, proceed with setting up your camera session
            setupCamera()
        case .notDetermined:
            // Request camera access permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCamera()
                    } else {
                        // Handle the case where the user denied camera access
                        self.showCameraAccessDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            // Camera access is denied or restricted, inform the user
            showCameraAccessDeniedAlert()
        @unknown default:
            // Handle unexpected cases
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
        videoOutput.setSampleBufferDelegate(self, queue:
 DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)


        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity
 = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

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
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)

        // 1. Get the dot's position on the main thread
        var dotPositionInView: CGPoint!
        DispatchQueue.main.sync {
            dotPositionInView = dotView.center
        }

        // 2. Convert the dot's position to a point within the CIImage's coordinates
        let dotPositionInImage = previewLayer.captureDevicePointConverted(fromLayerPoint: dotPositionInView)

        // 3. Get the color at the dot's position
        let color = getColorAtPoint(dotPositionInImage, from: ciImage)

        // 4. Convert the color to a hex string
        let hexString = color.toHexString()

        // 5. Update the UI on the main thread
        DispatchQueue.main.async {
            self.colorLabel.text = hexString
        }
    }
    
    func getColorAtPoint(_ point: CGPoint, from image: CIImage) -> UIColor {
        let context = CIContext(options: nil)
        let extent = CGRect(x: point.x, y: point.y, width: 1, height: 1) // Sample a single pixel

        guard let pixelBuffer = context.createCGImage(image, from: extent) else {
            return .black // Return a default color if sampling fails
        }

        let dataProvider = pixelBuffer.dataProvider
        let data = CFDataGetBytePtr(dataProvider!.data)

        let red = CGFloat(data![0]) / 255.0
        let green = CGFloat(data![1]) / 255.0
        let blue = CGFloat(data![2]) / 255.0
        let alpha = CGFloat(data![3]) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
}

extension UIColor {
    func toHexString() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red,
 green: &green, blue: &blue, alpha: &alpha)

        let rgb: Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | (Int)(blue*255)<<0

        return String(format: "#%06x", rgb)

    }
}
