//
//  PastebinHistoryViewController.swift
//  WhatTheHex
//
//  Created by Ivan Evačić on 17.08.2024..
//

import UIKit

class PastebinHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up table view
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .lightGray
        tableView.register(PastebinHistoryTableViewCell.self, forCellReuseIdentifier: "PastebinHistoryCell")
        view.addSubview(tableView)
        setupConstraints()
    }
    
    func setupConstraints() {

        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5//services.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PastebinHistoryCell", for: indexPath) as! PastebinHistoryTableViewCell
        cell.configure(with: "test")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PastebinHistoryViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return BottomHalfPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class BottomHalfPresentationController: UIPresentationController {

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }

        let halfHeight = containerView.bounds.height / 2
        return CGRect(x: 0,
                      y: containerView.bounds.height - halfHeight,
                      width: containerView.bounds.width,
                      height: halfHeight)
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        // Add a dimming view to the background
        containerView?.insertSubview(dimmingView, at: 0)
        dimmingView.alpha = 0

        // Animate the dimming view alongside the presentation
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.5
        }, completion: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        dimmingView.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        // Dismiss the presented view controller when the dimming view is tapped
        presentedViewController.dismiss(animated: true, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        // Animate the dimming view out alongside the dismissal
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        }, completion: { _ in
            self.dimmingView.removeFromSuperview()
        })
    }

    // Dimming view to cover the background
    lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        view.frame = containerView?.bounds ?? .zero
        return view
    }()
}

