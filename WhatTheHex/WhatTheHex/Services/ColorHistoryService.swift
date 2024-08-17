//
//  ColorHistoryService.swift
//  WhatTheHex
//
//  Created by Ivan Evačić on 17.08.2024..
//

import Foundation

class ColorHistoryService {
    static let shared = ColorHistoryService()

    private var colorHistory: Set<String> = []

    private init() {
        loadFromUserDefaults()
    }

    func saveColor(hexString: String) {
        colorHistory.insert(hexString)
        saveToUserDefaults()
    }

    func getColorHistory() -> [String] {
        return Array(colorHistory)
    }

    private func saveToUserDefaults() {
        UserDefaults.standard.set(Array(colorHistory), forKey: "colorHistory")
    }

    private func loadFromUserDefaults() {
        if let savedColors = UserDefaults.standard.array(forKey: "colorHistory") as? [String] {
            colorHistory = Set(savedColors)
        }
    }
}
