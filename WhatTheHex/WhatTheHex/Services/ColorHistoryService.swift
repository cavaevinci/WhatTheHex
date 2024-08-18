//
//  ColorHistoryService.swift
//  WhatTheHex
//
//  Created by Ivan Evačić on 17.08.2024..
//

import Foundation

class ColorHistoryService {
    static let shared = ColorHistoryService()

    private var colorHistory: [String] = []

    private init() {
        loadFromUserDefaults()
    }

    func saveColor(hexString: String) {
        colorHistory.removeAll { $0 == hexString }
        colorHistory.insert(hexString, at: 0)
        saveToUserDefaults()
    }

    func getColorHistory() -> [String] {
        return colorHistory
    }

    private func saveToUserDefaults() {
        UserDefaults.standard.set(Array(colorHistory), forKey: "colorHistory")
    }

    private func loadFromUserDefaults() {
        if let savedColors = UserDefaults.standard.array(forKey: "colorHistory") as? [String] {
            colorHistory = savedColors
        }
    }
}
