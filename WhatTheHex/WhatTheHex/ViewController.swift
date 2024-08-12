//
//  ViewController.swift
//  WhatTheHex
//
//  Created by Ivan Evačić on 12.08.2024..
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
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
        // ... (Your camera setup code goes here)
    }

    func showCameraAccessDeniedAlert() {
        let alert = UIAlertController(title: "Camera Access Denied",
                                      message: "Please go to Settings and enable camera access for this app.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
