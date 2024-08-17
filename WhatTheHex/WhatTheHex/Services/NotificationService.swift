//
//  NotificationService.swift
//  WhatTheHex
//
//  Created by Ivan Evačić on 18.08.2024..
//

import UIKit
import SnapKit

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func showNotification(in view: UIView, message: String, duration: TimeInterval = 2.0) {
        let notificationLabel = UILabel()
        notificationLabel.backgroundColor = .black
        notificationLabel.textColor = .white
        notificationLabel.text = message
        notificationLabel.textAlignment = .center
        notificationLabel.alpha = 0
        notificationLabel.numberOfLines = 0
        notificationLabel.layer.cornerRadius = 5
        notificationLabel.layer.masksToBounds = true
        notificationLabel.font = UIFont.systemFont(ofSize: 16)
        
        view.addSubview(notificationLabel)
        
        notificationLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(25)
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            notificationLabel.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: [], animations: {
                notificationLabel.alpha = 0
            }, completion: { _ in
                notificationLabel.removeFromSuperview()
            })
        })
    }
}
