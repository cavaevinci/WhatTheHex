//
//  TabController.swift
//  WhatTheHex
//
//  Created by Ivan Evačić on 17.08.2024..
//

import UIKit

class TabController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTabs()
        self.delegate = self
        self.tabBar.tintColor = .black
        self.tabBar.unselectedItemTintColor = .white
    }
    
    private func setupTabs() {
        let camera = self.createNav(with: "Camera", and: UIImage(systemName: "arrow.triangle.2.circlepath.camera.fill"), vc: MainCameraViewController())
        let history = self.createNav(with: "History", and: UIImage(systemName: "list.clipboard"), vc: PastebinHistoryViewController())
        self.setViewControllers([camera, history], animated: true)
    }
    
    private func createNav(with title: String, and image: UIImage?, vc: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: vc)
        nav.tabBarItem.title = title
        nav.tabBarItem.image = image
        return nav
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.title == "Camera" {
            if let navController = selectedViewController as? UINavigationController,
               let cameraVC = navController.topViewController as? MainCameraViewController {
                cameraVC.toggleCamera()
            }
        }
    }
}
