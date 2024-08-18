//
//  PastebinHistoryViewController.swift
//  WhatTheHex
//
//  Created by Ivan Evačić on 17.08.2024..
//

import UIKit
import AVFoundation

class PastebinHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureSession: AVCaptureSession!
    private var blurEffectView: UIVisualEffectView!
    
    lazy var tableView = UITableView()
    
    private var colorHistory: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupCamera()
        setupBlurEffect()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadColorHistory()
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.register(PastebinHistoryTableViewCell.self, forCellReuseIdentifier: "PastebinHistoryCell")
    }
    
    func setupConstraints() {
        tableView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    private func loadColorHistory() {
        colorHistory = ColorHistoryService.shared.getColorHistory()
        tableView.reloadData()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let camera = AVCaptureDevice.default(for: .video) else {
            print("No camera available")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            captureSession.addInput(input)
        } catch {
            print("Error setting up camera input: \(error)")
            return
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }

    private func setupBlurEffect() {
        let blurEffect = UIBlurEffect(style: .light)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        view.bringSubviewToFront(blurEffectView)
        view.addSubview(tableView)
        view.bringSubviewToFront(tableView)
        setupConstraints()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colorHistory.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PastebinHistoryCell", for: indexPath) as! PastebinHistoryTableViewCell
        cell.configure(with: colorHistory[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UIPasteboard.general.string = colorHistory[indexPath.row]
        NotificationService.shared.showNotification(in: self.view, message: "Color \(colorHistory[indexPath.row]) copied to clipboard.")
    }
}

extension PastebinHistoryViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
